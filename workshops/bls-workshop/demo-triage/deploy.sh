#!/usr/bin/env bash
# Deploy the Cluster Triage AI app + broken demo pod onto workload01.
# Usage: ANTHROPIC_API_KEY=sk-ant-... ./deploy.sh
set -euo pipefail

KUBECONFIG="${KUBECONFIG:-$(dirname "$0")/../../../auth/workload01.conf}"
export KUBECONFIG

IMAGE="ghcr.io/icediceice/nkp-workshop-triage-app:latest"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S="$SCRIPT_DIR/k8s"

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  echo "ERROR: set ANTHROPIC_API_KEY before running this script"
  exit 1
fi

echo "▶ Namespace + RBAC"
kubectl apply -f "$K8S/namespace.yaml"
kubectl apply -f "$K8S/rbac.yaml"

echo "▶ API key secret"
kubectl create secret generic anthropic-key \
  --from-literal=api-key="$ANTHROPIC_API_KEY" \
  -n demo-triage \
  --dry-run=client -o yaml | kubectl apply -f -

echo "▶ Triage app"
kubectl apply -f "$K8S/deployment.yaml"
kubectl apply -f "$K8S/service.yaml"

echo "▶ Broken demo pod"
kubectl apply -f "$K8S/broken-demo.yaml"

echo ""
echo "▶ Waiting for triage-app to be ready…"
kubectl rollout status deployment/triage-app -n demo-triage --timeout=120s

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo ""
echo "✓ Ready!  Open: http://${NODE_IP}:30090"
echo "  The broken-demo pod should show ErrImagePull — hit 'AI Diagnose & Fix' to watch Claude fix it."
