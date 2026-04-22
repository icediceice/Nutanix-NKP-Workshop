---
title: "Lab 3: Enable Platform Catalog (1 hr)"
---

## Goal

Enable NKP's **Platform Application Catalog** on `workload01` and deploy a catalog application.
The catalog gives platform teams a curated set of Helm-packaged services (databases, observability
tools, ingress controllers, certificate managers) that any team can deploy with a few clicks.

---

## Background

The NKP catalog is driven by **HelmRepository** sources managed by Flux. When you enable a
catalog application on a workload cluster, Kommander instructs Flux to install the corresponding
Helm chart from the curated repository.

---

## Step 1 — Open the Catalog in Kommander

1. Click the **Kommander** tab on the right.
2. Navigate to **Clusters** → click `workload01`.
3. In the cluster sidebar, click **Applications** (or **Add-ons / Catalog**).
4. You will see the catalog grid — all available platform applications.

> **Observe:** Each application card shows name, version, and current deployment status.
> Green = already deployed. Grey = available to enable.

---

## Step 2 — Explore What Is Already Enabled

Check which platform applications are running:

```execute
kubectl get helmreleases -A
```

Common pre-installed apps:

| Application | Namespace | Purpose |
|-------------|-----------|---------|
| `cert-manager` | `cert-manager` | TLS certificate automation |
| `metrics-server` | `kube-system` | Resource metrics (CPU/memory) |
| `traefik` | `kommander-default-workspace` | Ingress controller |
| `prometheus` | `monitoring` | Metrics collection |

---

## Step 3 — Enable Grafana via Kommander UI

1. In the catalog grid, find the **Grafana** card.
2. Click **Enable** (or the toggle).
3. A configuration drawer opens. Review the default values — leave them as-is.
4. Click **Enable Application**.

Kommander creates a `HelmRelease` on `workload01`. Monitor the rollout:

```execute
kubectl get pods -n monitoring -w
```

Press `Ctrl+C` once all Grafana pods reach `Running`.

> **Checkpoint ✅** — Grafana pod running in `monitoring` namespace.

---

## Step 4 — Inspect the HelmRelease

Find the Grafana HelmRelease (note the namespace shown):

```execute
kubectl get helmrelease -A | grep -i grafana
```

Inspect it (replace `NAMESPACE` with the namespace from above if not `monitoring`):

```execute
kubectl get helmrelease grafana -n monitoring -o yaml
```

Key fields:
- `spec.chart.spec.chart` — the Helm chart name
- `spec.chart.spec.version` — the chart version
- `spec.values` — customization values Kommander passed

---

## Step 5 — Access Grafana

Get the Grafana service details:

```execute
kubectl get svc -n monitoring | grep grafana
```

Get the ingress URL if available:

```execute
kubectl get ingress -n monitoring
```

Open the URL in your browser. Default credentials are `admin / prom-operator`
(confirm with your facilitator — NKP may use a different default).

---

## Step 6 — Enable metrics-server

Check if `metrics-server` is available:

```execute
kubectl top nodes
```

If the command returns an error, enable `metrics-server` from the catalog the same way you enabled Grafana.
Once enabled, verify:

```execute
kubectl top nodes
```

Expected: CPU and memory usage shown for each node.

---

## Step 7 — Update a Catalog Application

The catalog supports in-place upgrades via Helm values changes.

1. In Kommander, click the **Grafana** card (now showing as enabled).
2. Click **Edit Configuration**.
3. Change a Helm value — for example, set `adminPassword: WorkshopAdmin2024`.
4. Click **Update**. Flux reconciles and Helm upgrades the release.
5. Watch the rollout:

```execute
kubectl rollout status deployment grafana -n monitoring
```

---

## Step 8 — Disable a Catalog Application

1. Find an application you enabled in the catalog.
2. Click the card → **Disable Application**.
3. Kommander removes the `HelmRelease`. Flux uninstalls the Helm chart.
4. Verify it is gone:

```execute
kubectl get helmreleases -A
```

> **Checkpoint ✅** — You have enabled, configured, and disabled catalog applications on `workload01` entirely from the Kommander UI.

---

## Summary

The NKP Platform Catalog gives operations teams a self-service way to provision infrastructure
services without writing Helm commands or managing chart repositories. The underlying engine is
Flux CD — every catalog change is a `HelmRelease` object, traceable and auditable in Git.
