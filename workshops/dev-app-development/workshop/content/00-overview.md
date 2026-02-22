---
title: Workshop Overview
---

## What We're Doing

In this developer-track workshop you will take a sample .NET application from source code to a
running deployment on NKP — fully automated. You will set up a GitLab CI pipeline, containerise
the app, push to Harbor, and let FluxCD deploy it to Kubernetes automatically when you push code.

## What You Will Learn

- How the GitOps model separates application code from deployment configuration
- How to containerise a .NET application with a multi-stage Dockerfile
- How to configure a GitLab CI/CD pipeline for a Kubernetes-native workflow
- How FluxCD watches a Git repository and reconciles the cluster state automatically
- How automated deployments eliminate manual `kubectl apply` steps

## Exercises

| # | Topic | Time |
|---|-------|------|
| 01 | GitOps model | 15 min |
| 02 | .NET app introduction | 10 min |
| 03 | Containerise the app | 20 min |
| 04 | GitLab CI pipeline | 25 min |
| 05 | Automated deployment | 20 min |

## Prerequisites

- Completion of the Containers and Docker workshop
- Completion of the Kubernetes Architecture workshop
- GitLab account pre-created for your session (credentials provided)
- Access to the workshop Harbor registry
