![Lab 02 Build a Redis Metrics Exporter](../../../assets/generated/week-07-lab-02/hero.png)
![Lab 02 metrics exporter build workflow](../../../assets/generated/week-07-lab-02/flow.gif)

---

# Lab 2: Build a Redis Metrics Exporter

**Time:** 55 minutes  
**Objective:** Build and deploy a small Prometheus exporter that reads real application state from Redis

---

## The Story

You already have state in Redis — your **Week 5** app writes visit counts to `visits:<username>` every time someone hits the home page.

In production, you don't debug by port-forwarding into random pods and eyeballing logs. You export metrics and graph them.

In this lab, you'll build an exporter that:
1. Connects to Redis using the same env vars as your app
2. Exposes `/metrics` in Prometheus format
3. Reports values like visit totals and comment counts

---

## Part 0: Built-in Resource Monitoring with kubectl top

Before building custom application metrics, let's explore what Kubernetes gives you out of the box for cluster and pod resource monitoring.

### Install metrics-server in kind

Resource monitoring requires `metrics-server`, which doesn't work in kind by default due to self-signed certificates:

```bash
# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Patch for kind (allow insecure TLS)
kubectl -n kube-system patch deployment metrics-server --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]'

# Wait for it to be ready
kubectl -n kube-system rollout status deployment/metrics-server
```

After ~60 seconds, verify metrics are flowing:

```bash
kubectl top nodes
kubectl top pods
```

### Explore cluster resource usage

```bash
# Node-level CPU/memory usage
kubectl top nodes

# Pod-level usage, sorted by CPU
kubectl top pods -A --sort-by=cpu

# Pod-level usage, sorted by memory
kubectl top pods -A --sort-by=memory

# Pods in a specific namespace
kubectl top pods -n kube-system

# Per-container breakdown within pods
kubectl top pods --containers -n kube-system
```

### Discovery questions

Answer these while exploring:

1. **Capacity planning:** How much CPU/memory capacity does your kind node have? What percentage is currently in use?

2. **Resource attribution:** You run `kubectl top pods` and a pod shows 450Mi memory usage, but its limit is 512Mi. Should you be worried?

3. **Accounting discrepancy:** `kubectl top nodes` shows 95% memory used, but adding up all `kubectl top pods` usage only reaches 60%. Where's the missing 35%? *(Hint: system processes, kubelet, container runtime)*

4. **No requests scenario:** A pod has no resource requests set. Does it still show up in `kubectl top pods`? *(Yes — `kubectl top` shows actual usage regardless of requests/limits)*

### kubectl top vs Prometheus

- **`kubectl top`** = point-in-time snapshot (like Linux `top`/`htop`)
- **Prometheus** = time-series history, alerting, dashboards
- Both are useful. CKA exam tests `kubectl top`. Production uses both.
- This `kubectl top` workflow is the baseline for the optional `jerry-hpa-not-scaling` scenario.

---

## Part 1: Decide What to Export

Start with simple, useful metrics:
- `course_visits_total{student="..."}`
- `course_guestbook_comments{student="..."}`

Keep labels low-cardinality. Don’t put timestamps, pod names, or unique IDs in labels.

---

## Part 2: Implement the Exporter

You've been writing Python/Flask since Week 1 — stick with what you know. Use the `prometheus_client` library to handle the Prometheus exposition format.

A starter is in [`starter/`](./starter/) with the Dockerfile, requirements, and a skeleton `exporter.py`. Fill in the `/metrics` logic.

The exporter should:
- Expose `GET /metrics` → `text/plain; version=0.0.4`
- Be **read-only** — it reads Redis keys, it should not modify them
- Use port **9100** (conventional for custom exporters, separate from your app's port 5000)

---

## Part 3: Deploy to kind

In your Week 5 kind cluster (or a fresh one), you should already have:
- Redis running
- `app-config` ConfigMap with `REDIS_HOST` and `REDIS_PORT`
- `redis-credentials` Secret with `REDIS_PASSWORD`

Build and load your exporter image:

```bash
docker build -t course-metrics-exporter:v1 .
kind load docker-image course-metrics-exporter:v1 --name lab
```

Deploy it with a Deployment + Service. Wire Redis connection the same way you did for the app:
- `envFrom: configMapRef: app-config`
- `env: secretKeyRef: redis-credentials`

Verify:

```bash
kubectl get pods
kubectl port-forward service/course-metrics-exporter 9100:9100 &
curl -s http://localhost:9100/metrics | head
kill %1
```

---

## Part 4: Seed Some Data

Your app already writes `visits:<username>` keys, so those should have data. For guestbook metrics, seed Redis manually (use the password from your `redis-credentials` Secret):

```bash
kubectl exec -it redis-0 -- redis-cli -a "$REDIS_PASSWORD" LPUSH guestbook:demo "hello"
kubectl exec -it redis-0 -- redis-cli -a "$REDIS_PASSWORD" LPUSH guestbook:demo "world"
```

Then hit `/metrics` again and confirm the count changed.

> **Note:** The `visits:<username>` key exists because your Week 5 app writes it on every page load. The `guestbook:<username>` key is hypothetical — you're seeding it here to show that the exporter can handle multiple metric types.

---

## Checkpoint

You are done when:
- `/metrics` responds
- metrics reflect real Redis state
- you can explain why this is a separate service (exporter pattern) instead of being built into the app

A complete solution is in [`solution/`](./solution/) if you get stuck.

> **Bonus:** After completing Lab 1, consider adding your exporter as a Kustomize component (`components/metrics-exporter/`) so any overlay can opt into it — just like you did with Uptime Kuma.
