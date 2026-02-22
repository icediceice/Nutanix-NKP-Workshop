---
title: Security Contexts
---

## What We're Doing

By default, containers run as root inside the container namespace. Security contexts let you
specify a non-root user, drop Linux capabilities, make the root filesystem read-only, and prevent
privilege escalation. These settings are the difference between a container and a secure container.

## Steps

### 1. Run a container as root (default) and see the problem

```terminal:execute
command: kubectl run root-demo --image=alpine --restart=Never -n demo-app -- sh -c 'id && sleep 30'
```

```terminal:execute
command: kubectl exec root-demo -n demo-app -- id
```

**Observe:** UID 0. If this container is compromised and escapes the namespace, it could interact
with the host as root.

### 2. Apply a security context

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/security/secure-pod.yaml -n demo-app
```

```terminal:execute
command: kubectl exec secure-demo -n demo-app -- id
```

**Observe:** The process runs as UID 1001 (a non-root user). `runAsNonRoot: true` causes
Kubernetes to reject any image that sets USER root.

### 3. Test read-only root filesystem

```terminal:execute
command: kubectl exec secure-demo -n demo-app -- sh -c 'touch /test.txt' || echo "Write blocked as expected"
```

### 4. Drop capabilities

Look at the manifest to see `capabilities.drop: [ALL]` — the container has no Linux capabilities
at all, which prevents many kernel-level exploits.

```terminal:execute
command: kubectl get pod secure-demo -n demo-app -o jsonpath='{.spec.containers[0].securityContext}' | jq .
```

## What Just Happened

Security contexts translate directly to Linux kernel security features applied by the container
runtime. In NKP, Pod Security Standards enforce baseline security context requirements across
namespaces, preventing misconfigured workloads from being admitted.
