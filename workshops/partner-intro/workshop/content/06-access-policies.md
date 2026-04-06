---
title: "Access Policies"
---

## Roles in NKP

NKP ships with three pre-defined workspace roles:

| Role | What it allows |
|------|---------------|
| `admin` | Full management of all resources in the workspace |
| `edit` | Create and modify workloads, services, configmaps |
| `view` | Read-only access — list and describe, no mutations |

You can also create custom roles for more granular control (for example, a role that allows
scaling deployments but not editing them).

---

## How Policies Work

An access policy is a `WorkspaceRoleBinding` — it binds a Group to a Role within a Workspace.
Once created, Kommander's federation controller creates the equivalent `ClusterRoleBinding` on
every cluster in the workspace.

---

## Exercise — List the Roles

```terminal:execute
command: kubectl get clusterroles -n kommander | grep -E 'kommander|workspace'
```

**Observe:** NKP pre-creates roles like `kommander-workspace-admin`, `kommander-workspace-edit`,
and `kommander-workspace-view`. These are the workspace-level roles that map to Kubernetes RBAC
on managed clusters.

---

## Exercise — See Active Policies

```terminal:execute
command: kubectl get workspacerolebindings -n kommander
```

**Observe:** Each binding maps a Group to a Role in a Workspace. This is the single source of
truth for who can access which clusters.

---

## Exercise — Verify Propagation

Access policies propagate automatically to managed clusters. Let's verify one:

```terminal:execute
command: kubectl get roles -n demo-app -o wide
```

**Observe:** Two roles are visible — `dev-role-demo-app` (read-only) and `ops-role-demo-app`
(read-write). These were propagated from a workspace policy on the management cluster. The
development team can observe their workloads but cannot change replicas or edit Deployments.

```terminal:execute
command: kubectl get rolebindings -n demo-app -o wide
```

**Observe:** Each binding shows which group or service account has which role in this namespace.
This was created automatically by Kommander's federation engine — not by manually running
`kubectl create rolebinding` on each cluster.

---

## The Security Model in Practice

A typical enterprise setup looks like this:

| Team | Group | Workspace | Role |
|------|-------|-----------|------|
| Platform Ops | `platform-team` | all workspaces | `admin` |
| App developers | `app-dev-team` | `production` | `view` |
| App developers | `app-dev-team` | `staging` | `edit` |
| Security | `security-team` | all workspaces | `view` |

Configure this once in Kommander. Every cluster — present and future — respects it.

---

## What Just Happened

You have seen how Kommander translates a workspace policy into Kubernetes RBAC across every
cluster in the workspace. In the next section your facilitator will walk through the NKP console
to show these same policies — and the broader platform — through the web UI.
