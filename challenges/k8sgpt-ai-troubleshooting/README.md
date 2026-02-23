# Challenge: AI-Assisted Troubleshooting with the k8sgpt Operator

**Time:** 60–90 minutes
**Objective:** Deploy the k8sgpt operator into a cluster, configure it with an AI backend, and use it to continuously diagnose six broken workloads that Jerry deployed using an AI chatbot.

**Prerequisites:** Week 05 completed (Deployments, Services, ConfigMaps, Secrets, PVCs, resource requests). Basic familiarity with Helm.

---

## The Situation

Jerry discovered AI.

Specifically, Jerry discovered that he could describe what he wanted in plain English and an AI would generate Kubernetes manifests for him. He spent two days doing exactly this, deployed everything to production, and then left for a "wellness retreat."

None of it works.

Your job is to use the **k8sgpt operator** — an in-cluster AI diagnostic controller — to continuously monitor Jerry's wreckage and surface plain-English diagnoses as Kubernetes custom resources. You fix each issue and watch the operator's results clean themselves up.

The deeper lesson: AI-generated output requires the same critical review as any other untrusted input. And when you need ongoing visibility into cluster health, the right place for that intelligence is *inside* the cluster — not a CLI you remember to run when something breaks.

---

## What is a Kubernetes Operator?

Kubernetes ships with built-in controllers for the resources you already know — Deployments, Services, ReplicaSets. Each controller runs a loop: observe the current state of the cluster, compare it to the desired state declared in the resource spec, and take action to close the gap. That loop is the engine behind everything Kubernetes does automatically.

An **operator** is the same pattern applied to your own domain-specific problems. It's a custom controller paired with one or more Custom Resource Definitions (CRDs). The CRDs give Kubernetes new vocabulary — new resource types you can `kubectl apply` — and the controller gives that vocabulary behavior.

```
┌─────────────────────────────────────────────────────────────────┐
│  The Kubernetes control loop (same pattern, every controller)   │
│                                                                 │
│   Observe        Compare       Act                              │
│  ──────────   ──────────────  ─────────────────────             │
│  Read actual  Desired state   Create / update / delete          │
│  state from   from your CRD   resources to reconcile            │
│  the cluster  spec            the difference                    │
│                                                                 │
│  Runs continuously. Never stops. Called "reconciliation."       │
└─────────────────────────────────────────────────────────────────┘
```

**Why do operators exist?**

Some things Kubernetes can't manage with its built-in primitives. A stateful database isn't just "a Pod with a PVC" — it has initialization procedures, leader election, backup schedules, and upgrade sequences that differ between versions. You *could* encode all that in Helm hooks, init containers, and bash scripts. Operators are the cleaner answer: package the operational knowledge into a controller that understands your specific software.

Common examples:
- **cert-manager** — watches `Certificate` CRDs and handles ACME challenges, renewal, and Secret rotation automatically
- **Prometheus Operator** — you declare a `ServiceMonitor` and the operator updates Prometheus scrape config for you
- **Strimzi** — you declare a `Kafka` CRD and the operator manages brokers, topic replication, and rolling upgrades
- **k8sgpt-operator** — you declare a `K8sGPT` CRD and the operator continuously scans the cluster and writes `Result` resources

The pattern has a name: **Operator Pattern**. It was formalized by CoreOS in 2016 and is now the standard way to package complex operational logic for Kubernetes.

**CRDs: the vocabulary half of an operator**

A CRD registers a new resource type with the Kubernetes API server. Once it's installed, your new type is a first-class citizen — you can `kubectl get`, `kubectl describe`, `kubectl apply`, and `kubectl watch` it, pipe it through RBAC, and use it in GitOps workflows exactly like any built-in resource.

```bash
# After installing k8sgpt-operator, these work like any other kubectl command:
kubectl get k8sgpts -n k8sgpt-operator-system
kubectl get results -n k8sgpt-operator-system
kubectl describe result jerry-ai-storefront -n k8sgpt-operator-system
```

The operator provides the CRD schema; you provide the instances. The controller does the rest.

---

## What is the k8sgpt Operator?

k8sgpt is an AI-powered Kubernetes diagnostic tool that identifies problems and explains them in plain language. You may have seen it as a CLI (`k8sgpt analyze`). The **operator** packages this as a controller: instead of a one-shot command, you deploy it once and it continuously watches the cluster, calling your AI backend on a reconciliation loop and publishing findings as `Result` custom resources.

```
┌──────────────────────────────────────────────────────────────────┐
│  k8sgpt-operator (running in k8sgpt-operator-system)             │
│                                                                  │
│  Watches cluster → calls AI backend → writes Result CRDs         │
│                                                                  │
│  $ kubectl get results -n k8sgpt-operator-system                 │
│  NAME                          AGE                               │
│  jerry-ai-storefront            2m                               │
│  jerry-ai-payment-processor     2m                               │
│  jerry-ai-recommendation-engi   2m                               │
│                                                                  │
│  $ kubectl describe result jerry-ai-storefront \                 │
│      -n k8sgpt-operator-system                                   │
│  ...                                                             │
│  Details:                                                        │
│    The Deployment references PVC 'storefront-data' which         │
│    does not exist. Create the PVC to allow pods to schedule.     │
└──────────────────────────────────────────────────────────────────┘
```

**CLI vs. Operator — why does it matter?**

| | CLI (`k8sgpt analyze`) | Operator |
|---|---|---|
| Runs | On demand, manually | Continuously |
| Results | Terminal output | Kubernetes CRDs |
| Auth config | Local config file | Kubernetes Secret |
| GitOps-able | No | Yes |
| Feeds alerting | Only with scripting | Via CRD watch events |

In a real cluster you'd deploy this once, wire up your AI key as a Secret, and pipe Results into Slack, PagerDuty, or a GitOps audit trail. For this lab, `kubectl describe result` is your diagnostic window.

---

## Part 1: Setup

### Create the cluster

```bash
kind create cluster --name ai-lab --config starter/kind-config.yaml
```

### Install cert-manager

The k8sgpt operator uses cert-manager for its webhook certificates. Install it and wait for it to be ready before proceeding:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=120s
```

### Install the k8sgpt operator via Helm

```bash
helm repo add k8sgpt-operator https://charts.k8sgpt.ai/
helm repo update

helm install k8sgpt-operator k8sgpt-operator/k8sgpt-operator \
  --namespace k8sgpt-operator-system \
  --create-namespace \
  --wait
```

Verify the operator pod is running:

```bash
kubectl get pods -n k8sgpt-operator-system
```

### Create the API key Secret

The operator reads your AI credentials from a Kubernetes Secret — not a local config file. Your instructor will provide your OpenRouter key.

```bash
kubectl create secret generic k8sgpt-secret \
  --from-literal=openai-api-key=YOUR_OPENROUTER_KEY \
  -n k8sgpt-operator-system
```

> **Why OpenRouter?** Your key has a $5 hard credit limit — it cannot spend more than that no matter what. This is different from a regular OpenAI key where runaway usage can rack up real charges.

### Deploy the K8sGPT custom resource

This CR tells the operator which AI backend to use and which resource types to analyze:

```bash
kubectl apply -f starter/k8sgpt-cr.yaml
```

Verify it was accepted and the operator has picked it up:

```bash
kubectl get k8sgpts -n k8sgpt-operator-system
```

### Deploy Jerry's broken workloads

```bash
kubectl create namespace jerry-ai
kubectl apply -f starter/broken-workloads.yaml
```

Wait 30 seconds for things to settle, then:

```bash
kubectl get pods -n jerry-ai
```

You should see a mixture of statuses: `Pending`, `CrashLoopBackOff`, `CreateContainerConfigError`, `Running` (but not Ready). Welcome to Jerry's legacy.

---

## Part 2: Reading the Operator's Results

The operator runs a reconciliation loop — it scans the cluster on a regular interval and updates its `Result` resources. Within a minute or two of applying the K8sGPT CR, results will appear:

```bash
kubectl get results -n k8sgpt-operator-system
```

For a detailed AI explanation of a specific result:

```bash
kubectl describe result <result-name> -n k8sgpt-operator-system
```

To read all results at once (look at the `Details` field in each):

```bash
kubectl get results -n k8sgpt-operator-system -o yaml
```

**Before you start fixing anything**, answer these questions in your notes:

1. How many `Result` resources appeared? Does that match the number of broken workloads?
2. Were there any problems the operator *missed* that you can see with `kubectl get pods`?
3. Did any of the AI explanations in the `Details` field surprise you, or were they exactly what you expected?

> **Important:** The operator's explanation is a starting point, not the answer. Treat it like advice from a knowledgeable colleague — useful, but verify before you act.

---

## Part 3: The Scenarios

There are six broken workloads. For each one:

1. **Read** what the operator's `Result` says about it
2. **Verify** the diagnosis using `kubectl describe` or `kubectl get` — don't just trust the AI
3. **Fix** the root cause
4. **Confirm** the workload reaches `Running` / Ready, then watch the `Result` disappear on the next reconciliation cycle

### Scenario 1: `storefront`

**What Jerry asked the AI:** *"Make me a web server with persistent storage"*

The AI generated a Deployment that references a PersistentVolumeClaim. The AI did not generate the PVC itself.

**The operator will show:** A Result explaining the pod references a PVC that doesn't exist.

**Guiding questions:**
- What is the PVC named?
- What access mode makes sense for a web server with 3 replicas? (Hint: think about whether multiple pods can write to the same volume simultaneously)
- What storage size is reasonable for serving static web content?

**Your task:** Create the missing PVC and watch the pods start. Then check if the `Result` clears on the next reconciliation cycle.

<details>
<summary>Hint</summary>

`ReadWriteOnce` means only one node can mount the volume for writing at a time. For 3 replicas that only need to *read* static files, `ReadOnlyMany` might be more appropriate — but kind's default StorageClass only supports `ReadWriteOnce`. For this exercise, use `ReadWriteOnce` and understand the limitation.

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: storefront-data
  namespace: jerry-ai
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF
```

</details>

---

### Scenario 2: `payment-processor`

**What Jerry asked the AI:** *"Make a secure payment service that reads credentials from environment variables"*

The AI correctly used `secretKeyRef` for the environment variables. It did not create the Secret.

**The operator will show:** A Result explaining the pod references a Secret that doesn't exist. It may identify both missing keys.

**Guiding questions:**
- What Secret name does the pod expect?
- How many keys does it need, and what are they named?
- The operator's AI explanation will suggest creating the Secret — but what values should the keys have? How would you determine that in a real incident?

**Your task:** Create the Secret with the right keys.

<details>
<summary>Hint</summary>

```bash
kubectl create secret generic payment-secrets \
  --from-literal=db-password=supersecret-dev-password \
  --from-literal=stripe-api-key=sk_test_placeholder \
  -n jerry-ai
```

In a real environment, these values would come from a secrets manager (Vault, AWS Secrets Manager, etc.) — not from a kubectl command. But for this lab, the values don't matter, only the key names do.

</details>

---

### Scenario 3: `recommendation-engine`

**What Jerry asked the AI:** *"Scale my ML model to handle production traffic"*

The AI gave Jerry "production-grade" resource specifications. The AI was not aware of how much RAM kind worker nodes actually have.

**The operator will show:** A Result explaining the pod can't be scheduled because no node has enough resources.

**Guiding questions:**
- What resources is the pod requesting?
- Run `kubectl describe node` on one of your worker nodes. How much allocatable memory does it actually have?
- What's a reasonable request for a Flask app that isn't actually doing ML inference?
- The operator will suggest reducing the resources — but it can't tell you the *right* value. How do you determine that?

**Your task:** Edit the Deployment to request realistic resources.

<details>
<summary>Hint</summary>

```bash
kubectl edit deployment recommendation-engine -n jerry-ai
```

Change:
```yaml
resources:
  requests:
    memory: 32Gi
    cpu: 16
  limits:
    memory: 32Gi
    cpu: 16
```

To something the cluster can actually schedule:
```yaml
resources:
  requests:
    memory: 256Mi
    cpu: 250m
  limits:
    memory: 512Mi
    cpu: 500m
```

</details>

---

### Scenario 4: `notification-service`

**What Jerry asked the AI:** *"Mount a config file into my container"*

The AI generated a ConfigMap and a Deployment with a volume mount. The AI was inconsistent about the key name — the ConfigMap has the data under one key, the mount expects a different key.

**The operator will show:** A Result for `CreateContainerConfigError` — the pod can't start because the volume mount can't be satisfied. (The operator may or may not pinpoint the key name mismatch specifically — this is a good test of its limits.)

**Guiding questions:**
- Run `kubectl describe pod <pod-name> -n jerry-ai`. What does the error say?
- Run `kubectl get configmap notifier-config -n jerry-ai -o yaml`. What key does the data have?
- What key does the volume mount's `items` section reference?
- The operator may suggest the ConfigMap is missing or the mount is wrong. Which diagnosis is more accurate?

**Your task:** Fix the mismatch. You can either rename the key in the ConfigMap, or update the `items` in the volume definition.

<details>
<summary>Hint</summary>

The ConfigMap has the data under key `settings.yaml`. The volumeMount's `items` section looks for `config.yaml`. These need to match.

The simpler fix — patch the ConfigMap to rename the key:

```bash
kubectl create configmap notifier-config \
  --from-literal=config.yaml="smtp_host: mail.example.com
smtp_port: 587
from_address: jerry@example.com" \
  -n jerry-ai \
  --dry-run=client -o yaml | kubectl apply -f -
```

Or edit the Deployment's `items` to reference `settings.yaml` instead.

</details>

---

### Scenario 5: `analytics-api`

**What Jerry asked the AI:** *"Expose my analytics service internally on port 80"*

The pods are `Running`. The Service exists. Traffic still won't reach the pods.

**The operator will show:** A Result for the Service — no Endpoints, or the targetPort doesn't match the container port.

**Guiding questions:**
- What port is the container actually listening on? (Check the Deployment)
- What targetPort does the Service specify?
- Run `kubectl get endpoints analytics-api -n jerry-ai`. What does it show?
- This is subtler than a crashed pod — the operator catches it because it checks Endpoint health, not just pod status. What `kubectl` commands would you have needed to find this manually?

**Your task:** Fix the Service targetPort.

<details>
<summary>Hint</summary>

```bash
kubectl patch service analytics-api -n jerry-ai \
  -p '{"spec":{"ports":[{"name":"http","port":80,"targetPort":9090}]}}'
```

After patching:
```bash
kubectl get endpoints analytics-api -n jerry-ai
```

You should see endpoints listed now.

</details>

---

### Scenario 6: `cache-layer`

**What Jerry asked the AI:** *"Add Redis with a health check"*

The Redis container starts successfully. But the pod never becomes `Ready`. It sits in `Running` with `0/1` in the READY column forever.

**The operator will show:** A Result for a failing readinessProbe. It may identify that the probe is connecting to an external host rather than localhost.

**Guiding questions:**
- Run `kubectl describe pod <cache-layer-pod> -n jerry-ai`. What do the probe failure events say?
- What host is `redis-cli` being asked to connect to?
- What host *should* it connect to for a self-health-check?
- Why would a pod be `Running` but not `Ready`? What's the difference, and why does it matter for traffic routing?

**Your task:** Fix the readinessProbe to check localhost.

<details>
<summary>Hint</summary>

```bash
kubectl edit deployment cache-layer -n jerry-ai
```

Find the readinessProbe and change:
```yaml
readinessProbe:
  exec:
    command:
      - redis-cli
      - -h
      - "postgres.jerry-ai.svc.cluster.local"
      - ping
```

To:
```yaml
readinessProbe:
  exec:
    command:
      - redis-cli
      - -h
      - "localhost"
      - ping
```

</details>

---

## Part 4: The Operator as a Cluster Citizen

Now that you've fixed everything, explore what makes the operator model different from a one-shot CLI.

### Watch Results disappear

After fixing each workload, watch how the operator cleans up its `Result` on the next reconciliation cycle:

```bash
kubectl get results -n k8sgpt-operator-system --watch
```

When a problem is fixed, the operator deletes the corresponding `Result`. This makes Results usable as signals: their *presence* means something is broken, their *absence* means it's resolved.

### Results as Kubernetes objects

Because Results are CRDs, you can treat them like any other resource:

```bash
# Count open problems
kubectl get results -n k8sgpt-operator-system --no-headers | wc -l

# Get results as JSON — pipe to jq, log to a SIEM, etc.
kubectl get results -n k8sgpt-operator-system -o json | jq '.items[].spec.details'

# Watch for new Results appearing in real time
kubectl get results -n k8sgpt-operator-system --watch
```

In production you'd pair this with a tool like `kube-state-metrics` or a controller that forwards Result events to Slack or PagerDuty.

### Inspect the operator's configuration

Look at what you deployed:

```bash
kubectl describe k8sgpt k8sgpt -n k8sgpt-operator-system
```

The `spec.filters` field controls which resource types get analyzed. Try adding `Ingress` or `Node` to the list in `starter/k8sgpt-cr.yaml` and re-applying it. The operator will pick up the change without restarting.

### The reconciliation loop

The operator doesn't watch events — it re-scans the cluster on a timer. This means:

- There's a short delay between a problem appearing and a Result showing up
- There's a short delay between fixing a problem and its Result disappearing
- If the AI backend is unavailable, the operator keeps the last-known Results until it can reach it again

```bash
# Check operator logs to see reconciliation activity
kubectl logs -n k8sgpt-operator-system deployment/k8sgpt-operator-controller-manager -f
```

---

## Part 5: Critical Evaluation

Run a final check after fixing everything:

```bash
kubectl get results -n k8sgpt-operator-system
```

**If it returns nothing:** Good. But that doesn't mean the cluster is production-ready.

**Discussion questions to work through:**

1. Were there any scenarios where the operator's explanation was misleading or incomplete? In Scenario 4 (the ConfigMap key mismatch), did it correctly identify the *actual* problem or just a symptom?

2. The operator found the `analytics-api` targetPort mismatch even though the pods were Running. Think about what it's actually checking under the hood. How would you verify Service→Endpoint→Pod connectivity without the operator?

3. The `recommendation-engine` had resource requests of `32Gi` / `16` CPU. The operator correctly said "can't schedule." But what's the *right* resource value? The operator can't tell you. How do you figure that out for a real workload?

4. In Scenario 6, the pod was `Running` but not `Ready`. The operator flagged this. What would have happened to traffic if this pod was behind a Service when it was Running-but-not-Ready? (Hint: check what Endpoints looks like for that Service.)

5. With the CLI approach, you'd run `k8sgpt analyze` when you noticed something was wrong. With the operator, Results appear automatically. What new failure modes does the operator approach introduce? (Think: what happens when the AI backend is rate-limited or returns garbage?)

6. Imagine you're using an AI tool to *generate* your manifests AND an AI tool to *diagnose* your cluster. What are the risks of this workflow? What human checkpoints would you want in place?

---

## Part 6: Cleanup

```bash
kind delete cluster --name ai-lab
```

---

## Checkpoint

- [ ] cert-manager installed and ready
- [ ] k8sgpt-operator installed via Helm
- [ ] k8sgpt-secret created with your OpenRouter key
- [ ] K8sGPT CR applied and operator is active
- [ ] You read the initial `Result` resources before fixing anything
- [ ] You verified each operator diagnosis with `kubectl describe` before acting on it
- [ ] You fixed `storefront` — missing PVC
- [ ] You fixed `payment-processor` — missing Secret (both keys)
- [ ] You fixed `recommendation-engine` — impossible resource requests
- [ ] You fixed `notification-service` — ConfigMap key name mismatch
- [ ] You fixed `analytics-api` — Service targetPort mismatch
- [ ] You fixed `cache-layer` — readinessProbe pointing at wrong host
- [ ] All six workloads show `1/1 Running`
- [ ] `kubectl get results -n k8sgpt-operator-system` returns nothing
- [ ] You can explain what the operator *cannot* tell you, not just what it can

---

## Discovery Questions

1. The k8sgpt operator writes `Result` CRDs. Browse the [k8sgpt-operator GitHub](https://github.com/k8sgpt-ai/k8sgpt-operator) and look at the `Result` CRD schema. What fields does a Result contain beyond the `details` string? How might you use the `severity` or `error` fields to build a priority queue for on-call engineers?

2. k8sgpt supports local AI backends like Ollama. What are the tradeoffs between using a cloud LLM (OpenRouter/OpenAI) vs. a local model for cluster diagnosis? When would a local model be *required* rather than just preferred? How would you update `starter/k8sgpt-cr.yaml` to point at a local Ollama instance?

3. The operator uses a reconciliation loop rather than event-driven analysis. What's the implication for *time to detection* compared to a tool that watches pod events directly? In a fast-moving incident, does the delay matter?

4. Results are Kubernetes objects — which means you can write a controller that watches them. Design a simple workflow: Results appear → controller reads them → posts to Slack. What Kubernetes concepts would you use to build this? (Hint: informers, reconcilers.)

5. Jerry's workflow was: describe to AI → get manifest → apply manifest. The operator helps *after* problems are in the cluster. What would a pre-deployment gate look like? Look into `datree`, `kubeconform`, and `kube-score`. How do these pre-deployment tools complement the operator's post-deployment analysis?

---

## Resources

- [k8sgpt-operator GitHub](https://github.com/k8sgpt-ai/k8sgpt-operator)
- [k8sgpt-operator Helm Chart](https://charts.k8sgpt.ai/)
- [k8sgpt Documentation](https://docs.k8sgpt.ai/)
- [K8sGPT CRD Reference](https://docs.k8sgpt.ai/reference/operator/operator/)
- [OpenRouter Model Catalog](https://openrouter.ai/models) — try different models and compare explanation quality
- [cert-manager Installation](https://cert-manager.io/docs/installation/)
