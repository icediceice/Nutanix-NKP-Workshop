---
title: Push to Harbor Registry
---

## What We're Doing

Building images locally is useful for development, but to run them on Kubernetes every node
needs to be able to pull the image. That requires a container registry. NKP includes Harbor —
an enterprise-grade, private registry with role-based access control and vulnerability scanning.

## Steps

### 1. Log in to Harbor

Your facilitator will provide the Harbor URL. Replace `HARBOR_URL` below.

```terminal:execute
command: docker login ${HARBOR_URL} -u workshop -p ${HARBOR_PASSWORD}
```

**Observe:** `Login Succeeded` confirms your credentials are accepted and stored in
`~/.docker/config.json`.

### 2. Tag your image for the registry

Docker image names encode the registry, project, repository, and tag.

```terminal:execute
command: docker tag workshop/hello-app:v2 ${HARBOR_URL}/workshop/hello-app:v2
```

### 3. Push the image

```terminal:execute
command: docker push ${HARBOR_URL}/workshop/hello-app:v2
```

**Observe:** Each layer is pushed independently. Layers already present in the registry are
skipped — this is the same caching mechanism as local builds.

### 4. Verify in the Harbor UI

Open the Harbor URL in your browser, navigate to the `workshop` project, and confirm your image
appears with its digest and size.

### 5. Pull the image on a Kubernetes Pod

```terminal:execute
command: kubectl run hello-from-harbor --image=${HARBOR_URL}/workshop/hello-app:v2 --restart=Never
```

```terminal:execute
command: kubectl get pod hello-from-harbor
```

## What Just Happened

Your image is now stored in Harbor with a content-addressable digest. Any Kubernetes node with
network access to Harbor can pull it. Harbor's built-in Trivy scanner will automatically scan
the image for known CVEs and report them in the UI.
