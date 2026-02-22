---
title: "Factor XII: Admin Processes"
---

## What We're Doing

AppCo's lead developer SSHes into production to run database migrations manually. If they are on
holiday, deployments are blocked. If they make a typo, data is corrupted. Factor XII defines
how one-off administrative tasks should be run in a twelve-factor system.

## Factor XII: Admin Processes — Run admin/management tasks as one-off processes

Database migrations, data backups, console scripts, and one-time fix-ups should run in an
identical environment to the long-running application processes — same image, same config,
same backing service connections. They should be tracked in version control alongside the app.

**AppCo's fix:** Database migrations are a Kubernetes Job that runs the same container image as
the web Deployment, passing a different command: `php artisan migrate --force`. The CI pipeline
creates this Job automatically before the rolling Deployment update.

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/factor-xii/migration-job.yaml
```

```terminal:execute
command: kubectl get job appco-migrate -w
```

**Observe:** The Job runs to completion, then stops. Its logs are available via `kubectl logs`.
The migration is auditable, repeatable, and does not require SSH access to any server.

## What Just Happened

Admin processes (Factor XII) complete the twelve-factor picture. By running migrations as Jobs
in the same environment as the app, AppCo eliminated the "only one person can deploy" bottleneck
and created a full audit trail of every administrative action run against production.

## Workshop Complete

You have now walked through all twelve factors with AppCo. The methodology is not about
following rules — it is about understanding the problems each factor solves and making
intentional architectural decisions that keep your software deployable, scalable, and operable.
