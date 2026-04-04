#!/bin/bash
# install/install.sh — NKP Workshop installer wrapper
#
# Usage:
#   ./install/install.sh --values install/values/values-workload01.yaml
#   ./install/install.sh --values install/values/values-workload02.yaml
#   ./install/install.sh --values install/values/values-workload01.yaml --platform-only
#   ./install/install.sh --values install/values/values-workload01.yaml --educates-only
#   ./install/install.sh --values install/values/values-workload01.yaml --app-only
#   ./install/install.sh --values install/values/values-workload01.yaml --teardown
#
# Environment variables (override values file):
#   WORKSHOP_ADMIN_PASSWORD   — admin password for the registration app
#   WORKSHOP_SESSION_LABEL    — override session label (e.g. workshop-2026-05)
#
# Requirements: yq, kubectl, educates CLI (auto-installed if missing)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_INIT_DIR="${SCRIPT_DIR}/../cluster-init"
CONFIG_LOCAL="${CLUSTER_INIT_DIR}/config.local.yaml"

# ── Parse arguments ──
VALUES_FILE=""
PASSTHROUGH_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --values)
      VALUES_FILE="$2"
      shift 2
      ;;
    *)
      PASSTHROUGH_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z "${VALUES_FILE}" ]]; then
  echo "ERROR: --values <path> is required."
  echo "Usage: $0 --values install/values/values-<cluster>.yaml [--platform-only|--educates-only|--app-only|--workshops-only|--teardown]"
  exit 1
fi

if [[ ! -f "${VALUES_FILE}" ]]; then
  echo "ERROR: Values file not found: ${VALUES_FILE}"
  exit 1
fi

# Resolve absolute path
VALUES_FILE="$(cd "$(dirname "${VALUES_FILE}")" && pwd)/$(basename "${VALUES_FILE}")"

echo "╔══════════════════════════════════════════════════════╗"
echo "║   NKP Workshop Installer                             ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Values: $(basename "${VALUES_FILE}")$(printf '%*s' $((44 - ${#VALUES_FILE##*/})) '')║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Merge values file → config.local.yaml ──
# Start from the template, overlay values file fields
cp "${VALUES_FILE}" "${CONFIG_LOCAL}"

# Inject env var overrides if set
if [[ -n "${WORKSHOP_ADMIN_PASSWORD:-}" ]]; then
  yq eval ".admin_password = \"${WORKSHOP_ADMIN_PASSWORD}\"" -i "${CONFIG_LOCAL}"
  echo "  ✓ admin_password injected from WORKSHOP_ADMIN_PASSWORD"
fi

if [[ -n "${WORKSHOP_SESSION_LABEL:-}" ]]; then
  yq eval ".session_label = \"${WORKSHOP_SESSION_LABEL}\"" -i "${CONFIG_LOCAL}"
  echo "  ✓ session_label overridden: ${WORKSHOP_SESSION_LABEL}"
fi

echo "  Config written to: ${CONFIG_LOCAL}"
echo ""

# ── Run init.sh with passthrough flags ──
exec "${CLUSTER_INIT_DIR}/init.sh" "${PASSTHROUGH_ARGS[@]+"${PASSTHROUGH_ARGS[@]}"}"
