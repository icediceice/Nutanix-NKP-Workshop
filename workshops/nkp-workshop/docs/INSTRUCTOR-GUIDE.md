# NKP Workshop — Instructor Guide

## Workshop Configurations

| Configuration | Duration | Audience | Labs |
|--------------|----------|----------|------|
| Full Workshop | 6–8 hrs | All roles | 1, 2, 3, 4, 5, 6 |
| Developer Fast Track | 4 hrs | Developers | 1, 2, 3, 5 |
| Executive Showcase | 2 hrs | Executives/managers | 1, 3, 6 |
| SRE Operations Focus | 4 hrs | SRE/Platform teams | 2, 4, 5 |

---

## Pre-Workshop Setup (30 min before start)

1. Run `./scripts/bootstrap-workshop.sh` to verify ArgoCD Application is synced
2. Run `./scripts/print-access.sh` and distribute URLs to participants
3. Verify all platform add-ons are running:
   ```bash
   kubectl get pods -n istio-system
   kubectl get pods -n kommander-default-workspace
   ```
4. Open Kiali, Jaeger, Grafana, ArgoCD in separate browser tabs to pre-warm
5. Switch to `lab-01-start` overlay so Demo Wall shows the ready state

---

## Per-Lab Timing and Talking Points

### Lab 1 — Application Deployment (30–45 min)

**Key message**: GitOps means the cluster is always a reflection of Git. Changing the overlay = changing what ArgoCD deploys. No runbooks, no SSH, no scripts.

**Timing**:
- Orient (Ex 1.1): 5 min
- Deploy (Ex 1.2): 10 min — wait for ArgoCD sync (~2 min)
- Verify (Ex 1.3): 5 min — Kiali graph takes 30–60s to populate
- Buffer/questions: 10 min

**Demo mode option**: Run Ex 1.2 yourself while explaining ArgoCD, have participants follow along in their browser.

**Common questions**:
- "What if the Git repo is down?" → ArgoCD continues serving the last known good state
- "Can I use Helm?" → Yes, ArgoCD supports Helm charts. This workshop uses Kustomize for simplicity.

---

### Lab 2 — Observability (45–60 min)

**Key message**: The Istio sidecar gives you metrics, traces, and topology for free — no SDK changes, no code changes.

**Timing**:
- Kiali (Ex 2.1): 10 min
- Jaeger tracing (Ex 2.2): 15 min
- Log correlation (Ex 2.3): 10 min
- Grafana bonus (Ex 2.4): 10 min if time permits

**Instructor tip**: Have a trace ID ready from a pre-run checkout. The first Jaeger search can take 10–15s to return results.

**Common questions**:
- "Do I need OpenTelemetry in my app?" → Istio gives mesh-level traces automatically. Adding OTEL SDK gives richer application-level spans.

---

### Lab 3 — GitOps & Progressive Delivery (45–60 min)

**Key message**: Progressive delivery is risk management. Every switch-lab.sh call is a Git-audited state change with instant rollback.

**Timing**:
- Mirror (Ex 3.1): 10 min
- Canary 10% (Ex 3.2): 10 min
- Ramp 50%→100% (Ex 3.3): 10 min
- Rollback (Ex 3.4): 5 min
- Buffer: 10 min

**Instructor tip**: Keep Kiali graph open on the projector throughout Lab 3. The traffic split visualization is the most compelling visual.

**Important**: The storefront v2/v1 theme (green/blue) is the most intuitive way to show traffic split. Emphasize: "Every time you see green, that request hit v2."

---

### Lab 4 — Storage & Stateful Workloads (45–60 min)

**Key message**: Nutanix CSI makes persistent storage as simple as block. Same `storageClassName` field, whether you need block or file, RWO or RWX.

**Timing**:
- Storage classes (Ex 4.1): 5 min
- Deploy Postgres (Ex 4.2): 10 min — wait for PVC binding (~30s)
- Kill pod (Ex 4.3): 5 min
- Snapshot (Ex 4.4): 10 min
- Restore (Ex 4.5): 10 min
- RWX bonus (Ex 4.6): 10 min

**Instructor tip**: The "3 rows vs 4 rows" moment in Exercise 4.5 is the most powerful demo. Walk participants through it slowly: "The restored database doesn't know about the post-snapshot insert. That's a true point-in-time backup."

---

### Lab 5 — Production Operations (45–60 min)

**Key message**: Observability + resilience + autoscaling are platform capabilities — they're available to every workload without application changes.

**Timing**:
- Latency incident (Ex 5.1): 10 min
- Error incident (Ex 5.2): 10 min
- Node resilience (Ex 5.3): 10 min — drain takes ~2 min
- KEDA (Ex 5.4): 10 min
- Buffer: 5 min

**Important for node drain**: Pre-identify a worker node before starting. Confirm 3+ workers are available. Never drain a control plane node.

**Instructor tip**: For Ex 5.1, let participants feel the slowness themselves in the storefront browser before revealing the trace. The "a-ha" moment of seeing the exact span with 1000ms is very effective.

---

### Lab 6 — Multi-Tenancy & Governance (30–45 min)

**Key message**: Governance at the platform layer means developers can't accidentally violate policy — or if they do, you find out immediately via Gatekeeper audit.

**Timing**:
- Quota (Ex 6.1): 10 min
- Gatekeeper dryrun (Ex 6.2): 5 min
- Gatekeeper enforce (Ex 6.3): 5 min
- RBAC (Ex 6.4): 5 min
- Kommander demo (Ex 6.5): 5 min

**Instructor tip**: The Gatekeeper enforce moment (Ex 6.3) is the most satisfying demo — `kubectl apply` fails with a clear error. Have the policy-violation-example.yaml visible in an editor tab so participants can see what's missing.

---

## Reset Between Sessions

```bash
./scripts/reset.sh
```

Wait for confirmation message before starting the next session.

---

## Troubleshooting Common Issues

See `docs/TROUBLESHOOTING.md` for the full list. Quick reference:

| Symptom | Fix |
|---------|-----|
| ArgoCD stuck Progressing | `kubectl -n argocd annotate app rx-demo argocd.argoproj.io/refresh=hard --overwrite` |
| Kiali graph empty | Check load generator is running: `kubectl -n demo-ops get pods` |
| Storefront not loading | Check Istio ingress: `kubectl -n istio-helm-gateway-ns get svc` |
| VolumeSnapshot not ready | CSI driver issue — check `kubectl -n ntnx-system get pods` |
| KEDA not scaling | Check ScaledObject: `kubectl -n demo-app describe scaledobject checkout-api-v1-keda` |
