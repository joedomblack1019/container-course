---
theme: default
title: Week 08 - GitOps with ArgoCD and DevSecOps Pipeline
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "08"
lab: "Week 08 · GitOps + DevSecOps"
---

# GitOps + DevSecOps
## Week 08

- Install and operate ArgoCD on your own kind cluster
- Understand and run an 8-stage fail-fast CI security pipeline
- Close the GitOps loop: push, sync, break, and recover with `git revert`

---
layout: win95
windowTitle: "Week 08 — Lab Roadmap"
windowIcon: "🗺"
statusText: "Week 08 · Six labs"
---

## Lab Sequence

<Win95TaskManager
  title="Week 08 — Lab Queue"
  tab="Pods"
  status-text="6 labs queued"
  :show-namespace="false"
  :processes="[
    { name: 'lab-01-argocd-install',                      pid: 1, cpu: 0, memory: '40 min', status: 'Running' },
    { name: 'lab-02-ci-pipeline-tools',                   pid: 2, cpu: 0, memory: '50 min', status: 'Pending' },
    { name: 'lab-03-gitops-loop',                         pid: 3, cpu: 0, memory: '40 min', status: 'Pending' },
    { name: 'lab-04-vault-integration',                   pid: 4, cpu: 0, memory: '30 min', status: 'Pending' },
    { name: 'lab-05-cluster-component-troubleshooting',   pid: 5, cpu: 0, memory: '60 min', status: 'Pending' },
    { name: 'lab-06-ha-control-plane-design',             pid: 6, cpu: 0, memory: '40 min', status: 'Pending' }
  ]"
/>

---
layout: win95
windowTitle: "Week 08 — GitOps Rule"
windowIcon: "🔁"
statusText: "Week 08 · Source of truth"
---

## Core Principle

<Win95Dialog
  type="warning"
  title="Rollback Reality"
  message="In GitOps, rollback means reverting the commit in Git."
  detail="UI rollback is temporary when auto-sync is enabled; ArgoCD re-applies whatever is in the repo on next reconciliation."
  :buttons="['Understood']"
  :active-button="0"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — week 08 highlights"
---

<Win95Terminal
  title="Command Prompt — week 08"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'helm install argocd argo/argo-cd --namespace argocd --create-namespace -f starter/values.yaml' },
    { type: 'input', text: 'ruff check app/ && bandit -r app/' },
    { type: 'input', text: 'hadolint app/Dockerfile && trivy config app/' },
    { type: 'input', text: 'kubectl apply -f argocd/application.yaml' },
    { type: 'input', text: 'git revert HEAD --no-edit && git push' },
    { type: 'input', text: 'docker stop ha-control-plane2 && kubectl get nodes' },
  ]"
/>
