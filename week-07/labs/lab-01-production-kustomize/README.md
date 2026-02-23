![Lab 01 Production Kustomize](../../../assets/generated/week-07-lab-01/hero.png)
![Lab 01 Kustomize overlay workflow](../../../assets/generated/week-07-lab-01/flow.gif)

---

# Lab 1: Production Kustomize (Base + Overlays + Components)

**Time:** 60 minutes  
**Objective:** Refactor a duplicated dev/prod GitOps directory into a production-style Kustomize layout

---

## The Story

Your GitOps directory started small. Now it's a stack:
- app + redis
- HTTPRoutes
- Uptime Kuma (dev-only)
- NetworkPolicies

If dev and prod are separate copied directories, you will eventually forget to update one of them. That's not a student problem. That's a production problem.

This lab fixes it by moving to a real Kustomize pattern:
- `base/` for shared resources
- `overlays/dev` and `overlays/prod` for environment differences
- `components/` for optional features you can enable per overlay

---

## Starting Point

Your starting point is your current `talos-gitops` directory — the `dev/` and `prod/` directories you built in **Week 5** (Lab 3: Ship Redis to Prod) and extended in **Week 6** (Gateway API + NetworkPolicies).

Right now those directories have nearly identical YAML. Compare them — the differences are probably just namespace, maybe replicas, and dev has Uptime Kuma. Everything else is copy/pasted. That's what we're fixing.

> In Weeks 5-6 you learned the resources the "beginner" way — one directory per environment, every manifest duplicated. That got you shipping fast. Now we evolve to how teams actually manage this at scale.

---

## Part 1: Identify What's Actually Different

Make a quick list of what should differ between dev and prod:
- replicas?
- resource limits?
- optional tooling (Uptime Kuma)?
- routes/hostnames?

Anything else should be identical and live in `base/`.

---

## Part 2: Create the New Directory Structure

Inside your student directory in `talos-gitops` (replacing the flat `dev/` and `prod/` directories you have now):

```text
student-infra/students/<you>/
  kustomization.yaml
  base/
    kustomization.yaml
    (shared manifests)
  components/
    uptime-kuma/
      kustomization.yaml
      (uptime-kuma + httproute)
    network-policy/
      kustomization.yaml
      (network policies)
  overlays/
    dev/
      kustomization.yaml
      namespace.yaml
      (dev-only patches)
    prod/
      kustomization.yaml
      namespace.yaml
      (prod-only patches)
```

Keep `namespace.yaml` inside each overlay. The namespace name is environment-specific.

---

## Part 3: Build the Base

Move your shared resources into `base/`:
- app Deployment + Service
- Redis StatefulSet + headless Service + ConfigMap + Secret

In `base/kustomization.yaml`, list only shared resources.

Then run:

```bash
kubectl kustomize base | head
```

You want valid YAML output before you touch overlays.

---

## Part 4: Create dev and prod overlays

Each overlay should:
- set the namespace (via Kustomize)
- include `../../base`
- include any components you want enabled
- apply patches for environment-specific differences

Commands that matter:

```bash
# Validate output without applying
kubectl kustomize overlays/dev | head

# Diff what would change (if you have access to a cluster)
kubectl diff -k overlays/dev 2>/dev/null || true
```

---

## Part 5: Use a Component for Dev-Only Tooling

Uptime Kuma is dev-only — you deployed it in **Week 6 Lab 2**. That makes it a perfect Kustomize component.

Create `components/uptime-kuma/` and move your existing Uptime Kuma manifests into it:
- PVC
- Deployment
- Service
- HTTPRoute

The `kustomization.yaml` for a component uses `kind: Component` (not `kind: Kustomization`):

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component

resources:
  - uptime-kuma-deployment.yaml
  - uptime-kuma-service.yaml
  - uptime-kuma-pvc.yaml
  - httproute.yaml
```

Then include it only in the dev overlay.

---

## Part 6: Commit and Submit

Once `kubectl kustomize overlays/dev` and `kubectl kustomize overlays/prod` both look correct, commit your changes and submit a PR.

---

## Checkpoint

You are done when:
- `base/` contains only shared resources (no env-specific drift)
- dev/prod overlays are small and patch-driven
- dev overlay includes Uptime Kuma via a component
- prod overlay does not include dev-only tooling

A complete solution is in [`solution/`](./solution/) if you get stuck.
