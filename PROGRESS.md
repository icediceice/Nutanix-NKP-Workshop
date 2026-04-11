# Project: Nutanix-NKP-Workshop

> Initialized: 2026-03-07 22:21
> Last updated: 2026-04-11

## NotebookLM

- **Notebook:** Nutanix-NKP-Workshop Docs
- **ID:** `134a02d9-3382-4fcc-a9a8-f634f56b14a9`
- **Sources:** FastAPI, SQLAlchemy 2.0, Pydantic v2, Vite, Kubernetes Client Libraries
- **Failed sources:** docs.educates.dev (site blocked by NotebookLM — add manually if needed)

## Current Focus

Building TLS certificate setup page for workshop attendees — `/setup` route in registration app that auto-detects OS, serves CA cert + install scripts, verifies trust, then redirects to portal.

## Task Queue

Upcoming work in priority order:

- [x] **Cert setup page** — `/setup` route: OS-detect, serve ca.crt + PS1/BAT/zip, verify HTTPS, redirect to portal
- [x] Bootstrap: create `workshop-ca-cert` ConfigMap + mount into backend pod
- [ ] **BLOCKED: Push images to GHCR** — PAT needs `write:packages` scope. Re-login then run:
      `sudo docker push ghcr.io/icediceice/nkp-lab-manager-backend:latest`
      `sudo docker push ghcr.io/icediceice/nkp-lab-manager-frontend:latest`
      Images are already built locally. After push: restart deployments on cluster.
- [ ] Smoke-test real Educates provisioning end-to-end (needs cluster)
- [ ] Workshop content expansion (placeholder stubs in workshops/)
- [ ] Excel bulk import UI improvements
- [ ] Admin password: implement real backend auth endpoint

## Tier Overrides

*(Populated by escalation events. Survives compaction — do not remove.)*

## Work Log

### 2026-04-11

#### session — Workshop Architecture Overhaul (Hugo+VPS) — complete
- **What:** Migrated NKP workshop content delivery from Educates renderer to Hugo static site on VPS. Educates now provides terminal+editor only (no proxy tabs). Content at https://light.factor-io.com/workshop/nkp-workshop/. Added Hugo scaffold, migration scripts (terminal:execute→bash, dashboard→URL), Makefile deploy pipeline, stripped workshop.yaml proxy tabs, updated StatusPage to single Terminal cert-bypass + VPS content link.
- **Files:** `workshops/nkp-workshop/hugo/`, `workshops/template/`, `workshops/migrate-*.py`, `Makefile`, `workshops/nkp-workshop/resources/workshop.yaml`, `workshops/nkp-workshop/workshop/content/*.md`, `registration-app/frontend/src/components/StatusPage.jsx`, `workshops/partner-intro/resources/workshop.yaml`
- **Commit:** `615eacc`
- **Next:** Step 9 — smoke-test on live cluster (content cert-free, terminal 1 bypass, LB URLs reachable)
- **Known issues:** Step 9 requires live cluster — manual verification pending

### 2026-03-09 (continued)

#### session — Jaeger white page fix — complete
- **What:** Jaeger v2.15.1 (chart 4.5.0) ignores `allInOne.args` — binary runs with `args: null`. `<base href="/">` in HTML caused all JS assets to 404. Fixed by replacing broken flag with `userconfig` (full OTEL Collector config) setting `extensions.jaeger_query.base_path: /dkp/jaeger`. Memory storage via `jaeger_storage.backends.memstore.memory`.
- **Files:** `workshops/nkp-workshop/resources/observability/jaeger.yaml`
- **Next:** Apply on cluster: `kubectl apply -f jaeger.yaml -n argocd` then verify `curl https://<ingress>/dkp/jaeger/ | grep 'base href'` returns `/dkp/jaeger/`
- **Known issues:** No known issues

### 2026-03-09

#### session — Per-session namespace isolation — complete
- **What:** All storefront resources had hardcoded `namespace: demo-app`/`demo-ops`, causing all attendees to share one namespace. Fixed via ArgoCD `source.kustomize.namespace: $(session_namespace)` (Educates resolves the var per-session). Added inline kustomize patches for demo-wall `APP_NAMESPACE` and loadgen `TARGET_HOST` ConfigMap values. Removed `namespace.yaml` Namespace creation from all kustomize overlays (8 files). Fixed loadgen FQDN → short name. Fixed Demo Wall dashboard URL.
- **Files:** `workshop.yaml`, `storefront/base/kustomization.yaml`, 7 overlay kustomizations, `loadgen/base/deployment.yaml`
- **Next:** Start session from w07 portal and verify: frontend DNS resolves, no SharedResourceWarning, each session isolated
- **Known issues:** "Workshop Failed" banner still appears — setup script CRLF+pipefail issue is in git but workshop FILES IMAGE (`nkp-workshop-files:latest`) needs rebuild via `educates publish workshop` to pick up the fix

#### session — Workshop Failed fix — complete
- **What:** `$(workshop_namespace)` is not a valid Educates variable → CiliumNetworkPolicy creation failed → "Workshop Failed". Removed the CNP from session.objects. Fixed ClusterRoleBinding subject namespace to `$(environment_name)`. Fixed setup script: removed `set -eo pipefail`, switched INGRESS_DOMAIN detection from Istio → Traefik (NKP), reduced ArgoCD wait from 120s to 60s.
- **Files:** `workshops/nkp-workshop/resources/workshop.yaml`, `workshops/nkp-workshop/workshop/setup.d/01-setup-session.sh`
- **Next:** Re-deploy workshop and verify no "Workshop Failed"; verify `kubectl get nodes` works in session terminal
- **Known issues:** `$(environment_name)` used for ClusterRoleBinding subject namespace — needs cluster verification that this resolves to `nkp-workshop-w05` (the env namespace where session SAs live)

#### session — Workshop RBAC + Cilium egress fix — complete
- **What:** `kubectl get nodes` was forbidden because Educates session service accounts have no cluster-level RBAC by default. Added `ClusterRole` + `ClusterRoleBinding` in `session.objects` (nodes/namespaces/pvs/storageclasses). Also added per-session `CiliumNetworkPolicy` in `$(workshop_namespace)` to allow workshop pod egress to session namespace (needed for Storefront dashboard tab proxy). Frontend DNS 404 at session start is by design — `lab-01-start` intentionally deploys no app workloads.
- **Files:** `workshops/nkp-workshop/resources/workshop.yaml`
- **Next:** Smoke-test real Educates provisioning end-to-end (needs cluster); verify `$(workshop_namespace)` is a valid Educates template variable
- **Known issues:** `$(workshop_namespace)` used for SA namespace in ClusterRoleBinding — needs cluster-level verification that this variable resolves correctly in Educates 3.6

### 2026-03-08 (continued)

#### session — Setup page auto-cert + kubeconfig integration — complete
- **What:** Setup page now works in every deployment without manual cert prep. Bootstrap auto-extracts CA cert from cluster (cert-manager/Traefik secrets, self-signed CA fallback). auth/*.conf files packaged as k8s Secret. Backend deployment mounts kubeconfigs + sets KUBECONFIG_PATH. setup.py has k8s-client fallback to auto-discover cert if ConfigMap is missing.
- **Files:** `bootstrap-educates.sh`, `deployment.yaml`, `routers/setup.py`, `ingressroute.yaml`
- **Next:** Smoke-test real Educates provisioning end-to-end (needs cluster)
- **Known issues:** No known issues

### 2026-03-08

#### 00:00 — Cert setup page — starting implementation
- **What:** Building `/setup` landing page into registration-app backend + frontend. Serves CA cert, PowerShell/batch install scripts, ZIP bundle. OS-detect in browser, HTTPS verify, redirect to portal.
- **Files:** `registration-app/backend/routers/setup.py`, `registration-app/frontend/src/components/SetupPage.jsx`, `registration-app/k8s/deployment.yaml`, `workshops/nkp-workshop/scripts/bootstrap-educates.sh`
- **Next:** Implement backend router → frontend component → k8s changes → bootstrap script

### 2026-03-07

#### 22:21 — Workflow discipline applied
- **What:** Project initialized with EDCR scaffold. .claude/ deployed, PROGRESS.md created, NotebookLM notebook created with 5 sources.
- **Files:** PROGRESS.md, .geminiignore, .claude/ (references, templates, history, settings, active-plan)
- **Next:** Awaiting first task
- **Known issues:** docs.educates.dev blocked by NotebookLM scraper
