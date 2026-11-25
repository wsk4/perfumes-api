#!/usr/bin/env bash
# Importa y verifica el dashboard personalizado exigido por la EP3.
# Uso: bash scripts/import-grafana-dashboard.sh [comando-kubectl]
set -euo pipefail

if [[ "${1:-kubectl}" == "k3s" ]]; then
  KUBECTL=(k3s kubectl)
else
  KUBECTL=(kubectl)
fi
DASHBOARD_FILE="observability/grafana/perfumes-ep3-dashboard.json"
GRAFANA_PORT="${GRAFANA_PORT:-3001}"

[[ -f "${DASHBOARD_FILE}" ]]

cleanup() {
  kill "${GRAFANA_PF_PID:-}" 2>/dev/null || true
}
trap cleanup EXIT

"${KUBECTL[@]}" -n istio-system port-forward svc/grafana "${GRAFANA_PORT}:3000" >/tmp/grafana-port-forward.log 2>&1 &
GRAFANA_PF_PID=$!

for _ in $(seq 1 30); do
  if curl -fsS -u admin:admin "http://127.0.0.1:${GRAFANA_PORT}/api/health" >/dev/null; then
    break
  fi
  sleep 2
done

curl -fsS -u admin:admin \
  -H 'Content-Type: application/json' \
  --data-binary "@${DASHBOARD_FILE}" \
  "http://127.0.0.1:${GRAFANA_PORT}/api/dashboards/db" >/tmp/grafana-dashboard-import.json

curl -fsS -u admin:admin "http://127.0.0.1:${GRAFANA_PORT}/api/dashboards/uid/perfumes-ep3" \
  | grep -q 'Perfumes API EP3 - Operacion y CI CD'

echo "Dashboard Grafana personalizado importado y verificado: perfumes-ep3"
