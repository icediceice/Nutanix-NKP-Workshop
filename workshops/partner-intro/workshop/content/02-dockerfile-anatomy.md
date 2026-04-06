---
title: "How Container Images Are Built"
---

## Inspect a Real Image

Before we talk about Dockerfiles, let's look at what is already running:

```terminal:execute
command: kubectl get pods -n educates -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort -u
```

**What happened?** Every pod has an `image` field -- the container image it was built from. These images were built from Dockerfiles and stored in a registry.

---

## The Recipe -- A Dockerfile

```mermaid
graph LR
    D["Dockerfile"] -->|docker build| I["Image"]
    I -->|docker push| R["Registry (Harbor/GHCR)"]
    R -->|kubectl apply| P["Running Pod"]
    style D fill:#1A1A1A,stroke:#1FDDE9,color:#F0F0F0
    style I fill:#1A1A1A,stroke:#7855FA,color:#F0F0F0
    style R fill:#1A1A1A,stroke:#F5A623,color:#F0F0F0
    style P fill:#1A1A1A,stroke:#3DD68C,color:#F0F0F0
```

A Dockerfile is a plain text recipe. Each instruction creates a **layer**:

```dockerfile
FROM python:3.11-slim          # Start from a base image
WORKDIR /app                   # Set working directory
COPY requirements.txt .        # Copy dependency list
RUN pip install -r requirements.txt  # Install dependencies (cached layer)
COPY . .                       # Copy application code
EXPOSE 8080                    # Document the port
CMD ["python", "app.py"]       # Default startup command
```

---

## Layer Caching -- Why Order Matters

```mermaid
graph TB
    subgraph Fast["Dependencies first = fast rebuilds"]
        F1["COPY requirements.txt"] --> F2["RUN pip install"]
        F2 --> F3["COPY . ."]
        F3 --> F4["CMD"]
        style F2 fill:#3DD68C,color:#000
    end
    subgraph Slow["Code first = slow rebuilds"]
        S1["COPY . ."] --> S2["RUN pip install"]
        S2 --> S3["CMD"]
        style S2 fill:#E05252,color:#fff
    end
    style Fast fill:#111,stroke:#3DD68C,color:#F0F0F0
    style Slow fill:#111,stroke:#E05252,color:#F0F0F0
```

Copy dependencies **before** code. When only code changes, the `pip install` layer is cached and the rebuild takes seconds instead of minutes.

---

## See Image Layers Live

```terminal:execute
command: kubectl run layer-demo --image=nginx:alpine --restart=Never 2>/dev/null; sleep 2 && kubectl get pod layer-demo -o jsonpath='Image: {.status.containerStatuses[0].image}{"\n"}ImageID: {.status.containerStatuses[0].imageID}{"\n"}'
```

```terminal:execute
command: kubectl run layer-demo2 --image=nginx:alpine --restart=Never 2>/dev/null; sleep 2 && kubectl get pods layer-demo layer-demo2 -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].imageID}{"\n"}{end}'
```

**What happened?** Both pods use `nginx:alpine` and share the **exact same imageID** -- a content-addressable hash. The node pulled the image once; both containers reuse those layers on disk. Run 100 containers of the same image and you pay almost zero extra storage.

```terminal:execute
command: kubectl delete pod layer-demo layer-demo2 --wait=false 2>/dev/null
```

> **Key takeaway**: Images are immutable. Once built, they never change. You deploy new versions by building a new image, not by modifying a running container.
