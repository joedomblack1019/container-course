---
theme: default
title: Week 06 - Networking and Security
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "06"
lab: "Week 06 · Networking & Security"
---

# Networking & Security
## Week 06

- Move from `port-forward` to hostname-based routing
- Compare Ingress and Gateway API operating models
- Lock down namespaces with incremental NetworkPolicies

---
layout: win95
windowTitle: "Week 06 — Traffic Mental Model"
windowIcon: "🌐"
statusText: "Week 06 · DNS to Pod path"
---

## How Requests Reach Workloads

```text
User hostname -> DNS -> gateway/load balancer
-> Ingress or HTTPRoute decision
-> Service selector
-> backend Pod container port
```

---
layout: win95
windowTitle: "Week 06 — Lab Roadmap"
windowIcon: "🗺"
statusText: "Week 06 · Six labs"
---

## Lab Sequence

<Win95TaskManager
  title="Week 06 — Lab Queue"
  tab="Pods"
  status-text="6 labs queued"
  :show-namespace="false"
  :processes="[
    { name: 'lab-01-ingress-kind',                            pid: 1, cpu: 0, memory: '40 min', status: 'Running' },
    { name: 'lab-02-gateway-api',                             pid: 2, cpu: 0, memory: '40 min', status: 'Pending' },
    { name: 'lab-03-network-policies',                        pid: 3, cpu: 0, memory: '25 min', status: 'Pending' },
    { name: 'lab-04-service-types-nodeport-loadbalancer',     pid: 4, cpu: 0, memory: '40 min', status: 'Pending' },
    { name: 'lab-05-coredns-troubleshooting',                 pid: 5, cpu: 0, memory: '35 min', status: 'Pending' },
    { name: 'lab-06-cni-comparison',                          pid: 6, cpu: 0, memory: '45-55 min', status: 'Pending' }
  ]"
/>

---
layout: win95
windowTitle: "Week 06 — Ingress vs Gateway API"
windowIcon: "⚖"
statusText: "Week 06 · Role model shift"
---

## API Model Comparison

| Topic | Ingress | Gateway API |
|---|---|---|
| Core object | `Ingress` | `Gateway` + `HTTPRoute` |
| Ownership pattern | app team often does all | platform owns gateway, app owns routes |
| Multi-tenancy design | convention-heavy | first-class and explicit |

---
layout: win95-terminal
termTitle: "Command Prompt — week command highlights"
---

<Win95Terminal
  title="Command Prompt — week 06"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/heads/release-1.13/deploy/static/provider/kind/deploy.yaml' },
    { type: 'input', text: 'kubectl describe gateway cilium-gateway -n kube-system' },
    { type: 'input', text: 'kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f solution/network-policy.yaml' },
    { type: 'input', text: 'kubectl describe svc svc-demo-nodeport' },
    { type: 'input', text: 'kubectl -n kube-system logs deployment/coredns --tail=80' },
    { type: 'input', text: 'kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/calico.yaml' },
  ]"
/>
