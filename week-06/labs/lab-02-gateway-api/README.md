# Lab 2: Gateway API on the Shared Cluster

**Time:** 40 minutes  
**Objective:** Deploy Uptime Kuma in your dev namespace and attach an HTTPRoute to the shared Cilium Gateway

---

## The Story

In Lab 1, you were both the platform team and the application team:
- You created the cluster
- You installed the controller
- You wrote the routing resources

In a real organization, that's not how it works.

On the shared cluster, the **Gateway already exists**. The platform team owns it. Your job is to deploy an app and publish a **route** to it without touching cluster-wide infrastructure.

Uptime Kuma is the new service this week. You'll run it in your dev namespace, then route to it at:

`https://<YOUR_GITHUB_USERNAME>.status.lab.shart.cloud`

This lab assumes the instructor has already provisioned:
- DNS: `*.status.lab.shart.cloud` → the shared gateway IP
- TLS: a wildcard certificate and an HTTPS listener on `cilium-gateway`

If DNS/TLS isn't live yet, you can still deploy and verify the Kubernetes resources, but the browser URL won't load until the infrastructure is in place.

---

## Part 1: Ingress vs Gateway API (Quick Comparison)

| Topic | Ingress | Gateway API |
|-------|---------|-------------|
| Who runs the controller? | Often the app team | Platform team |
| What you create | `Ingress` | `HTTPRoute` (and usually only that) |
| TLS termination | Controller-specific | First-class on `Gateway` |
| Multi-tenant safety | Convention | Designed-in |

Inspect the shared gateway:

```bash
kubectl config use-context ziyotek-prod
kubectl describe gateway cilium-gateway -n kube-system
```

Look for:
- Listener ports (HTTP/HTTPS)
- TLS config (certificate secret)
- Allowed routes (which namespaces can attach)

---

## Part 2: Render the Helm Chart to Plain Manifests

Helm is great for installing software, but GitOps usually wants **plain YAML** committed to the repo.

You have two options:
1. Use the provided solution YAML in this lab.
2. Render the Helm chart with `helm template` and commit the rendered manifests.

Example:

```bash
helm repo add uptime-kuma https://dirsigler.github.io/uptime-kuma-helm
helm repo update

# Render manifests locally (does not talk to the cluster)
helm template uptime-kuma uptime-kuma/uptime-kuma -f ../lab-01-ingress-kind/starter/uptime-kuma-values.yaml > rendered.yaml
```

For this course, we'll use plain manifests so you learn what is actually being deployed.

---

## Part 3: Prepare Your GitOps Directory (dev only)

Sync your `talos-gitops` fork and create a Week 6 branch:

```bash
cd ~/talos-gitops
git checkout main
git pull
git checkout -b week06/<YOUR_GITHUB_USERNAME>
```

Add four new manifests to your dev directory:

- `uptime-kuma-pvc.yaml`
- `uptime-kuma-deployment.yaml`
- `uptime-kuma-service.yaml`
- `httproute.yaml`

You can copy the provided solution and then edit placeholders:

```bash
cd student-infra/students/<YOUR_GITHUB_USERNAME>/dev
cp ~/container-course/week-06/labs/lab-02-gateway-api/solution/*.yaml .

# Edit httproute.yaml and set the hostname to:
# <YOUR_GITHUB_USERNAME>.status.lab.shart.cloud
```

Also update the `student:` label in all four files to your GitHub username.

Key HTTPRoute fields to understand:
- `parentRefs`: references the shared `cilium-gateway` in `kube-system`
- `hostnames`: the exact hostname you are claiming
- `backendRefs`: the Service and port to send traffic to (`uptime-kuma:3001`)

---

## Part 4: Update dev/kustomization.yaml

Edit `student-infra/students/<YOU>/dev/kustomization.yaml` and add the new resources:

```yaml
resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
  - app-config.yaml
  - redis-secret.yaml
  - redis-configmap.yaml
  - redis-statefulset.yaml
  - redis-service.yaml
  - uptime-kuma-pvc.yaml
  - uptime-kuma-deployment.yaml
  - uptime-kuma-service.yaml
  - httproute.yaml
```

Important: Uptime Kuma is **dev only**. Do not add these files to `prod/`.

---

## Part 5: Validate and Submit a PR

Validate the kustomize output:

```bash
kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/dev | head
```

Commit, push, and open a PR:

```bash
git add .
git commit -m "Week 06: Add Uptime Kuma + HTTPRoute (dev only)"
git push -u origin week06/<YOUR_GITHUB_USERNAME>
```

Open a PR against the upstream `talos-gitops` repository.

---

## Part 6: Verify After Merge

After merge, ArgoCD will sync the new resources.

```bash
kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-dev
kubectl get svc -n student-<YOUR_GITHUB_USERNAME>-dev
kubectl get pvc -n student-<YOUR_GITHUB_USERNAME>-dev
kubectl get httproute -n student-<YOUR_GITHUB_USERNAME>-dev
kubectl describe httproute uptime-kuma -n student-<YOUR_GITHUB_USERNAME>-dev
```

You want to see the route **Accepted** and **Attached**.

---

## Part 7: Configure Uptime Kuma

Browse to:

`https://<YOUR_GITHUB_USERNAME>.status.lab.shart.cloud`

Complete the setup wizard, then create three monitors:
1. Dev health: `https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/health`
2. Dev visits: `https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/visits`
3. Prod health: `https://<YOUR_GITHUB_USERNAME>.prod.lab.shart.cloud/health`

Then create a public status page and add those monitors to it.

---

## Part 8: Trace the Gateway API Request Path

```
Browser
  │  DNS: <you>.status.lab.shart.cloud → 192.168.0.240
  ▼
Cloudflare (DNS/TLS edge)
  ▼
Cilium Gateway (kube-system)
  │  matches listener + hostname
  ▼
HTTPRoute (your namespace)
  ▼
Service: uptime-kuma
  ▼
Pod: uptime-kuma-xxxxx:3001
```

---

## Checkpoint

You are done when:
- Uptime Kuma is running in your dev namespace with a PVC bound
- Your HTTPRoute is attached to `cilium-gateway`
- `https://<you>.status.lab.shart.cloud` loads
- You have three monitors and a public status page
