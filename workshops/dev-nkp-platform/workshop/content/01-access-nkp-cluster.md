---
title: Access the NKP Cluster
---

## What We're Doing

Access the NKP dashboard, download kubeconfig, and verify cluster connectivity.
In this exercise you will explore the Access the NKP Cluster interface and understand how it integrates with
your development workflow on NKP.

## Steps

### 1. Verify the service is running

```terminal:execute
command: kubectl get nodes -o wide
```

**Observe:** All nodes show Ready status. Note the NKP-specific node labels and the Nutanix infrastructure annotations.

### 2. Explore further

```terminal:execute
command: kubectl cluster-info && kubectl get namespaces | grep -E 'kommander|flux|cert-manager|traefik'
```

**Observe:** Each component contributes to the overall platform capability. Review the output
and note how NKP manages these services as first-class platform components.

### 3. Access the UI

Your facilitator will share the URL and credentials for the Access the NKP Cluster dashboard.
Open it in your browser and explore the interface. The hands-on sections of this exercise
will be demonstrated live with the facilitator.

## What Just Happened

You verified the Access the NKP Cluster components are healthy on the NKP cluster. These services are managed
by NKP's platform team and are available to all development teams without any installation or
configuration overhead. This is the platform engineering value proposition — developers consume
services, not infrastructure.
