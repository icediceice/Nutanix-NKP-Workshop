---
title: "NKP Console Walkthrough"
---

> **This section is facilitator-led.** Your facilitator will share their screen and navigate
> the NKP console live. Follow along and note what is visible at each step.

---

## Opening the Console

The NKP console URL is shown on the Demo Wall under **Platform Access → Kommander**.

All navigation below is relative to that base URL.

---

## Stop 1 — Multi-Cluster Fleet

**Where**: `/dkp/kommander/dashboard` → **Clusters**

**What you will see**:
- Every cluster managed by this Kommander instance
- Cluster version, health status, and node count
- Live CPU and memory utilisation per cluster

**The point**: One Kommander instance manages the entire fleet. Add a new cluster and it
inherits the same policies, add-ons, and RBAC automatically — no per-cluster setup.

---

## Stop 2 — Resource Quotas

**Where**: **Clusters** → select workload cluster → **Namespaces** → `demo-app`

**What you will see**:
- Live quota usage: pods, CPU requests, memory requests against the hard limits
- The `demo-ops` namespace has a tighter budget — separate teams, separate guardrails

**The point**: Every team namespace has a hard quota enforced by the platform. A rogue
deployment cannot starve the rest of the cluster. These quotas are defined in Git and
deployed by GitOps — no one had to SSH into a node.

**Verify in your terminal**:

```terminal:execute
command: kubectl describe resourcequota demo-app-quota -n demo-app
```

---

## Stop 3 — RBAC / Access Control

**Where**: `/dkp/kommander/dashboard` → **Access Control** → **Roles**

**What you will see**:
- `dev-role-demo-app` — read-only: list/get pods, deployments, services
- `ops-role-demo-app` — read-write: full workload management
- Bindings showing which groups hold which roles

**The point**: Developers can observe their workloads but cannot change replicas or edit
Deployments. Operators get full access. Nobody has cluster-admin by default.

---

## Stop 4 — Application Catalog

**Where**: `/dkp/kommander/dashboard` → **Applications** (workspace-scoped tab)

**What you will see**:
- Istio, Kiali, Jaeger, Grafana — all showing `Deployed` / healthy
- Each was enabled by a single manifest committed to Git — no manual Helm installs

**Verify in your terminal**:

```terminal:execute
command: kubectl get appdeployments -A 2>/dev/null || kubectl get helmreleases -n kommander-default-workspace -o wide
```

**The point**: The entire observability stack was deployed from NKP's app catalog with one
GitOps commit. Every new cluster onboarded to this workspace gets the same stack automatically.

---

## Stop 5 — Kubeconfig for Users

**Where**: **Clusters** → select cluster → **Download Kubeconfig**

**What you will see**:
- An admin kubeconfig for the cluster (scoped to admin RBAC)
- The portal also generates user-scoped kubeconfigs tied to SSO identity

**Verify in your terminal**:

```terminal:execute
command: kubectl get secrets -A | grep kubeconfig
```

**The point**: Admin kubeconfigs live in Secrets and are treated like root passwords. User
kubeconfigs from the portal are scoped to the user's RBAC and expire automatically. This
separation matters for security and audit compliance.

---

## Summary — What the Console Showed

| Capability | Surface |
|-----------|---------|
| Fleet overview (all clusters, health, versions) | Kommander → Clusters |
| Live quota usage per namespace | Kommander → Namespaces |
| RBAC roles and bindings | Kommander → Access Control |
| Platform add-ons deployed via GitOps | Kommander → Applications |
| Kubeconfig download (admin + user-scoped) | Kommander → Clusters → Download |

Everything in this console was provisioned from Git. The console is a read/write view of the
same state that kubectl and GitOps manage. There is one source of truth.

---

## Next

Your facilitator will now show the ecommerce application running live on this cluster —
with service mesh observability and a real incident scenario.
