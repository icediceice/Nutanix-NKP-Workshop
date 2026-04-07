---
title: "Containers -- The Tiny VM"
---

## See It First

Let's start by running a container right now:

```terminal:execute
command: kubectl run hello --image=busybox:glibc --restart=Never -- echo "Hello from a container!"
```

```terminal:execute
command: kubectl logs hello
```

You just ran a process inside an isolated environment. No VM boot. No OS install. It took **under 2 seconds**.

Clean up:

```terminal:execute
command: kubectl delete pod hello --wait=false
```

---

## Containers vs VMs

```mermaid
graph TB
    subgraph VM["Virtual Machine"]
        direction TB
        A1[Guest OS Kernel] --> A2[Libraries]
        A2 --> A3[Your App]
        style A1 fill:#E05252,color:#fff
    end
    subgraph Container["Container"]
        direction TB
        B2[Libraries] --> B3[Your App]
        style B2 fill:#3DD68C,color:#000
    end
    subgraph Host["Host (shared kernel)"]
        direction TB
        C1[Linux Kernel + containerd]
    end
    VM -.-> Host
    Container -.-> Host
    style VM fill:#1A1A1A,stroke:#E05252,color:#F0F0F0
    style Container fill:#1A1A1A,stroke:#3DD68C,color:#F0F0F0
    style Host fill:#111,stroke:#7855FA,color:#F0F0F0
```

> **A VM is a house** (full foundation, plumbing, wiring).
> **A container is a shipping container** (just the cargo). Stack hundreds on one ship.

| | Virtual Machine | Container |
|-|----------------|-----------|
| Includes | Full guest OS kernel + app | App + libraries only |
| Startup | 30-60 seconds | Under 1 second |
| Size | Gigabytes | Megabytes |
| Density | ~10 per host | ~100s per host |
| Isolation | Hypervisor | Linux namespaces + cgroups |

---

## Prove It -- Check What is Running

```terminal:execute
command: kubectl get pods -n kube-system --no-headers | head -10
```

**What happened?** Every component of Kubernetes itself runs as a container. The control plane (API server, scheduler, controller-manager) and networking (Cilium) are all containers. Containers running containers.

---

## The Stack on Nutanix

```mermaid
graph TB
    HW["Nutanix Hardware (AHV)"] --> VM["Virtual Machine (Ubuntu)"]
    VM --> CR["Container Runtime (containerd)"]
    CR --> P1["Pod: your-app"]
    CR --> P2["Pod: monitoring"]
    CR --> P3["Pod: ingress"]
    style HW fill:#4B00AA,color:#fff
    style VM fill:#1A1A1A,stroke:#7855FA,color:#F0F0F0
    style CR fill:#111,stroke:#1FDDE9,color:#F0F0F0
    style P1 fill:#1A1A1A,stroke:#3DD68C,color:#F0F0F0
    style P2 fill:#1A1A1A,stroke:#3DD68C,color:#F0F0F0
    style P3 fill:#1A1A1A,stroke:#3DD68C,color:#F0F0F0
```

NKP runs **on** your existing Nutanix infrastructure. VMs host the Kubernetes nodes, containers run inside. No rip and replace -- additive.
