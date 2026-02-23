---
theme: default
title: Week 08 Lab 02 - CI/CD Pipeline Deep Dive
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "08"
lab: "Lab 02 · CI/CD Pipeline Deep Dive"
---

# CI/CD Pipeline Deep Dive
## Lab 02

- Read and map the 8-stage fail-fast pipeline graph
- Run ruff, bandit, hadolint, trivy, and kubeconform locally
- Inject controlled failures and verify each gate catches them
- Push commit and observe full GitHub Actions execution

---
layout: win95
windowTitle: "8-Stage Pipeline"
windowIcon: "🧪"
statusText: "Week 08 · Lab 02 · Fail-fast ordering"
---

## Stages and Dependency Flow

| Stage | Job |
|---|---|
| 1 | `code-quality` |
| 2 | `dockerfile-scan` |
| 3 | `build` |
| 4 | `container-scan` |
| 5 | `push` |
| 6 | `k8s-validate` |
| 7 | `integration-test` |
| 8 | `update-tag` |

---
layout: win95-terminal
termTitle: "Command Prompt — code quality and SAST"
---

<Win95Terminal
  title="Command Prompt — stage 1 tools"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd container-devsecops-template' },
    { type: 'input', text: 'pip install ruff bandit' },
    { type: 'input', text: 'ruff check app/' },
    { type: 'input', text: 'bandit -r app/' },
    { type: 'comment', text: '# Add eval(&quot;1 + 1&quot;) in app/app.py intentionally, then rerun bandit' },
    { type: 'input', text: 'bandit -r app/' },
    { type: 'input', text: 'git checkout app/app.py' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — Dockerfile and image scanning"
---

<Win95Terminal
  title="Command Prompt — stages 2-4"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'curl -sL https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -o hadolint && chmod +x hadolint && sudo mv hadolint /usr/local/bin/' },
    { type: 'input', text: 'hadolint app/Dockerfile' },
    { type: 'input', text: 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin' },
    { type: 'input', text: 'trivy config app/' },
    { type: 'comment', text: '# Change USER appuser -> USER root in Dockerfile intentionally, rerun checks' },
    { type: 'input', text: 'hadolint app/Dockerfile && trivy config app/' },
    { type: 'input', text: 'git checkout app/Dockerfile' },
    { type: 'input', text: 'docker build -t portfolio-test app/ && trivy image --severity CRITICAL,HIGH --exit-code 1 portfolio-test' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — manifest validation and CI run"
---

<Win95Terminal
  title="Command Prompt — stages 6-8"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'curl -sL https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz | tar xz && sudo mv kubeconform /usr/local/bin/' },
    { type: 'input', text: 'kubectl kustomize k8s/overlays/local | kubeconform -strict -ignore-missing-schemas -summary' },
    { type: 'comment', text: '# Break apiVersion apps/v1 -> apps/v999 intentionally, then validate again' },
    { type: 'input', text: 'kubectl kustomize k8s/overlays/local | kubeconform -strict -ignore-missing-schemas -summary' },
    { type: 'input', text: 'git checkout k8s/base/deployment.yaml' },
    { type: 'input', text: 'git add k8s/base/configmap.yaml && git commit -m &quot;personalize bio&quot; && git push' },
    { type: 'success', text: 'Watch Actions tab for full pipeline execution' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 02 — Key Commands"
windowIcon: "📋"
statusText: "Week 08 · Lab 02 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `ruff check app/` | Python lint check |
| `bandit -r app/` | Python security static analysis |
| `hadolint app/Dockerfile` | Dockerfile best-practice lint |
| `trivy config app/` | Misconfiguration scan for IaC/Dockerfile |
| `docker build -t portfolio-test app/` | Build test image |
| `trivy image --severity CRITICAL,HIGH --exit-code 1 portfolio-test` | CVE gate for image |
| `kubectl kustomize k8s/overlays/local | kubeconform -strict -ignore-missing-schemas -summary` | Validate rendered Kubernetes manifests |
| `git checkout app/app.py` | Revert intentional bandit failure change |
| `git checkout app/Dockerfile` | Revert intentional Dockerfile security change |
| `git checkout k8s/base/deployment.yaml` | Revert intentional schema failure change |
| `git add k8s/base/configmap.yaml && git commit -m "personalize bio" && git push` | Trigger CI pipeline on fork |
