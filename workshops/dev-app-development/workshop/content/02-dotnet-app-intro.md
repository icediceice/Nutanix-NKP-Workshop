---
title: ".NET App Introduction"
---

## What We're Doing

The sample application is a minimal .NET 8 Web API that simulates AppCo's inventory service.
It exposes a REST endpoint that returns a list of products, reads its database connection string
from an environment variable, and writes structured JSON logs to stdout — a twelve-factor
compliant design.

## Explore the Application

```terminal:execute
command: ls /home/eduk8s/exercises/dotnet-app/
```

```terminal:execute
command: cat /home/eduk8s/exercises/dotnet-app/InventoryApi/Program.cs
```

**Observe:** The app is structured as a minimal API. Notice:
- `builder.Configuration["ConnectionStrings:Database"]` — reads from environment (Factor III)
- `builder.Logging.AddJsonConsole()` — structured JSON logs to stdout (Factor XI)
- Port binding via `app.Run("http://0.0.0.0:8080")` — self-contained (Factor VII)

## Health Endpoints

```terminal:execute
command: cat /home/eduk8s/exercises/dotnet-app/InventoryApi/HealthController.cs
```

**Observe:** `/health/live` and `/health/ready` endpoints are defined for Kubernetes probes.
`/health/live` always returns 200. `/health/ready` checks the database connection before returning
200 — the Pod will not receive traffic until the database is reachable.

## Project Structure

```
InventoryApi/
├── Program.cs          # App entry point and DI setup
├── Controllers/        # HTTP endpoints
├── Models/             # Data models
├── appsettings.json    # Default config (overridden by env vars)
├── Dockerfile          # (you will create this next)
└── InventoryApi.csproj # Project file with dependency declarations
```

## What Just Happened

You have reviewed the application structure. In the next exercise you will write the Dockerfile
that packages this .NET application into a container image.
