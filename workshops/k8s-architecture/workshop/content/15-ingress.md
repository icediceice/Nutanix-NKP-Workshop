---
title: Ingress
---

## What We're Doing

NodePort and LoadBalancer Services expose applications at the transport layer (L4). Ingress
operates at the application layer (L7) — it can route HTTP/HTTPS traffic by hostname or path,
terminate TLS, and consolidate many services behind a single external IP. NKP ships with the
NGINX Ingress Controller pre-installed.

## Steps

### 1. List the Ingress Controller

```terminal:execute
command: kubectl get pods -n ingress-nginx
```

**Observe:** The NGINX Ingress Controller runs as a Deployment. It watches Ingress objects
across all namespaces and dynamically reconfigures its nginx.conf.

### 2. Create an Ingress for the nginx Service

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/ingress/ingress-basic.yaml -n demo-app
```

```terminal:execute
command: kubectl get ingress -n demo-app
```

**Observe:** An external address is assigned (this may take 30-60 seconds). The ADDRESS column
shows the IP of the load balancer provisioned by NKP.

### 3. Test HTTP routing

```terminal:execute
command: curl -H "Host: demo-app.workshop.local" http://$(kubectl get ingress nginx-ingress -n demo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

### 4. Add TLS termination

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/ingress/ingress-tls.yaml -n demo-app
```

```terminal:execute
command: kubectl describe ingress nginx-ingress-tls -n demo-app | grep TLS
```

**Observe:** The Ingress references the TLS Secret you created earlier. NGINX handles decryption;
traffic inside the cluster is plain HTTP.

## What Just Happened

The Ingress Controller reconciled your Ingress object and updated its nginx configuration to proxy
requests for `demo-app.workshop.local` to the `nginx` Service. One external IP serves multiple
services on the same cluster via hostname-based routing.
