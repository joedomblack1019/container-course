![Lab 01 Create Your kind Cluster and Explore](../../../assets/generated/week-04-lab-01/hero.png)
![Lab 01 kind cluster bootstrap and exploration](../../../assets/generated/week-04-lab-01/flow.gif)

---

# Lab 1: Create Your kind Cluster & Explore

**Time:** 30 minutes  
**Objective:** Stand up a local Kubernetes cluster, learn essential kubectl commands, and discover that your Week 1 apps are already running on Kubernetes

---

## Part 1: Create Your Local Cluster

kind (Kubernetes IN Docker) runs Kubernetes nodes as Docker containers. You already have Docker, so this is the fastest way to get a real cluster on your machine.

### Create the Cluster

```bash
kind create cluster --name lab
```

This takes about 60 seconds. kind is pulling a node image (a Docker container that runs `kubelet`, `kube-proxy`, and the control plane components), then bootstrapping a single-node Kubernetes cluster inside it.

When it finishes, you'll see:

```
Creating cluster "lab" ...
 ✓ Ensuring node image (kindest/node:v1.35.0) 🖼
 ✓ Preparing nodes 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
Set kubectl context to "kind-lab"
```

### Verify

```bash
kubectl cluster-info --context kind-lab
```

You should see the API server address (something like `https://127.0.0.1:PORT`).

### What Just Happened?

Let's peek behind the curtain. Your "cluster" is a Docker container:

```bash
docker ps
```

You'll see a container named `lab-control-plane` running the `kindest/node` image. That single container is running the entire Kubernetes control plane plus acting as a worker node. For learning purposes, this is all we need.

```bash
# See the Kubernetes components running inside the "node"
kubectl get pods -n kube-system
```

These are the components from the lecture: `etcd`, `kube-apiserver`, `kube-controller-manager`, `kube-scheduler`, `coredns`, and the CNI (network plugin). They're running as pods inside the cluster — Kubernetes uses itself to run its own components.

---

## Part 2: kubectl — Your Primary Tool

`kubectl` is how you interact with any Kubernetes cluster. Every command follows the pattern:

```
kubectl <verb> <resource> [name] [flags]
```

### Essential Commands

**Explore what's in the cluster:**

```bash
# List all nodes (just one for kind)
kubectl get nodes

# Detailed node info — CPU, memory, OS, container runtime
kubectl describe node lab-control-plane

# List all namespaces
kubectl get namespaces
```

**Namespaces** are virtual partitions within a cluster. Think of them like folders that keep resources organized and isolated. Your kind cluster came with:
- `default` — where your resources go if you don't specify a namespace
- `kube-system` — Kubernetes internal components
- `kube-public` — readable by everyone, rarely used
- `local-path-storage` — kind's storage provider

**Get resources in a specific namespace:**

```bash
# What's running in kube-system?
kubectl get pods -n kube-system

# Get ALL resources across ALL namespaces
kubectl get all --all-namespaces
```

**Get more detail:**

`kubectl get` supports many output formats beyond the default table. Take 5 minutes to skim the [`kubectl get` reference](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_get/) — look at the `--output` flag and the list of formats (`wide`, `yaml`, `json`, `jsonpath`, `custom-columns`, etc.). You'll use these constantly.

```bash
# Wide output shows node placement and IPs
kubectl get pods -n kube-system -o wide

# Full YAML representation of any resource
kubectl get pod -n kube-system etcd-lab-control-plane -o yaml

# Just the names — useful for scripting
kubectl get pods -n kube-system -o name

# Pull a specific field with jsonpath
kubectl get pod -n kube-system etcd-lab-control-plane -o jsonpath='{.status.phase}'
```

### The API Resources

Kubernetes has dozens of resource types. See them all:

```bash
kubectl api-resources
```

For now, the ones that matter are. Click through to the docs for each — you don't need to memorize them, but knowing where to look is half the job:

| Resource | Short Name | What It Does |
|----------|-----------|-------------|
| [pods](https://kubernetes.io/docs/concepts/workloads/pods/) | po | Smallest runnable unit |
| [deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/) | deploy | Manages replica sets of pods |
| [services](https://kubernetes.io/docs/concepts/services-networking/service/) | svc | Stable network endpoints |
| [replicasets](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/) | rs | Ensures N pod copies exist |
| [namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/) | ns | Virtual cluster partitions |
| [configmaps](https://kubernetes.io/docs/concepts/configuration/configmap/) | cm | Configuration data |
| [secrets](https://kubernetes.io/docs/concepts/configuration/secret/) | — | Sensitive configuration data |
| [events](https://kubernetes.io/docs/reference/kubernetes-api/cluster-resources/event-v1/) | ev | Log of what happened in the cluster |

### Practice: Explore the Cluster

Before moving on, try these commands and observe the output:

```bash
# How many CPU cores and how much memory does your node have?
kubectl describe node lab-control-plane | grep -A 5 "Capacity:"

# What container runtime is this node using?
kubectl describe node lab-control-plane | grep "Container Runtime"

# What pods are using the most resources?
kubectl top pods -n kube-system 2>/dev/null || echo "Metrics server not installed (expected for kind)"

# List all events in the cluster — this is your first debugging tool
kubectl get events --all-namespaces --sort-by=.metadata.creationTimestamp
```

---

## Part 3: Pull Back the Curtain

Remember Week 1? You built a container image, pushed it to GHCR, and submitted a pull request to the `container-gitops` repo. You were told your app was "deployed." But deployed where?

It's time to find out.

### Connect to the Shared Cluster

The shared cluster's Kubernetes API is exposed through a Cloudflare Tunnel. You'll use `cloudflared` to create a local TCP proxy and `kubelogin` (already installed in the devcontainer) to authenticate via GitHub.

**Start the tunnel proxy** (in a separate terminal, or background it):

```bash
cloudflared access tcp --hostname kube.lab.shart.cloud --url localhost:6443 &
```

A browser window will open for Cloudflare Access authentication. Sign in with your GitHub account.

**Add the shared cluster context** to your kubeconfig (one-time setup):

```bash
# Add the cluster (points at the local cloudflared proxy)
kubectl config set-cluster ziyotek-prod \
  --server=https://localhost:6443 \
  --insecure-skip-tls-verify=true

# Add OIDC credentials (uses kubelogin for browser-based GitHub login)
kubectl config set-credentials oidc \
  --exec-api-version=client.authentication.k8s.io/v1beta1 \
  --exec-command=kubectl \
  --exec-arg=oidc-login \
  --exec-arg=get-token \
  --exec-arg=--oidc-issuer-url=https://argocd.lab.shart.cloud/api/dex \
  --exec-arg=--oidc-client-id=kubernetes \
  --exec-arg=--oidc-client-secret=hprtOl5JG85iadQL8AzCSkAdM15tRjZR \
  --exec-arg=--oidc-extra-scope=email \
  --exec-arg=--oidc-extra-scope=groups \
  --exec-arg=--oidc-extra-scope=profile \
  --exec-arg=--listen-address=localhost:8000

# Create a context that ties the cluster and credentials together
kubectl config set-context ziyotek-prod \
  --cluster=ziyotek-prod \
  --user=oidc
```

**Switch to the shared cluster:**

```bash
kubectl config use-context ziyotek-prod
```

The first `kubectl` command will trigger a GitHub OIDC login. kubelogin starts a local web server on port 8000 and tries to open your browser.

**If you're on your local machine:** A browser window opens automatically. Sign in with GitHub and the token is returned.

**If you're in a Codespace:** There's no browser inside the container, so kubelogin will print a message like:

```
error: could not open the browser: exec: "xdg-open": executable file not found
Please visit the following URL in your browser manually: http://localhost:8000/
```

Here's what to do:

1. Open the **Ports** tab in your Codespace (next to Terminal)
2. Find port **8000** — right-click it and set **Port Visibility** to **Public**
3. Run your `kubectl` command (e.g., `kubectl get namespaces`) — it will hang waiting for auth
4. Copy the `http://localhost:8000` URL from the terminal output and open it in your browser
5. You'll be redirected to GitHub to sign in
6. After signing in, the redirect back to `localhost:8000` will **fail** in your browser — this is expected. The Codespace's port 8000 isn't your local machine's port 8000.
7. **Copy the full URL** from your browser's address bar (it looks like `http://localhost:8000/?code=XXXXX&state=YYYYY`)
8. Back in your Codespace terminal, run:
   ```bash
   curl "http://localhost:8000/?code=XXXXX&state=YYYYY"
   ```
   (paste the full URL you copied)
9. kubelogin receives the auth code, exchanges it for a token, and your `kubectl` command completes

The token is cached after the first login — subsequent `kubectl` commands won't require re-authentication until the token expires.

> **Why does this happen?** The OIDC login flow uses a browser redirect: you authenticate with GitHub, then GitHub sends you back to `http://localhost:8000` with an auth code. On your local machine, localhost:8000 reaches kubelogin directly. In a Codespace, localhost in your browser means *your* machine, not the Codespace — so the redirect fails. The `curl` workaround delivers the auth code to kubelogin inside the Codespace.

### See Your Apps

```bash
# List the namespaces — look for container-course-week01
kubectl get namespaces | grep container

# There it is. Let's see what's running:
kubectl get pods -n container-course-week01
```

You should see pods with names like `student-almsid-*`, `student-otajon99-*`, `student-emmzi55-*`. Those are the Week 1 containers — your containers — running on a real Kubernetes cluster.

```bash
# See the full picture: deployments, services, pods
kubectl get all -n container-course-week01

# Look at one deployment in detail
kubectl describe deployment student-<YOUR_USERNAME> -n container-course-week01

# Check the logs of your running app
kubectl logs deployment/student-<YOUR_USERNAME> -n container-course-week01
```

### What's Actually Running?

```bash
# See the exact container image each pod is running
kubectl get pods -n container-course-week01 -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
```

Those are the GHCR images you pushed in Week 1. The PR you submitted added an entry to `students/week-01.yaml`. A GitHub Actions workflow generated Kubernetes manifests (Deployment + Service) for each student. ArgoCD watched the repo and deployed those manifests to this cluster.

You've been running on Kubernetes since Week 1. You just didn't know it yet.

### Switch Back to Local

For the rest of today's labs, we work on your local kind cluster:

```bash
kubectl config use-context kind-lab
```

> **Managing multiple contexts:** You now have two contexts in your kubeconfig — `kind-lab` (local) and `ziyotek-prod` (shared cluster). You can list them anytime:
> ```bash
> kubectl config get-contexts
> ```
> The `*` marks your active context. Always check which cluster you're talking to before running commands:
> ```bash
> kubectl config current-context
> ```
> Accidentally running `kubectl delete` on the wrong context is a real-world mistake that ruins someone's day.

---

## Part 4: Run a Quick Pod (Optional Exploration)

Before we get into Deployments in Lab 2, let's see what a raw pod looks like:

```bash
# Run a single nginx pod
kubectl run test-nginx --image=nginx --port=80

# Watch it come up
kubectl get pods -w
```

Press `Ctrl+C` once the pod shows `Running`.

```bash
# Describe it — see all the events that led to it running
kubectl describe pod test-nginx

# Read the events from the bottom up:
# 1. Scheduled — scheduler picked a node
# 2. Pulling — kubelet pulling the image
# 3. Pulled — image download complete
# 4. Created — container created
# 5. Started — container running
```

Now delete it:

```bash
kubectl delete pod test-nginx
```

It's gone. Permanently. There's no controller watching this pod because we created it directly, not through a Deployment. This is why you almost never create bare pods — there's nothing to bring them back if they die.

---

## Checkpoint ✅

Before moving on, verify:

- [ ] `kubectl get nodes` shows your kind cluster node as `Ready`
- [ ] You can list pods in `kube-system`
- [ ] You connected to the shared cluster and saw the Week 1 pods
- [ ] You understand which context (local vs shared) you're currently using
- [ ] You're back on the `kind-lab` context for the next lab

---

## Next Lab

Continue to [Lab 2: Deploy, Scale, Update, Debug](../lab-02-deploy-and-scale/)
