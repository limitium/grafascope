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
#   DRY_RUN=0
#
# Values resolution (when run as submodule from consumer repo):
#   First param (env)     → use grafascope/values.yaml + ../values/<env>.yaml
#   VALUES=<path>         → use only this file (overrides env)
#
# Usage:
#   scripts/update-and-upgrade.sh <env> [action] [--dry-run]
#   scripts/update-and-upgrade.sh grafascope-dev all
#   scripts/update-and-upgrade.sh grafascope-dev core --dry-run

set -euo pipefail

GRAFASCOPE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$GRAFASCOPE_ROOT"

PARENT_ROOT="$(cd "$GRAFASCOPE_ROOT/.." && pwd)"

NAMESPACE="${NAMESPACE:-grafascope}"
DRY_RUN="${DRY_RUN:-0}"

if [[ $# -gt 0 && "${@: -1}" == "--dry-run" ]]; then
  DRY_RUN=1
  set -- "${@:1:$#-1}"
fi

ENV="${1:?Usage: $0 <env> [action] [--dry-run] - env is required (e.g. grafascope-dev)}"
ACTION="${2:-all}"

# Build values file args: base + env override, or explicit VALUES
if [[ -n "${VALUES:-}" ]]; then
  VALUES_ARGS=""
  _last=""
  for v in $VALUES; do
    VALUES_ARGS="$VALUES_ARGS -f $v"
    _last="$v"
  done
  if [[ -n "$_last" && -f "$_last" ]] && _ns=$(grep -E '^\s*namespace:' "$_last" 2>/dev/null | head -1 | sed -E 's/^[^:]*:[[:space:]]*//' | tr -d '"\047'); [[ -n "$_ns" ]]; then
    NAMESPACE="$_ns"
  fi
elif [[ -f "$PARENT_ROOT/values/${ENV}.yaml" ]]; then
  VALUES_ARGS="-f grafascope/values.yaml -f $PARENT_ROOT/values/${ENV}.yaml"
  # Optional: read namespace from env values file (top-level key)
  if _ns=$(grep -E '^\s*namespace:' "$PARENT_ROOT/values/${ENV}.yaml" 2>/dev/null | head -1 | sed -E 's/^[^:]*:[[:space:]]*//' | tr -d '"\047'); [[ -n "$_ns" ]]; then
    NAMESPACE="$_ns"
  fi
else
  echo "Error: values/${ENV}.yaml not found" >&2
  exit 1
fi

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

update_gfs_user() {
  run helm dependency update ./grafascope/releases/gfs-user
  run helm upgrade --install gfs-user ./grafascope/releases/gfs-user -n "$NAMESPACE" --create-namespace $VALUES_ARGS
}

update_core() {
  run helm dependency update ./grafascope/releases/core
  run helm upgrade --install grafascope-core ./grafascope/releases/core -n "$NAMESPACE" --create-namespace $VALUES_ARGS
}

update_vmagent() {
  run helm dependency update ./grafascope/releases/vmagent
  run helm upgrade --install grafascope-vmagent ./grafascope/releases/vmagent -n "$NAMESPACE" --create-namespace $VALUES_ARGS
}

update_fluent_bit() {
  run helm dependency update ./grafascope/releases/log-tailer
  run helm upgrade --install grafascope-log-tailer ./grafascope/releases/log-tailer -n "$NAMESPACE" $VALUES_ARGS
}

update_demo_apps() {
  run helm dependency update ./demo-apps
  run helm upgrade --install demo-apps ./demo-apps -n "$NAMESPACE" --create-namespace $VALUES_ARGS
}

delete_all() {
  run helm uninstall demo-apps -n "$NAMESPACE" 2>/dev/null || true
  run helm uninstall grafascope-log-tailer -n "$NAMESPACE" 2>/dev/null || true
  run helm uninstall grafascope-vmagent -n "$NAMESPACE" 2>/dev/null || true
  run helm uninstall grafascope-vlagent -n "$NAMESPACE" 2>/dev/null || true
  run helm uninstall grafascope-core -n "$NAMESPACE" 2>/dev/null || true
  run helm uninstall gfs-user -n "$NAMESPACE" 2>/dev/null || true
  run kubectl delete namespace "$NAMESPACE" --timeout=120s 2>/dev/null || true
}

case "$ACTION" in
  all)
    update_gfs_user
    update_core
    update_vmagent
    update_fluent_bit
    update_demo_apps
    ;;
  obs)
    update_gfs_user
    update_core
    update_fluent_bit
    update_vmagent
    ;;
  demo)
    update_demo_apps
    update_vmagent
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
    echo "Usage: $0 <env> [action] [--dry-run]" >&2
    echo "Actions: all | obs | demo | core | vmagent | fluent-bit | demo-apps | delete-all" >&2
    exit 1
    ;;
esac
