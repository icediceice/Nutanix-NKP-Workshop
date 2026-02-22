---
title: Backup and Disaster Recovery
---

## What We're Doing

Velero is the backup and restore tool for Kubernetes workloads. NKP integrates Velero with
Nutanix object storage (Objects) as the backup destination. In this exercise you will create a
backup of a namespace, simulate a disaster by deleting the namespace, and restore it from the
backup.

## Steps

### 1. Verify Velero is installed

```terminal:execute
command: kubectl get pods -n velero
```

```terminal:execute
command: velero backup-location get
```

**Observe:** The backup location shows AVAILABLE=true, confirming connectivity to Nutanix Objects.

### 2. Create a backup

```terminal:execute
command: velero backup create demo-backup --include-namespaces demo-app --wait
```

```terminal:execute
command: velero backup describe demo-backup
```

**Observe:** Phase: Completed. All resources and PVC data (via Velero's CSI snapshot support)
are stored in the Nutanix Objects bucket.

### 3. Simulate disaster — delete the namespace

```terminal:execute
command: kubectl delete namespace demo-app
```

```terminal:execute
command: kubectl get namespace demo-app
```

**Observe:** The namespace and all its resources are gone. This simulates accidental deletion
or a failed cluster.

### 4. Restore from backup

```terminal:execute
command: velero restore create --from-backup demo-backup --wait
```

```terminal:execute
command: kubectl get all -n demo-app
```

**Observe:** All Deployments, Services, ConfigMaps, Secrets, and PVCs are restored. Application
data stored on PVCs is also restored from the volume snapshot.

## What Just Happened

Velero serialised all Kubernetes objects in `demo-app` to JSON and stored them in Nutanix
Objects. Volume data was snapshot-based via the CSI VolumeSnapshot integration. The restore
re-created every object in the correct order, including PVC-to-PV binding.
