---
theme: default
title: Week 08 Lab 03 - GitOps Loop and Revert
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "08"
lab: "Lab 03 · GitOps Loop + Revert"
---

# GitOps Loop + Revert

- Git is the **source of truth**
- ArgoCD reconciles drift automatically
- Rollback = `git revert` + push

---
layout: win95
windowTitle: "GitOps — Desired State Control Loop"
windowIcon: "🔄"
statusText: "Week 08 · Lab 03 · ArgoCD"
---

## Desired State Control Loop

<GitOpsLoopMap />

---
layout: win95
windowTitle: "GitOps Loop — Step 1: Commit a Change"
windowIcon: "🔄"
statusText: "git push origin main"
---

## Step 1: Commit a Change

<GitOpsLoopFlow :active-step="1" />

Update `k8s/base/configmap.yaml` and push to `main`.

---
layout: win95
windowTitle: "GitOps Loop — Step 2: Argo Detects Drift"
windowIcon: "🔄"
statusText: "ArgoCD: OutOfSync — target revision diverges from live state"
---

## Step 2: Argo Detects Drift

<GitOpsLoopFlow :active-step="2" />

Argo compares live state with rendered manifests from Git.

---
layout: win95
windowTitle: "GitOps Loop — Step 3: Sync Applies Desired State"
windowIcon: "🔄"
statusText: "ArgoCD: Syncing — applying kustomize output to cluster"
---

## Step 3: Sync Applies Desired State

<GitOpsLoopFlow :active-step="3" />

Cluster resources converge to the commit state.

---
layout: win95-terminal
termTitle: "Command Prompt — git revert · ArgoCD rollback"
---

## Step 4: Revert to Roll Back

<Win95Terminal
  title="Command Prompt — GitOps rollback"
  color="green"
  :crt="true"
  height="340px"
  :lines="[
    { type: 'comment', text: '# Bad deploy detected — ArgoCD shows degraded health' },
    { type: 'input',  text: 'git log --oneline -4' },
    { type: 'output', text: 'a3f91c2 feat: bump replicas to 10  ← BAD' },
    { type: 'output', text: '7b2e4d1 fix: update configmap value' },
    { type: 'output', text: '3c8a901 chore: bump chart version' },
    { type: 'output', text: '1d0f234 feat: initial deployment' },
    { type: 'comment', text: '# Revert the bad commit' },
    { type: 'input',  text: 'git revert a3f91c2 --no-edit' },
    { type: 'output', text: '[main f4e2b9a] Revert: feat: bump replicas to 10' },
    { type: 'output', text: ' 1 file changed, 1 insertion(+), 1 deletion(-)' },
    { type: 'input',  text: 'git push origin main' },
    { type: 'success', text: 'ArgoCD detects new commit — syncing...' },
    { type: 'success', text: 'Health: Healthy ✓  Sync: Synced ✓' },
  ]"
/>
