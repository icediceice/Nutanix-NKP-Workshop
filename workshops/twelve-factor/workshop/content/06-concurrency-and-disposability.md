---
title: "Factors VIII & IX: Concurrency and Disposability"
---

## What We're Doing

AppCo handles peak load by increasing the number of Apache worker threads on a single server.
This vertical scaling has a ceiling and a single point of failure. Factors VIII and IX define
how twelve-factor apps scale out and handle the inevitable Pod terminations gracefully.

## Factor VIII: Concurrency — Scale out via the process model

Different workload types should be handled by different process types. A web process handles
HTTP requests. A worker process handles background jobs. Each can be scaled independently.

**AppCo's fix:** Split into two Kubernetes Deployments:
- `appco-web` — scales with HTTP request rate (HPA based on CPU)
- `appco-worker` — scales with queue depth (KEDA based on Redis queue length)

```terminal:execute
command: kubectl get deployments -l app=appco
```

**Observe:** Two separate Deployments. The web tier can scale to 20 replicas while the worker
tier stays at 3 — matching the actual workload shape.

## Factor IX: Disposability — Maximise robustness with fast startup and graceful shutdown

Pods will be killed — by scaling events, node maintenance, or failures. A disposable process
starts fast and shuts down gracefully. On SIGTERM, the web server stops accepting new connections
and finishes in-flight requests before exiting.

**AppCo's fix:** Add a `preStop` hook and set `terminationGracePeriodSeconds: 30`. The PHP-FPM
process drains its worker pool before the container exits.

## What Just Happened

Concurrency (Factor VIII) enables independent scaling of different workload types. Disposability
(Factor IX) ensures that Kubernetes can safely reschedule Pods without dropping requests or
corrupting jobs. Together they make AppCo resilient to the dynamic nature of a container platform.
