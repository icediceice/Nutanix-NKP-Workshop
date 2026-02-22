---
title: Summary
---

## What We Covered

You explored the NKP platform services that development teams use daily. These services are
pre-installed, pre-integrated, and managed by the platform team — freeing developers to focus
on application code rather than infrastructure.

## Platform Services Summary

| Service | Developer Use Case | URL Type |
|---------|-------------------|---------|
| Harbor | Store and scan container images | Web UI + Docker CLI |
| Grafana | View application and cluster metrics | Web UI |
| OpenSearch | Search and filter application logs | Web UI |
| App Catalog | Deploy databases and middleware | Web UI + kubectl |
| FluxCD | GitOps deployments | kubectl + Git |
| Istio / Kiali | Service mesh and traffic visualisation | Web UI + kubectl |
| Traefik | Ingress and TLS termination | kubectl Ingress objects |

## The Developer Workflow on NKP

```
Write code → Push to GitLab → CI builds image → CI pushes to Harbor
→ CI updates config repo → FluxCD deploys → Grafana/OpenSearch shows telemetry
```

Every step uses a platform service. The developer never touches a VM, never installs software
on a server, and never runs a manual deployment command in production.

## Next Steps

- If you are on the **Developer track**, this completes your workshop series
- Return to the closing session for the architecture review and Q&A
- Explore the NKP documentation portal for advanced topics: KEDA, Velero backup, and
  multi-cluster management with Kommander
