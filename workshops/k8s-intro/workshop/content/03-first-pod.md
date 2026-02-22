---
title: Your First Pod
---

## What We're Doing

A Pod is the smallest deployable unit in Kubernetes — a wrapper around one or more containers
that share network and storage. In this exercise you will run an nginx Pod, inspect its state,
exec into it, and then clean it up. This workflow mirrors real-world debugging sessions.

## Steps

### 1. Run an nginx Pod

```terminal:execute
command: kubectl run nginx --image=nginx:alpine --restart=Never
```

**Observe:** The output says `pod/nginx created`. The Pod is now being scheduled.

### 2. Watch it start up

```terminal:execute
command: kubectl get pods -w
```

**Observe:** Watch the STATUS column transition from `ContainerCreating` to `Running`. Press Ctrl-C
to stop watching once it is Running.

### 3. Describe the Pod

```terminal:execute
command: kubectl describe pod nginx
```

**Observe:** The `Events` section at the bottom shows the scheduling decision, image pull, and
container start sequence. This is your first place to look when a Pod is stuck.

### 4. Exec into the running container

```terminal:execute
command: kubectl exec -it nginx -- sh
```

Run a command inside, then exit:

```terminal:execute
command: exit
```

### 5. Delete the Pod

```terminal:execute
command: kubectl delete pod nginx
```

## What Just Happened

Kubernetes scheduled the Pod onto a node, the kubelet pulled the nginx image, started the
container, and registered it with the network. When you deleted the Pod, the kubelet stopped
the container and the API server removed the object. No resurrection — this is a bare Pod.
