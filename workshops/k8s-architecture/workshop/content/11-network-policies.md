---
title: Network Policies
---

## What We're Doing

By default, all Pods in a Kubernetes cluster can talk to all other Pods. NetworkPolicy objects
let you define allow-list rules that restrict traffic flow. This is essential for multi-tenant
clusters and defence-in-depth security. NKP uses Cilium as its CNI, which enforces NetworkPolicy
using eBPF for high performance.

## Steps

### 1. Verify open communication (before policy)

```terminal:execute
command: kubectl run attacker --image=curlimages/curl --restart=Never -n default -- curl -s http://nginx.demo-app.svc.cluster.local
```

```terminal:execute
command: kubectl logs attacker -n default
```

**Observe:** The request succeeds. A Pod in `default` can reach a Service in `demo-app`.

### 2. Apply a default-deny ingress policy

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/network-policy/default-deny-ingress.yaml -n demo-app
```

### 3. Try again — traffic is now blocked

```terminal:execute
command: kubectl run attacker2 --image=curlimages/curl --restart=Never -n default -- curl -s --max-time 5 http://nginx.demo-app.svc.cluster.local || echo "Blocked"
```

### 4. Create an allow rule for the frontend

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/network-policy/allow-frontend.yaml -n demo-app
```

**Observe:** Only Pods with the label `role=frontend` in the `demo-app` namespace are now
permitted to reach the nginx Service. All other sources are denied.

### 5. Verify the policy

```terminal:execute
command: kubectl get networkpolicies -n demo-app
```

## What Just Happened

Cilium translated the NetworkPolicy objects into eBPF programs loaded into the kernel on each
node. Traffic that does not match an allow rule is dropped at the kernel level before it reaches
the Pod — zero overhead from user-space proxies.
