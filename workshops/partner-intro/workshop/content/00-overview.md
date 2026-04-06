---
title: Workshop Overview
---

## Welcome

This workshop introduces NKP — Nutanix Kubernetes Platform — through three connected modules.
Each module builds on the previous one, from fundamental concepts to a live production-grade platform.

## What You Will See

| # | Module | Format | Duration |
|---|--------|--------|----------|
| 1 | Container Fundamentals | Concepts + hands-on terminal | ~25 min |
| 2 | NKP Kommander Platform Tour | Hands-on + instructor console demo | ~35 min |
| 3 | Ecommerce on NKP — Live Demo | Guided walkthrough + live observability | ~30 min |

**Total: ~90 minutes**

---

## Module 1 — Container Fundamentals

You already know VMs. Containers are the same idea — an isolated, portable runtime environment
— but stripped down to just the application and its dependencies. No guest OS, no hypervisor overhead.
The result is something that starts in milliseconds, runs hundreds-per-host, and travels through a
pipeline from laptop to production without changing a single file.

Understanding containers is the foundation for everything NKP does. Every workload on the platform
is a container.

---

## Module 2 — NKP Kommander Platform Tour

Running Kubernetes at scale means answering questions that vanilla Kubernetes does not:
Who can access which cluster? How do policies propagate across hundreds of clusters?
Where does a new team member download their kubeconfig?

Kommander is the NKP answer. You will see how workspaces enforce multi-tenancy, how access
policies replicate automatically to every cluster in a workspace, and how the NKP console
gives operators a single pane across the entire fleet.

---

## Module 3 — Ecommerce on NKP

A 4-service online storefront — frontend, catalog, checkout, and payment — running live on NKP
with Istio service mesh. You will browse the application, watch its service topology light up in
Kiali, and observe as we inject a latency fault and use distributed traces to pinpoint the culprit
in seconds.

---

## Prerequisites

> These are pre-configured by your facilitator before the session starts.

- NKP management cluster running with Kommander
- otel-shop-lite demo app deployed in the `demo-app` namespace
- Demo Wall accessible at the URL your facilitator provides
