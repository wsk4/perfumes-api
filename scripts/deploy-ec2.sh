#!/usr/bin/env bash
# Despliegue en una instancia EC2 (Amazon Linux 2023) con k3s + Istio.
# Pensado para ejecutarse vía SSM (AWS-RunShellScript), como root.
#
# Uso: ./scripts/deploy-ec2.sh <imagen>
#   ./scripts/deploy-ec2.sh ghcr.io/moonlighpoio/perfumes-api:abc123
set -euo pipefail

IMAGE="${1:?uso: deploy-ec2.sh <imagen>}"
BRANCH="${BRANCH:-main}"
REPO="${REPO:-https://github.com/Moonlighpoio/perfumes-api.git}"
ISTIO_VERSION="${ISTIO_VERSION:-1.24.4}"
APP_DIR="/opt/perfumes-api"
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# --- 1. k3s (sin Traefik para liberar los puertos 80/443) --------------------
if ! command -v k3s >/dev/null 2>&1; then
  curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -
fi
systemctl enable --now k3s
for _ in $(seq 1 60); do
  k3s kubectl get nodes 2>/dev/null | grep -q " Ready" && break
  sleep 5
done

# --- 2. Código e imagen ------------------------------------------------------
rm -rf "${APP_DIR}"
git clone --depth 1 -b "${BRANCH}" "${REPO}" "${APP_DIR}"
cd "${APP_DIR}"
sed -i "s|perfumes-api:local|${IMAGE}|" src/k8s/deployment-api.yaml

# --- 3. Istio ----------------------------------------------------------------
if [ ! -x "/opt/istio-${ISTIO_VERSION}/bin/istioctl" ]; then
  curl -fsSL "https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-linux-amd64.tar.gz" -o /tmp/istio.tar.gz
  tar xzf /tmp/istio.tar.gz -C /opt
fi
ISTIO_DIR="/opt/istio-${ISTIO_VERSION}"
"${ISTIO_DIR}/bin/istioctl" install -y --set profile=default

# --- 4. Manifiestos ----------------------------------------------------------
k3s kubectl apply -f src/k8s/
k3s kubectl apply -f src/k8s/istio/
k3s kubectl -n perfumes rollout status deployment/redis --timeout=120s
k3s kubectl -n perfumes rollout status deployment/perfumes-api --timeout=300s

# --- 5. Observabilidad -------------------------------------------------------
for addon in prometheus grafana kiali; do
  k3s kubectl apply -f "${ISTIO_DIR}/samples/addons/${addon}.yaml"
done

# --- 6. Evidencias y verificación -------------------------------------------
"${ISTIO_DIR}/bin/istioctl" analyze -n perfumes
k3s kubectl -n perfumes get pods
k3s kubectl -n istio-system get svc istio-ingressgateway

PORT="$(k3s kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')"
for _ in $(seq 1 30); do
  curl -sf "http://127.0.0.1:${PORT}/health" >/dev/null 2>&1 && break
  sleep 2
done
curl -fsS "http://127.0.0.1:${PORT}/health"
echo
echo "Despliegue completado en el puerto ${PORT}. Ruta de observabilidad: istioctl dashboard kiali"
