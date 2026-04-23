---
title: "Lab 5: Production Operations — Day-2 Ops (1 hr)"
---

## Goal

Experience the Day-2 operations lifecycle on `workload01`: scale workloads in Kubernetes,
back up and restore a namespace with Velero, and practise common troubleshooting techniques —
all driven from the NKP Kommander UI and CLI.

---

## Background

| Operation | NKP Mechanism |
|-----------|--------------|
| Scale pods | `kubectl scale` — adjust replica count instantly |
| Scale nodes | Modify `MachineDeployment` replicas via Kommander UI |
| Backup / Restore | Velero with MinIO object storage |
| Troubleshoot | Kommander UI events, kubectl, log inspection |

---

## Part A — Workload Scaling (20 min)

Kubernetes lets you scale any Deployment up or down in seconds — no node changes needed.
You will scale the otel-shop app you deployed in Lab 2.

### Step A1 — Check Current Replicas

```execute
kubectl get deployments -n bls-app-$SESSION_NAME
```

### Step A2 — Scale Up

Scale the `frontend` to 3 replicas:

```execute
kubectl scale deployment frontend --replicas=3 -n bls-app-$SESSION_NAME
```

Watch pods come up:

```execute
kubectl get pods -n bls-app-$SESSION_NAME -w
```

Press `Ctrl+C` once all 3 frontend pods show `Running 2/2`.

> **Checkpoint ✅** — `kubectl get pods` shows 3 `frontend` pods in `Running` state.

### Step A3 — Scale Down

Scale back to 1 replica:

```execute
kubectl scale deployment frontend --replicas=1 -n bls-app-$SESSION_NAME
```

Verify:

```execute
kubectl get deployments -n bls-app-$SESSION_NAME
```

> **Note:** NKP node pools (MachineDeployments) follow the same pattern — change the replica
> count in Kommander UI → **Clusters** → `workload01` → node pool → **Edit**.
> Node scale-out takes 3–5 minutes on AHV; pod scaling takes seconds.

---

## Part B — Backup and Restore with Velero (20 min)

NKP integrates with **Velero** for Kubernetes object backup. Velero stores backups in
**MinIO** — an S3-compatible object store running inside the cluster.

### Step B1 — Verify Velero is Ready

```execute
kubectl get pods -n velero
```

Both `velero-*` and `minio-0` should be `Running`.

Check the backup storage location is available:

```execute
kubectl get backupstoragelocation -n velero
```

The `PHASE` column should show `Available`.

### Step B2 — View Existing Backups

```execute
kubectl get backup -n velero
```

### Step B3 — Back Up Your Namespace

Create a Velero backup of your session namespace from Lab 2:

```execute
kubectl apply -f - << EOF
apiVersion: velero.io/v1
kind: Backup
metadata:
  name: bls-app-backup-$SESSION_NAME
  namespace: velero
spec:
  includedNamespaces:
  - bls-app-$SESSION_NAME
  storageLocation: default
  ttl: 2h0m0s
EOF
```

Watch until the backup completes:

```execute
kubectl get backup bls-app-backup-$SESSION_NAME -n velero -w
```

Press `Ctrl+C` once `STATUS` shows `Completed`.

> **Checkpoint ✅** — Backup phase `Completed`.

### Step B4 — Simulate Data Loss

Delete the namespace to simulate an incident:

```execute
kubectl delete namespace bls-app-$SESSION_NAME
```

Confirm it is gone:

```execute
kubectl get ns bls-app-$SESSION_NAME
```

### Step B5 — Restore from Backup

```execute
kubectl apply -f - << EOF
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: bls-app-restore-$SESSION_NAME
  namespace: velero
spec:
  backupName: bls-app-backup-$SESSION_NAME
EOF
```

Watch the restore:

```execute
kubectl get restore bls-app-restore-$SESSION_NAME -n velero -w
```

Press `Ctrl+C` once `Completed`, then verify:

```execute
kubectl get pods -n bls-app-$SESSION_NAME
```

> **Checkpoint ✅** — `bls-app-$SESSION_NAME` namespace and all pods restored.

---

## Part C — Troubleshooting (10 min)

### Technique 1 — Cluster-wide events (always check first)

```execute
kubectl get events -A --sort-by='.lastTimestamp' | tail -30
```

### Technique 2 — Describe a failing pod

```execute
kubectl get pods -A | grep -v Running | grep -v Completed
```

If any pod is not Running, describe it (replace `POD` and `NS` with values from above):

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

Day-2 operations in NKP are declarative. Pod scaling takes seconds via `kubectl scale`;
node pool scaling is a replica count change in Kommander UI. Velero with MinIO gives you
point-in-time namespace recovery. The CLI commands on this page are your toolkit for any
production issue.
