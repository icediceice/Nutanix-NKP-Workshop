---
title: "Lab 5: Production Operations — Day-2 Ops (1 hr)"
---

## Goal

Experience the full Day-2 operations lifecycle on `workload01`: scale a node pool, perform a
Kubernetes version upgrade, explore backup and restore, and practise common
troubleshooting techniques — all driven from the NKP Kommander UI and CLI.

---

## Background

| Operation | NKP Mechanism |
|-----------|--------------|
| Scale nodes | Modify `MachineDeployment` replica count via UI or CLI |
| Upgrade Kubernetes | NKP upgrade wizard (CAPI rolling replacement) |
| Backup / Restore | Velero integration |
| Troubleshoot | Kommander UI events, kubectl, log inspection |

---

## Part A — Node Scaling (20 min)

### Step A1 — View Current Node Pools

```execute
kubectl get machinedeployment -A
```

Check current node count:

```execute
kubectl get nodes
```

### Step A2 — Scale Out via Kommander UI

1. Click the **Kommander** tab on the right.
2. Navigate to **Clusters** → `workload01` → **Nodes** tab.
3. Click the worker node pool name → **Edit**.
4. Change **Replicas** from `3` to `4` → **Save**.

Monitor the new node joining:

```execute
kubectl get nodes -w
```

Press `Ctrl+C` once the new node shows `Ready`. This typically takes 3–5 minutes on AHV.

> **Checkpoint ✅** — `kubectl get nodes` shows 4 worker nodes in `Ready` state.

### Step A3 — Scale In

In Kommander, reduce the worker pool back to `3` replicas.

NKP gracefully drains the node before terminating it (respects PodDisruptionBudgets).

Watch the drain:

```execute
kubectl get nodes -w
```

Press `Ctrl+C` once the node count returns to 3.

---

## Part B — Cluster Upgrade (20 min)

### Step B1 — Check Current Version

```execute
kubectl version --client
```

### Step B2 — Initiate an Upgrade via Kommander UI

> **Note:** If no newer Kubernetes version is available in this environment, your facilitator will demonstrate this step.

1. Kommander → **Clusters** → `workload01` → **Overview**.
2. If an upgrade is available, an **Upgrade Available** banner appears.
3. Click **Upgrade** → select the target Kubernetes version.
4. NKP shows the upgrade plan (control plane first, then workers).
5. Click **Start Upgrade**.

Monitor upgrade progress:

```execute
kubectl get machines -A -w
```

Press `Ctrl+C` to stop watching.

> **Checkpoint ✅** — `kubectl version` shows the upgraded Kubernetes version.

---

## Part C — Backup and Restore (10 min)

NKP integrates with **Velero** for Kubernetes object backup.

### Step C1 — Check Velero Status

```execute
kubectl get pods -n velero
```

### Step C2 — View Existing Backups

```execute
kubectl get backup -n velero
```

### Step C3 — Create a Namespace Backup

Back up your session namespace from Lab 2:

```execute
cat > ~/bls-backup.yaml << EOF
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: bls-app-backup-$(session_name)
  namespace: velero
spec:
  includedNamespaces:
  - bls-app-$(session_name)
EOF
```

```execute
kubectl apply -f ~/bls-backup.yaml
```

Watch until the backup completes:

```execute
kubectl get backup bls-app-backup-$(session_name) -n velero -w
```

Press `Ctrl+C` once status shows `Completed`.

### Step C4 — Simulate Recovery

Delete the namespace to simulate data loss:

```execute
kubectl delete namespace bls-app-$(session_name)
```

Confirm it is gone:

```execute
kubectl get ns bls-app-$(session_name)
```

Restore from backup:

```execute
cat > ~/bls-restore.yaml << EOF
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: bls-app-restore-$(session_name)
  namespace: velero
spec:
  backupName: bls-app-backup-$(session_name)
EOF
```

```execute
kubectl apply -f ~/bls-restore.yaml
```

Watch the restore:

```execute
kubectl get restore bls-app-restore-$(session_name) -n velero -w
```

Press `Ctrl+C` once `Completed`, then verify:

```execute
kubectl get pods -n bls-app-$(session_name)
```

> **Checkpoint ✅** — `bls-app-$(session_name)` namespace and NGINX pods restored.

---

## Part D — Troubleshooting (10 min)

### Technique 1 — Cluster-wide events (always check first)

```execute
kubectl get events -A --sort-by='.lastTimestamp' | tail -30
```

### Technique 2 — Describe a failing pod

```execute
kubectl get pods -A | grep -v Running | grep -v Completed
```

If any pod is not Running, describe it (copy and replace `POD` and `NS` with values from above):

```copy
kubectl describe pod POD -n NS
```

### Technique 3 — Pod logs

```copy
kubectl logs POD -n NS --tail=50
```

### Technique 4 — Node health

```execute
kubectl describe nodes | grep -A5 "Conditions:"
```

### Technique 5 — Resource pressure

```execute
kubectl top nodes
```

```execute
kubectl top pods -A --sort-by=memory | head -20
```

> **Checkpoint ✅** — You have the five essential troubleshooting tools for any NKP cluster.

---

## Summary

Day-2 operations in NKP are declarative. Scaling and upgrades are state changes you declare;
NKP converges to them safely using CAPI's rolling replacement model. Velero provides point-in-time
recovery for any namespace. The CLI commands on this page are your toolkit for any production issue.
