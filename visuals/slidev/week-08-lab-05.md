---
theme: default
title: Week 08 Lab 05 - Troubleshooting Playbook Sprint
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "08"
lab: "Lab 05 · Troubleshooting Playbook Sprint"
---

# Troubleshooting Playbook Sprint
## Lab 05

- Run timed incident triage across DNS, scheduling, control plane, and resources
- Apply playbook-first diagnosis sequence under 12-minute constraints
- Capture evidence commands and root cause per incident
- Validate recovery before moving to next scenario

---
layout: win95
windowTitle: "Incident Method"
windowIcon: "🚨"
statusText: "Week 08 · Lab 05 · Scope before commands"
---

## Fast Triage Pattern

1. Identify blast radius (pod/namespace/node/cluster)
2. Inspect chronological events
3. Check likely component for that symptom domain
4. Apply fix + verify state recovery

---
layout: win95-terminal
termTitle: "Command Prompt — baseline and incident 1"
---

<Win95Terminal
  title="Command Prompt — DNS outage drill"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config use-context kind-lab' },
    { type: 'input', text: 'kubectl apply -f starter/baseline-workload.yaml' },
    { type: 'input', text: 'kubectl -n sprint-lab rollout status deploy/web --timeout=60s' },
    { type: 'input', text: './instructor/inject-coredns-failure.sh' },
    { type: 'input', text: 'kubectl run dns-test --image=busybox:1.36 --restart=Never --rm -it -- nslookup web.sprint-lab.svc.cluster.local' },
    { type: 'input', text: 'kubectl -n kube-system logs deployment/coredns --tail=80' },
    { type: 'input', text: 'kubectl -n kube-system get configmap coredns -o yaml' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — incident 2 and 3"
---

<Win95Terminal
  title="Command Prompt — scheduling + control plane"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'NODE=&quot;$(kubectl get nodes -o name | grep -v control-plane | head -1 | cut -d/ -f2)&quot;' },
    { type: 'input', text: 'kubectl taint node &quot;$NODE&quot; sprint=blocked:NoSchedule' },
    { type: 'input', text: 'kubectl apply -f starter/pending-app.yaml' },
    { type: 'input', text: 'kubectl -n sprint-lab get pods' },
    { type: 'input', text: './instructor/inject-scheduler-break.sh' },
    { type: 'input', text: 'kubectl run test-schedule --image=registry.k8s.io/pause:3.10 --restart=Never' },
    { type: 'input', text: 'kubectl get pod test-schedule' },
    { type: 'input', text: 'kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -40' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — incident 4 and bonus incident 5"
---

<Win95Terminal
  title="Command Prompt — pressure + init crash"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: './instructor/inject-resource-hog.sh' },
    { type: 'input', text: 'kubectl -n sprint-lab get pods' },
    { type: 'input', text: 'kubectl top nodes' },
    { type: 'input', text: './instructor/inject-multi-container-failure.sh' },
    { type: 'input', text: 'kubectl -n sprint-lab get pods' },
    { type: 'input', text: 'kubectl -n sprint-lab logs <pod> -c <container>' },
    { type: 'input', text: 'kubectl -n sprint-lab describe pod <pod>' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — scorecard and cleanup"
---

<Win95Terminal
  title="Command Prompt — closeout"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl delete namespace sprint-lab' },
    { type: 'input', text: 'kubectl delete pod test-schedule --ignore-not-found' },
    { type: 'input', text: 'kubectl delete pod dns-test --ignore-not-found' },
    { type: 'input', text: 'for node in $(kubectl get nodes -o name | cut -d/ -f2); do kubectl taint node &quot;$node&quot; sprint=blocked:NoSchedule- 2>/dev/null || true; done' },
    { type: 'input', text: 'if [ -f /tmp/coredns-backup.yaml ]; then kubectl apply -f /tmp/coredns-backup.yaml; kubectl -n kube-system rollout restart deployment/coredns; rm -f /tmp/coredns-backup.yaml; fi' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 05 — Key Commands"
windowIcon: "📋"
statusText: "Week 08 · Lab 05 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl apply -f starter/baseline-workload.yaml` | Create baseline sprint namespace workload |
| `./instructor/inject-coredns-failure.sh` | Inject DNS incident fault |
| `kubectl run dns-test --image=busybox:1.36 --restart=Never --rm -it -- nslookup web.sprint-lab.svc.cluster.local` | Verify DNS failure symptom |
| `kubectl taint node "$NODE" sprint=blocked:NoSchedule` | Inject scheduling taint failure |
| `kubectl apply -f starter/pending-app.yaml` | Create pending workload scenario |
| `./instructor/inject-scheduler-break.sh` | Break scheduler path for cluster-wide Pending pods |
| `kubectl run test-schedule --image=registry.k8s.io/pause:3.10 --restart=Never` | Probe new pod scheduling |
| `./instructor/inject-resource-hog.sh` | Inject resource pressure incident |
| `kubectl top nodes` | Observe node resource contention |
| `./instructor/inject-multi-container-failure.sh` | Inject init container failure scenario |
| `kubectl -n sprint-lab logs <pod> -c <container>` | Container-specific log triage |
| `kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -40` | Capture timeline evidence |
| `kubectl delete namespace sprint-lab` | Cleanup incident namespace |
