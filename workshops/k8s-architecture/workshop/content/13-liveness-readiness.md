---
title: Liveness and Readiness Probes
---

## What We're Doing

Kubernetes cannot tell if your application is healthy just by checking if the process is running.
Liveness probes detect when an application is deadlocked and needs a restart. Readiness probes
detect when an application is not ready to serve traffic (during startup, or while processing a
heavy request) and remove it from Service endpoints temporarily.

## Steps

### 1. Apply a Pod with both probes

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/probes/pod-with-probes.yaml -n demo-app
```

```terminal:execute
command: kubectl describe pod probe-demo -n demo-app | grep -A 10 "Liveness\|Readiness"
```

**Observe:** Both probes use HTTP GET against `/healthz` and `/ready` respectively, with
different initial delays and periods.

### 2. Simulate a failing liveness probe

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/probes/pod-failing-liveness.yaml -n demo-app
```

```terminal:execute
command: kubectl get pod failing-liveness -n demo-app -w
```

**Observe:** After `failureThreshold` consecutive failures, the container is restarted. Watch
the RESTARTS counter increment. This is the liveness probe doing its job.

### 3. Simulate a failing readiness probe

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/probes/pod-failing-readiness.yaml -n demo-app
```

```terminal:execute
command: kubectl get endpoints -n demo-app
```

**Observe:** The Pod's IP is absent from the Service endpoints. Traffic is not routed to it even
though the container is running. When readiness recovers, the IP is re-added automatically.

## What Just Happened

The kubelet on each node runs the configured probes on the defined schedule. Failed liveness
probes trigger container restarts. Failed readiness probes update the Endpoints object, causing
kube-proxy to stop routing traffic to that Pod. The Pod is not killed — just taken out of rotation.
