---
theme: default
title: Week 07 Lab 05 - Horizontal Pod Autoscaler
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "07"
lab: "Lab 05 · Horizontal Pod Autoscaler"
---

# Horizontal Pod Autoscaler
## Lab 05

- Enable metrics-server in kind for HPA signals
- Create HPA via imperative and declarative methods
- Generate load and observe automatic scale-up and cooldown
- Compare HPA behavior to manual replica changes

---
layout: win95
windowTitle: "HPA Inputs"
windowIcon: "📊"
statusText: "Week 07 · Lab 05 · CPU-based scaling"
---

## Scaling Prerequisites

| Requirement | Why |
|---|---|
| metrics-server working | HPA needs CPU/memory metrics |
| pod resource requests set | utilization % is usage relative to requests |
| target deployment/service stable | avoids noise during scale decisions |

---
layout: win95-terminal
termTitle: "Command Prompt — metrics-server and imperative HPA"
---

<Win95Terminal
  title="Command Prompt — imperative flow"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml' },
    { type: 'input', text: 'kubectl -n kube-system patch deployment metrics-server --type=json -p=\'[{&quot;op&quot;:&quot;add&quot;,&quot;path&quot;:&quot;/spec/template/spec/containers/0/args/-&quot;,&quot;value&quot;:&quot;--kubelet-insecure-tls&quot;}]\'' },
    { type: 'input', text: 'kubectl -n kube-system rollout status deployment/metrics-server' },
    { type: 'input', text: 'kubectl top nodes' },
    { type: 'input', text: 'kubectl describe deployment student-app | grep -A2 -B2 requests' },
    { type: 'input', text: 'kubectl patch deployment student-app -p=\'{ ... resources.requests cpu 100m memory 128Mi ... }\'' },
    { type: 'input', text: 'kubectl autoscale deployment student-app --cpu-percent=50 --min=1 --max=5' },
    { type: 'input', text: 'kubectl get hpa -w' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — declarative HPA and load testing"
---

<Win95Terminal
  title="Command Prompt — declarative flow"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl delete hpa student-app' },
    { type: 'input', text: 'kubectl apply -f student-app-hpa.yaml' },
    { type: 'input', text: 'kubectl get hpa' },
    { type: 'input', text: 'kubectl explain hpa.spec' },
    { type: 'input', text: 'kubectl explain hpa.spec.metrics' },
    { type: 'input', text: 'kubectl explain hpa.spec.behavior' },
    { type: 'input', text: 'kubectl run load-gen --rm -it --restart=Never --image=busybox -- /bin/sh -c &quot;while true; do wget -q -O- http://student-app-svc; done&quot;' },
    { type: 'input', text: 'kubectl get pods -w' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — cooldown, benchmark, and cleanup"
---

<Win95Terminal
  title="Command Prompt — post-load behavior"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl get hpa -w' },
    { type: 'input', text: 'cd week-07/labs/lab-05-hpa-autoscaling' },
    { type: 'input', text: 'python3 scripts/benchmark_hpa.py --namespace default' },
    { type: 'input', text: 'python3 scripts/benchmark_hpa.py --namespace default --load-seconds 60 --cooldown-seconds 60' },
    { type: 'input', text: 'python3 scripts/benchmark_hpa.py --namespace default --hpa student-app' },
    { type: 'input', text: 'python3 scripts/benchmark_hpa.py --namespace default --skip-load' },
    { type: 'input', text: 'python3 scripts/benchmark_hpa.py --namespace default --no-charts' },
    { type: 'input', text: 'kubectl delete hpa student-app-hpa; kubectl delete pod load-gen --ignore-not-found; kubectl scale deployment student-app --replicas=1' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 05 — Key Commands"
windowIcon: "📋"
statusText: "Week 07 · Lab 05 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl autoscale deployment student-app --cpu-percent=50 --min=1 --max=5` | Create HPA imperatively |
| `kubectl apply -f student-app-hpa.yaml` | Create HPA declaratively |
| `kubectl get hpa -w` | Watch live HPA scaling state |
| `kubectl run load-gen --rm -it --restart=Never --image=busybox -- /bin/sh -c "while true; do wget -q -O- http://student-app-svc; done"` | Generate sustained load |
| `kubectl explain hpa.spec.behavior` | Inspect stabilization settings |
| `python3 scripts/benchmark_hpa.py --namespace default` | Generate autoscaling timeline |
| `python3 scripts/benchmark_hpa.py --namespace default --no-charts` | Data collection without chart output |
| `kubectl delete hpa student-app-hpa` | Remove declarative HPA |
| `kubectl scale deployment student-app --replicas=1` | Reset replica count |
