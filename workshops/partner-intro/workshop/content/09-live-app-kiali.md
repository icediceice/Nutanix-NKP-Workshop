---
title: "See Your Traffic -- Kiali Service Graph"
---

## Your Live Service Graph

Kiali is the service mesh observability UI. It shows **your** service-to-service traffic as a live graph -- no log parsing, no guessing.

---

## Exercise -- Open Your Kiali Dashboard

Click below to open Kiali filtered to your namespace:

```terminal:execute
command: echo "Open this URL in a new browser tab:" && echo "https://kiali.10.38.217.22.nip.io/kiali/?namespaces=$SESSION_NAMESPACE"
```

> **Note**: If your browser shows a certificate warning, click **Advanced** → **Proceed**. This is the same self-signed certificate used for the workshop.

---

## What You Should See

```mermaid
graph LR
    TG["traffic-generator"] --> FE["frontend<br/>200 OK"]
    FE --> CAT["catalog-api<br/>200 OK"]
    FE --> CO["checkout-api<br/>200 OK"]
    CO --> PAY["payment-mock<br/>200 OK"]

    linkStyle 0 stroke:#3DD68C
    linkStyle 1 stroke:#3DD68C
    linkStyle 2 stroke:#3DD68C
    linkStyle 3 stroke:#3DD68C

    style TG fill:#111,stroke:#888,color:#F0F0F0
    style FE fill:#111,stroke:#3DD68C,color:#F0F0F0
    style CAT fill:#111,stroke:#3DD68C,color:#F0F0F0
    style CO fill:#111,stroke:#3DD68C,color:#F0F0F0
    style PAY fill:#111,stroke:#3DD68C,color:#F0F0F0
```

**Green edges** = healthy traffic. Every arrow shows request rate, success rate, and latency. You see the entire application topology at a glance.

---

## Exercise -- Verify Traffic Flow

Back in your terminal, confirm the services are communicating:

```terminal:execute
command: kubectl exec -n $SESSION_NAMESPACE deploy/frontend-v1 -c app -- wget -q -O- http://catalog-api/api/products 2>/dev/null | head -c 200
```

**What happened?** The frontend pod called the catalog-api service by DNS name. Kubernetes service discovery handled the routing. The Istio proxy intercepted the call, added mTLS encryption, and recorded metrics -- all invisible to the application.

---

## The Observability Stack

```mermaid
graph TB
    APP["Your Pods"] -->|metrics| PROM["Prometheus<br/>Time-series metrics"]
    APP -->|traces| JAEGER["Jaeger<br/>Distributed tracing"]
    APP -->|topology| KIALI["Kiali<br/>Service graph"]
    PROM --> GRAFANA["Grafana<br/>Dashboards"]

    style APP fill:#1A1A1A,stroke:#7855FA,color:#F0F0F0
    style PROM fill:#111,stroke:#F5A623,color:#F0F0F0
    style JAEGER fill:#111,stroke:#1FDDE9,color:#F0F0F0
    style KIALI fill:#111,stroke:#3DD68C,color:#F0F0F0
    style GRAFANA fill:#111,stroke:#E05252,color:#F0F0F0
```

All of this is available on NKP. Deploy, enable, done.

> **For customers**: "When something breaks at 2 AM, your on-call engineer opens Kiali, sees the red edge, clicks it, and knows which service is failing -- in seconds, not hours."
