![Lab 01 Ingress in kind](../../../assets/generated/week-06-lab-01/hero.png)
![Lab 01 Ingress controller and routing workflow](../../../assets/generated/week-06-lab-01/flow.gif)

---

# Lab 1: Ingress in kind

**Time:** 40 minutes  
**Objective:** Install an Ingress controller in a local kind cluster and route traffic to two Services using host-based routing

---

## The Story

In Weeks 4-5, you proved your app runs on Kubernetes. But you only ever reached it with `kubectl port-forward`.

Port-forward is a debugging tool, not a traffic strategy.

In this lab, you build the missing layer: **an Ingress controller**. You'll create two hostnames and route them to two different Services:
- `app.local` → your Flask app (`course-app`)
- `status.local` → Uptime Kuma (`uptime-kuma`)

---

## Background: What is Ingress?

### The problem Ingress solves

Before Ingress existed, getting external traffic into a cluster meant one of:

- **NodePort** — punch a high-numbered port (30000-32767) on every node. Hard to use with real hostnames, not firewall-friendly.
- **LoadBalancer** — one cloud load balancer per Service. Works great, but costs money and you end up with 10 public IPs for 10 services.

Neither approach lets you route `myapp.com/api` and `myapp.com/static` to different pods, or serve multiple domains from a single IP.

Ingress was introduced in Kubernetes 1.1 (2015) to solve this. It's a layer-7 (HTTP/HTTPS) routing layer that sits in front of your Services:

```
Internet
    │
    ▼
Ingress Controller (one per cluster, one IP)
    │  reads Ingress rules
    ├──▶ host: app.local  → Service: course-app
    └──▶ host: status.local → Service: uptime-kuma
```

### How it works

There are two separate pieces:

1. **`Ingress` resource** (`networking.k8s.io/v1`) — a config object. Declares rules: which hostnames and paths map to which Services. By itself it does nothing.
2. **Ingress Controller** — the actual proxy/load balancer (nginx, Traefik, HAProxy, etc.) that watches for Ingress resources and programs itself accordingly.

The split is intentional: same rules, swappable implementation.

### A note on deprecation

The Kubernetes Ingress API (`networking.k8s.io/v1`) is **not formally deprecated**, but it is widely considered legacy. In Kubernetes 1.28, the **Gateway API** (`gateway.networking.k8s.io`) graduated to stable (v1) and is the recommended path forward for new clusters.

Gateway API improves on Ingress by:
- Splitting concerns across role-oriented resources (`GatewayClass`, `Gateway`, `HTTPRoute`)
- Supporting TCP/UDP routing natively (not just HTTP)
- Enabling more expressive traffic splitting and header manipulation

In practice, **Ingress is still everywhere**. The nginx ingress controller alone runs in millions of clusters. You will encounter it constantly, which is why this lab teaches it.

**Further reading:**
- [Kubernetes Ingress docs](https://kubernetes.io/docs/concepts/services-networking/ingress/)
- [Ingress Controllers](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)
- [Gateway API docs](https://kubernetes.io/docs/concepts/services-networking/gateway/) — the modern successor
- [Gateway API project site](https://gateway-api.sigs.k8s.io/)

---

## Part 1: Recreate Your kind Cluster

Ingress needs ports 80 and 443 mapped from your host into the kind node.

Delete your old cluster (if it exists):

```bash
kind delete cluster --name lab
```

Create a new one using the provided config:

```bash
kind create cluster --name lab --config week-06/labs/lab-01-ingress-kind/starter/kind-config.yaml
kubectl config use-context kind-lab
kubectl get nodes
```

---

## Part 2: Install the nginx Ingress Controller

Ingress resources don't do anything until a controller is running.

Apply the kind-specific nginx ingress manifest:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/heads/release-1.13/deploy/static/provider/kind/deploy.yaml
```

Wait for it to be ready:

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
```

> **Heads up — node scheduling fix required.**
> The release-1.13 manifest no longer pins the controller to the control-plane node by default. In a multi-node kind cluster the controller pod can land on a worker, which doesn't have the `extraPortMappings` for ports 80/443. If `curl http://127.0.0.1/` returns "Connection reset by peer" later, run this patch now:
>
> ```bash
> kubectl patch deployment ingress-nginx-controller -n ingress-nginx \
>   --type merge \
>   -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"}}}}}'
> kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx
> ```
>
> Confirm the pod is on the control-plane before continuing:
> ```bash
> kubectl get pod -n ingress-nginx -o wide
> # NODE column should show lab-control-plane
> ```

Verify the IngressClass:

```bash
kubectl get ingressclass
```

You should see an IngressClass named `nginx`. This is what your Ingress resources will target with `spec.ingressClassName: nginx`.

---

## Part 3: Redeploy Your Flask App + Redis

You already built this stack in Week 5. Here, we just redeploy it into the fresh cluster.

### Build + Load the v5 image

```bash
docker build -t course-app:v5 week-05/labs/lab-02-configmaps-and-wiring/starter
kind load docker-image course-app:v5 --name lab
```

### Apply the Week 5 solution manifests

Redis (4 files):

```bash
kubectl apply -f week-05/labs/lab-01-helm-redis-and-vault/solution/redis-secret.yaml
kubectl apply -f week-05/labs/lab-01-helm-redis-and-vault/solution/redis-configmap.yaml
kubectl apply -f week-05/labs/lab-01-helm-redis-and-vault/solution/redis-service.yaml
kubectl apply -f week-05/labs/lab-01-helm-redis-and-vault/solution/redis-statefulset.yaml
```

App (4 files):

```bash
kubectl apply -f week-05/labs/lab-02-configmaps-and-wiring/solution/configmap.yaml
kubectl apply -f week-05/labs/lab-02-configmaps-and-wiring/solution/secret.yaml
kubectl apply -f week-05/labs/lab-02-configmaps-and-wiring/solution/deployment.yaml
kubectl apply -f week-05/labs/lab-02-configmaps-and-wiring/solution/service.yaml
```

Wait for pods:

```bash
kubectl get pods -w
```

---

## Part 4: Deploy Uptime Kuma via Helm

Uptime Kuma is third-party software. This is exactly what Helm is for.

Add the repo and inspect defaults:

```bash
helm repo add uptime-kuma https://dirsigler.github.io/uptime-kuma-helm
helm repo update

# Preview the chart's full values surface (lots of knobs)
helm show values uptime-kuma/uptime-kuma | head -100
```

Install using the provided values file:

```bash
helm install uptime-kuma uptime-kuma/uptime-kuma -f week-06/labs/lab-01-ingress-kind/starter/uptime-kuma-values.yaml
```

Verify it came up:

```bash
kubectl get pods
kubectl get svc | grep uptime
```

---

## Part 5: Test Everything with Port-Forward First

Before adding Ingress, prove both backends work.

```bash
kubectl port-forward service/course-app 8080:80 &
curl -s http://localhost:8080/ | head
curl -s http://localhost:8080/visits | python3 -m json.tool
kill %1
```

```bash
kubectl port-forward service/uptime-kuma 3001:3001 &
curl -s http://localhost:3001/ | head
kill %1
```

---

## Part 6: Create Ingress Resources

Ingress routing is primarily driven by the **Host header**.

Create and apply an Ingress for your app:

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: course-app
spec:
  ingressClassName: nginx
  rules:
  - host: app.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: course-app
            port:
              number: 80
EOF
```

What each field does:
- `spec.ingressClassName`: selects the controller (`nginx`) that should process this Ingress
- `spec.rules[].host`: matches the incoming `Host:` header (virtual host)
- `paths[].path` + `pathType`: matches the request path
- `backend.service`: the Service name and port to route to

Create and apply an Ingress for Uptime Kuma:

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: uptime-kuma
spec:
  ingressClassName: nginx
  rules:
  - host: status.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: uptime-kuma
            port:
              number: 3001
EOF
```

Verify:

```bash
kubectl get ingress
```

---

## Part 7: Configure /etc/hosts and Test

Map the hostnames to localhost:

```
127.0.0.1 app.local
127.0.0.1 status.local
```

Then test:

```bash
curl -s http://app.local/ | head
curl -s http://app.local/visits | python3 -m json.tool
curl -s http://status.local/ | head
```

If you can't edit `/etc/hosts`, you can still test by forcing the Host header:

```bash
curl -H "Host: app.local" http://127.0.0.1/ | head
curl -H "Host: status.local" http://127.0.0.1/ | head
```

---

## Part 8: Trace the Request Path

When you run `curl http://app.local/`, the important pieces are:

```
curl
  │  Host: app.local
  ▼
localhost:80
  │  (kind port mapping)
  ▼
nginx ingress controller
  │  matches Ingress rule: host=app.local
  ▼
Service: course-app
  │  selects pods with app=course-app
  ▼
Pod: course-app-xxxxx:5000
```

---

## Cleanup

Destroy the kind cluster when you're done — Lab 2 uses the shared cluster, not this one:

```bash
kind delete cluster --name lab
kubectl config get-contexts  # confirm kind-lab context is gone
```

---

## Checkpoint ✅

Before moving on, verify:

- [ ] `curl -H "Host: app.local" http://127.0.0.1/` (or `http://app.local/`) returns your Flask app
- [ ] `curl -H "Host: status.local" http://127.0.0.1/` returns the Uptime Kuma UI
- [ ] `kubectl get ingress` shows both Ingress resources with an ADDRESS populated
- [ ] You applied the nodeSelector patch and confirmed the controller pod runs on `lab-control-plane`
- [ ] You can explain what `ingressClassName: nginx` does and why removing it would break routing
- [ ] You can trace the full request path: curl → host port → kind node → nginx controller → Service → Pod
- [ ] You understand why the `EXTERNAL-IP` on the ingress-nginx Service stays `<pending>` in kind

---

## Next Lab

Continue to [Lab 2: Gateway API on the Shared Cluster](../lab-02-gateway-api/)
