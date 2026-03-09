#!/usr/bin/env bash
# =============================================================================
# bootstrap-educates.sh — End-to-end Educates platform + NKP workshop install
# =============================================================================
#
# USAGE:
#   ./bootstrap-educates.sh [OPTIONS]
#
# OPTIONS:
#   --kubeconfig PATH      Path to kubeconfig (auto-detected from auth/ if omitted)
#   --version VERSION      Educates CLI version (default: 3.6.0)
#   --domain DOMAIN        Ingress base domain (default: auto from Traefik IP + nip.io)
#   --ingress-class CLASS  Kubernetes ingress class (default: auto-detected)
#   --skip-platform        Skip Educates platform deploy (already installed)
#   --skip-publish         Skip workshop image publish
#   --skip-portal          Skip TrainingPortal apply
#   --dry-run              Show what would be done, make no changes
#
# ENVIRONMENT OVERRIDES (same as CLI flags):
#   EDUCATES_VERSION, KUBECONFIG, INGRESS_DOMAIN, INGRESS_CLASS
#
# IDEMPOTENT: Safe to re-run. Already-completed steps are skipped.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

# ─── Resolve paths ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSHOP_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$(dirname "$WORKSHOP_ROOT")")"
STATE_FILE="${WORKSHOP_ROOT}/.educates-bootstrap-state"

# ─── Defaults (overridable via env or flags) ──────────────────────────────────
EDUCATES_VERSION="${EDUCATES_VERSION:-3.6.0}"
WORKSHOP_NAME="${WORKSHOP_NAME:-nkp-workshop}"
EDUCATES_NAMESPACE="${EDUCATES_NAMESPACE:-educates}"
REGISTRY_PORT="5000"
DRY_RUN=false
SKIP_PLATFORM=false
SKIP_PUBLISH=false
SKIP_PORTAL=false

# Auto-detected (populated in discover_cluster_params)
KUBECONFIG_PATH=""
INGRESS_DOMAIN=""
INGRESS_CLASS=""
TRAEFIK_IP=""
REGISTRY_HOST=""
PORTAL_URL=""
CERT_SETUP_URL=""

# ─── Colors ───────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
  C_RESET='\033[0m'; C_BOLD='\033[1m'
  C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'
  C_RED='\033[0;31m';   C_CYAN='\033[0;36m'
  C_BLUE='\033[0;34m'
else
  C_RESET=''; C_BOLD=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_CYAN=''; C_BLUE=''
fi

# ─── Logging ─────────────────────────────────────────────────────────────────
info()    { echo -e "${C_CYAN}[INFO]${C_RESET}  $*"; }
success() { echo -e "${C_GREEN}[OK]${C_RESET}    $*"; }
warn()    { echo -e "${C_YELLOW}[WARN]${C_RESET}  $*"; }
error()   { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; exit 1; }
skip()    { echo -e "${C_BLUE}[SKIP]${C_RESET}  $*"; }
dry()     { echo -e "${C_YELLOW}[DRY]${C_RESET}   $*"; }

step() {
  echo ""
  echo -e "${C_BOLD}${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  echo -e "${C_BOLD}  STEP: $*${C_RESET}"
  echo -e "${C_BOLD}${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
}

# ─── State tracking (idempotency) ────────────────────────────────────────────
state_set()   { mkdir -p "$(dirname "$STATE_FILE")"; echo "$1" >> "$STATE_FILE"; }
state_done()  { [[ -f "$STATE_FILE" ]] && grep -qxF "$1" "$STATE_FILE" 2>/dev/null; }
state_clear() { rm -f "$STATE_FILE"; info "State cleared. Fresh install."; }

# ─── Retry with exponential backoff ─────────────────────────────────────────
retry() {
  local max="${RETRY_MAX:-5}" delay="${RETRY_DELAY:-10}" n=1
  until "$@"; do
    (( n == max )) && error "Command failed after $max attempts: $*"
    warn "Attempt $n/$max failed. Retrying in ${delay}s..."
    sleep "$delay"
    (( n++ )); (( delay = delay * 2 < 120 ? delay * 2 : 120 ))
  done
}

# ─── Wait for condition ──────────────────────────────────────────────────────
wait_for() {
  local desc="$1" timeout="${2:-300}"; shift 2
  local elapsed=0 interval=10
  info "Waiting for: ${desc} (timeout: ${timeout}s)"
  until eval "$*" &>/dev/null; do
    (( elapsed >= timeout )) && error "Timeout (${timeout}s) waiting for: ${desc}"
    printf "  ... %ds elapsed\r" "$elapsed"
    sleep "$interval"; (( elapsed += interval ))
  done
  echo ""
  success "${desc}"
}

# ─── kubectl wrapper ──────────────────────────────────────────────────────────
k() { kubectl --kubeconfig="$KUBECONFIG_PATH" "$@"; }

# ─── Dry-run wrapper ──────────────────────────────────────────────────────────
run() {
  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would run: $(printf '%s ' "$@")"
  else
    "$@"
  fi
}

# ─── Parse arguments ─────────────────────────────────────────────────────────
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --kubeconfig)    KUBECONFIG_PATH="$2";  shift 2 ;;
      --version)       EDUCATES_VERSION="$2"; shift 2 ;;
      --domain)        INGRESS_DOMAIN="$2";   shift 2 ;;
      --ingress-class) INGRESS_CLASS="$2";    shift 2 ;;
      --skip-platform) SKIP_PLATFORM=true;    shift ;;
      --skip-publish)  SKIP_PUBLISH=true;     shift ;;
      --skip-portal)   SKIP_PORTAL=true;      shift ;;
      --dry-run)       DRY_RUN=true;          shift ;;
      --reset-state)   state_clear;           shift ;;
      --help|-h)       usage; exit 0 ;;
      *) error "Unknown argument: $1" ;;
    esac
  done
}

usage() {
  grep '^#' "$0" | grep -v '#!/' | sed 's/^# \?//'
}

# =============================================================================
# STEP 1 — Preflight checks
# =============================================================================
preflight_check() {
  step "Preflight checks"

  # Required tools
  local missing=()
  for cmd in kubectl helm curl git python3; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done
  (( ${#missing[@]} > 0 )) && error "Missing required tools: ${missing[*]}"
  success "Required tools present (kubectl, helm, curl, git, python3)"

  # Kubeconfig: auto-detect from auth/ if not provided
  if [[ -z "$KUBECONFIG_PATH" ]]; then
    # Prefer KUBECONFIG env, then auth/workload01.conf, then auth/*.conf
    if [[ -n "${KUBECONFIG:-}" && -f "${KUBECONFIG}" ]]; then
      KUBECONFIG_PATH="$KUBECONFIG"
    elif [[ -f "$REPO_ROOT/auth/workload01.conf" ]]; then
      KUBECONFIG_PATH="$REPO_ROOT/auth/workload01.conf"
    else
      local conf_files=("$REPO_ROOT/auth/"*.conf)
      [[ ${#conf_files[@]} -gt 0 && -f "${conf_files[0]}" ]] || \
        error "No kubeconfig found. Set --kubeconfig or KUBECONFIG, or place config in auth/"
      KUBECONFIG_PATH="${conf_files[0]}"
      warn "Auto-selected kubeconfig: $KUBECONFIG_PATH"
    fi
  fi
  [[ -f "$KUBECONFIG_PATH" ]] || error "Kubeconfig not found: $KUBECONFIG_PATH"
  success "Kubeconfig: $KUBECONFIG_PATH"

  # Cluster connectivity
  retry k cluster-info --request-timeout=10s &>/dev/null || error "Cannot reach cluster"
  success "Cluster reachable: $(k config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null)"

  # Git repo state
  git -C "$REPO_ROOT" rev-parse HEAD &>/dev/null || error "Not a git repository: $REPO_ROOT"
  local dirty
  dirty=$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null | wc -l)
  (( dirty > 0 )) && warn "Working tree has $dirty uncommitted changes"
  success "Git repo OK ($(git -C "$REPO_ROOT" log --oneline -1))"

  # Internet connectivity (for downloading CLI and nip.io)
  curl -sfo /dev/null --max-time 5 https://github.com || warn "GitHub not reachable — CLI download may fail"

  success "Preflight complete"
}

# =============================================================================
# STEP 2 — Install educates CLI
# =============================================================================
install_educates_cli() {
  step "Install educates CLI v${EDUCATES_VERSION}"

  local install_dir="${HOME}/.local/bin"
  local bin_path="${install_dir}/educates"
  local download_url="https://github.com/educates/educates-training-platform/releases/download/${EDUCATES_VERSION}/educates-linux-amd64"

  # Check if already installed at correct version
  if command -v educates &>/dev/null; then
    local installed_ver
    installed_ver=$(educates version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    if [[ "$installed_ver" == "${EDUCATES_VERSION#v}" ]]; then
      skip "educates CLI already installed: v${installed_ver}"
      return
    fi
    warn "educates v${installed_ver} installed, upgrading to v${EDUCATES_VERSION}"
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would download educates ${EDUCATES_VERSION} to ${bin_path}"
    export PATH="${install_dir}:${PATH}"
    return
  fi

  mkdir -p "$install_dir"
  info "Downloading educates v${EDUCATES_VERSION}..."
  retry curl -fsSL -o "${bin_path}.tmp" "$download_url"
  chmod +x "${bin_path}.tmp"

  # Validate binary before replacing
  "${bin_path}.tmp" version &>/dev/null || error "Downloaded binary failed sanity check"
  mv "${bin_path}.tmp" "$bin_path"

  # Ensure install_dir is in PATH for this session
  export PATH="${install_dir}:${PATH}"

  local installed_ver_str
  installed_ver_str=$(educates version 2>/dev/null | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1 || echo "${EDUCATES_VERSION}")
  success "educates CLI installed: v${installed_ver_str}"
}

# =============================================================================
# STEP 3 — Discover cluster parameters
# =============================================================================
discover_cluster_params() {
  step "Discover cluster parameters"

  # Ingress class: prefer kommander-traefik, else first available
  if [[ -z "$INGRESS_CLASS" ]]; then
    if k get ingressclass kommander-traefik &>/dev/null 2>&1; then
      INGRESS_CLASS="kommander-traefik"
    else
      INGRESS_CLASS=$(k get ingressclass -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
      [[ -z "$INGRESS_CLASS" ]] && error "No ingress class found on cluster"
    fi
  fi
  success "Ingress class: ${INGRESS_CLASS}"

  # Traefik external IP → base domain via nip.io
  if [[ -z "$INGRESS_DOMAIN" ]]; then
    # Try well-known Traefik service locations
    for ns_svc in "kommander-default-workspace/kommander-traefik" "kube-system/traefik" "ingress-nginx/ingress-nginx-controller"; do
      local ns="${ns_svc%%/*}" svc="${ns_svc##*/}"
      TRAEFIK_IP=$(k -n "$ns" get svc "$svc" \
        -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
      [[ -n "$TRAEFIK_IP" ]] && break
    done

    # Fallback: any LoadBalancer with an IP
    if [[ -z "$TRAEFIK_IP" ]]; then
      TRAEFIK_IP=$(k get svc -A \
        -o jsonpath='{.items[?(@.spec.type=="LoadBalancer")].status.loadBalancer.ingress[0].ip}' \
        2>/dev/null | tr ' ' '\n' | grep -v '^$' | head -1 || true)
    fi

    [[ -z "$TRAEFIK_IP" ]] && error "Cannot detect ingress IP. Set --domain explicitly."
    INGRESS_DOMAIN="${TRAEFIK_IP}.nip.io"
  fi
  success "Ingress domain: ${INGRESS_DOMAIN} (via nip.io → ${TRAEFIK_IP:-manual})"

  # Verify nip.io resolves correctly (best-effort)
  local resolved
  resolved=$(python3 -c "import socket; print(socket.gethostbyname('test.${INGRESS_DOMAIN}'))" 2>/dev/null || true)
  if [[ "$resolved" == "${TRAEFIK_IP}" ]]; then
    success "nip.io DNS verified: test.${INGRESS_DOMAIN} → ${TRAEFIK_IP}"
  else
    warn "nip.io DNS check inconclusive (resolved: ${resolved:-none}). Continuing anyway."
  fi

  # cert-manager availability
  if k get deployment -n cert-manager cert-manager &>/dev/null 2>&1; then
    success "cert-manager: present (will reuse, not reinstall)"
  else
    warn "cert-manager not found — Educates will install its own"
  fi

  success "Cluster parameter discovery complete"
}

# =============================================================================
# STEP 4 — Generate Educates platform config
# =============================================================================
# Sets global: PLATFORM_CONFIG_FILE
generate_platform_config() {
  step "Generate Educates platform config"

  PLATFORM_CONFIG_FILE="${WORKSHOP_ROOT}/.educates-platform-config.yaml"
  local config_file="$PLATFORM_CONFIG_FILE"

  cat > "$config_file" <<EOF
# Auto-generated by bootstrap-educates.sh — do not edit manually
# Regenerated on each run. Commit .educates-platform-config.yaml if desired.
clusterInfrastructure:
  provider: generic

clusterIngress:
  domain: "${INGRESS_DOMAIN}"
  class: "${INGRESS_CLASS}"
  protocol: https

clusterPackages:
  contour:
    enabled: false
  kyverno:
    enabled: true
    settings: {}
  educates:
    enabled: true
    settings: {}

clusterSecurity:
  policyEngine: kyverno

workshopSecurity:
  rulesEngine: kyverno
EOF

  success "Platform config written: ${config_file}"
  info "  domain:        ${INGRESS_DOMAIN}"
  info "  ingress class: ${INGRESS_CLASS}"
  info "  contour:       disabled (using kommander-traefik)"
  info "  kyverno:       enabled (policy engine)"
}

# =============================================================================
# STEP 5 — Deploy Educates platform
# =============================================================================
deploy_educates_platform() {
  step "Deploy Educates platform"

  if [[ "$SKIP_PLATFORM" == "true" ]]; then
    skip "Platform deploy skipped (--skip-platform)"
    return
  fi

  if state_done "platform_deployed"; then
    skip "Educates platform already deployed (state: platform_deployed)"
    return
  fi

  local config_file="$PLATFORM_CONFIG_FILE"

  info "Running: educates admin platform deploy"
  if [[ "$DRY_RUN" == "true" ]]; then
    dry "educates admin platform deploy --config ${config_file} --kubeconfig ${KUBECONFIG_PATH}"
    return
  fi

  # Deploy with retry — platform deploy can fail transiently on first attempt
  local attempts=0 max_attempts=3
  until educates admin platform deploy \
        --config "$config_file" \
        --kubeconfig "$KUBECONFIG_PATH"; do
    (( attempts++ ))
    (( attempts >= max_attempts )) && error "Educates platform deploy failed after ${max_attempts} attempts"
    warn "Deploy attempt ${attempts}/${max_attempts} failed. Retrying in 30s..."
    sleep 30
  done

  state_set "platform_deployed"
  success "Educates platform deploy initiated"
}

# =============================================================================
# STEP 6 — Wait for Educates platform ready
# =============================================================================
wait_platform_ready() {
  step "Wait for Educates platform ready"

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would wait for Educates operator, registry, and TrainingPortal CRD"
    return
  fi

  if state_done "platform_ready"; then
    skip "Platform already confirmed ready"
    return
  fi

  # Wait for Educates session-manager deployment (v3.6.0 name)
  wait_for "Educates session-manager deployment" 300 \
    "k get deployment -n ${EDUCATES_NAMESPACE} session-manager 2>/dev/null | grep -q '1/1'"

  # Verify TrainingPortal CRD registered
  wait_for "TrainingPortal CRD" 120 \
    "k get crd trainingportals.training.educates.dev &>/dev/null"

  state_set "platform_ready"
  success "Educates platform is ready"
}

# =============================================================================
# STEP 7 — Publish workshop OCI image
# =============================================================================
publish_workshop() {
  step "Publish workshop OCI image"

  if [[ "$SKIP_PUBLISH" == "true" ]]; then
    skip "Publish skipped (--skip-publish)"
    return
  fi

  # Workshop uses git-based file sourcing (resources/workshop.yaml) — no OCI publish needed.
  skip "Publish skipped — workshop uses git-based file sourcing (no registry required)"
  state_set "workshop_published"
}

# =============================================================================
# STEP 8b — Apply observability stack (Kiali, Jaeger, ArgoCD ingress + basehref)
# =============================================================================
# WHY THIS STEP EXISTS:
#   NKP's Traefik (kommander-traefik) blocks ExternalName service backends by
#   default. Ingress objects must live in the same namespace as their target
#   service so Traefik can resolve them directly. This step applies:
#     - kiali.yaml  → ArgoCD Application (installs Kiali) + Ingress in istio-system
#     - jaeger.yaml → ArgoCD Application (installs Jaeger) + Ingress in istio-system
#     - argocd-ingress.yaml → Ingress in argocd namespace (not kommander-default-workspace)
#   It also patches argocd-cmd-params-cm so ArgoCD serves at /dkp/argocd subpath.
#   Kyverno policies on NKP block LoadBalancer services in session namespaces, so
#   Kiali/Jaeger/demo-wall all use ClusterIP and are exposed only through Traefik.
# =============================================================================
apply_observability_stack() {
  step "Apply observability stack (Kiali, Jaeger, ArgoCD ingress)"

  if state_done "observability_applied"; then
    skip "Observability stack already applied"
    return
  fi

  local obs_dir="${WORKSHOP_ROOT}/resources/observability"
  if [[ ! -d "$obs_dir" ]]; then
    warn "Observability manifests not found at ${obs_dir} — skipping"
    return
  fi

  # Kiali and Jaeger: ArgoCD Applications deploy them into istio-system;
  # Ingresses are in istio-system so Traefik can resolve service backends.
  info "Applying Kiali (ArgoCD Application + istio-system Ingress)..."
  run k apply -f "${obs_dir}/kiali.yaml"

  info "Applying Jaeger (ArgoCD Application + istio-system Ingress)..."
  run k apply -f "${obs_dir}/jaeger.yaml"

  # ArgoCD: Ingress lives in argocd namespace pointing at argocd-server:80.
  # ExternalName proxy in kommander-default-workspace was rejected by Traefik.
  info "Applying ArgoCD ingress (argocd namespace → /dkp/argocd)..."
  run k apply -f "${obs_dir}/argocd-ingress.yaml"

  # ArgoCD v3.x reads server.basehref and server.rootpath from this configmap
  # via env vars (ARGOCD_SERVER_BASEHREF / ARGOCD_SERVER_ROOTPATH).
  # Without this, SPA links break and API calls 404 when served at a subpath.
  info "Patching argocd-cmd-params-cm (basehref + rootpath = /dkp/argocd)..."
  run k -n argocd patch configmap argocd-cmd-params-cm \
    --type merge \
    -p '{"data":{"server.basehref":"/dkp/argocd","server.rootpath":"/dkp/argocd","server.insecure":"true"}}'

  info "Restarting argocd-server to pick up configmap changes..."
  run k -n argocd rollout restart deployment/argocd-server
  if [[ "$DRY_RUN" != "true" ]]; then
    k -n argocd rollout status deployment/argocd-server --timeout=120s
  fi

  state_set "observability_applied"
  success "Observability stack applied — Kiali/Jaeger deploying via ArgoCD"
}

# =============================================================================
# STEP 8 — Apply TrainingPortal
# =============================================================================
apply_training_portal() {
  step "Apply TrainingPortal"

  if [[ "$SKIP_PORTAL" == "true" ]]; then
    skip "TrainingPortal skipped (--skip-portal)"
    return
  fi

  if state_done "portal_applied"; then
    local existing
    existing=$(k get trainingportal "$WORKSHOP_NAME" -o jsonpath='{.status.educates.url}' 2>/dev/null || true)
    [[ -n "$existing" ]] && { skip "TrainingPortal already applied: ${existing}"; return; }
  fi

  local portal_manifest="${WORKSHOP_ROOT}/resources/training-portal.yaml"
  [[ -f "$portal_manifest" ]] || error "TrainingPortal manifest not found: ${portal_manifest}"

  # Apply Workshop CRD first (required before TrainingPortal)
  info "Applying Workshop CRD..."
  run k apply -f "${WORKSHOP_ROOT}/resources/workshop.yaml"

  # Give Educates time to register the workshop
  sleep 5

  info "Applying TrainingPortal..."
  run k apply -f "$portal_manifest"

  state_set "portal_applied"
  success "TrainingPortal applied"
}

# =============================================================================
# STEP 9 — Wait for TrainingPortal ready
# =============================================================================
wait_portal_ready() {
  step "Wait for TrainingPortal ready"

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would wait for TrainingPortal ${WORKSHOP_NAME} phase=Running"
    return
  fi

  if state_done "portal_ready"; then
    skip "Portal already confirmed ready"
    return
  fi

  wait_for "TrainingPortal phase=Running" 600 \
    "k get trainingportal ${WORKSHOP_NAME} \
       -o jsonpath='{.status.educates.phase}' 2>/dev/null | grep -qx 'Running'"

  PORTAL_URL=$(k get trainingportal "$WORKSHOP_NAME" \
    -o jsonpath='{.status.educates.url}' 2>/dev/null || true)
  success "TrainingPortal running: ${PORTAL_URL}"
}

# =============================================================================
# STEP 10 — Extract credentials
# =============================================================================
extract_credentials() {
  step "Extract Educates credentials"

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would extract TrainingPortal robot credentials"
    return
  fi

  local portal_name="$WORKSHOP_NAME"

  # Wait a moment for status to populate
  sleep 5

  local robot_client_id robot_client_secret robot_password robot_username portal_url

  robot_client_id=$(k get trainingportal "$portal_name" \
    -o jsonpath='{.status.educates.clients.robot.id}' 2>/dev/null || true)
  robot_client_secret=$(k get trainingportal "$portal_name" \
    -o jsonpath='{.status.educates.clients.robot.secret}' 2>/dev/null || true)
  robot_password=$(k get trainingportal "$portal_name" \
    -o jsonpath='{.status.educates.credentials.robot.password}' 2>/dev/null || true)
  robot_username="robot@educates"
  portal_url=$(k get trainingportal "$portal_name" \
    -o jsonpath='{.status.educates.url}' 2>/dev/null || true)

  echo ""
  echo -e "${C_BOLD}${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  echo -e "${C_BOLD}  Educates Credentials${C_RESET}"
  echo -e "${C_BOLD}${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  echo "  Portal URL:            ${portal_url}"
  echo "  Robot Username:        ${robot_username}"
  echo "  Robot Password:        ${robot_password}"
  echo "  Robot Client ID:       ${robot_client_id}"
  echo "  Robot Client Secret:   ${robot_client_secret}"
  echo -e "${C_BOLD}${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
  echo ""

  # Persist credentials for downstream use
  cat > "${WORKSHOP_ROOT}/.educates-credentials" <<EOF
# Auto-generated by bootstrap-educates.sh — DO NOT COMMIT
EDUCATES_PORTAL_URL=${portal_url}
EDUCATES_ROBOT_USERNAME=${robot_username}
EDUCATES_ROBOT_PASSWORD=${robot_password}
EDUCATES_ROBOT_CLIENT_ID=${robot_client_id}
EDUCATES_ROBOT_CLIENT_SECRET=${robot_client_secret}
EOF
  chmod 600 "${WORKSHOP_ROOT}/.educates-credentials"
  success "Credentials saved to .educates-credentials"
}

# =============================================================================
# STEP 10b — Create DKP credentials Secret in workshop environment namespace
# =============================================================================
create_dkp_credentials_secret() {
  step "Create DKP credentials Secret for workshop sessions"

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would create dkp-workshop-credentials Secret in workshop environment namespace"
    return
  fi

  # Derive management cluster kubeconfig path (sibling of workload kubeconfig)
  local mgmt_kube="${KUBECONFIG_PATH%/*}/nkp.conf"
  if [[ ! -f "$mgmt_kube" ]]; then
    warn "Management kubeconfig not found at $mgmt_kube — skipping DKP credentials Secret"
    return
  fi

  local dkp_user dkp_pass
  dkp_user=$(kubectl --kubeconfig="$mgmt_kube" get secret dkp-credentials \
    -n kommander -o jsonpath='{.data.username}' 2>/dev/null | base64 -d || true)
  dkp_pass=$(kubectl --kubeconfig="$mgmt_kube" get secret dkp-credentials \
    -n kommander -o jsonpath='{.data.password}' 2>/dev/null | base64 -d || true)

  if [[ -z "$dkp_user" || -z "$dkp_pass" ]]; then
    warn "Could not read dkp-credentials from management cluster — skipping"
    return
  fi

  # Detect ALL workshop training environment namespaces (nkp-workshop-w*).
  # Multiple namespaces exist when the Workshop resource was updated and Educates
  # created a new environment (w16 → w17 → w18 etc). Create the secret in each.
  local env_namespaces
  mapfile -t env_namespaces < <(k get namespace -o name 2>/dev/null \
    | grep "namespace/nkp-workshop-w[0-9]" | cut -d/ -f2 || true)
  if [[ ${#env_namespaces[@]} -eq 0 ]]; then
    warn "Workshop training environment namespace not found — skipping DKP credentials Secret"
    return
  fi

  for env_ns in "${env_namespaces[@]}"; do
    k create secret generic dkp-workshop-credentials \
      -n "$env_ns" \
      --from-literal=username="$dkp_user" \
      --from-literal=password="$dkp_pass" \
      --dry-run=client -o yaml | k apply -f -
    success "DKP credentials Secret created/updated in $env_ns"
  done
}

# =============================================================================
# STEP 11 — Update registration app .env
# =============================================================================
update_env_file() {
  step "Update registration app .env"

  local env_file="${REPO_ROOT}/registration-app/backend/.env"
  [[ -f "$env_file" ]] || { warn ".env not found at ${env_file} — skipping"; return; }

  local creds_file="${WORKSHOP_ROOT}/.educates-credentials"
  [[ -f "$creds_file" ]] || { warn "Credentials file not found — skipping .env update"; return; }

  # Source credentials
  # shellcheck disable=SC1090
  source "$creds_file"

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would update ${env_file}: DRY_RUN=false, EDUCATES_PORTAL_URL=..., etc."
    return
  fi

  # Update each key in-place (add if missing, replace if present)
  update_env_key() {
    local key="$1" value="$2"
    if grep -q "^${key}=" "$env_file"; then
      sed -i "s|^${key}=.*|${key}=${value}|" "$env_file"
    else
      echo "${key}=${value}" >> "$env_file"
    fi
  }

  update_env_key "DRY_RUN"                      "false"
  update_env_key "EDUCATES_PORTAL_URL"           "${EDUCATES_PORTAL_URL}"
  update_env_key "EDUCATES_ROBOT_USERNAME"       "${EDUCATES_ROBOT_USERNAME}"
  update_env_key "EDUCATES_ROBOT_PASSWORD"       "${EDUCATES_ROBOT_PASSWORD}"
  update_env_key "EDUCATES_ROBOT_CLIENT_ID"      "${EDUCATES_ROBOT_CLIENT_ID}"
  update_env_key "EDUCATES_ROBOT_CLIENT_SECRET"  "${EDUCATES_ROBOT_CLIENT_SECRET}"
  update_env_key "CLUSTER_CONTEXT"               \
    "$(kubectl --kubeconfig="$KUBECONFIG_PATH" config current-context 2>/dev/null || echo 'default')"

  success "Updated ${env_file} with live Educates credentials"
  warn "Restart the backend for changes to take effect: uvicorn main:app --reload"
}

# =============================================================================
# STEP 11b — Extract workshop CA certificate from cluster
# =============================================================================
# Populates workshops/nkp-workshop/resources/workshop-ca.crt by:
#   1. Checking for an existing file (idempotent)
#   2. Scanning cert-manager / Traefik secrets for a CA cert
#   3. Falling back to a generated self-signed CA (stored in cluster + file)
# =============================================================================
extract_workshop_ca_cert() {
  step "Extract workshop CA certificate"

  local ca_dest="${WORKSHOP_ROOT}/resources/workshop-ca.crt"

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would extract CA cert from cluster to ${ca_dest}"
    return
  fi

  info "Searching for workshop CA certificate in cluster..."

  local ca_pem=""

  # ── Attempt 0: kommander-ca by name (the real cluster CA) ────────────────
  local raw0
  raw0=$(k get secret -n cert-manager kommander-ca \
         -o jsonpath='{.data.ca\.crt}' 2>/dev/null || true)
  if [[ -n "$raw0" ]]; then
    ca_pem=$(echo "$raw0" | base64 -d)
    info "  Found CA cert in secret cert-manager/kommander-ca"
  fi

  # ── Attempt 1: scan cert-manager CA secrets ──────────────────────────────
  if [[ -z "$ca_pem" ]]; then
    for ns in cert-manager kommander kommander-default-workspace; do
      local secrets
      secrets=$(k get secret -n "$ns" --no-headers 2>/dev/null \
                | awk '{print $1}' || true)
      for secret in $secrets; do
        local raw
        raw=$(k get secret -n "$ns" "$secret" \
              -o jsonpath='{.data.ca\.crt}' 2>/dev/null || true)
        if [[ -n "$raw" ]]; then
          ca_pem=$(echo "$raw" | base64 -d)
          info "  Found CA cert in secret ${ns}/${secret}"
          break 2
        fi
      done
    done
  fi

  # ── Attempt 2: last cert in Traefik / wildcard TLS chain ─────────────────
  if [[ -z "$ca_pem" ]]; then
    for ns in kommander-default-workspace kube-system traefik; do
      local secrets
      secrets=$(k get secret -n "$ns" --no-headers 2>/dev/null \
                | grep -iE "traefik|wildcard|tls|workshop" | awk '{print $1}' || true)
      for secret in $secrets; do
        local raw
        raw=$(k get secret -n "$ns" "$secret" \
              -o jsonpath='{.data.tls\.crt}' 2>/dev/null || true)
        if [[ -n "$raw" ]]; then
          # Extract the last (root CA) cert from the chain
          local last_cert
          last_cert=$(echo "$raw" | base64 -d \
            | awk '/-----BEGIN CERTIFICATE-----/{c=""} {c=c $0 "\n"}
                   /-----END CERTIFICATE-----/{last=c} END{printf "%s", last}')
          if [[ -n "$last_cert" ]]; then
            ca_pem="$last_cert"
            info "  Extracted CA from TLS chain in ${ns}/${secret}"
            break 2
          fi
        fi
      done
    done
  fi

  # ── Attempt 3: generate self-signed CA and install into cert-manager ─────
  if [[ -z "$ca_pem" ]]; then
    warn "No CA cert found in cluster — generating a self-signed workshop CA"
    local tmpkey="/tmp/workshop-ca.key" tmpcrt="/tmp/workshop-ca.crt"
    openssl req -x509 -newkey rsa:2048 -keyout "$tmpkey" -out "$tmpcrt" \
      -days 825 -nodes \
      -subj "/CN=NKP Workshop CA/O=NKP Workshop" \
      -addext "basicConstraints=critical,CA:TRUE" \
      -addext "keyUsage=critical,keyCertSign,cRLSign" 2>/dev/null
    ca_pem=$(cat "$tmpcrt")

    # Store key + cert as a cluster secret so cert-manager can use it later
    k create namespace cert-manager --dry-run=client -o yaml | k apply -f - 2>/dev/null || true
    k create secret tls workshop-ca \
      --namespace=cert-manager \
      --cert="$tmpcrt" --key="$tmpkey" \
      --dry-run=client -o yaml | k apply -f -
    success "Self-signed CA stored as secret cert-manager/workshop-ca"
    rm -f "$tmpkey"
  fi

  mkdir -p "$(dirname "$ca_dest")"
  printf '%s' "$ca_pem" > "$ca_dest"
  success "Workshop CA cert saved: ${ca_dest}"
  openssl x509 -in "$ca_dest" -noout -subject -issuer -dates 2>/dev/null || true
}

# =============================================================================
# STEP 11c — Create kubeconfig Secret in cluster
# =============================================================================
# Packages all auth/*.conf files as a k8s Secret (nkp-kubeconfigs) in the
# nkp-lab-manager namespace so the backend pod can reach both clusters.
# =============================================================================
create_kubeconfig_secret() {
  step "Create kubeconfig Secret in cluster"

  local namespace="nkp-lab-manager"
  local secret_name="nkp-kubeconfigs"

  if ! k get namespace "$namespace" &>/dev/null; then
    warn "Namespace ${namespace} not found — skipping kubeconfig secret (deploy registration app first)"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would create secret ${namespace}/${secret_name} from auth/*.conf files"
    return
  fi

  # Build --from-file args for every kubeconfig present
  local args=()
  for conf in "$REPO_ROOT"/auth/*.conf; do
    [[ -f "$conf" ]] && args+=("--from-file=$(basename "$conf")=$conf")
  done

  if [[ ${#args[@]} -eq 0 ]]; then
    warn "No *.conf files found in auth/ — skipping kubeconfig secret"
    return
  fi

  k create secret generic "$secret_name" \
    --namespace="$namespace" \
    "${args[@]}" \
    --dry-run=client -o yaml | k apply -f -

  success "Kubeconfig secret created: ${namespace}/${secret_name}"
  info "  Files: $(printf '%s ' "${args[@]}" | sed 's/--from-file=//g')"
}

# =============================================================================
# STEP 12 — Deploy standalone cert setup page (LoadBalancer, port 80)
# =============================================================================
deploy_cert_setup_page() {
  step "Deploy certificate setup page"

  local ca_cert="${WORKSHOP_ROOT}/resources/workshop-ca.crt"

  if [[ ! -f "$ca_cert" ]]; then
    warn "workshop-ca.crt not found — skipping cert setup page deployment"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would deploy workshop-cert-setup to namespace workshop-setup"
    return
  fi

  # Load portal URL from credentials file if available
  local portal_url="${PORTAL_URL:-}"
  if [[ -z "$portal_url" && -f "${WORKSHOP_ROOT}/.educates-credentials" ]]; then
    portal_url=$(grep "^EDUCATES_PORTAL_URL=" "${WORKSHOP_ROOT}/.educates-credentials" \
                 | cut -d= -f2- | tr -d '"' || true)
  fi

  local ca_cert_b64
  ca_cert_b64=$(base64 -w0 < "$ca_cert")

  # ── nginx config ──────────────────────────────────────────────────────────
  local nginx_conf
  nginx_conf=$(cat <<'NGINX'
server {
    listen 80;
    root /usr/share/nginx/html;
    index setup.html;
    location / { try_files $uri $uri/ /setup.html; }
}
NGINX
)

  # ── self-contained setup HTML ────────────────────────────────────────────
  # CA cert and portal URL are baked in at deploy time.
  local setup_html
  setup_html=$(cat <<SETUP_HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>NKP Workshop — Certificate Setup</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',Arial,sans-serif;background:#f5f5f5;color:#131313}
.header{background:#4B00AA;color:#fff;padding:20px 32px}
.header .sub{font-size:11px;letter-spacing:2px;opacity:.7;text-transform:uppercase}
.header .title{font-size:20px;font-weight:700;margin-top:4px}
.card{background:#fff;border-radius:10px;box-shadow:0 2px 8px rgba(0,0,0,.1);
      padding:32px;max-width:640px;margin:36px auto;width:calc(100% - 32px)}
h2{font-size:18px;font-weight:700;margin-bottom:8px}
h3{font-size:15px;font-weight:700;margin-bottom:10px;margin-top:24px}
p{font-size:14px;line-height:1.65;color:#555;margin-bottom:16px}
.badge{background:#f0f0f0;border:1px solid #ddd;border-radius:4px;
       padding:3px 10px;font-size:13px;font-weight:600;color:#555;display:inline-block;margin-bottom:20px}
.steps{margin-bottom:24px}
.step{display:flex;gap:14px;margin-bottom:14px;align-items:flex-start}
.step-num{width:28px;height:28px;border-radius:50%;background:#4B00AA;color:#fff;
          display:flex;align-items:center;justify-content:center;
          font-weight:700;font-size:13px;flex-shrink:0;margin-top:1px}
.step-text{font-size:14px;line-height:1.6;padding-top:2px}
.btn{display:inline-block;padding:11px 22px;border-radius:6px;font-size:14px;
     font-weight:700;cursor:pointer;border:none;text-decoration:none;text-align:center}
.btn-primary{background:#4B00AA;color:#fff}
.btn-verify{background:#1FDDE9;color:#131313}
.btn-go{background:#2E7D32;color:#fff;width:100%;padding:14px;font-size:15px;margin-top:8px}
.btn-secondary{font-size:13px;color:#7855FA;background:none;border:none;
               padding:0;cursor:pointer;text-decoration:underline}
.downloads{margin-bottom:28px}
.extra-links{margin-top:10px;font-size:13px;color:#777}
.extra-links a{color:#7855FA}
hr{border:none;border-top:1px solid #e0e0e0;margin:24px 0}
.verify-section{}
.alert{padding:14px 16px;border-radius:6px;font-size:14px;line-height:1.6;margin-top:16px}
.alert-error{background:#FFEBEE;border-left:4px solid #D32F2F;color:#b71c1c}
.alert-success{background:#E8F5E9;border-left:4px solid #2E7D32;color:#1b5e20;font-weight:600}
#verify-btn{margin-top:0}
#status{}
#go-btn{display:none}
</style>
</head>
<body>
<div class="header">
  <div class="sub">Nutanix</div>
  <div class="title">NKP Partner Workshop — Certificate Setup</div>
</div>
<div class="card">
  <div class="badge" id="os-badge">Detecting your OS...</div>

  <h2>One-time certificate setup required</h2>
  <p>This workshop runs on an internal cluster with a self-signed TLS certificate.
     Your browser needs to trust it before you can access your lab session.
     This takes about 2 minutes and is a one-time step.</p>

  <div class="steps" id="steps"></div>

  <div class="downloads">
    <a id="dl-cert" class="btn btn-primary" href="#" download="nkp-workshop-ca.crt">
      &#8659; Download Certificate
    </a>
    <div id="extra-links" class="extra-links"></div>
  </div>

  <hr>

  <div class="verify-section">
    <h3>Verify your browser trusts the certificate</h3>
    <p>After installing the certificate and <strong>restarting your browser</strong>,
       click the button below to confirm it worked.</p>
    <button id="verify-btn" class="btn btn-verify" onclick="doVerify()">&#10003; Verify Certificate</button>
    <div id="status"></div>
    <button id="go-btn" class="btn btn-go" onclick="gotoPortal()">Go to Workshop Portal &rarr;</button>
  </div>
</div>

<script>
// ── Baked in by bootstrap-educates.sh ─────────────────────────────────────
const CA_CERT_B64  = "${ca_cert_b64}";
const PORTAL_URL   = "${portal_url}";
// ──────────────────────────────────────────────────────────────────────────

const PS1 = \`# NKP Workshop CA Certificate Installer — run as Administrator
\\\$scriptDir = Split-Path -Parent \\\$MyInvocation.MyCommand.Path
\\\$certFile  = Join-Path \\\$scriptDir "nkp-workshop-ca.crt"
if (-not (Test-Path \\\$certFile)) { Write-Host "ERROR: nkp-workshop-ca.crt not found next to this script." -ForegroundColor Red; pause; exit 1 }
Write-Host "Installing..." -ForegroundColor Cyan
certutil -addstore -f "Root" "\\\$certFile"
if (\\\$LASTEXITCODE -eq 0) { Write-Host "Done! Restart your browser." -ForegroundColor Green } else { Write-Host "ERROR: run as Administrator." -ForegroundColor Red }
pause\`;

const BAT = \`@echo off
echo NKP Workshop CA Certificate Installer - Run as Administrator
certutil -addstore -f "Root" "%~dp0nkp-workshop-ca.crt"
if %errorlevel%==0 ( echo Done! Restart your browser. ) else ( echo ERROR: Run as Administrator. )
pause\`;

function b64ToBlob(b64, mime) {
  const bin = atob(b64), arr = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) arr[i] = bin.charCodeAt(i);
  return new Blob([arr], {type: mime});
}
function textBlob(text) { return new Blob([text], {type: 'text/plain'}); }
function blobUrl(blob) { return URL.createObjectURL(blob); }

function detectOS() {
  const ua = navigator.userAgent;
  if (/iPhone|iPad|iPod/i.test(ua)) return 'ios';
  if (/Android/i.test(ua)) return 'android';
  if (/Macintosh|MacIntel/i.test(ua)) return 'macos';
  if (/Win/i.test(ua)) return 'windows';
  if (/Linux/i.test(ua)) return 'linux';
  return 'unknown';
}

const STEPS = {
  macos: [
    'Click "Download Certificate" below.',
    'The file opens in Keychain Access automatically. Click <strong>Add</strong>.',
    'In Keychain Access, find <strong>NKP Workshop CA</strong> under the System keychain. Double-click it.',
    'Expand <strong>Trust</strong> &rarr; set "When using this certificate" to <strong>Always Trust</strong>. Close the window and enter your password.',
    'Quit and restart your browser, then click <strong>Verify</strong> below.'
  ],
  ios: [
    'Tap "Download Certificate" below.',
    'Go to <strong>Settings &rarr; General &rarr; VPN &amp; Device Management</strong> &rarr; tap the downloaded profile &rarr; <strong>Install</strong>.',
    'Go to <strong>Settings &rarr; General &rarr; About &rarr; Certificate Trust Settings</strong> and enable full trust for <strong>NKP Workshop CA</strong>.',
    'Return here and tap <strong>Verify</strong>.'
  ],
  windows: [
    'Click "Download Installer (.ps1)" below — save it to a folder.',
    'Also download the certificate and save it to <strong>the same folder</strong>.',
    'Right-click <strong>Install-NKP-Workshop-CA.ps1</strong> &rarr; <strong>Run with PowerShell</strong>. Approve any admin prompt.',
    'Alternatively, rename the .ps1 to .bat and double-click &rarr; Run as administrator.',
    'Restart your browser, then click <strong>Verify</strong> below.'
  ],
  android: [
    'Tap "Download Certificate" below.',
    'Go to <strong>Settings &rarr; Security &rarr; Install from storage</strong> (exact wording varies by device).',
    'Select the downloaded file. Name it <strong>NKP Workshop CA</strong> and install as <strong>CA certificate</strong>.',
    'Return here and tap <strong>Verify</strong>.'
  ],
  linux: [
    'Click "Download Certificate" below.',
    'Run: <code>sudo cp nkp-workshop-ca.crt /usr/local/share/ca-certificates/ &amp;&amp; sudo update-ca-certificates</code>',
    'For Chrome: Settings &rarr; Privacy &amp; Security &rarr; Security &rarr; Manage certificates &rarr; Authorities &rarr; Import.',
    'Restart your browser, then click <strong>Verify</strong>.'
  ],
  unknown: [
    'Download the certificate below.',
    'Install it as a trusted root CA in your operating system certificate store.',
    'Restart your browser, then click <strong>Verify</strong>.'
  ]
};

const OS_LABELS = {
  macos:'macOS \uD83C\uDF4E', ios:'iPhone/iPad \uD83D\uDCF1',
  windows:'Windows \uD83E\uDE9F', android:'Android \uD83E\uDD16',
  linux:'Linux \uD83D\uDC27', unknown:'Your Device \uD83D\uDCBB'
};

const os = detectOS();
document.getElementById('os-badge').textContent = 'Detected: ' + OS_LABELS[os];

// Render steps
const stepsEl = document.getElementById('steps');
(STEPS[os] || STEPS.unknown).forEach((text, i) => {
  stepsEl.innerHTML += \`<div class="step">
    <div class="step-num">\${i+1}</div>
    <div class="step-text">\${text}</div>
  </div>\`;
});

// Set up download links
const certBlob = b64ToBlob(CA_CERT_B64, 'application/x-x509-ca-cert');
const certUrl  = blobUrl(certBlob);
const dlCert   = document.getElementById('dl-cert');
dlCert.href    = certUrl;

const extraEl  = document.getElementById('extra-links');
if (os === 'windows') {
  dlCert.textContent = '\u2B07 Download Certificate (.crt)';
  const ps1Url = blobUrl(textBlob(PS1));
  const batUrl = blobUrl(textBlob(BAT));
  extraEl.innerHTML =
    \`Also: <a href="\${ps1Url}" download="Install-NKP-Workshop-CA.ps1">PowerShell installer (.ps1)</a>
     &middot; <a href="\${batUrl}" download="install-nkp-workshop-ca.bat">Batch installer (.bat)</a>
     <br><em>Save cert and installer to the same folder before running.</em>\`;
}

// Verify
async function doVerify() {
  const btn = document.getElementById('verify-btn');
  const st  = document.getElementById('status');
  if (!PORTAL_URL) {
    st.innerHTML = '<div class="alert alert-error"><strong>Portal URL not configured.</strong> Ask your trainer for the correct setup URL.</div>';
    return;
  }
  btn.textContent = '\u23F3 Checking...';
  btn.disabled = true;
  try {
    await fetch(PORTAL_URL, {mode:'no-cors', cache:'no-store'});
    st.innerHTML = '<div class="alert alert-success">\u2705 Certificate trusted! Your browser can connect to the workshop.</div>';
    document.getElementById('go-btn').style.display = 'block';
    btn.style.display = 'none';
  } catch(_) {
    st.innerHTML = '<div class="alert alert-error"><strong>Not trusted yet.</strong> Make sure you completed all steps above and restarted your browser completely, then try again.</div>';
    btn.textContent = '\u2713 Verify Certificate';
    btn.disabled = false;
  }
}

function gotoPortal() { window.location.href = PORTAL_URL; }
</script>
</body>
</html>
SETUP_HTML
)

  # Create namespace
  k create namespace workshop-setup --dry-run=client -o yaml | k apply -f -

  # Create ConfigMaps
  k create configmap workshop-cert-setup-nginx \
    --namespace=workshop-setup \
    --from-literal=default.conf="$nginx_conf" \
    --dry-run=client -o yaml | k apply -f -

  k create configmap workshop-cert-setup-html \
    --namespace=workshop-setup \
    --from-literal=setup.html="$setup_html" \
    --dry-run=client -o yaml | k apply -f -

  # Deploy
  k apply -f "${WORKSHOP_ROOT}/resources/cert-setup.yaml"

  # Wait for LB IP
  info "Waiting for LoadBalancer IP..."
  local setup_ip="" elapsed=0
  until [[ -n "$setup_ip" ]]; do
    (( elapsed >= 120 )) && { warn "Timed out waiting for cert-setup LoadBalancer IP"; return; }
    setup_ip=$(k get svc workshop-cert-setup -n workshop-setup \
      -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)
    [[ -z "$setup_ip" ]] && { sleep 5; (( elapsed += 5 )); }
  done

  success "Certificate setup page: http://${setup_ip}/"
  info "Share this URL with attendees before the workshop starts."

  # Store for use in summary
  CERT_SETUP_URL="http://${setup_ip}/"
}

# =============================================================================
# STEP 13 — Publish CA cert to registration app ConfigMap
# =============================================================================
create_ca_configmap() {
  step "Publish workshop CA cert to registration app ConfigMap"

  local ca_cert="${WORKSHOP_ROOT}/resources/workshop-ca.crt"
  local namespace="nkp-lab-manager"

  if [[ ! -f "$ca_cert" ]]; then
    warn "workshop-ca.crt not found at ${ca_cert} — skipping ConfigMap creation"
    warn "Generate a wildcard cert first and save it to resources/workshop-ca.crt"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would create ConfigMap workshop-ca-cert in namespace ${namespace} from ${ca_cert}"
    return
  fi

  if ! k get namespace "$namespace" &>/dev/null; then
    warn "Namespace ${namespace} not found — skipping CA ConfigMap (registration app not deployed yet)"
    return
  fi

  k create configmap workshop-ca-cert \
    --namespace="$namespace" \
    --from-file=workshop-ca.crt="$ca_cert" \
    --dry-run=client -o yaml | k apply -f -

  success "ConfigMap workshop-ca-cert updated in namespace ${namespace}"

  # Restart backend so the new cert mount is picked up immediately
  if k get deployment nkp-lab-manager-backend -n "$namespace" &>/dev/null; then
    k rollout restart deployment/nkp-lab-manager-backend -n "$namespace" &>/dev/null || true
    info "Backend restarted to pick up new CA cert"
  fi
}

# =============================================================================
# STEP 13 — Apply registration app IngressRoute
# =============================================================================
apply_registration_ingressroute() {
  step "Apply registration app IngressRoute"

  local ingressroute="${REPO_ROOT}/registration-app/k8s/ingressroute.yaml"
  local namespace="nkp-lab-manager"

  if [[ ! -f "$ingressroute" ]]; then
    warn "ingressroute.yaml not found at ${ingressroute} — skipping"
    return
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would apply IngressRoute for nkp-lab-manager.${INGRESS_DOMAIN}"
    return
  fi

  if ! k get namespace "$namespace" &>/dev/null; then
    warn "Namespace ${namespace} not found — skipping IngressRoute (registration app not deployed)"
    return
  fi

  DOMAIN="$INGRESS_DOMAIN" envsubst < "$ingressroute" | k apply -f -
  success "IngressRoute applied: http://nkp-lab-manager.${INGRESS_DOMAIN} and https://nkp-lab-manager.${INGRESS_DOMAIN}"
}

# =============================================================================
# STEP 14 — End-to-end verification
# =============================================================================
verify_e2e() {
  step "End-to-end verification"

  if [[ "$DRY_RUN" == "true" ]]; then
    dry "Would verify: TrainingPortal Running, portal URL reachable, robot auth"
    return
  fi

  local fail=0

  # 1. TrainingPortal phase
  local phase
  phase=$(k get trainingportal "$WORKSHOP_NAME" \
    -o jsonpath='{.status.educates.phase}' 2>/dev/null || echo "unknown")
  if [[ "$phase" == "Running" ]]; then
    success "TrainingPortal phase: Running"
  else
    warn "TrainingPortal phase: ${phase} (expected Running)"
    (( fail++ ))
  fi

  # 2. Portal URL reachable
  if [[ -n "${PORTAL_URL:-}" ]]; then
    local http_code
    http_code=$(curl -sk -o /dev/null -w "%{http_code}" --max-time 10 "$PORTAL_URL" || echo "000")
    if [[ "$http_code" =~ ^(200|301|302|303)$ ]]; then
      success "Portal URL reachable: ${PORTAL_URL} (HTTP ${http_code})"
    else
      warn "Portal URL returned HTTP ${http_code}: ${PORTAL_URL}"
      (( fail++ ))
    fi
  fi

  # 3. WorkshopEnvironment created (created on first session request, may be empty initially)
  local envs=0
  envs=$(k get workshopenvironment -A --no-headers 2>/dev/null | { grep -c "$WORKSHOP_NAME" || true; })
  envs="${envs//[^0-9]/}"  # strip any non-numeric chars
  envs="${envs:-0}"
  if [[ "$envs" -gt 0 ]]; then
    success "WorkshopEnvironment(s): ${envs} active"
  else
    warn "No WorkshopEnvironments yet — they are created on first session request (normal at this stage)"
  fi

  # 4. Robot auth
  if [[ -f "${WORKSHOP_ROOT}/.educates-credentials" ]]; then
    source "${WORKSHOP_ROOT}/.educates-credentials"
    if [[ -n "${EDUCATES_PORTAL_URL:-}" && -n "${EDUCATES_ROBOT_CLIENT_ID:-}" ]]; then
      local token_resp
      token_resp=$(curl -sk --max-time 10 \
        -d "grant_type=password&client_id=${EDUCATES_ROBOT_CLIENT_ID}&client_secret=${EDUCATES_ROBOT_CLIENT_SECRET}&username=${EDUCATES_ROBOT_USERNAME}&password=${EDUCATES_ROBOT_PASSWORD}" \
        "${EDUCATES_PORTAL_URL}/oauth2/token/" || echo "")
      if echo "$token_resp" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if 'access_token' in d else 1)" 2>/dev/null; then
        success "Robot OAuth2 token obtained"
      else
        warn "Robot OAuth2 auth failed — check credentials"
        (( fail++ ))
      fi
    fi
  fi

  echo ""
  if (( fail == 0 )); then
    echo -e "${C_BOLD}${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo -e "${C_BOLD}  ALL CHECKS PASSED — Workshop is live!${C_RESET}"
    echo -e "${C_BOLD}${C_GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo "  Portal:  ${PORTAL_URL:-<not available>}"
    echo "  Setup:   ${CERT_SETUP_URL:-<run deploy_cert_setup_page to get URL>}  ← send this to attendees first"
    echo "  ArgoCD:  http://10.8.16.55  (check ip with: kubectl -n argocd get svc argocd-server)"
    echo "  App:     http://$(k -n istio-system get svc istio-ingressgateway \
      -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '<detect>')"
    echo ""
  else
    echo -e "${C_BOLD}${C_YELLOW}  ${fail} CHECK(S) FAILED — Review warnings above${C_RESET}"
  fi
}

# =============================================================================
# MAIN
# =============================================================================
main() {
  echo ""
  echo -e "${C_BOLD}${C_CYAN}╔══════════════════════════════════════════════════╗${C_RESET}"
  echo -e "${C_BOLD}${C_CYAN}║  NKP Workshop — Educates Bootstrap               ║${C_RESET}"
  echo -e "${C_BOLD}${C_CYAN}╚══════════════════════════════════════════════════╝${C_RESET}"
  echo "  Repo:     ${REPO_ROOT}"
  echo "  Workshop: ${WORKSHOP_ROOT}"
  echo "  State:    ${STATE_FILE}"
  [[ "$DRY_RUN" == "true" ]] && echo -e "  ${C_YELLOW}MODE: DRY RUN — no changes will be made${C_RESET}"
  echo ""

  parse_args "$@"

  preflight_check
  install_educates_cli
  discover_cluster_params
  generate_platform_config
  deploy_educates_platform
  wait_platform_ready
  publish_workshop
  apply_observability_stack
  apply_training_portal
  wait_portal_ready
  extract_credentials
  create_dkp_credentials_secret
  update_env_file
  extract_workshop_ca_cert
  deploy_cert_setup_page
  create_ca_configmap
  create_kubeconfig_secret
  apply_registration_ingressroute
  verify_e2e

  echo ""
  success "Bootstrap complete. State file: ${STATE_FILE}"
  info "Re-run with --reset-state to force a fresh install."
}

main "$@"
