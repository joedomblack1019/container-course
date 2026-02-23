---
theme: default
title: Week 08 Lab 01 - Install ArgoCD on kind with Helm
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "08"
lab: "Lab 01 · Install ArgoCD on kind"
---

# Install ArgoCD on kind with Helm
## Lab 01

- Prepare local cluster and fork portfolio template repo
- Install ArgoCD with Helm values tuned for local labs
- Access UI through port-forward and retrieve admin password
- Verify core components before GitOps app onboarding

---
layout: win95
windowTitle: "ArgoCD Components"
windowIcon: "📦"
statusText: "Week 08 · Lab 01 · Core control loop services"
---

## What Runs in `argocd` Namespace

| Component | Function |
|---|---|
| API server | UI and API endpoint |
| Repo server | Clone/render (`kustomize build`) |
| Application controller | Diff + sync loop |
| Redis | Internal cache/state support |

---
layout: win95-terminal
termTitle: "Command Prompt — prerequisites and repo prep"
---

<Win95Terminal
  title="Command Prompt — setup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kind version' },
    { type: 'input', text: 'helm version' },
    { type: 'input', text: 'kubectl cluster-info' },
    { type: 'input', text: 'kind create cluster --name lab' },
    { type: 'input', text: 'gh repo clone <YOUR_GITHUB_USERNAME>/container-devsecops-template' },
    { type: 'input', text: 'cd container-devsecops-template' },
    { type: 'success', text: 'Enable workflows in GitHub Actions tab if prompted' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — install ArgoCD and access UI"
---

<Win95Terminal
  title="Command Prompt — argo install"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'helm repo add argo https://argoproj.github.io/argo-helm' },
    { type: 'input', text: 'helm repo update' },
    { type: 'input', text: 'helm install argocd argo/argo-cd --namespace argocd --create-namespace -f starter/values.yaml' },
    { type: 'input', text: 'kubectl get pods -n argocd -w' },
    { type: 'input', text: 'kubectl port-forward service/argocd-server -n argocd 8080:443 &' },
    { type: 'input', text: 'kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath=\'{.data.password}\' | base64 -d && echo' },
    { type: 'success', text: 'Login: admin / <decoded password> at http://localhost:8080' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 01 — Key Commands"
windowIcon: "📋"
statusText: "Week 08 · Lab 01 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kind version` | Verify kind binary |
| `helm version` | Verify Helm installation |
| `kubectl cluster-info` | Verify cluster connectivity |
| `kind create cluster --name lab` | Create lab cluster |
| `gh repo clone <YOUR_GITHUB_USERNAME>/container-devsecops-template` | Clone portfolio fork |
| `helm repo add argo https://argoproj.github.io/argo-helm` | Add Argo Helm repo |
| `helm repo update` | Refresh chart index |
| `helm install argocd argo/argo-cd --namespace argocd --create-namespace -f starter/values.yaml` | Install ArgoCD chart |
| `kubectl get pods -n argocd -w` | Watch ArgoCD pods become ready |
| `kubectl port-forward service/argocd-server -n argocd 8080:443 &` | Access local UI |
| `kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d && echo` | Decode initial admin password |
