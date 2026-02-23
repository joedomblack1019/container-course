---
theme: default
title: Week 06 Lab 01 - Ingress in kind
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "06"
lab: "Lab 01 · Ingress in kind"
---

# Ingress in kind
## Lab 01

- Recreate kind with host port mapping for `80/443`
- Install nginx ingress controller and verify IngressClass
- Route `app.local` and `status.local` to two Services
- Trace end-to-end request path from host header to pod

---
layout: win95
windowTitle: "Ingress Model"
windowIcon: "🚪"
statusText: "Week 06 · Lab 01 · Host-based routing"
---

## Ingress Resource + Controller

| Piece | Role |
|---|---|
| `Ingress` | Routing rules (`host`, `path`, backend `Service`) |
| nginx ingress controller | Watches Ingress objects and proxies traffic |

```text
app.local    -> Ingress rule -> Service course-app
status.local -> Ingress rule -> Service uptime-kuma
```

---
layout: win95-terminal
termTitle: "Command Prompt — recreate kind and install controller"
---

<Win95Terminal
  title="Command Prompt — ingress bootstrap"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kind delete cluster --name lab' },
    { type: 'input', text: 'kind create cluster --name lab --config week-06/labs/lab-01-ingress-kind/starter/kind-config.yaml' },
    { type: 'input', text: 'kubectl config use-context kind-lab' },
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/heads/release-1.13/deploy/static/provider/kind/deploy.yaml' },
    { type: 'input', text: 'kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=180s' },
    { type: 'input', text: 'kubectl get ingressclass' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — controller scheduling patch"
---

<Win95Terminal
  title="Command Prompt — control-plane pin"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl patch deployment ingress-nginx-controller -n ingress-nginx --type merge -p \'{&quot;spec&quot;:{&quot;template&quot;:{&quot;spec&quot;:{&quot;nodeSelector&quot;:{&quot;ingress-ready&quot;:&quot;true&quot;}}}}}\'' },
    { type: 'input', text: 'kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx' },
    { type: 'input', text: 'kubectl get pod -n ingress-nginx -o wide' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — deploy app, Redis, and Uptime Kuma"
---

<Win95Terminal
  title="Command Prompt — backend services"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker build -t course-app:v5 week-05/labs/lab-02-configmaps-and-wiring/starter' },
    { type: 'input', text: 'kind load docker-image course-app:v5 --name lab' },
    { type: 'input', text: 'kubectl apply -f week-05/labs/lab-01-helm-redis-and-vault/solution/redis-secret.yaml' },
    { type: 'input', text: 'kubectl apply -f week-05/labs/lab-01-helm-redis-and-vault/solution/redis-configmap.yaml' },
    { type: 'input', text: 'kubectl apply -f week-05/labs/lab-02-configmaps-and-wiring/solution/deployment.yaml' },
    { type: 'input', text: 'kubectl apply -f week-05/labs/lab-02-configmaps-and-wiring/solution/service.yaml' },
    { type: 'input', text: 'helm repo add uptime-kuma https://dirsigler.github.io/uptime-kuma-helm; helm repo update' },
    { type: 'input', text: 'helm install uptime-kuma uptime-kuma/uptime-kuma -f week-06/labs/lab-01-ingress-kind/starter/uptime-kuma-values.yaml' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — ingress rules and host routing tests"
---

<Win95Terminal
  title="Command Prompt — host-based routing"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f - <<\'EOF\'' },
    { type: 'input', text: 'kind: Ingress  # course-app host app.local -> service course-app:80' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl apply -f - <<\'EOF\'' },
    { type: 'input', text: 'kind: Ingress  # uptime-kuma host status.local -> service uptime-kuma:3001' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl get ingress' },
    { type: 'input', text: 'curl -H &quot;Host: app.local&quot; http://127.0.0.1/ | head' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — validation and cleanup"
---

<Win95Terminal
  title="Command Prompt — final checks"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'curl -H &quot;Host: app.local&quot; http://127.0.0.1/visits | python3 -m json.tool' },
    { type: 'input', text: 'curl -H &quot;Host: status.local&quot; http://127.0.0.1/ | head' },
    { type: 'input', text: 'kind delete cluster --name lab' },
    { type: 'input', text: 'kubectl config get-contexts' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 01 — Key Commands"
windowIcon: "📋"
statusText: "Week 06 · Lab 01 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kind create cluster --name lab --config week-06/labs/lab-01-ingress-kind/starter/kind-config.yaml` | Create ingress-ready kind cluster |
| `kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/heads/release-1.13/deploy/static/provider/kind/deploy.yaml` | Install nginx ingress controller |
| `kubectl wait ... --selector=app.kubernetes.io/component=controller` | Wait for controller readiness |
| `kubectl patch deployment ingress-nginx-controller ... nodeSelector ...` | Pin controller to ingress-ready node |
| `kubectl get ingressclass` | Verify available IngressClass |
| `docker build -t course-app:v5 week-05/labs/lab-02-configmaps-and-wiring/starter` | Build app image |
| `kind load docker-image course-app:v5 --name lab` | Load image into kind |
| `helm install uptime-kuma uptime-kuma/uptime-kuma -f week-06/labs/lab-01-ingress-kind/starter/uptime-kuma-values.yaml` | Install Uptime Kuma |
| `kubectl apply -f - <<'EOF' ... Ingress ... EOF` | Create host routing rules |
| `kubectl get ingress` | Show ingress objects and addresses |
| `curl -H "Host: app.local" http://127.0.0.1/` | Route test for app backend |
| `curl -H "Host: status.local" http://127.0.0.1/` | Route test for status backend |
| `kind delete cluster --name lab` | Cleanup cluster |
