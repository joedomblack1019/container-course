---
theme: default
title: Week 04 Lab 03 - Deploy to Dev via GitOps
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 03 · Deploy to Dev via GitOps"
---

# Deploy to Dev via GitOps
## Lab 03

- Push your app image to GHCR with `v4` tag
- Scaffold dev namespace manifests using `kubectl create --dry-run`
- Register Kustomize directory and open PR to `talos-gitops`
- Verify ArgoCD sync and `/info` response in dev namespace

---
layout: win95
windowTitle: "GitOps Model"
windowIcon: "🔄"
statusText: "Week 04 · Lab 03 · Git is source of truth"
---

## Flow Summary

| Step | Action |
|---|---|
| 1 | Push image to GHCR |
| 2 | Commit manifests to `talos-gitops` fork |
| 3 | Open PR to upstream `main` |
| 4 | ArgoCD syncs merged manifests |

> Deployments happen from repository state, not local `kubectl apply` to production.

---
layout: win95
windowTitle: "Kustomize Structure"
windowIcon: "🗂"
statusText: "Week 04 · Lab 03 · Student directory layout"
---

## Required Files

```text
student-infra/students/<YOUR_GITHUB_USERNAME>/
  kustomization.yaml
  dev/
    kustomization.yaml
    namespace.yaml
    deployment.yaml
    service.yaml
```

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - dev
```

---
layout: win95-terminal
termTitle: "Command Prompt — push image to GHCR"
---

<Win95Terminal
  title="Command Prompt — image publish"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd week-04/labs/lab-02-deploy-and-scale/starter' },
    { type: 'input', text: 'docker tag student-app:v4 ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4' },
    { type: 'input', text: 'echo $GITHUB_TOKEN | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin' },
    { type: 'input', text: 'echo &quot;ghp_YOUR_TOKEN_HERE&quot; | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin' },
    { type: 'input', text: 'docker push ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4' },
    { type: 'success', text: 'GHCR package pushed (set visibility to Public in GitHub UI)' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — fork, clone, branch"
---

<Win95Terminal
  title="Command Prompt — repo setup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd ~/' },
    { type: 'input', text: 'git clone https://github.com/<YOUR_GITHUB_USERNAME>/talos-gitops.git' },
    { type: 'input', text: 'cd talos-gitops' },
    { type: 'input', text: 'git checkout -b week04/<YOUR_GITHUB_USERNAME>' },
    { type: 'input', text: 'mkdir -p student-infra/students/<YOUR_GITHUB_USERNAME>/dev' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — scaffold manifests"
---

<Win95Terminal
  title="Command Prompt — kubectl dry-run scaffold"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd student-infra/students/<YOUR_GITHUB_USERNAME>/dev' },
    { type: 'input', text: 'kubectl create namespace student-<YOUR_GITHUB_USERNAME>-dev --dry-run=client -o yaml > namespace.yaml' },
    { type: 'input', text: 'kubectl create deployment student-app --image=ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4 --dry-run=client -o yaml > deployment.yaml' },
    { type: 'input', text: 'kubectl create service clusterip student-app-svc --tcp=80:5000 --dry-run=client -o yaml > service.yaml' },
    { type: 'comment', text: '# Edit files to add labels, env, probes, and limits' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — validate, commit, and verify"
---

<Win95Terminal
  title="Command Prompt — kustomize + PR"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/' },
    { type: 'input', text: 'cd ~/talos-gitops' },
    { type: 'input', text: 'git add student-infra/students/' },
    { type: 'input', text: 'git commit -m &quot;week04: add dev manifests for <YOUR_GITHUB_USERNAME>&quot;' },
    { type: 'input', text: 'git push origin week04/<YOUR_GITHUB_USERNAME>' },
    { type: 'input', text: 'kubectl get all -n student-<YOUR_GITHUB_USERNAME>-dev' },
    { type: 'input', text: 'kubectl port-forward -n student-<YOUR_GITHUB_USERNAME>-dev service/student-app-svc 8080:80 &' },
    { type: 'input', text: 'curl localhost:8080/info' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — final verification commands"
---

<Win95Terminal
  title="Command Prompt — post-merge checks"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-dev' },
    { type: 'input', text: 'kubectl logs deployment/student-app -n student-<YOUR_GITHUB_USERNAME>-dev' },
    { type: 'input', text: 'kill %1' },
    { type: 'success', text: 'Dev namespace running with namespace-derived ENVIRONMENT value' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 03 — Key Commands"
windowIcon: "📋"
statusText: "Week 04 · Lab 03 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `docker tag student-app:v4 ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4` | Tag image for GHCR |
| `echo $GITHUB_TOKEN | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin` | Login to GHCR |
| `echo "ghp_YOUR_TOKEN_HERE" | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin` | PAT-based GHCR login |
| `docker push ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4` | Push image |
| `git clone https://github.com/<YOUR_GITHUB_USERNAME>/talos-gitops.git` | Clone fork |
| `git checkout -b week04/<YOUR_GITHUB_USERNAME>` | Create branch |
| `mkdir -p student-infra/students/<YOUR_GITHUB_USERNAME>/dev` | Create directory structure |
| `kubectl create namespace ... --dry-run=client -o yaml > namespace.yaml` | Scaffold namespace manifest |
| `kubectl create deployment ... --dry-run=client -o yaml > deployment.yaml` | Scaffold deployment manifest |
| `kubectl create service clusterip ... --dry-run=client -o yaml > service.yaml` | Scaffold service manifest |
| `kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/` | Validate generated output |
| `git add student-infra/students/` | Stage changes |
| `git commit -m "week04: add dev manifests for <YOUR_GITHUB_USERNAME>"` | Commit manifests |
| `git push origin week04/<YOUR_GITHUB_USERNAME>` | Push branch |
| `kubectl get all -n student-<YOUR_GITHUB_USERNAME>-dev` | Check deployed resources |
| `kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-dev` | Check pod readiness |
| `kubectl logs deployment/student-app -n student-<YOUR_GITHUB_USERNAME>-dev` | Read deployment logs |
| `kubectl port-forward -n student-<YOUR_GITHUB_USERNAME>-dev service/student-app-svc 8080:80 &` | Forward service port |
| `curl localhost:8080/info` | Verify runtime metadata |
| `kill %1` | Stop port-forward job |

---
layout: win95
windowTitle: "GitOps Reconcile Flow"
windowIcon: "🔁"
statusText: "Week 04 · Lab 03 · PR to cluster sync"
---

## PR to Deployment Sequence

<ReconciliationSequence :active-step="5" title="GitOps Submission Flow" />
