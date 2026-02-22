---
title: Workspaces and Groups
---

## What We're Doing

Kommander workspaces are the multi-tenancy boundary in NKP. A workspace is a collection of
clusters, users, and policies. Groups map to identity provider groups (LDAP, SSO) and are
assigned roles within a workspace. This replaces the need to configure RBAC on each cluster
individually.

## Steps

### 1. List existing workspaces

```terminal:execute
command: kubectl get workspaces -n kommander
```

**Observe:** The `default` workspace contains your workshop clusters. Production environments
typically have workspaces per business unit or environment (prod, staging, dev).

### 2. Inspect a workspace

```terminal:execute
command: kubectl describe workspace default -n kommander
```

**Observe:** The workspace shows which clusters are members, which groups have access, and
which platform applications are enabled for this workspace.

### 3. List groups

```terminal:execute
command: kubectl get groups -n kommander
```

**Observe:** Groups correspond to identity provider groups. Assigning a group to a workspace
with a role automatically creates the appropriate RBAC on every cluster in that workspace.

### 4. Create a group

```terminal:execute
command: kubectl apply -f /home/eduk8s/exercises/workspaces/group.yaml -n kommander
```

```terminal:execute
command: kubectl get groups -n kommander
```

**Observe:** The new group exists in the management cluster. Until it is bound to a workspace
role, it has no permissions on any cluster.

## What Just Happened

Kommander's federation mechanism watches workspace bindings and propagates the resulting RBAC
policies to all member clusters automatically. Adding a new cluster to a workspace immediately
grants all workspace group members their assigned roles on the new cluster.
