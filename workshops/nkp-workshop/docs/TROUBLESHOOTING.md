# NKP Workshop — Troubleshooting Guide

---

## NKP-Specific: Known Issues & Root Causes

The issues below were discovered during the first live run on NKP and are now
fixed in the bootstrap script (`bootstrap-educates.sh`). They are documented
here so the root causes are understood if symptoms recur.

### Kiali or Jaeger dashboard tab shows 404

**Symptom:** Browser shows 404 when clicking the Kiali or Jaeger tab.

**Root cause:** Kiali and Jaeger are not installed by default on the NKP
workload cluster. They must be deployed via ArgoCD Applications.

**Fix (automated):** `bootstrap-educates.sh` now applies
`resources/observability/kiali.yaml` and `resources/observability/jaeger.yaml`
as part of setup. Each file contains an ArgoCD Application (Helm) plus an
Ingress in `istio-system`.

**Manual recovery:**
```bash
kubectl apply -f workshops/nkp-workshop/resources/observability/kiali.yaml
kubectl apply -f workshops/nkp-workshop/resources/observability/jaeger.yaml
# Wait ~2 min for ArgoCD to deploy the Helm releases
kubectl -n istio-system get pods -l app=kiali
kubectl -n istio-system get pods -l app.kubernetes.io/name=jaeger
```

---

### Dashboard tabs (ArgoCD, Kiali, Jaeger) show "connection refused" or fail to load

**Symptom:** Traefik log shows `externalName services not allowed:
kommander-default-workspace/<proxy-service-name>`.

**Root cause:** NKP's Traefik disables ExternalName service backends by default
(`--providers.kubernetesingress.allowExternalNameServices` is not set). Ingress
objects pointing to ExternalName services in `kommander-default-workspace` are
silently rejected — Traefik logs the error but returns 404 or drops the route.

**Fix (automated):** Ingress objects are now in the same namespace as their
target service so Traefik resolves them directly — no ExternalName proxy needed:
- ArgoCD → Ingress in `argocd` namespace → `argocd-server:80`
- Kiali → Ingress in `istio-system` namespace → `kiali:20001`
- Jaeger → Ingress in `istio-system` namespace → `jaeger:16686`

**Verify routing is working:**
```bash
# All three should return HTTP 200
curl -sk https://<ingress-domain>/dkp/argocd/ -o /dev/null -w "%{http_code}\n"
curl -sk https://<ingress-domain>/dkp/kiali/  -o /dev/null -w "%{http_code}\n"
curl -sk https://<ingress-domain>/dkp/jaeger/ -o /dev/null -w "%{http_code}\n"

# Check Traefik logs for any remaining ExternalName errors
kubectl -n kommander-default-workspace logs -l app.kubernetes.io/name=traefik \
  --tail=50 | grep "externalName"
```

---

### ArgoCD tab loads but SPA links or API calls fail (404 on /api/v1/…)

**Symptom:** ArgoCD page loads but navigation to Applications fails; browser
console shows 404s on `/api/v1/...` instead of `/dkp/argocd/api/v1/...`.

**Root cause:** ArgoCD defaults to serving at `/`. When served behind Traefik
at `/dkp/argocd`, it must be told its root path so API calls are constructed
with the correct prefix. This requires two keys in `argocd-cmd-params-cm`:
`server.basehref` and `server.rootpath`.

**Fix (automated):** `bootstrap-educates.sh` patches the configmap and restarts
`argocd-server` automatically.

**Manual recovery:**
```bash
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge \
  -p '{"data":{"server.basehref":"/dkp/argocd","server.rootpath":"/dkp/argocd","server.insecure":"true"}}'
kubectl -n argocd rollout restart deployment/argocd-server
kubectl -n argocd rollout status deployment/argocd-server --timeout=120s
```

---

### ArgoCD sync fails — Kyverno blocks LoadBalancer service

**Symptom:** ArgoCD Application stays OutOfSync; events show Kyverno admission
webhook denying creation of a `LoadBalancer` type Service.

**Root cause:** NKP Kyverno policies (`educates-environment-*`) enforce
`no-loadbalancer-service` in session namespaces. Any manifest with
`spec.type: LoadBalancer` is rejected at admission.

**Fix:** `demo-wall/base/service.yaml` uses `ClusterIP` (not `LoadBalancer`).
The demo-wall UI is accessed via the Educates dashboard at the internal
cluster DNS address.

**Check for Kyverno policy violations:**
```bash
kubectl -n <session-namespace> get events | grep -i "kyverno\|policy\|denied"
kubectl get polr -A | grep fail
```

---

### Per-session ClusterRole naming conflict (SharedResourceWarning)

**Symptom:** Educates shows `SharedResourceWarning`; multiple sessions fight
over a ClusterRole named `demo-wall-reader` and break each other.

**Root cause:** `demo-wall-reader` ClusterRole and ClusterRoleBinding have a
fixed name that is shared across all concurrent sessions.

**Fix:** The ArgoCD Application in `workshop.yaml` uses kustomize inline
patches to rename both resources to `demo-wall-reader-$(session_namespace)` per
session, making them globally unique.

---

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
