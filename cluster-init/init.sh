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

  STORAGE_CLASS=$(cfg kubeconfig_path)
  echo "  → Verifying StorageClass..."
  kubectl apply -f "${SCRIPT_DIR}/platform/storage-class.yaml"

  echo "  → Applying MetalLB config..."
  kubectl apply -f "${SCRIPT_DIR}/platform/metallb-config.yaml"

  echo "  → Applying ingress config..."
  kubectl apply -f "${SCRIPT_DIR}/platform/ingress-config.yaml"

  echo "  ✓ Platform setup complete"
  [[ "${PLATFORM_ONLY}" == "true" ]] && { echo "Done (platform-only)."; exit 0; }
fi

# ──────────────────────────────────────────────
# Step 3: Install Educates
# ──────────────────────────────────────────────
if [[ "${APP_ONLY}" == "false" && "${WORKSHOPS_ONLY}" == "false" ]] || [[ "${EDUCATES_ONLY}" == "true" ]]; then
  echo "[3/6] Installing Educates..."
  "${SCRIPT_DIR}/educates/install-educates.sh" "${CONFIG_FILE}"

  echo "  → Deploying Training Portal..."
  kubectl apply -f "${SCRIPT_DIR}/educates/training-portal.yaml"

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

# Create secrets from config
ADMIN_PASSWORD=$(cfg admin_password)
kubectl create secret generic nkp-lab-manager-secrets \
  --from-literal=ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
  --from-literal=DRY_RUN=false \
  --from-literal=DATABASE_URL=sqlite:///data/lab-manager.db \
  --namespace=nkp-lab-manager \
  --dry-run=client -o yaml | kubectl apply -f -

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
