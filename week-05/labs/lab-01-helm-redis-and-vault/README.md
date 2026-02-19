# Lab 1: Helm for Vault, Manifests for Redis

**Time:** 45 minutes
**Objective:** Learn Helm by installing Vault, unseal it, use it to manage real secrets, then deploy Redis from scratch with plain manifests

---

## The Two Approaches - Helm vs. Manifest.yaml

Kubernetes manifests can be a real pain in the butt. YAML is finicky, the schemas are complex and ever evolving. Installing and maintaining complex application on Kubernetes is a chore and filled with many pain points. The community surrounding Kubernetes came up with a different approach to manifest creation. That project is called Helm - https://helm.sh. Think of Helm like a package manager for Kubernetes deplyments. Don't want to configure a MySQL service, deployment, pvc, and statefulset from scratch every time? I don't blame you. Helm allows us to install software no matter how complex. It takes a simpler approach to installing, upgrading, and removing applications from within a cluster.

Not everything belongs in a Helm chart, and not everything should be hand-written YAML. This lab teaches you when to use which.

**Helm** is the right tool when you're deploying software you didn't write and don't want to maintain — software with dozens of configuration knobs, RBAC rules, sidecar injectors, and upgrade procedures that the maintainers have already figured out. Vault is a perfect example: it has a server, an agent injector, service accounts, policies, and HA modes. The HashiCorp team publishes a chart that wires all of this up correctly. You provide 10 lines of values, Helm generates 200+ lines of battle-tested manifests.

**Plain manifests** are the right tool when you understand the software and the deployment is simple. Redis in standalone mode is a container, a service, and a volume. Four files. You know exactly what each line does because you wrote it. No template magic, no hidden defaults, no wondering what `helm upgrade` will change under the hood.

```
┌─────────────────────────────────┐     ┌─────────────────────────────────┐
│          Use Helm When          │     │     Use Plain Manifests When    │
│                                 │     │                                 │
│  Complex software you didn't    │     │  Simple services you understand │
│  write (Vault, Prometheus,      │     │  (Redis standalone, your app,   │
│  cert-manager, ArgoCD)          │     │  nginx, postgres single-node)   │
│                                 │     │                                 │
│  Dozens of config options       │     │  A few files, clear structure   │
│  Upgrade procedures matter      │     │  You own every line             │
│  Community maintains templates  │     │  Changes go through Git review  │
│                                 │     │                                 │
│  You're a consumer              │     │  You're the author              │
└─────────────────────────────────┘     └─────────────────────────────────┘
```

By the end of this lab, you'll have Vault (via Helm) and Redis (via manifests) running on your local kind cluster, ready for Lab 2 where your app connects to both.

---

## Part 1: Helm Basics

Helm is a package manager for Kubernetes — think `apt install` but for your cluster. A **chart** is a package of templated Kubernetes manifests. A **release** is an installed instance of a chart. **Values** are your configuration overrides.

### Install Helm

**In Codespaces:** Helm is already installed in your devcontainer.

**On your VM:**

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

### Add Repositories

Charts are published to repositories, like Docker registries for Kubernetes packages:

```bash
# HashiCorp publishes the official Vault chart
helm repo add hashicorp https://helm.releases.hashicorp.com

# Update your local chart index
helm repo update
```

### Search for Charts

```bash
# What does HashiCorp publish?
helm search repo hashicorp

# See available versions of the Vault chart
helm search repo hashicorp/vault --versions | head -10
```

---

## Part 2: What Is Vault and Why Should You Care?

Before we install Vault, you need to understand what problem it solves. This isn't just another tool to learn — it's solving a problem you'll hit on every team you work on.

### The Problem: Secrets Are Everywhere

Think about a typical application. It needs:

- A database password to connect to MySQL
- An API key to talk to a payment processor
- A TLS certificate so users get HTTPS
- An AWS access key so it can upload files to S3

Where do those secrets live? In most companies:

```
┌──────────────────────────────────────────────────────────────────┐
│                    The Secrets Sprawl Problem                    │
│                                                                  │
│  .env files checked into Git          ← anyone can read them    │
│  Environment variables in CI/CD       ← who has access?         │
│  Hardcoded in Dockerfiles             ← baked into the image    │
│  Shared in Slack DMs                  ← "hey can you send me    │
│  Post-it notes on monitors            ←  the prod password?"    │
│  config.yaml files on servers         ← no audit trail          │
│                                                                  │
│  Nobody knows who has access to what.                            │
│  Nobody knows when a secret was last rotated.                    │
│  Nobody knows if a secret has been compromised.                  │
└──────────────────────────────────────────────────────────────────┘
```

This is called **secrets sprawl** and it's the number one cause of credential leaks. GitHub scans every public commit for accidentally pushed secrets — they find [millions per year](https://github.blog/security/secret-scanning/secret-scanning-alerts-are-now-available-and-free-for-all-public-repositories/).

### The Solution: A Centralized Secrets Manager

HashiCorp Vault is a centralized secrets manager. Instead of scattering secrets across files, environments, and Slack channels, everything goes into one place with strict access controls.

```
┌──────────────────────────────────────────────────────────────────┐
│                        With Vault                                │
│                                                                  │
│  ┌────────────┐     ┌─────────────────────────────┐              │
│  │   Your App  │────►│         Vault Server         │             │
│  └────────────┘     │                             │              │
│                     │  secret/myapp/database       │              │
│  ┌────────────┐     │    username = "admin"        │              │
│  │  CI/CD      │────►│    password = "s3cur3..."    │              │
│  └────────────┘     │                             │              │
│                     │  secret/myapp/stripe         │              │
│  ┌────────────┐     │    api_key = "sk_live_..."   │              │
│  │  Admin CLI  │────►│                             │              │
│  └────────────┘     │  Every access is logged.     │              │
│                     │  Every secret is encrypted.  │              │
│                     │  Every policy is enforced.   │              │
│                     └─────────────────────────────┘              │
└──────────────────────────────────────────────────────────────────┘
```

What Vault gives you:

- **Centralized storage** — One place for all secrets, not scattered across files
- **Access policies** — "The web app can read the database password. The intern cannot."
- **Audit logging** — Every secret access is logged. You know who read what and when.
- **Encryption at rest** — Secrets are encrypted on disk. Even if someone steals the storage, they can't read the secrets.
- **Secret versioning** — Accidentally overwrote a password? Roll back to the previous version.
- **Dynamic secrets** — Vault can generate short-lived database credentials on the fly (we won't cover this today, but it's powerful)

Read more: [What is Vault?](https://developer.hashicorp.com/vault/docs/what-is-vault)

### The Seal: Vault's Kill Switch

Here's the concept that makes Vault different from a config file. Vault encrypts everything it stores. The encryption key itself is encrypted by a **root key**. When Vault starts up, it doesn't have access to the root key — it's **sealed**.

A sealed Vault can't read or write any secrets. It's a brick. To unseal it, you need to provide **unseal keys** — fragments of the root key that were split up when Vault was first initialized using a technique called [Shamir's Secret Sharing](https://en.wikipedia.org/wiki/Shamir%27s_secret_sharing).

```
┌────────────────────────────────────────────────────┐
│                  Vault Lifecycle                    │
│                                                    │
│   Fresh install ──► vault operator init            │
│                     (generates unseal keys          │
│                      and root token)                │
│                           │                        │
│                           ▼                        │
│                  SEALED (can't do anything)         │
│                           │                        │
│               vault operator unseal                │
│              (provide unseal key)                   │
│                           │                        │
│                           ▼                        │
│                  UNSEALED (ready to use)            │
│                           │                        │
│               vault login (authenticate)           │
│                           │                        │
│                           ▼                        │
│                  Store and retrieve secrets         │
└────────────────────────────────────────────────────┘
```

In production, the unseal keys are split among multiple team members so no single person can unseal Vault alone. For this lab, we'll simplify to a single key so you can focus on the workflow.

Why does this matter? Because if someone steals the Vault server, they get an encrypted blob. Without the unseal keys, the data is useless. This is fundamentally different from a `.env` file — steal that, and you have everything.

---

## Part 3: Install Vault with Helm

### Look Before You Leap

Before installing anything, see what a chart will actually create:

```bash
# Show the chart's default values — this is its full configuration surface
helm show values hashicorp/vault | head -100
```

That's a lot of options. You don't need most of them. A values file lets you override just what you care about.

### Examine the Values File

The starter directory has a values file for Vault in standalone mode:

```bash
cat starter/vault-values.yaml
```

```yaml
server:
  standalone:
    enabled: true
    config: |
      ui = false

      listener "tcp" {
        address = "[::]:8200"
        tls_disable = 1
      }

      storage "file" {
        path = "/vault/data"
      }

  dataStorage:
    enabled: true
    size: 256Mi

  resources:
    requests:
      memory: "64Mi"
      cpu: "50m"
    limits:
      memory: "256Mi"
      cpu: "200m"

injector:
  enabled: true
  resources:
    requests:
      memory: "64Mi"
      cpu: "50m"
    limits:
      memory: "256Mi"
      cpu: "200m"
```

Notice: **no dev mode**. This Vault instance uses file-backed storage and starts sealed — just like production. You'll initialize and unseal it yourself.

### Preview What Helm Will Create

Before installing, you can see the exact Kubernetes manifests Helm would generate:

```bash
helm template vault hashicorp/vault -f starter/vault-values.yaml | head -200
```

Scroll through that output. You'll see ServiceAccounts, ClusterRoleBindings, ConfigMaps, Services, a StatefulSet for the server, a Deployment for the injector, and more. This is what you'd have to write by hand without Helm.

> **`helm template` vs `helm install --dry-run`:** `helm template` renders locally without talking to your cluster. `helm install --dry-run` renders server-side and validates against your cluster's API. For previewing, `template` is faster. For validation, use `--dry-run`.

### Install It

```bash
helm install vault hashicorp/vault -f starter/vault-values.yaml
```

Breaking this down:
- `helm install` — install a chart
- `vault` — the **release name** (you choose this, it prefixes created resources)
- `hashicorp/vault` — the chart (`repo/chart-name`)
- `-f starter/vault-values.yaml` — override default values with your file

### Explore What Helm Created

```bash
# List all Helm releases
helm list

# See what Kubernetes resources the chart created
kubectl get all -l app.kubernetes.io/instance=vault

# The Vault server pod — notice it shows 0/1 READY
kubectl get pods -l app.kubernetes.io/name=vault

# The Vault Agent Injector (we'll use this in a later week)
kubectl get pods -l app.kubernetes.io/name=vault-agent-injector
```

Count the resources. That's dozens of Kubernetes objects — RBAC, services, health checks, pod disruption budgets — all generated from your values file.

**Look at the Vault pod status.** It should show `0/1 Running` — the container is running but it's **not ready**. This is because Vault is sealed. The readiness probe is failing because a sealed Vault can't serve requests. This is exactly what we expected.

---

## Part 4: Initialize and Unseal Vault

This is the part that most tutorials skip by using dev mode. You're going to do it the real way.

### Check the Status

```bash
kubectl exec vault-0 -- vault status
```

You'll see output like:

```
Key                Value
---                -----
Seal Type          shamir
Initialized        false
Sealed             true
```

Vault is neither initialized nor unsealed. It's a locked box with no lock yet — you need to create the lock (initialize) and then open it (unseal).

### Initialize Vault

In production, you'd split the root key into 5 shares requiring 3 to unseal (`-key-shares=5 -key-threshold=3`). For this lab, we'll use a single key to keep it simple:

```bash
kubectl exec vault-0 -- vault operator init \
  -key-shares=1 \
  -key-threshold=1 \
  -format=json
```

**Save this output.** It contains:
- **Unseal Key** — You need this every time Vault restarts
- **Root Token** — Your admin password for Vault

Copy both values somewhere safe. In production, these would go to separate team members, stored in physically secure locations. Losing the unseal keys means losing access to all your secrets permanently.

> **Production reality check:** At a real company, the init ceremony is a Big Deal. Multiple senior engineers gather (sometimes in person), each receives one unseal key, and they store them separately — one in a hardware security module, one in a safe deposit box, one in a separate password manager. The root token is used once to set up initial policies and then revoked. Nobody has standing root access. What you're doing with one key is the same workflow, simplified.

### Unseal Vault

```bash
kubectl exec vault-0 -- vault operator unseal <YOUR-UNSEAL-KEY>
```

Replace `<YOUR-UNSEAL-KEY>` with the key from the previous step.

Check the status again:

```bash
kubectl exec vault-0 -- vault status
```

Now you should see:

```
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
```

`Sealed: false` — Vault is open for business.

Check the pod again:

```bash
kubectl get pods -l app.kubernetes.io/name=vault
```

It should now show `1/1 READY`. The readiness probe passes because Vault can serve requests. Kubernetes won't send traffic to a sealed Vault — the probe protects your applications from trying to read secrets from a brick.

### Helm Lifecycle Commands

Practice these — you'll use them constantly:

```bash
# What values did you use?
helm get values vault

# ALL values including defaults you didn't override
helm get values vault --all | head -50

# Release history (revisions)
helm history vault

# The actual manifests Helm applied
helm get manifest vault | head -50

# Upgrade: change a value and re-apply
# (e.g., increase memory limit in vault-values.yaml, then:)
# helm upgrade vault hashicorp/vault -f starter/vault-values.yaml

# Rollback to a previous revision
# helm rollback vault 1

# Uninstall (we won't do this — we need Vault running)
# helm uninstall vault
```

---

## Part 5: Use Vault — Store and Manage Real Secrets

You have a running, unsealed Vault. Now use it like you would on the job. This isn't a toy exercise — these are the exact commands you'd run when a teammate asks you to store credentials.

### Log In

First, authenticate with your root token:

```bash
kubectl exec vault-0 -- vault login <YOUR-ROOT-TOKEN>
```

### Enable the KV Secrets Engine

Vault organizes secrets into **secrets engines** — pluggable backends that handle different types of secrets. The KV (key-value) engine is the most common: you put data in, you get data out.

```bash
# Enable the KV version 2 secrets engine at the path "secret/"
kubectl exec vault-0 -- vault secrets enable -path=secret kv-v2
```

> **Why version 2?** KV v2 gives you **secret versioning** — every time you update a secret, Vault keeps the old versions. You can roll back if someone pushes a bad password. KV v1 is simpler but overwrites are permanent.

### Scenario: The DBA Created a New Database

Your team is launching a new microservice. The DBA set up a MySQL database and sent you the credentials over a secure channel. Your job: store them in Vault so the application can retrieve them at runtime.

**Store the database credentials:**

```bash
kubectl exec vault-0 -- vault kv put secret/myapp/database \
  username="myapp_svc" \
  password="r4nD0m-G3n3r4t3d-Pa55w0rd" \
  host="mysql.internal.company.com" \
  port="3306" \
  dbname="myapp_production"
```

Notice the path: `secret/myapp/database`. This is how Vault organizes secrets — by path, like a filesystem. Your team might use:
- `secret/myapp/database` — database credentials
- `secret/myapp/stripe` — payment API key
- `secret/myapp/tls` — TLS certificates
- `secret/other-team/their-stuff` — another team's secrets (they can't read yours)

**Retrieve the full secret:**

```bash
kubectl exec vault-0 -- vault kv get secret/myapp/database
```

**Retrieve a single field** (this is what scripts and applications do):

```bash
kubectl exec vault-0 -- vault kv get -field=password secret/myapp/database
```

**List what's stored under a path:**

```bash
kubectl exec vault-0 -- vault kv list secret/myapp/
```

### Scenario: Password Rotation

Three months later, security policy says it's time to rotate the database password. The DBA generates a new one and sends it to you.

**Update just the password:**

```bash
kubectl exec vault-0 -- vault kv put secret/myapp/database \
  username="myapp_svc" \
  password="n3w-R0t4t3d-P4ssw0rd-2025" \
  host="mysql.internal.company.com" \
  port="3306" \
  dbname="myapp_production"
```

**Check — the old password is still there as a previous version:**

```bash
# Current version
kubectl exec vault-0 -- vault kv get secret/myapp/database

# Previous version (version 1)
kubectl exec vault-0 -- vault kv get -version=1 secret/myapp/database
```

Version 1 still has `r4nD0m-G3n3r4t3d-Pa55w0rd`. Version 2 has `n3w-R0t4t3d-P4ssw0rd-2025`. If the new password breaks something, you can check what the old one was. In production, this versioning has saved many late-night incidents.

**See the version history:**

```bash
kubectl exec vault-0 -- vault kv metadata get secret/myapp/database
```

### Scenario: Store an API Key

Another teammate needs to store a Stripe API key for payment processing.

**Try it yourself.** Store a secret at `secret/myapp/stripe` with a key called `api_key` and any value you want. Then retrieve just the `api_key` field. (Scroll down for the answer if you're stuck.)

<details>
<summary>Solution</summary>

```bash
# Store it
kubectl exec vault-0 -- vault kv put secret/myapp/stripe \
  api_key="sk_live_fake_key_for_lab"

# Retrieve just the key
kubectl exec vault-0 -- vault kv get -field=api_key secret/myapp/stripe
```

</details>

### Clean Up (But Keep Vault Running)

You can delete secrets you no longer need:

```bash
# Soft delete (can be recovered)
kubectl exec vault-0 -- vault kv delete secret/myapp/stripe

# Verify it's gone from the current version
kubectl exec vault-0 -- vault kv get secret/myapp/stripe

# But the metadata still exists — you can undelete it
kubectl exec vault-0 -- vault kv undelete -versions=1 secret/myapp/stripe
kubectl exec vault-0 -- vault kv get secret/myapp/stripe
```

This soft-delete behavior is another reason to use Vault over `.env` files. Accidentally deleted a secret? Recover it. Try doing that with `rm .env`.

Leave `secret/myapp/database` in place — we'll reference it in a later week when we wire Vault into your application.

---

## Part 6: What Is a ConfigMap?

Before we deploy Redis, we need to understand ConfigMaps — one of the most important Kubernetes concepts for real-world applications.

### The Problem: Configuration Baked Into Images

Imagine you build a Docker image for your app with the database host hardcoded to `db.staging.company.com`. Now you need to deploy to production where the database is at `db.prod.company.com`. What do you do?

- Build a separate image for production? That defeats the whole point of containers (same image everywhere).
- Pass it as a command-line argument? Messy and hard to manage.
- Use environment variables? Better, but where do they come from?

### The Solution: Externalized Configuration

A **ConfigMap** is a Kubernetes object that stores configuration data as key-value pairs, separate from your container image. Your image stays the same across environments — only the configuration changes.

```
┌──────────────────────────────────────────────────────────────────┐
│                   Without ConfigMaps                             │
│                                                                  │
│  Image v1 (staging) ──► hardcoded: db.staging.company.com        │
│  Image v1 (prod)    ──► hardcoded: db.prod.company.com           │
│  ✗ Two different images for the same code                        │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│                    With ConfigMaps                                │
│                                                                  │
│  Image v1 (same everywhere) + ConfigMap (staging) = staging app  │
│  Image v1 (same everywhere) + ConfigMap (prod)    = prod app     │
│  ✓ One image, configuration lives in Kubernetes                  │
└──────────────────────────────────────────────────────────────────┘
```

ConfigMaps can be consumed two ways:
1. **As environment variables** — Kubernetes injects them when the pod starts
2. **As files mounted into the container** — Kubernetes creates a volume with the ConfigMap data as files

We'll use the file mount approach for Redis because Redis reads its configuration from a file (`redis.conf`). In Lab 2, we'll use the environment variable approach for your application.

This is part of the [12-Factor App methodology](https://12factor.net/config) (Factor III: Config) — configuration that varies between deploys should be stored in the environment, not in code.

Read more: [ConfigMap documentation](https://kubernetes.io/docs/concepts/configuration/configmap/)

---

## Part 7: Deploy Redis with Plain Manifests

Now the other approach. Redis in standalone mode is simple enough that you should own every line. No chart, no templates — just Kubernetes objects you write yourself.

You'll create four resources:

```
┌──────────────────────────────────────────────────────┐
│                   Your Redis Stack                    │
│                                                       │
│  ┌─────────────┐  ConfigMap: redis-config             │
│  │ redis.conf  │  (custom Redis configuration)        │
│  └──────┬──────┘                                      │
│         │ mounted as file                             │
│  ┌──────▼──────────────────────────────────────────┐  │
│  │  StatefulSet: redis                             │  │
│  │  ┌────────────────────────────┐                 │  │
│  │  │  Pod: redis-0              │                 │  │
│  │  │  image: redis:7-alpine     │                 │  │
│  │  │  port: 6379                │                 │  │
│  │  │  /data ──► PVC (256Mi)     │                 │  │
│  │  └────────────────────────────┘                 │  │
│  └─────────────────────────────────────────────────┘  │
│                                                       │
│  ┌─────────────────┐  Secret: redis-credentials       │
│  │  REDIS_PASSWORD  │  (auth password)                │
│  └─────────────────┘                                  │
│                                                       │
│  ┌─────────────────┐  Service: redis                  │
│  │  ClusterIP       │  (stable endpoint for pods)     │
│  │  port: 6379      │                                 │
│  └─────────────────┘                                  │
└──────────────────────────────────────────────────────┘
```

### Why a StatefulSet Instead of a Deployment?

Deployments are for stateless workloads — your app pods are interchangeable. StatefulSets are for stateful workloads where:

- Pods need **stable identities** (the pod is always `redis-0`, not `redis-7f4b8c9d-xk2j9`)
- Pods need **stable storage** (the same PVC reattaches if the pod restarts)
- Pods may need **ordered startup and shutdown**

Redis stores data on disk. If the pod restarts, it needs to find its data again. A StatefulSet guarantees that `redis-0` always gets the same PVC, even after deletion and recreation.

Read more: [StatefulSet documentation](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)

```bash
# Compare the two
kubectl explain statefulset.spec --recursive | head -30
kubectl explain deployment.spec --recursive | head -30
```

The key difference is `volumeClaimTemplates` — a StatefulSet can automatically create a PVC for each pod.

### Write the Manifests

Create a directory for your Redis manifests and work through each file. Use `kubectl explain` to understand every field — don't just copy and paste.

```bash
mkdir -p redis-manifests
cd redis-manifests
```

#### ConfigMap: Redis Configuration

Now you'll put ConfigMaps into practice. Redis reads its configuration from a file. Instead of baking that file into a custom Docker image, you'll store it in a ConfigMap and mount it into the container. If you ever need to change Redis settings, you update the ConfigMap — not the image.

> **Discovery:** Check the [official Redis configuration docs](https://redis.io/docs/latest/operate/oss_and_stack/management/config/) to understand what these settings do. What does `appendonly yes` mean for data durability? What's the difference between RDB snapshots and AOF persistence?

Create `redis-configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-config
data:
  redis.conf: |
    # Require password authentication
    requirepass redis-lab-password

    # Persistence — append-only file for durability
    appendonly yes
    appendfsync everysec

    # Memory limit appropriate for learning environment
    maxmemory 128mb
    maxmemory-policy allkeys-lru

    # Bind to all interfaces (required in containers)
    bind 0.0.0.0

    # Disable dangerous commands in shared environments
    rename-command FLUSHALL ""
    rename-command FLUSHDB ""
```

```bash
kubectl apply -f redis-configmap.yaml
```

Notice what's happening: the entire `redis.conf` file is stored as a single key (`redis.conf`) in the ConfigMap's `data` section. When we mount this ConfigMap as a volume, Kubernetes creates a file called `redis.conf` inside the container with these contents. The Redis container doesn't know or care that its config came from Kubernetes — it just reads a file at `/etc/redis/redis.conf`.

**Why put the password in the config file?** In this lab, it's intentional duplication — the password appears in both the ConfigMap (for Redis to read at startup) and a Secret (for your app to read as an env var). In production, you'd use Vault or an init container to inject the password at runtime. We'll fix this in a later week. For now, focus on the mechanics.

#### Secret: Redis Password

Your application needs the Redis password as an environment variable. Create `redis-secret.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: redis-credentials
type: Opaque
stringData:
  REDIS_PASSWORD: "redis-lab-password"
```

```bash
kubectl apply -f redis-secret.yaml
```

> **This should bother you.** The password is sitting in plaintext in a YAML file. Anyone who clones your repo reads it. Base64 encoding (what Kubernetes stores internally) is not encryption. You just spent 15 minutes learning Vault — a tool that solves exactly this problem. We're going to commit this sin today and fix it properly in a later week with Vault or Sealed Secrets. Feeling uncomfortable about plaintext secrets in Git is the correct instinct.

#### StatefulSet: The Redis Pod

This is the main resource. Create `redis-statefulset.yaml`:

> **Try scaffolding first.** Before looking at the manifest below, try generating a starting point:
> ```bash
> kubectl create deployment redis --image=redis:7-alpine --dry-run=client -o yaml > redis-skeleton.yaml
> ```
> In newer kubectl versions (for example v1.34), `kubectl create statefulset` is no longer available. Use this Deployment scaffold as a starting point, then convert it to a StatefulSet (`kind`, `spec.serviceName`, `volumeClaimTemplates`, probes, and mounts). Compare it to what's below to see what you need to add.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis
  labels:
    app: redis
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
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "200m"
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

Walk through this:

- **`serviceName: redis`** — Required for StatefulSets. Links to a headless Service for DNS.
- **`command: ["redis-server", "/etc/redis/redis.conf"]`** — Tells Redis to use our ConfigMap-mounted configuration file instead of defaults.
- **`volumeMounts`** — Two mounts: `/data` for persistent storage (from the PVC), `/etc/redis` for the config file (from the ConfigMap). Notice the ConfigMap mount — this is where our externalized configuration meets the running container.
- **`volumeClaimTemplates`** — The StatefulSet creates a PVC named `redis-data-redis-0` automatically. If the pod restarts, it reattaches to the same PVC.
- **`readinessProbe` / `livenessProbe`** — Uses `redis-cli ping` to check if Redis is responsive. The `-a` flag passes the password since we enabled authentication.
- **`image: redis:7-alpine`** — The official Redis image. Alpine variant for smaller size. No Bitnami wrapper, no custom entrypoint — just Redis.
- **`volumes.configMap`** — This is the link between the ConfigMap object and the volume mount. Kubernetes takes the ConfigMap named `redis-config` and projects it as files in the container.

```bash
kubectl apply -f redis-statefulset.yaml
```

Watch it come up:

```bash
kubectl get pods -w
```

Press `Ctrl+C` once `redis-0` shows `1/1 Running`.

> **Notice the pod name.** It's `redis-0`, not `redis-7f4b8c9d-xk2j9`. StatefulSet pods get predictable, sequential names. If you scaled to 3 replicas, you'd get `redis-0`, `redis-1`, `redis-2`. This is what "stable identity" means.

#### Service: Stable Network Endpoint

Your app needs a DNS name to reach Redis. Create `redis-service.yaml`:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: redis
  labels:
    app: redis
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
    name: redis
  clusterIP: None
```

**`clusterIP: None`** makes this a **headless Service**. Instead of a single virtual IP that load-balances, it creates a DNS record that resolves directly to the pod IPs. For a single-replica stateful service, this means `redis.default.svc.cluster.local` resolves to the IP of `redis-0`. StatefulSets require a headless Service for their DNS-based stable identities.

> **Discovery:** Read the [headless Services documentation](https://kubernetes.io/docs/concepts/services-networking/service/#headless-services). How does DNS resolution differ from a normal ClusterIP Service? What DNS record does `redis-0.redis.default.svc.cluster.local` resolve to?

```bash
kubectl apply -f redis-service.yaml
```

---

## Part 8: Verify Redis Is Working

### Check the Resources

```bash
# StatefulSet
kubectl get statefulset redis

# Pod with stable name
kubectl get pods -l app=redis

# PVC created by the volumeClaimTemplate
kubectl get pvc

# Service
kubectl get service redis

# Everything together
kubectl get all -l app=redis
kubectl get pvc -l app=redis
```

### Connect and Test

```bash
# Exec into the Redis pod
kubectl exec -it redis-0 -- redis-cli -a redis-lab-password

# Inside the redis-cli:
ping
# → PONG

set testkey "hello from kubernetes"
get testkey
# → "hello from kubernetes"

incr visitor-count
incr visitor-count
incr visitor-count
get visitor-count
# → "3"

exit
```

### Prove Data Survives a Restart

This is the whole point of PVCs. Delete the Redis pod and verify data persists:

```bash
# Kill the pod
kubectl delete pod redis-0

# Watch the StatefulSet recreate it (same name, same PVC)
kubectl get pods -w
```

Wait for `redis-0` to be `Running` again, then:

```bash
# Check — the data is still there
kubectl exec -it redis-0 -- redis-cli -a redis-lab-password get visitor-count
# → "3"

kubectl exec -it redis-0 -- redis-cli -a redis-lab-password get testkey
# → "hello from kubernetes"
```

The pod died and was recreated. The StatefulSet gave it the same name (`redis-0`) and reattached the same PVC (`redis-data-redis-0`). Redis loaded its AOF file from `/data` on startup and recovered all the data.

This is why StatefulSets exist. A Deployment would create a pod with a random name and a new empty PVC.

### Test DNS Resolution

From another pod, verify that the Redis Service name resolves:

```bash
kubectl run dns-test --rm -it --image=busybox:1.36 -- nslookup redis
```

You should see `redis.default.svc.cluster.local` resolve to the IP of `redis-0`. This is the hostname your app will use in Lab 2 — no hardcoded IPs, just the Service name.

---

## Part 9: Compare What You Built

Take stock of your cluster:

```bash
echo "=== Helm Release ==="
helm list

echo ""
echo "=== Vault (installed by Helm) ==="
kubectl get all -l app.kubernetes.io/instance=vault

echo ""
echo "=== Redis (your manifests) ==="
kubectl get all -l app=redis
kubectl get pvc -l app=redis
kubectl get configmap redis-config
kubectl get secret redis-credentials
```

Two backing services, two approaches:

| | Vault (Helm) | Redis (Manifests) |
|---|---|---|
| **Installed with** | `helm install` | `kubectl apply -f` |
| **Config** | `values.yaml` (30 lines) | 4 YAML files (~80 lines) |
| **Resources created** | ~15 (SA, RBAC, ConfigMap, StatefulSet, Service, Injector Deployment, ...) | 4 (ConfigMap, Secret, StatefulSet, Service) |
| **You understand every line?** | Probably not | Yes |
| **Upgrades** | `helm upgrade` | Edit YAML + `kubectl apply` |
| **Rollback** | `helm rollback` | `git revert` + `kubectl apply` |

Neither approach is "better." They're tools for different jobs. Complex third-party software → Helm. Simple services you own → manifests. Your student app will always be plain manifests. The monitoring stack on the shared cluster? That's Helm all the way.

---

## Part 10: Take Stock of Your Manifests

Your `redis-manifests/` directory should contain:

```
redis-manifests/
├── redis-configmap.yaml
├── redis-secret.yaml
├── redis-statefulset.yaml
└── redis-service.yaml
```

Keep these files — you'll reuse them in Lab 3 when you push Redis to the shared cluster alongside your updated app.

---

## Checkpoint

Before moving on, verify:

- [ ] `helm list` shows the `vault` release
- [ ] Vault pod is `1/1 READY` (you initialized and unsealed it)
- [ ] You stored database credentials in Vault at `secret/myapp/database`
- [ ] You can retrieve a single field: `vault kv get -field=password secret/myapp/database`
- [ ] You updated a secret and can access both the current and previous version
- [ ] `redis-0` pod is running with stable name
- [ ] PVC `redis-data-redis-0` exists and is Bound
- [ ] You can `redis-cli ping` and get `PONG`
- [ ] Data survives pod deletion (you proved this)
- [ ] DNS resolves `redis` to the pod IP
- [ ] You understand when to use Helm vs plain manifests
- [ ] You can explain what a ConfigMap is and why it matters

---

## Discovery Questions

1. Run `helm get manifest vault | grep "kind:" | sort | uniq -c | sort -rn`. How many different resource types did the Vault chart create? Pick two you haven't seen before and look them up with `kubectl explain <resource>`.

2. You wrote `clusterIP: None` on the Redis Service. What would change if you removed that line and let Kubernetes assign a ClusterIP? Would your app still be able to connect using the hostname `redis`? What's the practical difference?

3. The Redis StatefulSet has `volumeClaimTemplates`. What happens to the PVC if you `kubectl delete statefulset redis`? Does the data survive? Try it — delete the StatefulSet, check the PVC, recreate the StatefulSet, and see if Redis still has your data.

4. You deployed Redis with `redis:7-alpine`. Run `kubectl exec redis-0 -- redis-server --version` to see the exact version. How would you pin this to a specific patch version instead of floating on `7-alpine`? Why might you want to?

5. You stored `secret/myapp/database` in Vault and `redis-lab-password` in a Kubernetes Secret. What's the difference in security posture between these two approaches? What would an attacker need to access each one?

6. Vault is currently unsealed. What happens if the Vault pod restarts? Try it: `kubectl delete pod vault-0`, wait for it to come back, and run `vault status`. Can you still read your secrets? What do you need to do?

---

## Next Lab

Continue to [Lab 2: Wire Your App to Redis](../lab-02-configmaps-and-wiring/)
