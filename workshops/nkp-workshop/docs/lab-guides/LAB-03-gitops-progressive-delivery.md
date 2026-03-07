# Lab 3 — GitOps & Progressive Delivery

## Overview
- **Duration**: 45–60 min
- **What you'll do**: Perform a live canary rollout of payment-mock v2 — starting with traffic mirroring (zero user impact), progressing through 10%/50%/100% splits, and executing a one-command rollback.

## Before You Begin
- Verify: Demo Wall shows "lab-03-start — 100% v1 traffic"
- Verify: `kubectl -n demo-app get pods` shows both `payment-mock-v1-*` and `payment-mock-v2-*` running
- Current scenario: v2 pods deployed but receiving 0% of traffic

---

## Exercise 3.1: Traffic Mirroring — Test v2 with Zero Risk (10 min)

### What You'll Do
Mirror 100% of live traffic to v2 as shadow requests. Users only see v1 responses; v2 processes copies for validation.

### Steps

1. Switch to mirror overlay:
   ```bash
   ./scripts/switch-lab.sh lab-03-mirror
   ```

2. In **Kiali** → Graph: Look for a **dashed line** from `checkout-api` → `payment-mock-v2` (mirror edge)

3. In **Jaeger** → Service: `payment-mock` → Find Traces: See both v1 and v2 traces appearing

4. In **Storefront**: Refresh multiple times — **all loads show v1 (blue theme)**. Users see no change.

5. Check the VirtualService:
   ```bash
   kubectl -n demo-app get virtualservice payment-mock-vs -o yaml | grep -A5 mirror
   ```

### Checkpoint ✅
- [ ] Kiali shows dashed mirror edge to v2
- [ ] Jaeger shows v2 traces alongside v1
- [ ] Storefront shows only v1 theme (blue) — users unaffected
- [ ] Demo Wall shows: "Traffic mirroring — shadow v2, users see v1 only"

---

## Exercise 3.2: Canary 10% — Start the Rollout (10 min)

### What You'll Do
Shift 10% of live traffic to v2. Monitor error rate and latency before proceeding.

### Steps

1. Switch to 10% canary:
   ```bash
   ./scripts/switch-lab.sh lab-03-canary-10
   ```

2. Verify the VirtualService weight:
   ```bash
   kubectl -n demo-app get virtualservice payment-mock-vs -o yaml | grep -A5 weight
   # Expected: v1: 90, v2: 10
   ```

3. In **Storefront**: Refresh 10–20 times. Most loads show v1 (blue), ~1 in 10 shows v2 (green).

4. In **Kiali**: Graph shows traffic to both v1 and v2 subsets; v2 edge is thinner.

5. In **Jaeger**: Filter by tag `version=v2` to see v2-specific traces.

6. Demo Wall Traffic card shows: "v1 / v2 = 90 / 10"

### Checkpoint ✅
- [ ] VirtualService shows weight 90/10
- [ ] Storefront occasionally shows green theme
- [ ] Kiali shows both subsets receiving traffic

---

## Exercise 3.3: Ramp — 50% and Full Cutover (10 min)

### What You'll Do
Progress the canary rollout to 50% and then complete the cutover to 100% v2.

### Steps

1. Ramp to 50%:
   ```bash
   ./scripts/switch-lab.sh lab-03-canary-50
   # Observe: 50/50 traffic split in Kiali, Demo Wall, storefront
   # Wait 30 seconds for Kiali to update
   ```

2. Complete cutover to v2:
   ```bash
   ./scripts/switch-lab.sh lab-03-canary-100
   # Observe: 100% v2, all storefront loads show green theme
   ```

3. Verify:
   ```bash
   kubectl -n demo-app get virtualservice payment-mock-vs -o yaml | grep -A3 weight
   # Expected: v1: 0, v2: 100
   ```

### Checkpoint ✅
- [ ] After canary-100: VirtualService shows weight 0/100
- [ ] Storefront always shows green theme (v2)
- [ ] Kiali shows all traffic to v2 subset

---

## Exercise 3.4: Rollback (5 min)

### What You'll Do
Execute a one-command rollback from v2 back to v1 and observe instant traffic shift.

### Steps

1. Rollback to v1:
   ```bash
   ./scripts/switch-lab.sh lab-03-start
   ```

2. Observe:
   - **Storefront**: Immediately back to blue (v1) theme
   - **Kiali**: Traffic shifts back to v1 only
   - **Demo Wall**: "100% v1 baseline"

3. Show the Git audit trail:
   ```bash
   git log --oneline -5
   ```

### Checkpoint ✅
- [ ] Storefront shows only v1 theme (blue)
- [ ] Rollback completed in under 60 seconds
- [ ] Kiali shows 100% traffic on v1 subset

---

## Bonus Exercise: Observe a Bad Canary
Try injecting latency into v2 manually to simulate catching a bad release at 10%:
```bash
kubectl -n demo-app set env deployment/payment-mock-v2 INJECT_LATENCY_MS=1000
```
Watch Kiali show increased latency on the v2 edge, then roll back.

---

## Cleanup
To reset this lab:
```bash
./scripts/switch-lab.sh lab-03-start
```

---

## Key Takeaways
- Traffic mirroring lets you validate v2 with zero user risk — shadow traffic processes in v2 but only v1 responses are returned.
- Progressive delivery (10% → 50% → 100%) limits blast radius. If v2 has a bug, only 10% of users are affected.
- Rollback is a single Git operation. `selfHeal: true` means ArgoCD reverts the cluster immediately — no runbooks, no manual kubectl.
