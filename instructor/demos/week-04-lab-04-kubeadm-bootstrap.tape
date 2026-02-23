# kubeadm Bootstrap Demo - Shows key commands and workflows
# Week 04, Lab 04 - Critical CKA cluster initialization skills

Output ../../assets/generated/week-04-lab-04/demo.gif

Set Shell "bash"
Set FontFamily "Monaspace Neon"
Set FontSize 16
Set Width 1200
Set Height 600
Set Theme "Catppuccin Mocha"
Set TypingSpeed 40ms
Set Padding 20

# --- Hidden Setup ---
Hide
Type "export PS1='$ '"
Enter
Sleep 300ms
Type "clear"
Enter
Sleep 500ms
Show

# --- Visible Demo ---

Type "# kubeadm Bootstrap Demo - Lab 04"
Enter
Type "# Shows cluster initialization workflow and key inspection commands"
Enter
Sleep 2s

Type "# Part 1: Prerequisites Check"
Enter
Type "kubectl version --client"
Enter
Sleep 2s

Type "kubeadm version"
Enter
Sleep 2s

Type "# Part 2: Preflight Checks (shows what kubeadm validates)"
Enter
Type "sudo kubeadm init phase preflight"
Enter
Type "# [preflight] Running pre-flight checks"
Enter
Type "# [preflight] Pulling images required for setting up a Kubernetes cluster"
Enter
Type "# [preflight] This might take a minute or two, depending on the speed"
Enter
Sleep 3s

Type "# Part 3: Initialize Control Plane"
Enter
Type "sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --upload-certs"
Enter
Type "# [init] Using Kubernetes version: v1.28.2"
Enter
Type "# [preflight] Running pre-flight checks"
Enter
Type "# [certs] Using certificateDir folder '/etc/kubernetes/pki'"
Enter
Type "# [certs] Generating 'ca' certificate and key"
Enter
Type "# [certs] Generating 'apiserver' certificate and key"
Enter
Type "# [etcd] Creating static Pod manifest for local etcd in '/etc/kubernetes/manifests'"
Enter
Type "# [control-plane] Using manifest folder '/etc/kubernetes/manifests'"
Enter
Type "# [control-plane] Creating static Pod manifest for 'kube-apiserver'"
Enter
Type "# [control-plane] Creating static Pod manifest for 'kube-controller-manager'"
Enter
Type "# [control-plane] Creating static Pod manifest for 'kube-scheduler'"
Enter
Type "# [kubelet-start] Writing kubelet environment file"
Enter
Type "# [kubelet-start] Starting the kubelet"
Enter
Type "# [wait-control-plane] Waiting for the kubelet to boot up the control plane"
Enter
Type "#"
Enter
Type "# Your Kubernetes control-plane has initialized successfully!"
Enter
Sleep 4s

Type "# Part 4: Configure kubectl"
Enter
Type "mkdir -p $HOME/.kube"
Enter
Type "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config"
Enter
Type "sudo chown $(id -u):$(id -g) $HOME/.kube/config"
Enter
Sleep 2s

Type "# Part 5: Verify Initial State"
Enter
Type "kubectl get nodes -o wide"
Enter
Type "# NAME           STATUS     ROLES           AGE   VERSION   INTERNAL-IP"
Enter
Type "# control-plane  NotReady   control-plane   30s   v1.28.2   192.168.1.10"
Enter
Sleep 2s

Type "kubectl get pods -n kube-system"
Enter
Type "# NAME                                   READY   STATUS    RESTARTS"
Type "# etcd-control-plane                   1/1     Running   0"
Enter
Type "# kube-apiserver-control-plane         1/1     Running   0"
Enter
Type "# kube-controller-manager-control-plane 1/1     Running   0"
Enter
Type "# kube-scheduler-control-plane         1/1     Running   0"
Enter
Type "# coredns-5d78c9869d-abc123            0/1     Pending   0"
Enter
Type "# coredns-5d78c9869d-def456            0/1     Pending   0"
Enter
Sleep 3s

Type "# Part 6: Install CNI (Network Plugin)"
Enter
Type "kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml"
Enter
Type "# namespace/kube-flannel created"
Enter
Type "# clusterrole.rbac.authorization.k8s.io/flannel created"
Enter
Type "# daemonset.apps/kube-flannel-ds created"
Enter
Sleep 2s

Type "# Watch node become Ready"
Enter
Type "kubectl get nodes"
Enter
Type "# NAME           STATUS   ROLES           AGE   VERSION"
Enter
Type "# control-plane  Ready    control-plane   2m    v1.28.2"
Enter
Sleep 2s

Type "# Part 7: Inspect Critical Paths (CKA Key Skills)"
Enter
Type "sudo ls /etc/kubernetes/"
Enter
Type "# admin.conf  controller-manager.conf  kubelet.conf  manifests  pki  scheduler.conf"
Enter
Sleep 1s

Type "sudo ls /etc/kubernetes/manifests"
Enter
Type "# etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml"
Enter
Sleep 2s

Type "sudo ls /etc/kubernetes/pki | head -10"
Enter
Type "# apiserver.crt      ca.crt           front-proxy-ca.crt"
Enter
Type "# apiserver.key      ca.key           front-proxy-ca.key"
Enter
Type "# apiserver-kubelet-client.crt        front-proxy-client.crt"
Enter
Type "# apiserver-kubelet-client.key        front-proxy-client.key"
Enter
Type "# ca.srl             etcd/"
Enter
Sleep 2s

Type "# Part 8: Generate Join Command"
Enter
Type "kubeadm token create --print-join-command"
Enter
Type "# kubeadm join 192.168.1.10:6443 --token abc123.def456789abc123 \\"
Enter
Type "#     --discovery-token-ca-cert-hash sha256:1234567890abcdef..."
Enter
Sleep 2s

Type "# Key Components Demonstrated:"
Enter
Type "# ✅ Preflight validation"
Enter
Type "# ✅ Certificate generation in /etc/kubernetes/pki"
Enter
Type "# ✅ Static pod manifests in /etc/kubernetes/manifests"
Enter
Type "# ✅ CNI installation for network readiness"
Enter
Type "# ✅ Join token generation for worker nodes"
Enter
Sleep 2s

Type "# This is the foundation for CKA cluster management!"
Enter

Sleep 3s