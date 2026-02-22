---
title: ConfigMaps
---

## What We're Doing

ConfigMaps store non-sensitive configuration data as key-value pairs or as files. Pods consume
ConfigMaps as environment variables or as mounted files. Externalising config from the image
is Factor III of the Twelve-Factor methodology and enables the same image to run in multiple
environments.

## Steps

### 1. Create a ConfigMap from literals

```terminal:execute
command: kubectl create configmap app-config --from-literal=APP_ENV=production --from-literal=LOG_LEVEL=info -n demo-app
```

### 2. Inspect the ConfigMap

```terminal:execute
command: kubectl get configmap app-config -o yaml -n demo-app
```

**Observe:** The data is stored as plain text. ConfigMaps are not encrypted — do not store
passwords here.

### 3. Create a ConfigMap from a file

```terminal:execute
command: kubectl create configmap nginx-conf --from-file=/home/eduk8s/exercises/configmaps/nginx.conf -n demo-app
```

### 4. Mount as environment variables

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/configmaps/pod-envfrom.yaml -n demo-app
```

```terminal:execute
command: kubectl exec configmap-demo -n demo-app -- env | grep -E 'APP_ENV|LOG_LEVEL'
```

### 5. Mount as a volume (file)

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/configmaps/pod-volume.yaml -n demo-app
```

```terminal:execute
command: kubectl exec configmap-vol -n demo-app -- cat /etc/nginx/conf.d/nginx.conf
```

**Observe:** The config file appears inside the container at the mount path. Updating the
ConfigMap causes the mounted file to be updated automatically (with a short delay).

## What Just Happened

ConfigMaps decouple configuration from container images. Environment variable injection is
simpler but requires a Pod restart to pick up changes. Volume mounts update live and are better
for config files that an application watches for changes.
