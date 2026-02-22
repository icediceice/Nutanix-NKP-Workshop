---
title: Resource Requests and Limits
---

## What We're Doing

Resource requests tell the scheduler how much CPU and memory a Pod needs — it uses this to pick
a node with enough capacity. Resource limits cap how much a Pod can consume. Without limits, a
single runaway Pod can starve every other workload on the node.

## Steps

### 1. View current resource usage

```terminal:execute
command: kubectl top pods -n demo-app
```

**Observe:** CPU is shown in millicores (m) and memory in mebibytes (Mi). This data comes from
the metrics-server aggregating kubelet statistics.

### 2. Apply a Pod with requests and limits

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/resources/pod-with-resources.yaml -n demo-app
```

```terminal:execute
command: kubectl describe pod resource-demo -n demo-app | grep -A 10 "Limits\|Requests"
```

### 3. Trigger an OOM kill

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/resources/oom-pod.yaml -n demo-app
```

```terminal:execute
command: kubectl get pod oom-demo -n demo-app -w
```

**Observe:** The container is OOM-killed by the kernel when it exceeds its memory limit. The Pod
status shows `OOMKilled` in the `Reason` field. The container is restarted.

### 4. See QoS classes

```terminal:execute
command: kubectl get pod resource-demo -n demo-app -o jsonpath='{.status.qosClass}'
```

**Observe:** Pods with equal requests and limits get `Guaranteed` QoS — the highest priority.
Pods with only requests get `Burstable`. Pods with neither get `BestEffort` and are evicted first
under node memory pressure.

## What Just Happened

The scheduler uses requests to make placement decisions. The kernel enforces limits via cgroups.
Setting both correctly is one of the most impactful things you can do for cluster stability.
