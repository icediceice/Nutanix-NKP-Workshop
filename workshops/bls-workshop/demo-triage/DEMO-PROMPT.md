# Cold Claude Demo Prompt

Paste this into Claude Code in the terminal to run the live admin demo.

Claude will load KB context, find the broken pod, diagnose the image pull failure,
patch the deployment, expose the fixed app via NodePort, and print the access URL.

---

```
Search the NKP knowledge base (project: nkp) for context on this cluster before doing anything else.

Then use kubectl with KUBECONFIG=/Git/Nutanix-NKP-Workshop/auth/workload01.conf to:

1. List all pods in the demo-triage namespace — find anything not Running
2. Describe the failing pod and read the events to diagnose the exact root cause
3. Fix it with kubectl
4. Expose the fixed app with a NodePort Service so it's reachable from a browser
5. Print the final access URL: http://<node-ip>:<port>

Show your reasoning at each step. Be direct.
```

---

## Pre-demo checklist

- [ ] `kubectl get pods -n demo-triage` shows `broken-demo` in `ErrImagePull`
- [ ] Service pre-created: `http://10.38.49.118:30092` (returns connection refused until pod is fixed — goes live the moment Claude patches the image)
- [ ] Claude Code CLI open in terminal with repo at /Git/Nutanix-NKP-Workshop
- [ ] Audience can see the terminal (full screen, large font)

## Reset between sessions

```bash
cd /Git/Nutanix-NKP-Workshop
KUBECONFIG=auth/workload01.conf kubectl delete deployment broken-demo -n demo-triage
KUBECONFIG=auth/workload01.conf kubectl delete service broken-demo -n demo-triage --ignore-not-found
KUBECONFIG=auth/workload01.conf kubectl apply -f workshops/bls-workshop/demo-triage/k8s/broken-demo.yaml
```
