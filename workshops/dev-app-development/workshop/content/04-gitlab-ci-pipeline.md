---
title: GitLab CI Pipeline
---

## What We're Doing

You will configure a `.gitlab-ci.yml` pipeline that runs on every push to the main branch.
The pipeline has three stages: test, build-and-push, and update-config. The final stage
commits the new image tag to the config repository — this is what triggers FluxCD.

## Steps

### 1. Review the pipeline template

```terminal:execute
command: cat /home/eduk8s/exercises/gitlab-ci/.gitlab-ci.yml.template
```

**Observe:** Three stages, three jobs. Note the use of CI/CD variables (`$CI_REGISTRY_IMAGE`,
`$CI_COMMIT_SHORT_SHA`) for the image tag — no hardcoded values.

### 2. Configure the pipeline in your GitLab project

In your GitLab project (`inventory-app`), go to Settings → CI/CD → Variables and add:
- `HARBOR_USER` — your Harbor username
- `HARBOR_PASSWORD` — your Harbor password
- `CONFIG_REPO_TOKEN` — a GitLab access token for the config repo

### 3. Push the pipeline file

```terminal:execute
command: cp /home/eduk8s/exercises/gitlab-ci/.gitlab-ci.yml /home/eduk8s/repos/inventory-app/ && cd /home/eduk8s/repos/inventory-app && git add .gitlab-ci.yml && git commit -m "ci: add pipeline" && git push
```

### 4. Watch the pipeline run

Open your GitLab project in the browser and navigate to CI/CD → Pipelines. Watch the stages
progress in real time.

**Observe:** The `update-config` stage uses `git push` to update `values.yaml` in the config
repo with the new image tag. This commit is the GitOps trigger.

## What Just Happened

GitLab Runner executed your pipeline in a container, built and pushed the image to Harbor, and
made a commit to the config repo. The entire deploy process is now version-controlled and
reproducible — no human needs to run `kubectl` to deploy this application.
