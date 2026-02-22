---
title: "Factors I & II: Codebase and Dependencies"
---

## What We're Doing

The first two factors address the most fundamental question: where does your code live and how
do you ensure every environment runs exactly the same software? AppCo's current answer is
"a zip file on a shared drive" — we will do better.

## Factor I: Codebase — One codebase, tracked in version control, many deploys

AppCo currently has three copies of their codebase: one on the production server, one on staging,
and the "real" one on the lead developer's laptop. All three have drifted.

The rule is simple: one Git repository, one application. Multiple deploys (production, staging,
dev) all come from the same repo at different commits — never different repos.

**AppCo's fix:** Move everything into GitLab. Enforce branch protection. The server copy is
replaced by a CI/CD pipeline that deploys from Git.

## Factor II: Dependencies — Explicitly declare and isolate

AppCo relies on a system PHP extension (`soap`) that is installed globally on the server. New
developer laptops don't have it. Result: bugs that only appear in production.

The rule: declare every dependency in a manifest file (`composer.json`, `package.json`,
`requirements.txt`, `go.mod`) and use isolation so no implicit system package leaks in.

**AppCo's fix:** A `Dockerfile` that starts from `php:8.2-fpm`, installs `soap` explicitly, and
copies the application. Now every environment — laptop, CI, production — runs identical software.

```terminal:execute
command: cat /home/eduk8s/exercises/factor-ii/Dockerfile
```

**Observe:** Notice how every dependency is declared. There is no `apt-get install` happening at
runtime and no assumption about what the host has installed.

## What Just Happened

By combining version control (Factor I) with explicit dependency declaration (Factor II), AppCo
eliminated an entire category of environment-specific bugs. The container image is now the
immutable, auditable unit of deployment.
