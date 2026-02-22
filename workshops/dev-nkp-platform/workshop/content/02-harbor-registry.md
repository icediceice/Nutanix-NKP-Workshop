---
title: Harbor Registry
---

## What We're Doing

Harbor is NKP's built-in container registry. It provides private image storage, RBAC projects, vulnerability scanning with Trivy, and replication policies.
In this exercise you will explore the Harbor Registry interface and understand how it integrates with
your development workflow on NKP.

## Steps

### 1. Verify the service is running

```terminal:execute
command: docker login ${HARBOR_URL} -u ${HARBOR_USER} -p ${HARBOR_PASSWORD}
```

**Observe:** Login Succeeded confirms credentials. Harbor stores them in ~/.docker/config.json.

### 2. Explore further

```terminal:execute
command: kubectl get pods -n harbor
```

**Observe:** Each component contributes to the overall platform capability. Review the output
and note how NKP manages these services as first-class platform components.

### 3. Access the UI

Your facilitator will share the URL and credentials for the Harbor Registry dashboard.
Open it in your browser and explore the interface. The hands-on sections of this exercise
will be demonstrated live with the facilitator.

## What Just Happened

You verified the Harbor Registry components are healthy on the NKP cluster. These services are managed
by NKP's platform team and are available to all development teams without any installation or
configuration overhead. This is the platform engineering value proposition — developers consume
services, not infrastructure.
