---
theme: default
title: Week 06 Lab 04 - Service Types and Endpoint Debugging
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "06"
lab: "Lab 04 · Service Types + Endpoint Debugging"
---

# Service Types + Endpoint Debugging
## Lab 04

- Compare ClusterIP, NodePort, and LoadBalancer behavior
- Diagnose broken NodePort `targetPort` mapping
- Use Endpoints evidence to trace selector and backend wiring
- Explain why LoadBalancer remains pending in kind

---
layout: win95
windowTitle: "Service Type Comparison"
windowIcon: "🔌"
statusText: "Week 06 · Lab 04 · Access patterns"
---

## Types and Reachability

| Type | Reachable from |
|---|---|
| `ClusterIP` | in-cluster only |
| `NodePort` | host/node IP + high port |
| `LoadBalancer` | cloud-managed external IP (pending in kind) |

---
layout: win95-terminal
termTitle: "Command Prompt — baseline deployment and ClusterIP"
---

<Win95Terminal
  title="Command Prompt — baseline"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config use-context kind-lab' },
    { type: 'input', text: 'kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/app-deployment.yaml' },
    { type: 'input', text: 'kubectl rollout status deployment/svc-types-demo --timeout=120s' },
    { type: 'input', text: 'kubectl get pods -l app=svc-types-demo -o wide' },
    { type: 'input', text: 'kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/service-clusterip.yaml' },
    { type: 'input', text: 'kubectl get svc svc-demo-clusterip' },
    { type: 'input', text: 'kubectl get endpoints svc-demo-clusterip' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — NodePort failure triage and fix"
---

<Win95Terminal
  title="Command Prompt — endpoint debugging"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl run svc-probe --image=busybox:1.36 --restart=Never --rm -it -- wget -qO- -T 5 http://svc-demo-clusterip' },
    { type: 'input', text: 'kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/service-nodeport-broken.yaml' },
    { type: 'input', text: 'kubectl describe svc svc-demo-nodeport' },
    { type: 'input', text: 'kubectl get endpoints svc-demo-nodeport -o yaml' },
    { type: 'input', text: 'bash week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/endpoint-check.sh svc-demo-nodeport' },
    { type: 'input', text: 'kubectl patch svc svc-demo-nodeport --type merge -p \'{&quot;spec&quot;:{&quot;ports&quot;:[{&quot;port&quot;:80,&quot;targetPort&quot;:5678,&quot;nodePort&quot;:30080}]}}\'' },
    { type: 'input', text: 'kubectl get endpoints svc-demo-nodeport' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — LoadBalancer behavior and cleanup"
---

<Win95Terminal
  title="Command Prompt — LoadBalancer in kind"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl run nodeport-probe --image=busybox:1.36 --restart=Never --rm -it -- wget -qO- -T 5 http://svc-demo-nodeport' },
    { type: 'input', text: 'curl -s http://127.0.0.1:30080 | head' },
    { type: 'input', text: 'kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/service-loadbalancer.yaml' },
    { type: 'input', text: 'kubectl get svc svc-demo-loadbalancer -o wide' },
    { type: 'input', text: 'kubectl describe svc svc-demo-loadbalancer' },
    { type: 'input', text: 'kubectl get endpoints svc-demo-loadbalancer' },
    { type: 'input', text: 'kubectl delete svc svc-demo-clusterip svc-demo-nodeport svc-demo-loadbalancer --ignore-not-found; kubectl delete deployment svc-types-demo --ignore-not-found' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 04 — Key Commands"
windowIcon: "📋"
statusText: "Week 06 · Lab 04 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl apply -f .../app-deployment.yaml` | Deploy baseline app |
| `kubectl rollout status deployment/svc-types-demo --timeout=120s` | Wait for deployment readiness |
| `kubectl apply -f .../service-clusterip.yaml` | Create ClusterIP service |
| `kubectl get endpoints svc-demo-clusterip` | Inspect resolved backends |
| `kubectl run svc-probe ... wget ... http://svc-demo-clusterip` | Test ClusterIP in-cluster |
| `kubectl apply -f .../service-nodeport-broken.yaml` | Apply broken NodePort service |
| `kubectl describe svc svc-demo-nodeport` | Debug service config |
| `kubectl get endpoints svc-demo-nodeport -o yaml` | Check endpoint wiring |
| `bash .../endpoint-check.sh svc-demo-nodeport` | Run endpoint diagnostic helper |
| `kubectl patch svc svc-demo-nodeport --type merge -p '{"spec":{"ports":[{"port":80,"targetPort":5678,"nodePort":30080}]}}'` | Fix targetPort mapping |
| `kubectl run nodeport-probe ... wget ... http://svc-demo-nodeport` | Retest NodePort after fix |
| `curl -s http://127.0.0.1:30080` | Optional host-level NodePort test |
| `kubectl apply -f .../service-loadbalancer.yaml` | Create LoadBalancer service |
| `kubectl get svc svc-demo-loadbalancer -o wide` | Observe external IP pending state |
| `kubectl describe svc svc-demo-loadbalancer` | Inspect LB service events/details |
| `kubectl delete svc ...` | Remove lab services |
| `kubectl delete deployment svc-types-demo --ignore-not-found` | Remove lab deployment |
