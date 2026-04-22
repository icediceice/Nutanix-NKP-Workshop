---
title: "Lab 3: Exploring NKP via Kommander (1 hr)"
---

## Goal

Explore the NKP management platform through **Kommander** — understand what it gives
a platform team out of the box, without writing a single command.

> Click **<a href="https://kommander.nkp.nuth-lab.xyz" target="_blank">Open Kommander ↗</a>**
> and keep it open for this entire lab.

---

## 1 — The Dashboard

When Kommander opens you land on the main dashboard.

**Look at:**
- How many clusters are registered?
- What is the overall health status?
- What workspaces exist?

> A workspace is a logical boundary — think of it as a tenant or team boundary inside NKP.
> Platform teams can grant different groups access to different workspaces.

---

## 2 — Clusters

In the left navigation click **Clusters**.

**Explore:**
- Find `workload01` — what status does it show?
- Click `workload01` — what information is shown about the cluster?
  - Node count, Kubernetes version, resource usage
- Notice the **Platform Services** tab — these are the add-ons NKP manages on this cluster.

> Platform Services are Helm charts deployed and lifecycle-managed by Kommander.
> You don't manage them manually — Kommander keeps them reconciled.

---

## 3 — Applications Catalog

In the left navigation click **Applications** (or find it under the `workload01` cluster view).

**Explore:**
- Browse the catalog grid — what categories of applications are available?
- Find applications that are already **Enabled** (green) vs **Available** (grey).
- Click one enabled application — what information does the detail view show?
  - Chart version, values, last reconcile time

> Every enabled application is a HelmRelease managed by Flux under the hood.
> When you click Enable, Kommander creates the HelmRelease — nothing runs on your laptop.

**Find your Lab 2 deployment:**
- In the left navigation go to **Continuous Delivery** → **Kustomizations**.
- Can you find `bls-app-$(session_name)`? What does it show?
- Click it — see the resources it manages (8 Kubernetes objects, all from one Git commit).

---

## 4 — Continuous Delivery

Stay in **Continuous Delivery** and explore both tabs.

**GitRepositories:**
- What repositories is this cluster watching?
- Find `bls-app-source-$(session_name)` — what branch and commit is it tracking?

**Kustomizations:**
- How many Kustomizations are running across the cluster?
- Notice the reconciliation interval and last applied revision for each.

> Every application you see in this cluster — including the platform services — is
> deployed and kept in sync through this GitOps pipeline. Nothing was applied manually.

---

## 5 — Platform Services on workload01

Navigate to **Clusters** → `workload01` → **Platform Services**.

**Explore:**
- Which services are currently enabled?
- Find **Prometheus** and **cert-manager** — what version are they running?
- Is there a service you would want to enable for your own platform team?

> Platform Services are pre-validated, pre-integrated, and lifecycle-managed.
> Your team gets a production-grade Prometheus stack with one toggle — no Helm commands,
> no values files to manage manually.

---

## 6 — Access Control

In the left navigation find **Administration** → **Access Control** (or **Identity**).

**Explore:**
- What identity providers are connected?
- What roles exist?
- How would you give a new team member access to only `workload01`?

> NKP uses Dex for identity federation — connect your corporate LDAP, OIDC, or SAML
> provider once, and all clusters inherit the access control.

---

## 7 — What Would You Enable?

Take 5 minutes and browse freely. If you were setting up a platform for your organisation:

- Which catalog applications would you enable on day one?
- What is missing that you would want?
- How would you organise workspaces for your teams?

Share your thoughts with the group — your facilitator will take notes for the discussion.
