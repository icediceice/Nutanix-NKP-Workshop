# NKP Hands-On Workshop

A full-stack, GitOps-driven hands-on workshop for Nutanix Kubernetes Platform (NKP). Participants deploy a microservices application, explore observability, perform progressive delivery, manage persistent storage, simulate production incidents, and apply governance policies — all on a live NKP cluster.

## Quick Start

### Prerequisites
See [docs/PREREQS.md](docs/PREREQS.md) for full cluster requirements.

### Bootstrap
```bash
./scripts/bootstrap-workshop.sh
```

### Switch Labs
```bash
./scripts/switch-lab.sh lab-01-start
./scripts/switch-lab.sh lab-03-canary-10
# etc.
```

### Print Access URLs
```bash
./scripts/print-access.sh
```

### Reset Between Sessions
```bash
./scripts/reset.sh
```

---

## Workshop Structure

| Directory | Contents |
|-----------|----------|
| `apps/storefront/base/` | Rx Storefront microservices (4 services) |
| `apps/stateful/base/` | PostgreSQL StatefulSet, VolumeSnapshot, RWX demo |
| `apps/storefront/overlays/` | One Kustomization per lab scenario (24 overlays) |
| `platform/` | Istio variants, Gatekeeper policy, RBAC, KEDA, storage |
| `loadgen/` | Load generator (off/baseline/peak profiles) |
| `demo-wall/` | Live dashboard showing cluster state |
| `scripts/` | switch-lab.sh, bootstrap, print-access, reset |
| `docs/lab-guides/` | Participant lab guides (6 labs) |
| `docs/` | Instructor guide, prereqs, troubleshooting, reset |
| `resources/` | Educates Workshop CRD + TrainingPortal CRD |
| `workshop/` | Educates participant content (9 modules) |

## Labs

| Lab | Title | Duration |
|-----|-------|----------|
| 1 | Application Deployment | 30–45 min |
| 2 | Observability | 45–60 min |
| 3 | GitOps & Progressive Delivery | 45–60 min |
| 4 | Storage & Stateful Workloads | 45–60 min |
| 5 | Production Operations | 45–60 min |
| 6 | Multi-Tenancy & Governance | 30–45 min |

## Workshop Tracks

| Track | Labs | Duration |
|-------|------|----------|
| Full Workshop | 1–6 | 6–8 hrs |
| Developer Fast Track | 1, 2, 3, 5 | 4 hrs |
| Executive Showcase | 1, 3, 6 | 2 hrs |
| SRE Operations Focus | 2, 4, 5 | 4 hrs |

## Educates Integration

This workshop is packaged for the [Educates Training Platform](https://docs.educates.dev/). Deploy with:

```bash
educates publish-workshop
kubectl apply -f resources/training-portal.yaml
```

See [docs/PREREQS.md](docs/PREREQS.md) for Educates setup requirements.
