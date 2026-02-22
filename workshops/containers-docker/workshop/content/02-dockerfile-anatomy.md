---
title: Dockerfile Anatomy
---

## What We're Doing

A Dockerfile is a recipe that tells Docker how to assemble an image layer by layer. Each
instruction becomes a layer. Understanding which instructions create layers and which do not
is key to building small, cacheable images.

## Open the Example Dockerfile

```terminal:execute
command: cat /home/eduk8s/exercises/dockerfile-anatomy/Dockerfile
```

**Observe:** Each instruction and what it does.

## Key Instructions

| Instruction | Purpose |
|------------|---------|
| `FROM` | Set the base image — every Dockerfile starts here |
| `WORKDIR` | Set the working directory for subsequent instructions |
| `COPY` | Copy files from build context into the image |
| `RUN` | Execute a shell command and commit the result as a layer |
| `ENV` | Set environment variables baked into the image |
| `EXPOSE` | Document which port the app listens on (does not publish it) |
| `CMD` | Default command to run when the container starts |
| `ENTRYPOINT` | Fixed command; CMD becomes arguments |

## Layer Caching

Docker caches each layer. If a layer's inputs have not changed, Docker reuses the cached result.
This is why you should:
1. Copy dependency manifests first (`package.json`, `go.mod`)
2. Run dependency install
3. Copy application source last

If you copy source first, any code change invalidates the dependency install cache.

## What Just Happened

You have read a Dockerfile and mapped each instruction to its purpose. In the next exercise you
will build this image and run a container from it.
