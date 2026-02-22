# Educates on NKP

This document explains what Educates is, why the NKP workshop uses it, and how to install and
verify it on an NKP cluster.

---

## What is Educates?

Educates (https://docs.educates.dev) is an open-source workshop platform for Kubernetes. It
provides:

- **Browser-based workshop environments** — participants get an in-browser terminal, code editor,
  and web browser without installing anything locally
- **Declarative workshop definitions** — workshops are defined as Kubernetes custom resources
  (`Workshop`, `TrainingPortal`) and live in Git
- **Isolated per-participant namespaces** — each participant gets their own Kubernetes namespace,
  with resource quotas and RBAC pre-configured
- **Interactive terminal blocks** — Markdown `terminal:execute` blocks run commands in the
  participant's terminal on click
- **Session lifecycle management** — idle timeout, automatic cleanup, session resumption

---

## Why Educates on NKP?

The NKP workshop platform runs Educates on the same NKP cluster participants learn on. This
provides a unique advantage: participants do not need a separate cluster — their workshop
environment IS the cluster they are learning about. They can run `kubectl get nodes` and see
the actual workshop cluster nodes.

Educates integrates with NKP's:
- **Traefik** — for HTTP routing to workshop sessions
- **cert-manager** — for automatic TLS certificates
- **RBAC** — participant namespaces use standard Kubernetes RBAC

---

## Installation

### Prerequisites

- cert-manager installed (Educates depends on it)
- A wildcard DNS record `*.workshop.example.com` pointing to the cluster ingress IP
- Helm 3.13+

### Install Educates Operator

```bash
helm repo add educates https://charts.educates.dev
helm repo update

helm install educates-operator educates/educates-operator \
  --namespace educates \
  --create-namespace \
  --version 3.0.0 \
  --set clusterIngress.domain=workshop.example.com \
  --set clusterIngress.tlsCertificateRef.namespace=educates \
  --set clusterIngress.tlsCertificateRef.name=workshop-tls
```

### Verify the Operator

```bash
kubectl get pods -n educates
kubectl get crd | grep educates
```

Expected CRDs include: `workshops.training.educates.dev`, `trainingportals.training.educates.dev`,
`workshopsessions.training.educates.dev`.

---

## TrainingPortal Setup

A `TrainingPortal` object configures the portal URL, lists workshops, and sets session capacity.

```yaml
apiVersion: training.educates.dev/v1beta1
kind: TrainingPortal
metadata:
  name: nkp-workshop
spec:
  portal:
    title: "NKP Workshop Portal"
    sessions:
      maximum: 25
  workshops:
    - name: k8s-intro
      capacity: 25
    - name: k8s-architecture
      capacity: 25
    - name: twelve-factor-app
      capacity: 25
    - name: containers-docker
      capacity: 25
    - name: dev-app-development
      capacity: 15
    - name: dev-nkp-platform
      capacity: 15
    - name: infra-introduction
      capacity: 10
    - name: infra-nkp-platform
      capacity: 10
```

Apply it:

```bash
kubectl apply -f cluster-init/educates/training-portal.yaml
```

---

## Verifying Installation

```bash
kubectl get trainingportals
kubectl get workshopenvironments
```

Visit `https://portal.workshop.example.com` to see the Educates training portal. All listed
workshops should appear as available for participants to start.

---

## Session URL Pattern

Each participant session gets a unique URL:
```
https://<session-id>.workshop.example.com
```

The Educates portal handles session creation and URL distribution. Participants log in with
credentials from the registration app.
