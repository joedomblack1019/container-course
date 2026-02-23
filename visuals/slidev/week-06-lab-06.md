---
theme: default
title: Week 06 Lab 06 - CNI Plugin Comparison
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "06"
lab: "Lab 06 · CNI Plugin Comparison"
---

# CNI Plugin Comparison
## Lab 06

- Compare kindnet, no-CNI, Calico, and optional Cilium behavior
- Observe why NetworkPolicy objects may exist without enforcement
- Validate node readiness and pod networking after CNI install
- Build CNI decision rules for common CKA scenarios

---
layout: win95
windowTitle: "CNI Capability Matrix"
windowIcon: "🧩"
statusText: "Week 06 · Lab 06 · Enforcement and data plane"
---

## Plugin Comparison

| CNI | Pod networking | NetworkPolicy enforcement | Data plane |
|---|---|---|---|
| kindnet | yes | no | bridge/simple |
| Calico | yes | yes | iptables/nftables |
| Cilium | yes | yes + L7 | eBPF |

---
layout: win95-terminal
termTitle: "Command Prompt — kindnet baseline and policy no-op"
---

<Win95Terminal
  title="Command Prompt — default CNI"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kind create cluster --name cni-default' },
    { type: 'input', text: 'kubectl config use-context kind-cni-default' },
    { type: 'input', text: 'kubectl apply -f starter/test-workloads.yaml' },
    { type: 'input', text: 'kubectl wait --for=condition=Ready pod/server pod/client --timeout=60s' },
    { type: 'input', text: 'kubectl exec client -- curl -s --max-time 5 http://server' },
    { type: 'input', text: 'kubectl apply -f starter/deny-policy.yaml' },
    { type: 'input', text: 'kubectl exec client -- curl -s --max-time 5 http://server' },
    { type: 'comment', text: '# Still succeeds: kindnet does not enforce NetworkPolicy' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — no-CNI cluster and NotReady diagnosis"
---

<Win95Terminal
  title="Command Prompt — disable default CNI"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kind delete cluster --name cni-default' },
    { type: 'input', text: 'kind create cluster --name cni-calico --config starter/kind-calico.yaml' },
    { type: 'input', text: 'kubectl config use-context kind-cni-calico' },
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'kubectl describe node cni-calico-control-plane | grep -A10 &quot;Conditions:&quot;' },
    { type: 'input', text: 'kubectl run probe --image=nginx:1.27' },
    { type: 'input', text: 'kubectl describe pod probe | grep -A5 Events:' },
    { type: 'input', text: 'kubectl delete pod probe --ignore-not-found' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — install Calico and verify enforcement"
---

<Win95Terminal
  title="Command Prompt — Calico path"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/calico.yaml' },
    { type: 'input', text: 'kubectl -n kube-system rollout status daemonset/calico-node --timeout=180s' },
    { type: 'input', text: 'kubectl -n kube-system rollout status deployment/calico-kube-controllers --timeout=120s' },
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'kubectl apply -f starter/test-workloads.yaml' },
    { type: 'input', text: 'kubectl exec client -- curl -s --max-time 5 http://server' },
    { type: 'input', text: 'kubectl apply -f starter/deny-policy.yaml; kubectl exec client -- curl -s --max-time 5 http://server' },
    { type: 'input', text: 'kubectl delete networkpolicy deny-server-ingress; kubectl exec client -- curl -s --max-time 5 http://server' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — inspect Calico dataplane and optional Cilium"
---

<Win95Terminal
  title="Command Prompt — deep inspection"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'CALICO_NODE=$(kubectl -n kube-system get pods -l k8s-app=calico-node -o name | grep worker | head -1)' },
    { type: 'input', text: 'kubectl -n kube-system exec &quot;$CALICO_NODE&quot; -- iptables-save | grep -i cali | head -40' },
    { type: 'input', text: 'kubectl -n kube-system logs &quot;$CALICO_NODE&quot; -c calico-node --tail=50 | grep -i &quot;policy\|felix&quot; | head -20' },
    { type: 'input', text: 'kind delete cluster --name cni-calico' },
    { type: 'input', text: 'which cilium && cilium version || echo &quot;cilium CLI not available&quot;' },
    { type: 'input', text: 'kind create cluster --name cni-cilium --config starter/kind-cilium.yaml; kubectl config use-context kind-cni-cilium; cilium install; cilium status --wait; cilium policy get' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — final cleanup"
---

<Win95Terminal
  title="Command Prompt — cleanup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kind delete cluster --name cni-default 2>/dev/null || true' },
    { type: 'input', text: 'kind delete cluster --name cni-calico 2>/dev/null || true' },
    { type: 'input', text: 'kind delete cluster --name cni-cilium 2>/dev/null || true' },
    { type: 'input', text: 'kubectl config use-context ziyotek-prod 2>/dev/null || true' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 06 — Key Commands"
windowIcon: "📋"
statusText: "Week 06 · Lab 06 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kind create cluster --name cni-default` | Create default kindnet cluster |
| `kubectl apply -f starter/test-workloads.yaml` | Deploy server/client test pods |
| `kubectl apply -f starter/deny-policy.yaml` | Apply deny ingress NetworkPolicy |
| `kubectl exec client -- curl -s --max-time 5 http://server` | Test policy effect on connectivity |
| `kind create cluster --name cni-calico --config starter/kind-calico.yaml` | Create no-CNI bootstrap cluster |
| `kubectl describe node cni-calico-control-plane | grep -A10 "Conditions:"` | Confirm NetworkPluginNotReady evidence |
| `kubectl run probe --image=nginx:1.27` | Trigger pending pod symptom without CNI |
| `kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/calico.yaml` | Install Calico plugin |
| `kubectl -n kube-system rollout status daemonset/calico-node --timeout=180s` | Wait for Calico node agent |
| `kubectl -n kube-system rollout status deployment/calico-kube-controllers --timeout=120s` | Wait for Calico controllers |
| `kubectl -n kube-system exec "$CALICO_NODE" -- iptables-save | grep -i cali` | Inspect Calico-programmed iptables chains |
| `which cilium && cilium version || echo "cilium CLI not available"` | Check optional Cilium CLI availability |
| `kind create cluster --name cni-cilium --config starter/kind-cilium.yaml` | Create Cilium test cluster |
| `cilium install` | Install Cilium CNI |
| `cilium status --wait` | Verify Cilium control plane health |
| `cilium policy get` | Show active Cilium policy state |
| `kind delete cluster --name cni-default 2>/dev/null || true` | Cleanup default cluster |
| `kind delete cluster --name cni-calico 2>/dev/null || true` | Cleanup Calico cluster |
| `kind delete cluster --name cni-cilium 2>/dev/null || true` | Cleanup Cilium cluster |
