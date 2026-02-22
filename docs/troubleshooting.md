# Troubleshooting Guide

Common issues encountered during workshop setup and delivery, with diagnostics and remediation
steps.

---

## Issue 1: Educates Portal Not Reachable

**Symptom:** `https://portal.workshop.example.com` returns a connection timeout or 502 error.

### Diagnosis

```bash
# Check TrainingPortal status
kubectl get trainingportals
kubectl describe trainingportal nkp-workshop

# Check Educates operator pods
kubectl get pods -n educates

# Check ingress
kubectl get ingress -n educates
kubectl describe ingress -n educates
```

### Common Causes and Fixes

**DNS not resolving**
```bash
nslookup portal.workshop.example.com
# If this fails, the wildcard DNS record is not set or has not propagated
# Check with your DNS provider. Propagation can take up to 30 minutes.
```

**TLS certificate not issued**
```bash
kubectl get certificate -n educates
kubectl describe certificate workshop-tls -n educates
# Look for 'Reason: Failed' — check cert-manager logs
kubectl logs -n cert-manager -l app=cert-manager --tail=50
```

**Educates operator CrashLoopBackOff**
```bash
kubectl logs -n educates -l app=educates-operator --previous
# Common cause: incorrect domain configuration in the operator Helm values
# Reinstall with the correct domain value
```

---

## Issue 2: Participant Session Stuck in Provisioning

**Symptom:** The registration app shows a participant as `Provisioning` for more than 10 minutes.

### Diagnosis

```bash
# List all WorkshopSessions
kubectl get workshopsessions -A

# Find the stuck session and describe it
kubectl describe workshopsession <session-name> -n educates

# Check the namespace for the session
kubectl get all -n <participant-namespace>
```

### Common Causes and Fixes

**Insufficient cluster resources (Pending Pods)**
```bash
kubectl get pods -n <participant-namespace>
kubectl describe pod <pod-name> -n <participant-namespace>
# Look for 'Insufficient memory' or 'Insufficient cpu' in Events
# Resolution: add worker nodes via nkp or scale MachineDeployment
```

**Image pull failures**
```bash
kubectl get events -n <participant-namespace> | grep -i "pull\|image"
# If Harbor is unreachable, check Harbor pod health and network policies
kubectl get pods -n harbor
```

**ResourceQuota exceeded**
```bash
kubectl describe resourcequota -n <participant-namespace>
# If quota is exhausted, increase the budget in the Workshop config.yaml
```

---

## Issue 3: Cluster Became Unresponsive — Recreate Participant Namespace

**Symptom:** A participant's session is broken and cannot be recovered. The namespace needs to
be recreated.

### Steps

1. Identify the broken session name and namespace:
```bash
kubectl get workshopsessions -n educates | grep <participant-email>
```

2. Delete the WorkshopSession (this triggers cleanup):
```bash
kubectl delete workshopsession <session-name> -n educates
```

3. Verify the namespace is deleted:
```bash
kubectl get namespace | grep <participant-namespace>
```

4. Provision a new session via the registration app:
- Open the registration app admin interface
- Find the participant
- Click **Re-provision**

The participant will receive new credentials. Their previous work is lost if it was not pushed
to Git.

---

## Issue 4: SQLite Database Corruption

**Symptom:** The registration app returns 500 errors or cannot read/write participant data.
Log shows `database disk image is malformed`.

### Diagnosis

```bash
# Access the registration app pod
kubectl exec -it -n registration deploy/registration-app -- sh

# Check the database file
sqlite3 /data/workshop.db "PRAGMA integrity_check;"
```

### Fix

If `PRAGMA integrity_check` returns anything other than `ok`:

```bash
# Export a dump of recoverable data
sqlite3 /data/workshop.db ".dump" > /tmp/db-dump.sql

# Create a new database from the dump
sqlite3 /data/workshop-new.db < /tmp/db-dump.sql

# Replace the database file
cp /tmp/workshop-new.db /data/workshop.db

# Restart the registration app
kubectl rollout restart -n registration deploy/registration-app
```

**Prevention:** The registration app PVC should use a StorageClass with `Retain` reclaim policy
so the database survives Pod restarts. Configure daily Velero backups to include the
`registration` namespace.

---

## Issue 5: Provisioning Errors — "Cannot connect to Prism Central"

**Symptom:** `nkp create cluster` fails with a Prism Central connectivity error, or CAPI
Machines stay in `Provisioning` indefinitely.

### Diagnosis

```bash
# Check CAPI provider pods
kubectl get pods -n capx-system

# Check provider logs for Prism Central errors
kubectl logs -n capx-system -l control-plane=controller-manager --tail=100 | grep -i "error\|prism"

# Test Prism Central connectivity from within the cluster
kubectl run pc-test --image=curlimages/curl --restart=Never -- curl -sk https://<PRISM_IP>:9440/api/nutanix/v3/clusters
kubectl logs pc-test
```

### Common Causes and Fixes

**Invalid credentials in the NutanixCluster Secret**
```bash
kubectl get secret -n <cluster-namespace> | grep credentials
kubectl get secret <credentials-secret> -n <cluster-namespace> -o jsonpath='{.data.credentials}' | base64 -d
# Verify the username and password are correct
# Re-create the Secret with correct values and trigger a reconciliation
```

**Network policy blocking CAPX pods**
```bash
kubectl get networkpolicies -n capx-system
# Ensure no NetworkPolicy blocks egress from capx-system to Prism Central IP/port 9440
```

---

## General Debugging Commands

```bash
# Get all events across a namespace ordered by time
kubectl get events -n <namespace> --sort-by='.metadata.creationTimestamp'

# Watch resource state changes in real time
kubectl get pods -n <namespace> -w

# Get a full dump of a failing pod
kubectl describe pod <name> -n <namespace>

# Stream logs from all pods with a label
kubectl logs -l app=<label> -n <namespace> --tail=50 --follow

# Check cluster-wide resource pressure
kubectl top nodes
kubectl describe nodes | grep -A 5 "Conditions:"
```
