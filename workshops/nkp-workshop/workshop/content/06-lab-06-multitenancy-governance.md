---
title: "Lab 6 — Multi-Tenancy & Governance"
---

## Why Governance Matters

A shared cluster without governance leads to:
- One team using all the CPU — other teams starve
- An app without required labels — monitoring breaks
- A developer accidentally deleting production resources

NKP enforces governance at three levels:

```mermaid
graph TB
    subgraph GOVERNANCE["Governance Layers"]
        QUOTA["📋 ResourceQuota<br/>Ceiling per namespace<br/>'Team A gets at most 10 CPUs'"]
        GATE["🛡️ Gatekeeper (OPA)<br/>Policy-as-code admission<br/>'Every pod MUST have a version label'"]
        RBAC["🔑 RBAC<br/>Role-based access<br/>'Devs can read pods, not delete them'"]
    end

    REQ["📦 kubectl apply..."] --> GATE
    GATE -->|"allowed"| QUOTA
    QUOTA -->|"within quota"| K8S["⚙️ Kubernetes API Server"]
    GATE -->|"denied"| REJECT["❌ Error from server"]
    QUOTA -->|"quota exceeded"| REJECT2["❌ Cannot create resource"]
    RBAC -->|"checks identity"| GATE

    style QUOTA fill:#6366f1,color:#fff
    style GATE fill:#ef4444,color:#fff
    style RBAC fill:#0ea5e9,color:#fff
    style K8S fill:#10b981,color:#fff
```

These layers are cumulative — a request must pass all three.

---

## Exercise 6.1 — Quota Enforcement

**Duration**: 30–45 min | **Goal**: Enforce namespace quotas, use Gatekeeper in audit then deny mode, verify RBAC role separation.

Start Lab 6 baseline:

```bash
switch-lab lab-06-start
```

Apply quota pressure (20 stress pods):

```bash
switch-lab lab-06-quota-pressure
```

Check current quota usage:

```bash
kubectl describe resourcequota demo-app-quota -n $SESSION_NS
```

Try to scale beyond the quota:

```bash
kubectl -n $SESSION_NS scale deploy quota-stress --replicas=30
```

Check events for quota rejection:

```bash
kubectl -n $SESSION_NS get events --sort-by=.lastTimestamp | tail -5
```

**👁 Observe:** The scale command succeeds (Deployment updated) but the pods fail to be created.
The events show: `exceeded quota`. The quota enforces a ceiling, not a hard limit on API calls —
the Deployment records the desired state, but the API server refuses to schedule the pods.

### Checkpoint ✅


---

## Exercise 6.2 — Gatekeeper Audit Mode

Gatekeeper enforces policies at admission time using OPA (Open Policy Agent). Before enforcing,
use `dryrun` mode to **audit** violations without breaking anything.

```mermaid
graph LR
    subgraph DRYRUN["🟡 dryrun mode"]
        POD_D["📦 pod without version label"] -->|"allowed"| K8S_D["⚙️ API Server<br/>Pod created"]
        K8S_D --> VIOL["📋 Violation recorded<br/>totalViolations: 1"]
    end
    subgraph DENY["🔴 deny mode"]
        POD_E["📦 pod without version label"] -->|"rejected"| ERR["❌ Error: label 'version' required"]
    end

    style DRYRUN fill:#f59e0b,color:#000
    style DENY fill:#ef4444,color:#fff
```

Check current enforcement mode (should be dryrun):

```bash
kubectl get k8sdemorequiredlabels demo-required-labels \
  -o jsonpath='{.spec.enforcementAction}'
echo ""
```

Apply the policy-violating pod (missing `version` label):

```bash
kubectl apply -f ~/exercises/policy-violation-example.yaml
```

**Expected: Pod created** — dryrun mode allows it but records a violation.

Check violation count:

```bash
kubectl get k8sdemorequiredlabels demo-required-labels \
  -o jsonpath='{.status.totalViolations}'
echo " violation(s)"
```

Clean up:

```bash
kubectl -n $SESSION_NS delete pod policy-violation-example --ignore-not-found
```

---

## Exercise 6.3 — Gatekeeper Enforce Mode

Once you've audited violations and know what's non-compliant, switch to `deny` to block bad
workloads at the door:

```bash
switch-lab lab-06-policy-enforce
```

Verify mode has switched to deny:

```bash
kubectl get k8sdemorequiredlabels demo-required-labels \
  -o jsonpath='{.spec.enforcementAction}'
echo ""
```

Try the same violation pod — it will now be **rejected at admission**:

```bash
kubectl apply -f ~/exercises/policy-violation-example.yaml
```

**Expected:** `Error from server — [demo-required-labels] label 'version' is required`.

Confirm the pod was not created:

```bash
kubectl -n $SESSION_NS get pod policy-violation-example
```

**Expected:** `Error from server (NotFound)`.

### Checkpoint ✅


---

## Exercise 6.4 — RBAC Role Separation

RBAC maps **who** (ServiceAccount) → **what** (verbs) → **where** (namespace/resource):

```mermaid
graph TB
    subgraph ROLES["RBAC Roles in this Workshop"]
        DEV["👷 dev-user<br/>Role: developer"]
        OPS["🛠️ ops-user<br/>Role: operator"]
    end
    subgraph DEV_CAN["Developer can:"]
        D1["✅ get / list pods"]
        D2["✅ get / list services"]
        D3["✅ view logs"]
        D4["❌ delete pods"]
        D5["❌ exec into pods"]
    end
    subgraph OPS_CAN["Operator can:"]
        O1["✅ get / list pods"]
        O2["✅ delete pods"]
        O3["✅ exec into pods"]
        O4["✅ drain nodes"]
        O5["❌ modify RBAC"]
    end
    DEV --> DEV_CAN
    OPS --> OPS_CAN

    style DEV fill:#6366f1,color:#fff
    style OPS fill:#0ea5e9,color:#fff
```

Check what the dev-user can and cannot do:

```bash
echo "=== Dev User Permissions ==="
echo -n "get pods: "
kubectl auth can-i get pods -n $SESSION_NS \
  --as=system:serviceaccount:$SESSION_NS:dev-user
echo -n "delete pods: "
kubectl auth can-i delete pods -n $SESSION_NS \
  --as=system:serviceaccount:$SESSION_NS:dev-user
```

```bash
echo "=== Ops User Permissions ==="
echo -n "delete pods: "
kubectl auth can-i delete pods -n $SESSION_NS \
  --as=system:serviceaccount:$SESSION_NS:ops-user
echo -n "exec into pods: "
kubectl auth can-i create pods/exec -n $SESSION_NS \
  --as=system:serviceaccount:$SESSION_NS:ops-user
```

**👁 Observe:** `yes`/`no` is enforced by the API server, not by trust. A dev-user token physically
cannot delete pods — the API server rejects the request. No sudo, no escaping, no bypassing.

---

## Key Takeaways

- **ResourceQuotas** give teams self-service within a ceiling. Platform engineers set the policy; developers work freely within it.
- **Gatekeeper** policy-as-code: start with `dryrun` to audit without breaking things, switch to `deny` once ready to enforce.
- **RBAC** at the namespace level separates developer read-only from ops full-control — enforced by the API server, not trust.

Click **Finish** to continue to the Workshop Summary.
