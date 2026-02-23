---
theme: default
title: Week 07 Lab 04 - Node Lifecycle and Upgrade Planning
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "07"
lab: "Lab 04 · Node Lifecycle and Upgrade Planning"
---

# Node Lifecycle and Upgrade Planning
## Lab 04

- Practice `cordon`, `drain`, and `uncordon` workflows safely
- Reproduce PDB-blocked drain and capture evidence
- Build upgrade checklist with kubeadm version-skew rules
- Complete jsonpath/output-formatting verification drills

---
layout: win95
windowTitle: "Maintenance Workflow"
windowIcon: "🛠"
statusText: "Week 07 · Lab 04 · Safe node operations"
---

## Lifecycle Sequence

```text
cordon node -> drain with eviction checks -> perform maintenance
-> uncordon node -> verify scheduling restored
```

> Drain uses Eviction API, so PodDisruptionBudgets can block unsafe disruption.

---
layout: win95-terminal
termTitle: "Command Prompt — create ops cluster and baseline workload"
---

<Win95Terminal
  title="Command Prompt — cluster setup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cat <<\'EOF\' > /tmp/kind-ops.yaml' },
    { type: 'input', text: 'kind: Cluster  # name: ops with control-plane + 2 workers' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kind create cluster --name ops --config /tmp/kind-ops.yaml' },
    { type: 'input', text: 'kubectl config use-context kind-ops' },
    { type: 'input', text: 'kubectl get nodes -o wide' },
    { type: 'input', text: 'kubectl create namespace ops-lab' },
    { type: 'input', text: 'kubectl -n ops-lab apply -f - <<\'EOF\'  # deployment web + pdb minAvailable:2' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — cordon drain failure and safe unblock"
---

<Win95Terminal
  title="Command Prompt — disruption triage"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'WORKER=&quot;$(kubectl get nodes -o name | grep worker | head -1 | cut -d/ -f2)&quot;' },
    { type: 'input', text: 'kubectl cordon &quot;$WORKER&quot;' },
    { type: 'input', text: 'kubectl drain &quot;$WORKER&quot; --ignore-daemonsets --delete-emptydir-data --timeout=60s' },
    { type: 'input', text: 'kubectl -n ops-lab get events --sort-by=.metadata.creationTimestamp | tail -20' },
    { type: 'input', text: 'kubectl -n ops-lab describe pdb web-pdb' },
    { type: 'input', text: 'kubectl -n ops-lab patch pdb web-pdb --type merge -p \'{&quot;spec&quot;:{&quot;minAvailable&quot;:1}}\'' },
    { type: 'input', text: 'kubectl drain &quot;$WORKER&quot; --ignore-daemonsets --delete-emptydir-data --timeout=120s' },
    { type: 'input', text: 'kubectl uncordon &quot;$WORKER&quot;' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — upgrade planning signals and simulation"
---

<Win95Terminal
  title="Command Prompt — upgrade checklist"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl version' },
    { type: 'input', text: 'kubectl get nodes -o custom-columns=NAME:.metadata.name,KUBELET:.status.nodeInfo.kubeletVersion' },
    { type: 'input', text: 'docker exec ops-control-plane kubeadm version' },
    { type: 'input', text: 'docker exec ops-control-plane kubeadm upgrade plan || true' },
    { type: 'input', text: 'WORKER=$(kubectl get nodes -o name | grep worker | head -1 | cut -d/ -f2)' },
    { type: 'input', text: 'kubectl drain $WORKER --ignore-daemonsets --delete-emptydir-data' },
    { type: 'input', text: 'kubectl uncordon $WORKER' },
    { type: 'input', text: 'cp starter/upgrade-runbook-template.md ./upgrade-runbook.md' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — jsonpath check and cleanup"
---

<Win95Terminal
  title="Command Prompt — final validations"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cp starter/jsonpath-check.txt ./jsonpath-check.txt' },
    { type: 'input', text: 'bash starter/validate-jsonpath-check.sh ./jsonpath-check.txt' },
    { type: 'input', text: 'kubectl describe node &quot;$WORKER&quot;' },
    { type: 'input', text: 'kubectl -n ops-lab get pdb' },
    { type: 'input', text: 'kubectl -n ops-lab get events --sort-by=.metadata.creationTimestamp | tail -30' },
    { type: 'input', text: 'kubectl config use-context kind-lab || true' },
    { type: 'input', text: 'kind delete cluster --name ops' },
    { type: 'input', text: 'rm -f /tmp/kind-ops.yaml' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 04 — Key Commands"
windowIcon: "📋"
statusText: "Week 07 · Lab 04 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kind create cluster --name ops --config /tmp/kind-ops.yaml` | Create multi-node ops cluster |
| `kubectl cordon "$WORKER"` | Disable scheduling on node |
| `kubectl drain "$WORKER" --ignore-daemonsets --delete-emptydir-data --timeout=60s` | Attempt workload eviction for maintenance |
| `kubectl -n ops-lab describe pdb web-pdb` | Inspect disruption constraints |
| `kubectl -n ops-lab patch pdb web-pdb --type merge -p '{"spec":{"minAvailable":1}}'` | Relax PDB to allow one disruption |
| `kubectl uncordon "$WORKER"` | Re-enable scheduling |
| `docker exec ops-control-plane kubeadm upgrade plan` | Show possible upgrade targets |
| `kubectl get nodes -o custom-columns=NAME:.metadata.name,KUBELET:.status.nodeInfo.kubeletVersion` | Capture node kubelet versions |
| `cp starter/upgrade-runbook-template.md ./upgrade-runbook.md` | Create runbook draft |
| `bash starter/validate-jsonpath-check.sh ./jsonpath-check.txt` | Grade output-formatting/jsonpath answers |
| `kind delete cluster --name ops` | Cleanup lab cluster |
