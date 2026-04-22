#!/bin/bash
# reload-image.sh — rebuild bls-workshop-files image, push, restart active sessions
#
# Usage:
#   ./reload-image.sh
#
# Requires: sudo (snap docker), gh CLI logged in, auth/workload01.conf + auth/nkp.conf

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
WORKSHOP_DIR="${REPO_ROOT}/workshops/bls-workshop"
IMAGE="ghcr.io/icediceice/bls-workshop-files:latest"
KUBECONFIG_MGMT="${REPO_ROOT}/auth/nkp.conf"
KUBECONFIG_WK="${REPO_ROOT}/auth/workload01.conf"
LOCKFILE="/tmp/.bls-reload.lock"
BUILD_DIR="${HOME}/ws-build-bls"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
info() { echo -e "${YELLOW}  →${NC} $*"; }
fail() { echo -e "${RED}  ✗${NC} $*"; exit 1; }

# ── Lock — only one reload at a time ──────────────────────────────────────────
exec 9>"${LOCKFILE}"
if ! flock -n 9; then
  fail "Another reload is already running (${LOCKFILE} held). Aborting."
fi
trap 'flock -u 9; rm -f "${LOCKFILE}"; rm -rf "${BUILD_DIR}"' EXIT

echo ""
echo "╔═══════════════════════════════════════════════════════╗"
echo "║   bls-workshop — image reload                         ║"
echo "╚═══════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Discover active workshop namespace ────────────────────────────────
info "Discovering active bls-workshop environment..."
ENV_NAME=$(kubectl --kubeconfig="${KUBECONFIG_MGMT}" get workshopenvironments \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.workshop.name}{"\n"}{end}' 2>/dev/null \
  | awk -F'\t' '$2=="bls-workshop"{print $1}' | head -1)

[[ -z "${ENV_NAME}" ]] && fail "No running bls-workshop WorkshopEnvironment found on management cluster."
ok "Environment: ${ENV_NAME}"

# ── Step 2: Build image ───────────────────────────────────────────────────────
info "Copying workshop files to build dir..."
rm -rf "${BUILD_DIR}"
cp -r "${WORKSHOP_DIR}" "${BUILD_DIR}"

info "Building image..."
sudo docker build \
  -f "${BUILD_DIR}/Dockerfile.files" \
  -t "${IMAGE}" \
  "${BUILD_DIR}/" 2>&1 | grep -E "^#[0-9]|DONE|ERROR|error" || true
ok "Image built"

# ── Step 3: Push image ────────────────────────────────────────────────────────
info "Logging in to ghcr.io..."
gh auth token | sudo docker login ghcr.io -u icediceice --password-stdin 2>&1 | grep -v "^$"

info "Pushing ${IMAGE}..."
sudo docker push "${IMAGE}" 2>&1 | tail -3
ok "Image pushed"

# ── Step 4: Restart sessions ──────────────────────────────────────────────────
info "Restarting deployments in namespace ${ENV_NAME}..."
kubectl --kubeconfig="${KUBECONFIG_WK}" rollout restart deployment \
  -n "${ENV_NAME}" 2>&1

# Wait for rollout
info "Waiting for rollout to complete..."
for deploy in $(kubectl --kubeconfig="${KUBECONFIG_WK}" get deployments \
  -n "${ENV_NAME}" --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null); do
  kubectl --kubeconfig="${KUBECONFIG_WK}" rollout status deployment/"${deploy}" \
    -n "${ENV_NAME}" --timeout=120s 2>&1 | tail -1
done

ok "All sessions restarted — new content is live."
echo ""
