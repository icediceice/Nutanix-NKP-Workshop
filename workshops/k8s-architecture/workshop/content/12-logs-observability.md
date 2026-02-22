---
title: Logs and Observability
---

## What We're Doing

In Kubernetes, `kubectl logs` is the entry point for debugging. But in production you need
aggregated, searchable, persistent logs across all Pods. NKP ships with a logging stack:
Fluent Bit collects logs from every node and ships them to OpenSearch. In this exercise you
will use both.

## Steps

### 1. Stream logs from the nginx Deployment

```terminal:execute
command: kubectl logs -l app=nginx -n demo-app --tail=20 --follow &
```

### 2. Generate some traffic to produce log lines

```terminal:execute
command: for i in $(seq 1 5); do kubectl exec -n demo-app deploy/nginx -- wget -qO- localhost; done
```

**Observe:** Access log lines appear in real time. Multiple Pods are interleaved in the output.
Press Ctrl-C to stop following.

### 3. Get logs from a previous container (after a crash)

```terminal:execute
command: kubectl logs -n demo-app deploy/nginx --previous 2>/dev/null || echo "No previous container found (none have crashed yet)"
```

### 4. Open the OpenSearch Dashboards

The OpenSearch Dashboards URL is pre-configured in your session. Open it to search and filter
logs across all namespaces with structured queries.

```terminal:execute
command: echo "OpenSearch URL: ${OPENSEARCH_URL:-'Ask your facilitator for the URL'}"
```

**Observe:** In the Discover view, filter by `kubernetes.namespace: demo-app` to see only your
namespace's logs. Fields like `kubernetes.pod_name` and `log` are automatically parsed.

## What Just Happened

Fluent Bit runs as a DaemonSet — one Pod per node — and tails the container log files written
by the kubelet. It enriches log lines with Kubernetes metadata (namespace, Pod, container) and
ships them to OpenSearch. Your application writes to stdout; the platform handles everything else.
