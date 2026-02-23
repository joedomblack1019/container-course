---
theme: default
title: Week 04 Lab 04 - kubeadm Bootstrap Foundations
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 04 · kubeadm Bootstrap Foundations"
---

# kubeadm Bootstrap Foundations
## Lab 04

- Run kubeadm preflight checks and fix host prerequisites
- Initialize disposable control plane and configure kubectl access
- Install CNI, inspect manifests/certs, and generate join command
- Practice safe reset and rebuild sequence

---
layout: win95
windowTitle: "Bootstrap Artifacts"
windowIcon: "🛠"
statusText: "Week 04 · Lab 04 · Files kubeadm generates"
---

## What kubeadm Writes

| Path | Purpose |
|---|---|
| `/etc/kubernetes/manifests` | static pod manifests for API server, etcd, scheduler, controller-manager |
| `/etc/kubernetes/*.conf` | kubeconfig files for admin and components |
| `/etc/kubernetes/pki` | CA and component certificates/keys |

> Static pods let kubelet bootstrap control-plane components from disk before normal API workflows exist.

---
layout: win95-terminal
termTitle: "Command Prompt — prerequisites and preflight"
---

<Win95Terminal
  title="Command Prompt — host readiness"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl version --client' },
    { type: 'input', text: 'kubeadm version' },
    { type: 'input', text: 'kubelet --version' },
    { type: 'input', text: 'crictl --version || echo &quot;crictl optional but recommended&quot;' },
    { type: 'input', text: 'sudo kubeadm init phase preflight' },
    { type: 'input', text: 'sudo systemctl status kubelet --no-pager' },
    { type: 'input', text: 'sudo systemctl status containerd --no-pager' },
    { type: 'input', text: 'swapon --show' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — baseline kernel/network fixes"
---

<Win95Terminal
  title="Command Prompt — sysctl/modules"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'lsmod | grep br_netfilter || true' },
    { type: 'input', text: 'sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward' },
    { type: 'input', text: 'cat <<\'EOF\' | sudo tee /etc/modules-load.d/k8s.conf' },
    { type: 'input', text: 'overlay' },
    { type: 'input', text: 'br_netfilter' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'sudo modprobe overlay && sudo modprobe br_netfilter' },
    { type: 'input', text: 'sudo sysctl --system' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — init control plane and configure kubectl"
---

<Win95Terminal
  title="Command Prompt — kubeadm init"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --upload-certs' },
    { type: 'input', text: 'mkdir -p &quot;$HOME/.kube&quot;' },
    { type: 'input', text: 'sudo cp -i /etc/kubernetes/admin.conf &quot;$HOME/.kube/config&quot;' },
    { type: 'input', text: 'sudo chown &quot;$(id -u):$(id -g)&quot; &quot;$HOME/.kube/config&quot;' },
    { type: 'input', text: 'kubectl get nodes -o wide' },
    { type: 'input', text: 'kubectl get pods -n kube-system' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — CNI install, artifacts, join, reset"
---

<Win95Terminal
  title="Command Prompt — verify and teardown"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml' },
    { type: 'input', text: 'kubectl get nodes -w' },
    { type: 'input', text: 'sudo ls -1 /etc/kubernetes/; sudo ls -1 /etc/kubernetes/manifests; sudo ls -1 /etc/kubernetes/pki | head -20' },
    { type: 'input', text: 'kubeadm token create --print-join-command' },
    { type: 'input', text: 'kubectl config current-context; kubectl cluster-info' },
    { type: 'input', text: 'sudo journalctl -u kubelet -n 80 --no-pager' },
    { type: 'input', text: 'sudo kubeadm reset -f; sudo rm -rf /etc/cni/net.d; rm -rf &quot;$HOME/.kube/config&quot;' },
    { type: 'input', text: 'sudo systemctl restart containerd kubelet' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 04 — Key Commands"
windowIcon: "📋"
statusText: "Week 04 · Lab 04 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl version --client` | Verify kubectl client |
| `kubeadm version` | Verify kubeadm |
| `kubelet --version` | Verify kubelet |
| `crictl --version || echo "crictl optional but recommended"` | Check CRI CLI availability |
| `sudo kubeadm init phase preflight` | Run kubeadm preflight checks |
| `sudo systemctl status kubelet --no-pager` | Inspect kubelet service |
| `sudo systemctl status containerd --no-pager` | Inspect container runtime |
| `swapon --show` | Verify swap is off |
| `lsmod | grep br_netfilter || true` | Verify kernel module |
| `sysctl net.bridge.bridge-nf-call-iptables net.ipv4.ip_forward` | Check networking sysctls |
| `sudo modprobe overlay` | Load overlay module |
| `sudo modprobe br_netfilter` | Load bridge netfilter module |
| `sudo sysctl --system` | Apply sysctl config |
| `sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --upload-certs` | Bootstrap control plane |
| `mkdir -p "$HOME/.kube"` | Prepare kubeconfig directory |
| `sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"` | Copy admin kubeconfig |
| `sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"` | Fix kubeconfig ownership |
| `kubectl get nodes -o wide` | Verify node/API connectivity |
| `kubectl get pods -n kube-system` | Check system pod states |
| `kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml` | Install Flannel CNI |
| `kubectl get nodes -w` | Watch readiness transition |
| `sudo ls -1 /etc/kubernetes/` | List kubeadm generated files |
| `sudo ls -1 /etc/kubernetes/manifests` | List static pod manifests |
| `sudo ls -1 /etc/kubernetes/pki | head -20` | List PKI files |
| `kubeadm token create --print-join-command` | Generate worker join command |
| `kubectl config current-context` | Verify active context |
| `kubectl cluster-info` | Verify control-plane endpoint |
| `sudo journalctl -u kubelet -n 80 --no-pager` | Kubelet troubleshooting logs |
| `kubectl describe node "$(kubectl get nodes -o name | head -1 | cut -d/ -f2)"` | Node diagnostic details |
| `sudo kubeadm reset -f` | Reset cluster state |
| `sudo rm -rf /etc/cni/net.d` | Remove CNI config |
| `rm -rf "$HOME/.kube/config"` | Remove user kubeconfig |
| `sudo systemctl restart containerd kubelet` | Runtime + kubelet restart |
