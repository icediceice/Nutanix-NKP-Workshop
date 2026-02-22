---
title: Secrets
---

## What We're Doing

Secrets store sensitive data such as passwords, TLS certificates, and API tokens. They work
similarly to ConfigMaps but have additional access controls and can be encrypted at rest by the
cluster. Understanding Secrets also means understanding their limitations — and why tools like
Vault or Sealed Secrets are used in high-security environments.

## Steps

### 1. Create a Secret

```terminal:execute
command: kubectl create secret generic db-credentials --from-literal=username=appco --from-literal=password=S3cr3tP@ss -n demo-app
```

### 2. Inspect the Secret

```terminal:execute
command: kubectl get secret db-credentials -o yaml -n demo-app
```

**Observe:** The values are base64-encoded, NOT encrypted. Anyone with `get secret` RBAC
permission can decode them: `echo "UzNjcjN0..." | base64 -d`.

### 3. Decode a value

```terminal:execute
command: kubectl get secret db-credentials -o jsonpath='{.data.password}' -n demo-app | base64 -d
```

### 4. Inject as environment variables

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/secrets/pod-secret-env.yaml -n demo-app
```

```terminal:execute
command: kubectl exec secret-demo -n demo-app -- env | grep DB_
```

### 5. Create a TLS Secret

```terminal:execute
command: kubectl create secret tls workshop-tls --cert=/home/eduk8s/exercises/secrets/tls.crt --key=/home/eduk8s/exercises/secrets/tls.key -n demo-app
```

## What Just Happened

Secrets keep sensitive data out of your Pod specs and ConfigMaps. In production, enable
Kubernetes Secret encryption at rest and restrict access via RBAC. For enterprise use cases,
NKP integrates with external secret management via the Secrets Store CSI driver.
