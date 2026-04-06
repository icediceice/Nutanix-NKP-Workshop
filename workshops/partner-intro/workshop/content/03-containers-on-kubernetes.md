---
title: "Containers on Kubernetes — Why NKP"
---

## The Problem Containers Create

Containers are lightweight and portable. But when you run hundreds of them across dozens of
hosts, new problems appear:

- Which host has capacity for this container?
- What happens when the host goes down?
- How do containers find and talk to each other?
- How do you roll out a new version without downtime?
- Who is allowed to run what?

None of these are answered by the container runtime itself. This is what **Kubernetes** solves.

---

## Kubernetes in One Paragraph

Kubernetes is an **orchestrator** — it takes a description of what you want running
("3 replicas of the checkout service, always") and makes it true. If a host fails,
Kubernetes reschedules the containers to another host. If a container crashes,
Kubernetes restarts it. You declare the end state; Kubernetes enforces it continuously.

The fundamental unit is a **Pod** — a wrapper around one or more containers that share a
network namespace and can share storage volumes.

```
Node (VM)
  └── Pod
        ├── Container: checkout-api (port 8080)
        └── Container: istio-proxy (sidecar, port 15001)
```

---

## What Kubernetes Gives You

| Capability | What it means |
|-----------|---------------|
| **Scheduling** | Finds the right node based on CPU/memory requests and affinity rules |
| **Self-healing** | Restarts failed containers, replaces failed nodes |
| **Service discovery** | Every service gets a DNS name; containers find each other automatically |
| **Rolling updates** | Deploy a new version gradually; auto-rollback on health check failure |
| **Storage** | Attach persistent volumes to pods; supports Nutanix storage classes |
| **Secrets/Config** | Inject credentials and config without baking them into the image |

---

## What NKP Adds on Top

Kubernetes answers the *single cluster* problem. NKP answers the *enterprise* problem:

| Challenge | NKP Answer |
|-----------|-----------|
| Managing 10, 50, 100 clusters | **Kommander** — single pane, unified policies |
| Who can access which cluster? | **Workspace RBAC** — policies propagate automatically |
| Deploying the observability stack | **App Catalog** — Istio, Kiali, Jaeger, Grafana in one click |
| Policy enforcement across all clusters | **OPA Gatekeeper** — federated, Git-backed constraints |
| Persistent storage for stateful apps | **Nutanix CSI** — native integration with AHV storage |
| Backup and disaster recovery | **Velero** — cross-cluster backup built in |

NKP is Kubernetes with the enterprise layer already assembled and supported by Nutanix.

---

## Exercise — See a Running Pod

Your session has a terminal connected to an NKP cluster. Let's look at real pods:

```terminal:execute
command: kubectl get pods -n demo-app
```

**Observe:** Each row is a Pod. The `READY` column shows how many containers in the pod are
running. The `STATUS` column shows the pod lifecycle phase.

```terminal:execute
command: kubectl describe pod -n demo-app -l app=frontend | head -40
```

**Observe:** `Node:` shows which VM the pod is running on. `Containers:` lists the containers
inside the pod. `Events:` shows the scheduling and startup history.

---

## What Just Happened

Kubernetes scheduled the `frontend` pod onto a node, pulled the container image, injected the
Istio sidecar, and started both containers. All of that happened automatically from a single
manifest file committed to Git.

In the next module, you will see how Kommander manages the cluster that just served those pods.
