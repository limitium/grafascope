#!/usr/bin/env bash
# Install: ingress-nginx, gfs-user, core, vmagent, log-tailer (fluent-bit), demo-apps on the current cluster.
# Does not delete or create clusters. Run from repo root.
# Uses grafascope/values.yaml for global values (ports, paths, image registry).
# Optional: set CLEAN_NAMESPACE=1 to uninstall releases and delete the namespace before installing.
#
# For k3d: create cluster with port 80 mapped so http://localhost/<ns>/grafana works:
#   k3d cluster create <name> -p 80:80@server:0 -p 443:443@server:0
# Otherwise use: kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80
#   then open http://localhost:8080/<namespace>/grafana
set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
NAMESPACE="${NAMESPACE:-grafascope}"
VALUES="${VALUES:-grafascope/values.yaml}"
CLEAN_NAMESPACE="${CLEAN_NAMESPACE:-1}"

if [[ "$CLEAN_NAMESPACE" == "1" || "$CLEAN_NAMESPACE" == "true" || "$CLEAN_NAMESPACE" == "yes" ]]; then
  echo "=== Cleaning namespace $NAMESPACE (uninstall releases, delete namespace) ==="
  helm uninstall demo-apps -n "$NAMESPACE" 2>/dev/null || true
  helm uninstall grafascope-log-tailer -n "$NAMESPACE" 2>/dev/null || true
  helm uninstall grafascope-vmagent -n "$NAMESPACE" 2>/dev/null || true
  helm uninstall grafascope-core -n "$NAMESPACE" 2>/dev/null || true
  helm uninstall gfs-user -n "$NAMESPACE" 2>/dev/null || true
  kubectl delete namespace "$NAMESPACE" --timeout=120s 2>/dev/null || true
  echo "=== Waiting for namespace to be gone ==="
  kubectl wait --for=delete namespace/"$NAMESPACE" --timeout=120s 2>/dev/null || true
fi

echo "=== Installing ingress-nginx (required for Ingress with class nginx; skip if already present) ==="
if ! kubectl get deployment -n ingress-nginx ingress-nginx-controller 2>/dev/null; then
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
  helm repo update ingress-nginx
  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx --create-namespace \
    --set controller.hostPort.enabled=true \
    --set controller.hostPort.ports.http=80 \
    --set controller.hostPort.ports.https=443 \
    --set controller.kind=DaemonSet \
    --set controller.admissionWebhooks.enabled=false
  kubectl delete validatingwebhookconfiguration ingress-nginx-admission 2>/dev/null || true
  echo "Waiting for ingress-nginx controller to be ready..."
  kubectl wait --namespace ingress-nginx --for=condition=ready pod -l app.kubernetes.io/component=controller --timeout=120s 2>/dev/null || true
else
  echo "ingress-nginx already installed, skipping."
fi

echo "=== Creating namespace $NAMESPACE ==="
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

echo "=== Helm dependency update ==="
helm dependency update ./grafascope/releases/gfs-user
helm dependency update ./grafascope/releases/core
helm dependency update ./grafascope/releases/vmagent
helm dependency update ./grafascope/releases/log-tailer
helm dependency update ./demo-apps

echo "=== Installing gfs-user (ServiceAccount for vmagent) ==="
helm upgrade --install gfs-user ./grafascope/releases/gfs-user -n "$NAMESPACE" -f "$VALUES"

echo "=== Installing grafascope-core (Grafana + VictoriaMetrics/Logs/Traces) ==="
helm upgrade --install grafascope-core ./grafascope/releases/core -n "$NAMESPACE" -f "$VALUES"

echo "=== Installing grafascope-vmagent ==="
helm upgrade --install grafascope-vmagent ./grafascope/releases/vmagent -n "$NAMESPACE" -f "$VALUES"

echo "=== Installing grafascope-log-tailer (Fluent Bit) ==="
helm upgrade --install grafascope-log-tailer ./grafascope/releases/log-tailer -n "$NAMESPACE" -f "$VALUES"

echo "=== Installing demo-apps ==="
helm upgrade --install demo-apps ./demo-apps -n "$NAMESPACE" -f "$VALUES"

echo "=== Done. Ingress URLs (namespace prefix): /$NAMESPACE/<path> ==="
echo "  Grafana:         http://localhost/$NAMESPACE/grafana"
echo "  VictoriaMetrics: http://localhost/$NAMESPACE/victoria-metrics"
echo "  VictoriaLogs:    http://localhost/$NAMESPACE/victoria-logs"
echo "  VictoriaTraces:  http://localhost/$NAMESPACE/victoria-traces"
echo "  vmagent:         http://localhost/$NAMESPACE/vmagent"
echo ""
echo "For k3d: create cluster with port 80 mapped so localhost works:"
echo "  k3d cluster create <name> -p 80:80@server:0 -p 443:443@server:0"
echo "If the cluster was created without that, use port-forward and open http://localhost:8080/$NAMESPACE/grafana :"
echo "  kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80"
