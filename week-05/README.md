# Week 5: Configuration, Secrets & State

## Overview

**Duration:** 3 hours  
**Format:** Lecture + Hands-on Labs  

Last week you deployed an app and scaled it. But it was self-contained — no database, no cache, no external configuration. Real applications have backing services. They read connection strings from the environment, not from hardcoded values. They store passwords in a vault, not in a YAML file committed to Git.

This week your app gets a Redis backend, and you'll learn the Kubernetes-native way to manage configuration, secrets, and persistent storage. You'll also learn Helm — the package manager that lets you install complex software like Redis and Vault without writing hundreds of lines of YAML by hand.

---

## Learning Outcomes

By the end of this class, you will be able to:

1. Use Helm to install, configure, and manage third-party software on a Kubernetes cluster `CKA: Cluster Architecture, Installation and Configuration`
2. Inject application configuration using ConfigMaps (as environment variables and volume mounts) `CKA: Workloads and Scheduling`
3. Manage sensitive data with Kubernetes Secrets and explain why base64 != encryption `CKA: Workloads and Scheduling`
4. Provision persistent storage using PersistentVolumeClaims so data survives pod restarts `CKA: Storage`
5. Implement a production-grade secret management solution (Vault, Sealed Secrets, or SOPS) `CKA: Cluster Architecture, Installation and Configuration`
6. Create and validate etcd snapshots, then rehearse restore runbooks safely `CKA: Cluster Architecture, Installation and Configuration + Troubleshooting`
7. Compare StorageClass reclaim policy and access mode behavior with live workloads `CKA: Storage`

---

## Pre-Class Setup

You should have your kind cluster from Week 4 still running:

```bash
kubectl config use-context kind-lab
kubectl get nodes
```

If not, recreate it:

```bash
kind create cluster --name lab
```

### Install Helm

**In Codespaces:** Helm is already installed in your devcontainer.

**On your VM:**

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

---

## The Twelve-Factor App (Factors That Matter This Week)

The [Twelve-Factor App](https://12factor.net) is a methodology for building applications that deploy cleanly to cloud platforms. Three factors drive everything we do this week:

**Factor III — Config: Store config in the environment.** Configuration that varies between deploys (database URLs, API keys, feature flags) belongs in environment variables, not in code. The same container image should run in dev, staging, and production with only config changes. Kubernetes implements this with ConfigMaps and Secrets.

**Factor IV — Backing Services: Treat backing services as attached resources.** Your Redis instance is a "backing service" — it should be attachable and detachable without code changes. If Redis moves to a different host, you change a ConfigMap, not your application. If you swap Redis for Memcached, only the connection config changes.

**Factor VI — Processes: Execute the app as stateless processes.** Your app pods should store nothing locally. Session data, visit counters, cached results — all go in a backing service (Redis). If a pod dies, a replacement picks up exactly where it left off because the state lives in Redis, not in the pod.

---

## Class Agenda

| Time | Topic | Type |
|------|-------|------|
| 0:00 - 0:20 | The Twelve-Factor App: Why Config, Backing Services, and State Matter | Lecture |
| 0:20 - 0:35 | Helm: The Kubernetes Package Manager | Lecture + Demo |
| 0:35 - 1:05 | **Lab 1:** Install Redis & Vault with Helm | Hands-on |
| 1:05 - 1:20 | Break | — |
| 1:20 - 1:40 | ConfigMaps, Secrets, and PVCs: The Kubernetes Configuration Model | Lecture |
| 1:40 - 2:15 | **Lab 2:** Wire Your App to Redis | Hands-on |
| 2:15 - 2:50 | **Lab 3:** Choose Your Secret Manager | Hands-on |
| 2:50 - 3:00 | Wrap-up & Homework Introduction | — |

---

## Key Concepts

### Helm: Why It Exists

Installing Redis on Kubernetes from scratch means writing a Deployment, Service, ConfigMap, PVC, ServiceAccount, and possibly a StatefulSet with health checks and resource limits. That's 200+ lines of YAML for software you didn't write and don't want to maintain.

Helm solves this. It's a package manager for Kubernetes — think `apt install redis` but for your cluster.

```
┌──────────────────────────────────────────────┐
│                 Helm Chart                    │
│                                              │
│  Templates (parameterized YAML)              │
│  + Values (your configuration)               │
│  = Rendered Manifests (applied to cluster)   │
│                                              │
│  helm install my-redis bitnami/redis         │
│       ▲           ▲          ▲               │
│       │           │          │               │
│  release name   repo/chart  chart name       │
└──────────────────────────────────────────────┘
```

**Key Helm concepts:**
- **Chart** — A package of Kubernetes templates. Published to registries like Docker images.
- **Release** — An installed instance of a chart. You can install the same chart multiple times with different names and values.
- **Values** — Configuration that customizes the chart. Override defaults with `-f values.yaml` or `--set key=value`.
- **Repository** — Where charts are published. `bitnami`, `hashicorp`, etc.

### ConfigMaps

ConfigMaps hold non-sensitive configuration data as key-value pairs. They can be consumed as environment variables or mounted as files.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  REDIS_HOST: "my-redis-master"
  REDIS_PORT: "6379"
  LOG_LEVEL: "info"
```

**As environment variables:**
```yaml
# In a pod spec
envFrom:
- configMapRef:
    name: app-config
```

**As a mounted file:**
```yaml
volumes:
- name: config
  configMap:
    name: app-config
volumeMounts:
- name: config
  mountPath: /etc/config
```

### Secrets

Secrets hold sensitive data. Structurally identical to ConfigMaps, but:
- Values are base64-encoded (not encrypted — anyone with cluster access can decode them)
- Can be encrypted at rest if the cluster is configured for it
- RBAC can restrict who can read them
- Not printed in `kubectl describe` output by default

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: redis-credentials
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=  # echo -n "password123" | base64
```

**The problem:** This base64 "secret" is sitting in your Git repo. Anyone who clones the repo can decode it. This is why we need a real secret management solution — Vault, Sealed Secrets, or SOPS.

### PersistentVolumeClaims

Pods are ephemeral. When a pod dies, its local filesystem is gone. A PVC requests durable storage that outlives the pod.

```
┌─────────────────────────────────────────────┐
│  Your Pod                                   │
│  ┌───────────────────────────────────────┐  │
│  │ Container                             │  │
│  │ mountPath: /data ─────────────┐       │  │
│  └───────────────────────────────┼───────┘  │
│                                  │          │
│  PVC: redis-data ◄───────────────┘          │
│    ↓                                        │
│  PV: provisioned by StorageClass            │
│    ↓                                        │
│  Actual disk (EBS, local-path, NFS, etc.)   │
└─────────────────────────────────────────────┘

Pod dies → PVC and data survive
New pod mounts same PVC → data is still there
```

### The Secret Management Problem

Three approaches, each with tradeoffs:

| Approach | How It Works | Pros | Cons |
|----------|-------------|------|------|
| **Vault** | Central secret store. Vault Agent sidecar injects secrets into pods at runtime. | Dynamic secrets, rotation, audit log, fine-grained policies | Infrastructure overhead, learning curve |
| **Sealed Secrets** | Encrypt secrets client-side with `kubeseal`. Only the cluster controller can decrypt. Encrypted YAML is safe for Git. | Simple, GitOps-native, no external infrastructure | Cluster-specific keys, no rotation, no audit |
| **SOPS + age** | Encrypt secret values in YAML files. Decrypt at apply time or with a Kustomize plugin. | File-level encryption, multi-key support, works with any Git workflow | Manual key management, no dynamic secrets |

You'll learn all three and choose one for your production deployment.

---

## Labs

### Lab 1: Install Redis & Vault with Helm

📁 See [labs/lab-01-helm-redis-and-vault/](./labs/lab-01-helm-redis-and-vault/)

You'll:
- Add Helm repositories and search for charts
- Install Redis with a custom values file
- Install Vault in dev mode
- Explore what Helm created: releases, rendered manifests, values
- Understand `helm upgrade`, `helm rollback`, `helm uninstall`

### Lab 2: Wire Your App to Redis

📁 See [labs/lab-02-configmaps-and-wiring/](./labs/lab-02-configmaps-and-wiring/)

You'll:
- Get the updated app with Redis support (`/visits` endpoint)
- Create a ConfigMap for Redis connection settings
- Create a Secret for the Redis password
- Add a PVC for Redis data persistence
- Update your Deployment to consume ConfigMaps and Secrets
- Kill pods and verify data survives

### Lab 3: Ship Redis to Production

📁 See [labs/lab-03-ship-redis-to-prod/](./labs/lab-03-ship-redis-to-prod/)

You'll:
- Push your Redis-backed app and manifests through the GitOps repo
- Validate overlays and environment wiring before PR submission
- Verify ArgoCD deployment in the shared cluster

### Lab 4 (CKA Extension): etcd Snapshot + Restore Drill

📁 See [labs/lab-04-etcd-snapshot-restore/](./labs/lab-04-etcd-snapshot-restore/)

You'll:
- Capture etcd snapshots from the control plane with proper cert usage
- Validate snapshot integrity before incident pressure
- Rehearse a safe restore workflow in a non-destructive sandbox
- Map the sequence to `jerry-etcd-snapshot-missing`

### Lab 5 (CKA Extension): StorageClass Reclaim + Access Modes

📁 See [labs/lab-05-storageclass-reclaim-accessmode/](./labs/lab-05-storageclass-reclaim-accessmode/)

You'll:
- Create dynamic PVCs against multiple StorageClasses
- Observe `Delete` vs `Retain` reclaim behavior
- Trigger and triage access-mode scheduling failures
- Map outcomes to planned scenarios `jerry-pvc-pending-storageclass` and `jerry-reclaim-policy-surprise`

---

## Discovery Questions

Answer these in your own words after completing the labs:

1. You create a ConfigMap with `REDIS_HOST: my-redis`. Your pod reads it as an environment variable. You then update the ConfigMap to `REDIS_HOST: new-redis`. Does the running pod see the change? What about a new pod? What if the ConfigMap was mounted as a file instead?

2. A colleague commits a Kubernetes Secret to Git with `password: cGFzc3dvcmQxMjM=`. They say "it's fine, it's encoded." What's wrong with this reasoning? What would you recommend instead?

3. You delete a pod that has a PVC mounted. The pod comes back (thanks to the Deployment controller). Does it get the same data? Why or why not?

4. Your Redis pod restarts and comes back with a different IP address. Your app still connects successfully. How? Trace the request from the app container through the Service to the Redis pod.

5. You used `helm install` with `--set auth.password=secret123`. Where does that value end up? Is it stored anywhere persistent? What happens if someone runs `helm get values my-redis`?

---

## Homework

Complete these exercises in the container-gym before next class:

Use this mapped reinforcement set (all exercises below currently exist in `gymctl`):

| Exercise | Time | Focus |
|----------|------|-------|
| `jerry-missing-configmap` | 20 min | Debug ConfigMap dependencies and recover pod startup |
| `jerry-probe-failures` | 20 min | Tune startup/readiness behavior for slower services |
| `jerry-wrong-namespace` | 20 min | Fix cross-namespace service discovery using FQDNs |
| `jerry-etcd-snapshot-missing` | 25 min | etcd backup workflow and recovery validation |

---

## Resources

### Required Reading
- [ConfigMaps and Secrets](https://kubernetes.io/docs/concepts/configuration/) — Official Kubernetes configuration docs
- [The Twelve-Factor App](https://12factor.net) — Read factors III, IV, and VI

### Reference
- [Helm Documentation](https://helm.sh/docs/)
- [PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Vault on Kubernetes](https://developer.hashicorp.com/vault/docs/platform/k8s)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [SOPS](https://github.com/getsops/sops)

### Deep Dive (Optional)
- [Kubernetes Secrets Are Not Really Secret](https://www.youtube.com/watch?v=VtKkemv8g-g) — Why base64 isn't encryption
- [External Secrets Operator](https://external-secrets.io/) — Another approach worth knowing about

---

## Next Week Preview

In Week 6, we'll focus on **Networking & Security**:
- Ingress controllers and routing: give your app a real hostname
- NetworkPolicies: your app can talk to its Redis, nothing else can
- TLS termination: HTTPS for your student URLs
- Your app already has multiple services — now we lock down the communication paths
