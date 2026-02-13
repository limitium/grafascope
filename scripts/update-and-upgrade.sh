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
#   DRY_RUN=1 (print commands without executing)
#
# Usage:
#   scripts/update-and-upgrade.sh all [--dry-run]
#   scripts/update-and-upgrade.sh core [--dry-run]
#   scripts/update-and-upgrade.sh vmagent [--dry-run]
#   scripts/update-and-upgrade.sh fluent-bit [--dry-run]
#   scripts/update-and-upgrade.sh demo-apps [--dry-run]
#   scripts/update-and-upgrade.sh delete-all [--dry-run]

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

NAMESPACE="${NAMESPACE:-grafascope}"
VALUES="${VALUES:-grafascope/values.yaml}"
DRY_RUN="${DRY_RUN:-0}"

if [[ $# -gt 0 && "${@: -1}" == "--dry-run" ]]; then
  DRY_RUN=1
  set -- "${@:1:$#-1}"
fi

ACTION="${1:-all}"

run() {
  if [[ "$DRY_RUN" == "1" || "$DRY_RUN" == "true" || "$DRY_RUN" == "yes" ]]; then
    if [[ "$1" == "helm" && "$2" == "upgrade" ]]; then
      shift
      helm "$@" --dry-run --debug
      return 0
    fi
    echo "[dry-run] $*"
    return 0
  fi
  "$@"
}

update_core() {
  run helm dependency update ./grafascope/releases/core
  run helm upgrade --install grafascope-core ./grafascope/releases/core -n "$NAMESPACE" -f "$VALUES"
}

update_vmagent() {
  run helm dependency update ./grafascope/releases/vmagent
  run helm upgrade --install grafascope-vmagent ./grafascope/releases/vmagent -n "$NAMESPACE" -f "$VALUES"
}

update_fluent_bit() {
  run helm dependency update ./grafascope/releases/log-tailer
  run helm upgrade --install grafascope-log-tailer ./grafascope/releases/log-tailer -n "$NAMESPACE" -f "$VALUES"
}

update_demo_apps() {
  run helm dependency update ./demo-apps
  run helm upgrade --install demo-apps ./demo-apps -n "$NAMESPACE" -f "$VALUES"
}

delete_all() {
  run helm uninstall demo-apps -n "$NAMESPACE" 2>/dev/null || true
  run helm uninstall grafascope-log-tailer -n "$NAMESPACE" 2>/dev/null || true
  run helm uninstall grafascope-vmagent -n "$NAMESPACE" 2>/dev/null || true
  run helm uninstall grafascope-core -n "$NAMESPACE" 2>/dev/null || true
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
