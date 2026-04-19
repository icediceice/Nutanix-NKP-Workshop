---
title: "Lab 5: Production Operations — Day-2 Ops (1 hr)"
---

## Goal

Experience the full Day-2 operations lifecycle on `workload01`: scale a node pool, perform a
Kubernetes version upgrade, explore backup and restore concepts, and practice common
troubleshooting techniques — all driven from the NKP Kommander UI.

---

## Background

"Day-2" refers to everything that happens after a cluster is running: keeping it healthy,
scaling it to meet demand, upgrading it safely, and recovering it when things go wrong.
NKP centralises all of this into Kommander so you don't need direct access to each cluster's
control plane.

| Operation | NKP Mechanism |
|-----------|--------------|
| Scale nodes | Modify `MachineDeployment` replica count via UI or CLI |
| Upgrade Kubernetes | NKP upgrade wizard (CAPI rolling replacement) |
| Backup / Restore | Velero integration or snapshot-based backup |
| Troubleshoot | Kommander UI events, kubectl, NKP AI Navigator |

---

## Part A — Node Scaling (20 min)

### Step A1 — View Current Node Pools

1. Kommander → **Clusters** → `workload01` → **Nodes** tab.
2. Identify the worker node pool (e.g., `worker-pool-0`).
3. Note the current node count (typically 3 workers).

From the CLI:

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl get machinedeployment -A
```

### Step A2 — Scale Out (Add a Node)

**Via Kommander UI:**

1. Click the worker node pool name.
2. Click **Edit** (pencil icon).
3. Change **Replicas** from `3` to `4`.
4. Click **Save**.

Kommander instructs CAPI to provision a new VM and join it to the cluster. Monitor the new node:

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl get nodes -w
```

Watch for a new node reaching `Ready` status. This typically takes 3–5 minutes on AHV.

> **Checkpoint ✅** — `kubectl get nodes` shows 4 worker nodes in `Ready` state.

### Step A3 — Scale In (Remove a Node)

1. In the Kommander UI, reduce the worker pool back to `3` replicas.
2. NKP gracefully drains the node before terminating it:
   - Existing pods are evicted to other nodes
   - PodDisruptionBudgets are respected
   - The VM is deleted after drain completes

Watch the drain:

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl get nodes -w
```

> **Observe:** The node transitions through `Ready` → `SchedulingDisabled` → removed from the list.

---

## Part B — Cluster Upgrade (20 min)

### Step B1 — Check Current Version

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl version --short
```

In Kommander, the cluster version is also shown on the cluster overview card.

### Step B2 — Initiate an Upgrade

> **Note:** If no newer Kubernetes version is available in this environment, your facilitator
> will demonstrate this step. Follow along to understand the process.

**Via Kommander UI:**

1. Kommander → **Clusters** → `workload01` → **Overview**.
2. If an upgrade is available, an **Upgrade Available** banner appears.
3. Click **Upgrade** → select the target Kubernetes version.
4. NKP shows the upgrade plan:
   - Control plane nodes upgraded first (rolling, one at a time)
   - Worker node pools upgraded after control plane is healthy

5. Click **Start Upgrade**.

**What NKP does under the hood:**
1. Provisions a new control plane node at the new K8s version
2. Drains and deletes the old control plane node
3. Repeats for remaining control plane nodes
4. Rolls out worker pool replacements

Monitor via CLI:

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl get machines -A -w
```

> **Checkpoint ✅** — `kubectl version` shows the upgraded Kubernetes version.

---

## Part C — Backup and Restore Concepts (10 min)

NKP integrates with **Velero** for persistent volume snapshots and Kubernetes object backup.

### Step C1 — Check Velero Status

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl get pods -n velero
```

### Step C2 — View Existing Backups

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl get backup -n velero
```

### Step C3 — Create a Namespace Backup

Back up the `bls-app` namespace (deployed in Lab 2):

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  velero backup create bls-app-backup \
  --include-namespaces bls-app \
  --wait
```

Check backup status:

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  velero backup describe bls-app-backup
```

### Step C4 — Simulate Recovery

Delete the namespace (simulate data loss):

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl delete namespace bls-app
```

Restore from backup:

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  velero restore create --from-backup bls-app-backup --wait
```

Verify restoration:

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl get pods -n bls-app
```

> **Checkpoint ✅** — `bls-app` namespace and NGINX pods restored.

---

## Part D — Troubleshooting (10 min)

### Common Techniques

**1 — Check cluster-wide events (the first tool to reach for):**

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl get events -A --sort-by='.lastTimestamp' | tail -30
```

**2 — Describe a problematic pod:**

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl describe pod <pod-name> -n <namespace>
```

Look for: `OOMKilled`, `CrashLoopBackOff`, `ImagePullBackOff`, `Insufficient cpu`.

**3 — Check node conditions:**

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  kubectl describe nodes | grep -A5 "Conditions:"
```

**4 — Check platform application health via Kommander:**

1. Kommander → **Clusters** → `workload01` → **Applications**.
2. Any application showing a red/warning status has a degraded HelmRelease.
3. Click the application → **View Details** to see the Helm error message.

**5 — Force Flux reconciliation (if a catalog app is stuck):**

```bash
KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf \
  flux reconcile helmrelease grafana -n monitoring
```

**6 — NKP AI Navigator:**

In the Kommander UI, look for the **AI Navigator** or **Insights** panel. It surfaces anomalies
detected by NKP's built-in intelligence — failed controllers, resource pressure, certificate
expiry warnings — before they become incidents.

---

## Summary

You performed the full Day-2 operations lifecycle on `workload01`:

| Operation | Result |
|-----------|--------|
| Scale out | Added a worker node (4 total) |
| Scale in | Gracefully removed a node (back to 3) |
| Upgrade | Rolled through a Kubernetes version upgrade |
| Backup | Snapshotted `bls-app` namespace with Velero |
| Restore | Recovered deleted namespace from backup |
| Troubleshoot | Applied event inspection and Flux reconciliation |

NKP handles the complexity of each operation. Your job as an operator is to declare the
desired state — NKP ensures the cluster converges to it safely.
