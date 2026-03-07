# Lab 1 — Application Deployment

## Overview
- **Duration**: 30–45 min
- **What you'll do**: Explore the NKP platform, deploy a 4-service microservices application via GitOps, and verify the live service mesh topology in Kiali.

## Before You Begin
- Verify: `kubectl get nodes` shows 3+ Ready nodes
- Verify: Demo Wall is accessible and shows "lab-01-start — Platform ready, no application deployed"
- Current scenario: Empty namespace — no application pods running

---

## Exercise 1.1: Orient — Explore the NKP Platform (5 min)

### What You'll Do
Explore the cluster and verify platform add-ons are running before deploying any workloads.

### Steps

1. Verify kubectl access and cluster health:
   ```bash
   kubectl get nodes
   kubectl get ns
   ```

2. Check NKP platform add-ons are running:
   ```bash
   kubectl get pods -n istio-system
   kubectl get pods -n kommander-default-workspace
   ```

3. Explore the empty app namespace:
   ```bash
   kubectl get all -n demo-app
   # Expected: No resources found
   ```

4. Check the namespace quota:
   ```bash
   kubectl describe resourcequota demo-app-quota -n demo-app
   ```

5. Open in browser:
   - **NKP Console (Kommander)**: Verify cluster health, see the attached workload cluster
   - **Demo Wall**: Should show "Scenario: lab-01-start — Platform ready, no application deployed"

### Checkpoint ✅
- [ ] `kubectl get nodes` shows 3+ Ready nodes
- [ ] `demo-app` namespace exists but has no pods
- [ ] Demo Wall is accessible and shows the empty state

---

## Exercise 1.2: Deploy — Ship the Storefront via GitOps (10 min)

### What You'll Do
Switch the ArgoCD Application to the deploy overlay and watch the storefront come online.

### Steps

1. Switch to the deploy overlay:
   ```bash
   ./scripts/switch-lab.sh lab-01-deploy
   ```

2. Watch ArgoCD sync the application:
   ```bash
   kubectl -n argocd get application rx-demo -w
   # Wait for: Synced / Healthy
   ```

3. Watch pods come up:
   ```bash
   kubectl -n demo-app get pods -w
   # Expected: frontend, checkout-api, payment-mock-v1, catalog — all Running
   ```

4. Check services:
   ```bash
   kubectl -n demo-app get svc
   ```

5. Get the storefront URL:
   ```bash
   kubectl -n istio-helm-gateway-ns get svc istio-helm-ingressgateway \
     -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```

6. Open in browser:
   - **ArgoCD UI**: See `rx-demo` application with all resources synced (green checkmarks)
   - **Storefront**: Load the app at `http://<IP>`, see the product catalog

### Checkpoint ✅
- [ ] 4 Deployments running in `demo-app`: `frontend`, `checkout-api`, `payment-mock-v1`, `catalog`
- [ ] All pods in Running state (4–8 pods total)
- [ ] Storefront loads in browser — shows product catalog
- [ ] ArgoCD shows Synced / Healthy

---

## Exercise 1.3: Verify — See the Live Mesh (5 min)

### What You'll Do
Start the load generator and observe live traffic in the Kiali service mesh graph.

### Steps

1. Switch to verify overlay (starts load generator at baseline):
   ```bash
   ./scripts/switch-lab.sh lab-01-verify
   ```

2. Verify load generator is running:
   ```bash
   kubectl -n demo-ops get pods -l app=demo-loadgen
   ```

3. Open in browser:
   - **Kiali**: Navigate to Graph view, namespace `demo-app`. See the live topology with traffic flowing between all 4 services.
   - **Demo Wall**: Shows "Application deployed — baseline traffic active"

### Checkpoint ✅
- [ ] Kiali graph shows traffic flowing: `frontend` → `checkout-api` → `payment-mock-v1`, `frontend` → `catalog`
- [ ] Green edges (healthy traffic) on all service connections
- [ ] Load generator pod is Running in `demo-ops`

---

## Bonus Exercise: Explore ArgoCD Resource Tree
Click through individual resources (Deployments, Services, ConfigMaps) in the ArgoCD UI and see how ArgoCD tracks their sync state. Try editing a resource directly with `kubectl` and watch ArgoCD revert it within seconds (`selfHeal: true`).

---

## Cleanup
To reset this lab:
```bash
./scripts/switch-lab.sh lab-01-start
```

---

## Key Takeaways
- ArgoCD reconciles your cluster to match Git. Switching labs = changing `spec.source.path`.
- The Istio sidecar (injected automatically via namespace label) enables mesh-level visibility with zero application changes.
- ResourceQuotas give platform teams guardrails over what workloads can consume per namespace.
