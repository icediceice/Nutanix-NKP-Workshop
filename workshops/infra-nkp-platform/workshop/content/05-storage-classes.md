---
title: Storage Classes
---

## What We're Doing

StorageClasses define how dynamic volume provisioning works. NKP with Nutanix CSI supports
multiple storage classes tuned for different workload profiles: high-performance SSD storage for
databases, standard HDD storage for general workloads, and block vs. filesystem volume modes.

## Steps

### 1. List StorageClasses

```terminal:execute
command: kubectl get storageclasses
```

**Observe:** The `(default)` class is used when a PVC does not specify a StorageClass. NKP
typically sets the Nutanix CSI class as the default.

### 2. Inspect the default StorageClass

```terminal:execute
command: kubectl describe storageclass nutanix-volumes
```

**Observe:** The provisioner is `csi.nutanix.com`. Parameters define the Prism Central data
service IP, storage container name, and filesystem type.

### 3. Create a custom StorageClass for high-performance workloads

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/storage/storageclass-ssd.yaml
```

```terminal:execute
command: kubectl get storageclass nutanix-ssd
```

**Observe:** The new StorageClass references a different storage container configured on
Nutanix AOS with SSD-only placement. Stateful applications can request this class explicitly.

### 4. Create a PVC using the new class

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/storage/pvc-ssd.yaml -n demo-app
```

```terminal:execute
command: kubectl get pvc -n demo-app
```

**Observe:** The PVC is bound to a PersistentVolume provisioned from the SSD storage container.
The PV's `storageClassName` confirms which class was used.

## What Just Happened

StorageClasses give application teams self-service access to appropriate storage tiers without
needing to understand Nutanix storage container configuration. Developers request storage by
class name; the CSI driver handles the Nutanix API calls.
