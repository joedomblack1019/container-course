![Lab 05 RBAC Authorization Deep Dive](../../../assets/generated/week-04-lab-05/hero.png)
![Lab 05 RBAC roles and bindings workflow](../../../assets/generated/week-04-lab-05/flow.gif)

---

# Lab 5: RBAC Authorization Deep Dive

**Time:** 50 minutes  
**Objective:** Build and troubleshoot namespace and cluster RBAC policies using `kubectl auth can-i` and impersonation.

---

## CKA Objectives Mapped

- Manage role-based access controls (RBAC)
- Use least privilege for users and service accounts
- Troubleshoot authorization denies quickly

---

## Background: How RBAC Works

Kubernetes RBAC starts with identity, but identity works differently than AWS IAM. Kubernetes recognizes `User`, `ServiceAccount`, and `Group`, and only one of those is a first-class Kubernetes object: `ServiceAccount` inside a namespace. `User` identities usually come from client certificates or an external identity provider (OIDC), not from objects stored in the cluster, and `kubectl` normally uses whatever user identity is configured in your kubeconfig context.

When you create a ServiceAccount, Kubernetes automatically projects a short-lived token into any Pod that references it via `spec.serviceAccountName`. That token is mounted at `/var/run/secrets/kubernetes.io/serviceaccount/token` and carries the identity string `system:serviceaccount:<namespace>:<name>`. Every API call the Pod makes includes this token, and the API server resolves it to that identity string before evaluating RBAC rules. When you write a RoleBinding or ClusterRoleBinding with `subjects[].kind: ServiceAccount`, you are attaching permissions to that same identity string — which is why `kubectl auth can-i` uses `--as=system:serviceaccount:rbac-lab:trainee` to simulate it.

Roles and bindings are separate objects on purpose. A Role or ClusterRole defines what actions are allowed on which resources, with rule fields like `apiGroups`, `resources`, and `verbs`, while a RoleBinding or ClusterRoleBinding attaches that permission set to a specific subject through `subjects` and `roleRef`. This separation keeps permissions reusable and auditable because you can attach the same role to many identities without duplicating policy rules.

Scope is the next thing that trips people up. `Role` and `RoleBinding` are namespace-scoped, while `ClusterRole` and `ClusterRoleBinding` are cluster-scoped. A useful pattern is defining a reusable `ClusterRole` such as read-only pods, then using a namespaced `RoleBinding` to grant that access only in one namespace.

Kubernetes also supports **ClusterRole aggregation**, which lets you compose a ClusterRole automatically from other ClusterRoles that match a label selector. A ClusterRole with an `aggregationRule` field watches for ClusterRoles carrying specific labels and merges their rules into itself continuously — you never update the aggregated role directly. The built-in `admin`, `edit`, and `view` ClusterRoles already use this mechanism, which is why installing a Custom Resource Definition with matching labels can transparently extend those roles. For the CKA exam, know that `aggregationRule` exists, that it uses label selectors under `clusterRoleSelectors`, and that changes to source ClusterRoles propagate automatically without any manual reconciliation step.

`kubectl auth can-i` asks the API server to evaluate authorization exactly like a real request, so it is the fastest way to prove whether an action should be allowed. With `--as=...`, you impersonate another identity and test policy behavior without logging in as that principal. This is the same mental model as IAM policy simulation in AWS before you hand permissions to a real workload.

The most common RBAC mistake is crossing namespace boundaries with a RoleBinding. A RoleBinding in namespace `A` can only reference a `Role` that also lives in namespace `A`; pointing at a Role in another namespace does not grant what you expect. You will intentionally hit this in Part 4, so read failures as a scoping bug first, not as a syntax bug. For deeper reference, see the official Kubernetes RBAC docs: https://kubernetes.io/docs/reference/access-authn-authz/rbac/.

---

## Prerequisites

Use your local kind cluster:

```bash
kubectl config use-context kind-lab
kubectl get nodes
```

Starter assets for this lab are in [`starter/`](./starter/):

- `namespace-and-accounts.yaml`
- `role-pod-reader.yaml`
- `rolebinding.yaml`
- `clusterrole-node-reader.yaml`
- `clusterrolebinding.yaml`
- `verify.sh`

---

## Part 1: Create a Sandbox Namespace and Identities

```bash
kubectl create namespace rbac-lab
kubectl -n rbac-lab create serviceaccount trainee
kubectl -n rbac-lab create serviceaccount auditor
```

Validate identities exist:

```bash
kubectl -n rbac-lab get serviceaccounts
```

> **Reference:** [ServiceAccount docs](https://kubernetes.io/docs/concepts/security/service-accounts/) | [RBAC overview](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

---

## Part 2: Namespace-Scoped Read Access

Create a Role that allows read-only pod access:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: rbac-lab
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
EOF
```

Bind `trainee` to the role:

```bash
kubectl -n rbac-lab create rolebinding trainee-pod-reader \
  --role=pod-reader \
  --serviceaccount=rbac-lab:trainee
```

Test with impersonation:

```bash
kubectl auth can-i list pods --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab
kubectl auth can-i delete pods --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab
```

Expected:

- `list pods`: yes
- `delete pods`: no

> **Reference:** [Role and RoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#role-and-clusterrole) | [kubectl auth can-i](https://kubernetes.io/docs/reference/access-authn-authz/authorization/#checking-api-access)

---

## Part 3: Cluster-Scoped Read Access

Create a ClusterRole for node visibility:

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]
EOF
```

Bind `auditor` to the ClusterRole:

```bash
kubectl create clusterrolebinding auditor-node-reader \
  --clusterrole=node-reader \
  --serviceaccount=rbac-lab:auditor
```

Verify:

```bash
kubectl auth can-i list nodes --as=system:serviceaccount:rbac-lab:auditor
kubectl auth can-i list secrets --as=system:serviceaccount:rbac-lab:auditor -n rbac-lab
```

Expected:

- can list nodes: yes
- can list secrets: no

> **Reference:** [ClusterRole and ClusterRoleBinding](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#clusterrole-and-clusterrolebinding) | [Aggregated ClusterRoles](https://kubernetes.io/docs/reference/access-authn-authz/rbac/#aggregated-clusterroles)

---

## Part 4: Break and Fix a Binding

Create a broken RoleBinding on purpose (wrong namespace target):

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: trainee-broken
  namespace: default
subjects:
- kind: ServiceAccount
  name: trainee
  namespace: rbac-lab
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
EOF
```

Run checks and inspect:

```bash
kubectl auth can-i list pods --as=system:serviceaccount:rbac-lab:trainee -n default
kubectl -n default describe rolebinding trainee-broken
```

Fix it by removing the bad binding:

```bash
kubectl -n default delete rolebinding trainee-broken
```

Explain why it failed:

- RoleBindings are namespace-scoped
- `roleRef: Role` must reference a Role in the same namespace as the binding

---

## Part 5: Triage Sequence You Should Memorize

When a user gets `Forbidden`, use this order:

1. Confirm identity

```bash
kubectl auth can-i --list --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab
```

2. Inspect bindings in the target namespace

```bash
kubectl -n rbac-lab get rolebindings
kubectl get clusterrolebindings | grep trainee || true
```

3. Inspect referenced role/clusterrole rules

```bash
kubectl -n rbac-lab describe role pod-reader
kubectl describe clusterrole node-reader
```

---

## Validation Checklist

You are done when:

- `trainee` can list pods in `rbac-lab` but cannot delete them
- `auditor` can list nodes but cannot read secrets
- You can diagnose a broken binding and explain the root cause

---

## Cleanup

```bash
kubectl delete namespace rbac-lab
kubectl delete clusterrole node-reader
kubectl delete clusterrolebinding auditor-node-reader
```

---

## Reinforcement Scenario

- `jerry-rbac-denied`
