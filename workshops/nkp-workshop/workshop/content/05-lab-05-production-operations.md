# Lab 5 — Production Operations

**Duration**: 45–60 min | **Goal**: Diagnose latency and error incidents using Jaeger, test node resilience with PDBs, and configure KEDA autoscaling from zero.

---

## Exercise 5.1: Incident — Latency Injection

Start from Lab 5 baseline:

```terminal:execute
command: switch-lab lab-05-start
session: 1
```

Inject latency into v2:

```terminal:execute
command: switch-lab lab-05-incident-latency
session: 1
```

Open the Storefront and click **Checkout** 3 times. Feel the slowness.

```dashboard:open-url
url: https://frontend-%session_name%.%ingress_domain%/
name: Storefront
```

Open Jaeger and look at recent traces — find a slow one:

```dashboard:open-url
url: https://%ingress_domain%/dkp/jaeger/search?service=frontend&namespace=%session_namespace%
name: Jaeger
```

```terminal:execute
command: echo "Platform Login ——  Username: $DKP_USERNAME  |  Password: $DKP_PASSWORD"
session: 1
```

Find the trace where `payment-mock-v2` span shows ~1000ms. That's the root cause.

### Checkpoint ✅

```examiner:execute-test
name: lab-05-latency-injected
title: "v2 latency injection is active"
autostart: true
timeout: 30
command: |
  LATENCY=$(kubectl -n $SESSION_NS get deploy payment-mock-v2 \
    -o jsonpath='{.spec.template.spec.containers[0].env[1].value}' 2>/dev/null)
  [ "$LATENCY" = "1000" ] && exit 0 || exit 1
```

---

## Exercise 5.2: Incident — Error Injection

```terminal:execute
command: switch-lab lab-05-incident-error
session: 1
```

In **Kiali**, watch for **red edges** on the payment-mock-v2 path:

```dashboard:open-url
url: https://%ingress_domain%/dkp/kiali/console/graph/namespaces/?namespaces=%session_namespace%
name: Kiali
```

```terminal:execute
command: echo "Platform Login ——  Username: $DKP_USERNAME  |  Password: $DKP_PASSWORD"
session: 1
```

In **Jaeger**, filter by tag `error=true` to see failed spans.

In Storefront: ~1 in 10 checkout attempts fails. Observe the error in the activity log.

---

## Exercise 5.3: Node Failure Resilience

```terminal:execute
command: switch-lab lab-05-node-resilience
session: 1
```

Verify pods are spread across nodes:

```terminal:execute
command: kubectl -n $SESSION_NS get pods -o wide
session: 1
```

Pick a worker node and drain it (replace NODE_NAME):

```terminal:execute
command: |
  NODE=$(kubectl get nodes -l node-role.kubernetes.io/control-plane!= \
    -o jsonpath='{.items[0].metadata.name}')
  echo "Will drain: $NODE"
session: 1
```

```terminal:execute
command: kubectl cordon "$NODE"
session: 1
```

```terminal:execute
command: kubectl drain "$NODE" --ignore-daemonsets --delete-emptydir-data
session: 1
```

Watch pods reschedule in terminal 2:

```terminal:execute
command: kubectl -n $SESSION_NS get pods -o wide -w
session: 2
```

Verify the Storefront is still up:

```terminal:execute
command: |
  STOREFRONT=$(kubectl -n $SESSION_NS get svc frontend \
    -o jsonpath='{.spec.clusterIP}')
  curl -sf "http://${STOREFRONT}/" -o /dev/null && echo "Storefront: UP" || echo "Storefront: DOWN"
session: 1
```

Uncordon the node:

```terminal:execute
command: kubectl uncordon "$NODE"
session: 1
```

### Checkpoint ✅

```examiner:execute-test
name: lab-05-all-nodes-ready
title: "All nodes are Ready (after uncordon)"
autostart: false
timeout: 60
command: |
  NOT_READY=$(kubectl get nodes --no-headers | grep -v " Ready" | wc -l)
  [ "$NOT_READY" -eq 0 ] && exit 0 || exit 1
```

---

## Exercise 5.4: KEDA Autoscaling from Zero

```terminal:execute
command: switch-lab lab-05-keda
session: 1
```

Watch checkout-api scale from 0:

```terminal:execute
command: kubectl -n $SESSION_NS get deploy checkout-api -w
session: 2
```

The baseline load generator triggers KEDA. Within ~30 seconds, replicas go from 0 to 1+.

```terminal:execute
command: kubectl -n $SESSION_NS describe scaledobject checkout-api-v1-keda
session: 1
```

---

## Exercise 5.5: Recovery

Reset all incidents:

```terminal:execute
command: switch-lab lab-05-start
session: 1
```

All fault injection cleared. 90/10 canary restored. Healthy baseline.

---

## Key Takeaways

- **Distributed tracing** identifies root cause in seconds — which service, which version, which span.
- **PodDisruptionBudgets** are a safety contract for node maintenance. `minAvailable: 1` means Kubernetes won't evict the last replica.
- **KEDA** scales on real signals. Scale-to-zero means zero idle cost; scale-up happens on real traffic demand.

Click **Next Lab** to continue to Lab 6: Multi-Tenancy & Governance.
