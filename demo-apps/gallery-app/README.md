# Gallery App

A minimal static image gallery application used as a demo workload throughout the NKP workshop
series. It is served by nginx and is intentionally simple — the focus is on the Kubernetes
objects that deploy and expose it, not on the application itself.

## What It Demonstrates

- Multi-stage Docker build (builder stage + nginx runtime stage)
- Non-root container execution
- Kubernetes Deployment with resource requests/limits
- ClusterIP Service
- Ingress with TLS termination
- ConfigMap for nginx configuration
- Health check endpoints via nginx stub_status

## Directory Structure

```
gallery-app/
├── Dockerfile          # Multi-stage build: build → nginx runtime
├── app/                # Static HTML/CSS/JS assets
├── k8s/
│   └── deployment.yaml # Deployment + Service manifest
└── README.md
```

## Build and Run Locally

```bash
docker build -t gallery-app:latest .
docker run -p 8080:8080 gallery-app:latest
open http://localhost:8080
```

## Deploy to Kubernetes

```bash
kubectl apply -f k8s/deployment.yaml -n demo-app
kubectl port-forward svc/gallery-app 8080:80 -n demo-app
```

## Customise

Place your own images or HTML files in the `app/` directory. The Dockerfile copies all contents
of `app/` into `/usr/share/nginx/html`. The nginx configuration serves them as static files.
