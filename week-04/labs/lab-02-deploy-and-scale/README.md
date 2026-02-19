# Lab 2: Deploy, Scale, Update, Debug

**Time:** 40 minutes  
**Objective:** Deploy your app to a local Kubernetes cluster, scale it, perform a rolling update, and practice debugging failing pods

---

## Part 1: Update Your App

Your Week 1 app worked great as a container. Now we're adding a feature that only makes sense when running on Kubernetes: a `/info` endpoint that reveals which pod is handling each request.

### Get the Updated Code

The starter directory has the updated `app.py`:

```bash
cd week-04/labs/lab-02-deploy-and-scale/starter
cat app.py
```

**What's new?** The app now reads Kubernetes metadata from environment variables:

```python
POD_NAME = os.environ.get("POD_NAME", socket.gethostname())
POD_NAMESPACE = os.environ.get("POD_NAMESPACE", "unknown")
NODE_NAME = os.environ.get("NODE_NAME", "unknown")
POD_IP = os.environ.get("POD_IP", "unknown")
```

And exposes them through a `/info` endpoint:

```python
@app.route("/info")
def info():
    return {
        "pod_name": POD_NAME,
        "pod_namespace": POD_NAMESPACE,
        "node_name": NODE_NAME,
        "hostname": socket.gethostname(),
        ...
    }
```

These environment variables don't exist yet on your laptop — they'll show `"unknown"`. But when this runs on Kubernetes, we'll inject real values using the **Downward API**. More on that in Part 3.

### Customize and Build

Edit `app.py` and replace the placeholder values with your actual name and GitHub username, then build:

```bash
# Update STUDENT_NAME and GITHUB_USERNAME defaults in app.py
# Then build and tag for v4
docker build -t student-app:v4 .
```

### Quick Test Locally

```bash
docker run -d --name test-v4 -p 5000:5000 student-app:v4
curl localhost:5000/info
docker rm -f test-v4
```

The `/info` endpoint returns data, but `pod_namespace` and `node_name` show "unknown" — that's expected. Kubernetes will fill those in.

---

## Part 2: Load Your Image into kind

kind runs Kubernetes inside Docker. Your kind cluster can't pull from your local Docker images by default — it has its own image store. You need to explicitly load images into it:

```bash
kind load docker-image student-app:v4 --name lab
```

This copies the image from your local Docker into the kind node. Now Kubernetes can use it.

> **Why not just use GHCR?** You will for the gitops submission in Lab 3. But for local iteration — build, test, fix, repeat — loading directly into kind is faster than pushing to a remote registry every time.

---

## Part 3: Write Your Deployment Manifest

### How to Find This Stuff

Nobody memorizes Kubernetes YAML. Here's how you discover it:

**`kubectl explain`** is a built-in schema browser. It works offline, matches your cluster's actual API version, and is the fastest way to answer "what fields go here?":

```bash
# What goes in a Deployment?
kubectl explain deployment

# What goes in deployment.spec?
kubectl explain deployment.spec

# Keep drilling — what fields does a container have?
kubectl explain deployment.spec.template.spec.containers

# How do I set environment variables?
kubectl explain deployment.spec.template.spec.containers.env

# Show me the entire tree at once
kubectl explain deployment --recursive
```

**`kubectl create --dry-run`** generates starter YAML so you don't start from a blank file:

```bash
kubectl create deployment student-app --image=student-app:v4 --dry-run=client -o yaml
```

This outputs a minimal but valid Deployment manifest. It won't have everything you need (no env vars, no resource limits) but it gives you the skeleton — correct `apiVersion`, `kind`, label wiring, etc. You can redirect it to a file and build from there:

```bash
kubectl create deployment student-app --image=student-app:v4 --dry-run=client -o yaml > deployment.yaml
```

**Kubernetes docs** have the full API reference with examples for every resource type:

- [Deployments concept guide](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) — explains the "why" with examples
- [Deployment API reference](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/) — every field, every option
- [Downward API](https://kubernetes.io/docs/concepts/workloads/pods/downward-api/) — injecting pod metadata as env vars
- [Resource management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/) — CPU/memory requests and limits

Between `kubectl explain`, `--dry-run`, and the docs, you can build any manifest from scratch. The YAML below is what you'd arrive at — now you know where it comes from.

### The Manifest

Create a file called `deployment.yaml`. This tells Kubernetes what you want:

```yaml
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
        image: student-app:v4
        ports:
        - containerPort: 5000
          name: http
        env:
        - name: STUDENT_NAME
          value: "YOUR_NAME"
        - name: GITHUB_USERNAME
          value: "YOUR_GITHUB_USERNAME"
        - name: APP_VERSION
          value: "v4"
        - name: ENVIRONMENT
          value: "local"
        # Kubernetes Downward API — pod metadata injected as env vars
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
```

**Replace** `YOUR_NAME` and `YOUR_GITHUB_USERNAME` with your actual values.

### Understanding the Manifest

Walk through this top-to-bottom:

- **`apiVersion: apps/v1`** — Which API group this resource belongs to. Deployments live in the `apps` group.
- **`kind: Deployment`** — The type of resource.
- **`metadata.name`** — The name of this Deployment. Must be unique in the namespace.
- **`spec.replicas: 1`** — Start with 1 pod. We'll scale up shortly.
- **`spec.selector.matchLabels`** — How the Deployment finds its pods. This must match `template.metadata.labels`.
- **`spec.template`** — The pod template. Every pod created by this Deployment will look like this.
- **`env` with `valueFrom.fieldRef`** — This is the **Downward API**. Kubernetes injects runtime metadata (pod name, namespace, IP, node) as environment variables. Your app reads these to know where it's running.
- **`resources`** — CPU and memory requests/limits. Requests are what the scheduler uses for placement. Limits are the hard ceiling. Always set these.

### Deploy It

```bash
# Make sure you're on your local cluster
kubectl config current-context  # Should show kind-lab

kubectl apply -f deployment.yaml
```

### Watch It Come to Life

```bash
# Watch the pod start
kubectl get pods -w
```

Press `Ctrl+C` once the pod shows `1/1 Running`.

```bash
# See the deployment
kubectl get deployment student-app

# See the ReplicaSet it created (the middle layer between Deployment and Pod)
kubectl get replicasets

# See all the events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Test It

Forward the pod's port to your machine:

```bash
kubectl port-forward deployment/student-app 5000:5000 &
```

Now hit the endpoints:

```bash
curl localhost:5000
curl localhost:5000/info
curl localhost:5000/health
```

The `/info` endpoint now returns real Kubernetes metadata — the actual pod name, namespace, node, and IP. The Downward API is working.

```bash
# Stop the port-forward
kill %1
```

> **Heads up:** When you run `kubectl port-forward ... &`, it stays running in the background until you explicitly kill it. If you forget `kill %1` before starting a new port-forward on the same port, you'll get `bind: address already in use`. If that happens:
> ```bash
> # Kill all backgrounded jobs in this shell
> kill %1 %2 %3 2>/dev/null
> # Or find and kill whatever is holding the port
> kill $(lsof -ti :5000)
> ```
> This will come up again in Parts 4 and 5 — always kill the previous port-forward before starting a new one.

---

## Part 4: Create a Service

Port-forwarding is fine for debugging, but it only reaches one pod. A **Service** provides a stable endpoint that load-balances across all pods matching a label selector.

> **Try it yourself first:** Run `kubectl explain service.spec` to see what fields a Service takes, or generate a skeleton with:
> ```bash
> kubectl create service clusterip student-app-svc --tcp=80:5000 --dry-run=client -o yaml
> ```
> Compare the output to the manifest below — you'll see it's the same structure.

Create `service.yaml`:

```yaml
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
    targetPort: 5000
    protocol: TCP
    name: http
```

Apply it:

```bash
kubectl apply -f service.yaml
kubectl get services
```

You'll see a `ClusterIP` assigned. This is an internal IP that only works inside the cluster. To test it from your machine:

```bash
kubectl port-forward service/student-app-svc 8080:80 &
curl localhost:8080/info
kill %1
```

---

## Part 5: Scale and Observe

This is where it gets interesting. Scale to 3 replicas:

```bash
kubectl scale deployment student-app --replicas=3

# Watch the pods come up
kubectl get pods -w
```

Once all 3 are running, hit the Service from **inside** the cluster to see load balancing in action:

```bash
kubectl run curl-test --rm -it --restart=Never --image=curlimages/curl -- \
  sh -c 'for i in $(seq 1 10); do curl -s http://student-app-svc/info 2>/dev/null | grep pod_name; done'
```

Different pod names. The Service is load-balancing across your 3 replicas. Each request might hit a different pod. This is why the `/info` endpoint exists — it makes the abstract concept of "replicas" concrete and visible.

> **Why not `kubectl port-forward`?** Port-forwarding bypasses the Service's load balancing. It picks a single pod and tunnels directly to it, so every request hits the same pod. To see real load balancing, you need to go through the cluster network where kube-proxy routes traffic — that's what `kubectl run` does here by curling from inside the cluster.

### Kill a Pod and Watch Self-Healing

```bash
# Pick one of your pods
kubectl get pods

# Delete it
kubectl delete pod <PASTE_A_POD_NAME_HERE>

# Immediately watch — a new one appears
kubectl get pods -w
```

You deleted a pod, and Kubernetes created a replacement within seconds. The Deployment controller noticed the actual state (2 pods) didn't match the desired state (3 pods) and reconciled the difference. This is the reconciliation loop in action.

---

## Part 6: Rolling Updates

Change the greeting in your app to see a rolling update. Edit `app.py`:

Change `GREETING = os.environ.get("GREETING", "Hello")` to a new default, or just set it via the Deployment. Let's do it the Kubernetes way — update the manifest:

```bash
# Rebuild the image with a visible change
# Edit app.py: change the default GREETING to "Hey" or update the <h1> color
docker build -t student-app:v4.1 .

# Load into kind
kind load docker-image student-app:v4.1 --name lab
```

Now update the Deployment to use the new image:

```bash
kubectl set image deployment/student-app student-app=student-app:v4.1
```

Watch the rollout:

```bash
kubectl rollout status deployment/student-app
```

While that runs, in another terminal:

```bash
kubectl get pods -w
```

You'll see Kubernetes create new pods with the v4.1 image, wait for them to become ready, then terminate the old v4 pods. At no point are there zero running pods — this is a **rolling update**. Users would experience zero downtime.

### Check Rollout History

```bash
kubectl rollout history deployment/student-app
```

### Rollback

Changed your mind? Undo it:

```bash
kubectl rollout undo deployment/student-app
kubectl rollout status deployment/student-app
```

You're back on v4. Rollbacks are instant because Kubernetes keeps the previous ReplicaSet around.

---

## Part 7: Break Things and Debug

### Scenario: Bad Image Tag

```bash
kubectl set image deployment/student-app student-app=student-app:v999-does-not-exist
```

Watch what happens:

```bash
kubectl get pods -w
```

New pods try to start but can't pull the image. The old pods stay running (rolling update won't tear down working pods until new ones are ready). This is safe-by-default behavior.

**Debug it:**

```bash
# See the pod status — likely ImagePullBackOff or ErrImagePull
kubectl get pods

# Describe the failing pod — scroll to Events at the bottom
kubectl describe pod <FAILING_POD_NAME>

# The events will tell you exactly what went wrong:
# "Failed to pull image student-app:v999-does-not-exist: ..."
```

**Fix it** by rolling back:

```bash
kubectl rollout undo deployment/student-app
```

### Scenario: App Crashes on Startup

Let's simulate a CrashLoopBackOff. Create a broken image:

```bash
# Create a Dockerfile that will crash
cat > /tmp/Dockerfile.broken << 'EOF'
FROM python:3.11-slim
CMD ["python", "-c", "raise Exception('Jerry was here')"]
EOF

docker build -t student-app:broken -f /tmp/Dockerfile.broken .
kind load docker-image student-app:broken --name lab
kubectl set image deployment/student-app student-app=student-app:broken
```

Watch:

```bash
kubectl get pods -w
```

The pods keep restarting. The restart count climbs. Status shows `CrashLoopBackOff`.

**Debug it:**

```bash
# Check the logs — this is always your first stop
kubectl logs <CRASHING_POD_NAME>

# You'll see: Exception: Jerry was here
# The logs tell you exactly what crashed.

# If the container exits too fast, check previous container's logs:
kubectl logs <CRASHING_POD_NAME> --previous
```

**Fix it:**

```bash
kubectl rollout undo deployment/student-app
```

### Scenario: App Running But Unhealthy

```bash
# Exec into a running pod
kubectl exec -it <POD_NAME> -- /bin/sh

# Look around
ls /app
cat /app/app.py
env | grep -E "POD_|NODE_|STUDENT"

# Check networking from inside the pod
# Can you reach the other pods? The service?
wget -qO- http://student-app-svc/health

exit
```

`kubectl exec` is the equivalent of `docker exec` — it gives you a shell inside a running container. This is essential for debugging networking, file system issues, and environment variable problems.

---

## Part 8: Clean Up (But Keep the Cluster)

Remove the deployment and service, but keep the kind cluster — you'll use it for homework:

```bash
kubectl delete -f deployment.yaml
kubectl delete -f service.yaml

# Verify nothing is running
kubectl get all
```

---

## Part 9 (Optional): Generate Rollout Timeline Charts

If you want a visual timeline of scale, rollout restart, and rollback behavior:

```bash
cd week-04/labs/lab-02-deploy-and-scale
python3 scripts/benchmark_rollout_timeline.py --namespace default --deployment student-app
```

What this script does:
- Samples deployment + pod status every few seconds
- Triggers scale to 3 replicas
- Triggers `rollout restart`
- Triggers `rollout undo`
- Restores the original replica count at the end
- Generates timeline charts and a summary report

Requirements:
- `student-app` deployment exists in your namespace
- Python 3
- `matplotlib` installed (for PNG chart output)

Useful options:

```bash
# Faster test run
python3 scripts/benchmark_rollout_timeline.py --namespace default --deployment student-app --pre-seconds 10 --after-scale-seconds 20 --after-restart-seconds 30 --after-undo-seconds 30

# Observe only (no automated actions)
python3 scripts/benchmark_rollout_timeline.py --namespace default --deployment student-app --skip-actions

# Collect data only
python3 scripts/benchmark_rollout_timeline.py --namespace default --deployment student-app --no-charts

# Keep whatever scale the script set (skip automatic restore)
python3 scripts/benchmark_rollout_timeline.py --namespace default --deployment student-app --no-restore-scale
```

Artifacts are written to:

```text
assets/generated/week-04-deploy-rollout/
  deployment_rollout_timeline.png
  deployment_pod_phase_timeline.png
  summary.md
  results.json
```

![Deployment Rollout Timeline Chart](../../../assets/generated/week-04-deploy-rollout/deployment_rollout_timeline.png)

![Deployment Pod Phase Timeline Chart](../../../assets/generated/week-04-deploy-rollout/deployment_pod_phase_timeline.png)

---

## Checkpoint ✅

Before moving on, verify you can:

- [ ] Write a Deployment manifest with resource requests, probes, and Downward API env vars
- [ ] Apply manifests with `kubectl apply -f`
- [ ] Create a Service that load-balances across pods
- [ ] Scale a Deployment and observe traffic distribution
- [ ] Delete a pod and watch self-healing
- [ ] Perform a rolling update and rollback
- [ ] Debug `ImagePullBackOff` with `kubectl describe`
- [ ] Debug `CrashLoopBackOff` with `kubectl logs`
- [ ] Exec into a running pod with `kubectl exec`

---

## Demo

![Kubernetes Deploy Demo](../../../assets/week-04-lab-02-k8s-deploy.gif)

---

## Next Lab

Continue to [Lab 3: GitOps Submission — Ship to Production](../lab-03-gitops-submission/)
