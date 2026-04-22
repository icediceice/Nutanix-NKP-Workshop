---
title: "Lab 4: Observability — Traces, Topology & Metrics (1 hr)"
---

## Goal

Observe the **otel-shop** application you deployed in Lab 2 using the full NKP observability
stack: Kiali for service mesh topology, Jaeger for distributed traces, and Grafana for
infrastructure metrics.

> **Pre-requisite:** Lab 2 complete — otel-shop running in `bls-app-$(session_name)`.
> Facilitator has pre-enabled Istio, Kiali, and Jaeger on `workload01`.

---

## Step 1 — Generate Traffic

The otel-shop services only produce traces when they receive requests. Run a quick traffic
burst from within the cluster:

```execute
kubectl run traffic-gen-$SESSION_NAME \
  --image=curlimages/curl \
  --restart=Never \
  -n bls-app-$SESSION_NAME \
  -- sh -c 'for i in $(seq 1 30); do curl -s http://frontend/ > /dev/null; curl -s http://frontend/products > /dev/null; done; echo done'
```

Wait for it to complete:

```execute
kubectl logs -n bls-app-$SESSION_NAME traffic-gen-$SESSION_NAME --follow
```

Clean up when done:

```execute
kubectl delete pod traffic-gen-$SESSION_NAME -n bls-app-$SESSION_NAME
```

---

## Step 2 — Kiali: Service Mesh Topology

Kiali shows how your services talk to each other in real time.

1. Click **<a href="https://kommander.nkp.nuth-lab.xyz" target="_blank">Open Kommander ↗</a>**.
2. Navigate to **Clusters** → `workload01` → **Platform Services**.
3. Find **Kiali** → click **Open**.

In Kiali:

1. Click **Graph** in the left sidebar.
2. In the **Namespace** dropdown, select `bls-app-$(session_name)`.
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

## Step 3 — Jaeger: Distributed Traces

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

## Step 4 — Grafana: Infrastructure Metrics

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

3. Switch to **Kubernetes / Compute Resources / Cluster** for a full cluster view.
4. Click **Explore** (compass icon) → run a PromQL query to see your namespace's pod count:

```copy
count(kube_pod_info{namespace="bls-app-$(session_name)"})
```

> **Checkpoint ✅** — You can correlate the traffic you generated in Step 1 with CPU/network spikes in Grafana.

---

## Step 5 — Connect the Dots

You have now used three tools that complement each other:

| Question | Tool |
|----------|------|
| "Which service is failing?" | Kiali — red edges in graph |
| "What's the full call chain for this slow request?" | Jaeger — trace waterfall |
| "Is the cluster running out of CPU/memory?" | Grafana — resource dashboards |

In production: an alert from Grafana leads you to Kiali to find the failing service, then
Jaeger to pinpoint the slow span. Each tool answers a different layer of the same problem.
