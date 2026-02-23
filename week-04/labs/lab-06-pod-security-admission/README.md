![Lab 06 Pod Security Admission Deep Dive](../../../assets/generated/week-04-lab-06/hero.png)
![Lab 06 Pod Security Admission enforcement workflow](../../../assets/generated/week-04-lab-06/flow.gif)

---

# Lab 6: Pod Security Admission Deep Dive

**Time:** 45 minutes
**Objective:** Configure Pod Security Standards enforcement at the namespace level and troubleshoot pod admission failures.

---

## CKA Objectives Mapped

- Configure Pod admission and scheduling (limits, node affinity, etc.)
- Understand security contexts and Pod Security Standards
- Troubleshoot application failure (admission controller denials)

---

## Background: How Pod Security Admission Actually Enforces Policy

Pod Security Admission (PSA) runs at API admission time, before a pod is persisted, so it is a preventive control and not a runtime detector. When you submit a pod or a controller that creates pods, PSA evaluates the effective pod spec against a Pod Security Standard profile and either rejects it, warns, or records an audit event depending on namespace labels. That means most failures in this lab happen before scheduling, which is why you see admission errors instead of container crash logs.

The three label families are `enforce`, `audit`, and `warn`, and they are deliberately independent so you can move teams toward stricter policy without instant outages. `enforce` blocks non-compliant pod creation, `warn` allows creation but prints violations back to the client, and `audit` allows creation while attaching policy violations to audit signals for later review. A common production rollout is baseline in enforce and restricted in warn or audit so developers can remediate before enforcement gets tightened.

PSA is namespace-scoped, so the namespace label set is effectively the security boundary for this mechanism. Existing pods are not retroactively killed when you change labels; policy applies when new pods are created or old pods are replaced, which is why rollouts surface issues that old workloads might have hidden. In AWS terms, this is closer to an organization guardrail like an SCP at account boundary than to a per-instance firewall rule: it controls what can be created, not packet flow after creation.

Most restricted-profile failures come from a small set of fields that appear later in this lab: running as root, allowing privilege escalation, using broad Linux capabilities, writable root filesystems, and missing seccomp defaults. The fix pattern is predictable: set pod and container `securityContext` fields to non-root and least privilege, then add explicit writable ephemeral mounts like `emptyDir` for paths the application must write to.

Version pinning matters because Pod Security Standards evolve with Kubernetes releases. If you do not set `*-version` labels, a cluster upgrade can tighten checks and suddenly reject manifests that used to pass. Pinning labels gives you controlled policy behavior during upgrades, then you deliberately move the pin when you are ready to enforce newer rules. For deeper details, see the official Pod Security Admission docs: https://kubernetes.io/docs/concepts/security/pod-security-admission/.

---

## Prerequisites

Use your local kind cluster:

```bash
kubectl config use-context kind-lab
kubectl get nodes
```

Starter assets for this lab are in [`starter/`](./starter/):

- `namespace-restricted.yaml`
- `namespace-baseline.yaml`
- `bad-deployment.yaml`
- `good-deployment.yaml`

---

## Part 1: Understanding Pod Security Admission

Pod Security Admission (PSA) is a built-in admission controller that enforces Pod Security Standards at the namespace level. Unlike the deprecated PodSecurityPolicy, PSA requires no CRDs or webhooks—just namespace labels.

The three security levels are:

- **privileged**: Unrestricted, allows anything
- **baseline**: Blocks known dangerous configurations (hostNetwork, privileged containers)
- **restricted**: Strictest, requires non-root users, read-only root filesystem, drops all capabilities

Create a test namespace to explore:

```bash
kubectl create namespace psa-demo
```

---

## Part 2: Restricted Enforcement - Hard Blocking

Apply restricted enforcement to the namespace:

```bash
kubectl label namespace psa-demo \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

Verify the labels:

```bash
kubectl get namespace psa-demo --show-labels
```

Try to deploy a privileged pod:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bad-nginx
  namespace: psa-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bad-nginx
  template:
    metadata:
      labels:
        app: bad-nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
        securityContext:
          privileged: true
          runAsUser: 0
EOF
```

Expected result: Pod creation is **rejected** by the admission controller.

Check the deployment status:

```bash
kubectl -n psa-demo describe deployment bad-nginx
kubectl -n psa-demo get replicasets
```

You should see admission failure events.

---

## Part 3: Fix the Deployment to Meet Restricted Standards

Create a compliant deployment:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: good-nginx
  namespace: psa-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: good-nginx
  template:
    metadata:
      labels:
        app: good-nginx
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
        fsGroup: 65534
        seccompProfile:
          type: RuntimeDefault
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 8080
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-run
          mountPath: /var/run
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-run
        emptyDir: {}
EOF
```

Verify the pod is Running:

```bash
kubectl -n psa-demo get pods
kubectl -n psa-demo describe pod -l app=good-nginx
```

Key compliance changes:
- `runAsNonRoot: true` and `runAsUser: 65534` (nobody user)
- `allowPrivilegeEscalation: false`
- `readOnlyRootFilesystem: true` with writable tmpfs volumes
- `capabilities.drop: ["ALL"]`
- `seccompProfile.type: RuntimeDefault`

---

## Part 4: Three Enforcement Modes

Create namespaces demonstrating each mode:

**Enforce mode (rejects pods):**
```bash
kubectl create namespace psa-enforce
kubectl label namespace psa-enforce pod-security.kubernetes.io/enforce=baseline
```

**Audit mode (allows but logs):**
```bash
kubectl create namespace psa-audit
kubectl label namespace psa-audit pod-security.kubernetes.io/audit=baseline
```

**Warn mode (allows but warns):**
```bash
kubectl create namespace psa-warn
kubectl label namespace psa-warn pod-security.kubernetes.io/warn=baseline
```

Deploy a baseline-violating pod to each:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: host-network-pod
  namespace: psa-enforce
spec:
  hostNetwork: true
  containers:
  - name: nginx
    image: nginx:1.20
EOF
```

Expected: **Rejected** with admission error.

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: host-network-pod
  namespace: psa-audit
spec:
  hostNetwork: true
  containers:
  - name: nginx
    image: nginx:1.20
EOF
```

Expected: **Accepted** but check for audit annotations:

```bash
kubectl -n psa-audit get pod host-network-pod -o yaml | grep -A5 -B5 audit
```

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: host-network-pod
  namespace: psa-warn
spec:
  hostNetwork: true
  containers:
  - name: nginx
    image: nginx:1.20
EOF
```

Expected: **Accepted** with warning message during `kubectl apply`.

---

## Part 5: Version Pinning for Production Stability

Pin the policy to a specific Kubernetes version:

```bash
kubectl create namespace psa-production
kubectl label namespace psa-production \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/enforce-version=v1.31 \
  pod-security.kubernetes.io/audit=restricted \
  pod-security.kubernetes.io/warn=restricted
```

This pattern ensures:
- **Enforce baseline** for minimum safety
- **Audit restricted** to track violations
- **Warn restricted** to alert developers
- **Version-pinned** for deployment stability

Verify the multi-mode configuration:

```bash
kubectl get namespace psa-production --show-labels
```

---

## Part 6: Troubleshoot a Pod Admission Failure

Deploy a pod that violates multiple restricted policies:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: debug-violation
  namespace: psa-demo
spec:
  containers:
  - name: debug
    image: busybox:1.35
    command: ["sleep", "3600"]
    securityContext:
      runAsUser: 0
      privileged: true
      allowPrivilegeEscalation: true
EOF
```

Diagnose the failure:

```bash
kubectl -n psa-demo describe pod debug-violation
```

The error message should list specific violations. Fix them systematically:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: debug-fixed
  namespace: psa-demo
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 65534
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: debug
    image: busybox:1.35
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
EOF
```

---

## Validation Checklist

You are done when:

- A privileged deployment is **rejected** in a restricted namespace
- A compliant deployment **runs successfully** in a restricted namespace
- You can identify the difference between enforce/audit/warn modes
- You can fix pod admission failures by adjusting securityContext

---

## Cleanup

```bash
kubectl delete namespace psa-demo psa-enforce psa-audit psa-warn psa-production
```

---

## Reinforcement Scenario

- `jerry-psa-violation`
