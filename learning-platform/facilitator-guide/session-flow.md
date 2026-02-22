# Session Flow and 3-Day Schedule

## Overview

This guide describes the recommended delivery schedule for the full NKP Workshop series.
The programme is designed for groups of 8-20 participants split into two tracks from Day 2.
All times are approximate and should be adjusted based on group pace.

---

## Day 1 — Foundations (All Participants)

### 08:30 — Registration and Setup
- Participants register at the registration app kiosk
- Session credentials distributed (GitLab, Harbor, Educates portal)
- Facilitator verifies all session environments are provisioned

### 09:00 — Welcome and Introduction (30 min)
- Workshop goals and agenda overview
- Participant introductions (name, role, Kubernetes experience)
- Housekeeping: breaks, lunch, questions policy

### 09:30 — Whiteboard: The Twelve-Factor App (45 min)
- Facilitator delivers the AppCo whiteboard narrative
- Introduce all 12 factors at high level
- Discussion: which factors are most relevant to participants' organisations?

### 10:15 — Break (15 min)

### 10:30 — Workshop: Twelve-Factor App (90 min)
- Participants work through the Educates workshop: `twelve-factor`
- Facilitator circulates and facilitates discussion at each factor
- Debrief: AppCo transformation table

### 12:00 — Lunch (60 min)

### 13:00 — Whiteboard: Containers and the Container Image (30 min)
- Layers, union filesystems, the image vs container distinction
- Why containers are not VMs

### 13:30 — Workshop: Containers and Docker (90 min)
- Participants work through: `containers-docker`
- Key exercise: multi-stage build comparison
- Debrief: image size comparison results

### 15:00 — Break (15 min)

### 15:15 — Workshop: Kubernetes Introduction (75 min)
- Participants work through: `k8s-intro`
- Debrief: the reconciliation loop concept

### 16:30 — Day 1 Wrap-up (30 min)
- Quiz: Kubernetes Foundations Knowledge Check
- Preview of Day 2 tracks
- Q&A

---

## Day 2 — Track Split

Participants choose Developer or Infrastructure track at the end of Day 1.

### 09:00 — Whiteboard: Kubernetes Architecture Deep-Dive (45 min)
- Full object model overview
- The reconciliation pattern applied to every object type

### 09:45 — Workshop: Kubernetes Architecture (4 hours with breaks)
- Participants work through all 16 topics in `k8s-architecture`
- Suggested break points: after topic 08 (Security Contexts) and after topic 12 (Logs)

### 14:00 — Lunch (60 min)

### 15:00 — Track Split

#### Developer Track (Room A)
- Workshop: Application Development on NKP (`dev-app-development`)
- Focus: GitLab CI pipeline setup, .NET containerisation, FluxCD

#### Infrastructure Track (Room B)
- Workshop: Infrastructure Introduction (`infra-introduction`)
- Focus: Nutanix stack, CAPI concepts, live cluster provisioning demo

### 17:00 — End of Day 2
- Cross-track debrief: what did each group build/learn?

---

## Day 3 — Advanced Platform

### 09:00 — Developer Track (Room A)
- Workshop: NKP Platform for Developers (`dev-nkp-platform`)
- Focus: Harbor, observability, application catalog, Istio

### 09:00 — Infrastructure Track (Room B)
- Workshop: NKP Platform for Infrastructure (`infra-nkp-platform`)
- Focus: Workspaces, access policies, storage, backup/DR

### 12:00 — Lunch (60 min)

### 13:00 — Track Quizzes (30 min)
- Developer track quiz
- Infrastructure track quiz

### 13:30 — Joint Session: Architecture Review
- Facilitator presents the full NKP architecture diagram
- How developer and infrastructure tracks connect
- Common integration points: Harbor, FluxCD, Kommander

### 14:30 — Break (15 min)

### 14:45 — Open Lab / Advanced Topics (60 min)
- Participants continue any unfinished workshops
- Advanced participants: explore KEDA, Velero DR drill, Istio traffic management

### 15:45 — Closing Session (45 min)
- Participant reflections: what will you apply next week?
- Next steps and resources
- Certificate distribution (if applicable)
- Feedback forms

---

## Facilitator Notes

- Keep the Educates portal tab open on the projector throughout — use it to demonstrate navigation
- The AppCo narrative should feel like storytelling, not a lecture — pause for reactions
- Day 2 workshop (k8s-architecture) is the longest session — check in frequently and adjust pace
- If a participant finishes early, direct them to the "Try It Yourself" extensions in each module
