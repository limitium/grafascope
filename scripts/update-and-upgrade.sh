#!/usr/bin/env bash
# Update chart deps and upgrade releases (prod/regular k8s):
# 1) core
# 2) vmagent
# 3) fluent-bit (log-tailer)
# 4) demo-apps
# 5) delete-all (uninstall the four above)
#
# Defaults:
#   NAMESPACE=grafascope
#   VALUES=grafascope/values.yaml
#
# Usage:
#   scripts/update-and-upgrade.sh all
#   scripts/update-and-upgrade.sh core
#   scripts/update-and-upgrade.sh vmagent
#   scripts/update-and-upgrade.sh fluent-bit
#   scripts/update-and-upgrade.sh demo-apps
#   scripts/update-and-upgrade.sh delete-all

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

NAMESPACE="${NAMESPACE:-grafascope}"
VALUES="${VALUES:-grafascope/values.yaml}"
ACTION="${1:-all}"

update_core() {
  helm dependency update ./grafascope/releases/core
  helm upgrade --install grafascope-core ./grafascope/releases/core -n "$NAMESPACE" -f "$VALUES"
}

update_vmagent() {
  helm dependency update ./grafascope/releases/vmagent
  helm upgrade --install grafascope-vmagent ./grafascope/releases/vmagent -n "$NAMESPACE" -f "$VALUES"
}

update_fluent_bit() {
  helm dependency update ./grafascope/releases/log-tailer
  helm upgrade --install grafascope-log-tailer ./grafascope/releases/log-tailer -n "$NAMESPACE" -f "$VALUES"
}

update_demo_apps() {
  helm dependency update ./demo-apps
  helm upgrade --install demo-apps ./demo-apps -n "$NAMESPACE" -f "$VALUES"
}

delete_all() {
  helm uninstall demo-apps -n "$NAMESPACE" 2>/dev/null || true
  helm uninstall grafascope-log-tailer -n "$NAMESPACE" 2>/dev/null || true
  helm uninstall grafascope-vmagent -n "$NAMESPACE" 2>/dev/null || true
  helm uninstall grafascope-core -n "$NAMESPACE" 2>/dev/null || true
}

case "$ACTION" in
  all)
    update_core
    update_vmagent
    update_fluent_bit
    update_demo_apps
    ;;
  core)
    update_core
    ;;
  vmagent)
    update_vmagent
    ;;
  fluent-bit|fluentbit|log-tailer)
    update_fluent_bit
    ;;
  demo-apps|demoapps)
    update_demo_apps
    ;;
  delete-all|delete)
    delete_all
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    echo "Use: all | core | vmagent | fluent-bit | demo-apps | delete-all" >&2
    exit 1
    ;;
esac
