---
theme: default
title: Week 07 Lab 01 - Production Kustomize
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "07"
lab: "Lab 01 · Production Kustomize"
---

# Production Kustomize
## Lab 01

- Refactor duplicate `dev/` and `prod/` manifests into shared `base/`
- Move environment-specific differences into overlays
- Create reusable component for dev-only Uptime Kuma
- Validate render output before PR submission

---
layout: win95
windowTitle: "Target Layout"
windowIcon: "🗂"
statusText: "Week 07 · Lab 01 · Base + overlays + components"
---

## Directory Structure

```text
student-infra/students/<you>/
  base/
  components/
    uptime-kuma/
    network-policy/
  overlays/
    dev/
    prod/
```

---
layout: win95
windowTitle: "Component Definition"
windowIcon: "🧩"
statusText: "Week 07 · Lab 01 · Reusable feature slice"
---

## `components/uptime-kuma/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - uptime-kuma-deployment.yaml
  - uptime-kuma-service.yaml
  - uptime-kuma-pvc.yaml
  - httproute.yaml
```

---
layout: win95-terminal
termTitle: "Command Prompt — build base and overlays"
---

<Win95Terminal
  title="Command Prompt — kustomize refactor"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'comment', text: '# After moving shared resources to base/' },
    { type: 'input', text: 'kubectl kustomize base | head' },
    { type: 'comment', text: '# Validate environment overlays' },
    { type: 'input', text: 'kubectl kustomize overlays/dev | head' },
    { type: 'input', text: 'kubectl diff -k overlays/dev 2>/dev/null || true' },
    { type: 'input', text: 'kubectl kustomize overlays/prod | head' },
    { type: 'success', text: 'Dev includes component; prod excludes dev-only tooling' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — final verification and commit"
---

<Win95Terminal
  title="Command Prompt — submit refactor"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl kustomize overlays/dev | head' },
    { type: 'input', text: 'kubectl kustomize overlays/prod | head' },
    { type: 'input', text: 'git add .' },
    { type: 'input', text: 'git commit -m &quot;week07: refactor to base overlays components&quot;' },
    { type: 'input', text: 'git push origin week07/<YOUR_GITHUB_USERNAME>' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 01 — Key Commands"
windowIcon: "📋"
statusText: "Week 07 · Lab 01 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl kustomize base | head` | Validate base render output |
| `kubectl kustomize overlays/dev | head` | Validate dev overlay render |
| `kubectl diff -k overlays/dev 2>/dev/null || true` | Preview cluster diff for dev overlay |
| `kubectl kustomize overlays/prod | head` | Validate prod overlay render |
| `git add .` | Stage refactor changes |
| `git commit -m "week07: refactor to base overlays components"` | Commit structure changes |
| `git push origin week07/<YOUR_GITHUB_USERNAME>` | Push branch for PR |
