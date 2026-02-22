---
title: Connect to the Cluster
---

## What We're Doing

Before you can manage any workload you need a valid connection to a Kubernetes cluster. `kubectl`
uses a file called a kubeconfig to store credentials and cluster addresses. In this exercise you
will verify your context, inspect the kubeconfig, and confirm that the API server is reachable.

## Steps

### 1. Check your current context

A context ties together a cluster, a user, and a namespace. List all available contexts and see
which one is currently active.

```terminal:execute
command: kubectl config get-contexts
```

**Observe:** The row marked with `*` is your active context. Note the cluster name and namespace.

### 2. View the raw kubeconfig

```terminal:execute
command: kubectl config view --minify
```

**Observe:** You can see the server address, certificate authority data, and user credentials that
`kubectl` sends with every request.

### 3. Verify the API server is reachable

```terminal:execute
command: kubectl cluster-info
```

**Observe:** Kubernetes master and CoreDNS endpoints are printed. If you see a connection refused
error, notify your facilitator.

## What Just Happened

`kubectl` read `~/.kube/config`, selected the active context, and opened a TLS connection to the
Kubernetes API server. Every subsequent `kubectl` command follows this same path.
