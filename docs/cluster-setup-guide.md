# Cluster Setup Guide

This guide covers the end-to-end process of preparing an NKP cluster to host the workshop
environment: from prerequisites through Educates installation to running your first workshop
session.

---

## Prerequisites

### Required Software (on the facilitator workstation)

| Tool | Minimum Version | Install |
|------|----------------|---------|
| kubectl | 1.28+ | https://kubernetes.io/docs/tasks/tools/ |
| nkp CLI | 2.12+ | Nutanix Support Portal |
| yq | 4.x | https://github.com/mikefarah/yq |
| helm | 3.13+ | https://helm.sh/docs/intro/install/ |
| educates CLI | 3.x | https://docs.educates.dev |
| docker or nerdctl | latest | https://docs.docker.com/engine/install/ |

### Required Access

- NKP cluster with admin kubeconfig
- Prism Central credentials (for nkp CLI cluster operations)
- Harbor admin credentials (for pushing workshop images)
- DNS A record pointing `*.workshop.example.com` to the cluster's load balancer IP

### Cluster Sizing

Recommended minimum cluster specification for 20 participants:

| Pool | Count | vCPU | RAM | Storage |
|------|-------|------|-----|---------|
| Control plane | 3 | 4 | 16 GB | 100 GB |
| Workers (platform) | 3 | 8 | 32 GB | 200 GB |
| Workers (participants) | 5 | 8 | 32 GB | 200 GB |

---

## Configuration Reference: `config.yaml`

The `cluster-init/config.yaml` file controls all workshop parameters.

```yaml
workshop:
  domain: workshop.example.com     # Base domain for all URLs
  cluster_name: nkp-workshop       # NKP cluster name in Kommander
  participant_count: 20            # Number of participant sessions to provision
  session_duration: 8h             # How long each session stays alive

harbor:
  url: harbor.workshop.example.com
  project: workshop
  admin_user: admin

educates:
  version: 3.0.0
  portal:
    title: "NKP Workshop Portal"
    logo_url: ""

registration_app:
  enabled: true
  database_path: /data/workshop.db
```

---

## Step-by-Step Initialisation

### Step 1: Clone the repository

```bash
git clone https://gitlab.example.com/nkp-workshop/workshop-platform.git
cd workshop-platform
```

### Step 2: Configure the environment

```bash
cp cluster-init/config.yaml.example cluster-init/config.yaml
# Edit config.yaml with your cluster-specific values
```

### Step 3: Run the preflight check

```bash
./cluster-init/prereqs/preflight-check.sh
```

The preflight check verifies:
- kubectl is connected to the correct cluster
- All required CLI tools are installed at the correct version
- Harbor is reachable and credentials are valid
- DNS is resolving correctly
- The cluster has sufficient node capacity

### Step 4: Install dependencies

```bash
./cluster-init/prereqs/install-dependencies.sh
```

This installs: cert-manager, external-dns (if not present), and the Educates operator.

### Step 5: Install Educates

```bash
./cluster-init/educates/install-educates.sh
```

### Step 6: Run init.sh

```bash
./cluster-init/init.sh
```

`init.sh` provisions all TrainingPortal objects and waits for participant sessions to be ready.

### Step 7: Verify

```bash
kubectl get trainingportals
kubectl get workshopsessions
```

All sessions should show `Running` status within 10 minutes.

---

## NKP-Specific Cluster Preparation

This section applies when running on an NKP (Nutanix Kubernetes Platform)
workload cluster managed by Kommander. The bootstrap script handles all of
this automatically, but understanding the why helps when troubleshooting.

### Traefik ingress routing rules

NKP uses Kommander-Traefik (`kommander-traefik` ingress class) as the cluster
ingress controller. Two behaviours matter for workshop routing:

1. **ExternalName services are blocked.** The ingress provider does not have
   `allowExternalNameServices` enabled. Any Ingress whose backend points to an
   ExternalName Service is silently dropped (Traefik logs the error but never
   routes the path). **Rule:** put each Ingress in the same namespace as its
   target Service.

2. **IngressRoute CRDs are watched cluster-wide** (`--providers.kubernetescrd`
   with no namespace restriction), but cross-namespace service references
   require `allowCrossNamespace` which is not enabled. Use standard Ingress
   objects (not IngressRoute) for simplicity.

### Kyverno admission policies

NKP installs Kyverno with `educates-environment-*` policies that enforce:

- **No LoadBalancer services** in Educates session namespaces.
  Use `ClusterIP` + Traefik ingress instead.
- **Security contexts**: `runAsNonRoot: true`, `allowPrivilegeEscalation: false`,
  `capabilities.drop: [ALL]` on containers in session namespaces.

If ArgoCD shows an Application stuck OutOfSync with a Kyverno admission error,
check the events in the session namespace:
```bash
kubectl -n <session-ns> get events | grep -i denied
```

### Observability stack

Kiali and Jaeger are **not** installed by default on the NKP workload cluster.
They are installed automatically by `bootstrap-educates.sh` via ArgoCD
Applications defined in `workshops/nkp-workshop/resources/observability/`.

| Tool | ArgoCD Application | Helm repo |
|------|--------------------|-----------|
| Kiali | `kiali.yaml` | `https://kiali.org/helm-charts` |
| Jaeger | `jaeger.yaml` | `https://jaegertracing.github.io/helm-charts` |

Both are deployed into `istio-system` in all-in-one mode.
Ingresses for both live in `istio-system` to satisfy the ExternalName rule above.

### ArgoCD subpath configuration

ArgoCD is pre-installed on the workload cluster. To serve it at `/dkp/argocd`
via Traefik, the bootstrap script patches `argocd-cmd-params-cm`:

```bash
kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge \
  -p '{"data":{"server.basehref":"/dkp/argocd","server.rootpath":"/dkp/argocd","server.insecure":"true"}}'
kubectl -n argocd rollout restart deployment/argocd-server
```

`server.insecure: "true"` is required because Traefik terminates TLS and
forwards plain HTTP to ArgoCD. Without it, ArgoCD redirects to HTTPS and
the browser gets an infinite redirect loop.

### Cilium network policy for Educates

Cilium on NKP blocks ClusterIP + kube-dns egress from session pods by default.
The `environment.objects` in `workshop.yaml` installs a `CiliumNetworkPolicy`
that explicitly allows:
- Egress to `kube-apiserver` and `world`
- Egress to `kube-dns` on UDP/TCP 53
- Egress to pods in `kube-system`, `nkp-workshop-ui`, and `kommander-default-workspace` (Traefik)

Without this, session terminals cannot reach the API server or resolve DNS.

---

## Teardown

At the end of the workshop, run:

```bash
./cluster-init/teardown.sh
```

This deletes all TrainingPortal objects, participant sessions, and PVCs created by the workshop.
It does NOT delete the NKP cluster itself.
