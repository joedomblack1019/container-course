# Week 4: Kubernetes Architecture & Your First Deployment

## Overview

**Duration:** 3 hours  
**Format:** Lecture + Hands-on Labs  

Everything you built in Weeks 1-3 has been leading here. You containerized an application, optimized the image, orchestrated multiple services with Compose. Now the question is: how does this work when you have 50 containers across 10 machines instead of 3 containers on your laptop?

The answer is Kubernetes. And here's the thing—your Week 1 apps? They've been running on a Kubernetes cluster this entire time. Today we pull back the curtain.

---

## Learning Outcomes

By the end of this class, you will be able to:

1. Diagram the Kubernetes control plane and explain the role of each component (API server, etcd, scheduler, controller manager, kubelet) `CKA: Cluster Architecture, Installation and Configuration`
2. Explain the desired state -> actual state reconciliation loop that makes Kubernetes self-healing `CKA: Workloads and Scheduling`
3. Create and manage Pods, Deployments, and Services using `kubectl` `CKA: Workloads and Scheduling + Services and Networking`
4. Perform rolling updates and explain how Kubernetes rolls out changes without downtime `CKA: Workloads and Scheduling`
5. Debug failing pods using `kubectl logs`, `kubectl describe`, `kubectl exec`, and cluster events `CKA: Troubleshooting`
6. Bootstrap a disposable control plane with `kubeadm` and identify key admin artifacts (`/etc/kubernetes/manifests`, kubeconfigs, certs) `CKA: Cluster Architecture, Installation and Configuration`
7. Author and test least-privilege RBAC with Roles, ClusterRoles, and bindings using `kubectl auth can-i` `CKA: Cluster Architecture, Installation and Configuration`

---

## Pre-Class Setup

### Local Cluster with kind

You need a local Kubernetes cluster for experimentation. We use **kind** (Kubernetes IN Docker) because it runs K8s nodes as Docker containers — you already have Docker, so this just works.

**In Codespaces:** kind is already installed in your devcontainer.

**On your VM:**

```bash
# Install kind
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.31.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
```

**Verify:**

```bash
kind version
kubectl version --client
```

### Shared Cluster Access

You'll connect to the shared production cluster using `cloudflared` (a Cloudflare Tunnel proxy) and OIDC authentication via your GitHub account. Both tools are pre-installed in the devcontainer.

See [Lab 1, Part 3](./labs/lab-01-kind-cluster/) for the full setup steps. You'll use two contexts throughout this course: your local kind cluster for experimentation, and the shared cluster to see your production deployments.

---

## The Two-Cluster Model

This is how we work for the rest of the course:

```
┌─────────────────────────────────┐     ┌─────────────────────────────────┐
│     LOCAL CLUSTER (kind)        │     │     SHARED CLUSTER (Talos)      │
│                                 │     │                                 │
│  Your workbench.                │     │  Production.                    │
│  Full write access.             │     │  Read-only kubectl.             │
│  Break things. Learn. Fix them. │     │  Deploys happen via GitOps.     │
│                                 │     │                                 │
│  kubectl apply ✅               │     │  kubectl apply ❌               │
│  kubectl delete ✅              │     │  kubectl get ✅                 │
│  kubectl scale ✅               │     │  kubectl logs ✅                │
│  experiment freely ✅           │     │  ArgoCD dashboard ✅            │
│                                 │     │                                 │
│  "dev"                          │     │  "prod"                         │
└─────────────────────────────────┘     └─────────────────────────────────┘
         ▲                                         ▲
         │                                         │
    You run kubectl                          Git push triggers
    directly here                            ArgoCD sync here
```

This mirrors how real teams work. Developers don't `kubectl apply` to production. They push code, and a pipeline handles deployment. Your local cluster is where you learn the mechanics. The shared cluster is where your work goes live.

---

## Class Agenda

| Time | Topic | Type |
|------|-------|------|
| 0:00 - 0:20 | From Compose to Kubernetes: What Problem Are We Solving? | Lecture |
| 0:20 - 0:40 | Kubernetes Architecture: Control Plane & Data Plane | Lecture |
| 0:40 - 1:10 | **Lab 1:** Create Your kind Cluster & Explore | Hands-on |
| 1:10 - 1:25 | Break | — |
| 1:25 - 1:45 | Pods, Deployments, Services: The Core Objects | Lecture |
| 1:45 - 2:25 | **Lab 2:** Deploy, Scale, Update, Debug | Hands-on |
| 2:25 - 2:50 | **Lab 3:** GitOps Submission — Ship Dev to Production | Hands-on |
| 2:50 - 3:00 | Wrap-up & Homework Introduction | — |

---

## Key Concepts

### Why Not Just Docker Compose in Production?

Docker Compose is great for your laptop. But in production you need answers to questions Compose can't handle:

- **What happens when a container crashes at 3 AM?** Compose won't restart it unless you configure restart policies, and even then it's only on the same machine.
- **What happens when a machine dies?** Compose doesn't know about other machines.
- **How do you update without downtime?** Compose tears down the old container and starts a new one. Users see an error page.
- **How do you scale to handle a traffic spike?** You'd manually edit the compose file and re-run it.

Kubernetes handles all of this automatically. You declare what you want, and it makes it happen.

### The Kubernetes Architecture

```
┌─────────────────────────── Control Plane ───────────────────────────┐
│                                                                      │
│  ┌──────────────┐  ┌──────────┐  ┌─────────────┐  ┌──────────────┐ │
│  │  API Server   │  │   etcd   │  │  Scheduler  │  │  Controller  │ │
│  │              │  │          │  │             │  │  Manager     │ │
│  │ "Front door" │  │ "Memory" │  │ "Placement" │  │ "Enforcer"   │ │
│  └──────┬───────┘  └──────────┘  └─────────────┘  └──────────────┘ │
│         │                                                            │
└─────────┼────────────────────────────────────────────────────────────┘
          │
          │  kubelet reports / receives instructions
          │
┌─────────┼────────────────────────── Worker Nodes ─────────────────────┐
│         ▼                                                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                   │
│  │   Node 1    │  │   Node 2    │  │   Node 3    │                   │
│  │             │  │             │  │             │                   │
│  │ ┌─────────┐ │  │ ┌─────────┐ │  │ ┌─────────┐ │                   │
│  │ │ kubelet │ │  │ │ kubelet │ │  │ │ kubelet │ │                   │
│  │ ├─────────┤ │  │ ├─────────┤ │  │ ├─────────┤ │                   │
│  │ │ Pod Pod │ │  │ │ Pod Pod │ │  │ │   Pod   │ │                   │
│  │ └─────────┘ │  │ └─────────┘ │  │ └─────────┘ │                   │
│  └─────────────┘  └─────────────┘  └─────────────┘                   │
└────────────────────────────────────────────────────────────────────────┘
```

**API Server** — The front door to everything. Every `kubectl` command, every internal component, talks to the API server. It validates requests and writes to etcd.

**etcd** — The cluster's memory. A distributed key-value store that holds all cluster state: what pods should exist, what nodes are available, what configs are set. If etcd is lost, the cluster has amnesia.

**Scheduler** — The placement engine. When a new pod needs to run, the scheduler decides which node has the resources and meets the constraints. It doesn't run the pod — it just assigns it.

**Controller Manager** — The enforcer. Runs control loops that constantly compare desired state (what you asked for) with actual state (what's running). If a pod dies and you said you want 3 replicas, the controller creates a replacement.

**kubelet** — The node agent. Runs on every worker node. Receives instructions from the API server ("run this pod"), manages containers through the container runtime, and reports status back.

### The Reconciliation Loop

This is the most important concept in Kubernetes:

```
You declare:  "I want 3 replicas of my app"
                    │
                    ▼
            ┌───────────────┐
            │  Desired State │  ← Stored in etcd
            │  replicas: 3   │
            └───────┬───────┘
                    │
          Controller compares
                    │
            ┌───────▼───────┐
            │  Actual State  │  ← What's running right now
            │  replicas: 2   │
            └───────┬───────┘
                    │
             Drift detected!
                    │
                    ▼
         Controller creates 1 pod
         to reconcile the difference
```

This loop runs constantly. If a pod crashes, the actual state changes and the controller fixes it. If you update the desired state (change the image tag), the controller rolls out the change. You never tell Kubernetes *how* to do something — you tell it *what you want* and it figures out how to get there.

### Core Objects: Pod → Deployment → Service

**Pod** — The smallest deployable unit. One or more containers that share networking and storage. In practice, most pods run a single container. You rarely create pods directly.

**Deployment** — Manages a set of identical pods. You say "I want 3 pods running my image" and the Deployment's controller (ReplicaSet) makes it happen. Handles rolling updates, rollbacks, and scaling.

**Service** — A stable network endpoint for a set of pods. Pods are ephemeral — they get new IPs when they restart. A Service provides a consistent DNS name and IP that routes traffic to healthy pods using label selectors.

```
                    ┌──────────────────┐
                    │     Service      │
                    │  "my-app-svc"    │
                    │  ClusterIP:      │
                    │  10.96.45.12     │
                    └────────┬─────────┘
                             │
              selector: app=my-app
                             │
            ┌────────────────┼────────────────┐
            │                │                │
      ┌─────▼─────┐   ┌─────▼─────┐   ┌─────▼─────┐
      │   Pod 1   │   │   Pod 2   │   │   Pod 3   │
      │ my-app    │   │ my-app    │   │ my-app    │
      │ 10.244.1.5│   │10.244.2.8 │   │10.244.1.9 │
      └───────────┘   └───────────┘   └───────────┘

      Labels: app=my-app on all three
```

### From Compose to Kubernetes — Concept Mapping

If you're thinking "this feels familiar," it should:

| Docker Compose | Kubernetes | What It Does |
|---------------|------------|-------------|
| `services:` block | Deployment + Service | Defines your application |
| `image:` | Pod spec `.containers[].image` | Which container to run |
| `ports:` | Service `ports:` | How to reach the app |
| `replicas:` (v3) | `spec.replicas:` | How many copies |
| `restart: always` | Built into Deployments | Self-healing |
| `depends_on:` | No equivalent (by design) | Startup ordering |
| `volumes:` | PersistentVolumeClaim | Persistent storage |
| `environment:` | `env:` / ConfigMap / Secret | Configuration |

The biggest shift: Compose is imperative ("run these containers in this order"), Kubernetes is declarative ("here's what I want — you figure it out").

---

## Labs

### Lab 1: Create Your kind Cluster & Explore

📁 See [labs/lab-01-kind-cluster/](./labs/lab-01-kind-cluster/)

You'll:
- Create a local Kubernetes cluster with kind
- Learn essential `kubectl` commands
- Explore the cluster's components
- Connect to the shared cluster and see your Week 1 apps running

### Lab 2: Deploy, Scale, Update, Debug

📁 See [labs/lab-02-deploy-and-scale/](./labs/lab-02-deploy-and-scale/)

You'll:
- Update your app with a new `/info` endpoint that reveals pod metadata
- Write a Deployment manifest and deploy to your local cluster
- Scale replicas and watch load balancing in action
- Perform a rolling update with zero downtime
- Break things on purpose and debug with `kubectl describe`, `logs`, and `exec`

### Lab 3: GitOps Submission — Ship Dev to Production

📁 See [labs/lab-03-gitops-submission/](./labs/lab-03-gitops-submission/)

You'll:
- Push your updated image to GHCR
- Write Kubernetes manifests for your dev namespace
- Submit a pull request to `talos-gitops`
- Watch ArgoCD deploy your app to the shared cluster
- Verify your dev environment is live

### Lab 4 (CKA Extension): kubeadm Bootstrap Foundations

📁 See [labs/lab-04-kubeadm-bootstrap/](./labs/lab-04-kubeadm-bootstrap/)

You'll:
- Run kubeadm preflight checks in a disposable admin VM
- Initialize a single control-plane cluster and configure kubectl access
- Inspect static pod manifests, kubeconfig files, and cert locations
- Practice safe reset and re-bootstrap workflow

### Lab 5 (CKA Extension): RBAC Authorization Deep Dive

📁 See [labs/lab-05-rbac-authz/](./labs/lab-05-rbac-authz/)

You'll:
- Create namespace-scoped and cluster-scoped permissions
- Bind identities with RoleBindings and ClusterRoleBindings
- Diagnose authorization errors with impersonation and `kubectl auth can-i`
- Verify least-privilege guardrails

---

## Generated Visualizations

### Lab 2: Deploy, Scale, Update, Debug Timeline

![Deployment Rollout Timeline](../assets/generated/week-04-deploy-rollout/deployment_rollout_timeline.png)

![Deployment Pod Phase Timeline](../assets/generated/week-04-deploy-rollout/deployment_pod_phase_timeline.png)

---

## Discovery Questions

Answer these in your own words after completing the labs:

1. You deleted a pod with `kubectl delete pod <name>`. It came back. Why? What would you need to delete to make it stay gone?

2. Your Deployment has `replicas: 3` but you only see 2 pods running. Where do you look first? Name three `kubectl` commands that would help you investigate.

3. You update your Deployment image from `:v1` to `:v2`. Kubernetes doesn't delete all pods and recreate them — it does something smarter. What is it, and why?

4. A Service selects pods with the label `app: my-app`. You have 5 pods but only 3 have that label. How many pods receive traffic? What happens to the other 2?

5. What's the difference between a pod's IP address and a Service's ClusterIP? Which one should other applications use to connect, and why?

---

## Homework

Complete these before next class:

| Exercise | Time | Focus |
|----------|------|-------|
| **Add prod namespace** | 20 min | Add a `prod/` directory to your `talos-gitops` student directory, update the root kustomization, and submit a PR — same process as Lab 3, different namespace |

Plus these exercises in the container-gym:

| Exercise | Time | Focus |
|----------|------|-------|
| `jerry-forgot-resources` | 20 min | Pod scheduling failures from missing requests/limits |
| `jerry-broken-service` | 20 min | Service-to-pod routing and selector debugging |
| `jerry-probe-failures` | 20 min | Startup/readiness probe troubleshooting |
| `jerry-rbac-denied` | 20 min | RBAC deny triage with `kubectl auth can-i` |

---

## Resources

### Required Reading
- [Kubernetes Components](https://kubernetes.io/docs/concepts/overview/components/) — Official architecture overview
- [Understanding Kubernetes Objects](https://kubernetes.io/docs/concepts/overview/working-with-objects/) — How desired state works

### Reference
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/) — Essential commands
- [Deployment Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Service Documentation](https://kubernetes.io/docs/concepts/services-networking/service/)

### Deep Dive (Optional)
- [The Kubernetes Book](https://www.amazon.com/Kubernetes-Book-Version-January-2024/dp/1916585000) by Nigel Poulton — Excellent beginner-friendly overview
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) — Build a cluster from scratch to understand every piece

---

## Next Week Preview

In Week 5, we'll focus on **Configuration & State**:
- ConfigMaps and Secrets — externalizing configuration the Kubernetes way
- PersistentVolumes and PersistentVolumeClaims — giving pods durable storage
- Your app gets a Redis backend: connection strings become ConfigMaps, auth becomes a Secret, Redis data needs a PVC
- The Twelve-Factor App methodology and why it matters for containers
