#!/usr/bin/env bash
# Levanta un cluster Kubernetes local (kind) con Istio, despliega la API,
# instala el stack de observabilidad (Prometheus, Grafana, Kiali) y ejecuta
# el smoke test a través del ingress gateway.
#
# Uso: ./scripts/k8s-local.sh [imagen]   (por defecto perfumes-api:local)
# Requiere: docker, kubectl y conexión a internet.
set -euo pipefail

IMAGE="${1:-perfumes-api:local}"
CLUSTER="${CLUSTER:-ep3}"
ISTIO_VERSION="${ISTIO_VERSION:-1.24.4}"
KIND_VERSION="${KIND_VERSION:-v0.24.0}"
ISTIO_DIR="istio-${ISTIO_VERSION}"

# --- 1. Cluster kind ---------------------------------------------------------
if ! command -v kind >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -fsSL "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64" -o /tmp/kind
  chmod +x /tmp/kind
  sudo mv /tmp/kind /usr/local/bin/kind
fi
if ! kind get clusters 2>/dev/null | grep -qx "${CLUSTER}"; then
  kind create cluster --name "${CLUSTER}"
fi
kind load docker-image "${IMAGE}" --name "${CLUSTER}"

# --- 2. Istio ----------------------------------------------------------------
if [[ ! -x "${ISTIO_DIR}/bin/istioctl" ]]; then
  curl --proto '=https' --tlsv1.2 -fsSL "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux-amd64.tar.gz" | tar xz
fi
"${ISTIO_DIR}/bin/istioctl" install -y --set profile=default

# --- 3. Manifiestos de la aplicación ----------------------------------------
# Se generan en un directorio temporal para no modificar los archivos versionados.
TMP_MANIFESTS="$(mktemp -d)"
trap 'rm -rf "${TMP_MANIFESTS}"; kill "${PF_PID:-}" 2>/dev/null || true' EXIT
cp -r src/k8s/. "${TMP_MANIFESTS}/"
sed -i "s|perfumes-api:local|${IMAGE}|" "${TMP_MANIFESTS}/deployment-api.yaml"
kubectl apply -f "${TMP_MANIFESTS}/"
kubectl apply -f "${TMP_MANIFESTS}/istio/"
kubectl -n perfumes rollout status deployment/redis --timeout=120s
kubectl -n perfumes rollout status deployment/perfumes-api --timeout=300s

# --- 4. Stack de observabilidad (addons oficiales de Istio) ------------------
for addon in prometheus grafana kiali; do
  kubectl apply -f "${ISTIO_DIR}/samples/addons/${addon}.yaml"
done
kubectl -n istio-system rollout status deployment/prometheus --timeout=180s
kubectl -n istio-system rollout status deployment/grafana --timeout=180s
kubectl -n istio-system rollout status deployment/kiali --timeout=180s
bash scripts/import-grafana-dashboard.sh kubectl

# --- 5. Validación de la malla (gate bloqueante) -----------------------------
"${ISTIO_DIR}/bin/istioctl" analyze -n perfumes

# --- 6. Smoke test a través del ingress gateway ------------------------------
kubectl -n istio-system port-forward svc/istio-ingressgateway 3000:80 >/tmp/istio-port-forward.log 2>&1 &
PF_PID=$!
for _ in $(seq 1 30); do
  curl -sf http://localhost:3000/health >/dev/null 2>&1 && break # NOSONAR: loopback-only port-forward without TLS
  sleep 2
done
node scripts/smoke-test.mjs

echo
echo "Listo. Dashboards (en otra terminal):"
echo "  istioctl dashboard kiali"
echo "  istioctl dashboard grafana"
echo "  istioctl dashboard prometheus"
