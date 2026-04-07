---
title: "Why Kubernetes -- Why NKP"
---

## The Problem at Scale

You can run one container with `docker run`. But what happens with 200 containers across 20 hosts?

```mermaid
graph LR
    Q1["Which host has capacity?"] --> K["Kubernetes"]
    Q2["Host dies -- now what?"] --> K
    Q3["How do services find each other?"] --> K
    Q4["Zero-downtime upgrades?"] --> K
    Q5["Who can run what?"] --> K
    K --> A["Automated, declarative, self-healing"]
    style K fill:#7855FA,color:#fff
    style A fill:#3DD68C,color:#000
```

---

## See Kubernetes in Action

```terminal:execute
command: kubectl get nodes -o wide
```

**What happened?** These are the worker VMs in your cluster. Kubernetes is managing all of them as a single pool of compute.

```terminal:execute
command: kubectl get pods -A --no-headers | wc -l
```

**What happened?** That is the total number of containers running across all nodes right now. Kubernetes is scheduling, monitoring, and restarting every one of them automatically.

---

## The Pod -- Kubernetes Building Block

```mermaid
graph TB
    subgraph Node["Worker Node (VM)"]
        subgraph Pod1["Pod: checkout"]
            C1["checkout-api :8080"]
            C2["istio-proxy :15001"]
        end
        subgraph Pod2["Pod: frontend"]
            C3["frontend :3000"]
            C4["istio-proxy :15001"]
        end
    end
    style Node fill:#1A1A1A,stroke:#7855FA,color:#F0F0F0
    style Pod1 fill:#111,stroke:#1FDDE9,color:#F0F0F0
    style Pod2 fill:#111,stroke:#1FDDE9,color:#F0F0F0
```

A **Pod** wraps one or more containers that share networking. The app container and its sidecar (like Istio proxy) run together and communicate over `localhost`.

---

## Self-Healing -- Kill a Pod, Watch It Come Back

```terminal:execute
command: kubectl get pods -n kube-system -l k8s-app=kube-dns
```

Note the pod names. Now let's delete one:

```terminal:execute
command: kubectl delete pod -n kube-system -l k8s-app=kube-dns --wait=false | head -1
```

```terminal:execute
command: sleep 3 && kubectl get pods -n kube-system -l k8s-app=kube-dns
```

**What happened?** Kubernetes immediately created a replacement. The desired state says "2 DNS pods must run." You deleted one, Kubernetes restored it. This is **declarative self-healing** -- you describe the end state, Kubernetes enforces it continuously.

---

## What Kubernetes Gives You

| Capability | What It Means |
|-----------|---------------|
| **Scheduling** | Finds the right node based on CPU/memory requests |
| **Self-healing** | Restarts crashed containers, replaces failed nodes |
| **Service discovery** | Every service gets a DNS name automatically |
| **Rolling updates** | New versions deploy gradually with auto-rollback |
| **Storage** | Persistent volumes via Nutanix CSI |
| **Secrets** | Inject credentials without baking them into images |

> **But Kubernetes alone is not enough for enterprise.** That is where NKP comes in -- next page.
