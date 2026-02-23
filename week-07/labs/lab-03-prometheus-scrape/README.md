![Lab 03 Scrape With Prometheus](../../../assets/generated/week-07-lab-03/hero.png)
![Lab 03 Prometheus scrape and query workflow](../../../assets/generated/week-07-lab-03/flow.gif)

---

# Lab 3: Scrape With Prometheus (Minimal Demo in kind)

**Time:** 35 minutes  
**Objective:** Deploy Prometheus in kind, scrape your exporter, and query metrics with PromQL

---

## The Story

Exporting metrics is only half the job. The other half is proving that something can scrape them reliably.

In this lab, you’ll deploy a single Prometheus instance with a tiny config that scrapes your exporter Service.

We’re keeping this intentionally minimal:
- No operator
- No ServiceMonitors
- No “install the whole monitoring stack”

Just the core loop: **export → scrape → query**.

---

## Part 1: Create a Prometheus ConfigMap

Create `prometheus.yml` that scrapes your exporter Service:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: course-metrics-exporter
    metrics_path: /metrics
    static_configs:
      - targets:
          - course-metrics-exporter:9100
```

---

## Part 2: Deploy Prometheus

Deploy three resources:
- **ConfigMap** with your `prometheus.yml`
- **Deployment** running `prom/prometheus` with the ConfigMap mounted
- **Service** on port 9090

The `prom/prometheus` image looks for config at `/etc/prometheus/prometheus.yml` by default. Mount your ConfigMap there:

```yaml
volumes:
  - name: config
    configMap:
      name: prometheus-config
containers:
  - name: prometheus
    image: prom/prometheus
    volumeMounts:
      - name: config
        mountPath: /etc/prometheus
```

> **Important:** Deploy Prometheus in the same namespace as your exporter. The scrape config uses the short service name `course-metrics-exporter:9100` — that only resolves within the same namespace. If they're in different namespaces, use the FQDN: `course-metrics-exporter.<namespace>.svc.cluster.local:9100`.

Solution manifests are in [`solution/`](./solution/) if you get stuck.

Then port-forward the UI:

```bash
kubectl port-forward service/prometheus 9090:9090 &
```

Open:

`http://localhost:9090`

---

## Part 3: Verify Targets and Query Metrics

1. Go to **Status → Targets**
2. Confirm your exporter is `UP`
3. Run queries like:
   - `up`
   - `course_visits_total`
   - `course_guestbook_comments`

---

## Checkpoint

You are done when:
- Prometheus targets show your exporter `UP`
- PromQL queries return your custom metrics
- you can explain the scrape model (Prometheus pulls metrics on an interval)

> **Bonus:** Query `up` in the PromQL box. You'll see Prometheus also scrapes itself — that's the self-monitoring loop baked into the default config.
