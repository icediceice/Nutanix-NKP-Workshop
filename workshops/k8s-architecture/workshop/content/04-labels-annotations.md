---
title: Labels and Annotations
---

## What We're Doing

Labels and annotations both attach metadata to Kubernetes objects, but they serve different
purposes. Labels are used for selection and grouping — Services and Deployments use them to
find Pods. Annotations store non-identifying metadata for tools and operators.

## Steps

### 1. View existing labels on Pods

```terminal:execute
command: kubectl get pods -n demo-app --show-labels
```

**Observe:** Every Pod created by the Deployment has `app=nginx` and a `pod-template-hash` label
added automatically.

### 2. Filter by label selector

```terminal:execute
command: kubectl get pods -n demo-app -l app=nginx
```

### 3. Add a label to a Pod

```terminal:execute
command: kubectl label pod $(kubectl get pods -n demo-app -o name | head -1 | cut -d/ -f2) tier=frontend -n demo-app
```

### 4. Use set-based selectors

```terminal:execute
command: kubectl get pods -n demo-app -l 'app in (nginx,httpd)'
```

### 5. Add an annotation

```terminal:execute
command: kubectl annotate deployment/nginx -n demo-app team="platform-engineering" contact="platform@example.com"
```

```terminal:execute
command: kubectl describe deployment/nginx -n demo-app | grep Annotations
```

**Observe:** Annotations appear in describe output but are not used for selection. They are
typically consumed by CI/CD pipelines, monitoring tools, and operators.

## What Just Happened

Labels are the glue of Kubernetes. Services route traffic to Pods by label. HPA targets
Deployments by label. Network Policies select Pods by label. Annotations carry the metadata
that labels are not meant to — URLs, ownership, tool-specific config.
