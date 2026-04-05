---
title: Workshop Overview
---

## What is Kubernetes?

Kubernetes is a platform that decides **where** your containers run, keeps them running, and
connects them to the network — automatically.

```mermaid
graph TB
    You["💻 You<br/>(kubectl)"] -->|API calls| API["⚙️ API Server<br/>Control Plane"]
    API --> ETCD["🗄️ etcd<br/>cluster state"]
    API --> SCH["📋 Scheduler<br/>picks a node"]
    API --> CM["🔄 Controller Manager<br/>keeps desired state"]
    SCH --> N1["🖥️ Worker Node 1<br/>Pod · Pod · Pod"]
    SCH --> N2["🖥️ Worker Node 2<br/>Pod · Pod · Pod"]
    SCH --> N3["🖥️ Worker Node 3<br/>Pod · Pod · Pod"]

    style You fill:#6366f1,color:#fff
    style API fill:#0ea5e9,color:#fff
    style ETCD fill:#64748b,color:#fff
    style SCH fill:#0ea5e9,color:#fff
    style CM fill:#0ea5e9,color:#fff
    style N1 fill:#10b981,color:#fff
    style N2 fill:#10b981,color:#fff
    style N3 fill:#10b981,color:#fff
```

**You** describe what you want. **Kubernetes** figures out how to make it happen.

---

## What is a Container?

Before Kubernetes, running an app on a new server was painful. You had to install the right
version of Node, Python, or Java, configure libraries, set environment variables, and hope the
server matched your laptop. It rarely did.

```mermaid
graph LR
    subgraph Old["❌ Old Way — \"Works on my machine\""]
        L1["💻 Dev laptop<br/>Node 18 · libssl 1.1"]
        S1["🖥️ Staging server<br/>Node 16 · libssl 3.0"]
        P1["🖥️ Prod server<br/>Node 14 · libssl 1.0"]
    end
    subgraph New["✅ Container Way — Same everywhere"]
        IMG["📦 Container Image<br/>App + Node 18 + libssl 1.1<br/>+ every dependency"]
        L2["💻 Dev laptop"]
        S2["🖥️ Staging server"]
        P2["🖥️ Prod server"]
        IMG --> L2
        IMG --> S2
        IMG --> P2
    end

    style IMG fill:#6366f1,color:#fff
    style L2 fill:#10b981,color:#fff
    style S2 fill:#10b981,color:#fff
    style P2 fill:#10b981,color:#fff
```

A **container image** bundles your app and every dependency it needs into one sealed package.
Run that image anywhere — laptop, cloud, edge — and you get identical behaviour.

Think of it like a **shipping container**: the same box works on a truck, a train, and a ship
because the interface is standardised. The contents never change in transit.

---

## What You Will Build

By the end of this workshop you will have deployed a real application and understand exactly what
Kubernetes did behind the scenes at each step.

| Exercise | You Will… | Concept |
|----------|-----------|---------|
| 01 | Connect to a live cluster | kubeconfig, context |
| 02 | Inspect nodes and the control plane | Nodes, roles, capacity |
| 03 | Run your first container | Pods, exec, logs |
| 04 | Keep it running automatically | Deployments, ReplicaSets |
| 05 | Expose it to the network | Services, ClusterIP |
| 06 | Organise resources | Namespaces, labels |

---

## How This Workshop Works

Each exercise follows the same three-step pattern:

> **▶ Run** — Execute a command in the terminal on the right
>
> **👁 Observe** — Read what Kubernetes tells you and why it matters
>
> **✅ Checkpoint** — Confirm your understanding before moving on

Commands in boxes like this are **clickable** — click them and they run automatically.

```terminal:execute
command: echo "Your cluster is ready. Let's go."
```
