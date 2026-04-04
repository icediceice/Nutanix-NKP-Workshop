#!/bin/bash
# teardown.sh — Remove workshop environments from the cluster
#
# Usage:
#   ./teardown.sh                   Remove workshop sessions only (keeps Educates + app running)
#   ./teardown.sh --workshops-only  Remove workshop environments and sessions
#   ./teardown.sh --app-only        Remove registration app only
#   ./teardown.sh --all             Remove everything: Educates, app, all workshop content

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.local.yaml"
[[ ! -f "${CONFIG_FILE}" ]] && CONFIG_FILE="${SCRIPT_DIR}/config.yaml"

cfg() { yq eval ".${1}" "${CONFIG_FILE}"; }

WORKSHOPS_ONLY=false
APP_ONLY=false
ALL=false

for arg in "$@"; do
  case $arg in
    --workshops-only) WORKSHOPS_ONLY=true ;;
    --app-only)       APP_ONLY=true ;;
    --all)            ALL=true ;;
  esac
done

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   NKP Workshop Platform Teardown                     ║"
echo "╚══════════════════════════════════════════════════════╝"

# ──────────────────────────────────────────────
# Remove workshop sessions (always unless app-only)
# ──────────────────────────────────────────────
if [[ "${APP_ONLY}" == "false" ]]; then
  echo "→ Deleting WorkshopSession CRDs..."
  kubectl delete workshopsessions --all --all-namespaces --ignore-not-found=true 2>/dev/null || true

  echo "→ Deleting workshop environments..."
  kubectl delete workshopenvironments --all --all-namespaces --ignore-not-found=true 2>/dev/null || true

  SESSION_LABEL=$(cfg session_label)
  echo "→ Deleting namespaces labeled managed-by=nkp-lab-manager..."
  kubectl delete namespaces -l "managed-by=nkp-lab-manager" --ignore-not-found=true

  echo "✓ Workshop sessions removed"
fi

# ──────────────────────────────────────────────
# Remove registration app
# ──────────────────────────────────────────────
if [[ "${ALL}" == "true" || "${APP_ONLY}" == "true" ]]; then
  echo "→ Removing registration app..."
  APP_DIR="${SCRIPT_DIR}/../registration-app"
  kubectl delete -f "${APP_DIR}/k8s/" --ignore-not-found=true
  kubectl delete namespace nkp-lab-manager --ignore-not-found=true
  echo "✓ Registration app removed"
fi

# ──────────────────────────────────────────────
# Remove Educates (--all only)
# ──────────────────────────────────────────────
if [[ "${ALL}" == "true" ]]; then
  echo "→ Removing Educates..."
  educates delete-platform 2>/dev/null || kubectl delete -f "${SCRIPT_DIR}/educates/training-portal.yaml" --ignore-not-found=true
  echo "✓ Educates removed"
fi

echo ""
echo "Teardown complete."
