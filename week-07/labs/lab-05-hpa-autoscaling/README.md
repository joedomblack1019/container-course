![Lab 05 HPA Autoscaling](../../../assets/generated/week-07-lab-05/hero.png)
![Lab 05 HPA scaling workflow](../../../assets/generated/week-07-lab-05/flow.gif)

---

# Lab 5: Horizontal Pod Autoscaler (HPA)

**Time:** 35 minutes
**Objective:** Configure HPA to automatically scale a Deployment based on CPU utilization, observe the scale-up and scale-down cycle, and understand what breaks when the metrics pipeline is missing.

---

## The Story

It is 3 AM. Your on-call phone goes off. The dashboard shows request latency climbing and error rates spiking. You SSH in, see one pod at 98% CPU, and manually run `kubectl scale deployment student-app --replicas=4`. Latency drops. You go back to bed.

Two hours later the phone goes off again. Traffic spiked again while you were asleep.

You cannot be the autoscaler. That is what this lab fixes.

HPA watches a metrics signal — CPU utilization by default — and continuously adjusts replica count to keep that signal near a target value. When load rises, it scales up. When load falls, it waits long enough to be sure, then scales down. You define the policy once and stop being woken up at 3 AM.

---

## CKA Objectives Mapped

- Implement autoscaling (HPA)
- Understand metrics-server as a prerequisite for HPA
- Troubleshoot HPA not scaling (missing requests, missing metrics-server)

---

## Background: How HPA Works

### The control loop

HPA is a Kubernetes controller that runs a reconciliation loop on a configurable interval (default: 15 seconds). Each cycle it does three things:

1. **Fetches current metrics** from the metrics pipeline (metrics-server for CPU/memory, or a custom adapter for application metrics)
2. **Calculates desired replicas** using the formula: `desiredReplicas = ceil(currentReplicas × (currentMetricValue / desiredMetricValue))`
3. **Updates the Deployment** replica count if the result differs from current replicas

```
┌─────────────────────────────────────────────────────────┐
│                      HPA Control Loop                   │
│                                                         │
│  ┌──────────────┐    metrics    ┌──────────────────┐   │
│  │ metrics-server│◄─────────────│ kubelet (on node) │   │
│  └──────┬───────┘               └──────────────────┘   │
│         │ CPU/memory                                     │
│         ▼                                               │
│  ┌──────────────┐  scale up/down  ┌────────────────┐   │
│  │     HPA      │────────────────►│   Deployment   │   │
│  │  controller  │                 │  (replicas: N) │   │
│  └──────────────┘                 └────────────────┘   │
│         ▲                                               │
│         │ targetCPU = 50%                               │
│         │ currentCPU = 80% → scale up                  │
└─────────────────────────────────────────────────────────┘
```

### Why resource requests are required

HPA calculates CPU utilization as a **percentage of the pod's CPU request**, not of the node's total CPU. If a pod has no `resources.requests.cpu` set, the denominator is zero and HPA cannot compute a meaningful percentage. The HPA will report `<unknown>` for current utilization and will not scale.

This is the most common reason HPA "doesn't work" in practice.

### The metrics-server dependency

`kubectl top` and HPA both depend on `metrics-server`, which collects resource usage from kubelet on each node and exposes it through the Kubernetes Metrics API (`metrics.k8s.io`). If metrics-server is not installed or unhealthy, HPA enters a degraded state — it does not scale to max, it does not scale to min, it freezes at its current replica count and logs a condition indicating the metrics source is unavailable.

### Scale-down stabilization

HPA deliberately delays scale-down to prevent thrashing. After load drops, it waits for a `stabilizationWindowSeconds` period (default: 300 seconds / 5 minutes) before reducing replicas. This prevents a brief traffic lull from triggering a scale-down that immediately needs to reverse when the next request burst hits.

**Further reading:**
- [Horizontal Pod Autoscaling (Kubernetes docs)](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
- [HPA walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
- [metrics-server](https://github.com/kubernetes-sigs/metrics-server)

---

## Prerequisites

Use your local kind cluster:

```bash
kubectl config use-context kind-lab
kubectl get nodes
```

### Check for student-app

This lab requires a `student-app` Deployment and `student-app-svc` Service. Check if they exist:

```bash
kubectl get deployment student-app
kubectl get service student-app-svc
```

**If both are running, skip ahead to Part 1.**

### Redeploy Week 4 (if needed)

If either resource is missing, run the block below. It deploys a minimal nginx-based stand-in that behaves the same way for HPA purposes — it serves HTTP traffic, has resource requests, and is accessible via the same Service name the load generator expects.

```bash
kubectl apply -f - <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: student-app
  labels:
    app: student-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: student-app
  template:
    metadata:
      labels:
        app: student-app
    spec:
      containers:
      - name: student-app
        image: nginx:alpine
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "256Mi"
---
apiVersion: v1
kind: Service
metadata:
  name: student-app-svc
  labels:
    app: student-app
spec:
  selector:
    app: student-app
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
EOF

kubectl rollout status deployment/student-app --timeout=60s
```

Verify both are ready before continuing:

```bash
kubectl get deployment student-app
kubectl get service student-app-svc
```

---

## Part 1: Install metrics-server

HPA cannot function without a working metrics pipeline. In kind, metrics-server requires a small patch to accept self-signed kubelet certificates.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

kubectl -n kube-system rollout status deployment/metrics-server --timeout=90s

# Wait ~60 seconds, then verify
kubectl top nodes
kubectl top pods
```

Notice: `kubectl top` is point-in-time — like running `htop` on a server. It tells you what is happening right now but retains no history. Prometheus gives you history and alerting. Both are useful; CKA tests `kubectl top`. Do not move on until `kubectl top nodes` returns data.

Operator mindset: if `kubectl top` has no data, do not debug HPA yet; restore metrics first, then evaluate scaling behavior.

---

## Part 2: Ensure Resource Requests Exist

HPA computes utilization as a percentage of the pod's CPU request. Without requests, HPA reports `<unknown>` and will not scale.

```bash
kubectl describe deployment student-app | grep -A4 requests
```

If requests are missing, patch them in:

```bash
kubectl patch deployment student-app -p='
{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "student-app",
            "resources": {
              "requests": {
                "cpu": "100m",
                "memory": "128Mi"
              }
            }
          }
        ]
      }
    }
  }
}'
kubectl rollout status deployment/student-app
```

Notice: `100m` CPU request means "one tenth of a CPU core." If this pod consumes 80m actual CPU, that is 80% utilization from HPA's perspective — even though the node itself may be nearly idle. The percentage is always relative to the request, not the node.

Operator mindset: if HPA `TARGETS` is `<unknown>` or percentages look wrong, verify CPU requests first because they define autoscaling math.

---

## Part 3: Create an HPA (Imperative)

The fastest way to attach an HPA to a Deployment on the CKA exam:

```bash
kubectl autoscale deployment student-app --cpu-percent=50 --min=1 --max=5
kubectl get hpa -w
```

Wait for the `TARGETS` column to show a real percentage rather than `<unknown>`. This can take up to 60 seconds after metrics-server is ready.

Notice: while `kubectl autoscale` is fast to type, the resulting object uses the older `autoscaling/v1` API. For production YAML you will want `autoscaling/v2`, which supports memory metrics and custom metric types. Know both for the exam.

Exam note: imperative commands are useful for speed; verify the generated API version and fields before carrying it into production manifests.

---

## Part 4: Create an HPA (Declarative)

Delete the imperative HPA and recreate it from YAML so you can see and control every field:

```bash
kubectl delete hpa student-app
```

Create `student-app-hpa.yaml`:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: student-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: student-app
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 60  # shortened for lab speed; production default is 300
```

```bash
kubectl apply -f student-app-hpa.yaml
kubectl get hpa
```

Explore the API shape before experimenting:

```bash
kubectl explain hpa.spec
kubectl explain hpa.spec.metrics
kubectl explain hpa.spec.behavior
```

Notice: the `stabilizationWindowSeconds` is set to 60 here instead of the production default of 300 so you can actually observe scale-down in a lab session. In production, 300 seconds prevents thrashing during normal traffic variance.

Authoring note: read the API docs for the fields you are writing — `kubectl explain` is the exam-safe equivalent of external docs.

---

## Part 5: Generate Load and Watch Scale-Up

Open three terminals. In terminal 1, start the load generator:

```bash
kubectl run load-gen --rm -it --restart=Never --image=busybox -- \
  /bin/sh -c "while true; do wget -q -O- http://student-app-svc; done"
```

In terminal 2, watch the HPA:

```bash
kubectl get hpa -w
```

In terminal 3, watch the pods:

```bash
kubectl get pods -w
```

You should see CPU in the TARGETS column climb past 50%, then `REPLICAS` increment as HPA schedules additional pods.

Notice: there is a lag between CPU rising and new pods serving traffic. The HPA sync interval is 15 seconds, pod startup takes additional time, and the new pods must pass readiness checks before the Service routes to them. This pipeline delay is why you should set your HPA targets conservatively rather than at 90% — you want headroom to absorb load while new pods spin up.

Performance note: autoscaling is not instantaneous. Size your target threshold to account for HPA sync interval, startup, and readiness delay.

---

## Part 6: Stop Load and Watch Scale-Down

Kill the load generator (Ctrl+C in terminal 1).

Watch the HPA in terminal 2. CPU will drop, but replicas will not immediately decrease — the stabilization window holds them in place.

```bash
kubectl get hpa -w
kubectl describe hpa student-app-hpa
```

Look at the `Conditions` section in `describe` output. You will see a `ScalingActive` condition and a `ScalingLimited` condition that explain HPA's current reasoning.

Notice: HPA stabilization prevents a scenario where a brief traffic lull causes a scale-down that immediately reverses when the next request burst arrives — which would cause Kubernetes to thrash between replica counts. The cooldown trades a little wasted capacity for scheduling stability.

Tuning note: scale-down delay is a feature, not a bug — tune stabilization to your traffic pattern instead of optimizing for instant scale-in.

---

## Part 7: Break the Metrics Pipeline

This is the failure mode you are most likely to encounter in production and on the CKA.

```bash
kubectl scale deployment metrics-server -n kube-system --replicas=0
```

Wait 30 seconds, then observe HPA:

```bash
kubectl get hpa
kubectl describe hpa student-app-hpa | grep -A5 Conditions
```

Notice: HPA does not scale to max replicas, and it does not scale to min replicas. It freezes. The `AbleToScale` condition will show `False` with a reason referencing the unavailable metrics source. This is the correct safe behavior — HPA should not guess when its data source is gone.

Restore metrics-server:

```bash
kubectl scale deployment metrics-server -n kube-system --replicas=1
kubectl -n kube-system rollout status deployment/metrics-server
kubectl top nodes
```

Operator mindset: if HPA stops scaling, check metrics availability before touching the Deployment, or you risk masking the real fault.

---

## HPA vs VPA

HPA and VPA solve different problems and should not both target the same resource signal on the same workload without careful policy configuration.

HPA changes the **number of pods** in response to a utilization signal. It is the right tool when your workload scales horizontally and individual pod capacity is roughly fixed. VPA changes the **CPU and memory requests and limits** of individual pods to right-size them for their actual consumption. It is the right tool when you want to stop over-provisioning or under-provisioning individual containers.

For CKA scenarios, default to HPA unless the prompt specifically asks about right-sizing resource requests.

---

## Verification Checklist

You are done when:

- `kubectl top nodes` returns CPU and memory data
- HPA TARGETS shows a real percentage (not `<unknown>`)
- Replica count increases under load
- Replica count decreases after load stops (wait for stabilization window)
- You can describe HPA Conditions and interpret what they say
- You can explain what happens to HPA when metrics-server is unavailable

---

## Discovery Questions

1. **Conflict:** You run `kubectl scale deployment student-app --replicas=3` while HPA has `minReplicas: 1`. Which wins? Try it and find out.

2. **Metrics lag:** Your HPA shows `cpu-percent=50` but `kubectl top pods` shows 80% CPU for individual pods. Why hasn't it scaled yet? Check `kubectl describe hpa student-app-hpa` and look at the Conditions section.

3. **Memory autoscaling:** Can you autoscale based on memory instead of CPU? Check `kubectl explain hpa.spec.metrics.resource.name`. What's different about memory as a scaling signal compared to CPU?

4. **Requests missing:** Delete the resource requests from your Deployment (`kubectl edit deployment student-app`), wait 60 seconds, and check what HPA reports. Then restore them and watch HPA recover.

---

## Cleanup

```bash
kubectl delete hpa student-app-hpa
kubectl delete pod load-gen --ignore-not-found
kubectl scale deployment student-app --replicas=1
```

---

## Reinforcement Scenarios

- `jerry-hpa-not-scaling`
- `jerry-metrics-server-down`
