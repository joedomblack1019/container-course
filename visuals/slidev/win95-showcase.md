---
theme: default
title: Container Course — Win95 Visual System
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 05 · RBAC Authorization"
---
<!-- SLIDE 1 — Cover (Full Desktop Scene) -->

# RBAC Authorization
## Deep Dive

- Who can do **what**, in which **namespace**
- How `can-i` answers yes or no
- How bindings control blast radius

---

<!-- ╔══════════════════════════════════════════════════╗ -->
<!-- ║  SLIDE 2 — Standard Window (content)             ║ -->
<!-- ╚══════════════════════════════════════════════════╝ -->
---
layout: win95
windowTitle: "kubectl — RBAC Overview"
windowIcon: "🔐"
statusText: "Week 04 · Lab 05"
---

## RBAC: Core Relationships

| Object | Purpose |
|---|---|
| `ServiceAccount` | Identity for pods to act as |
| `Role` | Set of allowed verbs + resources |
| `RoleBinding` | Glues subject → role in a namespace |
| `ClusterRole` | Same as Role but cluster-wide |
| `ClusterRoleBinding` | Binds cluster-wide |

```yaml
# Check what you can do
kubectl auth can-i list pods \
  --as=system:serviceaccount:rbac-lab:trainee \
  -n rbac-lab
```

---

<!-- ╔══════════════════════════════════════════════════╗ -->
<!-- ║  SLIDE 3 — Task Manager (Pods as Processes)      ║ -->
<!-- ╚══════════════════════════════════════════════════╝ -->
---
layout: win95
windowTitle: "Kubernetes Task Manager"
windowIcon: "🖥"
statusText: "8 processes running"
---

## Pod Status · Task Manager View

<Win95TaskManager
  title="Kubernetes Task Manager — Pods"
  tab="Pods"
  :show-namespace="true"
  status-text="8 pods running | 1 terminating | CPU 14%"
  :processes="[
    { name: 'api-server',       pid: 1001, cpu: 12, memory: '312 MB', status: 'Running',          namespace: 'kube-system' },
    { name: 'etcd',             pid: 1002, cpu: 3,  memory: '128 MB', status: 'Running',          namespace: 'kube-system' },
    { name: 'trainee-pod',      pid: 2001, cpu: 1,  memory: '48 MB',  status: 'Running',          namespace: 'rbac-lab' },
    { name: 'bad-actor-pod',    pid: 2002, cpu: 0,  memory: '12 MB',  status: 'CrashLoopBackOff', namespace: 'rbac-lab' },
    { name: 'metrics-server',   pid: 1010, cpu: 4,  memory: '96 MB',  status: 'Running',          namespace: 'kube-system' },
    { name: 'coredns-6b4f8',    pid: 1020, cpu: 1,  memory: '44 MB',  status: 'Running',          namespace: 'kube-system' },
    { name: 'vault-injector',   pid: 3001, cpu: 2,  memory: '88 MB',  status: 'Running',          namespace: 'vault' },
    { name: 'old-deploy-xyz',   pid: 2010, cpu: 0,  memory: '0 MB',   status: 'Terminating',      namespace: 'default' },
  ]"
  selected-pid="2002"
/>

---

<!-- ╔══════════════════════════════════════════════════╗ -->
<!-- ║  SLIDE 4 — Terminal (kubectl commands)           ║ -->
<!-- ╚══════════════════════════════════════════════════╝ -->
---
layout: win95-terminal
termTitle: "Command Prompt — kubectl auth can-i"
---

<Win95Terminal
  title="Command Prompt — kubectl"
  color="green"
  :crt="true"
  height="100%"
  :lines="[
    { type: 'comment', text: '# Who am I in this cluster?' },
    { type: 'input',  text: 'kubectl config current-context' },
    { type: 'output', text: 'kind-rbac-lab' },
    { type: 'input',  text: 'kubectl auth can-i list pods --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab' },
    { type: 'success', text: 'yes' },
    { type: 'input',  text: 'kubectl auth can-i delete pods --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab' },
    { type: 'error',  text: 'no' },
    { type: 'comment', text: '# Inspect the binding' },
    { type: 'input',  text: 'kubectl describe rolebinding trainee-pod-reader -n rbac-lab' },
    { type: 'output', text: 'Name:         trainee-pod-reader' },
    { type: 'output', text: 'Namespace:    rbac-lab' },
    { type: 'output', text: 'Role:' },
    { type: 'output', text: '  Kind:  Role' },
    { type: 'output', text: '  Name:  pod-reader' },
    { type: 'output', text: 'Subjects:' },
    { type: 'output', text: '  Kind            Name     Namespace' },
    { type: 'output', text: '  ServiceAccount   trainee  rbac-lab' },
  ]"
/>

---

<!-- ╔══════════════════════════════════════════════════╗ -->
<!-- ║  SLIDE 5 — Dialog (PSA Denial)                   ║ -->
<!-- ╚══════════════════════════════════════════════════╝ -->
---
layout: win95
windowTitle: "Pod Security Admission — Access Denied"
windowIcon: "🔒"
statusText: "Pod rejected by admission controller"
---

## Pod Security Admission — Denial Dialog

<div style="display:flex; gap:20px; align-items:flex-start; margin-top:12px;">

<Win95Dialog
  type="error"
  title="Kubernetes Admission Controller"
  message='pods "privileged-pod" is forbidden: violates PodSecurity "restricted:latest"'
  detail='spec.containers[0].securityContext.allowPrivilegeEscalation: Forbidden
spec.containers[0].securityContext.capabilities.drop: Required value
spec.containers[0].securityContext.runAsNonRoot: Required value'
  :buttons="['Details >>','OK']"
  :active-button="1"
/>

<div style="flex:1">

### What failed?

- `allowPrivilegeEscalation` not set to `false`
- `capabilities.drop` missing `ALL`
- `runAsNonRoot` not set to `true`

### Fix:
```yaml
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
```
</div>
</div>

---

<!-- ╔══════════════════════════════════════════════════╗ -->
<!-- ║  SLIDE 6 — Progress Bars (Rolling Deploy)        ║ -->
<!-- ╚══════════════════════════════════════════════════╝ -->
---
layout: win95
windowTitle: "kubectl rollout status — Deploying v2"
windowIcon: "📦"
statusText: "Rolling update in progress..."
---

## Rolling Deployment · Progress

<Win95Window title="Deployment Progress — nginx v1 → v2" icon="📦" style="margin-bottom:16px;">
  <div style="padding:12px; display:flex; flex-direction:column; gap:14px;">
    <Win95ProgressBar :value="100" label="Pods Terminated (v1)"   sublabel="3/3 old pods removed"         color="#808080" />
    <Win95ProgressBar :value="100" label="Pods Created (v2)"      sublabel="3/3 new pods scheduled"       color="#000080" />
    <Win95ProgressBar :value="66"  label="Pods Ready (v2)"        sublabel="2/3 pods passing readiness"   color="#006400" :animated="true" />
    <Win95ProgressBar :value="0"   label="Traffic Shifted"        sublabel="Waiting for all pods ready"   color="#000080" />
  </div>
</Win95Window>

```bash
kubectl rollout status deployment/nginx -n default
# Waiting for deployment "nginx" rollout to finish:
# 2 out of 3 new replicas have been updated...
```

---

<!-- ╔══════════════════════════════════════════════════╗ -->
<!-- ║  SLIDE 7 — RBAC Decision Flow (upgraded)         ║ -->
<!-- ╚══════════════════════════════════════════════════╝ -->
---
layout: win95
windowTitle: "RBAC Decision Engine — Step 3: Rule Evaluation"
windowIcon: "🔐"
statusText: "Evaluating: list pods in rbac-lab"
---

## RBAC Decision Engine

<RbacDecisionFlow :active-step="3" />

<div style="margin-top:16px; display:flex; gap:8px;">
<Win95Dialog
  type="info"
  title="Authorization Check"
  message="Verb: list  |  Resource: pods  |  Namespace: rbac-lab"
  detail="Role pod-reader: verbs=[get,list,watch] resources=[pods] → MATCH"
  :buttons="['Allow →']"
  :active-button="0"
  style="max-width:360px;"
/>
</div>

---

<!-- ╔══════════════════════════════════════════════════╗ -->
<!-- ║  SLIDE 8 — Chapter break (next week)             ║ -->
<!-- ╚══════════════════════════════════════════════════╝ -->
---
layout: win95-desktop
week: "05"
lab: "Lab 01 · Helm + Vault"
---

# Helm + Vault
## Secret Injection Pipeline

- Helm chart as the deployment unit
- Vault Agent Injector sidecars
- Dynamic secrets — no more hardcoded credentials
