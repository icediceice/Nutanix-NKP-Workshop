---
title: "Lab 1: Workload Cluster Provisioning (45 min)"
---

## Goal

Understand how NKP manages workload clusters from the Kommander console. You will explore the
cluster management UI and register an existing cluster (`workload01`) into Kommander.

---

## Background

NKP uses **Cluster API (CAPI)** under the hood. Every cluster — whether created new or registered —
becomes a managed object in Kommander. From that point, you can:

- Deploy platform applications to it centrally
- Monitor it from the shared observability stack
- Apply RBAC and policies consistently across all clusters

**Two paths to add a cluster in NKP:**

| Path | When to use |
|------|-------------|
| **Create new cluster** | Provision fresh VMs via NKP on AHV, vSphere, or cloud |
| **Register existing cluster** | Attach a pre-existing Kubernetes cluster (any CAPI-compatible) |

In this lab you will use the **Register** path to attach `workload01`.

---

## Step 1 — Log In to Kommander

1. Open `http://10.38.49.15` in your browser.
2. Log in with the credentials your facilitator provided.
3. You should land on the **Kommander Dashboard** — the global overview page.

---

## Step 2 — Explore the Clusters View

1. In the left navigation, click **Clusters**.
2. You will see the management cluster listed as **Host Cluster**.
3. Take note of the columns: **Name**, **Status**, **Kubernetes Version**, **Provider**, **Age**.

> **Observe:** The management cluster is always present. Workload clusters appear here once registered or provisioned.

---

## Step 3 — Add a Cluster (New Provision — Guided Tour)

Even if you are registering an existing cluster, walk through the wizard first to understand the options.

1. Click **Add Cluster** (top-right button).
2. Two options appear:
   - **Create New Cluster** — provisions infrastructure + Kubernetes from scratch
   - **Register Existing Cluster** — attaches a running cluster via a kubeconfig or agent

3. Click **Create New Cluster** to explore the form:
   - **Infrastructure Provider:** Nutanix (AHV), VMware vSphere, AWS, Azure
   - **Cluster Name:** A unique identifier
   - **Node Pools:** Separate configurations for control-plane and worker nodes
   - **Kubernetes Version:** Pick the target version (e.g., 1.29.x)
   - **CNI Plugin:** Cilium (default on NKP)

4. **Do not submit** — press **Cancel** to return.

> This wizard is how platform teams provision production clusters in minutes.

---

## Step 4 — Register workload01

1. Click **Add Cluster** again.
2. Select **Register Existing Cluster**.
3. Fill in the form:
   - **Cluster Name:** `workload01`
   - **Display Name:** `BLS Workshop — Workload 01`
4. Click **Generate** — Kommander creates a **registration manifest** (a small YAML that installs an agent).
5. Copy the `kubectl apply` command shown on screen.
6. Open a terminal and apply it against `workload01`:

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl apply -f <registration-manifest-url>
```

7. Return to the Kommander UI. Within 1–2 minutes `workload01` appears in the cluster list with status **Joining**, then **Ready**.

> **Checkpoint ✅** — `workload01` shows **Ready** in the Clusters view.

---

## Step 5 — Explore the Cluster Detail

1. Click on `workload01` in the cluster list.
2. Review the **Overview** tab:
   - Control-plane nodes and worker nodes
   - Kubernetes version
   - CPU / memory allocation (from Prometheus)
3. Click the **Add-ons** tab — platform applications deployed to this cluster are listed here.
4. Click the **Nodes** tab — each node shows its status, role, and resource usage.

---

## Step 6 — Verify via CLI

Optional confirmation from the terminal:

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf kubectl get nodes
```

Expected output: all nodes in `Ready` state.

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf kubectl cluster-info
```

Shows the API server endpoint at `10.38.49.18:6443`.

---

## Summary

You explored the NKP Kommander cluster management UI and registered `workload01` as a managed
workload cluster. In the remaining labs you will deploy applications, enable services,
and operate this cluster entirely through Kommander.
