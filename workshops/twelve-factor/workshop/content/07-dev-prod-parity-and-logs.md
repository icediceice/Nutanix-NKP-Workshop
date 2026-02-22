---
title: "Factors X & XI: Dev/Prod Parity and Logs"
---

## What We're Doing

AppCo developers use SQLite on their laptops but PostgreSQL in production. Bugs that only appear
in production are a direct result of this divergence. Meanwhile, when the production server had
a disk failure last year, the logs went with it. Factors X and XI fix both problems.

## Factor X: Dev/Prod Parity — Keep development, staging, and production as similar as possible

The three gaps that cause parity problems:
- **Time gap:** Code written today deploying weeks later
- **Personnel gap:** Developers write code, ops deploy it
- **Tools gap:** Different databases, OS versions, middleware

**AppCo's fix:** Every developer runs the full stack locally using Docker Compose with the same
PostgreSQL image used in production. CI uses the same image. Staging uses the same Helm chart
as production with different values. The time gap is closed by daily deploys.

## Factor XI: Logs — Treat logs as event streams

An app should never concern itself with routing or storing its logs. Write to stdout/stderr and
let the platform handle collection, routing, and retention.

**AppCo's fix:** Remove all file-based log handlers. PHP logs go to stdout. The Nutanix NKP
logging stack (Fluent Bit + OpenSearch) captures all container stdout automatically.

```terminal:execute
command: kubectl logs -l app=appco --tail=20
```

**Observe:** Logs are streamed from all Pods matching the selector. In production, these same
streams flow into OpenSearch where they are indexed and searchable across the entire fleet.

## What Just Happened

Dev/prod parity (Factor X) eliminates the "works on my machine" class of bugs. Logs as streams
(Factor XI) means AppCo never loses a log line to a disk failure and can correlate events across
hundreds of Pods in a single search.
