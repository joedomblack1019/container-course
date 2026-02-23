![Lab 03 Deploy to Dev via GitOps](../../../assets/generated/week-04-lab-03/hero.png)
![Lab 03 GitOps submission workflow](../../../assets/generated/week-04-lab-03/flow.gif)

---

# Lab 3: Deploy to Dev via GitOps

**Time:** 25 minutes
**Objective:** Deploy your app to a dev namespace on the shared cluster by submitting Kubernetes manifests to the infrastructure repo via GitOps

---

## What is GitOps?

Up to this point, you've deployed to Kubernetes by running `kubectl apply` from your laptop. That works, but think about what happens at scale: multiple people deploying different things, no record of who changed what, no easy way to undo a bad deploy, and no guarantee that what's running in the cluster matches what's in your repo.

**GitOps** is an operational model where **git is the single source of truth** for your infrastructure. Instead of pushing changes to the cluster directly, you push changes to a git repository, and an automated controller running inside the cluster pulls those changes and applies them. The cluster continuously reconciles its actual state to match the desired state declared in git.

This gives you several things for free:

- **Audit trail** — every change is a git commit with an author, timestamp, and diff
- **Rollbacks** — revert a commit, and the cluster reverts with it
- **Consistency** — the cluster always converges to what's in `main`, even if someone manually edits something with `kubectl`
- **Collaboration** — infrastructure changes go through pull requests with review, just like application code

**ArgoCD** is the GitOps controller we use on this cluster. It watches a git repository, detects when files change, and syncs those changes to Kubernetes. When your PR is merged into `main`, ArgoCD notices the new manifests, creates your namespaces, and deploys your pods — without anyone running `kubectl apply`.

---

## What are Namespaces?

In Lab 2, everything ran in the `default` namespace on your local kind cluster. That's fine when you're the only user. On a shared cluster with 20+ students, you need isolation.

A **namespace** is a logical partition inside a Kubernetes cluster. Resources within a namespace — pods, services, deployments — only need unique names within that namespace. Two students can both have a deployment called `student-app` as long as they're in different namespaces.

Namespaces provide:

- **Name scoping** — your `student-app` Service won't collide with another student's `student-app` Service
- **Access control** — RBAC policies can grant you full access to your dev namespace but read-only access to prod
- **Resource quotas** — administrators can limit how much CPU and memory each namespace can consume

In this lab, you'll create a dev namespace: `student-<username>-dev`. When your app reads `metadata.namespace` through the Downward API, it knows which environment it's running in. You'll add a prod namespace as homework — same process, different namespace.

> **How Services work across namespaces:** A Service is only reachable by its short name (`student-app-svc`) from within the same namespace. From a different namespace, you use the fully qualified DNS name: `student-app-svc.student-<username>-dev.svc.cluster.local`. This is how the routing layer reaches your app — it uses the full DNS name to cross namespace boundaries.

---

## How This Works

You fork the infrastructure repo, scaffold manifests for your dev environment, and open a PR. After merge, ArgoCD deploys your app automatically.

```
  You (local)                    GitHub                     Shared Cluster
  ──────────                    ──────                     ──────────────

  1. Build image ──────────►  2. Push to GHCR
                                     │
  3. Fork talos-gitops         4. Scaffold manifests
     Create branch                  for dev/
          │                          │
          └──────────────────► 5. Open PR to
                                  talos-gitops
                                     │
                              6. PR merged ──────────►  7. ArgoCD syncs
                                                              │
                                                     8. Dev namespace created:
                                                        student-<you>-dev
```

Your directory in `talos-gitops` looks like this:

```
student-infra/students/<username>/
  kustomization.yaml         # points to dev/
  dev/
    kustomization.yaml       # sets namespace: student-<username>-dev
    namespace.yaml
    deployment.yaml
    service.yaml
```

The `kustomization.yaml` uses the Kustomize namespace transformer — the individual manifests don't hardcode a namespace. For homework, you'll add a `prod/` directory following the same pattern.

> **Reference:** The instructor's directory at `student-infra/students/jlgore/` is a complete working example. Look at it whenever you're unsure about a field or structure.

---

## Part 1: Push Your Image to GHCR

You did this in Week 1, but now with the v4 tag:

```bash
cd week-04/labs/lab-02-deploy-and-scale/starter

# Tag for GHCR
docker tag student-app:v4 ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4

# Log in to GHCR (use a Personal Access Token with packages:write scope)
echo $GITHUB_TOKEN | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin

# Push
docker push ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4
```

> **Codespace users:** The default `$GITHUB_TOKEN` in GitHub Codespaces does **not** have permission to create packages in the org. You'll get `permission_denied: installation not allowed to Create organization package`. To fix this, create a **Personal Access Token (classic)** at [Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens) with the `write:packages` scope, then log in with that instead:
>
> ```bash
> echo "ghp_YOUR_TOKEN_HERE" | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin
> ```

### Make It Public

Your image must be publicly pullable so the shared cluster can access it without credentials:

1. Go to `https://github.com/<YOUR_USERNAME>?tab=packages`
2. Click on `container-course-app`
3. **Package settings** → **Danger zone** → Change visibility to **Public**

---

## Part 2: Fork and Clone talos-gitops

You have triage access to the infrastructure repo. Fork it so you can push a branch:

1. Go to [github.com/ziyotek-edu/talos-gitops](https://github.com/ziyotek-edu/talos-gitops) and click **Fork**
2. Clone your fork:

```bash
cd ~/
git clone https://github.com/<YOUR_GITHUB_USERNAME>/talos-gitops.git
cd talos-gitops
git checkout -b week04/<YOUR_GITHUB_USERNAME>
```

---

## Part 3: Create Your Directory and Scaffold Manifests

### Create the directory structure

```bash
mkdir -p student-infra/students/<YOUR_GITHUB_USERNAME>/dev
```

### Scaffold with kubectl

Use `kubectl create --dry-run=client -o yaml` to generate starting manifests:

```bash
cd student-infra/students/<YOUR_GITHUB_USERNAME>/dev

kubectl create namespace student-<YOUR_GITHUB_USERNAME>-dev \
  --dry-run=client -o yaml > namespace.yaml

kubectl create deployment student-app \
  --image=ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v4 \
  --dry-run=client -o yaml > deployment.yaml

kubectl create service clusterip student-app-svc \
  --tcp=80:5000 \
  --dry-run=client -o yaml > service.yaml
```

### Edit the scaffolded files

The `kubectl create` output is minimal. You need to add labels, environment variables, probes, and resource limits. Open the instructor's example at `student-infra/students/jlgore/` and use it as reference.

**`namespace.yaml`** — add course labels:

```yaml
  labels:
    app.kubernetes.io/managed-by: gitops
    course.ziyotek.edu/course: container-fundamentals
    course.ziyotek.edu/environment: dev
    course.ziyotek.edu/student: <YOUR_GITHUB_USERNAME>
```

**`deployment.yaml`** — add to the container spec:

- Labels: `app: student-app` and `student: <YOUR_GITHUB_USERNAME>` on both the deployment and pod template
- Environment variables: `STUDENT_NAME`, `GITHUB_USERNAME`, `APP_VERSION`, plus `ENVIRONMENT` using a field reference to `metadata.namespace` (so it auto-detects dev vs prod)
- Pod metadata injection: `POD_NAME`, `POD_NAMESPACE`, `POD_IP`, `NODE_NAME` via `fieldRef`
- Resource limits: 64Mi/256Mi memory, 50m/200m CPU
- Health probes: liveness and readiness on `/health` port 5000

**`service.yaml`** — add labels (`app: student-app`, `student: <YOUR_GITHUB_USERNAME>`) and make sure the selector matches `app: student-app`.

> **Key detail:** The `ENVIRONMENT` env var uses `fieldRef: metadata.namespace` instead of a hardcoded string. Kustomize sets the namespace, and the pod picks it up automatically. When you add prod for homework, you won't need to change the deployment — just the namespace in the kustomization file.


---

## What is Kustomize?

Before you start writing `kustomization.yaml` files, it's worth understanding what Kustomize is and why it exists.

Imagine you need to deploy the same application to dev, staging, and prod. Each environment needs slightly different settings — different namespaces, replica counts, resource limits, maybe different image tags. The brute-force approach is to copy all your YAML files into separate folders for each environment and edit them individually. That works, but now you have three copies of everything. When you update a label or add a health probe, you have to remember to change it in every folder.

Kustomize solves this problem. It's a tool — built directly into `kubectl` since Kubernetes 1.14 — that lets you customize Kubernetes manifests without modifying the original files. Instead of templating (like Helm does with `{{ .Values.replicas }}`), Kustomize works with plain YAML. You write a `kustomization.yaml` file that tells Kustomize which resource files to include and what transformations to apply on top of them.

In this lab, you're using two Kustomize features:

1. **Resource listing** — your `kustomization.yaml` declares which YAML files belong together as a group. When you run `kubectl kustomize <directory>`, it reads the `kustomization.yaml`, finds the listed resources, and outputs them as one combined YAML stream. This is how ArgoCD knows what to deploy.

2. **Namespace transformer** — the `namespace:` field in a `kustomization.yaml` automatically injects that namespace into every resource it manages. This is why your `deployment.yaml` and `service.yaml` don't need a hardcoded `metadata.namespace` — Kustomize adds it for you at build time.

Right now you're only setting up dev. For homework, you'll add a `prod/` directory — identical manifests, different namespace. That duplication is intentional for now. We'll fix it in a later week using Kustomize's **base + overlay** pattern, where you write shared manifests once in a `base/` directory and each environment only contains the differences.

You can try it yourself — run `kubectl kustomize` against your directory and watch it combine and transform your files into the final output that ArgoCD will apply to the cluster.

**Official docs:**
- [Kustomize.io](https://kustomize.io/) — project homepage
- [Kubernetes docs: Declarative Management with Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/) — the official Kubernetes walkthrough
- [Kustomize GitHub repo](https://github.com/kubernetes-sigs/kustomize) — source and examples
- [ArgoCD + Kustomize](https://argo-cd.readthedocs.io/en/stable/user-guide/kustomize/) — how ArgoCD detects and renders Kustomize directories (this is what happens after your PR is merged)

---

### Write kustomization.yaml files

These are short — write them by hand.

**`student-infra/students/<YOUR_GITHUB_USERNAME>/kustomization.yaml`** (root):

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - dev
```

> When you add prod for homework, you'll add `- prod` to this list.

**`student-infra/students/<YOUR_GITHUB_USERNAME>/dev/kustomization.yaml`**:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: student-<YOUR_GITHUB_USERNAME>-dev

resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
```

The `namespace:` field is the Kustomize namespace transformer — it automatically sets the namespace on every resource in the directory. That's why your deployment.yaml and service.yaml don't need a `metadata.namespace` field.

---

## Part 4: Register Your Directory and Validate

### Add yourself to the parent kustomization

Edit `student-infra/students/kustomization.yaml` and add your directory name to the resources list:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - jlgore
  - <YOUR_GITHUB_USERNAME>    # <-- add this line
```

### Validate with kustomize

From the repo root, run:

```bash
kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/
```

This should output valid YAML containing:
- One Namespace resource (`student-<YOUR_GITHUB_USERNAME>-dev`)
- One Deployment (in the dev namespace)
- One Service (in the dev namespace)

If you get errors, compare your files to the `jlgore/` example and fix any differences.

### Verify your directory structure

```
student-infra/students/<YOUR_GITHUB_USERNAME>/
├── kustomization.yaml
└── dev/
    ├── kustomization.yaml
    ├── namespace.yaml
    ├── deployment.yaml
    └── service.yaml
```

---

## Part 5: Submit Your Pull Request

```bash
cd ~/talos-gitops
git add student-infra/students/
git commit -m "week04: add dev manifests for <YOUR_GITHUB_USERNAME>"
git push origin week04/<YOUR_GITHUB_USERNAME>
```

Go to [github.com/ziyotek-edu/talos-gitops](https://github.com/ziyotek-edu/talos-gitops) and open a pull request:

- **Base:** `main`
- **Compare:** your fork's `week04/<YOUR_GITHUB_USERNAME>` branch
- **Title:** `Week 04: <YOUR_NAME> - dev deployment`

Once a reviewer approves and merges, ArgoCD picks up the change and syncs your dev namespace.

---

## Part 6: Watch the Deployment

After your PR is merged, ArgoCD will detect the new manifests and sync them. This usually takes 1-3 minutes.

### Verify with kubectl

```bash
# Check your dev namespace
kubectl get all -n student-<YOUR_GITHUB_USERNAME>-dev

# Check the pods are running
kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-dev

# Check logs
kubectl logs deployment/student-app -n student-<YOUR_GITHUB_USERNAME>-dev
```

### Test with port-forward

```bash
kubectl port-forward -n student-<YOUR_GITHUB_USERNAME>-dev service/student-app-svc 8080:80 &
curl localhost:8080/info
kill %1
```

The `/info` endpoint should return pod metadata. Notice that `ENVIRONMENT` shows the namespace name — `student-<YOUR_GITHUB_USERNAME>-dev` — because it comes from `metadata.namespace`, not a hardcoded value.

---

## Checkpoint

Before you're done, verify:

- [ ] Your v4 image is on GHCR and publicly accessible
- [ ] Your `student-infra/students/<username>/` directory has the dev structure (5 files)
- [ ] `kubectl kustomize student-infra/students/<username>/` produces valid output with the dev namespace
- [ ] You added your directory to `student-infra/students/kustomization.yaml`
- [ ] Your PR is submitted to `ziyotek-edu/talos-gitops` (or merged)
- [ ] After merge: pods are running in `student-<username>-dev`
- [ ] After merge: `/info` returns correct `ENVIRONMENT` (your dev namespace name)
