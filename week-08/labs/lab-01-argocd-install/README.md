![Lab 01 Install ArgoCD on kind with Helm](../../../assets/generated/week-08-lab-01/hero.png)
![Lab 01 ArgoCD install and UI workflow](../../../assets/generated/week-08-lab-01/flow.gif)

---

# Lab 1: Install ArgoCD on kind with Helm

**Time:** 40 minutes
**Objective:** Install ArgoCD on your local kind cluster using Helm and access the UI

---

## The Story

You've been deploying to Kubernetes by hand — `kubectl apply` after every change. That's fine for learning, but it doesn't scale and it doesn't leave an audit trail. In production, a GitOps operator watches your repo and syncs the cluster automatically.

This lab sets up that operator: ArgoCD on your cluster, under your control. In Lab 3, you'll point it at your portfolio fork and watch the full loop close. First, you need the infrastructure.

We're using Helm to install it because you already know Helm from Week 5. The ArgoCD Helm chart is one of the most popular charts in the ecosystem, and configuring it with a `values.yaml` is how most teams actually deploy it.

---

## Starting Point

You should have a kind cluster running (from Week 7, or create a fresh one). You also need Helm installed.

```bash
kind version
helm version
kubectl cluster-info
```

If you need a fresh cluster:

```bash
kind create cluster --name lab
```

### Fork the Portfolio Template

You'll need this in Lab 3, but fork it now so the CI pipeline can start running on your repo while you work through Labs 1 and 2.

1. Go to the [`container-devsecops-template`](https://github.com/shart-cloud/container-devsecops-template) repo on GitHub
2. Click **Fork** (keep the default name)
3. Clone your fork locally:

```bash
gh repo clone <YOUR_GITHUB_USERNAME>/container-devsecops-template
cd container-devsecops-template
```

4. Go to your fork's **Actions** tab and enable workflows if prompted

Come back to this directory for the ArgoCD install.

---

## Part 1: Add the ArgoCD Helm Repo

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

---

## Part 2: Review the Values File

A starter `values.yaml` is in [`starter/`](./starter/). Key settings:

- **Dex disabled** — we don't need an external identity provider for local dev
- **Insecure mode** — skips TLS so port-forward works without cert warnings
- **30-second reconciliation** — ArgoCD checks Git every 30s instead of the default 3 minutes (faster demos)
- **Reasonable resource requests** — sized for kind, not production

Read through it before installing. Understand what you're configuring.

---

## Part 3: Install ArgoCD

```bash
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f starter/values.yaml
```

Wait for all pods to be ready:

```bash
kubectl get pods -n argocd -w
```

You should see pods for the API server, repo server, application controller, and Redis (ArgoCD's internal cache).

---

## Part 4: Access the UI

Port-forward the ArgoCD server:

```bash
kubectl port-forward service/argocd-server -n argocd 8080:443 &
```

Open: `http://localhost:8080`

Get the admin password:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

Log in with:
- Username: `admin`
- Password: (the output from above)

---

## Part 5: Tour the UI

Take a minute to explore:

1. **Applications** — empty for now. In Lab 3, your portfolio will appear here.
2. **Settings → Repositories** — no repos connected yet. ArgoCD will pull from your public fork without needing credentials.
3. **Settings → Projects** — `default` project exists, that's where we'll work.

---

## Checkpoint

You are done when:
- ArgoCD pods are all Running in the `argocd` namespace
- You can access the UI at `localhost:8080`
- You can log in as admin
- You understand what the `values.yaml` settings control
- You've forked the portfolio template and enabled Actions on your fork
