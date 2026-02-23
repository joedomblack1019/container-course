---
theme: default
title: Week 05 Lab 02 - Wire Your App to Redis
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "05"
lab: "Lab 02 · Wire Your App to Redis"
---

# Wire Your App to Redis
## Lab 02

- Build/load `course-app:v5` into kind
- Inject app config via ConfigMap and secret via Secret
- Deploy app Service and verify `/visits` counter
- Prove state survives app and Redis pod restarts

---
layout: win95
windowTitle: "Wiring Model"
windowIcon: "🔌"
statusText: "Week 05 · Lab 02 · Config and secret injection"
---

## ConfigMap + Secret Injection

| Source | Injection method | Used for |
|---|---|---|
| `app-config` ConfigMap | `envFrom.configMapRef` | `REDIS_HOST`, `REDIS_PORT`, app settings |
| `redis-credentials` Secret | `env[].valueFrom.secretKeyRef` | `REDIS_PASSWORD` |
| Downward API fields | `env[].valueFrom.fieldRef` | pod metadata (`POD_NAME`, `NODE_NAME`) |

---
layout: win95
windowTitle: "Deployment v5 Pattern"
windowIcon: "📄"
statusText: "Week 05 · Lab 02 · App deployment spec"
---

## `deployment.yaml` Core Block

```yaml
containers:
- name: app
  image: course-app:v5
  imagePullPolicy: Never
  envFrom:
  - configMapRef:
      name: app-config
  env:
  - name: REDIS_PASSWORD
    valueFrom:
      secretKeyRef:
        name: redis-credentials
        key: REDIS_PASSWORD
  - name: POD_NAME
    valueFrom:
      fieldRef:
        fieldPath: metadata.name
```

---
layout: win95-terminal
termTitle: "Command Prompt — build app and verify Redis prereq"
---

<Win95Terminal
  title="Command Prompt — build + prereq"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd labs/lab-02-configmaps-and-wiring/starter' },
    { type: 'input', text: 'docker build -t course-app:v5 .' },
    { type: 'input', text: 'kind load docker-image course-app:v5 --name lab' },
    { type: 'input', text: 'kubectl config current-context' },
    { type: 'input', text: 'kubectl get svc redis' },
    { type: 'input', text: 'kubectl get pod redis-0' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — optional Redis bootstrap commands"
---

<Win95Terminal
  title="Command Prompt — if Redis missing"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f ../lab-01-helm-redis-and-vault/solution/redis-configmap.yaml' },
    { type: 'input', text: 'kubectl apply -f ../lab-01-helm-redis-and-vault/solution/redis-secret.yaml' },
    { type: 'input', text: 'kubectl apply -f ../lab-01-helm-redis-and-vault/solution/redis-service.yaml' },
    { type: 'input', text: 'kubectl apply -f ../lab-01-helm-redis-and-vault/solution/redis-statefulset.yaml' },
    { type: 'input', text: 'kubectl get pods -l app=redis -w' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — config and secret creation"
---

<Win95Terminal
  title="Command Prompt — ConfigMap + Secret"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f configmap.yaml' },
    { type: 'input', text: 'kubectl get configmap app-config -o yaml' },
    { type: 'input', text: 'kubectl apply -f secret.yaml' },
    { type: 'input', text: 'kubectl get secret redis-credentials -o yaml' },
    { type: 'input', text: 'echo &quot;cmVkaXMtbGFiLXBhc3N3b3Jk&quot; | base64 -d' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — deploy app and test endpoints"
---

<Win95Terminal
  title="Command Prompt — app deployment"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply --dry-run=client -f deployment.yaml -o yaml' },
    { type: 'input', text: 'kubectl apply -f deployment.yaml' },
    { type: 'input', text: 'kubectl get pods -w' },
    { type: 'input', text: 'kubectl apply -f service.yaml' },
    { type: 'input', text: 'kubectl port-forward service/course-app 8080:80 &' },
    { type: 'input', text: 'curl http://localhost:8080' },
    { type: 'input', text: 'curl -s http://localhost:8080/visits | python3 -m json.tool' },
    { type: 'input', text: 'curl -s http://localhost:8080/info | python3 -m json.tool' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — restart resilience and config updates"
---

<Win95Terminal
  title="Command Prompt — survival tests"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl delete pod -l app=course-app --wait=false' },
    { type: 'input', text: 'kubectl get pods -w' },
    { type: 'input', text: 'kubectl port-forward service/course-app 8080:80 &' },
    { type: 'input', text: 'curl -s http://localhost:8080/visits | python3 -m json.tool' },
    { type: 'input', text: 'kubectl delete pod redis-0 --wait=false' },
    { type: 'input', text: 'kubectl get pods -l app=redis -w' },
    { type: 'input', text: 'kubectl get pvc; kubectl describe pvc redis-data-redis-0' },
    { type: 'input', text: 'kubectl patch configmap app-config --type merge -p \'{&quot;data&quot;:{&quot;GREETING&quot;:&quot;Howdy&quot;}}\'' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — rollout restart for envFrom refresh"
---

<Win95Terminal
  title="Command Prompt — apply updated ConfigMap"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl port-forward service/course-app 8080:80 &' },
    { type: 'input', text: 'curl -s http://localhost:8080 | grep Howdy' },
    { type: 'input', text: 'kubectl rollout restart deployment course-app' },
    { type: 'input', text: 'kubectl get pods -w' },
    { type: 'input', text: 'kubectl port-forward service/course-app 8080:80 &' },
    { type: 'input', text: 'curl -s http://localhost:8080 | grep Howdy' },
    { type: 'input', text: 'kill %1' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 02 — Key Commands"
windowIcon: "📋"
statusText: "Week 05 · Lab 02 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `docker build -t course-app:v5 .` | Build v5 app image |
| `kind load docker-image course-app:v5 --name lab` | Load image into kind |
| `kubectl get svc redis` | Verify Redis service exists |
| `kubectl get pod redis-0` | Verify Redis pod exists |
| `kubectl apply -f configmap.yaml` | Create app ConfigMap |
| `kubectl get configmap app-config -o yaml` | Inspect ConfigMap data |
| `kubectl apply -f secret.yaml` | Create Redis secret |
| `kubectl get secret redis-credentials -o yaml` | Inspect Secret |
| `echo "cmVkaXMtbGFiLXBhc3N3b3Jk" | base64 -d` | Decode sample base64 value |
| `kubectl apply -f deployment.yaml` | Deploy app workload |
| `kubectl apply -f service.yaml` | Create app service |
| `kubectl port-forward service/course-app 8080:80 &` | Access app locally |
| `curl -s http://localhost:8080/visits | python3 -m json.tool` | Verify counter endpoint |
| `curl -s http://localhost:8080/info | python3 -m json.tool` | Verify metadata + Redis status |
| `kubectl delete pod -l app=course-app --wait=false` | Force app pod recreation |
| `kubectl delete pod redis-0 --wait=false` | Force Redis pod recreation |
| `kubectl get pvc` | List PVCs |
| `kubectl describe pvc redis-data-redis-0` | Inspect Redis persistent claim |
| `kubectl patch configmap app-config --type merge -p '{"data":{"GREETING":"Howdy"}}'` | Update ConfigMap key |
| `kubectl rollout restart deployment course-app` | Restart pods to consume env-based config changes |
| `kill %1` | Stop port-forward process |
