---
title: "The Demo App -- Ecommerce on NKP"
---

## What We Are Running

A real microservices ecommerce application is running on this cluster right now. This is the kind of workload your customers would run on NKP.

```mermaid
graph LR
    Browser["Browser"] --> FE["frontend<br/>Flask + nginx"]
    FE --> CAT["catalog-api<br/>Product listings"]
    FE --> CO["checkout-api<br/>Cart + orders"]
    CO --> PAY["payment-mock<br/>Payment processor"]

    subgraph mesh["Istio Service Mesh"]
        FE
        CAT
        CO
        PAY
    end

    style Browser fill:#4B00AA,color:#fff
    style mesh fill:#1A1A1A,stroke:#1FDDE9,color:#F0F0F0
    style FE fill:#111,stroke:#7855FA,color:#F0F0F0
    style CAT fill:#111,stroke:#3DD68C,color:#F0F0F0
    style CO fill:#111,stroke:#F5A623,color:#F0F0F0
    style PAY fill:#111,stroke:#E05252,color:#F0F0F0
```

Every pod has an **Istio sidecar** -- a proxy that intercepts all traffic. Zero code changes required. The mesh provides mTLS encryption, traffic routing, and full observability automatically.

---

## Exercise -- See the Running Services

```terminal:execute
command: kubectl get pods -n demo-app 2>/dev/null || echo "Demo app namespace will be deployed by the facilitator"
```

```terminal:execute
command: kubectl get svc -n demo-app 2>/dev/null || echo "Services will appear when the demo app is deployed"
```

**What happened?** Each service has its own deployment and service object. Kubernetes handles service discovery -- `frontend` finds `catalog-api` by DNS name, not by IP address.

---

## The Four Services

| Service | Role | Why It Matters |
|---------|------|---------------|
| **frontend** | Browser-facing UI | Calls other services -- shows service-to-service communication |
| **catalog-api** | Product listings | Stateless microservice -- scales horizontally |
| **checkout-api** | Cart and orders | Calls payment-mock -- creates a dependency chain |
| **payment-mock** | Simulated payments | Has v1 and v2 -- used for canary deployment demo |

---

## What Istio Adds (Zero Code Changes)

```mermaid
graph TB
    subgraph Without["Without Service Mesh"]
        A1["App A"] -->|"plain HTTP"| A2["App B"]
        A3["No encryption"]
        A4["No traffic metrics"]
        A5["No routing control"]
    end
    subgraph With["With Istio on NKP"]
        B1["App A"] -->|"mTLS encrypted"| B2["App B"]
        B3["Automatic encryption"]
        B4["Full traffic metrics"]
        B5["Canary routing, retries, timeouts"]
    end
    style Without fill:#1A1A1A,stroke:#E05252,color:#F0F0F0
    style With fill:#1A1A1A,stroke:#3DD68C,color:#F0F0F0
```

> **The pitch to customers**: "Your developers write the same code. The mesh adds encryption, observability, and traffic control as infrastructure -- not application changes."
