# Discussion Prompts

Use these prompts to drive group discussion at natural pause points in each module.
Good discussions take 5-10 minutes. If a topic resonates strongly with the group, let it run —
real-world context is more valuable than covering every slide.

---

## Module: Twelve-Factor App

### After Factor I (Codebase)
> "Does your team have one canonical copy of the source? If there are multiple, how do changes
> get synchronized? What is your single source of truth?"

### After Factor III (Config)
> "If I asked you to open-source your application repository right now, would any credentials
> be exposed? What would need to change first?"

### After Factor V (Build/Release/Run)
> "What does a 'deploy' look like at your organisation today? Who approves it? Who performs it?
> How long does it take? What can go wrong?"

### After Factor XI (Logs)
> "When something goes wrong in production at 3am, how do you find out? How do you investigate?
> What would change if you had centralised, searchable logs across all services?"

### End of Module
> "If you could adopt only one of the twelve factors in the next sprint, which would have the
> highest impact for your team? Why?"

---

## Module: Containers and Docker

### After 'What is a Container'
> "Your organisation probably already runs VMs. What would it take to change the culture from
> 'provision a VM' to 'build a container image'? What is the hardest part?"

### After 'Dockerfile Anatomy'
> "What is the difference between a developer who writes a Dockerfile and one who does not?
> What new skills does containerisation require from a development team?"

### After 'Multi-Stage Builds'
> "We reduced the image size from 1.2GB to 150MB. What operational benefits does this have
> beyond just saving disk space? Think about security scanning, pull time, attack surface."

### After 'Push to Registry'
> "Who in your organisation is responsible for the container registry? Is it a shared service
> or does each team manage their own? What are the trade-offs?"

---

## Module: Kubernetes Introduction

### After 'Connect to Cluster'
> "How many Kubernetes clusters does your organisation run today? Who has access to each one?
> How are access credentials distributed?"

### After 'Explore Nodes'
> "How does understanding node capacity help you as a developer vs as an infrastructure engineer?
> When does this knowledge become operationally critical?"

### After 'First Pod'
> "We saw that deleting a bare Pod does not recreate it. Why is running bare Pods in production
> almost always a mistake? What should you use instead?"

---

## Module: Kubernetes Architecture

### After 'Deployments'
> "The reconciliation loop — desired state vs actual state — is the core pattern of Kubernetes.
> Where else do you see this pattern in technology? In your own work?"

### After 'Secrets'
> "We saw that Secrets are base64-encoded, not encrypted. What does this mean for your security
> model? When would you need something like HashiCorp Vault or Sealed Secrets?"

### After 'Network Policies'
> "The default Kubernetes network model is 'everything can talk to everything'. Is this
> acceptable in your environment? Who is responsible for defining network segmentation policy?"

### After 'Liveness/Readiness'
> "How does a readiness probe change the deployment process compared to a system where you just
> check if the process started? What class of bugs does it catch earlier?"

### After 'Requests/Limits'
> "What happens to a cluster where no Pods have resource limits? Why does this matter more on a
> shared cluster than on a dedicated server?"

---

## Module: Application Development on NKP

### After 'GitOps Model'
> "In GitOps, a developer cannot deploy without making a Git commit. Some teams see this as
> a constraint; others see it as a feature. What is your reaction? What are the trade-offs?"

### After 'GitLab CI Pipeline'
> "Who writes and owns the CI pipeline in your organisation today? Developer? DevOps team? Both?
> How does that affect the pace of pipeline improvements?"

### After 'Automated Deployment'
> "We now have a system where no human runs kubectl in production. How would this change
> your organisation's incident response process? Your change management process?"

---

## Module: Infrastructure Introduction

### After 'Cluster API Concepts'
> "CAPI applies the Kubernetes reconciliation model to cluster lifecycle. What are the
> implications of treating cluster config as code in Git? Who benefits most?"

### After 'Provision an NKP Cluster'
> "We provisioned a cluster by applying YAML. If we stored that YAML in Git and someone
> deleted the Cluster object, what should happen? What would GitOps mean for cluster lifecycle?"

---

## Module: NKP Platform for Infrastructure

### After 'Workspaces and Groups'
> "How does your organisation currently handle multi-team access to shared Kubernetes clusters?
> What is the pain point that Kommander workspaces would solve for you?"

### After 'Backup and DR'
> "We ran a restore from backup in about 5 minutes. What is your current RTO (Recovery Time
> Objective) for a critical namespace? What would need to change to meet it?"

### End of Infrastructure Track
> "Looking back at the three days — what is the most surprising thing you learned? What is the
> first thing you will do differently when you return to your organisation?"

---

## Universal Closing Prompt

Use this at the end of each day to consolidate learning:

> "In one sentence: what is the most important thing you learned today, and why does it matter
> to you personally?"

Go around the room and ask each participant. This surfaces insights you may not have known
resonated, and creates a sense of shared progress in the group.
