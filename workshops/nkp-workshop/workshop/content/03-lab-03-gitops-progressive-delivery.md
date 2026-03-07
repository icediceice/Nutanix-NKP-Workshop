# Lab 3 — GitOps & Progressive Delivery

**Duration**: 45–60 min | **Goal**: Perform a canary rollout of payment-mock v2 through traffic mirroring → 10% → 50% → 100%, then execute a one-command rollback.

---

## Exercise 3.1: Traffic Mirroring — Test v2 with Zero Risk

Start from Lab 3 baseline (v2 pods running but 0% traffic):

```terminal:execute
command: switch-lab lab-03-start
session: 1
```

Enable traffic mirroring (v2 receives shadow copies of all requests):

```terminal:execute
command: switch-lab lab-03-mirror
session: 1
```

In **Kiali**, look for a **dashed line** between `checkout-api` and `payment-mock-v2` — that's the mirror edge.

Open the Storefront and refresh several times:

```dashboard:open-url
url: http://frontend.$(session_namespace).svc.cluster.local
name: Storefront
```

The storefront always shows the **blue** (v1) theme — users see no change.

Check the VirtualService mirror config:

```terminal:execute
command: kubectl -n $SESSION_NS get virtualservice payment-mock-vs -o yaml | grep -A8 mirror
session: 1
```

### Checkpoint ✅

```examiner:execute-test
name: lab-03-mirror-active
title: "VirtualService has mirror stanza"
autostart: true
timeout: 30
command: |
  kubectl -n $SESSION_NS get virtualservice payment-mock-vs -o yaml 2>/dev/null | \
    grep -q "mirror:" && exit 0 || exit 1
```

---

## Exercise 3.2: Canary 10% — Start the Rollout

```terminal:execute
command: switch-lab lab-03-canary-10
session: 1
```

Verify the weights:

```terminal:execute
command: kubectl -n $SESSION_NS get virtualservice payment-mock-vs -o yaml | grep -A5 weight
session: 1
```

Refresh the Storefront 10–20 times. About 1 in 10 loads shows the **green** (v2) theme.

Watch the traffic split in Kiali — the v2 edge is thinner but visible.

### Checkpoint ✅

```examiner:execute-test
name: lab-03-canary-10-active
title: "VirtualService shows 90/10 split"
autostart: true
timeout: 30
command: |
  V1=$(kubectl -n $SESSION_NS get virtualservice payment-mock-vs -o jsonpath='{.spec.http[0].route[0].weight}' 2>/dev/null)
  [ "$V1" = "90" ] && exit 0 || exit 1
```

---

## Exercise 3.3: Ramp — 50% and Full Cutover

Ramp to 50%:

```terminal:execute
command: switch-lab lab-03-canary-50
session: 1
```

Now about half the Storefront loads show green. Wait 30s and check Kiali.

Complete cutover to v2:

```terminal:execute
command: switch-lab lab-03-canary-100
session: 1
```

Every Storefront load now shows **green** (v2). All traffic is on v2.

```terminal:execute
command: kubectl -n $SESSION_NS get virtualservice payment-mock-vs -o yaml | grep -A5 weight
session: 1
```

### Checkpoint ✅

```examiner:execute-test
name: lab-03-canary-100-active
title: "VirtualService shows 0/100 (v2 full cutover)"
autostart: true
timeout: 30
command: |
  V2=$(kubectl -n $SESSION_NS get virtualservice payment-mock-vs -o jsonpath='{.spec.http[0].route[1].weight}' 2>/dev/null)
  [ "$V2" = "100" ] && exit 0 || exit 1
```

---

## Exercise 3.4: Rollback — Back to v1 in Seconds

Rollback to v1 baseline:

```terminal:execute
command: switch-lab lab-03-start
session: 1
```

The Storefront immediately returns to **blue** (v1). Rollback complete — under 60 seconds.

This is Git as the single source of truth. The ArgoCD audit trail shows every state transition.

---

## Key Takeaways

- **Traffic mirroring** lets you validate a new version with zero user risk.
- **Progressive delivery** limits blast radius. At 10% canary, only 10% of users are affected if v2 has a bug.
- **GitOps rollback** is a single operation — every state change is versioned, audited, and reversible.

Click **Next Lab** to continue to Lab 4: Storage & Stateful Workloads.
