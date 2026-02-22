---
title: Observability Tools
---

## What We're Doing

NKP deploys a full observability stack
In this exercise you will explore the Observability Tools interface and understand how it integrates with
your development workflow on NKP.

## Steps

### 1. Verify the service is running

```terminal:execute
command:  Prometheus scrapes metrics from all workloads, Grafana visualises them, Fluent Bit collects logs, and OpenSearch indexes them.
```

**Observe:** kubectl get pods -n monitoring

### 2. Explore further

```terminal:execute
command: Prometheus, Alertmanager, and Grafana are running. Note the -w flag — press Ctrl-C when all show Running.:kubectl top nodes && kubectl top pods -A --sort-by=memory | head -20
```

**Observe:** Each component contributes to the overall platform capability. Review the output
and note how NKP manages these services as first-class platform components.

### 3. Access the UI

Your facilitator will share the URL and credentials for the Observability Tools dashboard.
Open it in your browser and explore the interface. The hands-on sections of this exercise
will be demonstrated live with the facilitator.

## What Just Happened

You verified the Observability Tools components are healthy on the NKP cluster. These services are managed
by NKP's platform team and are available to all development teams without any installation or
configuration overhead. This is the platform engineering value proposition — developers consume
services, not infrastructure.
