---
title: Deployments
---

## What We're Doing

A Deployment manages a ReplicaSet which manages a set of identical Pods. Deployments give you
declarative updates, rolling upgrades, and easy rollbacks. They are the standard way to run
stateless applications on Kubernetes.

## Steps

### 1. Create a Deployment

```terminal:execute
command: kubectl create deployment nginx --image=nginx:alpine --replicas=3 -n demo-app
```

### 2. Watch the rollout

```terminal:execute
command: kubectl rollout status deployment/nginx -n demo-app
```

### 3. Inspect the ReplicaSet

```terminal:execute
command: kubectl get replicaset -n demo-app
```

**Observe:** The Deployment created a ReplicaSet. The ReplicaSet name includes a pod template
hash. If you update the Deployment, a second ReplicaSet will be created for the new version.

### 4. Scale the Deployment

```terminal:execute
command: kubectl scale deployment/nginx --replicas=5 -n demo-app
```

```terminal:execute
command: kubectl get pods -n demo-app -w
```

**Observe:** Two new Pods appear in `ContainerCreating` state and then transition to `Running`.
Kubernetes added exactly 2 Pods to reach the desired count of 5.

### 5. Kill a Pod and watch it self-heal

```terminal:execute
command: kubectl delete pod $(kubectl get pods -n demo-app -o name | head -1 | cut -d/ -f2) -n demo-app
```

```terminal:execute
command: kubectl get pods -n demo-app
```

**Observe:** The ReplicaSet controller immediately creates a replacement Pod. The Deployment
always converges toward the desired replica count.

## What Just Happened

The Deployment controller continuously compares desired state (5 replicas) to actual state and
reconciles any differences. This reconciliation loop is the fundamental pattern of Kubernetes.
