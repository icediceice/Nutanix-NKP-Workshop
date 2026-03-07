#!/bin/bash
# 01-workshop-env.sh — Shell profile for NKP Workshop sessions
# Loaded into every terminal in the participant's session.

# Convenient aliases
alias k=kubectl
alias kn='kubectl -n $SESSION_NS'
alias ko='kubectl -n $OPS_NS'
alias ka='kubectl -n argocd'

# switch-lab: wrapper around ArgoCD app patch for session-scoped app
switch-lab() {
  local OVERLAY="$1"
  if [ -z "$OVERLAY" ]; then
    echo "Usage: switch-lab <overlay-name>"
    echo "Examples: lab-01-start, lab-02-start, lab-03-canary-10, ..."
    return 1
  fi
  echo "Switching to overlay: $OVERLAY"
  kubectl -n argocd patch application "$ARGOCD_APP" --type merge \
    -p "{\"spec\":{\"source\":{\"path\":\"apps/storefront/overlays/${OVERLAY}\"}}}"
  kubectl -n argocd annotate application "$ARGOCD_APP" \
    argocd.argoproj.io/refresh=hard --overwrite
  echo "Waiting for sync..."
  kubectl -n argocd wait \
    --for=jsonpath='{.status.sync.status}'=Synced \
    application/"$ARGOCD_APP" \
    --timeout=120s 2>/dev/null && echo "Done: $OVERLAY" || echo "Sync timeout — check ArgoCD UI"
}
export -f switch-lab

# Custom prompt showing session namespace
export PS1='\[\033[01;32m\][nkp-workshop:$SESSION_NS]\[\033[00m\] \$ '

# Print workshop hints on session start
cat <<'HINTS'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  NKP Workshop — Session Ready
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Your namespace:   $SESSION_NS
  Ops namespace:    $OPS_NS
  ArgoCD app:       $ARGOCD_APP

  Useful commands:
    kn get pods         — list pods in your namespace
    ka get app $ARGOCD_APP — check ArgoCD sync status
    switch-lab <name>   — switch to a lab overlay
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HINTS
