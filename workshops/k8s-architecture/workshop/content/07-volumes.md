---
title: Volumes
---

## What We're Doing

Container filesystems are ephemeral — when a container restarts, all writes are lost. Volumes
give Pods access to persistent storage. Kubernetes decouples storage provisioning (done by
admins via StorageClasses) from storage consumption (done by developers via PVCs).

## Steps

### 1. List available StorageClasses

```terminal:execute
command: kubectl get storageclasses
```

**Observe:** NKP provisions storage classes backed by Nutanix Volumes. The default class is
marked with `(default)` and supports dynamic provisioning.

### 2. Create a PersistentVolumeClaim

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/volumes/pvc.yaml -n demo-app
```

```terminal:execute
command: kubectl get pvc -n demo-app -w
```

**Observe:** The PVC status transitions from `Pending` to `Bound`. The storage controller
dynamically provisioned a PersistentVolume and bound it to this claim.

### 3. Mount the PVC in a Pod

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/volumes/pod-with-pvc.yaml -n demo-app
```

```terminal:execute
command: kubectl exec pvc-demo -n demo-app -- sh -c 'echo "persistent data" > /data/test.txt && cat /data/test.txt'
```

### 4. Delete and recreate the Pod — data persists

```terminal:execute
command: kubectl delete pod pvc-demo -n demo-app && kubectl apply -f /home/eduk8s/exercises/volumes/pod-with-pvc.yaml -n demo-app
```

```terminal:execute
command: kubectl exec pvc-demo -n demo-app -- cat /data/test.txt
```

**Observe:** The file survived the Pod deletion because it lives on the PersistentVolume, not
the container filesystem.

## What Just Happened

The StorageClass `provisioner` controller created a Nutanix Volume disk, the PV object appeared
in the cluster, and the kubelet mounted it into the Pod's filesystem. The data lifecycle is now
tied to the PVC, not the Pod.
