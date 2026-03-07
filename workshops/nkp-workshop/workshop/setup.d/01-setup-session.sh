#!/bin/bash
# 01-setup-session.sh — Per-session initialization for NKP Workshop
# Runs once when the participant's session starts.
set -eo pipefail

# Write session-specific environment variables to the workshop env file
cat >> $WORKSHOP_ENV <<EOF
export SESSION_NS=$SESSION_NAMESPACE
export OPS_NS=${SESSION_NAME}-ops
export ARGOCD_APP=rx-demo-${SESSION_NAME}
export INGRESS_DOMAIN=${INGRESS_DOMAIN:-$(kubectl -n istio-helm-gateway-ns get svc istio-helm-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 'pending')}
EOF

# Wait for ArgoCD Application to be created by session.objects
echo "Waiting for ArgoCD Application rx-demo-${SESSION_NAME}..."
for i in $(seq 1 24); do
  if kubectl -n argocd get application "rx-demo-${SESSION_NAME}" &>/dev/null; then
    echo "ArgoCD Application ready."
    break
  fi
  echo "  Attempt $i/24 — waiting 5s..."
  sleep 5
done

# Copy exercise files to home directory for easy access
cp -r /opt/workshop/exercises ~/exercises 2>/dev/null || true

echo "Session setup complete."
