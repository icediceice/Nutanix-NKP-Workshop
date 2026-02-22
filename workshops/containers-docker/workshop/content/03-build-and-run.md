---
title: Build and Run
---

## What We're Doing

Now you will build an image from a Dockerfile, inspect the layers, run a container from it, and
interact with the running process. This is the core loop of container development.

## Steps

### 1. Navigate to the exercise directory

```terminal:execute
command: cd /home/eduk8s/exercises/build-and-run
```

### 2. Build the image

```terminal:execute
command: docker build -t workshop/hello-app:v1 .
```

**Observe:** Each `Step N/M` corresponds to a Dockerfile instruction. Watch for the layer IDs —
some will say `CACHED` if this is not your first build.

### 3. Inspect the image layers

```terminal:execute
command: docker history workshop/hello-app:v1
```

**Observe:** The layers are listed newest-first. Note the size contribution of each layer.
Large `RUN` layers often indicate an opportunity to clean up temp files in the same instruction.

### 4. Run the container

```terminal:execute
command: docker run -d -p 8080:8080 --name hello workshop/hello-app:v1
```

### 5. Test the running container

```terminal:execute
command: curl http://localhost:8080
```

**Observe:** The application responds. The container is isolated but accessible on port 8080.

### 6. Clean up

```terminal:execute
command: docker rm -f hello
```

## What Just Happened

You executed the full build-run-test loop. The `docker build` command sent the build context to
the Docker daemon, which executed each instruction in a temporary container and committed the
result as a layer. The final image is the stack of all those layers.
