---
theme: default
title: Week 07 Lab 08 - VPA Right-Sizing Resource Requests
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "07"
lab: "Lab 08 · VPA Right-Sizing Resource Requests"
---

# VPA Right-Sizing Resource Requests
## Lab 08

- Install VPA and understand its three components
- Deploy an over-provisioned workload and observe recommendations
- Distinguish Off / Initial / Recreate / Auto update modes
- Apply VPA recommendations manually and combine safely with HPA

---
layout: win95
windowTitle: "HPA vs VPA — The Model"
windowIcon: "📐"
statusText: "Week 07 · Lab 08 · scaling axes"
---

## HPA vs VPA

| | HPA | VPA |
|---|---|---|
| **What it changes** | `spec.replicas` | `resources.requests` and `limits` per container |
| **Responds to** | Aggregate utilization across replicas | Per-pod usage vs requests ratio |
| **Scaling axis** | Horizontal (more pods) | Vertical (bigger/smaller pods) |
| **Pod restart?** | No | Yes — evicts and recreates pods to apply changes |
| **Safe together?** | Yes — divide: HPA owns CPU replicas, VPA owns memory sizing |

---
layout: win95-terminal
termTitle: "Command Prompt — install VPA and verify components"
---

<Win95Terminal
  title="Command Prompt — VPA installation"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'git clone https://github.com/kubernetes/autoscaler.git --depth 1' },
    { type: 'input', text: 'cd autoscaler/vertical-pod-autoscaler' },
    { type: 'input', text: './hack/vpa-up.sh' },
    { type: 'input', text: 'kubectl get pods -n kube-system | grep vpa' },
    { type: 'input', text: 'kubectl explain vpa.spec' },
    { type: 'input', text: 'kubectl explain vpa.spec.updatePolicy' },
    { type: 'input', text: 'kubectl explain vpa.spec.resourcePolicy.containerPolicies' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — deploy over-provisioned app and create VPA"
---

<Win95Terminal
  title="Command Prompt — workload and VPA object"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f deploy-overprovisioned.yaml' },
    { type: 'input', text: 'kubectl rollout status deployment/jerry-overprovisioned' },
    { type: 'input', text: 'kubectl apply -f vpa-recommend.yaml' },
    { type: 'input', text: 'kubectl port-forward deployment/jerry-overprovisioned 8080:80 &' },
    { type: 'input', text: 'for i in $(seq 1 300); do curl -s http://localhost:8080 > /dev/null; sleep 0.2; done' },
    { type: 'input', text: 'kill %1' },
    { type: 'input', text: 'kubectl describe vpa jerry-vpa' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — read recommendation and apply manually"
---

<Win95Terminal
  title="Command Prompt — Off mode workflow"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl get vpa jerry-vpa -o yaml | grep -A10 recommendation' },
    { type: 'input', text: '# Read Target cpu/memory from output above, then apply:' },
    { type: 'input', text: 'kubectl set resources deployment jerry-overprovisioned -c=app --requests=cpu=25m,memory=32Mi' },
    { type: 'input', text: 'kubectl rollout status deployment/jerry-overprovisioned' },
    { type: 'input', text: 'kubectl describe deployment jerry-overprovisioned | grep -A6 Requests' },
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
    { type: 'input', text: 'kubectl delete vpa jerry-vpa' },
    { type: 'input', text: 'kubectl delete deployment jerry-overprovisioned' },
    { type: 'input', text: 'cd ../../../..' },
    { type: 'input', text: 'rm -rf autoscaler' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 08 — Key Commands"
windowIcon: "📋"
statusText: "Week 07 · Lab 08 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `./hack/vpa-up.sh` | Install VPA recommender, updater, and admission controller |
| `kubectl get pods -n kube-system \| grep vpa` | Verify all three VPA components are running |
| `kubectl apply -f vpa-recommend.yaml` | Create a VPA object (updateMode: Off = recommend only) |
| `kubectl describe vpa <name>` | Show recommendation bounds: Lower, Target, Upper, Uncapped |
| `kubectl get vpa <name> -o yaml \| grep -A10 recommendation` | Extract target recommendation values |
| `kubectl set resources deployment <name> -c=<container> --requests=cpu=<v>,memory=<v>` | Apply VPA recommendation without JSON quoting |
| `kubectl explain vpa.spec.updatePolicy` | Off / Initial / Recreate / Auto modes |
| `kubectl explain vpa.spec.resourcePolicy.containerPolicies` | Per-container min/max bounds and resource exclusions |
| `kubectl patch deployment <name> -p='{...}'` | Apply VPA recommendation manually (Off mode workflow) |
| `kubectl describe deployment <name> \| grep -A6 Requests` | Verify updated resource requests on the deployment |
| `kubectl rollout status deployment/<name>` | Confirm rollout after patching requests |
