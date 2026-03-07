# NKP Workshop — Prerequisites & Cluster Requirements

## Cluster Requirements

| Component | Requirement |
|-----------|------------|
| NKP version | 2.16+ |
| Worker nodes | 3+ (required for node failure resilience lab) |
| Worker node sizing | 8 vCPU, 32 GB RAM minimum per node |
| Total cluster capacity | 24+ vCPU, 96+ GB RAM |
| Kubernetes version | 1.28+ |
| Container runtime | containerd |
| CNI | Calico (NKP default) |

## Platform Add-ons (Pre-installed via NKP)

Run this verification before starting the workshop:

```bash
# Istio
kubectl get pods -n istio-system
# Expected: istiod, istio-ingressgateway running

# Kiali
kubectl get pods -n kiali
# Expected: kiali running

# Jaeger (or OpenTelemetry + Jaeger backend)
kubectl get pods -n monitoring | grep jaeger
# OR
kubectl get pods -n monitoring | grep opentelemetry

# Grafana
kubectl get pods -n monitoring | grep grafana

# Gatekeeper (OPA)
kubectl get pods -n gatekeeper-system
# Expected: gatekeeper-controller-manager, gatekeeper-audit running

# KEDA
kubectl get pods -n keda
# Expected: keda-operator running
```

## Storage Requirements (Pre-configured)

```bash
# Verify StorageClasses
kubectl get storageclass
# Required: nutanix-volumes (RWO), nutanix-files (RWX)

# Verify VolumeSnapshotClass
kubectl get volumesnapshotclass
# Required: nutanix-snapshot

# Verify CSI driver
kubectl get pods -n ntnx-system
# Expected: csi-driver pods running
```

## Network Requirements

| Requirement | Notes |
|-------------|-------|
| LoadBalancer | MetalLB or cloud LB — needed for Istio ingress and Demo Wall |
| Participant access | HTTP/HTTPS to Istio ingress, NKP console, ArgoCD |
| DNS (optional) | Wildcard DNS for pretty URLs; IP-based access works without DNS |

## ArgoCD Setup

ArgoCD must be installed and the workshop repo must be accessible:

```bash
# Verify ArgoCD
kubectl get pods -n argocd
# Expected: argocd-server, argocd-repo-server, argocd-application-controller running

# Verify repo access (after bootstrap)
kubectl -n argocd get application rx-demo
```

## Pre-Workshop Verification Checklist

Run through these checks 30 minutes before the workshop starts:

- [ ] `kubectl get nodes` — 3+ nodes in Ready state
- [ ] `kubectl get pods -n istio-system` — all Running
- [ ] `kubectl get pods -n argocd` — all Running
- [ ] `kubectl get pods -n gatekeeper-system` — all Running
- [ ] `kubectl get pods -n keda` — all Running
- [ ] `kubectl get storageclass` — `nutanix-volumes` and `nutanix-files` present
- [ ] `kubectl get volumesnapshotclass` — `nutanix-snapshot` present
- [ ] ArgoCD Application synced: `kubectl -n argocd get app rx-demo`
- [ ] Demo Wall accessible in browser
- [ ] Kiali, Jaeger, Grafana accessible (NKP SSO)
- [ ] `./scripts/print-access.sh` shows valid URLs
