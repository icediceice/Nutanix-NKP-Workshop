---
title: Workshop Overview
---

## What We're Doing

The Twelve-Factor App methodology is a set of best practices for building modern, cloud-native
software-as-a-service applications. Originally articulated by Heroku engineers, these factors
are now the lingua franca of cloud-native architecture — and Kubernetes enforces many of them
automatically.

In this workshop you will follow the journey of **AppCo**, a fictional SaaS company modernising
a legacy monolith. Each factor is introduced in the context of a real AppCo engineering decision.

## The Twelve Factors at a Glance

| # | Factor | Theme |
|---|--------|-------|
| I | Codebase | One codebase, many deploys |
| II | Dependencies | Explicitly declare and isolate |
| III | Config | Store config in the environment |
| IV | Backing Services | Treat as attached resources |
| V | Build, Release, Run | Strictly separate stages |
| VI | Processes | Execute as stateless processes |
| VII | Port Binding | Export services via port binding |
| VIII | Concurrency | Scale out via the process model |
| IX | Disposability | Fast startup and graceful shutdown |
| X | Dev/Prod Parity | Keep environments as similar as possible |
| XI | Logs | Treat logs as event streams |
| XII | Admin Processes | Run admin tasks as one-off processes |

## Prerequisites

No cluster access is needed for this module — it is a guided discussion and conceptual deep-dive.
Optionally, a terminal is provided to inspect example manifests.
