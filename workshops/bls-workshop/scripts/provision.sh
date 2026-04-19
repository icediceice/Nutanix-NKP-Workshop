#!/bin/bash
# provision.sh — BLS Workshop: workload01 pre-provisioning
#
# Installs all prerequisites for the BLS Workshop onto workload01:
#   - Flux CD (GitOps engine for Lab 2)
#   - kube-prometheus-stack (Prometheus + Grafana + Alertmanager for Lab 4)
#   - Velero + MinIO (backup/restore for Lab 5)
#   - Lab namespaces
#
# Usage:
#   ./provision.sh                        Full install
#   ./provision.sh --flux-only            Flux CD only
#   ./provision.sh --monitoring-only      kube-prometheus-stack only
#   ./provision.sh --velero-only          Velero + MinIO only
#   ./provision.sh --check                Pre-flight connectivity check only
#
# Requirements: kubectl, helm, flux CLI in PATH. KUBECONFIG set to workload01.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
KUBECONFIG_PATH="${REPO_ROOT}/auth/workload01.conf"
export KUBECONFIG="${KUBECONFIG_PATH}"

FLUX_ONLY=false
MONITORING_ONLY=false
VELERO_ONLY=false
CHECK_ONLY=false

for arg in "$@"; do
  case $arg in
    --flux-only)       FLUX_ONLY=true ;;
    --monitoring-only) MONITORING_ONLY=true ;;
    --velero-only)     VELERO_ONLY=true ;;
    --check)           CHECK_ONLY=true ;;
  esac
done

# ── colours ──────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $*"; }
fail() { echo -e "${RED}  ✗${NC} $*"; exit 1; }
step() { echo -e "\n${YELLOW}[$*]${NC}"; }

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   BLS Workshop — workload01 Provisioning             ║"
echo "╚══════════════════════════════════════════════════════╝"
echo "KUBECONFIG: ${KUBECONFIG_PATH}"
echo ""

# ──────────────────────────────────────────────
# Pre-flight
# ──────────────────────────────────────────────
step "Pre-flight checks"

command -v kubectl >/dev/null 2>&1 || fail "kubectl not found in PATH"
command -v helm    >/dev/null 2>&1 || fail "helm not found in PATH"
ok "kubectl and helm found"

kubectl cluster-info --request-timeout=10s >/dev/null 2>&1 \
  || fail "Cannot reach workload01 API at $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
ok "workload01 reachable"

NODE_COUNT=$(kubectl get nodes --no-headers 2>/dev/null | wc -l | tr -d ' ')
ok "${NODE_COUNT} nodes in cluster"
kubectl get nodes --no-headers

if [[ "${CHECK_ONLY}" == "true" ]]; then
  echo ""
  ok "Pre-flight passed. Run without --check to provision."
  exit 0
fi

# ──────────────────────────────────────────────
# Step 1: Flux CD
# ──────────────────────────────────────────────
install_flux() {
  step "1/3  Flux CD"

  if kubectl get namespace flux-system >/dev/null 2>&1; then
    warn "flux-system namespace already exists — checking readiness"
    FLUX_READY=$(kubectl get pods -n flux-system --no-headers 2>/dev/null \
      | awk '{print $3}' | sort -u | tr '\n' ' ')
    ok "Flux pods status: ${FLUX_READY}"
    return
  fi

  command -v flux >/dev/null 2>&1 || {
    warn "flux CLI not found — installing via script"
    curl -s https://fluxcd.io/install.sh | bash
  }

  ok "Installing Flux CD via 'flux install'"
  flux install \
    --namespace=flux-system \
    --components=source-controller,kustomize-controller,helm-controller,notification-controller \
    --log-level=info \
    --wait

  ok "Flux CD installed"
  kubectl get pods -n flux-system
}

# ──────────────────────────────────────────────
# Step 2: kube-prometheus-stack
# ──────────────────────────────────────────────
install_monitoring() {
  step "2/3  kube-prometheus-stack (Prometheus + Grafana + Alertmanager)"

  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
  helm repo update prometheus-community >/dev/null

  if helm status kube-prometheus-stack -n monitoring >/dev/null 2>&1; then
    warn "kube-prometheus-stack already installed — skipping"
    return
  fi

  kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

  helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --set grafana.adminPassword=Workshop2024 \
    --set grafana.ingress.enabled=true \
    --set grafana.ingress.ingressClassName=nginx \
    --set grafana.ingress.hosts[0]=grafana.workload01.local \
    --set prometheus.prometheusSpec.retention=1d \
    --set alertmanager.alertmanagerSpec.retention=12h \
    --set nodeExporter.enabled=true \
    --set kubeStateMetrics.enabled=true \
    --timeout=10m \
    --wait

  ok "kube-prometheus-stack installed"
  kubectl get pods -n monitoring
}

# ──────────────────────────────────────────────
# Step 3: Velero + MinIO (in-cluster S3 backend)
# ──────────────────────────────────────────────
install_velero() {
  step "3/3  Velero + MinIO"

  helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts 2>/dev/null || true
  helm repo add minio https://charts.min.io/ 2>/dev/null || true
  helm repo update vmware-tanzu minio >/dev/null

  kubectl create namespace velero --dry-run=client -o yaml | kubectl apply -f -

  # Deploy MinIO as in-cluster S3 backend
  if ! helm status minio -n velero >/dev/null 2>&1; then
    ok "Installing MinIO (Velero storage backend)"
    helm install minio minio/minio \
      --namespace velero \
      --set rootUser=minio \
      --set rootPassword=minio123 \
      --set replicas=1 \
      --set persistence.size=10Gi \
      --set resources.requests.memory=256Mi \
      --set buckets[0].name=velero \
      --set buckets[0].policy=none \
      --set buckets[0].purge=false \
      --set service.type=ClusterIP \
      --timeout=5m \
      --wait
    ok "MinIO installed"
  else
    warn "MinIO already installed — skipping"
  fi

  MINIO_SVC=$(kubectl get svc minio -n velero -o jsonpath='{.spec.clusterIP}')

  # Deploy Velero pointing at MinIO
  if ! helm status velero -n velero >/dev/null 2>&1; then
    ok "Installing Velero"
    helm install velero vmware-tanzu/velero \
      --namespace velero \
      --set configuration.provider=aws \
      --set configuration.backupStorageLocation[0].name=default \
      --set configuration.backupStorageLocation[0].provider=aws \
      --set configuration.backupStorageLocation[0].bucket=velero \
      --set configuration.backupStorageLocation[0].config.region=minio \
      --set configuration.backupStorageLocation[0].config.s3ForcePathStyle=true \
      --set "configuration.backupStorageLocation[0].config.s3Url=http://${MINIO_SVC}:9000" \
      --set credentials.useSecret=true \
      --set credentials.secretContents.cloud="[default]\naws_access_key_id=minio\naws_secret_access_key=minio123" \
      --set initContainers[0].name=velero-plugin-for-aws \
      --set initContainers[0].image=velero/velero-plugin-for-aws:v1.8.0 \
      --set initContainers[0].volumeMounts[0].mountPath=/target \
      --set initContainers[0].volumeMounts[0].name=plugins \
      --set deployNodeAgent=true \
      --timeout=10m \
      --wait
    ok "Velero installed"
  else
    warn "Velero already installed — skipping"
  fi

  kubectl get pods -n velero
}

# ──────────────────────────────────────────────
# Step 4: Lab namespaces
# ──────────────────────────────────────────────
create_namespaces() {
  step "Lab namespaces"
  for ns in bls-app flux-system; do
    kubectl create namespace "${ns}" --dry-run=client -o yaml | kubectl apply -f -
    ok "namespace/${ns} ready"
  done
}

# ──────────────────────────────────────────────
# Run selected steps
# ──────────────────────────────────────────────
if [[ "${FLUX_ONLY}" == "true" ]]; then
  install_flux
elif [[ "${MONITORING_ONLY}" == "true" ]]; then
  install_monitoring
elif [[ "${VELERO_ONLY}" == "true" ]]; then
  install_velero
else
  install_flux
  install_monitoring
  install_velero
  create_namespaces
fi

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║   Provisioning Complete                               ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "Grafana:"
GRAFANA_SVC=$(kubectl get svc -n monitoring -l app.kubernetes.io/name=grafana \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "grafana")
echo "  kubectl port-forward svc/${GRAFANA_SVC} 3000:80 -n monitoring"
echo "  http://localhost:3000  (admin / Workshop2024)"
echo ""
echo "Flux:"
kubectl get gitrepositories -A 2>/dev/null || true
echo ""
echo "Velero:"
echo "  velero backup-location get"
echo ""
echo "Workshop content: https://light.factor-io.com/workshop/bls-workshop/"
echo ""
