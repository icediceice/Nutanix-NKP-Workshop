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

export PATH="${HOME}/.local/bin:${PATH}"

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

# NKP stores Traefik config in a ConfigMap referenced by valuesFrom, NOT in
# spec.values. Patching spec.values has no effect — must patch the ConfigMap.
CONFIG_CM="traefik-37.1.2-config-defaults"

# Check if redirect is already gone
REDIRECT=$(kubectl get helmrelease "${TRAEFIK_HR}" -n "${TRAEFIK_NS}" \
  -o jsonpath='{.spec.values.ports.web.redirectTo}' 2>/dev/null || echo "")

# Check ConfigMap for redirect args (real config location on NKP)
CM_HAS_REDIRECT=$(kubectl get cm "${CONFIG_CM}" -n "${TRAEFIK_NS}" \
  -o jsonpath='{.data.values\.yaml}' 2>/dev/null | \
  python3 -c "import sys; d=sys.stdin.read(); print('yes' if 'redirections' in d else 'no')" 2>/dev/null || echo "no")

if [[ "${CM_HAS_REDIRECT}" != "yes" && (-z "${REDIRECT}" || "${REDIRECT}" == "null") ]]; then
  ok "HTTP→HTTPS redirect already disabled — skipping"
  exit 0
fi

ok "Found redirect config — patching ConfigMap ${CONFIG_CM}..."

# Remove redirect lines from ConfigMap values.yaml
kubectl get cm "${CONFIG_CM}" -n "${TRAEFIK_NS}" \
  -o jsonpath='{.data.values\.yaml}' > /tmp/traefik-values.yaml

python3 -c "
with open('/tmp/traefik-values.yaml') as f:
    lines = f.readlines()
filtered = [l for l in lines if 'redirections' not in l and 'entryPoint.to=:443' not in l and 'entryPoint.scheme=https' not in l]
with open('/tmp/traefik-values-patched.yaml', 'w') as f:
    f.writelines(filtered)
print(f'Removed {len(lines)-len(filtered)} redirect lines')
"

kubectl create cm "${CONFIG_CM}" -n "${TRAEFIK_NS}" \
  --from-file=values.yaml=/tmp/traefik-values-patched.yaml \
  --dry-run=client -o yaml | kubectl apply --validate=false -f -
rm -f /tmp/traefik-values.yaml /tmp/traefik-values-patched.yaml

# Trigger Flux reconciliation to pick up ConfigMap changes
kubectl annotate helmrelease "${TRAEFIK_HR}" -n "${TRAEFIK_NS}" \
  reconcile.fluxcd.io/requestedAt="$(date -u +%Y-%m-%dT%H:%M:%SZ)" --overwrite 2>/dev/null || true

ok "Waiting for Traefik rollout..."
sleep 10

# Wait for Traefik pods to restart (NKP names it kommander-traefik)
kubectl rollout status deployment/kommander-traefik -n "${TRAEFIK_NS}" --timeout=120s 2>/dev/null || \
  kubectl rollout status deployment/traefik -n "${TRAEFIK_NS}" --timeout=120s 2>/dev/null || \
  warn "Could not confirm Traefik rollout — verify manually with: kubectl get pods -n ${TRAEFIK_NS}"

ok "Traefik HTTP→HTTPS redirect disabled. All ingresses now serve HTTP."
