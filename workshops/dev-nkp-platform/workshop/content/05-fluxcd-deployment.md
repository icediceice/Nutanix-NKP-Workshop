---
title: FluxCD Deployment
---

## What We're Doing

FluxCD is pre-installed on NKP and manages all platform components via GitOps. You can use the same FluxCD instance for your own applications by creating GitRepository and Kustomization objects in your namespace.
In this exercise you will explore the FluxCD Deployment interface and understand how it integrates with
your development workflow on NKP.

## Steps

### 1. Verify the service is running

```terminal:execute
command: kubectl get gitrepositories -A
```

**Observe:** Platform GitRepository objects show the source repos FluxCD is watching. The READY column confirms they are reachable.

### 2. Explore further

```terminal:execute
command: kubectl get kustomizations -A | head -15
```

**Observe:** Each component contributes to the overall platform capability. Review the output
and note how NKP manages these services as first-class platform components.

### 3. Access the UI

Your facilitator will share the URL and credentials for the FluxCD Deployment dashboard.
Open it in your browser and explore the interface. The hands-on sections of this exercise
will be demonstrated live with the facilitator.

## What Just Happened

You verified the FluxCD Deployment components are healthy on the NKP cluster. These services are managed
by NKP's platform team and are available to all development teams without any installation or
configuration overhead. This is the platform engineering value proposition — developers consume
services, not infrastructure.
