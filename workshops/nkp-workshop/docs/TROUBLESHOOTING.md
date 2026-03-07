# NKP Workshop — Troubleshooting Guide

## ArgoCD Issues

### Application stuck in Progressing state
```bash
# Force a hard refresh
kubectl -n argocd annotate application rx-demo \
  argocd.argoproj.io/refresh=hard --overwrite

# Check ArgoCD application events
kubectl -n argocd describe application rx-demo | tail -30

# Check repo-server logs
kubectl -n argocd logs -l app.kubernetes.io/name=argocd-repo-server --tail=50
```

### Application shows OutOfSync after switch-lab.sh
```bash
# Wait 30s — ArgoCD needs time to detect the path change
# If still OutOfSync after 60s, force sync:
kubectl -n argocd app sync rx-demo --force
```

### kustomize build errors
```bash
# Test the overlay locally
kustomize build apps/storefront/overlays/lab-01-start

# Common issue: relative paths in kustomization.yaml
# Ensure paths use ../../ or ../../../../ relative to the kustomization.yaml location
```

---

## Istio / Kiali Issues

### Kiali graph is empty (no services shown)
```bash
# Check load generator is running
kubectl -n demo-ops get pods -l app=demo-loadgen

# Check Istio injection is enabled on namespace
kubectl get ns demo-app -o jsonpath='{.metadata.labels}'
# Expected: istio-injection: enabled

# Check sidecars are injected (2 containers per pod)
kubectl -n demo-app get pods -o jsonpath='{range .items[*]}{.metadata.name}: {range .spec.containers[*]}{.name} {end}\n{end}'
```

### Storefront not accessible (404 or connection refused)
```bash
# Check Istio ingress gateway
kubectl -n istio-helm-gateway-ns get svc istio-helm-ingressgateway
# Expected: EXTERNAL-IP is set (not <pending>)

# Check VirtualService exists
kubectl -n demo-app get virtualservice

# Check Gateway exists
kubectl -n demo-app get gateway

# Describe ingress gateway for troubleshooting
kubectl -n istio-helm-gateway-ns describe svc istio-helm-ingressgateway
```

### Traffic split not updating in Kiali
- Kiali aggregates metrics over a time window. Wait 30–60 seconds after switching overlays.
- Refresh Kiali → Graph → click "Refresh" button.

---

## Storage Issues

### PVC stuck in Pending state
```bash
# Check PVC events
kubectl -n demo-app describe pvc data-postgres-0

# Check CSI driver pods
kubectl -n ntnx-system get pods
kubectl -n ntnx-system logs -l app=nutanix-csi-node --tail=30

# Common causes:
# - No capacity on Nutanix storage
# - CSI driver not connected to Nutanix cluster
# - StorageClass provisioner misconfigured
```

### VolumeSnapshot stuck in "readyToUse: false"
```bash
# Check VolumeSnapshot status
kubectl -n demo-app describe volumesnapshot postgres-snapshot

# Check VolumeSnapshotContent
kubectl get volumesnapshotcontent

# Check CSI snapshotter logs
kubectl -n kube-system logs -l app=csi-snapshotter --tail=30
```

---

## Gatekeeper Issues

### Constraint not enforcing (pods still created in deny mode)
```bash
# Check Gatekeeper webhook is active
kubectl get validatingwebhookconfigurations | grep gatekeeper

# Check Gatekeeper controller logs
kubectl -n gatekeeper-system logs -l control-plane=controller-manager --tail=30

# Verify constraint mode
kubectl get k8sdemorequiredlabels demo-required-labels -o yaml | grep enforcementAction
```

### ConstraintTemplate not installed
```bash
# The ConstraintTemplate CRD must be applied before the Constraint.
# Check if it exists:
kubectl get constrainttemplate k8sdemorequiredlabels

# If missing, apply it directly:
kubectl apply -f platform/policy/constraint-template.yaml
# Then wait 30s before applying the constraint
```

---

## KEDA Issues

### checkout-api not scaling from zero
```bash
# Check ScaledObject status
kubectl -n demo-app describe scaledobject checkout-api-v1-keda

# Check KEDA operator logs
kubectl -n keda logs -l app=keda-operator --tail=30

# Verify Prometheus is accessible from KEDA
# KEDA queries Prometheus for Istio request rate — Prometheus must be reachable
kubectl -n monitoring get svc prometheus-operated
```

---

## Load Generator Issues

### Load generator pod not starting
```bash
kubectl -n demo-ops describe pod -l app=demo-loadgen
# Check image pull errors — ensure rx-storefront/loadgen:1.0 is accessible
```

### No traffic visible in Kiali despite load generator running
```bash
# Verify target URL is reachable from demo-ops namespace
kubectl -n demo-ops exec -it <loadgen-pod> -- \
  wget -q -O- http://frontend.demo-app.svc.cluster.local | head -5
```

---

## Workshop Reset Issues

### Reset leaves stale resources
```bash
# Manual cleanup if switch-lab.sh workshop-reset didn't prune everything:
kubectl delete namespace demo-app
kubectl delete namespace demo-ops
kubectl -n argocd delete application rx-demo

# Recreate and restart
./scripts/bootstrap-workshop.sh --lab lab-01-start
```
