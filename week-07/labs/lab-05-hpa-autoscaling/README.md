# Lab 5: Horizontal Pod Autoscaler (HPA)

**Time:** 20-25 minutes
**Objective:** Set up automated scaling based on CPU utilization

---

## The Story

In **Week 4 Lab 2**, you manually scaled your app with `kubectl scale deployment student-app --replicas=3`. But what happens when traffic spikes at 3 AM? HPA watches metrics and scales for you.

This lab shows you how to configure workload autoscaling — a core CKA competency.

---

## Part 1: Install metrics-server in kind

HPA needs metrics to make scaling decisions. The `metrics-server` collects resource usage from kubelets, but it doesn't work in kind by default due to self-signed certificates.

```bash
# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch for kind (allow insecure TLS)
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# Wait for it to be ready
kubectl -n kube-system rollout status deployment/metrics-server

# Verify (should show CPU/memory usage after ~60 seconds)
kubectl top nodes
```

If `kubectl top nodes` returns data, metrics-server is working.

---

## Part 2: Create an HPA (Imperative)

First, ensure your app has resource requests set (from Week 4 Lab 2):

```bash
kubectl describe deployment student-app | grep -A2 -B2 requests
```

If no requests are set, the HPA can't calculate CPU percentage. Update your deployment:

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
```

Now create the HPA:

```bash
kubectl autoscale deployment student-app --cpu-percent=50 --min=1 --max=5
kubectl get hpa -w
```

The HPA targets 50% CPU utilization. When average CPU exceeds 50%, it scales up. When below 50%, it scales down.

---

## Part 3: Create an HPA (Declarative)

You can also define HPA in YAML. Delete the existing HPA and recreate it:

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
      stabilizationWindowSeconds: 300  # Wait 5 minutes before scaling down
```

Apply it:

```bash
kubectl apply -f student-app-hpa.yaml
kubectl get hpa
```

Explore the HPA spec using familiar commands:

```bash
kubectl explain hpa.spec
kubectl explain hpa.spec.metrics
kubectl explain hpa.spec.behavior
```

---

## Part 4: Generate Load and Watch Scaling

Create a load generator to drive CPU usage:

```bash
# Start load generator (runs until you Ctrl+C)
kubectl run load-gen --rm -it --restart=Never --image=busybox -- \
  /bin/sh -c "while true; do wget -q -O- http://student-app-svc; done"
```

In another terminal, watch the HPA and pods scale:

```bash
# Watch HPA metrics and target replicas
kubectl get hpa -w

# In a third terminal, watch pods being created
kubectl get pods -w
```

You should see:
1. CPU usage climbing in the HPA output
2. Current replicas increasing from 1 → 2 → 3 → etc.
3. New pods being created

---

## Part 5: Stop Load and Watch Scale Down

Kill the load generator (Ctrl+C in the first terminal).

Watch the HPA scale back down:

```bash
kubectl get hpa -w
```

HPA waits ~5 minutes (the `stabilizationWindowSeconds`) before scaling down to prevent thrashing.

---

## HPA vs VPA (Exam Note)

- **HPA** changes replica count (`Deployment.spec.replicas`) based on usage signals.
- **VPA** changes pod CPU/memory requests and limits per container.
- For CKA scenarios, default to HPA workflows unless the prompt explicitly asks about right-sizing requests.
- In production, avoid letting HPA and VPA both control CPU/memory for the same workload without explicit policy guardrails.

---

## Part 6 (Optional): Generate HPA Timeline Charts

If you want a time-series visualization of autoscaling behavior:

```bash
cd week-07/labs/lab-05-hpa-autoscaling
python3 scripts/benchmark_hpa.py --namespace default
```

This script will:
- Start a load-generator pod against `student-app-svc`
- Sample HPA and Deployment status every few seconds
- Stop load and continue sampling cooldown behavior
- Generate timeline charts and a summary

Requirements:
- `student-app` deployment exists
- `student-app-hpa` exists
- metrics-server is working (`kubectl top nodes` returns data)
- Python 3
- `matplotlib` installed (for PNG chart output)

Useful options:

```bash
# Shorter run for quick tests
python3 scripts/benchmark_hpa.py --namespace default --load-seconds 60 --cooldown-seconds 60

# If you used imperative HPA name from Part 2 (`student-app`)
python3 scripts/benchmark_hpa.py --namespace default --hpa student-app

# Capture only (no load generator)
python3 scripts/benchmark_hpa.py --namespace default --skip-load

# Collect data only (no charts)
python3 scripts/benchmark_hpa.py --namespace default --no-charts
```

Artifacts are written to:

```text
assets/generated/week-07-hpa-autoscaling/
  hpa_timeline.png
  deployment_replica_timeline.png
  summary.md
  results.json
```

![HPA Timeline Chart](../../../assets/generated/week-07-hpa-autoscaling/hpa_timeline.png)

![Deployment Replica Timeline Chart](../../../assets/generated/week-07-hpa-autoscaling/deployment_replica_timeline.png)

---

## Discovery Questions

1. **Conflict Resolution:** Set `kubectl scale deployment student-app --replicas=3` while HPA `minReplicas: 1`. Which wins? Why?

2. **Metrics Lag:** Your HPA shows `cpu-percent=50` but `kubectl top pods` shows 80% CPU for individual pods. Why hasn't it scaled yet?
   - *Hint:* Check `kubectl describe hpa student-app` and look at the Conditions section.

3. **Failure Modes:** What happens if metrics-server goes down? Does HPA scale to max replicas? To min? Neither?
   - *Hint:* Try `kubectl scale deployment metrics-server -n kube-system --replicas=0` and observe HPA behavior.

4. **Resource Types:** Can you autoscale based on memory usage instead of CPU? What about custom metrics?
   - *Hint:* Check `kubectl explain hpa.spec.metrics.resource.name`.

---

## Cleanup

```bash
kubectl delete hpa student-app-hpa
kubectl delete pod load-gen --ignore-not-found
kubectl scale deployment student-app --replicas=1
```

---

## Key Takeaways

- HPA automates what you did manually with `kubectl scale`
- Requires metrics-server for CPU/memory-based scaling
- Targets resource utilization percentages, not absolute values
- Has built-in stabilization to prevent rapid scale up/down cycles
- CKA exam may ask for both imperative (`kubectl autoscale`) and declarative (YAML manifest) approaches
