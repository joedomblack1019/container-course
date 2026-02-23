---
theme: default
title: Week 04 Lab 04b - kubeadm Full Lifecycle on VirtualBox
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 04b · kubeadm Full Lifecycle on VirtualBox"
---

# kubeadm Full Lifecycle on VirtualBox
## Lab 04b

- Provision multi-VM infrastructure and prepare all nodes
- Initialize control plane, install CNI, and join workers
- Perform control-plane and worker upgrade sequence
- Reset cluster state and destroy VMs safely

---
layout: win95
windowTitle: "Lifecycle Scope"
windowIcon: "🖥"
statusText: "Week 04 · Lab 04b · init -> join -> upgrade -> reset"
---

## End-to-End kubeadm Operations

| Phase | Primary outcome |
|---|---|
| Infra prep | 3 VMs with network + required binaries |
| Bootstrap | `kubeadm init` control plane operational |
| Networking | Calico/Cilium installed, nodes become Ready |
| Join + verify | workers attached and workloads scheduled |
| Upgrade + reset | safe maintenance + teardown practice |

---
layout: win95-terminal
termTitle: "Command Prompt — VM provisioning and node prep"
---

<Win95Terminal
  title="Command Prompt — infrastructure"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd starter/' },
    { type: 'input', text: 'vagrant up' },
    { type: 'input', text: 'vagrant ssh control-plane' },
    { type: 'input', text: 'sudo bash /vagrant/preflight-check.sh' },
    { type: 'input', text: 'sudo bash /vagrant/install-k8s-packages.sh' },
    { type: 'input', text: 'vagrant ssh worker-1 && sudo bash /vagrant/preflight-check.sh && sudo bash /vagrant/install-k8s-packages.sh' },
    { type: 'input', text: 'vagrant ssh worker-2 && sudo bash /vagrant/preflight-check.sh && sudo bash /vagrant/install-k8s-packages.sh' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — control plane init and CNI"
---

<Win95Terminal
  title="Command Prompt — bootstrap and networking"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --control-plane-endpoint=192.168.56.10 --apiserver-advertise-address=192.168.56.10' },
    { type: 'input', text: 'mkdir -p $HOME/.kube; sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config; sudo chown $(id -u):$(id -g) $HOME/.kube/config' },
    { type: 'input', text: 'kubectl get nodes; kubectl get pods -n kube-system' },
    { type: 'input', text: 'kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml' },
    { type: 'input', text: 'kubectl wait --for=condition=Ready pods -l app.kubernetes.io/name=calico-node -n kube-system --timeout=300s' },
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'kubectl get crd | grep calico; kubectl get daemonset -n kube-system calico-node' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — worker join and verification"
---

<Win95Terminal
  title="Command Prompt — join workflow"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'sudo kubeadm join 192.168.56.10:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>' },
    { type: 'input', text: 'kubeadm token create --print-join-command' },
    { type: 'input', text: 'kubectl get nodes -o wide' },
    { type: 'input', text: 'kubectl get pods -A' },
    { type: 'input', text: 'bash /vagrant/verify-cluster.sh' },
    { type: 'input', text: 'kubectl create deployment nginx-test --image=nginx:1.20 --replicas=3' },
    { type: 'input', text: 'kubectl get pods -o wide' },
    { type: 'input', text: 'kubectl run network-test --image=busybox:1.36 --rm -it --restart=Never -- nslookup kubernetes.default.svc.cluster.local' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — upgrade, reset, destroy"
---

<Win95Terminal
  title="Command Prompt — maintenance lifecycle"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'sudo apt-cache madison kubeadm | grep 1.32; sudo kubeadm upgrade plan; sudo kubeadm upgrade apply v1.32.0' },
    { type: 'input', text: 'sudo kubeadm upgrade node' },
    { type: 'input', text: 'kubectl drain worker-1 --ignore-daemonsets --force; kubectl uncordon worker-1' },
    { type: 'input', text: 'kubectl drain worker-2 --ignore-daemonsets --force; kubectl uncordon worker-2' },
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'sudo kubeadm reset --force; sudo rm -rf /etc/kubernetes/ /var/lib/kubelet/ /var/lib/etcd/ /etc/cni/net.d/ /opt/cni/bin/' },
    { type: 'input', text: 'sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X' },
    { type: 'input', text: 'vagrant destroy -f' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 04b — Key Commands"
windowIcon: "📋"
statusText: "Week 04 · Lab 04b · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `vagrant up` | Provision all VirtualBox VMs |
| `vagrant ssh control-plane` | SSH into control plane VM |
| `sudo bash /vagrant/preflight-check.sh` | Host preflight config |
| `sudo bash /vagrant/install-k8s-packages.sh` | Install containerd/kube* binaries |
| `sudo kubeadm init ...` | Initialize control plane |
| `mkdir -p $HOME/.kube` | Prepare kubeconfig path |
| `sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config` | Copy admin kubeconfig |
| `kubectl get nodes` | Verify node status |
| `kubectl apply -f <calico.yaml>` | Install Calico CNI |
| `kubectl wait --for=condition=Ready ... calico-node ...` | Wait for CNI readiness |
| `kubectl get crd | grep calico` | Inspect Calico CRDs |
| `kubectl delete -f <calico.yaml>` | Remove Calico (optional swap) |
| `cilium install` | Install Cilium (optional) |
| `cilium status` | Verify Cilium health |
| `sudo kubeadm join ...` | Join worker node |
| `kubeadm token create --print-join-command` | Regenerate join command |
| `bash /vagrant/verify-cluster.sh` | Run verification script |
| `kubectl create deployment nginx-test --image=nginx:1.20 --replicas=3` | Create test workload |
| `kubectl run network-test ... nslookup ...` | Validate DNS/networking |
| `sudo kubeadm upgrade plan` | Plan version upgrade |
| `sudo kubeadm upgrade apply v1.32.0` | Upgrade control plane |
| `sudo kubeadm upgrade node` | Upgrade worker node internals |
| `kubectl drain worker-1 --ignore-daemonsets --force` | Drain node for maintenance |
| `kubectl uncordon worker-1` | Return node to schedulable state |
| `sudo kubeadm reset --force` | Reset node from cluster |
| `sudo rm -rf /etc/kubernetes/ ...` | Remove remaining cluster artifacts |
| `vagrant destroy -f` | Destroy all VMs |
