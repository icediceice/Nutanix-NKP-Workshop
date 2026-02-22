---
title: "Factors VI & VII: Processes and Port Binding"
---

## What We're Doing

AppCo's application writes session data to the local filesystem. This means requests must always
hit the same server — a "sticky session" architecture. Sticky sessions prevent horizontal scaling
and create single points of failure. Factors VI and VII eliminate both problems.

## Factor VI: Processes — Execute as one or more stateless processes

Twelve-factor processes are stateless and share-nothing. Any data that needs to persist goes into
a backing service (database, cache, blob store). Session state belongs in Redis, not on disk.

**AppCo's fix:** Move PHP sessions to a Redis-backed session store. Now any Pod can handle any
request. A Pod can be killed and replaced without any user noticing.

```terminal:execute
command: kubectl get pods -l app=appco -o wide
```

**Observe:** Multiple Pods running across different nodes. No Pod is "special" — they are
interchangeable. The load balancer can send traffic to any of them.

## Factor VII: Port Binding — Export services via port binding

A twelve-factor app is self-contained. It does not rely on the host to inject a web server —
it binds to a port itself and listens for requests. This is why we use `php-fpm` + `nginx` in
the same container, or a framework with a built-in HTTP server.

**AppCo's fix:** The Docker image runs an nginx process that listens on port 8080. The
Kubernetes Service fronts this port. The app is not dependent on Apache being pre-installed.

## What Just Happened

Stateless processes (Factor VI) enable horizontal scaling and eliminate sticky sessions.
Port binding (Factor VII) makes the app self-contained and portable — it runs identically in a
container, a VM, or a developer laptop without any host configuration.
