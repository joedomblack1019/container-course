# Lab 3: NetworkPolicies (Break It, Fix It, Lock It Down)

**Time:** 25 minutes  
**Objective:** Apply a default-deny policy, then incrementally allow only required traffic so your app stays reachable while your namespace becomes safer

---

## The Story

Right now your namespace is a flat network:

- Any pod can talk to any other pod
- Any pod can talk to the internet
- Any compromised container can scan laterally

This is the default Kubernetes model: **allow-all**.

NetworkPolicies let you declare least-privilege flows. The catch is: you have to be precise. We'll do this the right way:

1. Break it (default deny)
2. Fix it incrementally (one allow at a time)
3. Commit the final policy to GitOps

Uptime Kuma is your feedback loop. When networking breaks, monitors go red.

---

## Background: What are NetworkPolicies?

### The default Kubernetes network model

Out of the box, Kubernetes runs a **flat, allow-all network**. Every pod can reach every other pod in the cluster, regardless of namespace. Every pod can reach the internet. There are no firewall rules.

This is convenient for getting started, but dangerous in production. A single compromised container can scan every other pod's port, exfiltrate data, or pivot to the control plane.

### What NetworkPolicy does

A `NetworkPolicy` is a Kubernetes resource that defines L3/L4 firewall rules for pods. Once any NetworkPolicy selects a pod, only traffic explicitly allowed by a policy is permitted. Unselected pods remain allow-all.

```
No NetworkPolicy:        With default-deny:
┌──────────────┐         ┌──────────────┐
│  any pod  ──────────▶ │  any pod  ✗  │  (blocked unless a policy allows it)
└──────────────┘         └──────────────┘
```

Rules can match on:
- **`podSelector`** — which pods in the same namespace this policy applies to
- **`namespaceSelector`** — allow traffic from/to pods in specific namespaces
- **`ipBlock`** — allow traffic from/to specific IP CIDR ranges (e.g. the internet)
- **ports** — restrict to specific protocol/port combinations

### Critical behaviour to understand

**1. Both directions must be open.** If pod A wants to talk to pod B, you need an egress rule on A AND an ingress rule on B. Forgetting either side silently drops traffic.

**2. Policies are additive (union).** Multiple NetworkPolicies selecting the same pod combine — you never "replace" an existing policy by applying another. Delete the old one if you want to remove a rule.

**3. The CNI must support it.** NetworkPolicy is just an API object. The CNI plugin (Cilium, Calico, Weave) is responsible for actually enforcing it. Some CNIs (Flannel in its basic form) ignore NetworkPolicies entirely. The shared cluster uses Cilium, which fully enforces them.

### A note on scope

NetworkPolicy is intentionally L3/L4 only — it works on IPs and ports, not HTTP paths or headers. For application-level policies ("only allow GET /api"), you need a service mesh (Istio, Cilium Network Policy with L7 rules).

**Further reading:**
- [NetworkPolicy concepts](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [NetworkPolicy reference](https://kubernetes.io/docs/reference/kubernetes-api/policy-resources/network-policy-v1/)
- [Cilium NetworkPolicy docs](https://docs.cilium.io/en/stable/security/policy/)
- [NetworkPolicy editor (visual tool)](https://editor.networkpolicy.io/)

---

## Part 1: Verify the Current State Works

Make sure your dev namespace is healthy before you start:

```bash
kubectl config use-context ziyotek-prod
kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-dev
```

Confirm you have permissions to create NetworkPolicies in your dev namespace:

```bash
kubectl auth can-i create networkpolicy -n student-<YOUR_GITHUB_USERNAME>-dev
```

If this returns `no`, stop and ask the instructor to confirm RBAC for Week 6.

Check that your URLs work (public, if available):

```bash
curl -s https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/health
curl -s https://<YOUR_GITHUB_USERNAME>.status.lab.shart.cloud/ | head
```

---

## Part 2: Default Deny (Break Everything)

Apply a default deny for both ingress and egress:

```bash
kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
  ingress: []
  egress: []
EOF
```

Watch what breaks:
- Uptime Kuma monitors go red
- Public URLs fail
- Pods are still Running (usually), but traffic is blocked

---

## Part 3: Allow DNS (Fix Name Resolution)

Without DNS, almost nothing works (Services, external monitors, etc.).

```bash
kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
spec:
  podSelector: {}
  policyTypes:
    - Egress
  egress:
    - to:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              k8s-app: kube-dns
      ports:
        - protocol: UDP
          port: 53
        - protocol: TCP
          port: 53
EOF
```

---

## Part 4: Allow Gateway Ingress to Your Services

You want the shared gateway (in `kube-system`) to be able to reach:
- `student-app` on port `5000`
- `uptime-kuma` on port `3001`

```bash
kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-gateway-ingress
spec:
  podSelector:
    matchExpressions:
      - key: app
        operator: In
        values:
          - student-app
          - uptime-kuma
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: kube-system
      ports:
        - protocol: TCP
          port: 5000
        - protocol: TCP
          port: 3001
EOF
```

Your public URLs should come back.

---

## Part 5: Allow App-to-Redis (Fix /visits)

The Flask app needs to reach Redis on `6379`.

Allow app egress to Redis:

```bash
kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-to-redis
spec:
  podSelector:
    matchLabels:
      app: student-app
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: redis
      ports:
        - protocol: TCP
          port: 6379
EOF
```

Allow Redis ingress from the app:

```bash
kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-redis-from-app
spec:
  podSelector:
    matchLabels:
      app: redis
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: student-app
      ports:
        - protocol: TCP
          port: 6379
EOF
```

Now `/visits` should work again.

---

## Part 6: Allow Uptime Kuma Monitoring

Uptime Kuma needs to:
- Reach your app internally (port `5000`)
- Reach external URLs on ports `80/443` (for monitoring prod by public hostname)

Allow Kuma egress:

```bash
kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-kuma-monitoring
spec:
  podSelector:
    matchLabels:
      app: uptime-kuma
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: student-app
      ports:
        - protocol: TCP
          port: 5000
    - to:
        - ipBlock:
            cidr: 0.0.0.0/0
      ports:
        - protocol: TCP
          port: 80
        - protocol: TCP
          port: 443
EOF
```

The app still needs to allow ingress from Kuma:

```bash
kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-from-kuma
spec:
  podSelector:
    matchLabels:
      app: student-app
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: uptime-kuma
      ports:
        - protocol: TCP
          port: 5000
EOF
```

All monitors should go green again.

---

## Part 7: Combine Into a Single File

Delete the temporary policies if you made separate files during debugging (optional), then apply the combined solution file:

```bash
kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f solution/network-policy.yaml
kubectl get networkpolicy -n student-<YOUR_GITHUB_USERNAME>-dev
```

---

## Part 8: Add to GitOps

Copy `solution/network-policy.yaml` into your `talos-gitops` dev directory, add it to `dev/kustomization.yaml`, and commit it on your Week 6 branch.

---

## Part 9 (Optional): Generate Policy Reachability Charts

If you want a clear before/after visualization of your policy surface area:

```bash
cd week-06/labs/lab-03-network-policies
python3 scripts/benchmark_networkpolicy_matrix.py
```

What this script does:
- Parses `solution/network-policy.yaml`
- Evaluates key lab traffic flows (gateway/app/redis/kuma/dns/internet)
- Compares baseline (default-allow) vs post-policy behavior
- Generates matrix and source-level charts

Requirements:
- Python 3
- `pyyaml` installed
- `matplotlib` installed (for PNG output)

If you only want JSON/markdown output:

```bash
python3 scripts/benchmark_networkpolicy_matrix.py --no-charts
```

Artifacts are written to:

```text
assets/generated/week-06-network-policies/
  networkpolicy_flow_matrix.png
  networkpolicy_allowed_by_source.png
  summary.md
  results.json
```

![NetworkPolicy Flow Matrix](../../../assets/generated/week-06-network-policies/networkpolicy_flow_matrix.png)

![NetworkPolicy Allowed Flow Count by Source](../../../assets/generated/week-06-network-policies/networkpolicy_allowed_by_source.png)

---

## Verification Checklist

You are done when:
- Public URLs work (Gateway → Services)
- `/visits` works (app ↔ redis)
- Uptime Kuma can monitor dev and prod
- Your namespace is no longer default-allow

---

## Reinforcement Scenarios

- `jerry-networkpolicy-dns`
