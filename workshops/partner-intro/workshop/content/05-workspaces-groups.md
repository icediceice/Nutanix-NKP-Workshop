---
title: "Workspaces and Groups"
---

## The Multi-Tenancy Problem

A large enterprise runs dozens of teams — platform engineering, application teams, security,
and more — all needing different levels of access to different clusters.

Without a management layer, an operator must configure RBAC on every cluster individually.
Add a new team member → update N clusters. Add a new cluster → re-apply all policies.
This does not scale.

---

## How Kommander Solves It

Kommander introduces two objects:

- **Workspace** — a logical grouping of clusters, users, and policies. Think of it as a
  "project" or "environment boundary." One workspace per business unit or environment is common.

- **Group** — maps to a group in your identity provider (LDAP, OIDC, Active Directory).
  Assign a group to a workspace with a role, and every member of that IdP group gets the
  appropriate permissions on every cluster in the workspace — automatically.

```
Identity Provider (LDAP / SSO)
  └── Group: "platform-team"
        │
        └── WorkspaceRoleBinding
              ├── Workspace: "production"
              │     └── Role: admin  →  propagated to cluster-A, cluster-B
              └── Workspace: "staging"
                    └── Role: edit   →  propagated to cluster-C
```

---

## Exercise — Explore Workspaces

```terminal:execute
command: kubectl get workspaces -n kommander
```

**Observe:** Each workspace has a name and an age. Production environments typically have
workspaces per business unit (`infra`, `payments`, `data-platform`) or per environment
(`prod`, `staging`, `dev`).

```terminal:execute
command: kubectl describe workspace default -n kommander
```

**Observe:**
- `Clusters` — which clusters are members of this workspace
- `Groups` — which identity groups have access
- `Namespace` — the corresponding namespace on each member cluster

---

## Exercise — Explore Groups

```terminal:execute
command: kubectl get groups -n kommander
```

**Observe:** Groups correspond to your identity provider groups. A group with no workspace
binding has no permissions anywhere. Assign it to a workspace and all member clusters inherit
the access.

---

## The Key Insight

Kommander's federation controller watches `WorkspaceRoleBinding` objects on the management
cluster. When you create or update a binding, the controller propagates the corresponding
Kubernetes RBAC objects (`ClusterRoleBinding`, `RoleBinding`) to every cluster in the workspace.

**You configure access once, in one place. Every cluster stays in sync.**

Adding a new cluster to a workspace does not require a separate access setup — it inherits
the workspace's policies immediately.

---

## What Just Happened

You have seen the workspace and group model that underpins NKP's multi-tenancy. In the next
section you will see how roles and policies are assigned and how they propagate to managed clusters.
