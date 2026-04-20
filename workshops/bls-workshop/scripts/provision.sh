#!/bin/bash
# provision.sh — BLS Workshop: workload01 pre-flight + lab setup
#
# NKP Kommander already manages the full platform stack on workload clusters:
#   - Flux CD          → kommander-flux namespace
#   - Prometheus/Grafana/Alertmanager → kommander-default-workspace
#   - Velero/NDK       → available via NKP Platform Catalog
#   - Nutanix CSI      → pre-installed
#
# This script verifies those components are healthy and creates the
# lab-specific namespaces participants need for the workshop.
#
# Usage:
#   ./provision.sh           Full verify + setup
#   ./provision.sh --check   Connectivity check only

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
KUBECONFIG_PATH="${REPO_ROOT}/auth/workload01.conf"
export KUBECONFIG="${KUBECONFIG_PATH}"

CHECK_ONLY=false
[[ "${1:-}" == "--check" ]] && CHECK_ONLY=true

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $*"; }
fail() { echo -e "${RED}  ✗${NC} $*"; exit 1; }
step() { echo -e "\n${YELLOW}[$*]${NC}"; }

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   BLS Workshop — workload01 Pre-flight & Setup       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo "KUBECONFIG: ${KUBECONFIG_PATH}"
echo ""

# ──────────────────────────────────────────────
# Pre-flight
# ──────────────────────────────────────────────
step "Pre-flight checks"

command -v kubectl >/dev/null 2>&1 || fail "kubectl not found in PATH"
ok "kubectl found"

kubectl cluster-info --request-timeout=10s >/dev/null 2>&1 \
  || fail "Cannot reach workload01 API at $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
ok "workload01 reachable"

NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
ok "${NODE_COUNT} nodes in cluster"
kubectl get nodes --no-headers

[[ "${CHECK_ONLY}" == "true" ]] && { echo ""; ok "Pre-flight passed."; exit 0; }

# ──────────────────────────────────────────────
# Step 1: Verify Flux (managed by Kommander)
# ──────────────────────────────────────────────
step "1/3  Flux CD (Kommander-managed)"

FLUX_RUNNING=$(kubectl get pods -n kommander-flux --no-headers 2>/dev/null \
  | awk '$3=="Running"{c++}END{print c+0}')
if [[ "${FLUX_RUNNING:-0}" -ge 4 ]]; then
  ok "Flux running in kommander-flux (${FLUX_RUNNING} pods)"
else
  warn "Flux pods in kommander-flux: ${FLUX_RUNNING} running — check Kommander UI"
fi

# ──────────────────────────────────────────────
# Step 2: Verify Observability (managed by Kommander)
# ──────────────────────────────────────────────
step "2/3  Observability stack (Kommander-managed)"

for COMPONENT in kube-prometheus-stack-grafana kube-prometheus-stack-operator; do
  READY=$(kubectl get deployment "${COMPONENT}" -n kommander-default-workspace \
    --no-headers 2>/dev/null | awk '{print $2}')
  if [[ -n "${READY}" ]]; then
    ok "${COMPONENT}: ${READY}"
  else
    warn "${COMPONENT} not found in kommander-default-workspace"
    warn "Enable via Kommander UI: Clusters → workload01 → Applications → Grafana / Prometheus"
  fi
done

# ──────────────────────────────────────────────
# Step 3: Velero (via NKP Platform Catalog on management cluster)
# ──────────────────────────────────────────────
step "3/4  Velero backup (NKP Platform Catalog)"

# Check if Velero is already running on workload01
VELERO_RUNNING=$(kubectl get pods -n velero --no-headers 2>/dev/null \
  | awk '$3=="Running"{c++}END{print c+0}')

if [[ "${VELERO_RUNNING:-0}" -ge 1 ]]; then
  ok "Velero already running on workload01 (${VELERO_RUNNING} pods)"
else
  warn "Velero not yet enabled on workload01"
  echo "  → Enabling Velero via NKP Platform Catalog..."

  # Enable Velero on workload01 via the management cluster Kommander API
  # This creates an AppDeployment that Flux reconciles onto the workload cluster
  MGMT_KUBECONFIG="${REPO_ROOT}/auth/nkp.conf"

  # Get the workload01 cluster ID from Kommander
  WK01_CLUSTER_ID=$(KUBECONFIG="${MGMT_KUBECONFIG}" kubectl get cluster workload01 \
    -n kommander --no-headers -o jsonpath='{.metadata.name}' 2>/dev/null || echo "")

  if [[ -n "${WK01_CLUSTER_ID}" ]]; then
    # Apply AppDeployment to enable Velero on workload01
    KUBECONFIG="${MGMT_KUBECONFIG}" kubectl apply -f - <<EOF
apiVersion: apps.kommander.d2iq.io/v1alpha2
kind: AppDeployment
metadata:
  name: velero
  namespace: ${WK01_CLUSTER_ID}
spec:
  appRef:
    name: velero
    kind: ClusterApp
EOF
    ok "Velero AppDeployment applied — Flux will reconcile within 2-3 min"
    warn "Verify: KUBECONFIG=auth/workload01.conf kubectl get pods -n velero"
  else
    warn "Could not find workload01 cluster in Kommander — enable Velero manually:"
    warn "  Kommander UI → Clusters → workload01 → Applications → Velero → Enable"
  fi
fi

# ──────────────────────────────────────────────
# Step 4: Create lab namespaces
# ──────────────────────────────────────────────
step "4/4  Lab namespaces"

for ns in bls-app bls-gitops; do
  kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f -
  ok "namespace/${ns} ready"
done

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Setup Complete                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Kommander management cluster: https://10.38.49.15"
echo ""
echo "Platform services on workload01 (via Kommander UI):"
echo "  Grafana    → Clusters → workload01 → Applications → Grafana"
echo "  Prometheus → Clusters → workload01 → Applications → Prometheus"
echo "  Velero     → Enabled via NKP Platform Catalog (check: kubectl get pods -n velero)"
echo ""
echo "Lab namespaces created: bls-app, bls-gitops"
echo "Workshop content: http://light.factor-io.com/workshop/bls-workshop/"
echo ""
