![Lab 02 Gateway API on the Shared Cluster](../../../assets/generated/week-06-lab-02/hero.png)
![Lab 02 Gateway API routing workflow](../../../assets/generated/week-06-lab-02/flow.gif)

---

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

## Background: What is Gateway API?

### Why Ingress wasn't enough

Ingress solved the "one IP, many services" problem, but it accumulated pain points over time:

- **Too much lives in annotations.** TLS config, timeouts, rate limits, header rewrites — none of these are in the spec. Every controller invented its own annotation namespace (`nginx.ingress.kubernetes.io/...`, `traefik.ingress.kubernetes.io/...`). Manifests became controller-specific.
- **No role model.** One resource (`Ingress`) is written by the app team but describes cluster-wide infrastructure. In multi-tenant clusters this creates conflict: who owns TLS? Who controls which namespaces can publish routes?
- **HTTP only.** Ingress has no story for TCP or UDP traffic.

Gateway API was designed from scratch by Kubernetes SIG Network to fix all three. It graduated to **stable (v1)** in Kubernetes 1.28 (2023) and is the officially recommended path for new clusters.

### The three-resource model

Gateway API splits routing across three resources, each owned by a different team:

```
GatewayClass          ← infra/cloud team: "what kind of gateway?"
    └── Gateway        ← platform team: "what ports/TLS/namespaces?"
            └── HTTPRoute  ← app team: "what hostname/paths route where?"
```

| Resource | Scope | Who writes it | What it does |
|---|---|---|---|
| `GatewayClass` | Cluster | Infra/cloud team | Names a controller implementation (Cilium, Envoy, nginx) |
| `Gateway` | Cluster or Namespace | Platform team | Declares listeners (ports, hostnames, TLS), controls which namespaces can attach |
| `HTTPRoute` | Namespace | App team | Maps hostnames + paths to Services in the same namespace |

In this lab you only write an `HTTPRoute`. The `Gateway` is already running — the instructor provisioned it. This mirrors how real multi-tenant clusters work.

### What it enables that Ingress can't

- **Route-level traffic splitting** — send 90% to `v1`, 10% to `v2` in the spec, no annotations
- **Header and path rewrites** — first-class fields, not controller-specific annotations
- **TCP/UDP routes** — `TCPRoute`, `UDPRoute`, `TLSRoute` resources for non-HTTP traffic
- **Cross-namespace references** — a `Gateway` in `kube-system` can accept routes from any allowed namespace
- **Portable manifests** — same `HTTPRoute` YAML works on Cilium, Envoy Gateway, Contour, or NGINX Gateway Fabric

### Status in the ecosystem

Gateway API is stable but adoption is still catching up to Ingress. As of 2025:
- **Cilium**, **Contour**, **Envoy Gateway**, and **NGINX Gateway Fabric** all have production-ready implementations
- Major cloud providers are adding native Gateway API support (GKE, EKS, AKS)
- The Ingress API is still supported with no removal date, but receives no new features

**Further reading:**
- [Gateway API concepts (Kubernetes docs)](https://kubernetes.io/docs/concepts/services-networking/gateway/)
- [Gateway API project site + full spec](https://gateway-api.sigs.k8s.io/)
- [HTTPRoute reference](https://gateway-api.sigs.k8s.io/api-types/httproute/)
- [Cilium Gateway API docs](https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/)

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
