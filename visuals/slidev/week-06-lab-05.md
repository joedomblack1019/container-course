---
theme: default
title: Week 06 Lab 05 - CoreDNS Troubleshooting Sprint
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "06"
lab: "Lab 05 · CoreDNS Troubleshooting Sprint"
---

# CoreDNS Troubleshooting Sprint
## Lab 05

- Capture healthy DNS baseline from probe pod
- Inject CoreDNS forwarding failure in local kind cluster
- Triage with pod logs, ConfigMap, and events evidence
- Restore CoreDNS config and verify recovery

---
layout: win95
windowTitle: "DNS Failure Signals"
windowIcon: "🧠"
statusText: "Week 06 · Lab 05 · Incident recognition"
---

## Why DNS Outages Are Tricky

- Pods often stay `Running`, so failures look like app bugs
- Service-name lookups fail even when deployments are healthy
- Fastest check: resolve `kubernetes.default.svc.cluster.local` from a pod

---
layout: win95-terminal
termTitle: "Command Prompt — baseline and fault injection"
---

<Win95Terminal
  title="Command Prompt — baseline DNS"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config use-context kind-lab' },
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'kubectl apply -f week-06/labs/lab-05-coredns-troubleshooting/starter/dns-probe-pod.yaml' },
    { type: 'input', text: 'kubectl wait --for=condition=Ready pod/dns-probe --timeout=60s' },
    { type: 'input', text: 'kubectl exec dns-probe -- nslookup kubernetes.default.svc.cluster.local' },
    { type: 'input', text: 'kubectl exec dns-probe -- nslookup svc-demo-clusterip.default.svc.cluster.local || true' },
    { type: 'input', text: 'bash week-06/labs/lab-05-coredns-troubleshooting/starter/inject-coredns-failure.sh' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — triage and restore"
---

<Win95Terminal
  title="Command Prompt — incident workflow"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl exec dns-probe -- nslookup kubernetes.default.svc.cluster.local || true' },
    { type: 'input', text: 'kubectl -n kube-system get pods -l k8s-app=kube-dns' },
    { type: 'input', text: 'kubectl -n kube-system logs deployment/coredns --tail=80' },
    { type: 'input', text: 'kubectl -n kube-system get configmap coredns -o yaml' },
    { type: 'input', text: 'kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -40' },
    { type: 'input', text: 'bash week-06/labs/lab-05-coredns-troubleshooting/starter/restore-coredns.sh' },
    { type: 'input', text: 'kubectl -n kube-system rollout status deployment/coredns --timeout=120s' },
    { type: 'input', text: 'kubectl exec dns-probe -- nslookup kubernetes.default.svc.cluster.local' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — cleanup"
---

<Win95Terminal
  title="Command Prompt — post-incident cleanup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl delete pod dns-probe --ignore-not-found' },
    { type: 'input', text: 'rm -f /tmp/coredns-backup.yaml' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 05 — Key Commands"
windowIcon: "📋"
statusText: "Week 06 · Lab 05 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl apply -f week-06/labs/lab-05-coredns-troubleshooting/starter/dns-probe-pod.yaml` | Create DNS probe pod |
| `kubectl wait --for=condition=Ready pod/dns-probe --timeout=60s` | Wait for probe readiness |
| `kubectl exec dns-probe -- nslookup kubernetes.default.svc.cluster.local` | Baseline/verify core service DNS |
| `bash week-06/labs/lab-05-coredns-troubleshooting/starter/inject-coredns-failure.sh` | Inject CoreDNS config failure |
| `kubectl -n kube-system get pods -l k8s-app=kube-dns` | Check CoreDNS pod state |
| `kubectl -n kube-system logs deployment/coredns --tail=80` | Inspect CoreDNS runtime errors |
| `kubectl -n kube-system get configmap coredns -o yaml` | Inspect Corefile source |
| `kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -40` | Collect event evidence |
| `bash week-06/labs/lab-05-coredns-troubleshooting/starter/restore-coredns.sh` | Restore CoreDNS configuration |
| `kubectl -n kube-system rollout status deployment/coredns --timeout=120s` | Confirm CoreDNS recovery |
| `kubectl delete pod dns-probe --ignore-not-found` | Cleanup probe pod |
| `rm -f /tmp/coredns-backup.yaml` | Remove backup artifact |
