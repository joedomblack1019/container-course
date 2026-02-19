# Lab 5: RBAC Authorization Deep Dive

**Time:** 50 minutes  
**Objective:** Build and troubleshoot namespace and cluster RBAC policies using `kubectl auth can-i` and impersonation.

---

## CKA Objectives Mapped

- Manage role-based access controls (RBAC)
- Use least privilege for users and service accounts
- Troubleshoot authorization denies quickly

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
