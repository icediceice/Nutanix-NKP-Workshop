#!/bin/bash
# update-theme.sh — Apply Nutanix dark theme to the live Educates portal.
#
# Patches the default-website-theme Secret directly — NO platform redeploy,
# NO session disruption. Safe to run while workshops are in progress.
#
# Usage: ./update-theme.sh [kubeconfig] [portal-namespace]
#   kubeconfig        path to kubeconfig (default: ~/.kube/config)
#   portal-namespace  namespace of the training portal (default: nkp-workshop-portal-ui)

set -euo pipefail

KUBECONFIG="${1:-$HOME/.kube/config}"
PORTAL_NS="${2:-nkp-workshop-portal-ui}"
export KUBECONFIG

echo "Applying Nutanix dark theme to ${PORTAL_NS}..."

# ── Write CSS files to temp dir ──────────────────────────────────────────────
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "${TMP}/training-portal.html" << 'CSSEOF'
<style>
html, body { background-color: #090909 !important; color: #F0F0F0 !important; }
.navbar { border-bottom: 2px solid #7855FA !important; }
.card, .panel, .well { background-color: #111111 !important; border-color: #242424 !important; color: #F0F0F0 !important; }
.card-header, .card-footer, .panel-heading { background-color: #1A1A1A !important; border-color: #242424 !important; }
.card-body, .card-text { color: #F0F0F0 !important; }
.table, table { color: #F0F0F0 !important; }
.table thead th, th { background-color: #1A1A1A !important; border-color: #242424 !important; color: #1FDDE9 !important; }
.table td, td { border-color: #242424 !important; }
.table-striped tbody tr:nth-of-type(odd) { background-color: #111111 !important; }
.table-striped tbody tr:nth-of-type(even) { background-color: #0D0D0D !important; }
.table-hover tbody tr:hover { background-color: #1A1A1A !important; }
.btn-primary { background: linear-gradient(135deg, #4B00AA, #1FDDE9) !important; border: none !important; color: #fff !important; }
.btn-secondary, .btn-default, .btn-light { background-color: #1A1A1A !important; border-color: #242424 !important; color: #F0F0F0 !important; }
input, select, textarea, .form-control { background-color: #1A1A1A !important; border-color: #242424 !important; color: #F0F0F0 !important; }
.alert { background-color: #1A1A1A !important; border-color: #242424 !important; color: #F0F0F0 !important; }
.alert-info { border-left: 4px solid #1FDDE9 !important; }
.alert-warning { border-left: 4px solid #F5A623 !important; }
.alert-danger { border-left: 4px solid #E05252 !important; }
.alert-success { border-left: 4px solid #3DD68C !important; }
.bg-light, .bg-white { background-color: #111111 !important; }
.text-dark { color: #F0F0F0 !important; } .text-muted { color: #A0A0A0 !important; }
hr { border-color: #242424 !important; }
a { color: #1FDDE9; } a:hover { color: #7855FA; }
h1, h2, h3, h4, h5, h6 { color: #F0F0F0 !important; }
.modal-content { background-color: #111111 !important; border-color: #242424 !important; color: #F0F0F0 !important; }
.modal-header, .modal-footer { border-color: #242424 !important; }
.dropdown-menu { background-color: #111111 !important; border-color: #242424 !important; }
.dropdown-item { color: #F0F0F0 !important; } .dropdown-item:hover { background-color: #1A1A1A !important; }
.list-group-item { background-color: #111111 !important; border-color: #242424 !important; color: #F0F0F0 !important; }
.page-link { background-color: #111111 !important; border-color: #242424 !important; color: #1FDDE9 !important; }
.page-item.active .page-link { background-color: #7855FA !important; border-color: #7855FA !important; }
body::before { content: ''; display: block; height: 3px; background: linear-gradient(135deg, #4B00AA, #1FDDE9); position: fixed; top: 0; left: 0; right: 0; z-index: 9999; pointer-events: none; }
</style>
CSSEOF

cat > "${TMP}/workshop-dashboard.html" << 'CSSEOF'
<style>
html, body { background-color: #090909 !important; color: #F0F0F0 !important; }
header, .header, [class*="Header"], [class*="header"] { background-color: #0D0D0D !important; border-bottom: 1px solid #242424 !important; color: #F0F0F0 !important; }
[class*="Tab"], [class*="tab"], [role="tablist"] { background-color: #111111 !important; border-color: #242424 !important; }
[class*="Panel"], [class*="panel"], [class*="Frame"], [class*="Content"], .split-pane { background-color: #090909 !important; }
[class*="Sidebar"], [class*="sidebar"], nav, aside { background-color: #0D0D0D !important; border-color: #242424 !important; }
a { color: #1FDDE9; } a:hover { color: #7855FA; }
::-webkit-scrollbar { width: 6px; height: 6px; } ::-webkit-scrollbar-track { background: #111111; }
::-webkit-scrollbar-thumb { background: #333; border-radius: 3px; } ::-webkit-scrollbar-thumb:hover { background: #7855FA; }
body::before { content: ''; display: block; height: 3px; background: linear-gradient(135deg, #4B00AA, #1FDDE9); position: fixed; top: 0; left: 0; right: 0; z-index: 9999; pointer-events: none; }
</style>
CSSEOF

cat > "${TMP}/workshop-instructions.html" << 'CSSEOF'
<style>
html, body { background-color: #090909 !important; color: #F0F0F0 !important; font-family: 'Segoe UI', system-ui, sans-serif; }
h1, h2, h3, h4, h5, h6 { color: #F0F0F0 !important; }
h1, h2 { border-bottom: 1px solid #242424 !important; padding-bottom: 8px; }
a { color: #1FDDE9 !important; } a:hover { color: #7855FA !important; }
pre { background-color: #0D0D0D !important; border: 1px solid #242424 !important; border-radius: 6px !important; color: #F0F0F0 !important; padding: 16px !important; }
code { background-color: #1A1A1A !important; color: #1FDDE9 !important; border-radius: 3px !important; padding: 2px 5px !important; }
pre code { background: transparent !important; color: #F0F0F0 !important; padding: 0 !important; }
blockquote, .note, .warning, .tip, .info { background-color: #111111 !important; border-left: 4px solid #7855FA !important; color: #F0F0F0 !important; padding: 12px 16px !important; border-radius: 0 6px 6px 0; }
table { color: #F0F0F0 !important; border-collapse: collapse; width: 100%; }
th { background-color: #1A1A1A !important; color: #1FDDE9 !important; border: 1px solid #242424 !important; padding: 8px 12px; }
td { border: 1px solid #242424 !important; padding: 8px 12px; }
tr:nth-child(even) { background-color: #111111 !important; } tr:nth-child(odd) { background-color: #0D0D0D !important; }
.mermaid { background: #111111 !important; border-radius: 8px; padding: 16px; }
::-webkit-scrollbar { width: 6px; height: 6px; } ::-webkit-scrollbar-track { background: #111111; }
::-webkit-scrollbar-thumb { background: #333; border-radius: 3px; } ::-webkit-scrollbar-thumb:hover { background: #7855FA; }
body::before { content: ''; display: block; height: 3px; background: linear-gradient(135deg, #4B00AA, #1FDDE9); position: fixed; top: 0; left: 0; right: 0; z-index: 9999; pointer-events: none; }
</style>
CSSEOF

# ── Patch the theme Secret ────────────────────────────────────────────────────
kubectl create secret generic default-website-theme \
  -n "${PORTAL_NS}" \
  --from-literal=training-portal.css="" \
  --from-literal=training-portal.js="" \
  --from-literal=workshop-dashboard.css="" \
  --from-literal=workshop-dashboard.js="" \
  --from-literal=workshop-instructions.css="" \
  --from-literal=workshop-instructions.js="" \
  --from-literal=workshop-started.html="" \
  --from-literal=workshop-finished.html="" \
  --from-file=training-portal.html="${TMP}/training-portal.html" \
  --from-file=workshop-dashboard.html="${TMP}/workshop-dashboard.html" \
  --from-file=workshop-instructions.html="${TMP}/workshop-instructions.html" \
  --dry-run=client -o yaml | kubectl apply -f -

# ── Restart only the training portal (sessions unaffected) ───────────────────
kubectl rollout restart deployment/training-portal -n "${PORTAL_NS}"
kubectl rollout status deployment/training-portal -n "${PORTAL_NS}" --timeout=90s

echo "✓ Theme applied. Reload any open workshop tabs to see the change."
echo "  Note: active sessions keep their current OAuth2 tokens — no disruption."
