---
title: "Containers — The Tiny VM"
---

## The Idea You Already Know

You have been running VMs for years. A VM gives you an isolated, portable environment:
install your app, snapshot it, ship it to another host, run it. Containers do exactly the same
thing — but instead of packaging a full operating system, they package only what the application
needs.

Think of it this way:

> **A VM is a house. A container is a shipping container.**
> The house includes plumbing, wiring, and foundation — a full OS kernel.
> The shipping container holds only the cargo — your app and its libraries.
> You can stack hundreds of shipping containers on one ship.

---

## Side by Side

| | Virtual Machine | Container |
|-|----------------|-----------|
| What it includes | Full guest OS kernel + your app | Your app + libraries only (shared host kernel) |
| Startup time | 30–60 seconds | Under 1 second |
| Size | Gigabytes | Megabytes |
| Density per host | ~10s | ~100s |
| Isolation | Kernel-level (hypervisor) | Process-level (Linux namespaces) |
| Portability | Image tied to hypervisor format | Runs anywhere with a container runtime |

Containers are not replacing VMs. NKP itself runs on VMs (or bare metal). Containers run
**inside** the operating system that the VM provides. The stack is:

```
Physical / Cloud Hardware
  └── Hypervisor (AHV / VMware / cloud)
        └── VM (Linux OS)
              └── Container runtime (containerd)
                    └── Your containers
```

---

## What Makes a Container Work

Three Linux kernel features combine to create the isolated environment:

- **Namespaces** — each container sees its own process list, network interfaces, and filesystem.
  It cannot see or interfere with processes in other containers.
- **cgroups** — the kernel enforces hard limits on how much CPU and memory a container can consume.
  A runaway process cannot starve the host or its neighbours.
- **Union filesystems** — the container image is a stack of read-only layers. At runtime, a thin
  writable layer is added on top. Two containers sharing the same base image share those layers
  on disk — no duplication.

---

## Image vs Container

An **image** is a frozen, layered snapshot — like a VM template. A **container** is a running
instance of that image — like a powered-on VM cloned from that template.

One image → many containers. Each container gets its own writable layer. Stop the container and
the writable layer is discarded. The image is unchanged.

---

## Why This Matters for Partners

Your customers are already running hundreds of VMs. The shift to containers is not a replacement
of that investment — it is an addition. The same Nutanix infrastructure that runs their VMs today
runs NKP and their containers tomorrow.

The payload shrinks from gigabytes to megabytes. Deployment time drops from minutes to seconds.
And the platform — NKP — manages the scheduling, health, scaling, and networking of every
container automatically.

This is the direction the industry is moving. NKP is how partners bring their customers there
on Nutanix infrastructure.
