# Week 6: Networking & Security

## Overview

**Duration:** 3 hours  
**Format:** Lecture + Hands-on Labs  

Your app now has a backing service. It has state. It has configuration. It's starting to look real.

But nobody can reach it.

Right now, the only way to use your app is `kubectl port-forward` and a localhost URL. That's fine for debugging, but it's not a deployment strategy. Real users don't run `kubectl`. They type a hostname, hit TLS, and expect traffic to route to the right pod.

This week you take control of routing. You'll learn how traffic gets from the internet to your Service, why Ingress was the old model, why Gateway API is the new model, and how to lock your namespace down with NetworkPolicies without breaking everything.

---

## Learning Outcomes

By the end of this class, you will be able to:

1. Explain Kubernetes Service types (ClusterIP, NodePort, LoadBalancer, ExternalName) and when to use each `CKA: Services and Networking`
2. Create and debug Ingress resources for host-based routing `CKA: Services and Networking`
3. Create HTTPRoute resources and attach them to a shared Gateway (Gateway API) `CKA: Services and Networking`
4. Compare Ingress vs Gateway API (roles, TLS, multi-tenancy, and operational model) `CKA: Cluster Architecture, Installation and Configuration + Services and Networking`
5. Implement NetworkPolicies to enforce least-privilege traffic flow inside a namespace `CKA: Services and Networking`
6. Diagnose Service routing failures using selectors, Endpoints, and `kubectl describe` evidence `CKA: Troubleshooting + Services and Networking`
7. Run a CoreDNS incident triage and recovery workflow with command-level verification `CKA: Troubleshooting`

---

## Pre-Class Setup

### Local Tools (kind + kubectl + Helm)

Verify your tooling:

```bash
kind version
kubectl version --client
helm version
```

### Shared Cluster Access

You should still be able to read from the shared cluster context:

```bash
kubectl config get-contexts
kubectl config use-context ziyotek-prod
kubectl get namespaces | head
```

### Sync Your talos-gitops Fork

Week 6 continues the GitOps workflow from Weeks 4-5. Before class, make sure your fork is up to date with upstream and that you can create a `week06/<username>` branch.

---

## How Traffic Reaches Your Pod

This is the mental model for the rest of the course:

1. **A user types a hostname**: `https://you.dev.lab.shart.cloud`
2. **DNS resolves** that hostname to an IP address
3. **The client connects** to that IP (often via a CDN or reverse proxy) and negotiates TLS
4. **A gateway/load balancer** receives the request and decides where it should go (host/path matching)
5. **A routing object** (Ingress or HTTPRoute) selects a backend **Service**
6. **The Service** selects backend **Pods** via label selectors
7. **The Pod** receives the request on a container port (for the Flask app, `5000`)

The key idea: **Pods are not endpoints. Services are.** Pods die, IPs change, replicas scale up and down. Services provide the stable abstraction that everything routes through.

---

## Class Agenda

| Time | Topic | Type |
|------|-------|------|
| 0:00 - 0:20 | From Port-Forward to Public URLs: What Are We Missing? | Lecture |
| 0:20 - 0:45 | Service Types + DNS: How Kubernetes Networking Actually Works | Lecture |
| 0:45 - 1:25 | **Lab 1:** Ingress in kind (nginx ingress controller) | Hands-on |
| 1:25 - 1:35 | Break | — |
| 1:35 - 2:00 | Ingress vs Gateway API: The Role Model Shift | Lecture |
| 2:00 - 2:40 | **Lab 2:** Gateway API on the shared cluster (HTTPRoute + Uptime Kuma) | Hands-on |
| 2:40 - 3:00 | **Lab 3:** NetworkPolicies (break it, fix it, lock it down) | Hands-on |

> **CKA Extension Track:** Two additional self-paced labs are included below (Lab 4 and Lab 5) for Service-type troubleshooting and CoreDNS incident response. Lab 6 (CNI) is a first-class 2025 CKA competency and should be completed before the exam, even if it is self-paced.

---

## Key Concepts

### Service Types Deep Dive

Kubernetes Services give you stable networking, but the *type* changes who can reach it.

```
Inside the cluster (default):

  Pod ──► Service (ClusterIP) ──► Pod
```

**ClusterIP** (default)
- Only reachable inside the cluster
- You use this for nearly everything (app services, Redis, internal APIs)

**NodePort**
- Exposes a port on every node: `<NodeIP>:3xxxx`
- Often used as a building block under a LoadBalancer, or for quick labs

**LoadBalancer**
- Requests an external IP from a cloud provider (or a bare-metal LB implementation)
- Front door into your cluster (often combined with an Ingress/Gateway)

**ExternalName**
- No proxying. Just DNS: Service name becomes a CNAME to an external hostname
- Useful for "pretend this external thing is a Service"

```
From outside the cluster (conceptually):

  Internet
    │
    ▼
  LB / Gateway IP
    │
    ▼
  Service (usually ClusterIP behind the scenes)
    │
    ▼
  Pod IP:Port
```

### Ingress: L7 Routing

Ingress adds **HTTP routing** on top of Services.

```
             Host: app.local
Client  ─────────────────────────►  Ingress Controller (nginx)
                                       │
                                       ▼
                                  Service: course-app
                                       │
                                       ▼
                                  Pod: course-app-xxxxx
```

Ingress is a *spec*, not an implementation. You need a controller (nginx, Traefik, HAProxy, etc.) to make it work.

### Gateway API: The Modern Approach

Gateway API replaces the "single Ingress object does everything" model with a more explicit, multi-tenant design.

```
Cluster admin owns:

  GatewayClass  ──►  Gateway (listeners, TLS, allowed routes)

App teams own:

  HTTPRoute ──► attaches to Gateway ──► routes to Service ──► Pod
```

```
DNS / Internet
    │
    ▼
 Cilium Gateway (shared)
    │
    ▼
 HTTPRoute (your namespace)
    │
    ▼
 Service
    │
    ▼
 Pod
```

The shift is operational: **platform teams manage Gateways, app teams manage Routes.**

### Ingress vs Gateway API

| Category | Ingress | Gateway API |
|----------|---------|-------------|
| API group | `networking.k8s.io/v1` | `gateway.networking.k8s.io/v1` |
| Object model | One object does routing (+ annotations) | Role-separated objects (GatewayClass/Gateway/Route) |
| Multi-tenancy | Harder (mostly convention) | Designed for multi-tenant clusters |
| TLS | Often configured on Ingress (controller-specific) | First-class on Gateway listeners |
| Cross-namespace attachment | Limited / controller-specific | First-class (with explicit allow rules) |
| Operational model | "App team installs controller + writes Ingress" | "Platform provides Gateway, app team writes HTTPRoute" |

### NetworkPolicy: Microsegmentation

By default, Kubernetes networking is **allow-all**: every pod can talk to every other pod.

NetworkPolicies let you declare "only these flows are allowed."

```
student namespace (dev)

  [Gateway] ─────► [student-app] ─────► [redis]
      │               ▲
      │               │
      └─────► [uptime-kuma] ───────────┘
                 │
                 ├────► DNS (kube-system)
                 └────► Internet (80/443)   (optional, for external monitoring)
```

The practical workflow is:
1. Default deny (break everything)
2. Add one allow rule at a time (DNS, ingress from gateway, app-to-redis, etc.)
3. Verify after each change

> **CNI enforcement is a prerequisite.** A NetworkPolicy is just an API object stored in etcd. The CNI plugin running on each node is what programs actual kernel rules to enforce it. CNIs like **kindnet** and basic **Flannel** do not implement NetworkPolicy enforcement — if you apply a deny policy on those clusters, traffic continues to flow unchanged with no error or warning. The shared cluster uses **Cilium**, which fully enforces policies. See [Lab 6](./labs/lab-06-cni-comparison/) for the direct kindnet-vs-Calico comparison. **Reference:** [Network Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/) | [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

### NetworkPolicy Exam Patterns

The CKA exam requires writing NetworkPolicy YAML from scratch. These three patterns cover the most common task types:

**Pattern 1 — Allow egress to a specific CIDR (e.g. an external API)**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-external
  namespace: my-namespace
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
    - Egress
  egress:
    - to:
        - ipBlock:
            cidr: 203.0.113.0/24   # specific external CIDR
            except:
              - 203.0.113.5/32     # carve out one address if needed
      ports:
        - protocol: TCP
          port: 443
```

**Pattern 2 — Allow ingress from a specific namespace (namespaceSelector)**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-monitoring
  namespace: my-namespace
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: monitoring   # match namespace by label
      ports:
        - protocol: TCP
          port: 8080
```

**Pattern 3 — Allow from specific pods in a specific namespace (AND logic)**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-gateway-pods
  namespace: my-namespace
spec:
  podSelector:
    matchLabels:
      app: my-app
  policyTypes:
    - Ingress
  ingress:
    - from:
        - namespaceSelector:       # both selectors in the SAME list item = AND
            matchLabels:
              kubernetes.io/metadata.name: kube-system
          podSelector:
            matchLabels:
              app: gateway
      ports:
        - protocol: TCP
          port: 5000
```

> **AND vs OR:** When `namespaceSelector` and `podSelector` are in the **same** `from` list item (as above), both must match — it's an AND. When they are **separate** list items (`- namespaceSelector: ...` and `- podSelector: ...`), either can match — it's an OR. Getting this wrong produces subtle access bugs that are hard to spot under exam pressure.

### DNS in Kubernetes

Kubernetes DNS is how "Service names become hostnames."

Common patterns:
- Same namespace: `redis` resolves to the Service named `redis`
- Cross-namespace: `redis.student-jlgore-dev`
- Fully qualified: `redis.student-jlgore-dev.svc.cluster.local`

CoreDNS watches Services and Endpoints and answers queries automatically. If DNS breaks, your app may be healthy but unable to reach anything by name.

**First check — can any pod resolve cluster DNS?**

```bash
# Quickest baseline check: run nslookup from the CoreDNS pod itself
COREDNS_POD=$(kubectl -n kube-system get pods -l k8s-app=kube-dns -o name | head -1)
kubectl -n kube-system exec "$COREDNS_POD" -- nslookup kubernetes.default.svc.cluster.local

# Or spin up a one-off probe pod
kubectl run dns-check --rm -it --image=busybox:1.36 -- nslookup kubernetes.default.svc.cluster.local
```

**Check the Corefile configuration:**

```bash
# View the entire CoreDNS config — the forward directive is the most common failure point
kubectl describe configmap coredns -n kube-system

# Check CoreDNS pod health and recent logs
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n kube-system logs deployment/coredns --tail=40
```

If cluster names resolve but external names (e.g. `google.com`) fail, look at the `forward` line in the Corefile — it's pointing somewhere unreachable. If all DNS fails including cluster names, CoreDNS pods are down or OOMKilled.

---

## Labs

### Lab 1: Ingress in kind

See [labs/lab-01-ingress-kind/](./labs/lab-01-ingress-kind/)

You will:
- Create a kind cluster configured for ingress on ports 80/443
- Install nginx ingress controller
- Route two hostnames to two Services (`course-app` and Uptime Kuma)

### Lab 2: Gateway API on the Shared Cluster

See [labs/lab-02-gateway-api/](./labs/lab-02-gateway-api/)

You will:
- Deploy Uptime Kuma to your dev namespace
- Attach an HTTPRoute to the shared `cilium-gateway`
- Access it at `https://<you>.status.lab.shart.cloud`

### Lab 3: NetworkPolicies

See [labs/lab-03-network-policies/](./labs/lab-03-network-policies/)

You will:
- Apply a default-deny policy
- Restore only the traffic you actually need
- Commit the final policy into GitOps

### Lab 4 (CKA Extension): Service Types + Endpoint Debugging

See [labs/lab-04-service-types-nodeport-loadbalancer/](./labs/lab-04-service-types-nodeport-loadbalancer/)

You will:
- Deploy a sample app and expose it through ClusterIP, NodePort, and LoadBalancer Services
- Diagnose and fix a broken NodePort `targetPort` mapping
- Inspect Endpoint objects and trace how selectors control traffic flow

### Lab 5 (CKA Extension): CoreDNS Failure and Recovery

See [labs/lab-05-coredns-troubleshooting/](./labs/lab-05-coredns-troubleshooting/)

You will:
- Run baseline DNS checks from workload pods
- Inject a CoreDNS forwarding failure in a disposable cluster
- Restore CoreDNS config and verify service discovery recovery
- Map this workflow to `jerry-coredns-loop`

### Lab 6: CNI Plugin Comparison

See [labs/lab-06-cni-comparison/](./labs/lab-06-cni-comparison/)

You will:
- Apply a NetworkPolicy on a kindnet cluster and observe that it is silently ignored
- Bootstrap a cluster with `disableDefaultCNI: true` and see pods stuck in `Pending`
- Install Calico and watch nodes reach `Ready` with pod IPs from the Calico pool
- Apply the same deny policy and observe traffic being blocked by Calico's enforcement
- Learn when to choose kindnet, Calico, or Cilium for a given production scenario

---

## Generated Visualizations

### Lab 3: NetworkPolicy Reachability

![NetworkPolicy Flow Matrix](../assets/generated/week-06-network-policies/networkpolicy_flow_matrix.png)

![NetworkPolicy Allowed Flows by Source](../assets/generated/week-06-network-policies/networkpolicy_allowed_by_source.png)

---

## Discovery Questions

1. In a Gateway API setup, what prevents you from attaching an HTTPRoute in your namespace to a Gateway you don't own (or claiming someone else's hostname)?
2. You have a public URL that returns 404. List the resources you would check (Gateway, HTTPRoute, Service, Endpoints, Pods) and what "good" looks like for each.
3. You apply a default-deny NetworkPolicy and your public URL still works, but your app's `/visits` endpoint breaks. What traffic flow is missing?
4. Why can `kubectl port-forward` still reach a pod even when NetworkPolicies block pod-to-pod traffic? What component is proxying that connection?
5. In kind with nginx ingress controller, if two Ingress resources both claim the same hostname, what happens and how do you debug which rule is winning?

---

## Homework

Complete these exercises in the container-gym before next class:

| Exercise | Time | Focus |
|----------|------|-------|
| `jerry-nodeport-mystery` | 20 min | Service types and port mapping |
| `jerry-broken-ingress-host` | 20 min | Ingress host routing and debugging |
| `jerry-networkpolicy-dns` | 25 min | Default deny + DNS allow rules |
| `jerry-gateway-route-detached` | 25 min | HTTPRoute attachment and status conditions |
| `jerry-coredns-loop` *(optional extension)* | 25 min | DNS outage triage and CoreDNS recovery |
| `33-jerry-wrong-cni-config` *(optional extension)* | 25 min | CNI misconfiguration; pods pending, no node networking |

---

## Resources

- Kubernetes Ingress: https://kubernetes.io/docs/concepts/services-networking/ingress/
- Kubernetes Services: https://kubernetes.io/docs/concepts/services-networking/service/
- Gateway API docs: https://gateway-api.sigs.k8s.io/
- Cilium Gateway API: https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/
- NetworkPolicy docs: https://kubernetes.io/docs/concepts/services-networking/network-policies/
- Network Plugins (CNI): https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/
- Debugging DNS resolution: https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/
- CoreDNS project docs: https://coredns.io/
- NetworkPolicy editor: https://editor.networkpolicy.io/
- Uptime Kuma: https://github.com/louislam/uptime-kuma

---

## Next Week Preview

Next week we level up the GitOps workflow:
- Kustomize: reduce duplication between dev and prod with bases + overlays
- Metrics/Observability: how to *measure* what your cluster is doing (and why "it feels slow" isn't a metric)
