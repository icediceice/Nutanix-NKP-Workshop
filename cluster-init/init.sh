#!/bin/bash
# init.sh — NKP Workshop Platform Initialization
#
# Usage:
#   ./init.sh                   Full initialization (all steps)
#   ./init.sh --platform-only   Platform setup only (StorageClass, MetalLB, ingress)
#   ./init.sh --educates-only   Install/verify Educates only
#   ./init.sh --app-only        Deploy registration app only
#   ./init.sh --workshops-only  Publish workshop definitions only
#   ./init.sh --teardown        Run teardown.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config.local.yaml"

# Fall back to config.yaml if local override doesn't exist
if [[ ! -f "${CONFIG_FILE}" ]]; then
  CONFIG_FILE="${SCRIPT_DIR}/config.yaml"
fi

# Ensure ~/.local/bin is in PATH (kubectl/yq may be installed there)
export PATH="${HOME}/.local/bin:${PATH}"

# Parse flags
PLATFORM_ONLY=false
EDUCATES_ONLY=false
APP_ONLY=false
WORKSHOPS_ONLY=false
TEARDOWN=false

for arg in "$@"; do
  case $arg in
    --platform-only)  PLATFORM_ONLY=true ;;
    --educates-only)  EDUCATES_ONLY=true ;;
    --app-only)       APP_ONLY=true ;;
    --workshops-only) WORKSHOPS_ONLY=true ;;
    --teardown)       TEARDOWN=true ;;
  esac
done

if [[ "${TEARDOWN}" == "true" ]]; then
  exec "${SCRIPT_DIR}/teardown.sh" "$@"
fi

# Helper: read a value from config YAML (requires yq)
cfg() {
  yq eval ".${1}" "${CONFIG_FILE}"
}

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   NKP Workshop Platform Initialization               ║"
echo "╚══════════════════════════════════════════════════════╝"
echo "Config: ${CONFIG_FILE}"
echo ""

# Export KUBECONFIG from config so all kubectl calls target the right cluster
KUBECONFIG_PATH=$(yq eval ".kubeconfig_path" "${CONFIG_FILE}")
if [[ -n "${KUBECONFIG_PATH}" && "${KUBECONFIG_PATH}" != "null" ]]; then
  # Resolve relative paths from SCRIPT_DIR
  if [[ "${KUBECONFIG_PATH}" != /* ]]; then
    KUBECONFIG_PATH="${SCRIPT_DIR}/${KUBECONFIG_PATH}"
  fi
  export KUBECONFIG="${KUBECONFIG_PATH}"
  echo "Cluster: $(yq eval '.cluster_context' "${CONFIG_FILE}") (${KUBECONFIG_PATH})"
  echo ""
fi

# ──────────────────────────────────────────────
# Step 1: Pre-flight checks
# ──────────────────────────────────────────────
if [[ "${EDUCATES_ONLY}" == "false" && "${APP_ONLY}" == "false" && "${WORKSHOPS_ONLY}" == "false" ]] || [[ "${PLATFORM_ONLY}" == "true" ]]; then
  echo "[1/6] Pre-flight checks..."
  "${SCRIPT_DIR}/prereqs/preflight-check.sh" "${CONFIG_FILE}"
fi

# ──────────────────────────────────────────────
# Step 2: Platform setup (idempotent)
# ──────────────────────────────────────────────
if [[ "${EDUCATES_ONLY}" == "false" && "${APP_ONLY}" == "false" && "${WORKSHOPS_ONLY}" == "false" ]] || [[ "${PLATFORM_ONLY}" == "true" ]]; then
  echo "[2/6] Platform setup..."

  STORAGE_CLASS=$(cfg storage_class)
  METALLB_RANGE=$(cfg metallb_ip_range)
  INGRESS_CLASS=$(cfg educates_ingress_class 2>/dev/null || echo "")
  [[ "${INGRESS_CLASS}" == "null" ]] && INGRESS_CLASS=""

  # ── StorageClass: only create if not already present ──
  echo "  → StorageClass '${STORAGE_CLASS}'..."
  if kubectl get storageclass "${STORAGE_CLASS}" >/dev/null 2>&1; then
    echo "  ✓ StorageClass '${STORAGE_CLASS}' already exists — skipping"
  else
    # Patch storage-class.yaml name to match config before applying
    yq eval ".metadata.name = \"${STORAGE_CLASS}\"" \
      "${SCRIPT_DIR}/platform/storage-class.yaml" | kubectl apply -f -
    echo "  ✓ StorageClass '${STORAGE_CLASS}' created"
  fi

  # ── MetalLB: add workshop IP pool (idempotent) ──
  echo "  → MetalLB pool (${METALLB_RANGE})..."
  # Check if any existing pool already contains the first IP of the configured range
  FIRST_IP=$(echo "${METALLB_RANGE}" | cut -d'-' -f1)
  if kubectl get ipaddresspools -n metallb-system -o json 2>/dev/null | \
      python3 -c "
import sys, json
data = json.load(sys.stdin)
for item in data.get('items', []):
  for addr in item.get('spec', {}).get('addresses', []):
    if '${FIRST_IP}' in addr or addr.startswith('${FIRST_IP}'):
      sys.exit(0)
sys.exit(1)
" 2>/dev/null; then
    echo "  ✓ IP range already in an existing MetalLB pool — skipping"
  elif kubectl get ipaddresspool workshop-pool -n metallb-system >/dev/null 2>&1; then
    echo "  ✓ workshop-pool already exists — skipping"
  else
    TMPFILE_POOL=$(mktemp /tmp/metallb-pool-XXXXXX.yaml)
    TMPFILE_ADV=$(mktemp /tmp/metallb-adv-XXXXXX.yaml)
    cat > "${TMPFILE_POOL}" <<EOPOOL
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: workshop-pool
  namespace: metallb-system
spec:
  addresses:
    - ${METALLB_RANGE}
EOPOOL
    cat > "${TMPFILE_ADV}" <<EOADV
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: workshop-l2
  namespace: metallb-system
spec:
  ipAddressPools:
    - workshop-pool
EOADV
    kubectl apply -f "${TMPFILE_POOL}" && kubectl apply -f "${TMPFILE_ADV}"
    rm -f "${TMPFILE_POOL}" "${TMPFILE_ADV}"
    echo "  ✓ MetalLB workshop-pool configured"
  fi

  # ── IngressClass: skip if one already exists for the same controller ──
  echo "  → IngressClass..."
  if [[ -n "${INGRESS_CLASS}" ]] && kubectl get ingressclass "${INGRESS_CLASS}" >/dev/null 2>&1; then
    echo "  ✓ IngressClass '${INGRESS_CLASS}' already exists — skipping"
  elif kubectl get ingressclass traefik >/dev/null 2>&1; then
    echo "  ✓ IngressClass 'traefik' already exists — skipping"
  else
    kubectl apply -f "${SCRIPT_DIR}/platform/ingress-config.yaml"
    echo "  ✓ IngressClass applied"
  fi

  echo "  ✓ Platform setup complete"
  [[ "${PLATFORM_ONLY}" == "true" ]] && { echo "Done (platform-only)."; exit 0; }
fi

# ──────────────────────────────────────────────
# Step 3: Install Educates
# ──────────────────────────────────────────────
if [[ "${APP_ONLY}" == "false" && "${WORKSHOPS_ONLY}" == "false" ]] || [[ "${EDUCATES_ONLY}" == "true" ]]; then
  echo "[3/6] Installing Educates..."
  "${SCRIPT_DIR}/educates/install-educates.sh" "${CONFIG_FILE}"

  # ── Scale Kyverno to 2 replicas + increase webhook timeout ──
  # NKP/Kyverno has 19+ ClusterPolicies. Creating all 8 workshop environments
  # simultaneously floods the admission webhook and causes context deadline exceeded
  # (pykube has a 10s read timeout). Two replicas and 25s webhook timeout prevents this.
  echo "  → Tuning Kyverno for Educates burst load..."
  kubectl scale deployment kyverno-admission-controller -n kyverno --replicas=2 >/dev/null 2>&1 || true
  kubectl rollout status deployment/kyverno-admission-controller -n kyverno --timeout=60s >/dev/null 2>&1 || true
  for vwc in $(kubectl get validatingwebhookconfiguration 2>/dev/null | grep kyverno | awk '{print $1}'); do
    kubectl patch validatingwebhookconfiguration "${vwc}" --type='json' \
      -p='[{"op":"replace","path":"/webhooks/0/timeoutSeconds","value":25}]' >/dev/null 2>&1 || true
  done
  echo "  ✓ Kyverno: 2 replicas, webhook timeout 25s"

  echo "  → Deploying Training Portal..."
  kubectl apply -f "${SCRIPT_DIR}/educates/training-portal.yaml"

  echo "  → Waiting for workshop environment namespaces..."
  for i in $(seq -w 01 09); do
    ns="nkp-workshop-portal-w${i}"
    for attempt in $(seq 1 30); do
      if kubectl get ns "${ns}" >/dev/null 2>&1; then
        kubectl apply -f - <<EOF
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-kube-apiserver
  namespace: ${ns}
spec:
  endpointSelector: {}
  egress:
  - toEntities:
    - kube-apiserver
EOF
        echo "  ✓ kube-apiserver egress allowed: ${ns}"
        break
      fi
      [[ $attempt -eq 30 ]] && echo "  ⚠ Namespace ${ns} not ready after 60s — skipping" || sleep 2
    done
  done

  echo "  ✓ Educates ready"
  [[ "${EDUCATES_ONLY}" == "true" ]] && { echo "Done (educates-only)."; exit 0; }
fi

# ──────────────────────────────────────────────
# Step 4: Publish workshops
# ──────────────────────────────────────────────
if [[ "${APP_ONLY}" == "false" ]] || [[ "${WORKSHOPS_ONLY}" == "true" ]]; then
  echo "[4/6] Publishing workshops..."

  WORKSHOPS_DIR="${SCRIPT_DIR}/../workshops"
  for workshop_dir in "${WORKSHOPS_DIR}"/*/; do
    workshop_id=$(basename "${workshop_dir}")
    workshop_yaml="${workshop_dir}resources/workshop.yaml"
    if [[ -f "${workshop_yaml}" ]]; then
      echo "  → Publishing ${workshop_id}..."
      kubectl apply -f "${workshop_yaml}"
    fi
  done

  echo "  ✓ Workshops published"
  [[ "${WORKSHOPS_ONLY}" == "true" ]] && { echo "Done (workshops-only)."; exit 0; }
fi

# ──────────────────────────────────────────────
# Step 5: Deploy Registration App
# ──────────────────────────────────────────────
echo "[5/6] Deploying Registration App..."

APP_DIR="${SCRIPT_DIR}/../registration-app"
kubectl apply -f "${APP_DIR}/k8s/namespace.yaml"
kubectl apply -f "${APP_DIR}/k8s/rbac.yaml"

# Create secrets from config + auto-extract Educates robot credentials
ADMIN_PASSWORD=$(cfg admin_password)
PORTAL_NAME=$(kubectl get trainingportal -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
EDUCATES_PORTAL_URL=""
EDUCATES_ROBOT_CLIENT_ID=""
EDUCATES_ROBOT_CLIENT_SECRET=""
EDUCATES_ROBOT_USERNAME=""
EDUCATES_ROBOT_PASSWORD=""
if [[ -n "${PORTAL_NAME}" ]]; then
  EDUCATES_PORTAL_URL=$(kubectl get trainingportal "${PORTAL_NAME}" -o jsonpath='{.status.url}' 2>/dev/null || echo "")
  EDUCATES_ROBOT_CLIENT_ID=$(kubectl get trainingportal "${PORTAL_NAME}" -o jsonpath='{.status.clients.robot.id}' 2>/dev/null || echo "")
  EDUCATES_ROBOT_CLIENT_SECRET=$(kubectl get trainingportal "${PORTAL_NAME}" -o jsonpath='{.status.clients.robot.secret}' 2>/dev/null || echo "")
  EDUCATES_ROBOT_USERNAME=$(kubectl get trainingportal "${PORTAL_NAME}" -o jsonpath='{.status.credentials.robot.username}' 2>/dev/null || echo "")
  EDUCATES_ROBOT_PASSWORD=$(kubectl get trainingportal "${PORTAL_NAME}" -o jsonpath='{.status.credentials.robot.password}' 2>/dev/null || echo "")
  echo "  ✓ Educates robot credentials extracted for portal '${PORTAL_NAME}'"
else
  echo "  ⚠ No TrainingPortal found — Educates credentials will be empty (provision will fail)"
fi
CLUSTER_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
kubectl create secret generic nkp-lab-manager-secrets \
  --from-literal=ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
  --from-literal=DRY_RUN=false \
  --from-literal=DATABASE_URL=sqlite:///data/lab-manager.db \
  --from-literal=CLUSTER_CONTEXT="${CLUSTER_CONTEXT}" \
  --from-literal=EDUCATES_PORTAL_URL="${EDUCATES_PORTAL_URL}" \
  --from-literal=EDUCATES_ROBOT_CLIENT_ID="${EDUCATES_ROBOT_CLIENT_ID}" \
  --from-literal=EDUCATES_ROBOT_CLIENT_SECRET="${EDUCATES_ROBOT_CLIENT_SECRET}" \
  --from-literal=EDUCATES_ROBOT_USERNAME="${EDUCATES_ROBOT_USERNAME}" \
  --from-literal=EDUCATES_ROBOT_PASSWORD="${EDUCATES_ROBOT_PASSWORD}" \
  --namespace=nkp-lab-manager \
  --dry-run=client -o yaml | kubectl apply -f -

# Kubeconfig secret for ClusterMonitor (reads cluster health from inside the pod)
kubectl create secret generic nkp-kubeconfigs \
  --from-file=workload01.conf="${KUBECONFIG}" \
  --namespace=nkp-lab-manager \
  --dry-run=client -o yaml | kubectl apply -f -
echo "  ✓ nkp-kubeconfigs secret created"

# Create ConfigMap from courses.yaml
kubectl create configmap nkp-lab-manager-courses \
  --from-file=courses.yaml="${SCRIPT_DIR}/../courses.yaml" \
  --namespace=nkp-lab-manager \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f "${APP_DIR}/k8s/deployment.yaml"
kubectl apply -f "${APP_DIR}/k8s/service.yaml"

echo "  → Waiting for backend to be ready..."
kubectl rollout status deployment/nkp-lab-manager-backend -n nkp-lab-manager --timeout=120s

echo "  ✓ Registration app deployed"

# ──────────────────────────────────────────────
# Step 6: Verify and print access info
# ──────────────────────────────────────────────
echo "[6/6] Verification..."

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null || \
          kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
NODEPORT=$(cfg registration_app_nodeport)
INGRESS_DOMAIN=$(cfg ingress_domain)

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Workshop Platform Ready!                           ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Registration URL (NodePort):                        ║"
echo "║    http://${NODE_IP}:${NODEPORT}                     "
echo "║                                                      ║"
echo "║  Admin Panel:                                        ║"
echo "║    http://${NODE_IP}:${NODEPORT}/admin               "
echo "║                                                      ║"
echo "║  Educates Portal:                                    ║"
echo "║    https://$(cfg educates_ingress_domain)            "
echo "╚══════════════════════════════════════════════════════╝"
echo ""
