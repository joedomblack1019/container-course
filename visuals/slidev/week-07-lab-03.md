---
theme: default
title: Week 07 Lab 03 - Scrape With Prometheus
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "07"
lab: "Lab 03 · Scrape With Prometheus"
---

# Scrape With Prometheus
## Lab 03

- Create minimal Prometheus scrape config for exporter service
- Deploy ConfigMap, Deployment, and Service for Prometheus
- Verify target health in Prometheus UI
- Run PromQL queries against custom metrics

---
layout: win95
windowTitle: "Minimal Scrape Config"
windowIcon: "📡"
statusText: "Week 07 · Lab 03 · exporter target"
---

## `prometheus.yml`

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: course-metrics-exporter
    metrics_path: /metrics
    static_configs:
      - targets:
          - course-metrics-exporter:9100
```

---
layout: win95-terminal
termTitle: "Command Prompt — deploy and access Prometheus"
---

<Win95Terminal
  title="Command Prompt — scrape demo"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'comment', text: '# Apply ConfigMap + Deployment + Service manifests' },
    { type: 'input', text: 'kubectl apply -f prometheus-configmap.yaml' },
    { type: 'input', text: 'kubectl apply -f prometheus-deployment.yaml' },
    { type: 'input', text: 'kubectl apply -f prometheus-service.yaml' },
    { type: 'input', text: 'kubectl port-forward service/prometheus 9090:9090 &' },
    { type: 'input', text: 'curl -s http://localhost:9090/-/ready' },
    { type: 'success', text: 'Open http://localhost:9090 and check Status -> Targets' },
    { type: 'input', text: 'kill %1' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 03 — Key Commands"
windowIcon: "📋"
statusText: "Week 07 · Lab 03 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl apply -f prometheus-configmap.yaml` | Create Prometheus config |
| `kubectl apply -f prometheus-deployment.yaml` | Deploy Prometheus server |
| `kubectl apply -f prometheus-service.yaml` | Expose Prometheus service |
| `kubectl port-forward service/prometheus 9090:9090 &` | Open local UI access |
| `curl -s http://localhost:9090/-/ready` | Check readiness endpoint |
| `kill %1` | Stop Prometheus port-forward |
