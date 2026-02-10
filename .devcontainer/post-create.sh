#!/bin/bash
set -e

echo "Setting up Container Fundamentals environment..."

echo "Installing additional tools (vim, neovim, ncat, age)..."
sudo apt-get update -qq
sudo apt-get install -y vim neovim ncat age unzip

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
curl -fsSLo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64
sudo install -m 755 ./kind /usr/local/bin/kind
rm ./kind
kind version

echo "Installing cloudflared..."
curl -fsSLo ./cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
sudo install -m 755 ./cloudflared /usr/local/bin/cloudflared
rm ./cloudflared
cloudflared version

echo "Installing kubelogin (kubectl oidc-login plugin)..."
KUBELOGIN_VERSION=$(curl -fsSL https://api.github.com/repos/int128/kubelogin/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -fsSLo /tmp/kubelogin.zip "https://github.com/int128/kubelogin/releases/download/${KUBELOGIN_VERSION}/kubelogin_linux_amd64.zip"
unzip -o -q /tmp/kubelogin.zip -d /tmp/kubelogin
sudo install -m 755 /tmp/kubelogin/kubelogin /usr/local/bin/kubectl-oidc_login
rm -rf /tmp/kubelogin /tmp/kubelogin.zip

# --- Week 05: Secret management tools ---

echo "Installing SOPS..."
SOPS_VERSION=$(curl -fsSL https://api.github.com/repos/getsops/sops/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -fsSLo ./sops "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64"
sudo install -m 755 ./sops /usr/local/bin/sops
rm ./sops

echo "Installing kubeseal..."
KUBESEAL_VERSION=$(curl -fsSL https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -fsSLo ./kubeseal.tar.gz "https://github.com/bitnami-labs/sealed-secrets/releases/download/${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION#v}-linux-amd64.tar.gz"
tar -xzf kubeseal.tar.gz kubeseal
sudo install -m 755 ./kubeseal /usr/local/bin/kubeseal
rm ./kubeseal ./kubeseal.tar.gz

echo "Installing HashiCorp Vault CLI..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update -qq
sudo apt-get install -y vault

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
echo "  sops:     $(sops --version 2>/dev/null)"
echo "  age:      $(age --version 2>/dev/null)"
echo "  kubeseal: $(kubeseal --version 2>/dev/null)"
echo "  vault:    $(vault version 2>/dev/null)"
echo "  cloudflared: $(cloudflared version 2>/dev/null | head -1)"
echo "  kubelogin: $(kubectl-oidc_login --version 2>/dev/null | head -1)"
echo ""
echo "Quick verification:"
echo "  docker run hello-world"
echo ""
echo "To get started with Week 1:"
echo "  cd week-01/labs"
echo ""
