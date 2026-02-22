---
title: Istio Service Mesh
---

## What We're Doing

Istio provides mutual TLS between services, traffic management (canary deployments, circuit breaking), and detailed telemetry without changing application code. NKP deploys Istio with Kiali for visualisation.
In this exercise you will explore the Istio Service Mesh interface and understand how it integrates with
your development workflow on NKP.

## Steps

### 1. Verify the service is running

```terminal:execute
command: kubectl get pods -n istio-system
```

**Observe:** Istiod, the ingress gateway, and Kiali are running. Kiali provides a live service graph of all mesh traffic.

### 2. Explore further

```terminal:execute
command: kubectl get virtualservices -A && kubectl get destinationrules -A
```

**Observe:** Each component contributes to the overall platform capability. Review the output
and note how NKP manages these services as first-class platform components.

### 3. Access the UI

Your facilitator will share the URL and credentials for the Istio Service Mesh dashboard.
Open it in your browser and explore the interface. The hands-on sections of this exercise
will be demonstrated live with the facilitator.

## What Just Happened

You verified the Istio Service Mesh components are healthy on the NKP cluster. These services are managed
by NKP's platform team and are available to all development teams without any installation or
configuration overhead. This is the platform engineering value proposition — developers consume
services, not infrastructure.
