---
title: "Factors III & IV: Config and Backing Services"
---

## What We're Doing

Config and backing services are where most security incidents and environment-specific failures
originate. AppCo hard-codes database passwords in PHP files and has different code paths for
"are we in staging or prod?" — both of which are violations waiting to become incidents.

## Factor III: Config — Store config in the environment

Everything that varies between deploys — database URLs, API keys, feature flags, external service
hostnames — must come from the environment, not the code. A litmus test: could you open-source
your codebase right now without exposing credentials? If not, you have a Factor III violation.

**AppCo's fix:** Move all config to Kubernetes `ConfigMap` and `Secret` objects, injected as
environment variables.

```terminal:execute
command: kubectl create configmap appco-config --from-literal=DB_HOST=postgres --from-literal=APP_ENV=production --dry-run=client -o yaml
```

**Observe:** The ConfigMap holds non-sensitive config. Secrets (base64-encoded) hold credentials.
The Pod spec references them — the image itself contains no config values.

## Factor IV: Backing Services — Treat as attached resources

A backing service is any service the app consumes over the network: databases, caches, message
queues, email providers. The factor says: treat local and third-party services identically. You
should be able to swap a local MySQL for an RDS instance by changing a URL, not code.

**AppCo's fix:** The database connection string is an environment variable. Switching from the
local dev database to the managed Nutanix Era PostgreSQL instance is a one-line change in the
ConfigMap — zero code changes.

## What Just Happened

Config is now external to the image. The same container image can run in dev, staging, and
production — the environment tells it where to connect and how to behave. This is the foundation
of environment parity (Factor X) and safe secret management.
