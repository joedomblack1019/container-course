---
theme: default
title: Week 06 Lab 02 - Gateway API on the Shared Cluster
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "06"
lab: "Lab 02 · Gateway API on the Shared Cluster"
---

# Gateway API on the Shared Cluster
## Lab 02

- Deploy Uptime Kuma in your dev namespace
- Attach `HTTPRoute` to shared `cilium-gateway`
- Validate route acceptance and service backend wiring
- Publish status UI at `https://<you>.status.lab.shart.cloud`

---
layout: win95
windowTitle: "Gateway API Role Model"
windowIcon: "🧭"
statusText: "Week 06 · Lab 02 · Platform vs app ownership"
---

## Resource Ownership Split

| Resource | Owner |
|---|---|
| `GatewayClass`, `Gateway` | Platform team |
| `HTTPRoute` | Application team |

```text
HTTPRoute (your namespace)
  -> parentRefs: cilium-gateway (kube-system)
  -> backendRefs: uptime-kuma:3001
```

---
layout: win95-terminal
termTitle: "Command Prompt — inspect shared gateway"
---

<Win95Terminal
  title="Command Prompt — gateway discovery"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config use-context ziyotek-prod' },
    { type: 'input', text: 'kubectl describe gateway cilium-gateway -n kube-system' },
    { type: 'input', text: 'helm repo add uptime-kuma https://dirsigler.github.io/uptime-kuma-helm' },
    { type: 'input', text: 'helm repo update' },
    { type: 'input', text: 'helm template uptime-kuma uptime-kuma/uptime-kuma -f ../lab-01-ingress-kind/starter/uptime-kuma-values.yaml > rendered.yaml' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — prepare GitOps branch and manifests"
---

<Win95Terminal
  title="Command Prompt — GitOps updates"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd ~/talos-gitops' },
    { type: 'input', text: 'git checkout main' },
    { type: 'input', text: 'git pull' },
    { type: 'input', text: 'git checkout -b week06/<YOUR_GITHUB_USERNAME>' },
    { type: 'input', text: 'cd student-infra/students/<YOUR_GITHUB_USERNAME>/dev' },
    { type: 'input', text: 'cp ~/container-course/week-06/labs/lab-02-gateway-api/solution/*.yaml .' },
    { type: 'comment', text: '# Edit httproute hostname and student labels' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — validate, commit, and verify route"
---

<Win95Terminal
  title="Command Prompt — route publish"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/dev | head' },
    { type: 'input', text: 'git add .' },
    { type: 'input', text: 'git commit -m &quot;Week 06: Add Uptime Kuma + HTTPRoute (dev only)&quot;' },
    { type: 'input', text: 'git push -u origin week06/<YOUR_GITHUB_USERNAME>' },
    { type: 'input', text: 'kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-dev' },
    { type: 'input', text: 'kubectl get httproute -n student-<YOUR_GITHUB_USERNAME>-dev' },
    { type: 'input', text: 'kubectl describe httproute uptime-kuma -n student-<YOUR_GITHUB_USERNAME>-dev' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — application setup and monitor URLs"
---

<Win95Terminal
  title="Command Prompt — runtime checks"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'curl -s https://<YOUR_GITHUB_USERNAME>.status.lab.shart.cloud | head' },
    { type: 'input', text: 'curl -s https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/health' },
    { type: 'input', text: 'curl -s https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/visits' },
    { type: 'input', text: 'curl -s https://<YOUR_GITHUB_USERNAME>.prod.lab.shart.cloud/health' },
    { type: 'success', text: 'Configure monitors + public status page in Uptime Kuma UI' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 02 — Key Commands"
windowIcon: "📋"
statusText: "Week 06 · Lab 02 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl describe gateway cilium-gateway -n kube-system` | Inspect shared gateway listeners/TLS/allowed routes |
| `helm template uptime-kuma uptime-kuma/uptime-kuma -f ../lab-01-ingress-kind/starter/uptime-kuma-values.yaml > rendered.yaml` | Render chart manifests locally |
| `git checkout -b week06/<YOUR_GITHUB_USERNAME>` | Create Week 6 branch |
| `cp ~/container-course/week-06/labs/lab-02-gateway-api/solution/*.yaml .` | Seed dev manifests |
| `kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/dev | head` | Validate overlay render |
| `git commit -m "Week 06: Add Uptime Kuma + HTTPRoute (dev only)"` | Commit route and workload manifests |
| `git push -u origin week06/<YOUR_GITHUB_USERNAME>` | Push PR branch |
| `kubectl get httproute -n student-<YOUR_GITHUB_USERNAME>-dev` | Check HTTPRoute existence |
| `kubectl describe httproute uptime-kuma -n student-<YOUR_GITHUB_USERNAME>-dev` | Verify route attached/accepted conditions |
| `curl -s https://<YOUR_GITHUB_USERNAME>.status.lab.shart.cloud` | Verify external route works |
