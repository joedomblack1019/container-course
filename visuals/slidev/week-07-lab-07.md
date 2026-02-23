---
theme: default
title: Week 07 Lab 07 - Resource Observation with kubectl top
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "07"
lab: "Lab 07 · Resource Observation with kubectl top"
---

# Resource Observation with kubectl top
## Lab 07

- Enable metrics-server in kind and verify `top` API availability
- Deploy workload zoo with distinct CPU/memory profiles
- Use sort + label filters to identify resource hogs quickly
- Complete graded challenge using `top` and `describe` evidence

---
layout: win95
windowTitle: "Reading top Output"
windowIcon: "📈"
statusText: "Week 07 · Lab 07 · units and interpretation"
---

## Essential Interpretation Rules

| Metric | Meaning |
|---|---|
| CPU `m` | millicores (`1000m = 1 core`) |
| Memory `Mi`/`Gi` | actual resident memory consumption |
| Requests vs top | reservation vs real-time usage |

---
layout: win95-terminal
termTitle: "Command Prompt — create cluster and install metrics-server"
---

<Win95Terminal
  title="Command Prompt — lab bootstrap"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cat <<\'EOF\' > /tmp/kind-resource.yaml' },
    { type: 'input', text: 'kind: Cluster  # name resource-lab with control-plane + 2 workers' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kind create cluster --name resource-lab --config /tmp/kind-resource.yaml' },
    { type: 'input', text: 'kubectl config use-context kind-resource-lab' },
    { type: 'input', text: 'kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml' },
    { type: 'input', text: 'kubectl -n kube-system patch deployment metrics-server --type=json -p=\'[{&quot;op&quot;:&quot;add&quot;,&quot;path&quot;:&quot;/spec/template/spec/containers/0/args/-&quot;,&quot;value&quot;:&quot;--kubelet-insecure-tls&quot;}]\'' },
    { type: 'input', text: 'kubectl -n kube-system rollout status deployment/metrics-server --timeout=90s' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — baseline and workload zoo"
---

<Win95Terminal
  title="Command Prompt — top baseline"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl top nodes' },
    { type: 'input', text: 'kubectl top pods --all-namespaces' },
    { type: 'input', text: 'kubectl top pods -n kube-system --sort-by=memory' },
    { type: 'input', text: 'kubectl apply -f starter/workload-zoo.yaml' },
    { type: 'input', text: 'kubectl -n resource-lab get pods -w' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — sorting, filtering, and requests comparison"
---

<Win95Terminal
  title="Command Prompt — triage patterns"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl top pods -n resource-lab' },
    { type: 'input', text: 'kubectl top pods -n resource-lab --sort-by=cpu' },
    { type: 'input', text: 'kubectl top pods -n resource-lab --sort-by=memory' },
    { type: 'input', text: 'kubectl top pods -n resource-lab -l tier=compute' },
    { type: 'input', text: 'kubectl top pods -n resource-lab -l tier=web' },
    { type: 'input', text: 'kubectl top pods --all-namespaces --sort-by=cpu' },
    { type: 'input', text: 'CPU_POD=$(kubectl get pods -n resource-lab -l app=cpu-burner -o name | head -1 | cut -d/ -f2)' },
    { type: 'input', text: 'kubectl -n resource-lab describe pod &quot;$CPU_POD&quot; | grep -A4 &quot;Requests:&quot;' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — job lifecycle and graded challenge"
---

<Win95Terminal
  title="Command Prompt — challenge"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl top pod -n resource-lab &quot;$CPU_POD&quot;' },
    { type: 'input', text: 'MEM_POD=$(kubectl get pods -n resource-lab -l app=memory-hog -o name | head -1 | cut -d/ -f2)' },
    { type: 'input', text: 'kubectl -n resource-lab describe pod &quot;$MEM_POD&quot; | grep -A4 &quot;Requests:&quot;' },
    { type: 'input', text: 'kubectl -n resource-lab describe job batch-processor | grep -E &quot;Completions|Succeeded|Failed&quot;' },
    { type: 'input', text: 'bash starter/challenge-validate.sh challenge-answers.txt' },
    { type: 'success', text: 'Passing target: 4/4' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — cleanup"
---

<Win95Terminal
  title="Command Prompt — lab teardown"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config use-context kind-lab 2>/dev/null || true' },
    { type: 'input', text: 'kind delete cluster --name resource-lab' },
    { type: 'input', text: 'rm -f /tmp/kind-resource.yaml' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 07 — Key Commands"
windowIcon: "📋"
statusText: "Week 07 · Lab 07 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl top nodes` | Show node-level usage snapshot |
| `kubectl top pods --all-namespaces` | Show pod usage cluster-wide |
| `kubectl top pods -n resource-lab --sort-by=cpu` | Find CPU-heavy pods |
| `kubectl top pods -n resource-lab --sort-by=memory` | Find memory-heavy pods |
| `kubectl top pods -n resource-lab -l tier=compute` | Filter by label for specific tier |
| `kubectl -n resource-lab describe pod "$CPU_POD" | grep -A4 "Requests:"` | Compare requests to actual usage |
| `kubectl -n resource-lab describe job batch-processor | grep -E "Completions|Succeeded|Failed"` | Check batch lifecycle outcome |
| `bash starter/challenge-validate.sh challenge-answers.txt` | Validate graded answers |
| `kind delete cluster --name resource-lab` | Cleanup cluster |
