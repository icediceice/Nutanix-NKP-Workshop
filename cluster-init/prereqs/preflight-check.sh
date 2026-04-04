#!/bin/bash
# preflight-check.sh — Verify cluster is ready for workshop initialization
#
# Usage: ./preflight-check.sh [config.yaml]

set -euo pipefail

CONFIG_FILE="${1:-$(dirname "$0")/../config.yaml}"
ERRORS=0

cfg() { yq eval ".${1}" "${CONFIG_FILE}"; }

pass() { echo "  ✓ $1"; }
fail() { echo "  ✗ $1"; ERRORS=$((ERRORS + 1)); }
warn() { echo "  ⚠ $1"; }

echo ""
echo "=== Pre-flight Checks ==="
echo ""

# ── kubectl connectivity ──
echo "1. Cluster connectivity"
if kubectl get nodes >/dev/null 2>&1; then
  CONTEXT=$(kubectl config current-context 2>/dev/null || echo "unknown")
  pass "kubectl connected (context: ${CONTEXT})"
else
  fail "kubectl not connected or cluster unreachable"
fi

# ── Nodes ready ──
echo "2. Node readiness"
TOTAL=$(kubectl get nodes --no-headers 2>/dev/null | wc -l)
READY=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || true)
if [[ "${READY}" -gt 0 ]]; then
  pass "${READY}/${TOTAL} nodes Ready"
else
  fail "No nodes in Ready state"
fi

# ── Nutanix CSI ──
echo "3. Nutanix CSI StorageClass"
STORAGE_CLASS=$(cfg storage_class)
if kubectl get storageclass "${STORAGE_CLASS}" >/dev/null 2>&1; then
  pass "StorageClass '${STORAGE_CLASS}' exists"
else
  warn "StorageClass '${STORAGE_CLASS}' not found — will attempt to create"
fi

# ── Ingress controller ──
echo "4. Ingress controller"
if kubectl get pods -A -l "app.kubernetes.io/name=traefik" --no-headers 2>/dev/null | grep -q Running; then
  pass "Traefik ingress controller running"
elif kubectl get pods -A -l "app.kubernetes.io/name=ingress-nginx" --no-headers 2>/dev/null | grep -q Running; then
  pass "NGINX ingress controller running"
else
  warn "No ingress controller detected — check ingress setup"
fi

# ── MetalLB ──
echo "5. MetalLB"
if kubectl get ns metallb-system >/dev/null 2>&1 && kubectl get pods -n metallb-system --no-headers 2>/dev/null | grep -q Running; then
  pass "MetalLB running"
else
  warn "MetalLB not detected — external LoadBalancer IPs may not work"
fi

# ── Required tools ──
echo "6. Required tools"
for tool in kubectl yq; do
  if command -v "${tool}" >/dev/null 2>&1; then
    pass "${tool} available"
  else
    fail "${tool} not found — run: cluster-init/prereqs/install-dependencies.sh"
  fi
done
# docker is optional on the bootstrap machine
if command -v docker >/dev/null 2>&1; then
  pass "docker available (optional)"
else
  warn "docker not found — not required for bootstrap, but needed for local image builds"
fi

# ── educates CLI ──
echo "7. Educates CLI"
if command -v educates >/dev/null 2>&1; then
  EDUCATES_VERSION=$(educates version 2>/dev/null | head -1 || echo "unknown")
  pass "educates CLI available (${EDUCATES_VERSION})"
else
  warn "educates CLI not found — install-educates.sh will download it"
fi

# ── Summary ──
echo ""
if [[ "${ERRORS}" -gt 0 ]]; then
  echo "Pre-flight FAILED: ${ERRORS} error(s). Resolve them before proceeding."
  exit 1
else
  echo "Pre-flight passed. Cluster is ready for initialization."
fi
