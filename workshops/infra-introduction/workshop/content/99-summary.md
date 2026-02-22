---
title: Summary
---

## What We Covered

You mapped the Nutanix infrastructure stack from physical hardware through AHV and AOS to
Kubernetes nodes. You explored Cluster API concepts and saw how NKP uses CAPI to manage cluster
lifecycle declaratively.

## Key Takeaways

- **Nutanix AHV** provides the VM substrate — every Kubernetes node is an AHV VM
- **Nutanix CSI** bridges PersistentVolumeClaims to Nutanix Volumes storage
- **Cluster API** applies the Kubernetes reconciliation model to cluster lifecycle
- **CAPI objects** (`Cluster`, `MachineDeployment`, `NutanixCluster`) are the source of truth
  for cluster configuration — not scripts, not UI clicks
- **NKP CLI** generates CAPI manifests from flags — the output is standard Kubernetes YAML

## CAPI Object Hierarchy

```
Cluster
├── KubeadmControlPlane → Machines (control plane)
│   └── NutanixMachineTemplate
└── MachineDeployment → MachineSet → Machines (workers)
    └── NutanixMachineTemplate
```

## Next Steps

Proceed to the **NKP Platform for Infrastructure** workshop to learn how to manage clusters
at scale: workspaces, access policies, upgrades, scaling, and disaster recovery.
