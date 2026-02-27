![Lab 01 Install ArgoCD on kind with Helm](../../../assets/generated/week-08-lab-01/hero.png)
![Lab 01 ArgoCD install and UI workflow](../../../assets/generated/week-08-lab-01/flow.gif)

---

# Lab 1: Install ArgoCD on kind with Helm

**Time:** 40 minutes
**Objective:** Install ArgoCD on your local kind cluster using Helm, access the UI, and understand what each component does before you use it in Lab 3.

---

## The Story

Every time you have deployed to Kubernetes so far, you have run `kubectl apply` by hand. That works fine for a lab. In production it is a reliability problem.

If the cluster drifts from your YAML — someone edits a Deployment directly, a rollback gets half-applied, a ConfigMap gets patched in an emergency — there is no automatic recovery. The cluster slowly diverges from what your repo says it should be, and the gap grows silently until something breaks.

A GitOps operator solves this by continuously comparing the cluster state to a Git source and reconciling any drift back to what Git says. You never push to the cluster directly. You push to Git, and the operator does the rest.

ArgoCD is the most widely deployed GitOps operator in the Kubernetes ecosystem. You will install it here, understand its architecture, and point it at your portfolio repo in Lab 3 to close the loop. From that point forward, Git is the source of truth and you stop touching `kubectl apply`.

---

## CKA Objectives Mapped

- Understand cluster component deployment patterns
- Use Helm to install and configure cluster-level tooling
- Interpret pod and service topology for a multi-component system

---

## Background: How ArgoCD Works

### The reconciliation loop

ArgoCD runs a continuous control loop. Every `timeout.reconciliation` seconds (30 seconds in our values, 3 minutes by default), it does three things:

1. **Fetches** the target state from Git — clones the repo, renders the Kustomize or Helm output
2. **Observes** the live state from the Kubernetes API — reads the actual cluster resources
3. **Compares** them — if they differ, the Application is `OutOfSync`
4. **Syncs** (if auto-sync is enabled) — applies the diff to drive the cluster toward the target state

```
+-------------------------------------------------------------+
|                 ArgoCD Reconciliation Loop                  |
|                                                             |
|  +-------------+   clone/render   +---------------------+  |
|  |  Git Repo   |<-----------------| Repo Server         |  |
|  |  (source)   |                  | (kustomize / helm)  |  |
|  +-------------+                  +---------+-----------+  |
|                                             | target state  |
|                                             v               |
|  +-------------+  read live state  +---------------------+ |
|  |  Kubernetes |<------------------| App Controller      | |
|  |   Cluster   |                   | (compare + sync)    | |
|  |   (actual)  |------------------>+                     | |
|  +-------------+  apply diff       +---------------------+ |
+-------------------------------------------------------------+
```

### ArgoCD components

When you install ArgoCD, you get several distinct processes. Understanding what each one does helps you diagnose problems later.

| Component | What it does |
|---|---|
| `argocd-server` | API server and UI. Handles login, application management, and the web interface. |
| `argocd-repo-server` | Clones Git repos, runs Kustomize/Helm, caches rendered manifests. Isolated from the API server for security. |
| `argocd-application-controller` | The heart of ArgoCD. Runs the reconciliation loop — compares target vs live, triggers syncs, tracks health. |
| `argocd-redis` | In-cluster cache. Stores rendered manifests and cluster state to reduce API server load. |
| `argocd-dex-server` | (Optional) SSO identity provider integration. Disabled in our values file for local dev. |

### Why Helm for ArgoCD itself?

The official install method is `kubectl apply -f install.yaml`. Helm wraps that same manifest set but lets you override individual settings with a `values.yaml` rather than editing raw YAML. For a team that needs to reproduce their ArgoCD installation across multiple clusters with consistent configuration, Helm is significantly easier to manage.

**Further reading:**
- [ArgoCD Architecture](https://argo-cd.readthedocs.io/en/stable/operator-manual/architecture/)
- [ArgoCD Getting Started](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Argo Helm Chart](https://github.com/argoproj/argo-helm)

---

## Prerequisites

You need a kind cluster running and Helm installed:

```bash
kind version
helm version
kubectl cluster-info
```

If you need a fresh cluster:

```bash
kind create cluster --name lab
kubectl config use-context kind-lab
```

### Fork the Portfolio Template

You will need this in Lab 3. Fork it now so CI starts running on your repo while you work through Labs 1 and 2.

1. Go to [`devsecops-portfolio-template`](https://github.com/ziyotek-edu/devsecops-portfolio-template) on GitHub
2. Click **Fork** and keep the default name
3. Clone your fork:

```bash
gh repo clone <YOUR_GITHUB_USERNAME>/devsecops-portfolio-template
cd devsecops-portfolio-template
```

4. Go to your fork's **Actions** tab and enable workflows if prompted

Notice: the portfolio template has a full CI pipeline already configured. By forking now, you get pipeline runs on your first commits while you are still setting up ArgoCD — they run in parallel, not sequentially.

---

## Part 1: Add the ArgoCD Helm Repo

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

Verify the chart is available:

```bash
helm search repo argo/argo-cd
```

Notice: the chart name is `argo/argo-cd` — ArgoCD is one chart in the broader Argo project family, which also includes Argo Workflows, Argo Events, and Argo Rollouts. On the CKA you will not use Helm to install ArgoCD, but in production this is the standard approach.

---

## Part 2: Review the Values File

A starter `values.yaml` is in [`starter/`](./starter/). Read through it before installing — understand what you are configuring before you apply it.

Key settings and why they exist:

```yaml
configs:
  params:
    server.insecure: true       # Skip TLS so port-forward works without cert warnings
  cm:
    timeout.reconciliation: 30s # Poll Git every 30s instead of the default 3m
dex:
  enabled: false                # No SSO needed for local dev
```

The resource requests are sized for kind — smaller than what you would use in production. In production, the application controller in particular needs more memory as the number of managed Applications grows.

Notice: `server.insecure: true` is appropriate here because all traffic goes through a local port-forward. In production ArgoCD, you terminate TLS either at the ArgoCD server itself or at an Ingress/Gateway in front of it. Never run ArgoCD in insecure mode on a cluster reachable from the internet.

Operator mindset: always read values files before applying them. A Helm install is only as good as the configuration behind it.

---

## Part 3: Install ArgoCD

```bash
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f starter/values.yaml
```

Watch all pods reach Running:

```bash
kubectl get pods -n argocd -w
```

You should eventually see pods for `argocd-server`, `argocd-repo-server`, `argocd-application-controller`, `argocd-redis`, and `argocd-notifications-controller`.

While you wait, check what services were created:

```bash
kubectl get svc -n argocd
```

Notice: `argocd-server` is a `ClusterIP` service — not exposed outside the cluster. You access it through a port-forward in local dev. In production you would put an Ingress or LoadBalancer in front of it, or use ArgoCD's Ingress configuration in the Helm values.

Operator mindset: verify pods and services independently. A pod can be Running while its service is misconfigured, or vice versa.

---

## Part 4: Access the UI

Port-forward the ArgoCD server:

```bash
kubectl port-forward service/argocd-server -n argocd 8080:443 &
```

Open: `http://localhost:8080`

Get the initial admin password:

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' | base64 -d && echo
```

Log in with username `admin` and the password from above.

Notice: `argocd-initial-admin-secret` is a Kubernetes Secret that ArgoCD creates on first install with a generated password. In production you would change this immediately and integrate ArgoCD with your SSO provider via Dex or another OIDC provider. The secret name includes "initial" for a reason — it is meant to be rotated, not used permanently.

Operator mindset: any generated credential is a temporary credential. Rotate it before the cluster is shared with a team.

---

## Part 5: Tour the UI

Take a few minutes to explore before Lab 3 puts real content here.

**Applications** — empty now. In Lab 3 your portfolio Application will appear here. Each Application card shows sync status (does Git match the cluster?), health status (are pods healthy?), and the last sync time.

**Settings → Repositories** — no repos connected yet. ArgoCD will pull your public fork without credentials. For private repos you would add an SSH key or token here.

**Settings → Projects** — the `default` project exists. Projects define what repos, clusters, and namespaces a set of Applications can target. For a single team on a single cluster, `default` is usually sufficient.

Notice: the distinction between ArgoCD `Applications` and `Projects` matters. An `Application` is "watch this path in this repo and sync it to this cluster/namespace." A `Project` is a security boundary that limits what repos and namespaces Applications in that project can touch. You will work exclusively in the `default` project in this course, but in a multi-team cluster each team typically gets its own Project.

---

## Verification Checklist

You are done when:

- All ArgoCD pods are Running in the `argocd` namespace
- You can access the UI at `http://localhost:8080` and log in as admin
- You can explain what each of the four main ArgoCD components does
- You understand what `server.insecure` and `timeout.reconciliation` control in the values file
- You have forked the portfolio template and enabled Actions on your fork

---

## Reinforcement Scenarios

- `jerry-argocd-wont-sync`
- `jerry-repo-server-crash`
