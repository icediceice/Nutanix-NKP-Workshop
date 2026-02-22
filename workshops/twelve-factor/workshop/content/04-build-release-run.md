---
title: "Factor V: Build, Release, Run"
---

## What We're Doing

AppCo's current deploy process is: SSH into the server, `git pull`, restart Apache. The build,
release, and run phases are collapsed into a single manual step. One typo can take down
production. Factor V enforces strict separation of these three stages.

## The Three Stages

**Build:** Transform source code into an executable artifact. For AppCo this is a Docker image.
The build stage pulls dependencies, compiles assets, and produces an immutable image tagged with
the Git SHA.

**Release:** Combine the build artifact with the environment-specific config. The result is a
release — every release has a unique ID and can be rolled back to instantly.

**Run:** Execute the release in the target environment. The run stage should be as simple as
possible — ideally just starting a process.

## AppCo's Pipeline

```
git push → GitLab CI builds image → tags :v1.4.2 → pushes to Harbor
                                                       ↓
                                          FluxCD detects new image tag
                                                       ↓
                                          Updates Deployment in Kubernetes
                                                       ↓
                                          Kubernetes does rolling update (Run)
```

**Observe the separation:** A developer cannot bypass the build stage to deploy hand-edited files.
The image is immutable. The release (image + config) is versioned. The run stage is automated.

## What Just Happened

Separating build, release, and run means that every deployment is reproducible, auditable, and
rollback-able. AppCo's 2am deploys become automated pipeline runs. The on-call engineer goes
back to sleeping.
