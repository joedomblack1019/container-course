---
theme: default
title: Week 04 Lab 05 - RBAC Authorization Deep Dive
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 05 · RBAC Authorization Deep Dive"
---

# RBAC Authorization Deep Dive
## Lab 05

- Create namespace and service-account identities for authz tests
- Apply Role/RoleBinding and ClusterRole/ClusterRoleBinding
- Validate permissions with impersonation and `kubectl auth can-i`
- Diagnose and fix namespace-scoping RBAC mistakes

---
layout: win95
windowTitle: "RBAC Relationship Map"
windowIcon: "🔐"
statusText: "Week 04 · Lab 05 · Subject -> Binding -> Rules"
---

## Core Relationships

<RbacRelationshipMap />

---
layout: win95
windowTitle: "Decision Flow"
windowIcon: "🔐"
statusText: "Week 04 · Lab 05 · can-i evaluation"
---

## Authorization Evaluation Steps

<RbacDecisionFlow :active-step="4" />

---
layout: win95-terminal
termTitle: "Command Prompt — setup namespace and identities"
---

<Win95Terminal
  title="Command Prompt — RBAC setup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config use-context kind-lab' },
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'kubectl create namespace rbac-lab' },
    { type: 'input', text: 'kubectl -n rbac-lab create serviceaccount trainee' },
    { type: 'input', text: 'kubectl -n rbac-lab create serviceaccount auditor' },
    { type: 'input', text: 'kubectl -n rbac-lab get serviceaccounts' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — namespace role and impersonation checks"
---

<Win95Terminal
  title="Command Prompt — Role + RoleBinding"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cat <<\'EOF\' | kubectl apply -f -' },
    { type: 'input', text: 'apiVersion: rbac.authorization.k8s.io/v1' },
    { type: 'input', text: 'kind: Role' },
    { type: 'input', text: 'metadata: { name: pod-reader, namespace: rbac-lab }' },
    { type: 'input', text: 'rules: [{ apiGroups: [&quot;&quot;], resources: [&quot;pods&quot;], verbs: [&quot;get&quot;, &quot;list&quot;, &quot;watch&quot;] }]' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl -n rbac-lab create rolebinding trainee-pod-reader --role=pod-reader --serviceaccount=rbac-lab:trainee' },
    { type: 'input', text: 'kubectl auth can-i list pods --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — cluster role and broken binding triage"
---

<Win95Terminal
  title="Command Prompt — ClusterRole + diagnostics"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cat <<\'EOF\' | kubectl apply -f -' },
    { type: 'input', text: 'apiVersion: rbac.authorization.k8s.io/v1' },
    { type: 'input', text: 'kind: ClusterRole' },
    { type: 'input', text: 'metadata: { name: node-reader }' },
    { type: 'input', text: 'rules: [{ apiGroups: [&quot;&quot;], resources: [&quot;nodes&quot;], verbs: [&quot;get&quot;, &quot;list&quot;, &quot;watch&quot;] }]' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl create clusterrolebinding auditor-node-reader --clusterrole=node-reader --serviceaccount=rbac-lab:auditor' },
    { type: 'input', text: 'kubectl auth can-i list nodes --as=system:serviceaccount:rbac-lab:auditor' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — failure analysis and cleanup"
---

<Win95Terminal
  title="Command Prompt — break/fix workflow"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl auth can-i delete pods --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab' },
    { type: 'input', text: 'kubectl auth can-i list secrets --as=system:serviceaccount:rbac-lab:auditor -n rbac-lab' },
    { type: 'input', text: 'kubectl auth can-i list pods --as=system:serviceaccount:rbac-lab:trainee -n default' },
    { type: 'input', text: 'kubectl -n default describe rolebinding trainee-broken' },
    { type: 'input', text: 'kubectl -n default delete rolebinding trainee-broken' },
    { type: 'input', text: 'kubectl -n rbac-lab get rolebindings' },
    { type: 'input', text: 'kubectl get clusterrolebindings | grep trainee || true' },
    { type: 'input', text: 'kubectl delete namespace rbac-lab; kubectl delete clusterrole node-reader; kubectl delete clusterrolebinding auditor-node-reader' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 05 — Key Commands"
windowIcon: "📋"
statusText: "Week 04 · Lab 05 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl config use-context kind-lab` | Switch to local cluster |
| `kubectl create namespace rbac-lab` | Create RBAC sandbox namespace |
| `kubectl -n rbac-lab create serviceaccount trainee` | Create trainee SA |
| `kubectl -n rbac-lab create serviceaccount auditor` | Create auditor SA |
| `kubectl -n rbac-lab get serviceaccounts` | Verify identities |
| `cat <<'EOF' | kubectl apply -f -` | Apply inline Role/ClusterRole YAML |
| `kubectl -n rbac-lab create rolebinding trainee-pod-reader --role=pod-reader --serviceaccount=rbac-lab:trainee` | Bind namespace Role |
| `kubectl auth can-i list pods --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab` | Validate allowed action |
| `kubectl auth can-i delete pods --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab` | Validate denied action |
| `kubectl create clusterrolebinding auditor-node-reader --clusterrole=node-reader --serviceaccount=rbac-lab:auditor` | Bind cluster-level role |
| `kubectl auth can-i list nodes --as=system:serviceaccount:rbac-lab:auditor` | Validate cluster read access |
| `kubectl auth can-i list secrets --as=system:serviceaccount:rbac-lab:auditor -n rbac-lab` | Validate least privilege |
| `kubectl auth can-i --list --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab` | Enumerate allowed actions |
| `kubectl -n rbac-lab get rolebindings` | Inspect namespaced bindings |
| `kubectl get clusterrolebindings | grep trainee || true` | Inspect cluster bindings |
| `kubectl -n rbac-lab describe role pod-reader` | Inspect Role rules |
| `kubectl describe clusterrole node-reader` | Inspect ClusterRole rules |
| `kubectl -n default delete rolebinding trainee-broken` | Remove broken binding |
| `kubectl delete namespace rbac-lab` | Cleanup namespace |
| `kubectl delete clusterrole node-reader` | Cleanup ClusterRole |
| `kubectl delete clusterrolebinding auditor-node-reader` | Cleanup ClusterRoleBinding |
