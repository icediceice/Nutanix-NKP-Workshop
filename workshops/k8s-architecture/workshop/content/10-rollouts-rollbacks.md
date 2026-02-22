---
title: Rollouts and Rollbacks
---

## What We're Doing

Kubernetes Deployments use rolling updates by default — new Pods are brought up while old Pods
are terminated, ensuring zero downtime. If something goes wrong, a single command rolls back to
the previous version. This exercise walks through a full deploy-detect-rollback cycle.

## Steps

### 1. Check the current rollout history

```terminal:execute
command: kubectl rollout history deployment/nginx -n demo-app
```

### 2. Trigger a rolling update

```terminal:execute
command: kubectl set image deployment/nginx nginx=nginx:1.25 -n demo-app
```

```terminal:execute
command: kubectl rollout status deployment/nginx -n demo-app
```

**Observe:** New Pods with the updated image come up before old Pods are terminated. At no point
does the replica count drop below `maxUnavailable` (default: 25% of desired).

### 3. Simulate a bad deploy

```terminal:execute
command: kubectl set image deployment/nginx nginx=nginx:this-tag-does-not-exist -n demo-app
```

```terminal:execute
command: kubectl rollout status deployment/nginx -n demo-app --timeout=30s || echo "Rollout stalled"
```

```terminal:execute
command: kubectl get pods -n demo-app
```

**Observe:** Some Pods are in `ErrImagePull` or `ImagePullBackOff`. The old Pods are still
running because `maxUnavailable` prevents the rollout from removing them all.

### 4. Roll back

```terminal:execute
command: kubectl rollout undo deployment/nginx -n demo-app
```

```terminal:execute
command: kubectl rollout status deployment/nginx -n demo-app
```

**Observe:** Traffic is restored to the last known-good version within seconds.

## What Just Happened

The Deployment controller managed two ReplicaSets simultaneously during the update, gradually
shifting traffic from old to new. The rollback simply scaled the old ReplicaSet back up and the
new one back to zero — a fast, safe operation.
