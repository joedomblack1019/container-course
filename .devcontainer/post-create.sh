#!/bin/bash
set -e

echo "Setting up Container Fundamentals environment..."

echo "Installing additional tools (vim, neovim, ncat, age)..."
sudo apt-get update -qq
sudo apt-get install -y vim neovim ncat age unzip

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  aarch64|arm64) ARCH="arm64" ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

echo "Verifying Docker..."
docker_ready=0
for _ in $(seq 1 30); do
  if docker info >/dev/null 2>&1; then
    docker_ready=1
    break
  fi
  sleep 1
done

if [ "$docker_ready" -eq 1 ]; then
  docker --version || true
  docker compose version || true

  echo "Skipping image pre-pull."
else
  echo "Warning: Docker daemon did not become ready in time; skipping pre-pull."
  echo "If needed later, run: docker run hello-world"
fi

echo "Verifying Python..."
python3 --version
pip3 --version

# --- Week 04: Kubernetes tools ---

echo "Installing kind..."
curl -fsSLo ./kind "https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-${ARCH}"
sudo install -m 755 ./kind /usr/local/bin/kind
rm ./kind
kind version

echo "Installing kubeadm..."
K8S_STABLE_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
curl -fsSLo ./kubeadm "https://dl.k8s.io/release/${K8S_STABLE_VERSION}/bin/linux/${ARCH}/kubeadm"
sudo install -m 755 ./kubeadm /usr/local/bin/kubeadm
rm ./kubeadm
kubeadm version -o short

echo "Installing crictl..."
CRICTL_VERSION=$(curl -fsSL https://api.github.com/repos/kubernetes-sigs/cri-tools/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -fsSLo /tmp/crictl.tar.gz "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz"
tar -xzf /tmp/crictl.tar.gz -C /tmp
sudo install -m 755 /tmp/crictl /usr/local/bin/crictl
rm -f /tmp/crictl /tmp/crictl.tar.gz
crictl --version

echo "Installing etcdctl..."
ETCD_VERSION=$(curl -fsSL https://api.github.com/repos/etcd-io/etcd/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -fsSLo /tmp/etcd.tar.gz "https://github.com/etcd-io/etcd/releases/download/${ETCD_VERSION}/etcd-${ETCD_VERSION}-linux-${ARCH}.tar.gz"
tar -xzf /tmp/etcd.tar.gz -C /tmp
sudo install -m 755 "/tmp/etcd-${ETCD_VERSION}-linux-${ARCH}/etcdctl" /usr/local/bin/etcdctl
rm -rf /tmp/etcd.tar.gz "/tmp/etcd-${ETCD_VERSION}-linux-${ARCH}"
etcdctl version

echo "Installing cloudflared..."
curl -fsSLo ./cloudflared "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}"
sudo install -m 755 ./cloudflared /usr/local/bin/cloudflared
rm ./cloudflared
cloudflared version

echo "Installing kubelogin (kubectl oidc-login plugin)..."
KUBELOGIN_VERSION=$(curl -fsSL https://api.github.com/repos/int128/kubelogin/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -fsSLo /tmp/kubelogin.zip "https://github.com/int128/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin_linux_${ARCH}.zip"
unzip -o -q /tmp/kubelogin.zip -d /tmp/kubelogin
sudo install -m 755 /tmp/kubelogin/kubelogin /usr/local/bin/kubectl-oidc_login
rm -rf /tmp/kubelogin /tmp/kubelogin.zip

# --- Week 05: Secret management tools ---

echo "Installing SOPS..."
SOPS_VERSION=$(curl -fsSL https://api.github.com/repos/getsops/sops/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -fsSLo ./sops "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${ARCH}"
sudo install -m 755 ./sops /usr/local/bin/sops
rm ./sops

echo "Installing kustomize..."
curl -fsSL "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
sudo install -m 755 ./kustomize /usr/local/bin/kustomize
rm ./kustomize

echo "Installing kubeseal..."
KUBESEAL_VERSION=$(curl -fsSL https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -fsSLo ./kubeseal.tar.gz "https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION#v}-linux-${ARCH}.tar.gz"
tar -xzf kubeseal.tar.gz kubeseal
sudo install -m 755 ./kubeseal /usr/local/bin/kubeseal
rm ./kubeseal ./kubeseal.tar.gz

echo "Installing HashiCorp Vault CLI..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update -qq
sudo apt-get install -y vault

# --- Week 08: CI/CD tooling ---

echo "Installing ruff and bandit..."
pip3 install --user --upgrade ruff bandit
sudo ln -sf "$HOME/.local/bin/ruff" /usr/local/bin/ruff
sudo ln -sf "$HOME/.local/bin/bandit" /usr/local/bin/bandit

echo "Installing hadolint..."
HADOLINT_ARCH="x86_64"
if [ "$ARCH" = "arm64" ]; then
  HADOLINT_ARCH="arm64"
fi
curl -fsSLo ./hadolint "https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-${HADOLINT_ARCH}"
sudo install -m 755 ./hadolint /usr/local/bin/hadolint
rm ./hadolint

echo "Installing trivy..."
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin

echo "Installing kubeconform..."
curl -fsSLo /tmp/kubeconform.tar.gz "https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-${ARCH}.tar.gz"
tar -xzf /tmp/kubeconform.tar.gz -C /tmp kubeconform
sudo install -m 755 /tmp/kubeconform /usr/local/bin/kubeconform
rm -f /tmp/kubeconform /tmp/kubeconform.tar.gz

# Create a student workspace directory
mkdir -p ~/labs

echo ""
echo "Environment setup complete!"
echo ""
echo "Installed tools:"
echo "  docker:   $(docker --version 2>/dev/null || echo 'waiting for daemon')"
echo "  kubectl:  $(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)"
echo "  helm:     $(helm version --short 2>/dev/null)"
echo "  kind:     $(kind version 2>/dev/null)"
echo "  kubeadm:  $(kubeadm version -o short 2>/dev/null)"
echo "  crictl:   $(crictl --version 2>/dev/null)"
echo "  etcdctl:  $(etcdctl version 2>/dev/null | head -1)"
echo "  sops:     $(sops --version 2>/dev/null)"
echo "  age:      $(age --version 2>/dev/null)"
echo "  kubeseal: $(kubeseal --version 2>/dev/null)"
echo "  vault:    $(vault version 2>/dev/null)"
echo "  cloudflared: $(cloudflared version 2>/dev/null | head -1)"
echo "  kustomize: $(kustomize version 2>/dev/null)"
echo "  kubelogin: $(kubectl-oidc_login --version 2>/dev/null | head -1)"
echo "  ruff:     $(ruff --version 2>/dev/null)"
echo "  bandit:   $(bandit --version 2>/dev/null | head -1)"
echo "  hadolint: $(hadolint --version 2>/dev/null | head -1)"
echo "  trivy:    $(trivy --version 2>/dev/null | head -1)"
echo "  kubeconform: $(kubeconform -v 2>/dev/null)"
echo ""
echo "Quick verification:"
echo "  docker run hello-world"
echo ""
echo "To get started with Week 1:"
echo "  cd week-01/labs"
echo ""
