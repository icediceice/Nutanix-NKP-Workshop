# Workshop Authoring Guide

This guide explains how to write new workshop modules for the NKP Workshop platform and
how to follow the established style conventions so that all modules have a consistent look and feel.

---

## Directory Structure

Every workshop follows this structure:

```
workshops/<workshop-name>/
├── workshop/
│   ├── config.yaml          # Educates Workshop resource definition
│   └── content/             # Markdown content files
│       ├── 00-overview.md
│       ├── 01-<topic>.md
│       └── 99-summary.md
└── resources/               # Optional: Kubernetes YAML examples, exercise files
```

---

## The config.yaml File

Every workshop needs a `Workshop` custom resource. Minimum viable config:

```yaml
apiVersion: training.educates.dev/v1beta1
kind: Workshop
metadata:
  name: my-workshop
spec:
  title: "My Workshop Title"
  description: "One paragraph description shown in the portal."
  workshop:
    files:
      - image:
          url: $(image_repository)/my-workshop-files:latest
  session:
    namespaces:
      budget: small       # small | medium | large
    applications:
      terminal:
        enabled: true
        layout: split    # split | lower | upper
      editor:
        enabled: true    # set false if not needed
```

Budget sizes correspond to ResourceQuota presets defined in the Educates operator config.

---

## Content File Structure

Every content file must follow this template:

```markdown
---
title: Topic Title
---

## What We're Doing

2-3 sentences explaining what this exercise covers and why it matters.
No bullet lists here — write in prose.

## Steps

### 1. Step name

Explanation of what to run and why.

```terminal:execute
command: kubectl <some-command>
```

**Observe:** What the participant should look for in the output. What does it mean?

[Repeat for each step]

## What Just Happened

1-2 sentences explaining what Kubernetes (or the system) did in response to the commands.
Connect the hands-on action back to the concept.
```

---

## Style Guide

### Terminal Blocks

Always use `terminal:execute` for commands participants should run:

```
```terminal:execute
command: kubectl get pods -n my-namespace
```
```

For multi-line commands, use `\` continuation or a heredoc — do not use line breaks inside
the command string.

For commands that should NOT auto-execute (e.g., examples to read, not run), use plain code blocks:

```
```bash
# This is an example, do not run it
kubectl delete namespace production
```
```

### Observe Callouts

Every `terminal:execute` block must be followed by an `**Observe:**` callout explaining what
to look for. Never leave a command without guidance on what success looks like.

Good:
```
**Observe:** The Pod status transitions from `ContainerCreating` to `Running`. If it stays in
`Pending`, check the Events section with `kubectl describe pod`.
```

Bad:
```
**Observe:** You can see the output.
```

### Notice Callouts

Use `**Notice:**` (without a terminal block) for conceptual observations:

```
**Notice:** The Deployment created a ReplicaSet automatically. You did not create the ReplicaSet
directly — the Deployment controller manages it for you.
```

### Try It Yourself

End optional extension exercises with this standard heading:

```markdown
### Try It Yourself

> Create a second Deployment using `nginx:1.24` and observe how the cluster runs both versions
> simultaneously. Scale one to 0 replicas. What happens to traffic?

There is no solution provided for "Try It Yourself" exercises — the exploration is the point.
```

### What Just Happened

Always include a "What Just Happened" section at the end of each content page. Keep it to 2-3
sentences maximum. Avoid repeating the step descriptions — focus on the mechanism.

---

## Writing Principles

1. **Explain before you execute.** Never drop a terminal block without context.
2. **One concept per page.** If a page covers more than one major concept, split it.
3. **The Observe callout is not optional.** It is the difference between a demo and a workshop.
4. **Write for the person who is slightly lost.** The fast learner will skip; the struggling
   participant needs the context.
5. **Use the AppCo narrative when relevant.** For conceptual workshops, ground abstract concepts
   in the AppCo story rather than invented abstract examples.
6. **Test every command.** Run every `terminal:execute` block in a real session before publishing.

---

## Adding a New Workshop to the Portal

1. Create the workshop directory and files as above
2. Build and push the workshop files image to Harbor
3. Add the `Workshop` resource to the cluster: `kubectl apply -f workshop/config.yaml`
4. Add the workshop to the `TrainingPortal` spec in `cluster-init/educates/training-portal.yaml`
5. Apply the updated TrainingPortal: `kubectl apply -f cluster-init/educates/training-portal.yaml`
6. Verify the workshop appears in the portal at `https://portal.workshop.example.com`
