#!/bin/bash
# update-theme.sh — Apply Nutanix dark theme to the live Educates platform.
#
# Theme architecture:
#   educates/default-website-theme   — source secret, SecretCopier syncs it to
#                                      every session namespace automatically
#   nkp-workshop-portal-ui/default-website-theme — training portal catalog UI
#
# NO platform redeploy, NO session disruption. Safe to run mid-workshop.
#
# Usage: ./update-theme.sh [kubeconfig]

set -euo pipefail

KUBECONFIG="${1:-$HOME/.kube/config}"
PORTAL_NS="nkp-workshop-portal-ui"
export KUBECONFIG

echo "Applying Nutanix dark theme..."

# ── Write CSS files to temp dir ──────────────────────────────────────────────
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

cat > "${TMP}/training-portal.html" << 'CSSEOF'
<style>
html, body { background-color: #0D0D0D !important; color: #F0F0F0 !important; }
.navbar { border-bottom: 2px solid #7855FA !important; }
.card, .panel, .well { background-color: #161616 !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
.card-header, .card-footer, .panel-heading { background-color: #1E1E1E !important; border-color: #2A2A2A !important; }
.card-body, .card-text { color: #F0F0F0 !important; }
.table, table { color: #F0F0F0 !important; }
.table thead th, th { background-color: #1E1E1E !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
.table td, td { border-color: #2A2A2A !important; }
.table-striped tbody tr:nth-of-type(odd) { background-color: #161616 !important; }
.table-striped tbody tr:nth-of-type(even) { background-color: #0D0D0D !important; }
.table-hover tbody tr:hover { background-color: #1E1E1E !important; }
.btn-primary { background: linear-gradient(135deg, #4B00AA, #1FDDE9) !important; border: none !important; color: #fff !important; }
.btn-secondary, .btn-default, .btn-light { background-color: #1E1E1E !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
input, select, textarea, .form-control { background-color: #1E1E1E !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
.alert { background-color: #1E1E1E !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
.alert-info { border-left: 4px solid #1FDDE9 !important; }
.alert-warning { border-left: 4px solid #F5A623 !important; }
.alert-danger { border-left: 4px solid #E05252 !important; }
.alert-success { border-left: 4px solid #3DD68C !important; }
.bg-light, .bg-white { background-color: #161616 !important; }
.text-dark { color: #F0F0F0 !important; } .text-muted { color: #A0A0A0 !important; }
hr { border-color: #2A2A2A !important; }
a { color: #1FDDE9; } a:hover { color: #7855FA; }
h1, h2, h3, h4, h5, h6 { color: #F0F0F0 !important; }
.modal-content { background-color: #161616 !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
.modal-header, .modal-footer { border-color: #2A2A2A !important; }
.dropdown-menu { background-color: #161616 !important; border-color: #2A2A2A !important; }
.dropdown-item { color: #F0F0F0 !important; } .dropdown-item:hover { background-color: #1E1E1E !important; }
.list-group-item { background-color: #161616 !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
.page-link { background-color: #161616 !important; border-color: #2A2A2A !important; color: #1FDDE9 !important; }
.page-item.active .page-link { background-color: #7855FA !important; border-color: #7855FA !important; }
body::before { content: ''; display: block; height: 3px; background: linear-gradient(135deg, #4B00AA, #1FDDE9); position: fixed; top: 0; left: 0; right: 0; z-index: 9999; pointer-events: none; }
</style>
CSSEOF

cat > "${TMP}/workshop-dashboard.html" << 'CSSEOF'
<style>
html, body { background-color: #0D0D0D !important; color: #F0F0F0 !important; }
header, .header, [class*="Header"], [class*="header"] { background-color: #0D0D0D !important; border-bottom: 1px solid #2A2A2A !important; color: #F0F0F0 !important; }
[class*="Tab"], [class*="tab"], [role="tablist"] { background-color: #161616 !important; border-color: #2A2A2A !important; }
[class*="Panel"], [class*="panel"], [class*="Frame"], [class*="Content"], .split-pane { background-color: #0D0D0D !important; }
[class*="Sidebar"], [class*="sidebar"], nav, aside { background-color: #0D0D0D !important; border-color: #2A2A2A !important; }
a { color: #1FDDE9; } a:hover { color: #7855FA; }
.terminal { background-color: #0D0D0D !important; }
#startup-cover-panel { background: #0D0D0D !important; color: #F0F0F0 !important; }
div#terminate-session-dialog, div#workshop-expired-dialog, div#workshop-failed-dialog, div#finished-workshop-dialog, div#started-workshop-dialog { background-color: #161616 !important; color: #F0F0F0 !important; border-color: #2A2A2A !important; }
.modal-content { background-color: #161616 !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
.modal-header, .modal-footer { background-color: #1E1E1E !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
.modal-title { color: #F0F0F0 !important; }
.modal-body { color: #F0F0F0 !important; }
.modal-body p, .modal-body div { color: #F0F0F0 !important; }
.nav-pills .nav-link { color: #B0B0B0 !important; background-color: #161616 !important; border: 1px solid #2A2A2A !important; }
.nav-pills .nav-link.active, .nav-pills .show > .nav-link { background-color: #7855FA !important; border-color: #7855FA !important; color: #fff !important; }
.nav-tabs .nav-link { color: #B0B0B0 !important; border-color: #2A2A2A !important; background-color: transparent !important; }
.nav-tabs .nav-link.active { background-color: #161616 !important; border-color: #2A2A2A #2A2A2A #161616 !important; color: #F0F0F0 !important; }
.btn-primary { background: linear-gradient(135deg, #4B00AA, #1FDDE9) !important; border: none !important; color: #fff !important; }
.btn-secondary, .btn-default, .btn-light { background-color: #1E1E1E !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
.btn-danger { background-color: #7a2020 !important; border-color: #5c1a1a !important; color: #fff !important; }
.btn-close { filter: invert(1) !important; }
.dropdown-menu { background-color: #161616 !important; border-color: #2A2A2A !important; }
.dropdown-item { color: #F0F0F0 !important; } .dropdown-item:hover { background-color: #1E1E1E !important; }
input, select, textarea, .form-control, .form-select { background-color: #1E1E1E !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
.alert { background-color: #1E1E1E !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; }
::-webkit-scrollbar { width: 6px; height: 6px; } ::-webkit-scrollbar-track { background: #161616; }
::-webkit-scrollbar-thumb { background: #333; border-radius: 3px; } ::-webkit-scrollbar-thumb:hover { background: #7855FA; }
body::before { content: ''; display: block; height: 3px; background: linear-gradient(135deg, #4B00AA, #1FDDE9); position: fixed; top: 0; left: 0; right: 0; z-index: 9999; pointer-events: none; }
</style>
CSSEOF

# workshop-instructions.css — loaded by Educates as a <link> stylesheet.
# Must be raw CSS (no <style> tags). Overrides educates.css including .page-content.
cat > "${TMP}/workshop-instructions.css" << 'CSSEOF'
html, body { background-color: #0D0D0D !important; color: #F0F0F0 !important; font-family: 'Segoe UI', system-ui, sans-serif; }
.page-content { background-color: #0D0D0D !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; box-shadow: none !important; }
h1, h2, h3, h4, h5, h6 { color: #F0F0F0 !important; }
h1, h2 { border-bottom: 1px solid #2A2A2A !important; padding-bottom: 8px; }
a { color: #1FDDE9 !important; } a:hover { color: #7855FA !important; }
pre, .highlight, .page-content pre { background-color: #161616 !important; border: 1px solid #2A2A2A !important; border-radius: 6px !important; color: #F0F0F0 !important; padding: 16px !important; }
code { background-color: #1E1E1E !important; color: #1FDDE9 !important; border-radius: 3px !important; padding: 2px 5px !important; }
pre code { background: transparent !important; color: #F0F0F0 !important; padding: 0 !important; }
blockquote, .note, .warning, .tip, .info { background-color: #161616 !important; border-left: 4px solid #7855FA !important; color: #F0F0F0 !important; padding: 12px 16px !important; border-radius: 0 6px 6px 0; }
table { color: #F0F0F0 !important; border-collapse: collapse; width: 100%; }
th { background-color: #1E1E1E !important; color: #F0F0F0 !important; border: 1px solid #2A2A2A !important; padding: 8px 12px; }
td { border: 1px solid #2A2A2A !important; padding: 8px 12px; }
tr:nth-child(even) { background-color: #161616 !important; } tr:nth-child(odd) { background-color: #0D0D0D !important; }
.mermaid { background: #161616 !important; border-radius: 8px; padding: 16px; }
.bg-primary { background-color: #1E1E1E !important; }
div.magic-code-block-title { background-color: #1E3A5F !important; color: #B0D4F0 !important; border-radius: 4px 4px 0 0; }
div.magic-code-block-form, div.magic-code-block-upload { background-color: #161616 !important; color: #F0F0F0 !important; border-color: #2A2A2A !important; }
[data-action-name][data-action-result='success'] { background-color: #0D1F0D !important; }
[data-action-name][data-action-result='success'] div.magic-code-block-title { background-color: #1A4D2A !important; color: #3DD68C !important; }
[data-action-name][data-action-result='pending'] { background-color: #1F1500 !important; }
[data-action-name][data-action-result='pending'] div.magic-code-block-title { background-color: #4D3500 !important; color: #FBB040 !important; }
[data-action-name][data-action-result='failure'] { background-color: #1F0D0D !important; }
[data-action-name][data-action-result='failure'] div.magic-code-block-title { background-color: #4D1A1A !important; color: #E05252 !important; }
::-webkit-scrollbar { width: 6px; height: 6px; } ::-webkit-scrollbar-track { background: #161616; }
::-webkit-scrollbar-thumb { background: #333; border-radius: 3px; } ::-webkit-scrollbar-thumb:hover { background: #7855FA; }
body::before { content: ''; display: block; height: 3px; background: linear-gradient(135deg, #4B00AA, #1FDDE9); position: fixed; top: 0; left: 0; right: 0; z-index: 9999; pointer-events: none; }
CSSEOF

# workshop-instructions.html — injected into <head> of the instructions iframe.
# Renderer uses marked@4 + hljs: mermaid fences render as <pre><code class="hljs language-mermaid">.
# Script finds those <pre> blocks and replaces them with mermaid.js SVG output.
cat > "${TMP}/workshop-instructions.html" << 'CSSEOF'
<style>
html, body { background-color: #0D0D0D !important; color: #F0F0F0 !important; }
.page-content { background-color: #0D0D0D !important; border-color: #2A2A2A !important; color: #F0F0F0 !important; box-shadow: none !important; }
.mermaid-rendered { background: #161616; border-radius: 8px; padding: 16px; margin: 16px 0; overflow: auto; }
.mermaid-rendered svg { max-width: 100%; height: auto; }
</style>
<script type="module">
// NOTE: type="module" scripts are deferred — they execute AFTER DOMContentLoaded.
// Do NOT use addEventListener('DOMContentLoaded', ...) inside a module script;
// that event has already fired by the time this runs.
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
mermaid.initialize({ startOnLoad: false, theme: 'dark' });

async function renderMermaid() {
  // Renderer (marked@4 + hljs) outputs: <pre><code class="hljs language-mermaid">
  const blocks = document.querySelectorAll('pre:not([data-mmd]) code.language-mermaid');
  for (const code of blocks) {
    const pre = code.closest('pre');
    if (!pre) continue;
    pre.setAttribute('data-mmd', '1');
    const src = code.textContent.trim();
    if (!src) continue;
    try {
      const id = 'mmd' + Math.random().toString(36).slice(2, 9);
      const { svg } = await mermaid.render(id, src);
      const div = document.createElement('div');
      div.className = 'mermaid-rendered';
      div.innerHTML = svg;
      pre.replaceWith(div);
    } catch(e) { console.warn('Mermaid render failed:', e); }
  }
}

// DOM is ready (module scripts are deferred) — render immediately
renderMermaid();

// Also handle SPA-style content updates
let t;
new MutationObserver(() => { clearTimeout(t); t = setTimeout(renderMermaid, 200); })
  .observe(document.documentElement, { childList: true, subtree: true });
</script>
CSSEOF

# ── Base64-encode the theme files ────────────────────────────────────────────
PORTAL_B64=$(base64 -w0 "${TMP}/training-portal.html")
DASH_B64=$(base64 -w0 "${TMP}/workshop-dashboard.html")
INST_HTML_B64=$(base64 -w0 "${TMP}/workshop-instructions.html")
INST_CSS_B64=$(base64 -w0 "${TMP}/workshop-instructions.css")

# ── Patch educates/default-website-theme (source for SecretCopier) ───────────
# SecretCopier syncs this to every env namespace's workshop-theme secret.
# workshop-instructions.css is loaded via <link> — must be raw CSS, no <style> tags.
echo "  Patching educates/default-website-theme (session source)..."
kubectl patch secret default-website-theme -n educates --type=json -p "[
  {\"op\":\"replace\",\"path\":\"/data/workshop-instructions.css\",\"value\":\"${INST_CSS_B64}\"},
  {\"op\":\"replace\",\"path\":\"/data/workshop-instructions.html\",\"value\":\"${INST_HTML_B64}\"},
  {\"op\":\"replace\",\"path\":\"/data/workshop-dashboard.html\",\"value\":\"${DASH_B64}\"}
]"

# ── Patch portal namespace secret (training portal catalog UI) ────────────────
echo "  Patching ${PORTAL_NS}/default-website-theme (portal catalog)..."
kubectl patch secret default-website-theme -n "${PORTAL_NS}" --type=json -p "[
  {\"op\":\"replace\",\"path\":\"/data/training-portal.html\",\"value\":\"${PORTAL_B64}\"},
  {\"op\":\"replace\",\"path\":\"/data/workshop-instructions.css\",\"value\":\"${INST_CSS_B64}\"},
  {\"op\":\"replace\",\"path\":\"/data/workshop-instructions.html\",\"value\":\"${INST_HTML_B64}\"},
  {\"op\":\"replace\",\"path\":\"/data/workshop-dashboard.html\",\"value\":\"${DASH_B64}\"}
]"

# ── Restart only the training portal (sessions unaffected) ───────────────────
echo "  Restarting training portal..."
kubectl rollout restart deployment/training-portal -n "${PORTAL_NS}"
kubectl rollout status deployment/training-portal -n "${PORTAL_NS}" --timeout=90s

echo "✓ Theme applied."
echo "  Session pods pick up the new CSS via volume mount refresh (~60s)."
echo "  Hard-reload any open workshop tab to see the change."
