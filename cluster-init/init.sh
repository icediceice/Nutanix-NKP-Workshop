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

  # ── Disable Traefik HTTP→HTTPS redirect (required for Educates HTTP mode) ──
  echo "  → Disabling Traefik HTTP→HTTPS redirect..."
  "${SCRIPT_DIR}/platform/disable-https-redirect.sh"

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

  # ── Publish workshop definitions before training portal so environments are created immediately ──
  echo "  → Publishing workshop definitions..."
  kubectl apply -f "${SCRIPT_DIR}/../k8s/cluster-reader-role.yaml" >/dev/null 2>&1 || true
  WORKSHOPS_DIR="${SCRIPT_DIR}/../workshops"
  for workshop_dir in "${WORKSHOPS_DIR}"/*/; do
    workshop_yaml="${workshop_dir}resources/workshop.yaml"
    [[ -f "${workshop_yaml}" ]] && kubectl apply -f "${workshop_yaml}" >/dev/null 2>&1
  done
  echo "  ✓ Workshop definitions published"

  # ── Wait for external DNS resolution before creating session pods ──
  # Reserved session pods run vendir at startup to pull workshop content from ghcr.io.
  # If DNS isn't ready, vendir fails → download-workshop.failed → "Workshop Failed" error.
  # Test from the session-manager pod (already running) before creating the portal.
  echo "  → Waiting for external DNS resolution (ghcr.io)..."
  SESSION_MGR_POD=$(kubectl get pods -n educates -l app=session-manager --no-headers 2>/dev/null | grep Running | awk '{print $1}' | head -1)
  DNS_READY=false
  for attempt in $(seq 1 18); do
    if [[ -n "${SESSION_MGR_POD}" ]] && \
       kubectl exec -n educates "${SESSION_MGR_POD}" -- python3 -c \
         "import socket; socket.setdefaulttimeout(5); socket.getaddrinfo('ghcr.io',443)" \
         >/dev/null 2>&1; then
      DNS_READY=true
      echo "  ✓ External DNS ready (ghcr.io resolves)"
      break
    fi
    [[ $attempt -eq 18 ]] && echo "  ⚠ External DNS not confirmed after 3m — proceeding anyway" || sleep 10
  done

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
    - cluster
    - world
EOF
        echo "  ✓ egress policy applied: ${ns}"
        break
      fi
      [[ $attempt -eq 30 ]] && echo "  ⚠ Namespace ${ns} not ready after 60s — skipping" || sleep 2
    done
  done

  # ── Reconcile missing WorkshopEnvironments ──
  # The TrainingPortal creates WorkshopEnvironments automatically, but if a workshop
  # definition was unavailable when the portal first reconciled (e.g. image not yet
  # pushed), the environment is never retried. Create any missing ones manually.
  PORTAL_NAME="nkp-workshop-portal"
  PORTAL_UID=$(kubectl get trainingportal "${PORTAL_NAME}" -o jsonpath='{.metadata.uid}' 2>/dev/null || echo "")
  INGRESS_DOMAIN_CFG=$(cfg educates_ingress_domain)
  INGRESS_CLASS_CFG=$(cfg educates_ingress_class 2>/dev/null || echo "kommander-traefik")
  [[ "${INGRESS_CLASS_CFG}" == "null" || -z "${INGRESS_CLASS_CFG}" ]] && INGRESS_CLASS_CFG="kommander-traefik"

  if [[ -n "${PORTAL_UID}" ]]; then
    echo "  → Reconciling WorkshopEnvironments..."
    idx=1
    for workshop_dir in "${WORKSHOPS_DIR}"/*/; do
      workshop_id=$(basename "${workshop_dir}")
      env_name=$(printf "${PORTAL_NAME}-w%02d" "${idx}")
      if ! kubectl get workshopenvironment "${env_name}" >/dev/null 2>&1; then
        echo "  ⚠ WorkshopEnvironment ${env_name} (${workshop_id}) missing — creating..."
        kubectl apply -f - <<EOF
apiVersion: training.educates.dev/v1beta1
kind: WorkshopEnvironment
metadata:
  name: ${env_name}
  labels:
    training.educates.dev/portal.name: ${PORTAL_NAME}
    training.educates.dev/portal.uid: ${PORTAL_UID}
    training.educates.dev/portal.workshop: ${workshop_id}
spec:
  analytics:
    amplitude:
      trackingId: ""
  cookies: {}
  environment:
    objects: []
    secrets: []
  request:
    enabled: false
  session:
    ingress:
      class: ${INGRESS_CLASS_CFG}
      domain: ${INGRESS_DOMAIN_CFG}
      secret: educates-wildcard-tls
  theme:
    name: default-website-theme
  workshop:
    name: ${workshop_id}
EOF
        echo "  ✓ Created WorkshopEnvironment ${env_name} (${workshop_id})"
      fi
      idx=$((idx + 1))
    done
    echo "  ✓ WorkshopEnvironment reconciliation complete"
  fi

  echo "  ✓ Educates ready"
  [[ "${EDUCATES_ONLY}" == "true" ]] && { echo "Done (educates-only)."; exit 0; }
fi

# ──────────────────────────────────────────────
# Step 4: Publish workshops
# ──────────────────────────────────────────────
if [[ "${APP_ONLY}" == "false" ]] || [[ "${WORKSHOPS_ONLY}" == "true" ]]; then
  echo "[4/6] Publishing workshops..."

  # Apply shared ClusterRole so session.objects bindings resolve on first session start
  echo "  → Applying cluster-reader ClusterRole..."
  kubectl apply -f "${SCRIPT_DIR}/../k8s/cluster-reader-role.yaml"

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

  # ── Apply apex redirect (nkp.nuth-lab.xyz → bls-workshop /create/) ──
  echo "  → Applying apex redirect..."
  kubectl apply -f "${SCRIPT_DIR}/educates/apex-redirect.yaml"
  echo "  ✓ Apex redirect applied"

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
# Wait for TrainingPortal .status.url to be populated (portal needs ~60s to initialise)
ADMIN_PASSWORD=$(cfg admin_password)
PORTAL_NAME=""
EDUCATES_PORTAL_URL=""
EDUCATES_ROBOT_CLIENT_ID=""
EDUCATES_ROBOT_CLIENT_SECRET=""
EDUCATES_ROBOT_USERNAME=""
EDUCATES_ROBOT_PASSWORD=""

echo "  → Waiting for TrainingPortal credentials to be ready..."
for attempt in $(seq 1 30); do
  PORTAL_NAME=$(kubectl get trainingportal -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
  if [[ -n "${PORTAL_NAME}" ]]; then
    EDUCATES_PORTAL_URL=$(kubectl get trainingportal "${PORTAL_NAME}" -o jsonpath='{.status.url}' 2>/dev/null || echo "")
    EDUCATES_ROBOT_CLIENT_ID=$(kubectl get trainingportal "${PORTAL_NAME}" -o jsonpath='{.status.clients.robot.id}' 2>/dev/null || echo "")
    if [[ -n "${EDUCATES_PORTAL_URL}" && -n "${EDUCATES_ROBOT_CLIENT_ID}" ]]; then
      EDUCATES_ROBOT_CLIENT_SECRET=$(kubectl get trainingportal "${PORTAL_NAME}" -o jsonpath='{.status.clients.robot.secret}' 2>/dev/null || echo "")
      EDUCATES_ROBOT_USERNAME=$(kubectl get trainingportal "${PORTAL_NAME}" -o jsonpath='{.status.credentials.robot.username}' 2>/dev/null || echo "")
      EDUCATES_ROBOT_PASSWORD=$(kubectl get trainingportal "${PORTAL_NAME}" -o jsonpath='{.status.credentials.robot.password}' 2>/dev/null || echo "")
      echo "  ✓ Educates robot credentials ready for portal '${PORTAL_NAME}'"
      break
    fi
  fi
  [[ $attempt -eq 30 ]] && echo "  ⚠ TrainingPortal credentials not ready after 60s — provision will fail" || sleep 2
done
CLUSTER_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
# Derive registration app URL from the first worker node IP + NodePort
FIRST_NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null || echo "")
REGISTRATION_NODEPORT=$(cfg registration_app_nodeport 2>/dev/null || echo "30080")
EDUCATES_INDEX_URL="http://${FIRST_NODE_IP}:${REGISTRATION_NODEPORT}"

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
  --from-literal=EDUCATES_INDEX_URL="${EDUCATES_INDEX_URL}" \
  --namespace=nkp-lab-manager \
  --dry-run=client -o yaml | kubectl apply -f -

# Kubeconfig secret for ClusterMonitor (reads cluster health from inside the pod)
kubectl create secret generic nkp-kubeconfigs \
  --from-file=workload01.conf="${KUBECONFIG}" \
  --namespace=nkp-lab-manager \
  --dry-run=client -o yaml | kubectl apply -f -
echo "  ✓ nkp-kubeconfigs secret created"

# CA cert ConfigMap — backend uses this for SSL verification against kommander-ca
if kubectl get secret kommander-ca -n cert-manager &>/dev/null; then
  kubectl get secret kommander-ca -n cert-manager \
    -o jsonpath='{.data.tls\.crt}' | base64 -d > /tmp/workshop-ca.crt
  kubectl create configmap workshop-ca-cert \
    --from-file=workshop-ca.crt=/tmp/workshop-ca.crt \
    --namespace=nkp-lab-manager \
    --dry-run=client -o yaml | kubectl apply -f -
  rm -f /tmp/workshop-ca.crt
  echo "  ✓ workshop-ca-cert ConfigMap created"
else
  echo "  ⚠ kommander-ca secret not found in cert-manager — workshop-ca-cert ConfigMap skipped (SSL verify will fall back to disabled)"
fi

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

# ── Apply Nutanix dark theme to Educates ──────
echo "  → Applying Nutanix dark theme..."
bash "${SCRIPT_DIR}/educates/update-theme.sh" "${KUBECONFIG_PATH}"
echo "  ✓ Theme applied"

# ──────────────────────────────────────────────
# Step 6: Verify and print access info
# ──────────────────────────────────────────────
echo "[6/6] Verification..."

# ── Repair any session pods that failed to download workshop content ──
# Vendir may fail on first start if DNS wasn't ready. Scan all reserved session pods for:
# 1. download-workshop.failed flag → re-run update-workshop (vendir + Hugo rebuild)
# 2. workshop renderer not started (ENABLE_WORKSHOP_PROCESS=false at container start)
#    → start via supervisorctl after content is ready
echo "  → Scanning session pods for content/renderer failures..."
REPAIR_COUNT=0
for ns in $(kubectl get ns --no-headers 2>/dev/null | awk '{print $1}' | grep "nkp-workshop-portal-w[0-9]*$"); do
  for pod in $(kubectl get pods -n "${ns}" --no-headers 2>/dev/null | grep -v registry | grep Running | awk '{print $1}'); do
    failed=$(kubectl exec -n "${ns}" "${pod}" -c workshop -- \
      bash -c "test -f /home/eduk8s/.local/share/workshop/download-workshop.failed && echo Y || echo N" \
      2>/dev/null || echo "N")
    renderer=$(kubectl exec -n "${ns}" "${pod}" -c workshop -- \
      bash -c "supervisorctl status workshop 2>/dev/null | awk '{print \$2}'" \
      2>/dev/null || echo "UNKNOWN")
    if [[ "${failed}" == "Y" || "${renderer}" != "RUNNING" ]]; then
      echo "  ⚠ Repairing ${ns}/${pod} (failed=${failed} renderer=${renderer})..."
      kubectl exec -n "${ns}" "${pod}" -c workshop -- bash -c "
        rm -f /home/eduk8s/.local/share/workshop/download-workshop.failed
        update-workshop >/tmp/update-workshop.log 2>&1
        supervisorctl start workshop 2>/dev/null || true
      " 2>/dev/null &
      REPAIR_COUNT=$((REPAIR_COUNT + 1))
    fi
  done
done
[[ $REPAIR_COUNT -gt 0 ]] && wait && echo "  ✓ Repaired ${REPAIR_COUNT} session(s)" || echo "  ✓ All sessions healthy"

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
