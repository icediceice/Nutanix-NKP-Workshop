#!/bin/bash
# switch-lab.sh — Switch the ArgoCD Application to a different overlay
# Usage: ./scripts/switch-lab.sh <overlay-name>
# Example: ./scripts/switch-lab.sh lab-03-canary-10
set -eo pipefail

OVERLAY="$1"
ARGOCD_APP="${ARGOCD_APP:-rx-demo}"

if [ -z "$OVERLAY" ]; then
  echo "Usage: $0 <overlay-name>"
  echo ""
  echo "Available overlays:"
  ls "$(dirname "$0")/../apps/storefront/overlays/" | sort
  exit 1
fi

OVERLAY_PATH="workshops/nkp-workshop/apps/storefront/overlays/${OVERLAY}"
if [ ! -d "$(dirname "$0")/../${OVERLAY_PATH}" ]; then
  echo "Error: Overlay '$OVERLAY' not found at ${OVERLAY_PATH}"
  exit 1
fi

echo "Switching to overlay: $OVERLAY"
kubectl -n argocd patch application "${ARGOCD_APP}" --type merge \
  -p "{\"spec\":{\"source\":{\"path\":\"${OVERLAY_PATH}\"}}}"
kubectl -n argocd annotate application "${ARGOCD_APP}" \
  argocd.argoproj.io/refresh=hard --overwrite

echo "Waiting for sync..."
kubectl -n argocd wait --for=jsonpath='{.status.sync.status}'=Synced \
  application/"${ARGOCD_APP}" --timeout=120s 2>/dev/null || true

echo ""
echo "Status:"
kubectl -n argocd get application "${ARGOCD_APP}" -o wide
