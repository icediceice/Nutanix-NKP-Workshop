---
title: Services
---

## What We're Doing

Pods have ephemeral IPs that change when Pods are replaced. Services provide a stable virtual IP
(ClusterIP) and DNS name that load-balances across healthy Pod endpoints. In this exercise you
will create ClusterIP and NodePort services and observe how kube-proxy keeps endpoints updated.

## Steps

### 1. Create a ClusterIP Service

```terminal:execute
command: kubectl expose deployment/nginx --port=80 --target-port=80 --type=ClusterIP -n demo-app
```

### 2. Inspect the Service and Endpoints

```terminal:execute
command: kubectl get service nginx -n demo-app
```

```terminal:execute
command: kubectl get endpoints nginx -n demo-app
```

**Observe:** The Endpoints object lists the IPs of all running, Ready Pods. This list updates
automatically when Pods are added, removed, or fail readiness probes.

### 3. Test internal DNS resolution

```terminal:execute
command: kubectl run curl-test --image=curlimages/curl --restart=Never -n demo-app -- curl -s http://nginx.demo-app.svc.cluster.local
```

```terminal:execute
command: kubectl logs curl-test -n demo-app
```

**Observe:** The DNS name `<service>.<namespace>.svc.cluster.local` always resolves to the
Service's ClusterIP, regardless of which Pods are behind it.

### 4. Create a NodePort Service

```terminal:execute
command: kubectl expose deployment/nginx --name=nginx-nodeport --port=80 --type=NodePort -n demo-app
```

```terminal:execute
command: kubectl get service nginx-nodeport -n demo-app
```

**Observe:** A high-numbered port (30000-32767) is allocated on every node. Useful for testing
but not recommended for production — use Ingress instead.

## What Just Happened

kube-proxy watches the Endpoints object and programs iptables (or eBPF) rules on every node to
load-balance traffic destined for the Service ClusterIP across the backing Pods.
