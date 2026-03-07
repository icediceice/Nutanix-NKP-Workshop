#!/bin/bash
# print-access.sh — Print all workshop access URLs
set -eo pipefail

echo "=== Workshop Access URLs ==="
echo ""

# Storefront IP (from Istio ingress)
INGRESS_IP=$(kubectl -n istio-helm-gateway-ns get svc istio-helm-ingressgateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "<pending>")
echo "Storefront:    http://${INGRESS_IP}"

# Demo Wall
DEMOWALL_IP=$(kubectl -n demo-ops get svc demo-wall \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "<pending>")
echo "Demo Wall:     http://${DEMOWALL_IP}:9090"

# NKP base URL (from Kommander)
NKP_URL=$(kubectl -n kommander get svc kommander-ingress-nginx-controller \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "<nkp-base-url>")

echo ""
echo "=== NKP Platform UIs (SSO) ==="
echo "NKP Console:   https://${NKP_URL}/dkp/kommander/dashboard"
echo "ArgoCD:        https://${NKP_URL}/dkp/argocd"
echo "Kiali:         https://${NKP_URL}/dkp/kiali"
echo "Jaeger:        https://${NKP_URL}/dkp/jaeger"
echo "Grafana:       https://${NKP_URL}/dkp/logging/grafana"
echo ""
echo "Current ArgoCD sync status:"
kubectl -n argocd get application "${ARGOCD_APP:-rx-demo}" -o wide 2>/dev/null || true
