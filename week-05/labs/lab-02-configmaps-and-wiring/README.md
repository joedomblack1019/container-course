![Lab 02 Wire Your App to Redis](../../../assets/generated/week-05-lab-02/hero.png)
![Lab 02 ConfigMap and wiring workflow](../../../assets/generated/week-05-lab-02/flow.gif)

---

# Lab 2: Wire Your App to Redis

**Time:** 35 minutes  
**Objective:** Use ConfigMaps, Secrets, and PVCs to connect your app to a backing service

---

## The Story

Your app has been self-contained — it serves a page and that's it. No database, no cache, no external state. If the pod dies, nothing is lost because there's nothing to lose.

That changes now. Your app gets a Redis backend. A visit counter that persists across pod restarts. Configuration that lives outside the container image. Passwords that come from Kubernetes objects, not hardcoded strings.

By the end of this lab, your pod will read its Redis connection info from a ConfigMap, its Redis password from a Secret, and Redis will store data on a PVC that survives pod deletion.

---

## Part 1: Build and Load the Updated App

The updated `app.py` adds Redis support:
- `/` — Home page now shows a visit counter and Redis connection status
- `/visits` — JSON endpoint that increments and returns the visit count
- `/info` — Pod info (from Week 4) plus Redis connection status
- `/health` — Health check that reports healthy even if Redis is down (graceful degradation)

The app reads all configuration from environment variables — it has zero knowledge of Kubernetes, ConfigMaps, or Secrets. This is the 12-factor way.

### Build and Load

```bash
cd labs/lab-02-configmaps-and-wiring/starter

# Build the image
docker build -t course-app:v5 .

# Load it into kind (kind can't pull from your local Docker daemon)
kind load docker-image course-app:v5 --name lab
```

---

## Part 1.5: Verify Redis Prerequisite

Lab 2 assumes Redis from Lab 1 already exists in the same namespace and cluster context.

```bash
# Confirm you are on the cluster you intend to use for this lab
kubectl config current-context

# Redis should exist from Lab 1
kubectl get svc redis
kubectl get pod redis-0
```

If either command says `NotFound`, create Redis now (from Lab 1 solution manifests):

```bash
kubectl apply -f ../lab-01-helm-redis-and-vault/solution/redis-configmap.yaml
kubectl apply -f ../lab-01-helm-redis-and-vault/solution/redis-secret.yaml
kubectl apply -f ../lab-01-helm-redis-and-vault/solution/redis-service.yaml
kubectl apply -f ../lab-01-helm-redis-and-vault/solution/redis-statefulset.yaml
kubectl get pods -l app=redis -w
```

Wait for `redis-0` to be `1/1 Running` before continuing.

---

## Optional Preflight: Inspect the API + Scaffold YAML

If you want to inspect resource fields before writing YAML from scratch:

```bash
# Top-level objects
kubectl explain configmap
kubectl explain secret
kubectl explain deployment

# Fields used in this lab
kubectl explain configmap.data
kubectl explain secret.stringData
kubectl explain deployment.spec.template.spec.containers.envFrom
kubectl explain deployment.spec.template.spec.containers.env.valueFrom.secretKeyRef
kubectl explain deployment.spec.template.spec.containers.env.valueFrom.fieldRef
```

You can also scaffold manifests locally without creating anything:

```bash
kubectl create configmap app-config \
  --from-literal=REDIS_HOST=redis \
  --from-literal=REDIS_PORT=6379 \
  --from-literal=ENVIRONMENT=development \
  --from-literal=GREETING=Hello \
  --dry-run=client -o yaml > configmap.generated.yaml

kubectl create secret generic redis-credentials \
  --from-literal=REDIS_PASSWORD=redis-lab-password \
  --dry-run=client -o yaml > secret.generated.yaml
```

Review and adapt those files, or continue with the handwritten YAML below.

---

## Part 2: Create a ConfigMap

A ConfigMap holds non-sensitive configuration. Redis connection details aren't secret — they're just plumbing.

Create `configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  REDIS_HOST: "redis"
  REDIS_PORT: "6379"
  ENVIRONMENT: "development"
  GREETING: "Hello"
```

Notice:
- `redis` is the headless Service name you created for Redis in Lab 1. Kubernetes DNS resolves it to the Redis pod's IP automatically.
- All values are strings. Even the port number is quoted.
- Nothing here is sensitive. If someone reads this file, they learn where Redis lives — not how to authenticate to it.

```bash
kubectl apply -f configmap.yaml
kubectl get configmap app-config -o yaml
```

---

## Part 3: Create a Secret

The Redis password is sensitive. It goes in a Secret.

Create `secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: redis-credentials
type: Opaque
stringData:
  REDIS_PASSWORD: "redis-lab-password"
```

> **`stringData` vs `data`:** Use `stringData` to write secrets in plain text — Kubernetes base64-encodes them for you. The `data` field requires you to pre-encode. Same result, less typing.

```bash
kubectl apply -f secret.yaml
kubectl get secret redis-credentials -o yaml
```

Look at the output. Your password is now `cmVkaXMtbGFiLXBhc3N3b3Jk`. That's base64, not encryption:

```bash
echo "cmVkaXMtbGFiLXBhc3N3b3Jk" | base64 -d
```

**This should bother you.** Anyone with `kubectl get secret` access can read every password in the namespace. And this YAML file in Git is even worse — it's plaintext `stringData` that anyone who clones the repo can read. We'll fix this with proper secret management in a later week.

---

## Part 4: Update Your Deployment

Your Deployment needs to consume the ConfigMap and Secret as environment variables.

Create `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: course-app
  labels:
    app: course-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: course-app
  template:
    metadata:
      labels:
        app: course-app
    spec:
      containers:
      - name: app
        image: course-app:v5
        imagePullPolicy: Never       # Image is loaded locally via kind
        ports:
        - containerPort: 5000
        envFrom:
        - configMapRef:
            name: app-config          # All keys become env vars
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: REDIS_PASSWORD
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: POD_IP
          valueFrom:
            fieldRef:
              fieldPath: status.podIP
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 15
```

Notice the two ways to inject environment variables:
- **`envFrom`** — Loads ALL keys from a ConfigMap or Secret as env vars. Clean for bulk config.
- **`env[].valueFrom`** — Loads a single key. More explicit, required when you need to pick specific keys or rename them.

```bash
kubectl apply --dry-run=client -f deployment.yaml -o yaml
kubectl apply -f deployment.yaml
kubectl get pods -w
```

Wait for pods to be `Running` and `Ready`.

---

## Part 5: Create the Service

Create `service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: course-app
spec:
  selector:
    app: course-app
  ports:
  - port: 80
    targetPort: 5000
  type: ClusterIP
```

```bash
kubectl apply -f service.yaml
```

### Test It

```bash
# Port-forward to your service
kubectl port-forward service/course-app 8080:80 &

# Hit the home page
curl http://localhost:8080

# Hit it multiple times — watch the visit counter increase
curl -s http://localhost:8080/visits | python3 -m json.tool
curl -s http://localhost:8080/visits | python3 -m json.tool
curl -s http://localhost:8080/visits | python3 -m json.tool

# Check the info endpoint
curl -s http://localhost:8080/info | python3 -m json.tool

kill %1
```

The visit counter goes up. Redis is connected. Configuration came from ConfigMaps and Secrets. The app code has zero Kubernetes awareness.

---

## Part 6: Prove It Survives

### Kill the App Pod

```bash
# Note the current visit count
curl -s http://localhost:8080/visits | python3 -m json.tool

# Kill a pod
kubectl delete pod -l app=course-app --wait=false

# The Deployment controller creates a replacement immediately
kubectl get pods -w

# Port-forward again (the old forward died with the pod)
kubectl port-forward service/course-app 8080:80 &

# Check the count — it's still there because Redis has it
curl -s http://localhost:8080/visits | python3 -m json.tool
```

The counter survived. Your app pod is stateless (Factor VI). State lives in Redis.

### Kill the Redis Pod

```bash
# Kill Redis
kubectl delete pod redis-0 --wait=false

# Watch the StatefulSet recreate it (same name, same PVC)
kubectl get pods -l app=redis -w

# Check visits — data survived because Redis has a PVC
kubectl port-forward service/course-app 8080:80 &
curl -s http://localhost:8080/visits | python3 -m json.tool
kill %1
```

The counter survived even a Redis restart because the PVC preserved the data on disk.

### Inspect the PVC

```bash
kubectl get pvc
kubectl describe pvc redis-data-redis-0
```

This PVC was created by the StatefulSet's `volumeClaimTemplates` in Lab 1. The StatefulSet guarantees that `redis-0` always reattaches to the same PVC, which is why data survives pod deletion. In kind, the PVC is backed by the node's local filesystem; in production it would be an EBS volume, NFS share, or similar durable storage.

---

## Part 7: ConfigMap Changes

What happens when you change the ConfigMap?

```bash
# Update the greeting
kubectl patch configmap app-config --type merge -p '{"data":{"GREETING":"Howdy"}}'

# Check a running pod — the change is NOT reflected
kubectl port-forward service/course-app 8080:80 &
curl -s http://localhost:8080 | grep Howdy
```

Nothing changed. Environment variables are injected at pod creation and are **not updated** while the pod is running. To pick up ConfigMap changes injected via `envFrom`:

```bash
# Restart the pods
kubectl rollout restart deployment course-app
kubectl get pods -w

# Now check
kubectl port-forward service/course-app 8080:80 &
curl -s http://localhost:8080 | grep Howdy
kill %1
```

> **File-mounted ConfigMaps are different.** If you mount a ConfigMap as a volume, Kubernetes automatically updates the file when the ConfigMap changes (within ~60 seconds). No restart needed. This is a key design consideration — the homework exercise `configmap-hot-reload` explores this.

---

## Checkpoint ✅

Before moving on, verify:

- [ ] Your app connects to Redis and the visit counter works
- [ ] Configuration comes from a ConfigMap (not hardcoded in the image)
- [ ] The Redis password comes from a Secret (not hardcoded in the image)
- [ ] Killing the app pod does not lose the visit count
- [ ] Killing the Redis pod does not lose the visit count (PVC)
- [ ] You understand the difference between `envFrom` and `env[].valueFrom`
- [ ] You understand that env-based ConfigMap changes require a pod restart

**One thing should bother you:** your `secret.yaml` has the Redis password in plain text. Anyone who clones your repo can read it. We'll fix this with proper secret management in a later week. For now, the goal is to understand how ConfigMaps and Secrets work mechanically.

---

## Next Lab

Continue to [Lab 3: Ship Redis to Production](../lab-03-ship-redis-to-prod/)
