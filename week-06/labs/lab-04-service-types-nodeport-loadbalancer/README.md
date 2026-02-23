![Lab 04 Service Types and Endpoint Debugging](../../../assets/generated/week-06-lab-04/hero.png)
![Lab 04 NodePort LoadBalancer and endpoint workflow](../../../assets/generated/week-06-lab-04/flow.gif)

---

# Lab 4: Service Types + Endpoint Debugging (CKA Extension)

**Time:** 40 minutes  
**Objective:** Compare Service type behavior and debug a broken NodePort mapping using Endpoints and selectors.

---

## The Story

Your app is up. Pods are healthy. Dashboards look green. But users still get timeouts.

This is where many teams lose incident time: restarting workloads when the real break is Service wiring — selectors, endpoints, and port mapping. In this lab, you will intentionally break that wiring, read the exact symptom Kubernetes gives you, and build a repeatable debug loop you can run under CKA time pressure.

---

## CKA Objectives Mapped

- Understand Service networking models (ClusterIP, NodePort, LoadBalancer)
- Troubleshoot Service connectivity and endpoint discovery
- Validate backend wiring with evidence-driven commands

---

## Background: Kubernetes Service Types

### The problem Services solve

Pods are ephemeral. They restart, reschedule, and get new IP addresses constantly. You cannot hardcode a pod IP in your application config — it will break.

A **Service** is a stable virtual endpoint that sits in front of a set of pods. It provides:
- A fixed **ClusterIP** that never changes
- A DNS name (`my-service.my-namespace.svc.cluster.local`)
- Load balancing across all healthy pods that match its selector

Under the hood, kube-proxy (or the CNI, in Cilium's case) programs iptables/ipvs rules so that traffic to the ClusterIP is DNAT'd to a real pod IP.

### The four Service types

| Type | Reachable from | Use case |
|---|---|---|
| `ClusterIP` | Inside the cluster only | Default; service-to-service communication |
| `NodePort` | Outside via `<NodeIP>:<port>` (30000-32767) | Dev/testing; direct node access |
| `LoadBalancer` | Outside via a cloud-provisioned external IP | Production; cloud clusters |
| `ExternalName` | Returns a CNAME | Alias an external DNS name as a Service |

Each type is **additive** — a `NodePort` Service also gets a ClusterIP. A `LoadBalancer` Service also gets a NodePort and a ClusterIP.

### How the selector chain works

The selector chain is the most common source of Service bugs:

```
Service (selector: app=foo)
    │
    ▼
Endpoints object (auto-populated with pod IPs that match the selector)
    │
    ▼
Pods (must have label: app=foo AND be Ready)
```

If Endpoints is empty, the selector doesn't match any running pod. This is the diagnostic step most people miss — `kubectl get endpoints <svc>` shows you exactly what the Service sees.

### Why NodePort has limits

NodePort solves external access without a cloud LB, but has real drawbacks:
- Port range is restricted (30000-32767) — not standard HTTP ports
- Requires knowing a node IP — fragile if nodes come and go
- One port per service — doesn't scale to many services on one cluster

This is why Ingress and Gateway API exist: to multiplex many services behind a single external IP on standard ports.

### LoadBalancer in kind

In cloud clusters, `type: LoadBalancer` triggers the cloud provider to provision an external load balancer and assign an IP. In kind, there's no cloud provider — the `EXTERNAL-IP` stays `<pending>` unless you install a local implementation like MetalLB or use the kind-specific port mapping approach from Lab 1.

**Further reading:**
- [Services concepts](https://kubernetes.io/docs/concepts/services-networking/service/)
- [Service types reference](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)
- [Debugging Services](https://kubernetes.io/docs/tasks/debug/debug-application/debug-service/)
- [EndpointSlices](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/) — the modern replacement for Endpoints objects

---

## Prerequisites

Use your local cluster:

```bash
kubectl config use-context kind-lab
kubectl get nodes
```

Starter assets for this lab are in [`starter/`](./starter/):

- `app-deployment.yaml`
- `service-clusterip.yaml`
- `service-nodeport-broken.yaml`
- `service-loadbalancer.yaml`
- `endpoint-check.sh`

---

## Part 1: Deploy the Baseline App

Before you can debug Service behavior, you need a backend that is undeniably healthy. This step creates that clean baseline so later failures can be attributed to Service wiring, not a broken app.

```bash
kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/app-deployment.yaml
kubectl rollout status deployment/svc-types-demo --timeout=120s
kubectl get pods -l app=svc-types-demo -o wide
```

Notice: `rollout status` tells you the Deployment converged. `get pods -l app=svc-types-demo` verifies the exact label your Services will depend on. If this label is wrong, every networking test later gives confusing results.

Operator mindset: establish a trustworthy baseline first, then debug one layer at a time.

---

## Part 2: ClusterIP Baseline

Now you establish a known-good Service path inside the cluster. Think of this as your control case: if ClusterIP works, you have proof that selector matching and app reachability are fundamentally correct.

```bash
kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/service-clusterip.yaml
kubectl get svc svc-demo-clusterip
kubectl get endpoints svc-demo-clusterip
```

Notice: this is your known-good baseline. You want two signals together: a ClusterIP exists, and Endpoints are populated. That pair tells you selector wiring is healthy before you move to NodePort.

Validate in-cluster reachability:

This probe is intentional: you are validating Service DNS and backend forwarding from within Kubernetes first, before adding host or NodePort variables.

```bash
kubectl run svc-probe --image=busybox:1.36 --restart=Never --rm -it -- wget -qO- -T 5 http://svc-demo-clusterip
```

> Note: This tests pure in-cluster routing (DNS name -> Service -> backend pod). If this works, your app and selector chain are sound before adding external-access complexity.

Operator mindset: always create a known-good control path before testing more complex exposure types.

---

## Part 3: Broken NodePort (Intentional Failure)

Apply the intentionally broken NodePort manifest:

You are introducing a controlled failure on purpose. This is the fastest way to learn the diagnostic signal for bad Service wiring while the blast radius is small and predictable.

```bash
kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/service-nodeport-broken.yaml
kubectl get svc svc-demo-nodeport -o wide
```

Run diagnostics:

The goal is not just to "run debug commands". The goal is to separate symptoms into classes: discovery problems vs forwarding problems, so your fix is precise instead of guesswork.

```bash
kubectl describe svc svc-demo-nodeport
kubectl get endpoints svc-demo-nodeport -o yaml
bash week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/endpoint-check.sh svc-demo-nodeport
```

Notice: use these three together. `describe svc` shows intended wiring (selector and ports). `get endpoints` shows discovered backends. The helper script gives a fast pass/fail check. This is a strong CKA troubleshooting rhythm.

Expected symptom:

- Service exists, NodePort allocated
- Endpoints missing or traffic fails because `targetPort` is wrong

The failure mode matters. In a **selector mismatch**, Endpoints are empty because the Service cannot discover matching Ready pods. In a **targetPort mismatch**, Endpoints are populated but traffic still fails because packets are forwarded to the wrong container port.

That distinction is your diagnostic shortcut: empty Endpoints means discovery is broken; populated Endpoints with failed traffic means forwarding is broken. On the CKA, this is exactly what you are expected to demonstrate: check Endpoints first, identify the failure class, then apply the right fix quickly.

Operator mindset: classify the failure before changing anything.

---

## Part 4: Fix the NodePort Mapping

Patch the service to point at the app port (`5678`):

Now you repair only the broken layer (port mapping) and leave everything else untouched. This is an important production habit: minimal change, maximum verification.

```bash
kubectl patch svc svc-demo-nodeport --type merge -p '{"spec":{"ports":[{"port":80,"targetPort":5678,"nodePort":30080}]}}'
kubectl get svc svc-demo-nodeport -o yaml | sed -n '1,120p'
kubectl get endpoints svc-demo-nodeport
```

Notice: after patching, verify both config and behavior signals: `targetPort: 5678` is present, and Endpoints stay populated. Config-only checks are not enough; you need evidence traffic can route.

Retest from inside cluster:

This retest confirms the fix solved the real user path, not just the YAML diff. In incident response terms, this is your "service restored" evidence.

```bash
kubectl run nodeport-probe --image=busybox:1.36 --restart=Never --rm -it -- wget -qO- -T 5 http://svc-demo-nodeport
```

> Note: This is your proof step. You are not just trusting YAML output; you are proving the fixed Service actually routes traffic.

Optional host-level test (kind node mapped to localhost):

Run this if you want to isolate one more layer: internal Service routing can be healthy even if host exposure is not. This helps you avoid misdiagnosing environment issues as Kubernetes Service issues.

```bash
curl -s http://127.0.0.1:30080 | head
```

Notice: this checks host-to-NodePort reachability in kind. If in-cluster probe works but this fails, your Service wiring is likely fine and the issue is environment exposure.

Operator mindset: make the smallest possible fix, then prove user-path recovery.

---

## Part 4.5: Prove It (Break It a Second Way)

Now create a different failure on purpose: break discovery instead of port forwarding.

You already fixed one failure class. Now you deliberately trigger the other class so your mental model is robust under exam pressure.

```bash
kubectl patch svc svc-demo-nodeport --type merge -p '{"spec":{"selector":{"app":"svc-types-demo-typo"}}}'
kubectl get endpoints svc-demo-nodeport
```

Notice: Endpoints should now be empty because no pod has `app=svc-types-demo-typo`. This is the selector-mismatch signature and should look clearly different from the earlier `targetPort` failure.

Restore the correct selector and confirm recovery:

This is the full troubleshooting cycle in miniature: induce failure, identify signal, apply targeted fix, then prove recovery with a live request.

```bash
kubectl patch svc svc-demo-nodeport --type merge -p '{"spec":{"selector":{"app":"svc-types-demo"}}}'
kubectl get endpoints svc-demo-nodeport
kubectl run selector-probe --image=busybox:1.36 --restart=Never --rm -it -- wget -qO- -T 5 http://svc-demo-nodeport
```

> Note: You just validated both failure classes. Empty Endpoints = discovery failure. Populated Endpoints with broken traffic = port-forwarding failure. This is high-value troubleshooting muscle for both exams and production.

Operator mindset: practice controlled break/fix loops until the symptom-to-cause mapping is automatic.

---

## Part 5: LoadBalancer Service Behavior

Apply the LoadBalancer variant:

This final step teaches a key real-world distinction: Service internals can be correct while external exposure is still pending due to infrastructure. You are learning to separate Kubernetes wiring from platform provisioning.

```bash
kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/service-loadbalancer.yaml
kubectl get svc svc-demo-loadbalancer -o wide
```

Notice: focus on `TYPE`, `PORT(S)`, and `EXTERNAL-IP`. In kind, `<pending>` is expected for `EXTERNAL-IP` and does not mean the app is unhealthy.

In plain kind, `EXTERNAL-IP` is often `<pending>` unless you add a local LB implementation.

What to check anyway:

You are still verifying the same core chain (selector -> endpoints -> pods). The type changed, but your troubleshooting method stays consistent.

```bash
kubectl describe svc svc-demo-loadbalancer
kubectl get endpoints svc-demo-loadbalancer
```

> Note: Even without external provisioning, selector and endpoint wiring behave the same. Healthy Endpoints here mean Service internals are correct; the remaining gap is infrastructure integration.

Operator mindset: separate Kubernetes object health from infrastructure provisioning state.

Takeaway:

- `LoadBalancer` still depends on the same selector and endpoint wiring
- The external IP allocation is infrastructure-dependent

---

## Validation Checklist

You are done when:

- ClusterIP service routes traffic successfully
- You identify and fix the NodePort `targetPort` mismatch
- NodePort becomes reachable after fix
- You can explain why LoadBalancer stays pending in kind

---

## Cleanup

```bash
kubectl delete svc svc-demo-clusterip svc-demo-nodeport svc-demo-loadbalancer --ignore-not-found
kubectl delete deployment svc-types-demo --ignore-not-found
```

---

## Reinforcement Scenario

- `jerry-nodeport-mystery`
