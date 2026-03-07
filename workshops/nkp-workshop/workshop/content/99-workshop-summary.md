# Workshop Summary

Congratulations — you've completed the NKP Hands-On Workshop!

## What You Accomplished

| Lab | What You Did |
|-----|-------------|
| **Lab 1** | Deployed a 4-service storefront via GitOps (ArgoCD + Kustomize) |
| **Lab 2** | Explored live mesh topology, traced requests through Jaeger, correlated logs by trace ID |
| **Lab 3** | Performed a canary rollout with traffic mirroring, 10/50/100% splits, and instant rollback |
| **Lab 4** | Ran PostgreSQL with Nutanix CSI block storage, took a VolumeSnapshot, restored it |
| **Lab 5** | Diagnosed latency/error incidents, drained a node with PDBs, autoscaled with KEDA |
| **Lab 6** | Enforced namespace quotas, used Gatekeeper in audit then deny mode, verified RBAC |

## NKP Platform Capabilities You Used

- **ArgoCD** — GitOps continuous delivery, prune on sync, self-heal
- **Istio** — service mesh, traffic splitting, mirroring, mTLS
- **Kiali** — live mesh topology visualization
- **Jaeger** — distributed tracing with OpenTelemetry
- **Grafana** — time-series metrics and dashboards
- **Gatekeeper** — OPA-based admission control (audit → enforce)
- **KEDA** — event-driven autoscaling from zero
- **Nutanix CSI** — block (RWO) and file (RWX) dynamic provisioning
- **VolumeSnapshots** — point-in-time CSI snapshots
- **Kommander** — fleet management, workspace governance

## Key Principles to Take Home

1. **Git is the source of truth.** Every cluster state change is auditable, reversible, and versioned.
2. **Platform observability is free.** Istio sidecars emit metrics, traces, and topology without application changes.
3. **Progressive delivery limits blast radius.** Mirror first, canary second, cut over last.
4. **Resilience is declarative.** PDBs, anti-affinity, and multi-replica deployments are a few YAML lines.
5. **Storage is first-class.** Nutanix CSI makes persistent storage as easy as specifying a `storageClassName`.
6. **Governance scales through the platform.** One Gatekeeper policy applied to a workspace protects all clusters.

## Next Steps

- Explore the full NKP documentation at the NKP Console
- Try adding a second cluster to the Kommander workspace
- Experiment with building your own ArgoCD Application pointing at a custom repo
- Review the Instructor Guide for advanced demo scenarios

Thank you for participating in the NKP Hands-On Workshop!
