---
title: Multi-Stage Builds
---

## What We're Doing

The v1 image you built includes the full Go toolchain — several hundred megabytes of compiler
and build tools that serve no purpose at runtime. Multi-stage builds solve this by using separate
build and runtime stages. Only the final stage becomes the image you ship.

## Steps

### 1. Compare the Dockerfiles

```terminal:execute
command: diff /home/eduk8s/exercises/build-and-run/Dockerfile /home/eduk8s/exercises/multi-stage/Dockerfile
```

**Observe:** The multi-stage version has two `FROM` lines. The first stage (`builder`) compiles
the binary. The second stage copies only the binary into a minimal `scratch` or `alpine` base.

### 2. Build the multi-stage image

```terminal:execute
command: docker build -t workshop/hello-app:v2 /home/eduk8s/exercises/multi-stage/
```

### 3. Compare image sizes

```terminal:execute
command: docker images workshop/hello-app
```

**Observe:** v2 should be dramatically smaller than v1. The Go toolchain is gone. The attack
surface is reduced — fewer packages means fewer CVEs.

### 4. Verify the app still works

```terminal:execute
command: docker run -d -p 8080:8080 --name hello-v2 workshop/hello-app:v2 && curl http://localhost:8080
```

### 5. Clean up

```terminal:execute
command: docker rm -f hello-v2
```

## What Just Happened

Docker executed the `builder` stage, produced a binary, then started a fresh stage using only the
runtime base image and copied in the binary. Build-time dependencies (compiler, test frameworks,
linters) never appear in the final image. This is the standard pattern for Go, Java, .NET, and
any compiled language.
