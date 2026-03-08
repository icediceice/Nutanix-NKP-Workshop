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
# STEP 12 — End-to-end verification
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
  apply_training_portal
  wait_portal_ready
  extract_credentials
  update_env_file
  verify_e2e

  echo ""
  success "Bootstrap complete. State file: ${STATE_FILE}"
  info "Re-run with --reset-state to force a fresh install."
}

main "$@"
