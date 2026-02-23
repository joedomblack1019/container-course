---
theme: default
title: Week 08 Lab 03 - The GitOps Loop and Revert
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "08"
lab: "Lab 03 · The GitOps Loop + Revert"
---

# The GitOps Loop + Revert
## Lab 03

- Connect ArgoCD Application to your forked portfolio repo
- Trigger auto-sync from Git commit changes
- Intentionally break deployment with bad image tag
- Learn why UI rollback fails and `git revert` is the real fix

---
layout: win95
windowTitle: "GitOps Reconciliation"
windowIcon: "🔁"
statusText: "Week 08 · Lab 03 · Push to sync"
---

## Sync Lifecycle

<ReconciliationSequence :active-step="6" title="Git Commit to Cluster Sync" />

---
layout: win95-terminal
termTitle: "Command Prompt — baseline and portfolio personalization"
---

<Win95Terminal
  title="Command Prompt — prepare source"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl get pods -n argocd' },
    { type: 'input', text: 'kubectl port-forward service/argocd-server -n argocd 8080:443 &' },
    { type: 'input', text: 'cd container-devsecops-template' },
    { type: 'input', text: 'git add k8s/base/configmap.yaml' },
    { type: 'input', text: 'git commit -m &quot;personalize portfolio config&quot;' },
    { type: 'input', text: 'git push' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — create application and verify sync"
---

<Win95Terminal
  title="Command Prompt — first sync"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cp <path-to-this-lab>/starter/application.yaml argocd/application.yaml' },
    { type: 'input', text: 'kubectl apply -f argocd/application.yaml' },
    { type: 'input', text: 'kubectl get pods -n portfolio -w' },
    { type: 'input', text: 'kubectl port-forward -n portfolio service/portfolio-svc 5001:80 &' },
    { type: 'input', text: 'curl -s http://localhost:5001 | head' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — break deployment and recover correctly"
---

<Win95Terminal
  title="Command Prompt — bad tag drill"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'git add k8s/base/kustomization.yaml' },
    { type: 'input', text: 'git commit -m &quot;break: use nonexistent image tag&quot;' },
    { type: 'input', text: 'git push' },
    { type: 'error', text: 'Expected: portfolio pod enters ImagePullBackOff; app Degraded' },
    { type: 'comment', text: '# UI rollback appears to fix temporarily, then auto-sync re-breaks' },
    { type: 'input', text: 'git revert HEAD --no-edit' },
    { type: 'input', text: 'git push' },
    { type: 'success', text: 'Expected: permanent recovery after ArgoCD re-sync' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 03 — Key Commands"
windowIcon: "📋"
statusText: "Week 08 · Lab 03 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl port-forward service/argocd-server -n argocd 8080:443 &` | Access ArgoCD UI |
| `git add k8s/base/configmap.yaml && git commit -m "personalize portfolio config" && git push` | Trigger visible app content update |
| `kubectl apply -f argocd/application.yaml` | Create ArgoCD Application object |
| `kubectl get pods -n portfolio -w` | Watch portfolio workload rollout |
| `kubectl port-forward -n portfolio service/portfolio-svc 5001:80 &` | Access portfolio service locally |
| `git add k8s/base/kustomization.yaml && git commit -m "break: use nonexistent image tag" && git push` | Inject deployment failure via source |
| `git revert HEAD --no-edit && git push` | Perform correct GitOps rollback |
| `kubectl delete application portfolio -n argocd` | Optional cleanup with prune |
