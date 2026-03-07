# Lab 6 — Multi-Tenancy & Governance

## Overview
- **Duration**: 30–45 min
- **What you'll do**: Enforce namespace resource quotas, use Gatekeeper OPA policies in audit then deny mode, and verify RBAC role separation between developer and ops personas.

## Before You Begin
- Verify: Demo Wall shows "lab-06-start — Governance baseline, Gatekeeper in audit mode"
- Verify: `kubectl get k8sdemorequiredlabels demo-required-labels` shows `enforcementAction: dryrun`
- Current scenario: Full storefront + quota + Gatekeeper dryrun + RBAC roles

---

## Exercise 6.1: Quota Enforcement (10 min)

### What You'll Do
Fill the namespace quota with stress pods and observe what happens when you try to exceed it.

### Steps

1. Apply quota pressure:
   ```bash
   ./scripts/switch-lab.sh lab-06-quota-pressure
   ```

2. Check current quota usage:
   ```bash
   kubectl describe resourcequota demo-app-quota -n demo-app
   # Expected: pods ~30/40 used
   ```

3. Try to scale beyond the quota:
   ```bash
   kubectl -n demo-app scale deploy quota-stress --replicas=30
   # Expected: Some pods stay Pending
   ```

4. Check events for quota rejection:
   ```bash
   kubectl -n demo-app get events --sort-by=.lastTimestamp | tail -5
   # Expected: "exceeded quota: demo-app-quota"
   ```

5. In **NKP Console** → Clusters → [workload cluster] → Namespaces → `demo-app`:
   - See the amber/red quota bar indicating near-capacity usage

### Checkpoint ✅
- [ ] `kubectl describe resourcequota` shows usage near limit
- [ ] Scaling beyond 40 pods results in Pending pods
- [ ] Events show "exceeded quota" message

---

## Exercise 6.2: Gatekeeper Audit Mode (5 min)

### What You'll Do
Apply a policy-violating pod in audit (dryrun) mode and see that it's created but flagged as a violation.

### Steps

1. Check current constraint mode:
   ```bash
   kubectl get k8sdemorequiredlabels demo-required-labels \
     -o jsonpath='{.spec.enforcementAction}'
   # Expected: dryrun
   ```

2. Apply the violation pod (missing required `version` label):
   ```bash
   kubectl apply -f platform/policy/examples/policy-violation-example.yaml
   # Expected: Pod CREATED (dryrun allows it)
   ```

3. Check Gatekeeper violations:
   ```bash
   kubectl get k8sdemorequiredlabels demo-required-labels \
     -o jsonpath='{.status.totalViolations}'
   # Expected: 1 or more
   ```

4. In **Demo Wall**: Policy compliance card shows the violation count.

5. Clean up:
   ```bash
   kubectl -n demo-app delete pod policy-violation-example --ignore-not-found
   ```

### Checkpoint ✅
- [ ] Violation pod runs successfully (dryrun mode allows it)
- [ ] Gatekeeper reports a violation count > 0
- [ ] Demo Wall policy compliance card shows the violation

---

## Exercise 6.3: Gatekeeper Enforce Mode (5 min)

### What You'll Do
Switch the Gatekeeper constraint from dryrun to deny and see the same pod get rejected at admission.

### Steps

1. Switch to enforce mode:
   ```bash
   ./scripts/switch-lab.sh lab-06-policy-enforce
   ```

2. Verify enforce mode:
   ```bash
   kubectl get k8sdemorequiredlabels demo-required-labels \
     -o jsonpath='{.spec.enforcementAction}'
   # Expected: deny
   ```

3. Try the same violation pod:
   ```bash
   kubectl apply -f platform/policy/examples/policy-violation-example.yaml
   # Expected: REJECTED
   # Error from server: [demo-required-labels] label 'version' is required
   ```

4. Confirm nothing was created:
   ```bash
   kubectl -n demo-app get pod policy-violation-example
   # Expected: Error from server (NotFound)
   ```

### Checkpoint ✅
- [ ] `kubectl apply` fails with Gatekeeper rejection message mentioning `version` label
- [ ] Pod does not exist — rejected at admission webhook

---

## Exercise 6.4: RBAC Role Separation (5 min)

### What You'll Do
Verify that the dev-role and ops-role have the correct permissions using `kubectl auth can-i`.

### Steps

1. Check the roles:
   ```bash
   kubectl get roles -n demo-app -o wide
   kubectl describe role dev-role-demo-app -n demo-app
   kubectl describe role ops-role-demo-app -n demo-app
   ```

2. Simulate dev-role: can view, but NOT delete:
   ```bash
   kubectl auth can-i get pods -n demo-app \
     --as=system:serviceaccount:demo-app:dev-user
   # Expected: yes

   kubectl auth can-i delete pods -n demo-app \
     --as=system:serviceaccount:demo-app:dev-user
   # Expected: no
   ```

3. Simulate ops-role: full control:
   ```bash
   kubectl auth can-i delete pods -n demo-app \
     --as=system:serviceaccount:demo-app:ops-user
   # Expected: yes
   ```

### Checkpoint ✅
- [ ] `dev-user` can `get`/`list` but not `delete`/`scale`
- [ ] `ops-user` can perform all operations

---

## Exercise 6.5: Kommander Workspace Governance (5 min — Demo Mode)

### Instructor Demonstration

Show in **NKP Console (Kommander)**:
- **Access Control** → Roles: workspace-scoped roles
- **Applications**: Platform add-ons deployed to all clusters in the workspace
- **Clusters**: Attached clusters inheriting workspace policies

**Talking point**: "Add a new cluster to this workspace and it automatically inherits the same quotas, policies, RBAC, and platform add-ons. One control plane for the entire fleet — this is how Nutanix scales governance across hundreds of clusters."

---

## Cleanup
To reset this lab:
```bash
./scripts/switch-lab.sh lab-06-start
```

---

## Key Takeaways
- ResourceQuotas are namespace-scoped guardrails — teams self-service within their allocation, platform engineers set the ceiling.
- Gatekeeper gives you a policy-as-code audit trail. Start with `dryrun` to discover violations without breaking things, then flip to `deny` once you understand the blast radius.
- RBAC + Gatekeeper + Quotas give you three independent layers of governance. Kommander extends all three across a fleet of clusters from a single control plane.
