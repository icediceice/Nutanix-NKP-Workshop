# NKP Workshop — Reset Procedures

## Quick Reset (Between Sessions)

```bash
./scripts/reset.sh
```

This switches to `workshop-reset` (ArgoCD prunes all app resources), waits 30s, then switches to `workshop-load-off` (idle state). Takes ~2–3 minutes.

---

## Full Reset (Clean Slate)

Use this if the quick reset leaves unexpected state.

```bash
# Step 1: Delete application workload namespaces
kubectl delete namespace demo-app --ignore-not-found
kubectl delete namespace demo-ops --ignore-not-found

# Step 2: Delete the ArgoCD Application
kubectl -n argocd delete application rx-demo --ignore-not-found

# Step 3: Wait for cleanup
sleep 30

# Step 4: Re-bootstrap
./scripts/bootstrap-workshop.sh --lab lab-01-start
```

---

## Reset a Specific Lab

If you only need to reset one lab to its starting state:

```bash
./scripts/switch-lab.sh lab-01-start    # Reset Lab 1
./scripts/switch-lab.sh lab-02-start    # Reset Lab 2
./scripts/switch-lab.sh lab-03-start    # Reset Lab 3
./scripts/switch-lab.sh lab-04-start    # Reset Lab 4
./scripts/switch-lab.sh lab-05-start    # Reset Lab 5
./scripts/switch-lab.sh lab-06-start    # Reset Lab 6
```

---

## Reset After Node Drain (Lab 5)

If a node is still cordoned after Lab 5:

```bash
# List nodes and their status
kubectl get nodes

# Uncordon any cordoned nodes
for node in $(kubectl get nodes -o name | xargs); do
  kubectl uncordon "$node" 2>/dev/null || true
done

# Verify all nodes are Ready
kubectl get nodes
```

---

## Clear Gatekeeper State (Lab 6)

After Lab 6 policy-enforce, reset Gatekeeper to dryrun:

```bash
./scripts/switch-lab.sh lab-06-start
# This switches back to gatekeeper-constraint-dryrun.yaml
```

---

## Verify Clean State

After any reset, verify the cluster is clean:

```bash
# No app pods running
kubectl get pods -n demo-app 2>/dev/null || echo "Namespace gone — that's fine"

# Demo Wall shows idle state
# Load generator is off

# ArgoCD Application is Synced/Healthy
kubectl -n argocd get application rx-demo
```
