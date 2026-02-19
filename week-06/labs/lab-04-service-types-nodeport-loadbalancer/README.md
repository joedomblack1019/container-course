# Lab 4: Service Types + Endpoint Debugging (CKA Extension)

**Time:** 40 minutes  
**Objective:** Compare Service type behavior and debug a broken NodePort mapping using Endpoints and selectors.

---

## CKA Objectives Mapped

- Understand Service networking models (ClusterIP, NodePort, LoadBalancer)
- Troubleshoot Service connectivity and endpoint discovery
- Validate backend wiring with evidence-driven commands

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

```bash
kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/app-deployment.yaml
kubectl rollout status deployment/svc-types-demo --timeout=120s
kubectl get pods -l app=svc-types-demo -o wide
```

---

## Part 2: ClusterIP Baseline

```bash
kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/service-clusterip.yaml
kubectl get svc svc-demo-clusterip
kubectl get endpoints svc-demo-clusterip
```

Validate in-cluster reachability:

```bash
kubectl run svc-probe --image=busybox:1.36 --restart=Never --rm -it -- wget -qO- -T 5 http://svc-demo-clusterip
```

---

## Part 3: Broken NodePort (Intentional Failure)

Apply the intentionally broken NodePort manifest:

```bash
kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/service-nodeport-broken.yaml
kubectl get svc svc-demo-nodeport -o wide
```

Run diagnostics:

```bash
kubectl describe svc svc-demo-nodeport
kubectl get endpoints svc-demo-nodeport -o yaml
bash week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/endpoint-check.sh svc-demo-nodeport
```

Expected symptom:

- Service exists, NodePort allocated
- Endpoints missing or traffic fails because `targetPort` is wrong

---

## Part 4: Fix the NodePort Mapping

Patch the service to point at the app port (`5678`):

```bash
kubectl patch svc svc-demo-nodeport --type merge -p '{"spec":{"ports":[{"port":80,"targetPort":5678,"nodePort":30080}]}}'
kubectl get svc svc-demo-nodeport -o yaml | sed -n '1,120p'
kubectl get endpoints svc-demo-nodeport
```

Retest from inside cluster:

```bash
kubectl run nodeport-probe --image=busybox:1.36 --restart=Never --rm -it -- wget -qO- -T 5 http://svc-demo-nodeport
```

Optional host-level test (kind node mapped to localhost):

```bash
curl -s http://127.0.0.1:30080 | head
```

---

## Part 5: LoadBalancer Service Behavior

Apply the LoadBalancer variant:

```bash
kubectl apply -f week-06/labs/lab-04-service-types-nodeport-loadbalancer/starter/service-loadbalancer.yaml
kubectl get svc svc-demo-loadbalancer -o wide
```

In plain kind, `EXTERNAL-IP` is often `<pending>` unless you add a local LB implementation.

What to check anyway:

```bash
kubectl describe svc svc-demo-loadbalancer
kubectl get endpoints svc-demo-loadbalancer
```

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
