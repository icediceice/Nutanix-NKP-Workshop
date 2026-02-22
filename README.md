# Nutanix NKP Workshop Platform

A partner training workshop platform built on [Educates](https://educates.dev) — an open-source Kubernetes-native workshop engine.

## Components

| Component | Description |
|-----------|-------------|
| **Registration App** | Web app for participant registration, trainer admin, and credential distribution |
| **Educates Platform** | K8s-native workshop engine providing in-browser terminals, labs, and content rendering |
| **Cluster Init Scripts** | Bootstrap an NKP cluster for workshop use — one config file, one command |
| **Workshop Content** | 8 workshop modules across Developer and Infrastructure tracks |

## Workshop Tracks

### Developer Track — Cloud Native Developer
Foundation modules + App Development + NKP Developer Platform
Covers: GitOps, .NET containers, GitLab CI/CD, Harbor registry, FluxCD, Istio

### Infrastructure Track — Cloud Native Infrastructure
Foundation modules + Infra Introduction + NKP Infrastructure Platform
Covers: Cluster-API, NKP provisioning, workspaces, RBAC, storage classes, backup & DR

### Shared Foundation (all participants)
1. Introduction to Kubernetes
2. Twelve-Factor Application
3. Containers with Docker
4. Kubernetes Architectural Overview

## Quick Start

### Prerequisites

- A running NKP cluster with kubeconfig access
- `kubectl` configured and working
- `docker` and `docker-compose` (for local dev)

### Cluster Setup (Production)

```bash
cd cluster-init
cp config.yaml config.local.yaml      # Copy and edit with your settings
./init.sh                              # Bootstrap platform, Educates, and app
```

### Local Development

```bash
cd registration-app
cp ../.env.example .env               # Edit — DRY_RUN=true for local dev
docker-compose up
```

- Registration app: http://localhost:3000
- Admin panel: http://localhost:3000/admin
- API docs: http://localhost:8000/docs

## Repository Structure

```
Nutanix-NKP-Workshop/
├── registration-app/     # FastAPI backend + React frontend
├── cluster-init/         # Bootstrap scripts and config
├── workshops/            # Educates workshop content (8 modules)
├── demo-apps/            # Sample apps used in exercises
├── learning-platform/    # Quizzes, guides, facilitator materials
└── docs/                 # Setup and admin documentation
```

## Documentation

- [Cluster Setup Guide](docs/cluster-setup-guide.md)
- [Educates on NKP](docs/educates-on-nkp.md)
- [Registration App Admin Guide](docs/registration-app-admin-guide.md)
- [Workshop Authoring Guide](docs/workshop-authoring-guide.md)
- [Troubleshooting](docs/troubleshooting.md)

## License

Apache 2.0 — see [LICENSE](LICENSE)
