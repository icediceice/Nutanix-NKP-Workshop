#!/bin/bash
# disable-https-redirect.sh — Remove Traefik HTTP→HTTPS global redirect
#
# NKP ships Traefik with a global web→websecure redirect. This breaks Educates
# sessions on internal-network workshop clusters where the kommander-ca cert is
# self-signed and participants cannot install it.
#
# This script patches the Traefik HelmRelease to remove the redirect, letting
# Educates run over plain HTTP with zero cert friction.
# Safe to run on a dedicated workshop cluster — do NOT run on production.

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
warn() { echo -e "${YELLOW}  ⚠${NC} $*"; }

# Traefik HelmRelease — NKP places it in 'kommander' namespace
TRAEFIK_HR="traefik"
TRAEFIK_NS=""

echo "  → Locating Traefik HelmRelease..."

for ns in kommander kommander-default-workspace kube-system; do
  if kubectl get helmrelease "${TRAEFIK_HR}" -n "${ns}" >/dev/null 2>&1; then
    TRAEFIK_NS="${ns}"
    break
  fi
done

if [[ -z "${TRAEFIK_NS}" ]]; then
  warn "Traefik HelmRelease not found in any known namespace — skipping HTTP redirect patch"
  warn "Manually remove ports.web.redirectTo from the Traefik HelmRelease to enable HTTP mode."
  exit 0
fi

ok "Found traefik HelmRelease in namespace: ${TRAEFIK_NS}"

# Check if redirect is already gone
REDIRECT=$(kubectl get helmrelease "${TRAEFIK_HR}" -n "${TRAEFIK_NS}" \
  -o jsonpath='{.spec.values.ports.web.redirectTo}' 2>/dev/null || echo "")

if [[ -z "${REDIRECT}" || "${REDIRECT}" == "null" ]]; then
  ok "HTTP→HTTPS redirect already disabled — skipping"
  exit 0
fi

ok "Found redirect config: ${REDIRECT}"
echo "  → Patching Traefik HelmRelease to remove HTTP→HTTPS redirect..."

# Patch: set redirectTo to null (merge patch, idempotent)
kubectl patch helmrelease "${TRAEFIK_HR}" -n "${TRAEFIK_NS}" \
  --type=merge \
  -p '{
    "spec": {
      "values": {
        "ports": {
          "web": {
            "redirectTo": null
          }
        }
      }
    }
  }'

ok "HelmRelease patched — waiting for Traefik rollout..."

# Wait for Flux to reconcile the HelmRelease
sleep 5
kubectl wait helmrelease "${TRAEFIK_HR}" -n "${TRAEFIK_NS}" \
  --for=condition=Ready --timeout=120s 2>/dev/null || \
  warn "HelmRelease not Ready within 120s — Traefik may still be rolling out. Continue."

# Wait for Traefik pods to restart
kubectl rollout status deployment/traefik -n "${TRAEFIK_NS}" --timeout=120s 2>/dev/null || \
  kubectl rollout status daemonset/traefik -n "${TRAEFIK_NS}" --timeout=120s 2>/dev/null || \
  warn "Could not confirm Traefik rollout — verify manually."

ok "Traefik HTTP→HTTPS redirect disabled. All ingresses now serve HTTP."
