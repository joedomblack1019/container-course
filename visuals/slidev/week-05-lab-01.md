---
theme: default
title: Week 05 Lab 01 - Helm for Vault, Manifests for Redis
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "05"
lab: "Lab 01 · Helm for Vault, Manifests for Redis"
---

# Helm for Vault, Manifests for Redis
## Lab 01

- Install Vault via Helm with a custom values file
- Initialize and unseal Vault, then store versioned secrets
- Deploy Redis with hand-written ConfigMap, Secret, StatefulSet, Service
- Verify persistence and DNS behavior for stateful workloads

---
layout: win95
windowTitle: "Approach Selection"
windowIcon: "⎈"
statusText: "Week 05 · Lab 01 · Helm vs plain manifests"
---

## Which Tool to Use

| Use case | Preferred approach |
|---|---|
| Complex third-party software (Vault) | **Helm** |
| Small service you fully understand (Redis standalone) | **Plain manifests** |

> This lab intentionally uses both patterns in one workflow.

---
layout: win95
windowTitle: "Vault Helm Values"
windowIcon: "🔐"
statusText: "Week 05 · Lab 01 · Chart configuration"
---

## `starter/vault-values.yaml`

```yaml
server:
  standalone:
    enabled: true
    config: |
      ui = false
      listener "tcp" {
        address = "[::]:8200"
        tls_disable = 1
      }
      storage "file" {
        path = "/vault/data"
      }
  dataStorage:
    enabled: true
    size: 256Mi
injector:
  enabled: true
```

---
layout: win95
windowTitle: "Redis Manifests"
windowIcon: "📄"
statusText: "Week 05 · Lab 01 · Stateful service by hand"
---

## Redis Config + StatefulSet Pattern

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
spec:
  serviceName: redis
  replicas: 1
  template:
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        command: ["redis-server", "/etc/redis/redis.conf"]
  volumeClaimTemplates:
  - metadata:
      name: redis-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 256Mi
```

---
layout: win95-terminal
termTitle: "Command Prompt — Helm setup and chart discovery"
---

<Win95Terminal
  title="Command Prompt — helm basics"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash' },
    { type: 'input', text: 'helm version' },
    { type: 'input', text: 'helm repo add hashicorp https://helm.releases.hashicorp.com' },
    { type: 'input', text: 'helm repo update' },
    { type: 'input', text: 'helm search repo hashicorp' },
    { type: 'input', text: 'helm search repo hashicorp/vault --versions | head -10' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — install Vault and inspect release"
---

<Win95Terminal
  title="Command Prompt — vault release"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'helm show values hashicorp/vault | head -100' },
    { type: 'input', text: 'cat starter/vault-values.yaml' },
    { type: 'input', text: 'helm template vault hashicorp/vault -f starter/vault-values.yaml | head -200' },
    { type: 'input', text: 'helm install vault hashicorp/vault -f starter/vault-values.yaml' },
    { type: 'input', text: 'helm list' },
    { type: 'input', text: 'kubectl get all -l app.kubernetes.io/instance=vault' },
    { type: 'input', text: 'kubectl get pods -l app.kubernetes.io/name=vault' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — init/unseal Vault and Helm lifecycle"
---

<Win95Terminal
  title="Command Prompt — vault operations"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl exec vault-0 -- vault status' },
    { type: 'input', text: 'kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json' },
    { type: 'input', text: 'kubectl exec vault-0 -- vault operator unseal <YOUR-UNSEAL-KEY>' },
    { type: 'input', text: 'kubectl exec vault-0 -- vault status' },
    { type: 'input', text: 'helm get values vault' },
    { type: 'input', text: 'helm history vault' },
    { type: 'input', text: 'helm get manifest vault | head -50' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — store and version secrets in Vault"
---

<Win95Terminal
  title="Command Prompt — vault kv workflow"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl exec vault-0 -- vault login <YOUR-ROOT-TOKEN>' },
    { type: 'input', text: 'kubectl exec vault-0 -- vault secrets enable -path=secret kv-v2' },
    { type: 'input', text: 'kubectl exec vault-0 -- vault kv put secret/myapp/database username=&quot;myapp_svc&quot; password=&quot;r4nD0m-G3n3r4t3d-Pa55w0rd&quot; host=&quot;mysql.internal.company.com&quot; port=&quot;3306&quot; dbname=&quot;myapp_production&quot;' },
    { type: 'input', text: 'kubectl exec vault-0 -- vault kv get secret/myapp/database' },
    { type: 'input', text: 'kubectl exec vault-0 -- vault kv get -field=password secret/myapp/database' },
    { type: 'input', text: 'kubectl exec vault-0 -- vault kv metadata get secret/myapp/database' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — Redis manifests apply and verification"
---

<Win95Terminal
  title="Command Prompt — redis stack"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'mkdir -p redis-manifests' },
    { type: 'input', text: 'cd redis-manifests' },
    { type: 'input', text: 'kubectl apply -f redis-configmap.yaml' },
    { type: 'input', text: 'kubectl apply -f redis-secret.yaml' },
    { type: 'input', text: 'kubectl apply -f redis-statefulset.yaml' },
    { type: 'input', text: 'kubectl apply -f redis-service.yaml' },
    { type: 'input', text: 'kubectl get statefulset redis; kubectl get pods -l app=redis; kubectl get pvc; kubectl get service redis' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — persistence and DNS proof"
---

<Win95Terminal
  title="Command Prompt — state validation"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl exec -it redis-0 -- redis-cli -a redis-lab-password' },
    { type: 'input', text: 'ping; set testkey &quot;hello from kubernetes&quot;; incr visitor-count; incr visitor-count; incr visitor-count; get visitor-count; exit' },
    { type: 'input', text: 'kubectl delete pod redis-0' },
    { type: 'input', text: 'kubectl get pods -w' },
    { type: 'input', text: 'kubectl exec -it redis-0 -- redis-cli -a redis-lab-password get visitor-count' },
    { type: 'input', text: 'kubectl run dns-test --rm -it --image=busybox:1.36 -- nslookup redis' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 01 — Key Commands"
windowIcon: "📋"
statusText: "Week 05 · Lab 01 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `helm repo add hashicorp https://helm.releases.hashicorp.com` | Add Vault chart repo |
| `helm repo update` | Refresh chart index |
| `helm search repo hashicorp/vault --versions | head -10` | List Vault chart versions |
| `helm show values hashicorp/vault | head -100` | Inspect default values |
| `helm template vault hashicorp/vault -f starter/vault-values.yaml | head -200` | Preview rendered manifests |
| `helm install vault hashicorp/vault -f starter/vault-values.yaml` | Install Vault release |
| `helm list` | Show installed releases |
| `kubectl exec vault-0 -- vault operator init ...` | Initialize Vault |
| `kubectl exec vault-0 -- vault operator unseal <YOUR-UNSEAL-KEY>` | Unseal Vault |
| `kubectl exec vault-0 -- vault login <YOUR-ROOT-TOKEN>` | Authenticate to Vault |
| `kubectl exec vault-0 -- vault secrets enable -path=secret kv-v2` | Enable KV v2 engine |
| `kubectl exec vault-0 -- vault kv put secret/myapp/database ...` | Store DB secret |
| `kubectl exec vault-0 -- vault kv get -field=password secret/myapp/database` | Read single secret field |
| `kubectl apply -f redis-configmap.yaml` | Create Redis config map |
| `kubectl apply -f redis-secret.yaml` | Create Redis secret |
| `kubectl apply -f redis-statefulset.yaml` | Deploy Redis StatefulSet |
| `kubectl apply -f redis-service.yaml` | Create Redis headless service |
| `kubectl exec -it redis-0 -- redis-cli -a redis-lab-password` | Access Redis CLI |
| `kubectl delete pod redis-0` | Recreate Redis pod |
| `kubectl run dns-test --rm -it --image=busybox:1.36 -- nslookup redis` | Validate DNS resolution |
