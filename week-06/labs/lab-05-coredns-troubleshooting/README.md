# Lab 5: CoreDNS Troubleshooting Sprint (CKA Extension)

**Time:** 35 minutes  
**Objective:** Reproduce a CoreDNS failure, triage symptoms quickly, and restore service discovery.

---

## CKA Objectives Mapped

- Troubleshoot cluster component failures
- Troubleshoot DNS/service discovery symptoms
- Recover from CoreDNS configuration mistakes safely

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

```bash
kubectl apply -f week-06/labs/lab-05-coredns-troubleshooting/starter/dns-probe-pod.yaml
kubectl wait --for=condition=Ready pod/dns-probe --timeout=60s
kubectl exec dns-probe -- nslookup kubernetes.default.svc.cluster.local
kubectl exec dns-probe -- nslookup svc-demo-clusterip.default.svc.cluster.local || true
```

---

## Part 2: Inject Failure

Run the injection script:

```bash
bash week-06/labs/lab-05-coredns-troubleshooting/starter/inject-coredns-failure.sh
```

This script:

- Backs up current CoreDNS config to `/tmp/coredns-backup.yaml`
- Rewrites upstream forwarding to an invalid target
- Restarts CoreDNS deployment

---

## Part 3: Triage Like an Incident

Use this sequence:

```bash
kubectl exec dns-probe -- nslookup kubernetes.default.svc.cluster.local || true
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n kube-system logs deployment/coredns --tail=80
kubectl -n kube-system get configmap coredns -o yaml
kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -40
```

Capture in your notes:

1. Symptom
2. Root cause evidence command
3. Fix command
4. Verification command

---

## Part 4: Restore CoreDNS

```bash
bash week-06/labs/lab-05-coredns-troubleshooting/starter/restore-coredns.sh
kubectl -n kube-system rollout status deployment/coredns --timeout=120s
```

Re-run DNS checks:

```bash
kubectl exec dns-probe -- nslookup kubernetes.default.svc.cluster.local
```

---

## Part 5: Verification Checklist

You are done when:

- DNS lookups fail during incident window
- You identify CoreDNS configuration as root cause
- DNS lookups succeed after restore
- Your notes include command-level evidence, not guesses

---

## Cleanup

```bash
kubectl delete pod dns-probe --ignore-not-found
rm -f /tmp/coredns-backup.yaml
```

---

## Reinforcement Scenario

- `jerry-coredns-loop`
