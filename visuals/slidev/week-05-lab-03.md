---
theme: default
title: Week 05 Lab 03 - Ship Redis to Production
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "05"
lab: "Lab 03 · Ship Redis to Production"
---

# Ship Redis to Production
## Lab 03

- Push `course-app:v5` to GHCR and sync your `talos-gitops` fork
- Update app deployment for Redis-backed configuration
- Add Redis manifests to `dev/` and `prod/` overlays
- Validate with `kubectl kustomize` and submit PR for ArgoCD sync

---
layout: win95
windowTitle: "GitOps Directory Delta"
windowIcon: "📁"
statusText: "Week 05 · Lab 03 · Week 4 to Week 5 changes"
---

## Added Resources per Environment

| New file | Purpose |
|---|---|
| `app-config.yaml` | Redis connection settings |
| `redis-secret.yaml` | Redis password |
| `redis-configmap.yaml` | `redis.conf` content |
| `redis-statefulset.yaml` | Redis pod + PVC lifecycle |
| `redis-service.yaml` | Headless service endpoint |

---
layout: win95
windowTitle: "Deployment v5 Changes"
windowIcon: "📄"
statusText: "Week 05 · Lab 03 · App wiring updates"
---

## Update in `dev/deployment.yaml` and `prod/deployment.yaml`

```yaml
image: ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v5
envFrom:
- configMapRef:
    name: app-config
env:
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: redis-credentials
      key: REDIS_PASSWORD
- name: APP_VERSION
  value: "v5"
```

---
layout: win95-terminal
termTitle: "Command Prompt — image push and fork sync"
---

<Win95Terminal
  title="Command Prompt — GHCR + git prep"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd ~/container-course/week-05/labs/lab-02-configmaps-and-wiring/starter' },
    { type: 'input', text: 'docker tag course-app:v5 ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v5' },
    { type: 'input', text: 'echo $GITHUB_TOKEN | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin' },
    { type: 'input', text: 'docker push ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v5' },
    { type: 'input', text: 'cd ~/talos-gitops; git checkout main; git remote add upstream https://github.com/ziyotek-edu/talos-gitops.git 2>/dev/null' },
    { type: 'input', text: 'git fetch upstream; git merge upstream/main; git push origin main; git checkout -b week05/<YOUR_GITHUB_USERNAME>' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — create config and redis files"
---

<Win95Terminal
  title="Command Prompt — manifest additions"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cp dev/app-config.yaml prod/app-config.yaml' },
    { type: 'input', text: 'cp dev/redis-secret.yaml prod/redis-secret.yaml' },
    { type: 'input', text: 'cp dev/redis-configmap.yaml prod/redis-configmap.yaml' },
    { type: 'input', text: 'cp dev/redis-statefulset.yaml prod/redis-statefulset.yaml' },
    { type: 'input', text: 'cp dev/redis-service.yaml prod/redis-service.yaml' },
    { type: 'comment', text: '# Update both kustomization.yaml files with 8 resources each' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — validate, commit, and verify"
---

<Win95Terminal
  title="Command Prompt — PR workflow"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd ~/talos-gitops' },
    { type: 'input', text: 'kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/' },
    { type: 'input', text: 'kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/ | grep &quot;^kind:&quot; | sort | uniq -c' },
    { type: 'input', text: 'kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/ | grep -E &quot;^kind:|^  name:|^  namespace:&quot; | head -48' },
    { type: 'input', text: 'git add student-infra/students/<YOUR_GITHUB_USERNAME>/; git commit -m &quot;week05: add redis backing service for <YOUR_GITHUB_USERNAME>&quot;; git push origin week05/<YOUR_GITHUB_USERNAME>' },
    { type: 'input', text: 'kubectl config use-context ziyotek-prod; kubectl get all -n student-<YOUR_GITHUB_USERNAME>-dev' },
    { type: 'input', text: 'kubectl get pvc -n student-<YOUR_GITHUB_USERNAME>-dev; kubectl get configmap,secret -n student-<YOUR_GITHUB_USERNAME>-dev' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — runtime checks and debugging"
---

<Win95Terminal
  title="Command Prompt — post-merge validation"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'curl -s https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/info | python3 -m json.tool' },
    { type: 'input', text: 'curl -s https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/visits | python3 -m json.tool' },
    { type: 'input', text: 'kubectl port-forward -n student-<YOUR_GITHUB_USERNAME>-dev service/student-app-svc 8080:80 &' },
    { type: 'input', text: 'curl -s http://localhost:8080/visits | python3 -m json.tool' },
    { type: 'input', text: 'kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-dev -l app=redis' },
    { type: 'input', text: 'kubectl logs redis-0 -n student-<YOUR_GITHUB_USERNAME>-dev' },
    { type: 'input', text: 'kubectl logs deployment/student-app -n student-<YOUR_GITHUB_USERNAME>-dev' },
    { type: 'input', text: 'kill %1' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 03 — Key Commands"
windowIcon: "📋"
statusText: "Week 05 · Lab 03 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `docker tag course-app:v5 ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v5` | Tag v5 image for GHCR |
| `docker push ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v5` | Push v5 image |
| `git fetch upstream` | Pull latest upstream refs |
| `git merge upstream/main` | Sync local main with upstream |
| `git checkout -b week05/<YOUR_GITHUB_USERNAME>` | Create Week 5 branch |
| `cp dev/*.yaml prod/*.yaml` | Copy new dev resources into prod overlay |
| `kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/` | Validate rendered manifests |
| `kubectl kustomize ... | grep "^kind:" | sort | uniq -c` | Count rendered resource kinds |
| `git add student-infra/students/<YOUR_GITHUB_USERNAME>/` | Stage GitOps changes |
| `git commit -m "week05: add redis backing service for <YOUR_GITHUB_USERNAME>"` | Commit changes |
| `git push origin week05/<YOUR_GITHUB_USERNAME>` | Push PR branch |
| `kubectl config use-context ziyotek-prod` | Switch to shared cluster |
| `kubectl get all -n student-<YOUR_GITHUB_USERNAME>-dev` | Verify dev resources |
| `kubectl get pvc -n student-<YOUR_GITHUB_USERNAME>-dev` | Verify Redis PVC |
| `kubectl get configmap,secret -n student-<YOUR_GITHUB_USERNAME>-dev` | Verify app/Redis config objects |
| `curl -s https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/visits | python3 -m json.tool` | Verify incrementing counter |
| `kubectl port-forward -n student-<YOUR_GITHUB_USERNAME>-dev service/student-app-svc 8080:80 &` | Local verification fallback |
| `kubectl logs deployment/student-app -n student-<YOUR_GITHUB_USERNAME>-dev` | App-side troubleshooting |

---
layout: win95
windowTitle: "GitOps Sync Flow"
windowIcon: "🔁"
statusText: "Week 05 · Lab 03 · Merge to reconcile"
---

## Merge-Driven Deployment

<ReconciliationSequence :active-step="6" title="PR Merge to ArgoCD Sync" />
