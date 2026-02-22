---
title: Summary
---

## What We Covered

You worked through sixteen Kubernetes object types and operational patterns. This is the largest
module in the workshop series and covers the day-to-day toolkit of every Kubernetes practitioner.

## Quick Reference

| Object | Purpose | Key Command |
|--------|---------|-------------|
| Namespace | Isolation boundary | `kubectl create namespace` |
| Deployment | Manage stateless replicas | `kubectl create deployment` |
| ConfigMap | Non-sensitive config | `kubectl create configmap` |
| Secret | Sensitive data | `kubectl create secret` |
| PVC | Persistent storage claim | `kubectl apply -f pvc.yaml` |
| Service | Stable network endpoint | `kubectl expose deployment` |
| NetworkPolicy | Traffic allow-lists | `kubectl apply -f policy.yaml` |
| Ingress | L7 HTTP routing | `kubectl apply -f ingress.yaml` |
| Job | Run-to-completion task | `kubectl apply -f job.yaml` |
| CronJob | Scheduled tasks | `kubectl apply -f cronjob.yaml` |

## Production Checklist

- [ ] All Pods have resource requests and limits set
- [ ] Liveness and readiness probes are configured
- [ ] No container runs as root (securityContext)
- [ ] Secrets are not stored in ConfigMaps
- [ ] NetworkPolicy default-deny is applied per namespace
- [ ] Ingress uses TLS with a valid certificate

## Next Steps

- **Developer track:** Proceed to the **Application Development on NKP** workshop
- **Infra track:** Proceed to the **NKP Platform for Infra** workshop
