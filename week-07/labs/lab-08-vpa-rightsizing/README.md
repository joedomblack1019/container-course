![Lab 08 VPA Right-Sizing](../../../assets/generated/week-07-lab-08/hero.png)
![Lab 08 VPA recommendation and apply workflow](../../../assets/generated/week-07-lab-08/flow.gif)

---

# Lab 8: Vertical Pod Autoscaler (VPA) — Right-Sizing Resource Requests

**Time:** 25-30 minutes  
**Objective:** Use VPA to observe and apply right-sized CPU/memory requests based on actual workload behavior

---

## The Story

In Lab 5 you set up HPA to scale out — more replicas when CPU climbs. But HPA assumes your resource *requests* are already accurate. If Jerry's app has `requests: cpu: 1000m` and it actually uses 80m at peak, the scheduler reserves 12.5x the CPU it needs. On a 10-node cluster that's real money and real placement inefficiency.

VPA watches your pods over time and tells you — or automatically applies — better-fit requests and limits. On the CKA exam you're expected to know what VPA is, how it differs from HPA, and how to read its recommendations.

---

## VPA vs HPA — Quick Model

| | HPA | VPA |
|---|---|---|
| What it changes | `spec.replicas` | `resources.requests` and `limits` per container |
| Responds to | Aggregate utilization across replicas | Per-pod utilization vs requests ratio |
| Scaling axis | Horizontal (more pods) | Vertical (bigger/smaller pods) |
| Pod restart required | No | Yes — VPA applies changes by evicting and recreating pods |
| Use together? | Yes, but don't let both control CPU — use VPA for memory, HPA for CPU |

---

## Part 1: Install VPA

VPA is not included in kind by default. Install it from the official repo:

```bash
# Clone the autoscaler repo (VPA lives here)
git clone https://github.com/kubernetes/autoscaler.git --depth 1
cd autoscaler/vertical-pod-autoscaler

# Install VPA components
./hack/vpa-up.sh

# Verify the three VPA components are running
kubectl get pods -n kube-system | grep vpa
```

You should see three pods:
- `vpa-recommender` — watches actual usage and generates recommendations
- `vpa-updater` — evicts pods when recommendations differ significantly from current requests
- `vpa-admission-controller` — rewrites pod specs at admission time if updateMode is `Auto`

---

## Part 2: Deploy an Under-Resourced App

Create a deployment with intentionally wrong resource requests — the kind of thing Jerry would commit:

```yaml
# deploy-overprovisioned.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jerry-overprovisioned
spec:
  replicas: 2
  selector:
    matchLabels:
      app: jerry-overprovisioned
  template:
    metadata:
      labels:
        app: jerry-overprovisioned
    spec:
      containers:
      - name: app
        image: nginx:1.25-alpine
        resources:
          requests:
            cpu: 500m        # Jerry's guess — probably too high
            memory: 256Mi    # Jerry's guess — probably too high
          limits:
            cpu: 1000m
            memory: 512Mi
```

```bash
kubectl apply -f deploy-overprovisioned.yaml
kubectl rollout status deployment/jerry-overprovisioned
```

---

## Part 3: Create a VPA Object in Recommendation Mode

Create a VPA targeting the deployment. Start in `Off` mode — this means VPA only recommends, it never touches your pods:

```yaml
# vpa-recommend.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: jerry-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: jerry-overprovisioned
  updatePolicy:
    updateMode: "Off"    # Recommend only — do not evict or mutate pods
  resourcePolicy:
    containerPolicies:
    - containerName: app
      minAllowed:
        cpu: 10m
        memory: 32Mi
      maxAllowed:
        cpu: 2
        memory: 1Gi
```

```bash
kubectl apply -f vpa-recommend.yaml
```

VPA needs time to gather metrics. Wait a few minutes, then check recommendations:

```bash
kubectl describe vpa jerry-vpa
```

Look for the `Status.Recommendation` section. You'll see `Lower Bound`, `Target`, `Upper Bound`, and `Uncapped Target` for each container.

Explore the VPA spec to understand all fields:

```bash
kubectl explain vpa.spec
kubectl explain vpa.spec.updatePolicy
kubectl explain vpa.spec.resourcePolicy.containerPolicies
```

---

## Part 4: Generate Some Load to Shape the Recommendation

Run a brief load test so VPA has more signal to work with:

```bash
# Port-forward the app
kubectl port-forward deployment/jerry-overprovisioned 8080:80 &

# Generate requests for 60 seconds
for i in $(seq 1 300); do curl -s http://localhost:8080 > /dev/null; sleep 0.2; done

# Kill port-forward
kill %1
```

After another 2-3 minutes, recheck the VPA recommendation:

```bash
kubectl describe vpa jerry-vpa
```

Compare the `Target` recommendation to Jerry's original `500m / 256Mi` requests.

---

## Part 5: Understand Update Modes

VPA has four `updateMode` values — knowing these is exam-relevant:

| Mode | Behavior |
|------|----------|
| `Off` | Recommendations only. Never modifies pods. |
| `Initial` | Applies recommendations only to *new* pods at creation. Never evicts running pods. |
| `Recreate` | Evicts pods and applies recommendations when the pod's current requests differ significantly from recommendation. |
| `Auto` | Combination of `Initial` + `Recreate`. Current default "full auto" mode. |

For production, `Off` or `Initial` are safest starting points. `Auto` in a cluster with no PodDisruptionBudgets is aggressive.

---

## Part 6: Apply Recommendations Manually (Off Mode Workflow)

Since you're in `Off` mode, you control when changes land. Read the recommendation and apply it yourself:

```bash
# Get the target recommendation
kubectl get vpa jerry-vpa -o jsonpath='{.status.recommendation.containerRecommendations[0].target}'
```

Update the deployment with the recommended values:

```bash
kubectl patch deployment jerry-overprovisioned -p='{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "app",
          "resources": {
            "requests": {
              "cpu": "<VPA target cpu>",
              "memory": "<VPA target memory>"
            }
          }
        }]
      }
    }
  }
}'
```

Verify the rollout applied cleanly:

```bash
kubectl rollout status deployment/jerry-overprovisioned
kubectl describe deployment jerry-overprovisioned | grep -A6 Requests
```

---

## HPA + VPA Together — The Safe Pattern

If you're using both on the same deployment:

- Let HPA own CPU scaling (replica count based on CPU utilization)
- Let VPA own memory right-sizing (`resourcePolicy` to exclude CPU from VPA control)
- Set VPA updateMode to `Off` or `Initial` and manually review before applying

Exclude CPU from VPA recommendations:

```yaml
resourcePolicy:
  containerPolicies:
  - containerName: app
    controlledResources:
    - memory    # VPA only recommends memory — leave CPU to HPA
```

---

## Discovery Questions

1. You have a pod with `requests.cpu: 500m` and VPA recommends `Target: 80m`. In `Off` mode, does the running pod change? What about a new pod created after you switch to `Initial` mode?

2. VPA evicts a pod to apply new resource requests. What cluster feature prevents VPA from taking down every pod in a deployment simultaneously?

3. Your deployment has 1 replica and VPA is set to `Auto`. VPA wants to right-size resources. What happens to your running pod? Is there any downtime?

4. HPA is scaling your deployment based on CPU. VPA is also running in `Auto` mode and is changing `requests.cpu`. Why might this cause the HPA to make poor decisions, and what would you do about it?

5. `kubectl describe vpa jerry-vpa` shows `Lower Bound`, `Target`, and `Upper Bound`. What is the practical difference between `Target` and `Upper Bound` for a production sizing decision?

---

## Cleanup

```bash
kubectl delete vpa jerry-vpa
kubectl delete deployment jerry-overprovisioned
cd ../../../..
rm -rf autoscaler
```

---

## Key Takeaways

- VPA right-sizes requests and limits based on observed usage — it doesn't change replica count
- `Off` mode is recommendation-only and is the safest starting point in production
- VPA applies changes by evicting and recreating pods — understand the disruption model
- HPA and VPA can coexist safely if you divide responsibility: HPA for CPU replicas, VPA for memory sizing
- CKA exam expects you to know the difference between HPA and VPA and read VPA recommendation output
