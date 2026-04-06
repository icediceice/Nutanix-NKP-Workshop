---
title: "Workspaces and Multi-Tenancy"
---

## The Problem

A large enterprise runs dozens of teams needing different access to different clusters. Without a management layer, an operator must configure RBAC on every cluster individually. Add a team member -- update N clusters. Add a cluster -- re-apply all policies. **This does not scale.**

---

## How Kommander Solves It

```mermaid
graph TB
    IDP["Identity Provider<br/>(LDAP / OIDC / AD)"]
    IDP --> G1["Group: platform-team"]
    IDP --> G2["Group: app-developers"]

    G1 --> WRB1["WorkspaceRoleBinding<br/>Role: admin"]
    G2 --> WRB2["WorkspaceRoleBinding<br/>Role: edit"]

    subgraph WS["Workspace: production"]
        WRB1 --> C1["cluster-east<br/>admin access"]
        WRB1 --> C2["cluster-west<br/>admin access"]
        WRB2 --> C1
        WRB2 --> C2
    end

    style IDP fill:#4B00AA,color:#fff
    style WS fill:#1A1A1A,stroke:#7855FA,color:#F0F0F0
    style G1 fill:#111,stroke:#1FDDE9,color:#F0F0F0
    style G2 fill:#111,stroke:#3DD68C,color:#F0F0F0
```

**One binding, every cluster.** Assign a group to a workspace with a role, and every member gets the right permissions on every cluster in that workspace -- automatically. Add a new cluster to the workspace and it inherits all policies instantly.

---

## Exercise -- Explore Workspaces

```terminal:execute
command: kubectl get workspaces -A 2>/dev/null || echo "Workspaces are managed via the Kommander API -- let's check what exists:"
```

```terminal:execute
command: kubectl get namespaces | grep -E 'kommander|workspace'
```

**What happened?** Each workspace maps to a namespace in Kommander. The `kommander-default-workspace` is the built-in workspace where platform services run.

---

## Exercise -- See Role Bindings

```terminal:execute
command: kubectl get clusterrolebindings --no-headers | grep kommander | head -10
```

**What happened?** These are the RBAC bindings that Kommander created automatically. Each one maps a workspace role to a Kubernetes ClusterRoleBinding. When a new cluster joins the workspace, these bindings are replicated automatically.

---

## Why This Matters for Your Customers

```mermaid
graph LR
    subgraph Before["Without Kommander"]
        A1["New hire joins"] --> A2["Update cluster-1 RBAC"]
        A2 --> A3["Update cluster-2 RBAC"]
        A3 --> A4["Update cluster-N RBAC"]
        A4 --> A5["Hope nothing was missed"]
    end
    subgraph After["With Kommander"]
        B1["New hire joins"] --> B2["Add to IdP group"]
        B2 --> B3["Done. All clusters updated."]
    end
    style Before fill:#1A1A1A,stroke:#E05252,color:#F0F0F0
    style After fill:#1A1A1A,stroke:#3DD68C,color:#F0F0F0
```

One source of truth. Zero per-cluster configuration. The platform scales with the fleet.
