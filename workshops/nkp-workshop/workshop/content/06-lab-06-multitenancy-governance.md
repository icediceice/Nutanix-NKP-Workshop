# Lab 6 — Multi-Tenancy & Governance

**Duration**: 30–45 min | **Goal**: Enforce namespace quotas, use Gatekeeper policies in audit then deny mode, and verify RBAC role separation.

---

## Exercise 6.1: Quota Enforcement

Start Lab 6 baseline:

```terminal:execute
command: switch-lab lab-06-start
session: 1
```

Apply quota pressure (20 stress pods):

```terminal:execute
command: switch-lab lab-06-quota-pressure
session: 1
```

Check current quota usage:

```terminal:execute
command: kubectl describe resourcequota demo-app-quota -n $SESSION_NS
session: 1
```

Try to scale beyond the quota:

```terminal:execute
command: kubectl -n $SESSION_NS scale deploy quota-stress --replicas=30
session: 1
```

Check events for quota rejection:

```terminal:execute
command: kubectl -n $SESSION_NS get events --sort-by=.lastTimestamp | tail -5
session: 1
```

### Checkpoint ✅

```examiner:execute-test
name: lab-06-quota-stress-running
title: "Quota stress deployment is active"
autostart: true
timeout: 60
command: |
  kubectl -n $SESSION_NS get deploy quota-stress &>/dev/null && exit 0 || exit 1
```

---

## Exercise 6.2: Gatekeeper Audit Mode

Check current enforcement mode (should be dryrun):

```terminal:execute
command: |
  kubectl get k8sdemorequiredlabels demo-required-labels \
    -o jsonpath='{.spec.enforcementAction}'
  echo ""
session: 1
```

Apply the policy-violating pod (missing `version` label):

```terminal:execute
command: kubectl apply -f ~/exercises/policy-violation-example.yaml
session: 1
```

Expected: **Pod created** — dryrun mode allows it but flags a violation.

Check violation count:

```terminal:execute
command: |
  kubectl get k8sdemorequiredlabels demo-required-labels \
    -o jsonpath='{.status.totalViolations}'
  echo " violation(s)"
session: 1
```

Clean up:

```terminal:execute
command: kubectl -n $SESSION_NS delete pod policy-violation-example --ignore-not-found
session: 1
```

---

## Exercise 6.3: Gatekeeper Enforce Mode

```terminal:execute
command: switch-lab lab-06-policy-enforce
session: 1
```

Verify mode has switched to deny:

```terminal:execute
command: |
  kubectl get k8sdemorequiredlabels demo-required-labels \
    -o jsonpath='{.spec.enforcementAction}'
  echo ""
session: 1
```

Try the same violation pod — it will now be **rejected at admission**:

```terminal:execute
command: kubectl apply -f ~/exercises/policy-violation-example.yaml
session: 1
```

Expected: Error from server — `[demo-required-labels] label 'version' is required`.

Confirm the pod was not created:

```terminal:execute
command: kubectl -n $SESSION_NS get pod policy-violation-example
session: 1
```

Expected: `Error from server (NotFound)`.

### Checkpoint ✅

```examiner:execute-test
name: lab-06-enforce-active
title: "Gatekeeper constraint is in deny mode"
autostart: true
timeout: 30
command: |
  MODE=$(kubectl get k8sdemorequiredlabels demo-required-labels \
    -o jsonpath='{.spec.enforcementAction}' 2>/dev/null)
  [ "$MODE" = "deny" ] && exit 0 || exit 1
```

---

## Exercise 6.4: RBAC Role Separation

Check what the dev-user can and cannot do:

```terminal:execute
command: |
  echo "=== Dev User Permissions ==="
  echo -n "get pods: "
  kubectl auth can-i get pods -n $SESSION_NS \
    --as=system:serviceaccount:$SESSION_NS:dev-user
  echo -n "delete pods: "
  kubectl auth can-i delete pods -n $SESSION_NS \
    --as=system:serviceaccount:$SESSION_NS:dev-user
session: 1
```

```terminal:execute
command: |
  echo "=== Ops User Permissions ==="
  echo -n "delete pods: "
  kubectl auth can-i delete pods -n $SESSION_NS \
    --as=system:serviceaccount:$SESSION_NS:ops-user
  echo -n "exec into pods: "
  kubectl auth can-i create pods/exec -n $SESSION_NS \
    --as=system:serviceaccount:$SESSION_NS:ops-user
session: 1
```

---

## Key Takeaways

- **ResourceQuotas** give teams self-service within a ceiling. Platform engineers set the policy; developers work freely within it.
- **Gatekeeper** policy-as-code: start with `dryrun` to audit without breaking things, switch to `deny` once ready to enforce.
- **RBAC** at the namespace level separates developer read-only from ops full-control — enforced by the API server, not trust.

Click **Finish** to continue to the Workshop Summary.
