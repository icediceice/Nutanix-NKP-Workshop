---
title: What Is a Container?
---

## What We're Doing

Before writing a single line of Dockerfile, it helps to understand what a container actually is
at the operating system level. The answer shapes every decision you will make about image design,
security, and performance.

## Containers vs Virtual Machines

A virtual machine includes a full guest OS kernel. A container shares the host kernel and uses
Linux namespaces and cgroups to isolate processes.

| | Virtual Machine | Container |
|-|----------------|-----------|
| Startup time | 30-60 seconds | < 1 second |
| Size | Gigabytes | Megabytes |
| Isolation | Kernel-level | Process-level |
| Density | ~10s per host | ~100s per host |

## What Makes a Container

Three Linux primitives combine to create the container experience:

- **Namespaces** — isolate the process from seeing other processes, network interfaces, and filesystems
- **cgroups** — limit how much CPU and memory the process can consume
- **Union filesystems** — layer read-only image layers with a thin read-write layer on top

## The Image vs Container Distinction

An **image** is an immutable, layered filesystem snapshot — like a class definition. A
**container** is a running instance of that image — like an object. One image can run as many
containers simultaneously, each with its own writable layer.

```terminal:execute
command: docker images
```

**Observe:** Each image has an IMAGE ID, a TAG, and a SIZE. The size is the compressed disk footprint.

## What Just Happened

You have seen the images already pulled into your session environment. In the next exercise you
will look inside a Dockerfile to understand how these layers are constructed.
