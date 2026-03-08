# Project: Nutanix-NKP-Workshop

> Initialized: 2026-03-07 22:21
> Last updated: 2026-03-08 00:00

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

### 2026-03-09

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
