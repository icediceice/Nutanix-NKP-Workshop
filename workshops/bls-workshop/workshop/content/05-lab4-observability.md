---
title: "Lab 4: Observability — Traces, Topology & Metrics (1 hr)"
---

## Goal

Observe the **otel-shop** application you deployed in Lab 2 using the full NKP observability
stack: Kiali for service mesh topology, Jaeger for distributed traces, and Grafana for
infrastructure metrics.

> **Pre-requisite:** Lab 2 complete — otel-shop running in `bls-app-$(session_name)`.
> Facilitator has pre-enabled **Istio-Helm Service Mesh**, **Kiali**, and **Jaeger** on `workload01` via Kommander Platform Services.

---

## Step 1 — Inject Istio Sidecars

Your otel-shop pods were created before Istio was installed — they don't have Envoy sidecars yet.
Restart the deployments so **Istio-Helm** injects them (namespace is already labelled `istio.io/rev=istio-helm`):

```execute
kubectl rollout restart deployment -n bls-app-$SESSION_NAME
```

Wait for all pods to be ready (they will now show `2/2` — app + sidecar):

```execute
kubectl get pods -n bls-app-$SESSION_NAME -w
```

Press `Ctrl+C` when all pods show `2/2 Running`.

---

## Step 2 — Verify Traffic Generator is Running

The otel-shop deployment includes a `traffic-gen` pod that continuously calls `catalog-api/items`,
`checkout-api/checkout`, and `frontend` every 3 seconds from inside the mesh.

First — get your exact namespace name (you'll need this in Kiali):

```execute
echo "Your namespace: bls-app-$SESSION_NAME"
```

Check the traffic-gen is running:

```execute
kubectl get pods -n bls-app-$SESSION_NAME -l app=traffic-gen
```

Check its logs:

```execute
kubectl logs -n bls-app-$SESSION_NAME deploy/traffic-gen --tail=5
```

Wait ~30 seconds for traffic to appear in Kiali. When done with the lab, scale it down:

```execute
kubectl scale deployment traffic-gen -n bls-app-$SESSION_NAME --replicas=0
```

---

## Step 3 — Kiali: Service Mesh Topology

Kiali shows how your services talk to each other in real time — powered by the **Istio-Helm Service Mesh** sidecars injected in Step 1.

1. Click **<a href="https://kommander.nkp.nuth-lab.xyz" target="_blank">Open Kommander ↗</a>**.
2. Navigate to **Clusters** → `workload01` → **Platform Services**.
3. Find **Kiali** → click **Open**.

In Kiali:

1. Click **Graph** in the left sidebar.
2. In the **Namespace** dropdown, select your namespace (from Step 2 above — the full `bls-app-...` name).
3. Set the time range to **Last 5m** and enable **Traffic Animation**.

**What to look for:**

| Element | Meaning |
|---------|---------|
| Arrows between services | Active request paths |
| Green edges | Healthy traffic (2xx responses) |
| Red/orange edges | Errors or timeouts |
| Numbers on edges | Requests per second |

4. Click on the **frontend** node → **Details** panel shows inbound/outbound request rates.
5. Click on the **checkout-api** node — observe it calls both `catalog-api` and `payment-mock`.

> **Checkpoint ✅** — You can see the 4-service call graph and confirm all edges are green.

---

## Step 4 — Jaeger: Distributed Traces

Jaeger captures the full request path across all services — every hop, every latency.

1. In Kommander: **Clusters** → `workload01` → **Platform Services** → **Jaeger** → **Open**.

In Jaeger:

1. In the **Service** dropdown, select `frontend`.
2. Set **Lookback** to `Last 15 minutes`.
3. Click **Find Traces**.

**Explore a trace:**

1. Click any trace — it opens the waterfall view.
2. You should see spans for: `frontend` → `catalog-api` and `frontend` → `checkout-api` → `payment-mock`.
3. Click a span to expand timing details.

**Questions to explore:**
- Which service adds the most latency to a checkout request?
- What does the span look like for a product listing vs a checkout?

> **Checkpoint ✅** — You can see end-to-end traces crossing all 4 services.

---

## Step 5 — Grafana: Infrastructure Metrics

Grafana shows cluster-level and namespace-level resource metrics.

1. In Kommander: **Clusters** → `workload01` → **Platform Services** → **Grafana** → **Open**.
2. Log in with the credentials your facilitator provided.

**Explore dashboards:**

1. Click **Dashboards** → **Kubernetes / Compute Resources / Namespace (Pods)**.
2. In the **namespace** dropdown, select `bls-app-$(session_name)`.

**What to look for:**

| Panel | Meaning |
|-------|---------|
| CPU Usage | Which service is most CPU-intensive |
| Memory Usage | Baseline memory per service pod |
| Network I/O | Traffic volume per pod |
| Throttling | Whether any pod is CPU-throttled |

3. Switch to **Kubernetes / Compute Resources / Cluster** for the full cluster view — see how much of the shared cluster your otel-shop is using.

4. Switch to **Kubernetes / Networking / Namespace (Pods)** — observe inbound/outbound bytes during the traffic burst from Step 2.

---

### PromQL Exploration

Click **Explore** (compass icon in the left sidebar) → ensure data source is **Prometheus** → try these queries one at a time:

**Your namespace pod count:**

```copy
count(kube_pod_info{namespace="bls-app-$(session_name)"})
```

**CPU usage across your pods (cores):**

```copy
sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="bls-app-$(session_name)", container!=""}[5m]))
```

**Memory per pod (MB):**

```copy
sum by (pod) (container_memory_working_set_bytes{namespace="bls-app-$(session_name)", container!=""}) / 1024 / 1024
```

**Network bytes received per pod:**

```copy
sum by (pod) (rate(container_network_receive_bytes_total{namespace="bls-app-$(session_name)"}[5m]))
```

**Container restarts (should be 0 for healthy app):**

```copy
sum by (pod) (kube_pod_container_status_restarts_total{namespace="bls-app-$(session_name)"})
```

**All pods not Running across the whole cluster (health check):**

```copy
kube_pod_status_phase{phase!="Running", phase!="Succeeded"} == 1
```

**Node CPU utilisation % (all nodes):**

```copy
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Node memory available (GB):**

```copy
node_memory_MemAvailable_bytes / 1024 / 1024 / 1024
```

> **Checkpoint ✅** — You can correlate the traffic burst from Step 2 with CPU/network spikes in Grafana and write your own PromQL queries.

---

## Step 6 — Connect the Dots

You have now used three tools that complement each other:

| Question | Tool |
|----------|------|
| "Which service is failing?" | Kiali — red edges in graph |
| "What's the full call chain for this slow request?" | Jaeger — trace waterfall |
| "Is the cluster running out of CPU/memory?" | Grafana — resource dashboards |

In production: an alert from Grafana leads you to Kiali to find the failing service, then
Jaeger to pinpoint the slow span. Each tool answers a different layer of the same problem.
