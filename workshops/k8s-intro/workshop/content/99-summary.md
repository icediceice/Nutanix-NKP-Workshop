---
title: Summary
---

## What We Covered

Congratulations on completing the Kubernetes Introduction module. You have taken your first steps
into the world of container orchestration and built a foundation that every subsequent workshop
will build upon.

## Key Takeaways

- **kubeconfig and contexts** — `kubectl` uses contexts to select the right cluster, user, and
  namespace. You can switch contexts with `kubectl config use-context <name>`.
- **Nodes** — Worker machines register with the control plane. Labels on nodes drive scheduling
  decisions.
- **Pods** — The atomic unit of Kubernetes. A Pod wraps one or more containers and gives them a
  shared IP and volume space.
- **The describe / events pattern** — When something goes wrong, `kubectl describe` and the
  `Events` section are your first debugging tool.

## Commands Cheat Sheet

| Command | What it does |
|---------|-------------|
| `kubectl config get-contexts` | List all kubeconfig contexts |
| `kubectl get nodes -o wide` | List nodes with IP and OS info |
| `kubectl run <name> --image=<img>` | Create a bare Pod |
| `kubectl describe pod <name>` | Detailed Pod info and events |
| `kubectl exec -it <pod> -- sh` | Open a shell in a running container |
| `kubectl delete pod <name>` | Remove a Pod |

## Next Steps

Head to the **Kubernetes Architecture** workshop to explore Deployments, Services, ConfigMaps,
and the full set of objects that make production applications resilient and scalable.
