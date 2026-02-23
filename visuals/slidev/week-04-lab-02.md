---
theme: default
title: Week 04 Lab 02 - Deploy, Scale, Update, Debug
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 02 · Deploy, Scale, Update, Debug"
---

# Deploy, Scale, Update, Debug
## Lab 02

- Build and run `student-app:v4` with `/info` metadata endpoint
- Deploy with Downward API, resources, and Service abstraction
- Scale replicas and watch reconciliation + load balancing
- Practice rollout, rollback, and failure debugging workflows

---
layout: win95
windowTitle: "Deployment Manifest Core"
windowIcon: "📄"
statusText: "Week 04 · Lab 02 · Downward API + resources"
---

## `deployment.yaml` Highlights

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: student-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: student-app
  template:
    metadata:
      labels:
        app: student-app
    spec:
      containers:
      - name: student-app
        image: student-app:v4
        env:
        - name: POD_NAME
          valueFrom: { fieldRef: { fieldPath: metadata.name } }
        - name: POD_NAMESPACE
          valueFrom: { fieldRef: { fieldPath: metadata.namespace } }
        - name: POD_IP
          valueFrom: { fieldRef: { fieldPath: status.podIP } }
        - name: NODE_NAME
          valueFrom: { fieldRef: { fieldPath: spec.nodeName } }
        resources:
          requests: { memory: "64Mi", cpu: "50m" }
          limits:   { memory: "256Mi", cpu: "200m" }
```

---
layout: win95
windowTitle: "Service Manifest"
windowIcon: "🔌"
statusText: "Week 04 · Lab 02 · Stable endpoint"
---

## `service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: student-app-svc
spec:
  selector:
    app: student-app
  ports:
  - port: 80
    targetPort: 5000
    protocol: TCP
    name: http
```

---
layout: win95-terminal
termTitle: "Command Prompt — build and local container test"
---

<Win95Terminal
  title="Command Prompt — v4 image prep"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd week-04/labs/lab-02-deploy-and-scale/starter' },
    { type: 'input', text: 'cat app.py' },
    { type: 'input', text: 'docker build -t student-app:v4 .' },
    { type: 'input', text: 'docker run -d --name test-v4 -p 5000:5000 student-app:v4' },
    { type: 'input', text: 'curl localhost:5000/info' },
    { type: 'input', text: 'docker rm -f test-v4' },
    { type: 'input', text: 'kind load docker-image student-app:v4 --name lab' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — schema discovery helpers"
---

<Win95Terminal
  title="Command Prompt — kubectl explain"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl explain deployment' },
    { type: 'input', text: 'kubectl explain deployment.spec' },
    { type: 'input', text: 'kubectl explain deployment.spec.template.spec.containers' },
    { type: 'input', text: 'kubectl explain deployment.spec.template.spec.containers.env' },
    { type: 'input', text: 'kubectl explain deployment --recursive' },
    { type: 'input', text: 'kubectl create deployment student-app --image=student-app:v4 --dry-run=client -o yaml' },
    { type: 'input', text: 'kubectl create deployment student-app --image=student-app:v4 --dry-run=client -o yaml > deployment.yaml' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — deploy and validate"
---

<Win95Terminal
  title="Command Prompt — apply deployment"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config current-context' },
    { type: 'input', text: 'kubectl apply -f deployment.yaml' },
    { type: 'input', text: 'kubectl get pods -w' },
    { type: 'input', text: 'kubectl get deployment student-app' },
    { type: 'input', text: 'kubectl get replicasets' },
    { type: 'input', text: 'kubectl get events --sort-by=.metadata.creationTimestamp' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — service create and traffic test"
---

<Win95Terminal
  title="Command Prompt — service access"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl port-forward deployment/student-app 5000:5000 &' },
    { type: 'input', text: 'curl localhost:5000' },
    { type: 'input', text: 'curl localhost:5000/info' },
    { type: 'input', text: 'curl localhost:5000/health' },
    { type: 'input', text: 'kill %1' },
    { type: 'input', text: 'kubectl apply -f service.yaml' },
    { type: 'input', text: 'kubectl get services' },
    { type: 'input', text: 'kubectl port-forward service/student-app-svc 8080:80 &' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — scale, self-heal, and rollout"
---

<Win95Terminal
  title="Command Prompt — reconciliation and rollout"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'curl localhost:8080/info' },
    { type: 'input', text: 'kill %1' },
    { type: 'input', text: 'kubectl scale deployment student-app --replicas=3' },
    { type: 'input', text: 'kubectl get pods -w' },
    { type: 'input', text: 'kubectl run curl-test --rm -it --restart=Never --image=curlimages/curl -- sh -c \'for i in $(seq 1 10); do curl -s http://student-app-svc/info 2>/dev/null | grep pod_name; done\'' },
    { type: 'input', text: 'kubectl get pods' },
    { type: 'input', text: 'kubectl delete pod <PASTE_A_POD_NAME_HERE>' },
    { type: 'input', text: 'kubectl get pods -w' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — image update, rollback, and failures"
---

<Win95Terminal
  title="Command Prompt — update and debug"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker build -t student-app:v4.1 .' },
    { type: 'input', text: 'kind load docker-image student-app:v4.1 --name lab' },
    { type: 'input', text: 'kubectl set image deployment/student-app student-app=student-app:v4.1' },
    { type: 'input', text: 'kubectl rollout status deployment/student-app' },
    { type: 'input', text: 'kubectl rollout history deployment/student-app' },
    { type: 'input', text: 'kubectl rollout undo deployment/student-app' },
    { type: 'input', text: 'kubectl set image deployment/student-app student-app=student-app:v999-does-not-exist' },
    { type: 'input', text: 'kubectl describe pod <FAILING_POD_NAME>' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — crashloop scenario, cleanup, benchmark"
---

<Win95Terminal
  title="Command Prompt — crashloop triage"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cat > /tmp/Dockerfile.broken <<\'EOF\'' },
    { type: 'input', text: 'FROM python:3.11-slim' },
    { type: 'input', text: 'CMD [&quot;python&quot;, &quot;-c&quot;, &quot;raise Exception(\'Jerry was here\')&quot;]' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'docker build -t student-app:broken -f /tmp/Dockerfile.broken .' },
    { type: 'input', text: 'kind load docker-image student-app:broken --name lab' },
    { type: 'input', text: 'kubectl set image deployment/student-app student-app=student-app:broken' },
    { type: 'input', text: 'kubectl logs <CRASHING_POD_NAME> --previous' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — final commands from lab"
---

<Win95Terminal
  title="Command Prompt — final sequence"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl rollout undo deployment/student-app' },
    { type: 'input', text: 'kubectl exec -it <POD_NAME> -- /bin/sh' },
    { type: 'input', text: 'ls /app' },
    { type: 'input', text: 'cat /app/app.py' },
    { type: 'input', text: 'env | grep -E &quot;POD_|NODE_|STUDENT&quot;' },
    { type: 'input', text: 'wget -qO- http://student-app-svc/health' },
    { type: 'input', text: 'exit' },
    { type: 'input', text: 'kubectl delete -f deployment.yaml; kubectl delete -f service.yaml; kubectl get all' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 02 — Key Commands"
windowIcon: "📋"
statusText: "Week 04 · Lab 02 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `docker build -t student-app:v4 .` | Build v4 image |
| `docker run -d --name test-v4 -p 5000:5000 student-app:v4` | Run local test container |
| `curl localhost:5000/info` | Check `/info` endpoint |
| `docker rm -f test-v4` | Remove test container |
| `kind load docker-image student-app:v4 --name lab` | Load image into kind |
| `kubectl explain ...` | Discover Deployment schema |
| `kubectl create deployment ... --dry-run=client -o yaml` | Generate starter manifest |
| `kubectl apply -f deployment.yaml` | Create/update deployment |
| `kubectl get pods -w` | Watch pod lifecycle |
| `kubectl get deployment student-app` | Check deployment status |
| `kubectl get replicasets` | Inspect ReplicaSet layer |
| `kubectl port-forward deployment/student-app 5000:5000 &` | Tunnel to deployment |
| `curl localhost:5000` | Test app root |
| `curl localhost:5000/health` | Test health endpoint |
| `kill %1` | Stop background port-forward |
| `kubectl apply -f service.yaml` | Create service |
| `kubectl port-forward service/student-app-svc 8080:80 &` | Tunnel to service |
| `curl localhost:8080/info` | Hit service-backed endpoint |
| `kubectl scale deployment student-app --replicas=3` | Scale replicas |
| `kubectl run curl-test ...` | In-cluster load-balance test |
| `kubectl delete pod <PASTE_A_POD_NAME_HERE>` | Trigger self-healing |
| `docker build -t student-app:v4.1 .` | Build update image |
| `kind load docker-image student-app:v4.1 --name lab` | Load update image |
| `kubectl set image deployment/student-app student-app=student-app:v4.1` | Start rolling update |
| `kubectl rollout status deployment/student-app` | Watch rollout completion |
| `kubectl rollout history deployment/student-app` | View rollout revisions |
| `kubectl rollout undo deployment/student-app` | Roll back deployment |
| `kubectl set image deployment/student-app student-app=student-app:v999-does-not-exist` | Simulate image pull failure |
| `kubectl describe pod <FAILING_POD_NAME>` | Diagnose failing pod |
| `docker build -t student-app:broken -f /tmp/Dockerfile.broken .` | Build crashloop image |
| `kind load docker-image student-app:broken --name lab` | Load broken image |
| `kubectl set image deployment/student-app student-app=student-app:broken` | Trigger CrashLoopBackOff |
| `kubectl logs <CRASHING_POD_NAME>` | Read current container logs |
| `kubectl logs <CRASHING_POD_NAME> --previous` | Read previous crash logs |
| `kubectl exec -it <POD_NAME> -- /bin/sh` | Shell into running pod |
| `wget -qO- http://student-app-svc/health` | Check service from pod |
| `kubectl delete -f deployment.yaml` | Remove deployment |
| `kubectl delete -f service.yaml` | Remove service |
| `kubectl get all` | Verify cleanup |
| `cd week-04/labs/lab-02-deploy-and-scale` | Enter benchmark directory |
| `python3 scripts/benchmark_rollout_timeline.py --namespace default --deployment student-app` | Generate rollout charts |
| `python3 scripts/benchmark_rollout_timeline.py --namespace default --deployment student-app --skip-actions` | Observe only |
| `python3 scripts/benchmark_rollout_timeline.py --namespace default --deployment student-app --no-charts` | Collect timeline data only |

---
layout: win95
windowTitle: "Reconciliation Sequence"
windowIcon: "🔁"
statusText: "Week 04 · Lab 02 · Drift correction"
---

## Desired to Actual Loop

<ReconciliationSequence :active-step="4" title="Deployment Reconciliation" />
