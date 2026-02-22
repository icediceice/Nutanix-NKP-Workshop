---
title: Provision an NKP Cluster
---

## What We're Doing

In this exercise you will use the `nkp` CLI to generate the CAPI manifests for a new workload
cluster and apply them to the management cluster. You will watch the provisioning process in
real time — VMs appearing in Prism, nodes joining the cluster, and the kubeconfig becoming
available.

## Steps

### 1. Check the nkp CLI is available

```terminal:execute
command: nkp version
```

### 2. Generate cluster manifests

```terminal:execute
command: nkp create cluster nutanix \
  --cluster-name workshop-$(echo $SESSION_NAMESPACE | tr -dc '[:alnum:]') \
  --control-plane-replicas 1 \
  --worker-replicas 2 \
  --kubernetes-version v1.29.4 \
  --dry-run \
  --output yaml > /tmp/cluster-manifests.yaml
```

```terminal:execute
command: wc -l /tmp/cluster-manifests.yaml && head -40 /tmp/cluster-manifests.yaml
```

**Observe:** The dry run produces several hundred lines of YAML describing every CAPI object.
This is what `nkp create cluster` applies to the management cluster.

### 3. Review the NutanixCluster object

```terminal:execute
command: grep -A 20 'kind: NutanixCluster' /tmp/cluster-manifests.yaml | head -25
```

**Observe:** The Prism Central endpoint, subnet, and image name are encoded here. These come
from the `nkp` CLI flags or a config file.

### 4. (Demo) Watch a cluster provision

Your facilitator will trigger a live cluster provision and you will watch the events:

```terminal:execute
command: kubectl get machines -A -w
```

**Observe:** Machines transition: `Provisioning` → `Bootstrapping` → `Running`. Each state
change corresponds to a real event in Prism Central (VM created, VM powered on, node joined).

## What Just Happened

The `nkp` CLI is a thin wrapper around CAPI manifest generation. Understanding the underlying
YAML means you can version-control cluster definitions, apply them via GitOps, and reproduce
any cluster configuration exactly.
