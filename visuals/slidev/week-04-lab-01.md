---
theme: default
title: Week 04 Lab 01 - Create Your kind Cluster and Explore
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 01 · Create Your kind Cluster & Explore"
---

# Create Your kind Cluster & Explore
## Lab 01

- Create `kind-lab` and verify cluster control plane
- Practice essential `kubectl` discovery commands
- Connect to shared `ziyotek-prod` and inspect Week 1 apps
- Switch safely between local and shared contexts

---
layout: win95
windowTitle: "Two-Cluster Model"
windowIcon: "🧭"
statusText: "Week 04 · Lab 01 · local dev vs shared prod"
---

## Local and Shared Contexts

| Context | Usage | Access pattern |
|---|---|---|
| `kind-lab` | Experiment and break/fix locally | direct `kubectl apply/delete/scale` |
| `ziyotek-prod` | Observe shared deployment state | read-focused + GitOps flow |

> Always check current context before destructive commands.

---
layout: win95-terminal
termTitle: "Command Prompt — create and inspect kind cluster"
---

<Win95Terminal
  title="Command Prompt — kind bootstrap"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kind create cluster --name lab' },
    { type: 'output', text: 'Set kubectl context to &quot;kind-lab&quot;' },
    { type: 'input', text: 'kubectl cluster-info --context kind-lab' },
    { type: 'input', text: 'docker ps' },
    { type: 'input', text: 'kubectl get pods -n kube-system' },
    { type: 'success', text: 'control-plane components are running as pods' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — kubectl essentials"
---

<Win95Terminal
  title="Command Prompt — cluster discovery"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'kubectl describe node lab-control-plane' },
    { type: 'input', text: 'kubectl get namespaces' },
    { type: 'input', text: 'kubectl get pods -n kube-system' },
    { type: 'input', text: 'kubectl get all --all-namespaces' },
    { type: 'input', text: 'kubectl get pods -n kube-system -o wide' },
    { type: 'input', text: 'kubectl get pod -n kube-system -o name' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — output formats and node checks"
---

<Win95Terminal
  title="Command Prompt — api resources and events"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl get pod -n kube-system etcd-lab-control-plane -o yaml' },
    { type: 'input', text: 'kubectl get pod -n kube-system etcd-lab-control-plane -o jsonpath=\'{.status.phase}\'' },
    { type: 'input', text: 'kubectl api-resources' },
    { type: 'input', text: 'kubectl describe node lab-control-plane | grep -A 5 &quot;Capacity:&quot;' },
    { type: 'input', text: 'kubectl describe node lab-control-plane | grep &quot;Container Runtime&quot;' },
    { type: 'input', text: 'kubectl top pods -n kube-system 2>/dev/null || echo &quot;Metrics server not installed (expected for kind)&quot;' },
    { type: 'input', text: 'kubectl get events --all-namespaces --sort-by=.metadata.creationTimestamp' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — connect shared cluster"
---

<Win95Terminal
  title="Command Prompt — shared context setup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cloudflared access tcp --hostname kube.lab.shart.cloud --url localhost:6443 &' },
    { type: 'input', text: 'kubectl config set-cluster ziyotek-prod --server=https://localhost:6443 --insecure-skip-tls-verify=true' },
    { type: 'input', text: 'kubectl config set-credentials oidc --exec-api-version=client.authentication.k8s.io/v1beta1 --exec-command=kubectl --exec-arg=oidc-login --exec-arg=get-token --exec-arg=--oidc-issuer-url=https://argocd.lab.shart.cloud/api/dex --exec-arg=--oidc-client-id=kubernetes --exec-arg=--oidc-client-secret=hprtOl5JG85iadQL8AzCSkAdM15tRjZR --exec-arg=--oidc-extra-scope=email --exec-arg=--oidc-extra-scope=groups --exec-arg=--oidc-extra-scope=profile --exec-arg=--listen-address=localhost:8000' },
    { type: 'input', text: 'kubectl config set-context ziyotek-prod --cluster=ziyotek-prod --user=oidc' },
    { type: 'input', text: 'kubectl config use-context ziyotek-prod' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — inspect week-01 workloads and return"
---

<Win95Terminal
  title="Command Prompt — shared to local switch"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl get namespaces | grep container' },
    { type: 'input', text: 'kubectl get pods -n container-course-week01' },
    { type: 'input', text: 'kubectl get all -n container-course-week01' },
    { type: 'input', text: 'kubectl describe deployment student-<YOUR_USERNAME> -n container-course-week01' },
    { type: 'input', text: 'kubectl logs deployment/student-<YOUR_USERNAME> -n container-course-week01' },
    { type: 'input', text: 'kubectl get pods -n container-course-week01 -o custom-columns=NAME:.metadata.name,IMAGE:.spec.containers[0].image' },
    { type: 'input', text: 'kubectl config use-context kind-lab' },
    { type: 'input', text: 'kubectl config get-contexts' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — optional raw pod exploration"
---

<Win95Terminal
  title="Command Prompt — pod lifecycle demo"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config current-context' },
    { type: 'input', text: 'kubectl run test-nginx --image=nginx --port=80' },
    { type: 'input', text: 'kubectl get pods -w' },
    { type: 'input', text: 'kubectl describe pod test-nginx' },
    { type: 'input', text: 'kubectl delete pod test-nginx' },
    { type: 'success', text: 'bare pod deleted permanently (no controller)' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 01 — Key Commands"
windowIcon: "📋"
statusText: "Week 04 · Lab 01 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kind create cluster --name lab` | Create local kind cluster |
| `kubectl cluster-info --context kind-lab` | Verify API endpoint |
| `docker ps` | Show kind node container |
| `kubectl get pods -n kube-system` | List control-plane/system pods |
| `kubectl get nodes` | Show node readiness |
| `kubectl describe node lab-control-plane` | Show node details |
| `kubectl get namespaces` | List namespaces |
| `kubectl get all --all-namespaces` | List resources cluster-wide |
| `kubectl get pods -n kube-system -o wide` | Show pod IP/node placement |
| `kubectl get pod -n kube-system etcd-lab-control-plane -o yaml` | Full pod YAML |
| `kubectl get pod -n kube-system etcd-lab-control-plane -o name` | Pod name output |
| `kubectl get pod -n kube-system etcd-lab-control-plane -o jsonpath='{.status.phase}'` | Extract pod phase |
| `kubectl api-resources` | List Kubernetes resource types |
| `kubectl describe node lab-control-plane | grep -A 5 "Capacity:"` | Show CPU/memory capacity |
| `kubectl describe node lab-control-plane | grep "Container Runtime"` | Show runtime info |
| `kubectl top pods -n kube-system 2>/dev/null || echo "Metrics server not installed (expected for kind)"` | Optional metrics check |
| `kubectl get events --all-namespaces --sort-by=.metadata.creationTimestamp` | Chronological event stream |
| `cloudflared access tcp --hostname kube.lab.shart.cloud --url localhost:6443 &` | Start tunnel to shared cluster |
| `kubectl config set-cluster ...` | Add shared cluster endpoint |
| `kubectl config set-credentials ...` | Configure OIDC credential exec plugin |
| `kubectl config set-context ziyotek-prod --cluster=ziyotek-prod --user=oidc` | Create shared context |
| `kubectl config use-context ziyotek-prod` | Switch to shared cluster |
| `kubectl get namespaces | grep container` | Find container-course namespaces |
| `kubectl get pods -n container-course-week01` | View Week 1 pods |
| `kubectl get all -n container-course-week01` | View all Week 1 resources |
| `kubectl describe deployment student-<YOUR_USERNAME> -n container-course-week01` | Deployment details |
| `kubectl logs deployment/student-<YOUR_USERNAME> -n container-course-week01` | Deployment logs |
| `kubectl get pods -n container-course-week01 -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'` | Pod-to-image mapping |
| `kubectl config use-context kind-lab` | Return to local cluster |
| `kubectl config get-contexts` | List contexts |
| `kubectl config current-context` | Show active context |
| `kubectl run test-nginx --image=nginx --port=80` | Run raw test pod |
| `kubectl get pods -w` | Watch pod status |
| `kubectl describe pod test-nginx` | Inspect pod events |
| `kubectl delete pod test-nginx` | Delete test pod |
