---
theme: default
title: Week 03 - Compose and Local Development
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "03"
lab: "Week 03 · Compose & Local Development"
---

# Compose & Local Development
## Week 03

- Move from single containers to multi-service stacks
- Practice service discovery, networks, and persistent volumes
- Build a fast dev loop with bind mounts and live reload

---
layout: win95
windowTitle: "Week 03 — Learning Goals"
windowIcon: "🧭"
statusText: "Week 03 · Outcomes"
---

## What This Week Covers

| Topic | Practical outcome |
|---|---|
| **Compose services** | Launch app + db + cache from one YAML file |
| **Networking + DNS** | Resolve services by name, debug connectivity |
| **Volumes** | Keep state across container recreation |
| **Health checks** | Gate startup on real readiness |
| **Bind mounts** | Edit code and see changes without rebuild |

---
layout: win95
windowTitle: "Week 03 — Lab Roadmap"
windowIcon: "🗺"
statusText: "Week 03 · Three labs"
---

## Lab Sequence

<Win95TaskManager
  title="Week 03 — Lab Queue"
  tab="Pods"
  status-text="3 labs queued"
  :show-namespace="false"
  :processes="[
    { name: 'lab-01-compose-wordpress', pid: 1, cpu: 0, memory: '30 min', status: 'Running' },
    { name: 'lab-02-network-debugging', pid: 2, cpu: 0, memory: '30 min', status: 'Pending' },
    { name: 'lab-03-dev-workflow', pid: 3, cpu: 0, memory: '20 min', status: 'Pending' }
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — Week 03 core commands"
---

<Win95Terminal
  title="Command Prompt — week 03"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker compose up -d' },
    { type: 'input', text: 'docker compose ps' },
    { type: 'input', text: 'docker compose logs -f wordpress' },
    { type: 'input', text: 'docker compose exec web sh -c &quot;getent hosts redis&quot;' },
    { type: 'input', text: 'docker compose down -v' },
    { type: 'success', text: 'Stack lifecycle complete' },
  ]"
/>

---
layout: win95
windowTitle: "Week 03 — Compose to Kubernetes"
windowIcon: "☸"
statusText: "Week 03 · Mental model bridge"
---

## Concept Bridge

<Win95Dialog
  type="info"
  title="Why Week 03 Matters"
  message="Compose service discovery, networks, and health checks map directly to Kubernetes workflows."
  detail="This week builds the operational instincts you need before Week 4 cluster work."
  :buttons="['OK']"
  :active-button="0"
/>
