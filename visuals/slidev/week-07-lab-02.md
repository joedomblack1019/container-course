---
theme: default
title: Week 07 Lab 02 - Build a Redis Metrics Exporter
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "07"
lab: "Lab 02 · Build a Redis Metrics Exporter"
---

# Build a Redis Metrics Exporter
## Lab 02

- Install metrics-server and inspect baseline resource usage
- Implement exporter `/metrics` endpoint from Redis state
- Deploy exporter with ConfigMap + Secret wiring
- Seed test data and verify Prometheus-format output

---
layout: win95
windowTitle: "Exporter Contract"
windowIcon: "📈"
statusText: "Week 07 · Lab 02 · export pattern"
---

## Minimal Exporter Requirements

| Requirement | Detail |
|---|---|
| Endpoint | `GET /metrics` |
| Format | `text/plain; version=0.0.4` |
| Behavior | Read-only access to Redis keys |
| Port | `9100` |

---
layout: win95-terminal
termTitle: "Command Prompt — metrics-server and kubectl top warmup"
---

<Win95Terminal
  title="Command Prompt — cluster metrics baseline"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml' },
    { type: 'input', text: 'kubectl -n kube-system patch deployment metrics-server --type=json -p=\'[{&quot;op&quot;:&quot;add&quot;,&quot;path&quot;:&quot;/spec/template/spec/containers/0/args/-&quot;,&quot;value&quot;:&quot;--kubelet-insecure-tls&quot;}]\'' },
    { type: 'input', text: 'kubectl -n kube-system rollout status deployment/metrics-server' },
    { type: 'input', text: 'kubectl top nodes' },
    { type: 'input', text: 'kubectl top pods' },
    { type: 'input', text: 'kubectl top pods -A --sort-by=cpu' },
    { type: 'input', text: 'kubectl top pods -A --sort-by=memory' },
    { type: 'input', text: 'kubectl top pods --containers -n kube-system' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — build/load exporter and deploy"
---

<Win95Terminal
  title="Command Prompt — exporter deploy"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'comment', text: '# In starter/, implement exporter.py then build image' },
    { type: 'input', text: 'docker build -t course-metrics-exporter:v1 .' },
    { type: 'input', text: 'kind load docker-image course-metrics-exporter:v1 --name lab' },
    { type: 'input', text: 'kubectl get pods' },
    { type: 'input', text: 'kubectl port-forward service/course-metrics-exporter 9100:9100 &' },
    { type: 'input', text: 'curl -s http://localhost:9100/metrics | head' },
    { type: 'input', text: 'kill %1' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — seed redis data and re-check metrics"
---

<Win95Terminal
  title="Command Prompt — data-driven metrics"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl exec -it redis-0 -- redis-cli -a &quot;$REDIS_PASSWORD&quot; LPUSH guestbook:demo &quot;hello&quot;' },
    { type: 'input', text: 'kubectl exec -it redis-0 -- redis-cli -a &quot;$REDIS_PASSWORD&quot; LPUSH guestbook:demo &quot;world&quot;' },
    { type: 'input', text: 'kubectl port-forward service/course-metrics-exporter 9100:9100 &' },
    { type: 'input', text: 'curl -s http://localhost:9100/metrics | head' },
    { type: 'input', text: 'kill %1' },
    { type: 'success', text: 'Metric values reflect current Redis keys' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 02 — Key Commands"
windowIcon: "📋"
statusText: "Week 07 · Lab 02 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml` | Install metrics-server |
| `kubectl -n kube-system patch deployment metrics-server --type=json -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'` | Patch for kind kubelet TLS |
| `kubectl -n kube-system rollout status deployment/metrics-server` | Wait for metrics-server rollout |
| `kubectl top nodes` | View node resource usage |
| `kubectl top pods -A --sort-by=cpu` | Find highest CPU pods |
| `kubectl top pods -A --sort-by=memory` | Find highest memory pods |
| `docker build -t course-metrics-exporter:v1 .` | Build exporter image |
| `kind load docker-image course-metrics-exporter:v1 --name lab` | Load image into kind |
| `kubectl port-forward service/course-metrics-exporter 9100:9100 &` | Expose exporter endpoint locally |
| `curl -s http://localhost:9100/metrics | head` | Inspect metrics output |
| `kubectl exec -it redis-0 -- redis-cli -a "$REDIS_PASSWORD" LPUSH guestbook:demo "hello"` | Seed Redis list data |
| `kubectl exec -it redis-0 -- redis-cli -a "$REDIS_PASSWORD" LPUSH guestbook:demo "world"` | Add second guestbook entry |
| `kill %1` | Stop port-forward background job |
