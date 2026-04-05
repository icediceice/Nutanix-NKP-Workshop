#!/bin/bash
# update-theme.sh — Re-apply Nutanix dark theme to the live Educates platform.
#
# Run this after any change to the websiteStyling CSS in install-educates.sh.
# Safe to run on a live cluster — educates admin platform deploy is idempotent.
#
# Usage: ./update-theme.sh [config.yaml]

set -euo pipefail

CONFIG_FILE="${1:-$(dirname "$0")/../config.yaml}"
export PATH="${HOME}/.local/bin:${PATH}"

cfg() { yq eval ".${1}" "${CONFIG_FILE}"; }

EDUCATES_VERSION=$(cfg educates_version)
INGRESS_DOMAIN=$(cfg educates_ingress_domain)
STORAGE_CLASS=$(cfg storage_class)
POLICY_ENGINE=$(cfg educates_policy_engine)
INGRESS_CLASS=$(cfg educates_ingress_class 2>/dev/null || echo "")
[[ "${INGRESS_CLASS}" == "null" ]] && INGRESS_CLASS=""
INFRA_PROVIDER=$(cfg educates_infra_provider 2>/dev/null || echo "generic")
[[ "${INFRA_PROVIDER}" == "null" ]] && INFRA_PROVIDER="generic"

RUNTIME_CONFIG=$(mktemp /tmp/educates-config-XXXXXX.yaml)

# Generate config (mirrors websiteStyling block from install-educates.sh)
cat > "${RUNTIME_CONFIG}" <<EOF
clusterInfrastructure:
  provider: ${INFRA_PROVIDER}

clusterIngress:
  domain: ${INGRESS_DOMAIN}
$(if [[ -n "${INGRESS_CLASS}" ]]; then echo "  class: ${INGRESS_CLASS}"; fi)
  tlsCertificateRef:
    namespace: educates
    name: educates-wildcard-tls
clusterStorage:
  class: ${STORAGE_CLASS}

clusterSecurity:
  policyEngine: ${POLICY_ENGINE}

websiteStyling:
  trainingPortal:
    html: |
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
      input::placeholder, .form-control::placeholder { color: #666 !important; }
      .alert { background-color: #1A1A1A !important; border-color: #242424 !important; color: #F0F0F0 !important; }
      .alert-info { border-left: 4px solid #1FDDE9 !important; }
      .alert-warning { border-left: 4px solid #F5A623 !important; }
      .alert-danger { border-left: 4px solid #E05252 !important; }
      .alert-success { border-left: 4px solid #3DD68C !important; }
      .bg-light, .bg-white { background-color: #111111 !important; }
      .text-dark { color: #F0F0F0 !important; }
      .text-muted { color: #A0A0A0 !important; }
      hr { border-color: #242424 !important; }
      a { color: #1FDDE9; }
      a:hover { color: #7855FA; }
      h1, h2, h3, h4, h5, h6 { color: #F0F0F0 !important; }
      .breadcrumb { background-color: #1A1A1A !important; }
      .modal-content { background-color: #111111 !important; border-color: #242424 !important; color: #F0F0F0 !important; }
      .modal-header, .modal-footer { border-color: #242424 !important; }
      .dropdown-menu { background-color: #111111 !important; border-color: #242424 !important; }
      .dropdown-item { color: #F0F0F0 !important; }
      .dropdown-item:hover { background-color: #1A1A1A !important; }
      .list-group-item { background-color: #111111 !important; border-color: #242424 !important; color: #F0F0F0 !important; }
      .page-link { background-color: #111111 !important; border-color: #242424 !important; color: #1FDDE9 !important; }
      .page-item.active .page-link { background-color: #7855FA !important; border-color: #7855FA !important; }
      body::before { content: ''; display: block; height: 3px; background: linear-gradient(135deg, #4B00AA, #1FDDE9); position: fixed; top: 0; left: 0; right: 0; z-index: 9999; pointer-events: none; }
      </style>
  workshopDashboard:
    html: |
      <style>
      html, body { background-color: #090909 !important; color: #F0F0F0 !important; }
      header, .header, [class*="Header"], [class*="header"] { background-color: #0D0D0D !important; border-bottom: 1px solid #242424 !important; color: #F0F0F0 !important; }
      [class*="Tab"], [class*="tab"], [role="tablist"] { background-color: #111111 !important; border-color: #242424 !important; }
      [class*="Panel"], [class*="panel"], [class*="Frame"], [class*="Content"], .split-pane { background-color: #090909 !important; }
      [class*="Sidebar"], [class*="sidebar"], nav, aside { background-color: #0D0D0D !important; border-color: #242424 !important; }
      a { color: #1FDDE9; }
      a:hover { color: #7855FA; }
      ::-webkit-scrollbar { width: 6px; height: 6px; }
      ::-webkit-scrollbar-track { background: #111111; }
      ::-webkit-scrollbar-thumb { background: #333; border-radius: 3px; }
      ::-webkit-scrollbar-thumb:hover { background: #7855FA; }
      body::before { content: ''; display: block; height: 3px; background: linear-gradient(135deg, #4B00AA, #1FDDE9); position: fixed; top: 0; left: 0; right: 0; z-index: 9999; pointer-events: none; }
      </style>
  workshopInstructions:
    html: |
      <style>
      html, body { background-color: #090909 !important; color: #F0F0F0 !important; font-family: 'Segoe UI', system-ui, -apple-system, sans-serif; }
      h1, h2, h3, h4, h5, h6 { color: #F0F0F0 !important; }
      h1, h2 { border-bottom: 1px solid #242424 !important; padding-bottom: 8px; }
      a { color: #1FDDE9 !important; }
      a:hover { color: #7855FA !important; }
      pre { background-color: #0D0D0D !important; border: 1px solid #242424 !important; border-radius: 6px !important; color: #F0F0F0 !important; padding: 16px !important; }
      code { background-color: #1A1A1A !important; color: #1FDDE9 !important; border-radius: 3px !important; padding: 2px 5px !important; }
      pre code { background: transparent !important; color: #F0F0F0 !important; padding: 0 !important; }
      blockquote, .note, .warning, .tip, .info { background-color: #111111 !important; border-left: 4px solid #7855FA !important; color: #F0F0F0 !important; padding: 12px 16px !important; border-radius: 0 6px 6px 0; }
      table { color: #F0F0F0 !important; border-collapse: collapse; width: 100%; }
      th { background-color: #1A1A1A !important; color: #1FDDE9 !important; border: 1px solid #242424 !important; padding: 8px 12px; }
      td { border: 1px solid #242424 !important; padding: 8px 12px; }
      tr:nth-child(even) { background-color: #111111 !important; }
      tr:nth-child(odd) { background-color: #0D0D0D !important; }
      nav, .sidebar, [class*="sidebar"], [class*="nav"] { background-color: #0D0D0D !important; color: #A0A0A0 !important; }
      .mermaid { background: #111111 !important; border-radius: 8px; padding: 16px; }
      ::-webkit-scrollbar { width: 6px; height: 6px; }
      ::-webkit-scrollbar-track { background: #111111; }
      ::-webkit-scrollbar-thumb { background: #333; border-radius: 3px; }
      ::-webkit-scrollbar-thumb:hover { background: #7855FA; }
      body::before { content: ''; display: block; height: 3px; background: linear-gradient(135deg, #4B00AA, #1FDDE9); position: fixed; top: 0; left: 0; right: 0; z-index: 9999; pointer-events: none; }
      </style>
EOF

echo "Applying Nutanix dark theme to Educates platform..."
educates admin platform deploy \
  --config "${RUNTIME_CONFIG}" \
  --version "${EDUCATES_VERSION}" \
  --skip-image-resolution

rm -f "${RUNTIME_CONFIG}"
echo "✓ Theme applied. Reload any open workshop tabs to see the change."
