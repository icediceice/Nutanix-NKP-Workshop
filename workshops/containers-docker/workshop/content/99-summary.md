---
title: Summary
---

## What We Covered

You went from understanding what a container is at the kernel level to building, running, and
publishing production-ready images. These skills are the prerequisite for everything that runs
on Kubernetes.

## Key Takeaways

- **Containers are not VMs** — they share the host kernel and use namespaces/cgroups for isolation
- **Images are layered** — each Dockerfile instruction is a layer; cache invalidation flows downward
- **Order matters** — copy dependency manifests before source code to maximise cache reuse
- **Multi-stage builds** — keep build tools out of runtime images; smaller = safer
- **Registries** — Harbor provides private storage with RBAC and vulnerability scanning

## Dockerfile Best Practices Checklist

- [ ] Use a specific base image tag, never `latest`
- [ ] Run as a non-root user (`USER 1001`)
- [ ] Combine `apt-get update && apt-get install` in one `RUN` to avoid stale cache
- [ ] Clean up package caches in the same `RUN` instruction
- [ ] Use multi-stage builds for compiled languages
- [ ] Pin dependency versions in your manifest files
- [ ] Add a `.dockerignore` file to exclude `node_modules`, `.git`, test data

## Next Steps

Proceed to the **Kubernetes Architecture** workshop where you will deploy the images you built
here using Deployments, Services, ConfigMaps, and the full set of Kubernetes primitives.
