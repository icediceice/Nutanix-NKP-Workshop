# Lab 4 — Storage & Stateful Workloads

## Overview
- **Duration**: 45–60 min
- **What you'll do**: Deploy PostgreSQL with Nutanix block storage, take a point-in-time VolumeSnapshot, restore from it, and demonstrate ReadWriteMany shared file storage.

## Before You Begin
- Verify: Demo Wall shows "lab-04-start — Storage lab — CSI ready"
- Verify: `kubectl get storageclass` shows `nutanix-volumes` and `nutanix-files`
- Current scenario: Frontend-only deployment; no stateful workloads running

---

## Exercise 4.1: Explore Storage Classes (5 min)

### What You'll Do
Examine the pre-configured Nutanix CSI storage classes and understand their capabilities.

### Steps

1. List available storage classes:
   ```bash
   kubectl get storageclass
   ```

2. Examine Nutanix Volumes (block/RWO):
   ```bash
   kubectl describe storageclass nutanix-volumes
   # Key fields: provisioner (csi.nutanix.com), reclaimPolicy, volumeBindingMode
   ```

3. Examine Nutanix Files (file/RWX):
   ```bash
   kubectl describe storageclass nutanix-files
   ```

4. List VolumeSnapshotClasses:
   ```bash
   kubectl get volumesnapshotclass
   ```

### Checkpoint ✅
- [ ] Two StorageClasses visible: `nutanix-volumes` and `nutanix-files`
- [ ] Provisioner is `csi.nutanix.com`
- [ ] VolumeSnapshotClass `nutanix-snapshot` exists

---

## Exercise 4.2: Deploy PostgreSQL with Persistent Storage (10 min)

### What You'll Do
Deploy a PostgreSQL StatefulSet backed by a dynamically provisioned Nutanix Volumes PVC.

### Steps

1. Deploy the database:
   ```bash
   ./scripts/switch-lab.sh lab-04-deploy-db
   ```

2. Watch the StatefulSet come up:
   ```bash
   kubectl -n demo-app get pods -w -l app=postgres
   # Expected: postgres-0 Running
   ```

3. Check the PVC was dynamically provisioned:
   ```bash
   kubectl -n demo-app get pvc
   # Expected: data-postgres-0, Bound, nutanix-volumes storage class
   kubectl -n demo-app get pv | grep data-postgres-0
   ```

4. Connect to Postgres and insert data:
   ```bash
   kubectl -n demo-app exec -it postgres-0 -- psql -U demo -d storefront -c "
     CREATE TABLE IF NOT EXISTS orders (
       id SERIAL PRIMARY KEY,
       product TEXT,
       qty INT,
       created_at TIMESTAMP DEFAULT NOW()
     );
     INSERT INTO orders (product, qty)
       VALUES ('NKP License', 10), ('AHV Cluster', 5), ('Nutanix Files', 3);
     SELECT * FROM orders;
   "
   ```

### Checkpoint ✅
- [ ] `postgres-0` pod is Running
- [ ] PVC `data-postgres-0` is Bound to a PV
- [ ] `SELECT * FROM orders` returns 3 rows

---

## Exercise 4.3: Kill the Pod — Prove Data Survives (5 min)

### What You'll Do
Delete the PostgreSQL pod and verify the StatefulSet recreates it with all data intact.

### Steps

1. Delete the pod:
   ```bash
   kubectl -n demo-app delete pod postgres-0
   ```

2. Watch it restart:
   ```bash
   kubectl -n demo-app get pods -w -l app=postgres
   # Expected: postgres-0 → Terminating → Pending → Running
   ```

3. Query the data again:
   ```bash
   kubectl -n demo-app exec -it postgres-0 -- psql -U demo -d storefront -c "SELECT * FROM orders;"
   # Expected: Same 3 rows — data survived the pod restart
   ```

### Checkpoint ✅
- [ ] Pod restarts and reaches Running state
- [ ] All 3 rows are still present after restart

---

## Exercise 4.4: VolumeSnapshot — Point-in-Time Backup (10 min)

### What You'll Do
Create a VolumeSnapshot of the live PostgreSQL PVC, then add new data to demonstrate point-in-time capture.

### Steps

1. Create the snapshot:
   ```bash
   ./scripts/switch-lab.sh lab-04-snapshot
   ```

2. Check the VolumeSnapshot was created:
   ```bash
   kubectl -n demo-app get volumesnapshot
   # Expected: postgres-snapshot, readyToUse: true
   kubectl -n demo-app describe volumesnapshot postgres-snapshot
   ```

3. Add MORE data to the live database (after the snapshot):
   ```bash
   kubectl -n demo-app exec -it postgres-0 -- psql -U demo -d storefront -c "
     INSERT INTO orders (product, qty) VALUES ('Post-Snapshot Order', 99);
     SELECT * FROM orders;
   "
   # Expected: 4 rows now (3 original + 1 new)
   ```

### Checkpoint ✅
- [ ] VolumeSnapshot `postgres-snapshot` is `readyToUse: true`
- [ ] Database now has 4 rows (3 original + 1 post-snapshot)

---

## Exercise 4.5: Restore from Snapshot (10 min)

### What You'll Do
Restore the snapshot to a new PVC and run a second Postgres instance against it. Prove it captured state at snapshot time, not current state.

### Steps

1. Deploy the restored instance:
   ```bash
   ./scripts/switch-lab.sh lab-04-restore
   ```

2. Check both Postgres instances:
   ```bash
   kubectl -n demo-app get pods -l 'app in (postgres,postgres-restored)'
   ```

3. Query the RESTORED database:
   ```bash
   kubectl -n demo-app exec -it postgres-restored-0 -- psql -U demo -d storefront -c "SELECT * FROM orders;"
   # Expected: 3 rows ONLY — the post-snapshot row is NOT here
   ```

4. Compare with the LIVE database:
   ```bash
   kubectl -n demo-app exec -it postgres-0 -- psql -U demo -d storefront -c "SELECT * FROM orders;"
   # Expected: 4 rows — includes the post-snapshot row
   ```

### Checkpoint ✅
- [ ] Restored instance has exactly 3 rows (pre-snapshot state)
- [ ] Live instance has 4 rows (includes post-snapshot insert)
- [ ] This proves the snapshot is a true point-in-time backup

---

## Exercise 4.6 (Bonus): Nutanix Files — Shared Storage (10 min)

### Steps

1. Switch to RWX demo:
   ```bash
   ./scripts/switch-lab.sh lab-04-rwx
   ```

2. Check the RWX PVC:
   ```bash
   kubectl -n demo-app get pvc shared-data
   # Expected: Bound, nutanix-files storage class, ReadWriteMany
   ```

3. Write from pod 1, read from pod 2:
   ```bash
   POD1=$(kubectl -n demo-app get pods -l app=shared-writer -o jsonpath='{.items[0].metadata.name}')
   POD2=$(kubectl -n demo-app get pods -l app=shared-writer -o jsonpath='{.items[1].metadata.name}')
   kubectl -n demo-app exec $POD1 -- sh -c 'echo "written by pod1" > /shared/test.txt'
   kubectl -n demo-app exec $POD2 -- cat /shared/test.txt
   # Expected: "written by pod1" — shared access confirmed
   ```

---

## Cleanup
To reset this lab:
```bash
./scripts/switch-lab.sh lab-04-start
```

---

## Key Takeaways
- Nutanix CSI dynamically provisions block (RWO) and file (RWX) storage with a single `storageClassName` field — no manual volume setup.
- StatefulSets guarantee stable pod identity and persistent storage across restarts.
- VolumeSnapshots provide application-consistent point-in-time backups that can be restored to a new PVC in seconds.
