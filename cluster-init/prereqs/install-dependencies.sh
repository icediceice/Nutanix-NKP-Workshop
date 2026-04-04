#!/bin/bash
# install-dependencies.sh — Install required CLI tools
# Installs: kubectl, yq, educates CLI
# Run once on the machine that will execute init.sh

set -euo pipefail

OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
[[ "${ARCH}" == "x86_64" ]] && ARCH="amd64"
[[ "${ARCH}" == "aarch64" ]] && ARCH="arm64"

# Install to ~/.local/bin if /usr/local/bin is not writable
BIN_DIR="/usr/local/bin"
if [[ ! -w "${BIN_DIR}" ]]; then
  BIN_DIR="${HOME}/.local/bin"
  mkdir -p "${BIN_DIR}"
fi
export PATH="${HOME}/.local/bin:${PATH}"

echo "=== Installing Workshop Dependencies ==="
echo "OS: ${OS}, Arch: ${ARCH}, BIN_DIR: ${BIN_DIR}"
echo ""

# ── kubectl ──
if ! command -v kubectl >/dev/null 2>&1; then
  echo "Installing kubectl..."
  K8S_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
  curl -sLo "${BIN_DIR}/kubectl" "https://dl.k8s.io/release/${K8S_VERSION}/bin/${OS}/${ARCH}/kubectl"
  chmod +x "${BIN_DIR}/kubectl"
  echo "✓ kubectl installed (${K8S_VERSION})"
else
  echo "✓ kubectl already installed ($(kubectl version --client --short 2>/dev/null | head -1 || kubectl version --client 2>/dev/null | head -1))"
fi

# ── yq ──
if ! command -v yq >/dev/null 2>&1; then
  echo "Installing yq..."
  YQ_VERSION="v4.40.5"
  curl -sLo "${BIN_DIR}/yq" "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${OS}_${ARCH}"
  chmod +x "${BIN_DIR}/yq"
  echo "✓ yq installed"
else
  echo "✓ yq already installed ($(yq --version))"
fi

# ── Educates CLI ──
if ! command -v educates >/dev/null 2>&1; then
  echo "Installing Educates CLI..."
  EDUCATES_VERSION="3.7.0"
  # Note: educates releases use bare version tag (no v-prefix)
  curl -sLo "${BIN_DIR}/educates" "https://github.com/educates/educates-training-platform/releases/download/${EDUCATES_VERSION}/educates-${OS}-${ARCH}"
  chmod +x "${BIN_DIR}/educates"
  echo "✓ Educates CLI installed"
else
  echo "✓ Educates CLI already installed ($(educates version 2>/dev/null | head -1))"
fi

echo ""
echo "All dependencies satisfied."
