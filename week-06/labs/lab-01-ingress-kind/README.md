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
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/refs/heads/release-1.12/deploy/static/provider/kind/deploy.yaml
```

Wait for it to be ready:

```bash
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s
```

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

## Checkpoint

You are done when:
- `app.local` returns your Flask app
- `status.local` returns the Uptime Kuma UI
- You can explain what `ingressClassName` does and why host-based routing works
