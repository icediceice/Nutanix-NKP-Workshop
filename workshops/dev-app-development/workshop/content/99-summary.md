---
title: Summary
---

## What We Covered

You built a complete GitOps pipeline for a .NET application on NKP — from source code to
automated deployment in a production-grade Kubernetes cluster.

## The Pipeline You Built

```
Developer pushes code
        ↓
GitLab CI: run tests
        ↓
GitLab CI: docker build → push to Harbor
        ↓
GitLab CI: git commit new image tag to config repo
        ↓
FluxCD source-controller: detects new commit
        ↓
FluxCD kustomize-controller: applies updated manifests
        ↓
Kubernetes: rolling update of Deployment
        ↓
Application running with new code
```

## Key Takeaways

- **GitOps** means Git is the source of truth — the cluster state is defined in code
- **Two-repo pattern** separates application concerns from deployment concerns
- **FluxCD** is a pull-based CD system — the cluster pulls from Git, not the other way
- **Multi-stage Dockerfiles** keep .NET build tools out of the runtime image
- **CI variables** keep secrets out of the codebase

## Next Steps

- Explore the **NKP Platform for Developers** workshop to learn about Harbor, observability,
  the application catalog, and Istio service mesh
- Add image policy automation with FluxCD's `ImageRepository` and `ImagePolicy` objects to
  automate image tag updates without CI scripts
