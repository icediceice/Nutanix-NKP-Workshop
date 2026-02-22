---
title: Jobs and CronJobs
---

## What We're Doing

Not all workloads are long-running servers. Jobs run a container to completion — database
migrations, report generation, data imports. CronJobs schedule Jobs on a cron schedule —
nightly backups, hourly health reports. Both are essential for production operations.

## Steps

### 1. Create a Job

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/jobs/simple-job.yaml -n demo-app
```

```terminal:execute
command: kubectl get job -n demo-app -w
```

**Observe:** The COMPLETIONS column shows `0/1` then `1/1` when the Pod finishes successfully.
The Job ensures the task completes even if the Pod is evicted mid-execution.

### 2. Inspect the Job's Pod

```terminal:execute
command: kubectl get pods -n demo-app -l job-name=simple-job
```

```terminal:execute
command: kubectl logs -n demo-app -l job-name=simple-job
```

### 3. Run a parallel Job

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/jobs/parallel-job.yaml -n demo-app
```

```terminal:execute
command: kubectl get pods -n demo-app -w
```

**Observe:** Multiple Pods run simultaneously. The Job tracks completions and starts new Pods
until the target `completions` count is reached.

### 4. Create a CronJob

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/jobs/cronjob.yaml -n demo-app
```

```terminal:execute
command: kubectl get cronjob -n demo-app
```

**Observe:** The SCHEDULE column shows the cron expression. LAST SCHEDULE and ACTIVE show when
the last Job ran and whether any Jobs are currently running.

## What Just Happened

The Job controller ensures work is completed reliably, retrying on failure up to `backoffLimit`
times. The CronJob controller creates Job objects on the cron schedule. Together they handle
every batch workload pattern without needing external schedulers like cron on a VM.
