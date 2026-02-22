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

## Teardown

At the end of the workshop, run:

```bash
./cluster-init/teardown.sh
```

This deletes all TrainingPortal objects, participant sessions, and PVCs created by the workshop.
It does NOT delete the NKP cluster itself.
