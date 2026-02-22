---
title: Kubeconfig Management
---

## What We're Doing

When you provision a managed cluster with NKP, the kubeconfig for that cluster is stored as a
Secret in the management cluster. Distributing this kubeconfig to users — securely and at scale
— is a common operational task. NKP's Kommander provides a central portal where users can
download their kubeconfig based on their identity and group membership.

## Steps

### 1. List kubeconfig Secrets

```terminal:execute
command: kubectl get secrets -A | grep kubeconfig
```

**Observe:** Each managed cluster has a `<cluster-name>-kubeconfig` Secret. This is the admin
kubeconfig created by kubeadm during cluster provisioning.

### 2. Extract a kubeconfig

```terminal:execute
command: kubectl get secret workshop-cluster-kubeconfig -n workshop -o jsonpath='{.data.value}' | base64 -d > /tmp/workshop-cluster.kubeconfig
```

```terminal:execute
command: KUBECONFIG=/tmp/workshop-cluster.kubeconfig kubectl get nodes
```

**Observe:** You are now connected to the managed cluster via the extracted kubeconfig. This is
the kubeconfig an administrator would distribute to the development team.

### 3. Use the Kommander portal for user kubeconfigs

Users can generate their own kubeconfig (scoped to their permissions) from the Kommander UI.
It embeds their SSO token rather than the cluster admin credentials.

```terminal:execute
command: echo "Kommander portal: ${KOMMANDER_URL:-'Ask your facilitator for the URL'}"
```

**Observe:** The portal shows all clusters the user has access to. Each cluster has a
"Generate Kubeconfig" button that creates a time-limited, identity-aware kubeconfig.

## What Just Happened

Admin kubeconfigs are stored in Secrets and should be treated like root passwords. User
kubeconfigs from the Kommander portal are scoped to the user's RBAC permissions and expire
automatically. This separation is important for security and audit compliance.
