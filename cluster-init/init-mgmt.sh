#!/bin/bash
# init-mgmt.sh — NKP Workshop Management Cluster Init
#
# Applies management-cluster-specific configs using auth/nkp.conf.
# Run after init.sh completes the workload cluster / Educates setup.
#
# Usage:
#   ./init-mgmt.sh                   Full management cluster setup
#   ./init-mgmt.sh --domain-only     Kommander domain redirect only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.local.yaml"
[[ ! -f "${CONFIG_FILE}" ]] && CONFIG_FILE="${SCRIPT_DIR}/config.yaml"

export PATH="${HOME}/.local/bin:${PATH}"

DOMAIN_ONLY=false
for arg in "$@"; do
  case $arg in
    --domain-only) DOMAIN_ONLY=true ;;
  esac
done

cfg() { yq eval ".${1}" "${CONFIG_FILE}"; }

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   NKP Workshop Management Cluster Init               ║"
echo "╚══════════════════════════════════════════════════════╝"

MGMT_KUBECONFIG="${SCRIPT_DIR}/../auth/nkp.conf"
if [[ ! -f "${MGMT_KUBECONFIG}" ]]; then
  echo "ERROR: Management cluster kubeconfig not found at ${MGMT_KUBECONFIG}"
  echo "       Place the kubeconfig for the NKP management cluster at auth/nkp.conf"
  exit 1
fi

export KUBECONFIG="${MGMT_KUBECONFIG}"
echo "Kubeconfig: ${MGMT_KUBECONFIG}"
echo ""

# ──────────────────────────────────────────────
# Step 1: Kommander domain redirect
# ──────────────────────────────────────────────
echo "[1] Kommander domain redirect..."

MGMT_IP=$(cfg kommander_mgmt_ip 2>/dev/null || echo "")
if [[ -z "${MGMT_IP}" || "${MGMT_IP}" == "null" ]]; then
  echo "  ⚠ kommander_mgmt_ip not set in config — applying kommander-domain.yaml as-is"
  kubectl apply -f "${SCRIPT_DIR}/kommander/kommander-domain.yaml"
else
  SSLIP_HOST="nkp-$(echo "${MGMT_IP}" | tr '.' '-').sslip.nutanixdemo.com"
  KOMMANDER_URL="https://${SSLIP_HOST}/dkp/kommander/dashboard"
  echo "  → Redirecting kommander.nkp.nuth-lab.xyz → ${KOMMANDER_URL}"
  TMPFILE=$(mktemp /tmp/kommander-domain-XXXXXX.yaml)
  sed "s|https://nkp-[0-9-]*\.sslip\.nutanixdemo\.com/dkp/kommander/dashboard|${KOMMANDER_URL}|g" \
    "${SCRIPT_DIR}/kommander/kommander-domain.yaml" > "${TMPFILE}"
  kubectl apply -f "${TMPFILE}"
  rm -f "${TMPFILE}"
fi
echo "  ✓ Kommander domain redirect applied"

# ──────────────────────────────────────────────
# Step 2: Shared workshop Dex user
# ──────────────────────────────────────────────
echo "[2] Shared workshop Dex user (workshop@nuth-lab.xyz)..."
kubectl apply -f "${SCRIPT_DIR}/kommander/workshop-dex-user.yaml"
echo "  ✓ Dex user + ClusterRoleBinding applied"
echo "  ℹ  Login: workshop@nuth-lab.xyz / NKP-Workshop-2026"
echo "  ℹ  To change password: regenerate bcrypt hash and update workshop-dex-user.yaml"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Management Cluster Init Complete!                  ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Kommander:  https://kommander.nkp.nuth-lab.xyz      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
