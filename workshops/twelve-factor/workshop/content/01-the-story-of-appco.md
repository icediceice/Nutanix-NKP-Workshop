---
title: The Story of AppCo
---

## What We're Doing

Before diving into factors, we need context. AppCo is a mid-size B2B SaaS company that sells
an inventory management platform. Their system started as a PHP monolith running on a single
server in a colo facility. Today, it serves 400 customers — and every deploy is a crisis.

## AppCo's Current Pain Points

- **Deploys happen at 2am** to avoid customer impact. They still break things.
- **"Works on my machine"** is the most common phrase in the engineering Slack channel.
- **Database migrations** are run manually by the lead developer before every release.
- **Config is baked into the code** — switching between staging and production requires editing
  source files and hoping no one commits the wrong credentials.
- **Logs** are written to files on the server. When the server dies, so do the logs.

## The Decision to Modernise

AppCo's CTO has decided to migrate to Kubernetes on Nutanix NKP. The engineering team has six
months to containerise the application, adopt CI/CD, and reach a state where deploys happen
multiple times per day without drama.

This workshop tracks their journey, one factor at a time.

## Discussion

Think about your own organisation:

- Which of AppCo's pain points sound familiar?
- Which factor do you think will be hardest to adopt?
- What does "a successful deploy" look like where you work today?

There are no wrong answers. The twelve factors are a direction, not a checklist.
