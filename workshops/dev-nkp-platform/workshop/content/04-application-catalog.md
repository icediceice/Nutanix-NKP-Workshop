---
title: Application Catalog
---

## What We're Doing

The NKP Application Catalog provides one-click deployment of common infrastructure components. Need a PostgreSQL database for your app? Three clicks and it is running in your namespace.
In this exercise you will explore the Application Catalog interface and understand how it integrates with
your development workflow on NKP.

## Steps

### 1. Verify the service is running

```terminal:execute
command: kubectl get pods -n catalog-system
```

**Observe:** The catalog controller is running. It syncs available applications from a curated Helm repository.

### 2. Explore further

```terminal:execute
command: kubectl get helmreleases -A | head -10
```

**Observe:** Each component contributes to the overall platform capability. Review the output
and note how NKP manages these services as first-class platform components.

### 3. Access the UI

Your facilitator will share the URL and credentials for the Application Catalog dashboard.
Open it in your browser and explore the interface. The hands-on sections of this exercise
will be demonstrated live with the facilitator.

## What Just Happened

You verified the Application Catalog components are healthy on the NKP cluster. These services are managed
by NKP's platform team and are available to all development teams without any installation or
configuration overhead. This is the platform engineering value proposition — developers consume
services, not infrastructure.
