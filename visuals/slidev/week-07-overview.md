---
theme: default
title: Week 07 - Production Kustomize and Metrics Exporting
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "07"
lab: "Week 07 · Production Kustomize + Metrics"
---

# Production Kustomize + Metrics
## Week 07

- Refactor GitOps manifests into `base/` + overlays + components
- Build and export real Redis-backed application metrics
- Scrape and query metrics with a minimal Prometheus setup

---
layout: win95
windowTitle: "Week 07 — Lab Roadmap"
windowIcon: "🗺"
statusText: "Week 07 · Seven labs"
---

## Lab Sequence

<Win95TaskManager
  title="Week 07 — Lab Queue"
  tab="Pods"
  status-text="7 labs queued"
  :show-namespace="false"
  :processes="[
    { name: 'lab-01-production-kustomize',          pid: 1, cpu: 0, memory: '60 min', status: 'Running' },
    { name: 'lab-02-metrics-exporter',              pid: 2, cpu: 0, memory: '55 min', status: 'Pending' },
    { name: 'lab-03-prometheus-scrape',             pid: 3, cpu: 0, memory: '35 min', status: 'Pending' },
    { name: 'lab-04-node-lifecycle-and-upgrade',    pid: 4, cpu: 0, memory: '60 min', status: 'Pending' },
    { name: 'lab-05-hpa-autoscaling',               pid: 5, cpu: 0, memory: '20-25 min', status: 'Pending' },
    { name: 'lab-06-scheduling-constraints',        pid: 6, cpu: 0, memory: '55 min', status: 'Pending' },
    { name: 'lab-07-resource-observation',          pid: 7, cpu: 0, memory: '30-40 min', status: 'Pending' }
  ]"
/>

---
layout: win95
windowTitle: "Week 07 — Core Pattern"
windowIcon: "🧱"
statusText: "Week 07 · Reuse + observability"
---

## Two Core Skills

| Skill | Why it matters |
|---|---|
| **Kustomize base/overlays/components** | Remove drift and keep env differences explicit |
| **Exporter + Prometheus scrape loop** | Replace guesswork with measurable system state |

---
layout: win95-terminal
termTitle: "Command Prompt — week highlights"
---

<Win95Terminal
  title="Command Prompt — week 07"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl kustomize base | head' },
    { type: 'input', text: 'docker build -t course-metrics-exporter:v1 .' },
    { type: 'input', text: 'kubectl port-forward service/prometheus 9090:9090 &' },
    { type: 'input', text: 'kubectl drain &quot;$WORKER&quot; --ignore-daemonsets --delete-emptydir-data --timeout=60s' },
    { type: 'input', text: 'kubectl autoscale deployment student-app --cpu-percent=50 --min=1 --max=5' },
    { type: 'input', text: 'kubectl top pods -A --sort-by=cpu' },
  ]"
/>
