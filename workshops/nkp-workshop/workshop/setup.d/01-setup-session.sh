#!/bin/bash
# 01-setup-session.sh — Per-session initialization for NKP Workshop
# Runs once when the participant's session starts.
# Note: do NOT use set -e here — Educates marks the session failed on any non-zero exit.

# ── Detect ingress IP from Traefik (NKP uses Traefik, not Istio) ──────────────
_detect_ingress_domain() {
  local ip=""
  # Try Traefik in kommander-default-workspace (NKP default)
  ip=$(kubectl -n kommander-default-workspace get svc \
    -l app.kubernetes.io/name=traefik \
    -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  # Fallback: any traefik service in any namespace
  if [ -z "$ip" ]; then
    ip=$(kubectl get svc -A \
      -l app.kubernetes.io/name=traefik \
      -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
  fi
  echo "${ip:-pending}"
}

# Use INGRESS_DOMAIN from Educates env if already set, else auto-detect
RESOLVED_INGRESS="${INGRESS_DOMAIN:-$(_detect_ingress_domain)}"

# ── Write session env vars ─────────────────────────────────────────────────────
cat >> "$WORKSHOP_ENV" <<EOF
export SESSION_NS=${SESSION_NAMESPACE}
export OPS_NS=${SESSION_NAME}-ops
export ARGOCD_APP=rx-demo-${SESSION_NAME}
export INGRESS_DOMAIN=${RESOLVED_INGRESS}
EOF

# ── Wait for ArgoCD Application (created by session.objects) ──────────────────
echo "Waiting for ArgoCD Application rx-demo-${SESSION_NAME}..."
_argocd_ready=false
for i in $(seq 1 12); do
  if kubectl -n argocd get application "rx-demo-${SESSION_NAME}" &>/dev/null; then
    _argocd_ready=true
    echo "ArgoCD Application ready."
    break
  fi
  echo "  Attempt $i/12 — waiting 5s..."
  sleep 5
done
if [ "$_argocd_ready" = false ]; then
  echo "Warning: ArgoCD Application not found after 60s — continuing anyway."
fi

# ── Copy exercise files to home directory ─────────────────────────────────────
cp -r /opt/workshop/exercises ~/exercises 2>/dev/null || true

echo "Session setup complete."
