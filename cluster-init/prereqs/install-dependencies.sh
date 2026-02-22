#!/bin/bash
# install-dependencies.sh — Install required CLI tools
# Installs: kubectl, yq, educates CLI
# Run once on the machine that will execute init.sh

set -euo pipefail

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
[[ "${ARCH}" == "x86_64" ]] && ARCH="amd64"
[[ "${ARCH}" == "aarch64" ]] && ARCH="arm64"

echo "=== Installing Workshop Dependencies ==="
echo "OS: ${OS}, Arch: ${ARCH}"
echo ""

# ── yq ──
if ! command -v yq >/dev/null 2>&1; then
  echo "Installing yq..."
  YQ_VERSION="v4.40.5"
  curl -sL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${OS}_${ARCH}" -o /usr/local/bin/yq
  chmod +x /usr/local/bin/yq
  echo "✓ yq installed"
else
  echo "✓ yq already installed ($(yq --version))"
fi

# ── Educates CLI ──
if ! command -v educates >/dev/null 2>&1; then
  echo "Installing Educates CLI..."
  EDUCATES_VERSION="3.2.0"
  curl -sL "https://github.com/educates/educates-training-platform/releases/download/v${EDUCATES_VERSION}/educates-${OS}-${ARCH}" -o /usr/local/bin/educates
  chmod +x /usr/local/bin/educates
  echo "✓ Educates CLI installed"
else
  echo "✓ Educates CLI already installed ($(educates version 2>/dev/null | head -1))"
fi

echo ""
echo "All dependencies satisfied."
