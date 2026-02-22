---
title: "Containerise the .NET App"
---

## What We're Doing

You will write a multi-stage Dockerfile for the .NET inventory API. The build stage uses the
.NET SDK image to restore packages and compile the application. The runtime stage uses the
smaller ASP.NET runtime image and copies only the published output.

## Steps

### 1. Open the Dockerfile template

```terminal:execute
command: cat /home/eduk8s/exercises/dotnet-app/Dockerfile.template
```

**Observe:** The template has placeholders where you need to fill in the correct commands.

### 2. Complete the Dockerfile

Use the editor to open `/home/eduk8s/exercises/dotnet-app/Dockerfile` and fill in the blanks
using these instructions as a guide:

**Stage 1 — Build:**
```
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY InventoryApi/InventoryApi.csproj InventoryApi/
RUN dotnet restore InventoryApi/InventoryApi.csproj
COPY . .
RUN dotnet publish InventoryApi/InventoryApi.csproj -c Release -o /app/publish
```

**Stage 2 — Runtime:**
```
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .
USER 1001
EXPOSE 8080
ENTRYPOINT ["dotnet", "InventoryApi.dll"]
```

### 3. Build the image

```terminal:execute
command: docker build -t workshop/inventory-api:v1 /home/eduk8s/exercises/dotnet-app/
```

### 4. Test locally

```terminal:execute
command: docker run -d -p 8080:8080 -e ConnectionStrings__Database="Host=localhost" --name inv workshop/inventory-api:v1
```

```terminal:execute
command: curl http://localhost:8080/health/live
```

```terminal:execute
command: docker rm -f inv
```

## What Just Happened

The SDK image (~900MB) compiled your application. The runtime image (~200MB) runs it. The final
image is less than 250MB because build tools are excluded. The app runs as non-root UID 1001.
