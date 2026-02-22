---
title: Summary
---

## What We Covered

You followed AppCo from a fragile PHP monolith to a twelve-factor application running on
Kubernetes. Each factor addressed a specific class of operational pain.

## The AppCo Transformation

| Before | After | Factor |
|--------|-------|--------|
| Code on a shared drive | Git monorepo, branch protection | I |
| System dependencies assumed | Dockerfile with explicit deps | II |
| Passwords in source code | ConfigMaps and Secrets | III |
| Local MySQL only | Backing service URL in env var | IV |
| Manual `git pull` on server | Build → Release → Run pipeline | V |
| Sticky sessions, local files | Stateless Pods, Redis sessions | VI |
| Apache installed on host | Self-contained port-binding container | VII |
| Vertical scaling only | Independent Deployments per process type | VIII |
| Slow start, abrupt kills | Fast startup, SIGTERM graceful drain | IX |
| SQLite dev, Postgres prod | Same image and services everywhere | X |
| Logs on disk, lost on failure | stdout → Fluent Bit → OpenSearch | XI |
| SSH to run migrations | Kubernetes Jobs, CI-automated | XII |

## Further Reading

- [12factor.net](https://12factor.net) — the original methodology
- *Release It!* by Michael Nygard — patterns for resilient systems
- Kubernetes documentation: Jobs, ConfigMaps, HorizontalPodAutoscaler

## Next Steps

Proceed to the **Containers and Docker** workshop to build your own container images applying
the dependency and port-binding factors you learned today.
