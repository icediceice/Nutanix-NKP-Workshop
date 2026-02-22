---
title: Summary
---

## What We Covered

You managed NKP clusters at scale using the full infrastructure operations toolkit: workspaces
for multi-tenancy, access policies for RBAC federation, kubeconfig distribution, storage class
configuration, and backup/DR with Velero.

## Infrastructure Operations Cheat Sheet

| Operation | Command / Tool |
|-----------|---------------|
| Scale workers | `kubectl scale machinedeployment` |
| Upgrade Kubernetes | `nkp update cluster` |
| Create workspace | Kommander UI or `kubectl apply` |
| Assign group to workspace | `kubectl apply WorkspaceRoleBinding` |
| Extract admin kubeconfig | `kubectl get secret <cluster>-kubeconfig` |
| User kubeconfig | Kommander portal download |
| Create backup | `velero backup create` |
| Restore backup | `velero restore create --from-backup` |

## Production Recommendations

- Enable automatic daily backups with Velero schedule objects
- Store kubeconfig secrets with restricted RBAC — not everyone needs cluster admin
- Create a StorageClass per tier (SSD for databases, HDD for archives)
- Use workspace-level access policies — never configure RBAC on each cluster manually
- Test your backup restores quarterly — an untested backup is not a backup

## This Completes the Infrastructure Track

You have covered the full NKP infrastructure journey: understanding the Nutanix stack, using
CAPI to provision clusters, and managing them at scale with Kommander. Return to the closing
session for the architecture review, Q&A, and next steps discussion.
