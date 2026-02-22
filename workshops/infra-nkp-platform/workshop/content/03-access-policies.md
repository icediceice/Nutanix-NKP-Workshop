---
title: Access Policies
---

## What We're Doing

NKP access policies bind identity groups to roles on workspaces or specific clusters. NKP ships
with predefined roles (admin, edit, view) and you can create custom roles. Policies set at the
workspace level propagate to all member clusters automatically via Kommander's federation engine.

## Steps

### 1. List available ClusterRoles in Kommander

```terminal:execute
command: kubectl get clusterroles -n kommander | grep -E 'kommander|workspace'
```

**Observe:** NKP pre-creates roles like `kommander-workspace-admin`, `kommander-workspace-edit`,
and `kommander-workspace-view`. These map to Kubernetes RBAC ClusterRoles on managed clusters.

### 2. Create an access policy

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/access-policies/policy.yaml -n kommander
```

```terminal:execute
command: kubectl get workspaceroleBindings -n kommander
```

**Observe:** The policy binds the `developers` group to the `edit` role in the default workspace.
Kommander will propagate this as a ClusterRoleBinding on every cluster in the workspace.

### 3. Verify propagation on a managed cluster

Switch context to the managed cluster and check:

```terminal:execute
command: kubectl --kubeconfig=/home/eduk8s/exercises/access-policies/workshop-kubeconfig.yaml get clusterrolebindings | grep developers
```

**Observe:** The ClusterRoleBinding exists on the managed cluster even though you only created
the policy on the management cluster. This is the federation in action.

## What Just Happened

Kommander's federation controller watches `WorkspaceRoleBinding` objects and creates the
corresponding Kubernetes RBAC objects on every cluster in the workspace. Revoking the binding
from the management cluster removes access from all clusters simultaneously.
