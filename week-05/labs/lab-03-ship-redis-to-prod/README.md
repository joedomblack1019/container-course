![Lab 03 Ship Redis to Production](../../../assets/generated/week-05-lab-03/hero.png)
![Lab 03 production Redis deployment workflow](../../../assets/generated/week-05-lab-03/flow.gif)

---

# Lab 3: Ship Redis to Production

**Time:** 30 minutes  
**Objective:** Deploy your Redis-backed v5 app to the shared cluster by updating your gitops directory with backing service manifests

---

## What's Changed Since Week 4

In Week 4, you created your student directory in `talos-gitops` from scratch — a namespace, deployment, service, and kustomization for dev (in-class) and prod (homework). ArgoCD deployed your self-contained v4 app.

This week you're evolving that directory. Your app is no longer self-contained — it needs Redis. That means your gitops directory needs to grow:

```
Week 4 (what you have):              Week 5 (what you'll add):
───────────────────────               ──────────────────────────
student-infra/students/<you>/         student-infra/students/<you>/
├── kustomization.yaml                ├── kustomization.yaml
├── dev/                              ├── dev/
│   ├── kustomization.yaml            │   ├── kustomization.yaml    ← UPDATED
│   ├── namespace.yaml                │   ├── namespace.yaml
│   ├── deployment.yaml               │   ├── deployment.yaml       ← UPDATED (v5)
│   └── service.yaml                  │   ├── service.yaml
│                                     │   ├── app-config.yaml       ← NEW
│                                     │   ├── redis-secret.yaml     ← NEW
│                                     │   ├── redis-configmap.yaml  ← NEW
│                                     │   ├── redis-statefulset.yaml← NEW
│                                     │   └── redis-service.yaml   ← NEW
└── prod/                             └── prod/
    └── (same as dev)                     └── (same changes)
```

The pattern is the same as Week 4: update files, validate with `kubectl kustomize`, push a branch, open a PR, ArgoCD deploys after merge. The difference is you're shipping a backing service alongside your app — this is how real applications grow.

---

## Part 1: Push Your v5 Image to GHCR

You built `course-app:v5` locally in Lab 2. Now push it to GHCR so the shared cluster can pull it.

```bash
cd ~/container-course/week-05/labs/lab-02-configmaps-and-wiring/starter

# Tag for GHCR
docker tag course-app:v5 ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v5

# Log in to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u <YOUR_GITHUB_USERNAME> --password-stdin

# Push
docker push ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v5
```

> **Codespace users:** If you get `permission_denied`, you need a Personal Access Token (classic) with `write:packages` scope. See the [Week 4 Lab 3 instructions](../../week-04/labs/lab-03-gitops-submission/) for details.

### Verify It's Public

Your image must be publicly pullable. If you made it public in Week 4, it stays public for new tags. If not:

1. Go to `https://github.com/<YOUR_USERNAME>?tab=packages`
2. Click `container-course-app`
3. **Package settings** → **Danger zone** → Change visibility to **Public**

---

## Part 2: Sync Your Fork

Your fork of `talos-gitops` is probably behind `main` (other students have merged PRs since Week 4). Sync it before making changes:

```bash
cd ~/talos-gitops

# Make sure you're on main
git checkout main

# Add the upstream remote (if you haven't already)
git remote add upstream https://github.com/ziyotek-edu/talos-gitops.git 2>/dev/null

# Pull latest from upstream
git fetch upstream
git merge upstream/main

# Push to your fork
git push origin main

# Create your Week 5 branch
git checkout -b week05/<YOUR_GITHUB_USERNAME>
```

---

## Part 3: Update Your Deployment

Your Week 4 deployment was self-contained — one container, some env vars, no external dependencies. The v5 deployment adds Redis wiring.

Open `student-infra/students/<YOUR_GITHUB_USERNAME>/dev/deployment.yaml` and update it.

**What changes from v4 to v5:**

| Change | Why |
|--------|-----|
| Image tag `v4` → `v5` | New app version with Redis support |
| Add `envFrom: configMapRef` for `app-config` | Redis connection settings come from ConfigMap |
| Add `secretKeyRef` for `REDIS_PASSWORD` | Redis password comes from Secret |
| Update `APP_VERSION` value to `v5` | So `/info` reports the correct version |

Here's what the updated deployment looks like — compare it to your v4 deployment to see exactly what changed:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: student-app
  labels:
    app: student-app
    student: <YOUR_GITHUB_USERNAME>
spec:
  replicas: 1
  selector:
    matchLabels:
      app: student-app
  template:
    metadata:
      labels:
        app: student-app
        student: <YOUR_GITHUB_USERNAME>
    spec:
      containers:
      - name: student-app
        image: ghcr.io/<YOUR_GITHUB_USERNAME>/container-course-app:v5
        ports:
        - containerPort: 5000
          name: http
        envFrom:
        - configMapRef:
            name: app-config
        env:
        - name: REDIS_PASSWORD
          valueFrom:
            secretKeyRef:
              name: redis-credentials
              key: REDIS_PASSWORD
        - name: STUDENT_NAME
          value: "<YOUR_NAME>"
        - name: GITHUB_USERNAME
          value: "<YOUR_GITHUB_USERNAME>"
        - name: APP_VERSION
          value: "v5"
        - name: ENVIRONMENT
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
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
            memory: "256Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 5
          periodSeconds: 10
```

Notice what's **not** here that was in your local Lab 2 deployment:
- No `imagePullPolicy: Never` — the shared cluster pulls from GHCR, not a local Docker daemon
- No `replicas: 2` — start with 1 on the shared cluster (resource constraints)
- The image is the full GHCR path, not a local tag

Make the same changes to `prod/deployment.yaml`.

---

## Part 4: Add the App ConfigMap

Your app needs Redis connection settings. These come from a ConfigMap — the same pattern you used in Lab 2, but adapted for the shared cluster.

Create `student-infra/students/<YOUR_GITHUB_USERNAME>/dev/app-config.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  labels:
    app: student-app
    student: <YOUR_GITHUB_USERNAME>
data:
  REDIS_HOST: "redis"
  REDIS_PORT: "6379"
  GREETING: "Hello"
```

**`REDIS_HOST: "redis"`** — This is the name of the Redis headless Service you'll create in the next step. Because the app and Redis are in the same namespace, Kubernetes DNS resolves `redis` to the Redis pod's IP. No need for a fully-qualified domain name.

> Notice there's no `ENVIRONMENT` key here. In Week 4, you set `ENVIRONMENT` using `fieldRef: metadata.namespace` in the Deployment — it auto-detects whether it's running in dev or prod based on the namespace. That's still the right approach.

Copy the same file to `prod/`:

```bash
cp dev/app-config.yaml prod/app-config.yaml
```

---

## Part 5: Add the Redis Secret

Create `student-infra/students/<YOUR_GITHUB_USERNAME>/dev/redis-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: redis-credentials
  labels:
    app: redis
    student: <YOUR_GITHUB_USERNAME>
type: Opaque
stringData:
  REDIS_PASSWORD: "redis-lab-password"
```

Copy to `prod/`:

```bash
cp dev/redis-secret.yaml prod/redis-secret.yaml
```

> **Yes, this is plaintext in Git.** You should feel uncomfortable about that. Anyone who reads this file knows the Redis password. This is intentional tech debt — we'll replace this with a proper secret management solution (Vault or Sealed Secrets) in a later week. For now, the goal is to get the full stack deployed and working. Shipping something that works and improving security iteratively is better than never shipping because the perfect solution is too complex for one lab.

---

## Part 6: Add Redis Manifests

You wrote these in Lab 1 for your local kind cluster. Now adapt them for the shared cluster. The manifests are nearly identical — the only adjustment is adding student labels for consistency and removing the password from the ConfigMap-mounted `redis.conf` (since it's managed through the Secret in production setups). Actually, for simplicity and to match Lab 1, we'll keep the same approach.

Create the three Redis files in your `dev/` directory:

**`dev/redis-configmap.yaml`:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-config
  labels:
    app: redis
    student: <YOUR_GITHUB_USERNAME>
data:
  redis.conf: |
    requirepass redis-lab-password
    appendonly yes
    appendfsync everysec
    maxmemory 64mb
    maxmemory-policy allkeys-lru
    bind 0.0.0.0
```

> **Smaller memory limit.** On the shared cluster, resources are shared among all students. We use `64mb` instead of the `128mb` from Lab 1. The `allkeys-lru` eviction policy means Redis will drop the least-recently-used keys when it hits the limit instead of rejecting writes.

**`dev/redis-statefulset.yaml`:**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
  labels:
    app: redis
    student: <YOUR_GITHUB_USERNAME>
spec:
  serviceName: redis
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
        student: <YOUR_GITHUB_USERNAME>
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        command: ["redis-server", "/etc/redis/redis.conf"]
        ports:
        - containerPort: 6379
          name: redis
        volumeMounts:
        - name: redis-data
          mountPath: /data
        - name: redis-config
          mountPath: /etc/redis
        resources:
          requests:
            memory: "32Mi"
            cpu: "25m"
          limits:
            memory: "128Mi"
            cpu: "100m"
        readinessProbe:
          exec:
            command: ["redis-cli", "-a", "redis-lab-password", "ping"]
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          exec:
            command: ["redis-cli", "-a", "redis-lab-password", "ping"]
          initialDelaySeconds: 10
          periodSeconds: 15
      volumes:
      - name: redis-config
        configMap:
          name: redis-config
  volumeClaimTemplates:
  - metadata:
      name: redis-data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 256Mi
```

> **Smaller resource requests.** The shared cluster has limited resources. We're requesting 32Mi/25m instead of 64Mi/50m. Redis in standalone mode barely uses anything — this is plenty for a visit counter.

**`dev/redis-service.yaml`:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis
  labels:
    app: redis
    student: <YOUR_GITHUB_USERNAME>
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
    name: redis
  clusterIP: None
```

Copy all three to `prod/`:

```bash
cp dev/redis-configmap.yaml prod/redis-configmap.yaml
cp dev/redis-statefulset.yaml prod/redis-statefulset.yaml
cp dev/redis-service.yaml prod/redis-service.yaml
```

---

## Part 7: Update Kustomization Files

Your `kustomization.yaml` files need to know about the new resources. Update both dev and prod.

**`dev/kustomization.yaml`:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: student-<YOUR_GITHUB_USERNAME>-dev

resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
  - app-config.yaml
  - redis-secret.yaml
  - redis-configmap.yaml
  - redis-statefulset.yaml
  - redis-service.yaml
```

**`prod/kustomization.yaml`:**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: student-<YOUR_GITHUB_USERNAME>-prod

resources:
  - namespace.yaml
  - deployment.yaml
  - service.yaml
  - app-config.yaml
  - redis-secret.yaml
  - redis-configmap.yaml
  - redis-statefulset.yaml
  - redis-service.yaml
```

The root `kustomization.yaml` (the one that points to `dev/` and `prod/`) doesn't change — it already references both directories.

---

## Part 8: Validate

Before pushing, validate that Kustomize can render your manifests without errors:

```bash
cd ~/talos-gitops

# Render your full directory
kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/
```

This should output valid YAML containing — for each environment:
- 1 Namespace
- 1 Deployment (student-app with v5 image and envFrom)
- 1 Service (student-app-svc)
- 1 ConfigMap (app-config with Redis connection settings)
- 1 Secret (redis-credentials)
- 1 ConfigMap (redis-config with redis.conf)
- 1 StatefulSet (redis)
- 1 Service (redis, headless)

That's **16 resources total** across dev and prod. Check that namespaces are correctly set — every resource in the dev section should show `namespace: student-<YOUR_GITHUB_USERNAME>-dev`.

**Common validation mistakes:**
- File listed in `kustomization.yaml` but doesn't exist (typo in filename)
- Missing `namespace:` in a kustomization.yaml
- Label selector mismatch between Service and Deployment/StatefulSet
- `REDIS_HOST` in the ConfigMap doesn't match the Redis Service name

### Quick sanity check

```bash
# Count the resources
kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/ | grep "^kind:" | sort | uniq -c

# Should show:
#   2 ConfigMap     (app-config x2 envs + redis-config x2 envs = wait, these are 4)
```

Actually, let's be precise:

```bash
kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/ | grep -E "^kind:|^  name:|^  namespace:" | head -48
```

This shows every resource's kind, name, and namespace. Scan it to make sure everything looks right.

---

## Part 9: Verify Your Directory Structure

```
student-infra/students/<YOUR_GITHUB_USERNAME>/
├── kustomization.yaml           (unchanged from Week 4)
├── dev/
│   ├── kustomization.yaml       (updated — 8 resources)
│   ├── namespace.yaml           (unchanged)
│   ├── deployment.yaml          (updated — v5, envFrom, secretKeyRef)
│   ├── service.yaml             (unchanged)
│   ├── app-config.yaml          (NEW)
│   ├── redis-secret.yaml        (NEW)
│   ├── redis-configmap.yaml     (NEW)
│   ├── redis-statefulset.yaml   (NEW)
│   └── redis-service.yaml       (NEW)
└── prod/
    ├── kustomization.yaml       (updated — 8 resources)
    ├── namespace.yaml           (unchanged)
    ├── deployment.yaml          (updated — v5, envFrom, secretKeyRef)
    ├── service.yaml             (unchanged)
    ├── app-config.yaml          (NEW)
    ├── redis-secret.yaml        (NEW)
    ├── redis-configmap.yaml     (NEW)
    ├── redis-statefulset.yaml   (NEW)
    └── redis-service.yaml       (NEW)
```

That's 19 files total (1 root kustomization + 9 per environment). Compare to Week 4's 9 files — your infrastructure is growing alongside your application.

---

## Part 10: Submit Your Pull Request

```bash
cd ~/talos-gitops
git add student-infra/students/<YOUR_GITHUB_USERNAME>/
git commit -m "week05: add redis backing service for <YOUR_GITHUB_USERNAME>"
git push origin week05/<YOUR_GITHUB_USERNAME>
```

Go to [github.com/ziyotek-edu/talos-gitops](https://github.com/ziyotek-edu/talos-gitops) and open a pull request:

- **Base:** `main`
- **Compare:** your fork's `week05/<YOUR_GITHUB_USERNAME>` branch
- **Title:** `Week 05: <YOUR_NAME> - Redis backing service`

**Before submitting**, review the diff yourself:
- Do you see the 5 new files per environment?
- Is the deployment image `ghcr.io/<YOUR_USERNAME>/container-course-app:v5`?
- Does the app ConfigMap point `REDIS_HOST` to `redis`?
- Is `imagePullPolicy: Never` gone from the deployment?
- Does the Secret contain `redis-lab-password`? (Yes, it's plaintext. Yes, that's temporary.)

---

## Part 11: Watch the Deployment

After your PR is merged, ArgoCD detects the changes and syncs. This usually takes 1-3 minutes.

### Check ArgoCD

Open the ArgoCD dashboard at `https://argocd.lab.shart.cloud` and find your student application. You should see it syncing the new resources — ConfigMaps, Secrets, the Redis StatefulSet, and the updated Deployment.

### Verify with kubectl

```bash
# Switch to the shared cluster context
kubectl config use-context ziyotek-prod

# Check dev namespace — you should see more resources now
kubectl get all -n student-<YOUR_GITHUB_USERNAME>-dev

# Redis should be running with a stable pod name
kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-dev
# NAME                           READY   STATUS    RESTARTS   AGE
# redis-0                        1/1     Running   0          2m
# student-app-<hash>             1/1     Running   0          2m

# Check the PVC was created
kubectl get pvc -n student-<YOUR_GITHUB_USERNAME>-dev

# Check ConfigMaps and Secrets exist
kubectl get configmap,secret -n student-<YOUR_GITHUB_USERNAME>-dev

# Same for prod
kubectl get all -n student-<YOUR_GITHUB_USERNAME>-prod
```

### Test Your Live App

If the student router is configured for your namespace, test via the public URL:

```bash
# Dev environment
curl -s https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/info | python3 -m json.tool
curl -s https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/visits | python3 -m json.tool

# Hit /visits a few more times and watch the counter climb
curl -s https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/visits | python3 -m json.tool
curl -s https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/visits | python3 -m json.tool
```

If public URLs aren't set up yet, use port-forward:

```bash
kubectl port-forward -n student-<YOUR_GITHUB_USERNAME>-dev service/student-app-svc 8080:80 &
curl -s http://localhost:8080/visits | python3 -m json.tool
curl -s http://localhost:8080/info | python3 -m json.tool
kill %1
```

**What to check in the `/info` response:**
- `app_version` shows `v5`
- `redis_connected` shows `true`
- `redis_host` shows `redis`
- `pod_namespace` shows `student-<YOUR_GITHUB_USERNAME>-dev`

**What to check in the `/visits` response:**
- `visits` increments on each request
- `redis_host` shows `redis`

If `redis_connected` is `false`, debug:

```bash
# Check Redis pod status
kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-dev -l app=redis

# Check Redis logs
kubectl logs redis-0 -n student-<YOUR_GITHUB_USERNAME>-dev

# Check app logs for connection errors
kubectl logs deployment/student-app -n student-<YOUR_GITHUB_USERNAME>-dev

# Verify the ConfigMap has the right REDIS_HOST
kubectl get configmap app-config -n student-<YOUR_GITHUB_USERNAME>-dev -o yaml

# Verify the Secret exists
kubectl get secret redis-credentials -n student-<YOUR_GITHUB_USERNAME>-dev
```

---

## What You Just Did

Take a step back and look at what happened:

1. **Week 4:** You deployed a self-contained app (Deployment + Service) via GitOps.
2. **Week 5:** You added a backing service (Redis StatefulSet + Service + PVC), externalized configuration (ConfigMaps + Secrets), and deployed the entire stack via the same GitOps workflow.

Your gitops directory now describes a complete application architecture — not just a web server, but a web server with a persistent data store, externalized configuration, and secret management (even if that secret management is imperfect today).

Every week, your PR to `talos-gitops` adds new infrastructure. The directory grows, the application gets more capable, and ArgoCD handles the deployment. This is how teams ship software in production: declarative infrastructure, code-reviewed changes, automated deployment.

```
Week 1: Container image exists
Week 4: App deployed (Deployment + Service)
Week 5: App + backing service (Redis + ConfigMap + Secret + PVC)
Week 6: ???
```

The plaintext secret in your repo is a known problem. We'll fix it. But today you shipped a real application stack to production, and it works.

---

## Checkpoint ✅

Before you're done, verify:

- [ ] Your v5 image is on GHCR and publicly accessible
- [ ] Your student directory has 19 files (1 root + 9 per environment)
- [ ] `kubectl kustomize` renders all resources with correct namespaces
- [ ] Your PR is submitted to `ziyotek-edu/talos-gitops` (or merged)
- [ ] After merge: `redis-0` pod is running in both dev and prod
- [ ] After merge: `student-app` pod is running in both dev and prod
- [ ] After merge: `/visits` endpoint returns an incrementing counter
- [ ] After merge: `/info` shows `redis_connected: true` and `app_version: v5`
- [ ] You can explain why the deployment references a ConfigMap and Secret instead of hardcoding values
