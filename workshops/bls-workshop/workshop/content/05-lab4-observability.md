---
title: "Lab 4: Infrastructure Observability & Monitoring (1 hr)"
---

## Goal

Explore NKP's built-in observability stack on `workload01`. You will navigate Grafana dashboards,
query Prometheus metrics, and inspect Alertmanager rules — gaining visibility into cluster health
without installing any third-party tooling.

---

## Background

NKP ships a pre-integrated observability stack:

| Tool | Role |
|------|------|
| **Prometheus** | Scrapes metrics from all nodes, pods, and NKP components |
| **Grafana** | Visualizes metrics in pre-built and custom dashboards |
| **Alertmanager** | Routes and manages alerts from Prometheus rules |
| **Fluent Bit** | Collects container logs and forwards to OpenSearch |

---

## Step 1 — Confirm Monitoring Stack is Running

```execute
kubectl get pods -n monitoring
```

You should see pods for `prometheus-*`, `grafana-*`, `alertmanager-*`, `kube-state-metrics-*`, and `node-exporter-*` (one per node).

Check resource usage at a glance:

```execute
kubectl top nodes
```

---

## Step 2 — Open Grafana

Get the Grafana ingress URL:

```execute
kubectl get ingress -n monitoring
```

Or open it directly from Kommander:

1. Click the **Kommander** tab on the right.
2. Navigate to **Clusters** → `workload01` → **Applications**.
3. Click the **Grafana** tile → **Open**.

Log in with the admin credentials your facilitator provided.

---

## Step 3 — Explore Pre-Built Dashboards

1. In Grafana, click **Dashboards** in the left sidebar.
2. Open **Kubernetes / Compute Resources / Cluster**.

**What to look for:**

| Panel | Meaning |
|-------|---------|
| CPU Usage by Namespace | Which workloads are consuming CPU |
| Memory Usage by Namespace | Which namespaces are approaching limits |
| Network Bytes Received/Transmitted | Traffic patterns across the cluster |
| Pod Restart Count | Pods that may be crashing or OOM-killing |

3. Open **Kubernetes / Compute Resources / Node (Pods)** — select a node from the dropdown.
4. Open **Kubernetes / USE Method / Cluster** — Utilization, Saturation, Errors per resource.

---

## Step 4 — Query Prometheus Directly

1. In Grafana, go to **Explore** (compass icon in the left sidebar).
2. Ensure the data source is set to **Prometheus**.
3. Run these queries one at a time — click the copy button then paste into Grafana:

**Node CPU usage (%):**

```copy
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Memory available per node (GB):**

```copy
node_memory_MemAvailable_bytes / 1024 / 1024 / 1024
```

**Running pods per node:**

```copy
count by (node) (kube_pod_info{node!=""})
```

**Pods not in Running state:**

```copy
kube_pod_status_phase{phase!="Running",phase!="Succeeded"} == 1
```

> **Checkpoint ✅** — You can run PromQL queries and read live cluster metrics.

---

## Step 5 — Explore Alertmanager

Get the Alertmanager URL:

```execute
kubectl get ingress -n monitoring
```

Open the Alertmanager URL in your browser. You will see any currently firing alerts.

View the Prometheus alert rules loaded into the cluster:

```execute
kubectl get prometheusrule -A
```

List all rules, then inspect the first one:

```execute
kubectl get prometheusrule -n monitoring
```

```execute
kubectl get prometheusrule -n monitoring \
  $(kubectl get prometheusrule -n monitoring --no-headers -o custom-columns=NAME:.metadata.name | head -1) \
  -o jsonpath='{.spec.groups[0].rules[0]}'
```

> **Observe:** Alert rules are Kubernetes resources — they can be versioned in Git and deployed via the same GitOps workflow used for applications.

---

## Step 6 — Create a Custom Dashboard Panel

In Grafana, add a panel to track your application namespace:

1. Click **Dashboards** → **New** → **New Dashboard** → **Add visualization**.
2. Select **Prometheus** as the data source.
3. Copy and paste this query to track pod restarts in `bls-app` (from Lab 2):

```copy
sum(increase(kube_pod_container_status_restarts_total{namespace="bls-app"}[1h]))
```

4. Set the panel title to `bls-app Pod Restarts (1h)`.
5. Click **Apply** → **Save dashboard** → name it `BLS Workshop`.

---

## Step 7 — Review Node Exporter Metrics

View the node exporter daemonset pods:

```execute
kubectl get pods -n monitoring -l app.kubernetes.io/name=node-exporter
```

In Grafana, open **Node Exporter Full** and select any node from the dropdown. Key metrics to review:
- **CPU** — system vs user vs iowait
- **Memory** — used/available/cached
- **Disk I/O** — read/write throughput
- **Network** — interface traffic

---

## Step 8 — Check Cluster Events

Events are the first tool to reach for when something looks off:

```execute
kubectl get events -A --sort-by='.lastTimestamp' | tail -20
```

> **Checkpoint ✅** — You explored Grafana, queried Prometheus, and reviewed alert rules. The observability stack requires zero configuration — it's part of every NKP cluster.

---

## Summary

NKP's built-in observability stack gives platform teams immediate visibility into every cluster
without manual installation. Prometheus, Grafana, and Alertmanager are pre-configured and
pre-wired to all workloads from day one.
