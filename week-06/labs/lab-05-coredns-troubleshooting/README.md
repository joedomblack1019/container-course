![Lab 05 CoreDNS Troubleshooting Sprint](../../../assets/generated/week-06-lab-05/hero.png)
![Lab 05 CoreDNS diagnosis workflow](../../../assets/generated/week-06-lab-05/flow.gif)

---

# Lab 5: CoreDNS Troubleshooting Sprint (CKA Extension)

**Time:** 35 minutes  
**Objective:** Reproduce a CoreDNS failure, triage symptoms quickly, and restore service discovery.

---

## The Story

This is the outage that makes healthy apps look broken: pods are running, deployments are green, but every service call starts failing because names no longer resolve. In real incidents, teams often chase the wrong layer first (app code, Redis, network policy) and lose valuable time. In this lab, you will intentionally break cluster DNS, read the evidence trail, and restore service discovery with the same workflow expected on the CKA.

---

## CKA Objectives Mapped

- Troubleshoot cluster component failures
- Troubleshoot DNS/service discovery symptoms
- Recover from CoreDNS configuration mistakes safely

---

## Background: CoreDNS and Cluster DNS

### How Kubernetes service discovery works

When you create a Service, Kubernetes automatically registers a DNS name for it. Any pod in the cluster can resolve `my-service.my-namespace.svc.cluster.local` without any extra configuration.

This works because every pod is configured (via `/etc/resolv.conf`) to use a DNS server running inside the cluster. That server is **CoreDNS**.

```
Pod wants to reach "redis"
    │
    ▼
/etc/resolv.conf: nameserver 10.96.0.10  ← CoreDNS ClusterIP
    │
    ▼
CoreDNS: looks up redis in cluster.local zone
    │  → found: redis.default.svc.cluster.local → 10.96.42.1
    ▼
Pod connects to 10.96.42.1 (the Service ClusterIP)
```

### What CoreDNS is

CoreDNS is a Go-based DNS server that replaced kube-dns in Kubernetes 1.13. It runs as a Deployment in `kube-system`, usually with 2 replicas. Its configuration lives in a ConfigMap called `coredns`, in a format called a **Corefile**.

A minimal Corefile:

```
cluster.local {
    kubernetes cluster.local in-addr.arpa ip6.arpa {
        pods insecure
        fallthrough in-addr.arpa ip6.arpa
    }
    cache 30
    loop
    reload
    forward . /etc/resolv.conf   ← upstream for non-cluster names
}
```

The `forward` directive controls where non-cluster DNS queries go (e.g. `google.com`). If this points at an invalid target, external resolution fails — which often looks like a total network outage.

### Why DNS failures are deceptive

DNS failure is one of the hardest cluster issues to diagnose because:

- Pods stay `Running` — DNS failure doesn't crash containers
- Error messages are misleading — apps report "connection refused" or "host not found", not "DNS is broken"
- It's cascading — if your app can't resolve `redis`, it reports a Redis error, not a DNS error

The fastest triage path is always: **can a pod resolve `kubernetes.default.svc.cluster.local`?** If not, DNS is the problem, not your app.

**Baseline triage commands — run these first in any DNS incident:**

```bash
# 1. Check CoreDNS pods are Running and not restarting
kubectl -n kube-system get pods -l k8s-app=kube-dns

# 2. Resolve the canonical cluster name from inside the CoreDNS pod itself
COREDNS=$(kubectl -n kube-system get pods -l k8s-app=kube-dns -o name | head -1)
kubectl -n kube-system exec "$COREDNS" -- nslookup kubernetes.default.svc.cluster.local

# 3. Try from a workload pod to confirm the path pods take
kubectl run dns-probe --rm -it --image=busybox:1.36 -- nslookup kubernetes.default.svc.cluster.local

# 4. Inspect the Corefile — forward directive is the most common failure point
kubectl describe configmap coredns -n kube-system

# 5. Read recent CoreDNS logs for errors (SERVFAIL, loop, plugin panics)
kubectl -n kube-system logs deployment/coredns --tail=60
```

### Common CoreDNS failure modes

| Symptom | Likely cause |
|---|---|
| All DNS fails, including cluster names | CoreDNS pods crashed or OOMKilled |
| Cluster names resolve, external names fail | Bad `forward` upstream in Corefile |
| Intermittent timeouts | CoreDNS under-resourced; scale the deployment |
| `SERVFAIL` on specific names | Corefile syntax error or loop plugin triggered |

### The Corefile lives in a ConfigMap

This is both a feature and a footgun. You can update CoreDNS configuration with `kubectl edit configmap coredns -n kube-system` (or patch it), and CoreDNS reloads automatically (the `reload` plugin watches for changes). But a bad edit takes effect immediately across the whole cluster.

**Further reading:**
- [DNS for Services and Pods (Kubernetes docs)](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
- [CoreDNS Customization](https://kubernetes.io/docs/tasks/administer-cluster/dns-custom-nameservers/)
- [Debugging DNS resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)
- [CoreDNS project docs](https://coredns.io/manual/toc/)

---

## Prerequisites

Use local kind cluster only:

```bash
kubectl config use-context kind-lab
kubectl get nodes
```

Starter assets for this lab are in [`starter/`](./starter/):

- `dns-probe-pod.yaml`
- `inject-coredns-failure.sh`
- `restore-coredns.sh`
- `triage-checklist.md`

---

## Part 1: Baseline DNS Health

Create a probe pod and confirm DNS works before fault injection:

You are establishing a control state first. If you do not prove DNS is healthy now, you cannot confidently attribute later failures to your injected CoreDNS change.

```bash
kubectl apply -f week-06/labs/lab-05-coredns-troubleshooting/starter/dns-probe-pod.yaml
kubectl wait --for=condition=Ready pod/dns-probe --timeout=60s
kubectl exec dns-probe -- nslookup kubernetes.default.svc.cluster.local
kubectl exec dns-probe -- nslookup svc-demo-clusterip.default.svc.cluster.local || true
```

If `svc-demo-clusterip` does not exist in your cluster, expect `NXDOMAIN` on the second lookup. That is a healthy DNS response for a missing name, not a CoreDNS outage.

Notice: `kubernetes.default.svc.cluster.local` is the canonical baseline check because it should exist in every cluster. The second lookup may fail if that Service is absent, but the key signal is that DNS resolution itself works before injection.

Operator mindset: prove a known-good baseline before introducing failure.

---

## Part 2: Inject Failure

Run the injection script:

This is a controlled blast radius exercise. You are creating a predictable DNS fault so you can practice diagnosis under pressure without guessing.

```bash
bash week-06/labs/lab-05-coredns-troubleshooting/starter/inject-coredns-failure.sh
```

This script:

- Backs up current CoreDNS config to `/tmp/coredns-backup.yaml`
- Rewrites upstream forwarding to an invalid target
- Restarts CoreDNS deployment

Notice: this is not random breakage. The backup file gives you a clean rollback path, and the invalid `forward` target creates a failure class you should recognize quickly in logs and lookup symptoms.

Operator mindset: break systems deliberately only when you also control recovery.

---

## Part 3: Triage Like an Incident

Use this sequence:

Run these in order to narrow scope fast: client symptom first, then component health, then logs/config evidence, then event timeline.

```bash
kubectl exec dns-probe -- nslookup kubernetes.default.svc.cluster.local || true
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n kube-system logs deployment/coredns --tail=80
kubectl -n kube-system get configmap coredns -o yaml
kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -40
```

Notice: you are building a chain of proof, not collecting random output. If lookups fail from the probe while CoreDNS logs and Corefile show bad forwarding, you have root-cause evidence that DNS config (not app code) is the fault domain.

Capture in your notes:

1. Symptom
2. Root cause evidence command
3. Fix command
4. Verification command

Operator mindset: always leave an evidence trail another operator could replay.

---

## Part 4: Restore CoreDNS

Now execute a targeted restore and wait for control-plane convergence. Fast fixes still require explicit readiness confirmation.

```bash
bash week-06/labs/lab-05-coredns-troubleshooting/starter/restore-coredns.sh
kubectl -n kube-system rollout status deployment/coredns --timeout=120s
```

Notice: restoration is not complete until rollout status reports success. A rollback command without a healthy rollout is just a change request, not recovery.

Re-run DNS checks:

This is your "incident closed" proof: user-path symptom is gone from inside a workload pod.

```bash
kubectl exec dns-probe -- nslookup kubernetes.default.svc.cluster.local
```

Operator mindset: declare recovery only after symptom-level verification.

---

## Part 5: Verification Checklist

This checklist turns troubleshooting into objective criteria. If you cannot point to these outcomes, you are not done yet.

You are done when:

- DNS lookups fail during incident window
- You identify CoreDNS configuration as root cause
- DNS lookups succeed after restore
- Your notes include command-level evidence, not guesses

Notice: this mirrors CKA scoring behavior and real incident review standards: observable symptom, evidenced cause, tested fix, confirmed recovery.

Operator mindset: optimize for reproducible diagnosis, not heroic intuition.

---

## Cleanup

```bash
kubectl delete pod dns-probe --ignore-not-found
rm -f /tmp/coredns-backup.yaml
```

---

## Reinforcement Scenario

- `jerry-coredns-loop`
