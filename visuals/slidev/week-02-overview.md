---
theme: default
title: Week 02 - Dockerfile Mastery
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "02"
lab: "Week 02 · Dockerfile Mastery"
---

# Dockerfile Mastery
## Week 02

- Fix cache-busting Dockerfiles and speed up rebuilds
- Convert fat images into multi-stage lean images
- Scan images with Trivy and remediate CVEs

---
layout: win95
windowTitle: "Week 02 — Learning Outcomes"
windowIcon: "🎯"
statusText: "Week 02 · Outcomes"
---

## What You Will Be Able to Do

| Skill | Why it matters |
|---|---|
| **Layer caching strategy** | Rebuild in seconds instead of minutes |
| **Multi-stage builds** | Ship only runtime artifacts |
| **Base image selection** | Balance size, compatibility, and security |
| **Trivy scanning** | Catch CVEs before production |
| **.dockerignore usage** | Reduce build context and accidental leaks |

---
layout: win95
windowTitle: "Week 02 — Lab Roadmap"
windowIcon: "🗺"
statusText: "Week 02 · Three labs"
---

## Lab Sequence

<Win95TaskManager
  title="Week 02 — Lab Queue"
  tab="Pods"
  status-text="3 labs queued"
  :show-namespace="false"
  :processes="[
    { name: 'lab-01-layer-optimization', pid: 1, cpu: 0, memory: '25 min', status: 'Running' },
    { name: 'lab-02-multistage-build',   pid: 2, cpu: 0, memory: '30 min', status: 'Pending' },
    { name: 'lab-03-security-scanning',  pid: 3, cpu: 0, memory: '20 min', status: 'Pending' }
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — Week 02 core workflow"
---

<Win95Terminal
  title="Command Prompt — week 02"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'comment', text: '# Lab 1: layer cache optimization' },
    { type: 'input', text: 'time docker build -t data-processor:fast -f Dockerfile.optimized .' },
    { type: 'comment', text: '# Lab 2: multi-stage lean runtime image' },
    { type: 'input', text: 'docker build -t go-api:lean -f Dockerfile.multistage .' },
    { type: 'comment', text: '# Lab 3: security gate before push' },
    { type: 'input', text: 'trivy image --severity CRITICAL,HIGH --exit-code 1 myapp:latest' },
    { type: 'success', text: 'No CRITICAL/HIGH findings' },
  ]"
/>

---
layout: win95
windowTitle: "Week 02 — End State"
windowIcon: "✅"
statusText: "Week 02 · Ready for Compose"
---

## End of Week Target

<Win95Dialog
  type="info"
  title="Production-Ready Images"
  message="Build fast, ship lean, and scan continuously."
  detail="You finish Week 02 with practical optimization and security habits that directly map to CI/CD and Kubernetes deployment pipelines."
  :buttons="['OK']"
  :active-button="0"
/>
