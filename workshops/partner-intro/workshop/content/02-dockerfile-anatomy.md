---
title: "How a Container Image Is Built"
---

## From Code to Image

A container image is built from a **Dockerfile** — a plain text recipe that describes every layer.
Each instruction adds a layer. The final stack of layers is the image.

Here is a minimal Dockerfile for a Python web service:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8080
CMD ["python", "app.py"]
```

---

## What Each Instruction Does

| Instruction | Purpose |
|------------|---------|
| `FROM` | Base image — every Dockerfile starts here. `python:3.11-slim` is a minimal Python image. |
| `WORKDIR` | Sets the working directory for all following instructions. |
| `COPY` | Copies files from the build machine into the image. |
| `RUN` | Executes a shell command and commits the result as a new layer. |
| `EXPOSE` | Documents which port the app listens on (does not publish it). |
| `CMD` | The default command when the container starts. |

---

## Layer Caching — Why Order Matters

The build engine caches each layer. If nothing changed in that layer's inputs, it reuses the
cache. This has a big practical consequence for build speed:

**Slow (cache always misses on code change):**
```dockerfile
COPY . .                        # ← any code change invalidates from here
RUN pip install -r requirements.txt
```

**Fast (dependencies cached separately from code):**
```dockerfile
COPY requirements.txt .         # ← only changes when deps change
RUN pip install -r requirements.txt   # ← cached most of the time
COPY . .                        # ← code changes here, only re-runs COPY
```

Put the things that change least at the top. Put application code near the bottom.

---

## The VM Analogy

Think of the Dockerfile as an **automation script for building a VM template**:
- `FROM` = start with a base OS snapshot
- `RUN` = install software, configure the OS
- `COPY` = drop your application files in
- `CMD` = set the startup command

The difference: the result is megabytes instead of gigabytes, builds in seconds instead of
minutes, and is byte-for-byte reproducible on any machine that runs the same build.

---

## What Happens at Runtime

When NKP schedules your container, it:
1. Pulls the image from a registry (Harbor, GHCR, Docker Hub)
2. Mounts the image layers read-only
3. Adds a thin writable layer on top
4. Starts the `CMD` process inside the isolated namespace

The image never changes. The writable layer is discarded when the container stops.
This is why containers are stateless by design — persistent data lives outside the container
in a volume (which NKP and Nutanix storage provide).
