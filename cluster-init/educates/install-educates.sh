#!/bin/bash
# install-educates.sh — Install Educates Training Platform on the NKP cluster
#
# Usage: ./install-educates.sh [config.yaml]
# Reference: https://docs.educates.dev/en/stable/installation-guides/cli-based-installation.html

set -euo pipefail

CONFIG_FILE="${1:-$(dirname "$0")/../config.yaml}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export PATH="${HOME}/.local/bin:${PATH}"

cfg() { yq eval ".${1}" "${CONFIG_FILE}"; }

EDUCATES_VERSION=$(cfg educates_version)
INGRESS_DOMAIN=$(cfg educates_ingress_domain)
STORAGE_CLASS=$(cfg storage_class)
POLICY_ENGINE=$(cfg educates_policy_engine)
INGRESS_CLASS=$(cfg educates_ingress_class 2>/dev/null || echo "")
[[ "${INGRESS_CLASS}" == "null" ]] && INGRESS_CLASS=""
INFRA_PROVIDER=$(cfg educates_infra_provider 2>/dev/null || echo "generic")
[[ "${INFRA_PROVIDER}" == "null" || -z "${INFRA_PROVIDER}" ]] && INFRA_PROVIDER="generic"

echo "=== Installing Educates v${EDUCATES_VERSION} ==="
echo "  Domain:        ${INGRESS_DOMAIN}"
echo "  Storage:       ${STORAGE_CLASS}"
echo "  Policy engine: ${POLICY_ENGINE}"
echo ""

# ── Ensure educates CLI is available ──
if ! command -v educates >/dev/null 2>&1; then
  echo "Educates CLI not found. Running install-dependencies.sh..."
  "${SCRIPT_DIR}/../prereqs/install-dependencies.sh"
fi

# ── Generate runtime educates-config.yaml from template ──
RUNTIME_CONFIG=$(mktemp /tmp/educates-config-XXXXXX.yaml)
cat > "${RUNTIME_CONFIG}" <<EOF
clusterInfrastructure:
  provider: ${INFRA_PROVIDER}

clusterIngress:
  domain: ${INGRESS_DOMAIN}
$(if [[ -n "${INGRESS_CLASS}" ]]; then echo "  class: ${INGRESS_CLASS}"; fi)
clusterStorage:
  class: ${STORAGE_CLASS}

clusterSecurity:
  policyEngine: ${POLICY_ENGINE}
EOF

# ── Deploy Educates platform ──
echo "Deploying Educates platform (this may take 2–5 minutes)..."
educates admin platform deploy \
  --config "${RUNTIME_CONFIG}" \
  --version "${EDUCATES_VERSION}" \
  --skip-image-resolution

rm -f "${RUNTIME_CONFIG}"

# ── Verify (v3.7+: secrets-manager + session-manager replace educates-operator) ──
echo "Verifying Educates components..."
kubectl rollout status deployment/secrets-manager -n educates --timeout=180s
kubectl rollout status deployment/session-manager -n educates --timeout=180s

echo ""
echo "✓ Educates installed and running."
echo "  Portal will be available at: https://training.${INGRESS_DOMAIN}"
echo "  (after training-portal.yaml is applied)"
