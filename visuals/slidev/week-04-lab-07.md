---
theme: default
title: Week 04 Lab 07 - Extension Interfaces Deep Dive
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 07 · Extension Interfaces Deep Dive"
---

# Extension Interfaces Deep Dive
## Lab 07

- Inspect CRI runtime details and node-level sockets
- Discover CNI config, binaries, and plugin behavior
- Explore storage class and PVC provisioning path
- Build troubleshooting patterns for CRI vs CNI vs CSI failures

---
layout: win95
windowTitle: "Interface Boundaries"
windowIcon: "🧩"
statusText: "Week 04 · Lab 07 · CRI, CNI, CSI ownership"
---

## Responsibility Split

| Interface | Handles | Typical failure symptom |
|---|---|---|
| **CRI** | Pull/run/stop containers | `ContainerCreating` + runtime/socket errors |
| **CNI** | Pod IP wiring and routes | network setup failures, node `NotReady` |
| **CSI** | PV/PVC provisioning and mount lifecycle | PVC `Pending`, volume attach errors |

---
layout: win95-terminal
termTitle: "Command Prompt — CRI discovery"
---

<Win95Terminal
  title="Command Prompt — runtime interface"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config use-context kind-lab' },
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'kubectl get nodes -o jsonpath=\'{.items[*].status.nodeInfo.containerRuntimeVersion}\'' },
    { type: 'input', text: 'echo' },
    { type: 'input', text: 'kubectl get nodes -o wide' },
    { type: 'input', text: 'docker exec -it kind-lab-control-plane bash' },
    { type: 'input', text: 'ls -la /run/containerd/containerd.sock; ps aux | grep containerd; crictl info | head -20; exit' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — CNI discovery and failure simulation"
---

<Win95Terminal
  title="Command Prompt — network interface"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker exec -it kind-lab-control-plane bash' },
    { type: 'input', text: 'ls -la /etc/cni/net.d/; cat /etc/cni/net.d/10-kindnet.conflist; ls -la /opt/cni/bin/; exit' },
    { type: 'input', text: 'kubectl get pods -n kube-system | grep -E &quot;(kindnet|flannel|calico|cilium)&quot;' },
    { type: 'input', text: 'kubectl describe pod -n kube-system -l app=kindnet' },
    { type: 'input', text: 'kubectl delete pod -n kube-system -l app=kindnet' },
    { type: 'input', text: 'kubectl run cni-test --image=nginx:1.20 --rm -it --restart=Never -- echo &quot;test&quot;' },
    { type: 'input', text: 'kubectl get pod cni-test; kubectl describe pod cni-test; kubectl delete pod cni-test --ignore-not-found' },
    { type: 'input', text: 'kubectl get pods -n kube-system -l app=kindnet' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — CSI discovery and provisioning"
---

<Win95Terminal
  title="Command Prompt — storage interface"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl get storageclass' },
    { type: 'input', text: 'kubectl describe storageclass standard' },
    { type: 'input', text: 'kubectl get pods -n kube-system | grep -E &quot;(csi|storage|local-path)&quot;' },
    { type: 'input', text: 'kubectl describe pod -n local-path-storage -l app=local-path-provisioner' },
    { type: 'input', text: 'kubectl create namespace csi-test' },
    { type: 'input', text: 'cat <<\'EOF\' | kubectl apply -f -' },
    { type: 'input', text: 'kind: PersistentVolumeClaim + Pod using claim test-pvc' },
    { type: 'input', text: 'EOF' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — troubleshooting drills and cleanup"
---

<Win95Terminal
  title="Command Prompt — triage patterns"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl -n csi-test get pvc,pod; kubectl get pv' },
    { type: 'input', text: 'kubectl -n csi-test describe pvc test-pvc' },
    { type: 'input', text: 'kubectl get pv -o yaml | grep -A5 -B5 local-path' },
    { type: 'input', text: 'kubectl describe node | grep -A10 &quot;Container Runtime&quot;' },
    { type: 'input', text: 'kubectl get events --sort-by=.metadata.creationTimestamp | grep -i cri' },
    { type: 'input', text: 'kubectl describe node | grep -A5 -B5 &quot;PodCIDR&quot;' },
    { type: 'input', text: 'kubectl get crd | grep storage; kubectl get pods -A | grep csi' },
    { type: 'input', text: 'kubectl delete namespace csi-test' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 07 — Key Commands"
windowIcon: "📋"
statusText: "Week 04 · Lab 07 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl config use-context kind-lab` | Use local cluster context |
| `kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.containerRuntimeVersion}'` | Show runtime version |
| `docker exec -it kind-lab-control-plane bash` | Shell into kind node |
| `ls -la /run/containerd/containerd.sock` | Verify CRI socket |
| `ps aux | grep containerd` | Verify containerd process |
| `crictl info | head -20` | Inspect CRI info |
| `ls -la /etc/cni/net.d/` | List CNI configs |
| `cat /etc/cni/net.d/10-kindnet.conflist` | Inspect kindnet CNI config |
| `ls -la /opt/cni/bin/` | List CNI binaries |
| `kubectl get pods -n kube-system | grep -E "(kindnet|flannel|calico|cilium)"` | Find CNI pods |
| `kubectl describe pod -n kube-system -l app=kindnet` | Inspect kindnet pod |
| `kubectl delete pod -n kube-system -l app=kindnet` | Simulate CNI restart/failure |
| `kubectl run cni-test --image=nginx:1.20 --rm -it --restart=Never -- echo "test"` | Test pod start behavior |
| `kubectl get pod cni-test` | Check cni-test pod status |
| `kubectl describe pod cni-test` | Inspect CNI-related events |
| `kubectl delete pod cni-test --ignore-not-found` | Cleanup test pod |
| `kubectl get storageclass` | List storage classes |
| `kubectl describe storageclass standard` | Inspect default storage class |
| `kubectl get pods -n kube-system | grep -E "(csi|storage|local-path)"` | Find storage pods |
| `kubectl describe pod -n local-path-storage -l app=local-path-provisioner` | Inspect local-path provisioner |
| `kubectl create namespace csi-test` | Create storage test namespace |
| `cat <<'EOF' | kubectl apply -f -` | Apply PVC + pod test manifests |
| `kubectl -n csi-test get pvc,pod` | Check PVC/pod status |
| `kubectl get pv` | List provisioned PVs |
| `kubectl -n csi-test describe pvc test-pvc` | PVC event diagnostics |
| `kubectl get pv -o yaml | grep -A5 -B5 local-path` | Inspect local-path PV details |
| `kubectl describe node | grep -A10 "Container Runtime"` | CRI diagnostics from node |
| `kubectl get events --sort-by=.metadata.creationTimestamp | grep -i cri` | Search events for runtime errors |
| `kubectl describe node | grep -A5 -B5 "PodCIDR"` | CNI-related node networking info |
| `kubectl get crd | grep storage` | Show storage-related CRDs |
| `kubectl get pods -A | grep csi` | Show CSI pods |
| `kubectl delete namespace csi-test` | Cleanup namespace |
