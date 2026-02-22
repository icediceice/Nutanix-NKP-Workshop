# Whiteboard Scripts

These scripts guide the facilitator through the whiteboard sessions. They are not meant to be
read verbatim — they are structured talking points with key diagrams to draw. Adapt the language
and examples to match the audience's domain.

---

## Script 1: The Twelve-Factor App — The AppCo Story (45 min)

### Opening (5 min)

Draw a simple box on the whiteboard:

```
┌────────────────┐
│  PHP Monolith  │
│  on one server │
└────────────────┘
```

"This is AppCo six months ago. One server. One codebase. One developer who knows where
everything is. It works — until it doesn't."

Ask the group: "Who has seen a system that looks like this?"

### The Pain Points (10 min)

Add arrows pointing to the box showing problems:

```
Config in code ──→ ┌────────────────┐ ←── "Works on my machine"
2am deploys ─────→ │  PHP Monolith  │ ←── Logs on disk
Manual migrations → │  on one server │ ←── One sticky session
                   └────────────────┘
```

Walk through each pain point. Ask: "What does a deploy look like at your organisation?"

### The Twelve-Factor Solution (20 min)

Erase the single server box. Draw a new diagram:

```
Git repo  →  CI Pipeline  →  Container Image  →  Kubernetes
                                  ↑
                           Config from env
                           (ConfigMap/Secret)
```

Walk through each factor, pointing to where it applies in the diagram:
- Factor I (Codebase): the Git repo box
- Factor II (Dependencies): the container image box
- Factor III (Config): the "Config from env" arrow
- Factor V (Build/Release/Run): the pipeline boxes
- Factor VI (Processes): "Stateless Pods" — can kill any one of them
- Factor XI (Logs): "Everything goes to stdout, platform collects it"

### Close (10 min)

Draw the "before and after" table from the workshop content. Ask:
"Which of these factors is your team furthest from today? Which could you adopt next week?"

---

## Script 2: Containers and the Container Image (30 min)

### The VM vs Container Comparison (10 min)

Draw two columns:

```
Virtual Machine              Container
─────────────               ─────────────
Guest OS kernel         →   Host kernel shared
30-60s startup          →   < 1s startup
GBs in size             →   MBs in size
Full isolation          →   Process isolation
```

"A container is not a lightweight VM — it's a process with a restricted view of the system."

### The Layer Diagram (10 min)

Draw the layer cake:

```
┌──────────────────────┐  ← Writable container layer (thin)
├──────────────────────┤
│  Your application    │  ← COPY instruction
├──────────────────────┤
│  Language runtime    │  ← RUN apt-get install
├──────────────────────┤
│  OS base image       │  ← FROM ubuntu:22.04
└──────────────────────┘
```

"Each Dockerfile instruction creates one of these layers. Layers are cached. If your code changes,
only the top layer is rebuilt — the OS and runtime layers are reused."

### The Multi-Stage Build (10 min)

Draw two columns showing single-stage vs multi-stage:

```
Single Stage         Multi-Stage
────────────         ───────────
Build tools    ┐     Build tools  → (discarded)
Runtime        │     Runtime      ┐
Application    │     Application  ┘ → Final image
               ↓
         Large image              Small image
          ~1.2 GB                  ~150 MB
```

"Multi-stage builds are the standard for compiled languages — Go, Java, .NET, Rust."

---

## Script 3: Kubernetes Architecture (45 min)

### The Control Plane / Data Plane Split (10 min)

Draw the cluster:

```
┌─────────── Management Plane ────────────┐
│  API Server  ─→  etcd (state store)    │
│  Controller Manager  Scheduler          │
└──────────────────────────────────────────┘
           ↓ Watch / Reconcile
┌────────────── Data Plane ───────────────┐
│  Node 1: kubelet + kube-proxy + Pods   │
│  Node 2: kubelet + kube-proxy + Pods   │
│  Node 3: kubelet + kube-proxy + Pods   │
└──────────────────────────────────────────┘
```

"Every component is a reconciliation loop. Desired state goes into etcd via the API server.
Controllers watch etcd and drive the cluster toward that state."

### The Object Hierarchy (15 min)

Draw the hierarchy:

```
Deployment
    └── ReplicaSet
            └── Pod
                  └── Container(s)
                        ├── ConfigMap (env vars or files)
                        ├── Secret (sensitive env vars)
                        └── PersistentVolume (storage)
```

"A Deployment owns a ReplicaSet. The ReplicaSet owns Pods. Deleting the Deployment cascades
down. Scaling the Deployment scales the Pods."

### The Networking Model (10 min)

Draw:

```
External Traffic
      ↓
  Ingress (L7 routing by hostname/path)
      ↓
  Service (stable ClusterIP, load balances)
      ↓
  Pod Endpoints (ephemeral IPs)
```

"Services are the stable addressing layer. Without a Service, you would need to track Pod IPs
which change every restart. With a Service, callers always use the same ClusterIP or DNS name."

### The Operations Loop (10 min)

Draw:

```
Deploy → Observe (logs/metrics) → Problem detected
                                       ↓
                               Describe / Events
                                       ↓
                    Fix: rollback, scale, patch, restart
                                       ↓
                               Re-observe
```

"This is your day-to-day operating loop. kubectl describe is your first stop. Logs are your
second. Metrics dashboards are your third."
