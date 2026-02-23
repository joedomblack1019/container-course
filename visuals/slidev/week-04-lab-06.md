---
theme: default
title: Week 04 Lab 06 - Pod Security Admission Deep Dive
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 06 · Pod Security Admission Deep Dive"
---

# Pod Security Admission Deep Dive
## Lab 06

- Enforce namespace-level Pod Security Standards
- Observe admission rejections for non-compliant specs
- Fix workloads with strict `securityContext` settings
- Compare `enforce`, `audit`, and `warn` behavior modes

---
layout: win95
windowTitle: "PSA Admission Flow"
windowIcon: "🔒"
statusText: "Week 04 · Lab 06 · Namespace labels to decision"
---

## Admission Sequence

<PsaAdmissionFlow :active-step="4" />

---
layout: win95
windowTitle: "Restricted-Compliant SecurityContext"
windowIcon: "🛡"
statusText: "Week 04 · Lab 06 · Required hardening fields"
---

## Key Fix Pattern

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 65534
  seccompProfile:
    type: RuntimeDefault
containers:
- securityContext:
    allowPrivilegeEscalation: false
    readOnlyRootFilesystem: true
    capabilities:
      drop: ["ALL"]
```

---
layout: win95-terminal
termTitle: "Command Prompt — baseline setup and restricted labels"
---

<Win95Terminal
  title="Command Prompt — PSA setup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config use-context kind-lab' },
    { type: 'input', text: 'kubectl get nodes' },
    { type: 'input', text: 'kubectl create namespace psa-demo' },
    { type: 'input', text: 'kubectl label namespace psa-demo pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/audit=restricted pod-security.kubernetes.io/warn=restricted' },
    { type: 'input', text: 'kubectl get namespace psa-demo --show-labels' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — rejection and compliant deploy"
---

<Win95Terminal
  title="Command Prompt — enforce restricted"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cat <<\'EOF\' | kubectl apply -f -' },
    { type: 'input', text: 'kind: Deployment  # bad-nginx with privileged: true and runAsUser: 0' },
    { type: 'input', text: 'EOF' },
    { type: 'error', text: 'Expected: pod creation rejected by admission controller' },
    { type: 'input', text: 'kubectl -n psa-demo describe deployment bad-nginx' },
    { type: 'input', text: 'kubectl -n psa-demo get replicasets' },
    { type: 'input', text: 'cat <<\'EOF\' | kubectl apply -f -' },
    { type: 'input', text: 'kind: Deployment  # good-nginx with non-root + dropped caps + emptyDir mounts' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — mode comparisons"
---

<Win95Terminal
  title="Command Prompt — enforce/audit/warn"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl -n psa-demo get pods' },
    { type: 'input', text: 'kubectl -n psa-demo describe pod -l app=good-nginx' },
    { type: 'input', text: 'kubectl create namespace psa-enforce; kubectl label namespace psa-enforce pod-security.kubernetes.io/enforce=baseline' },
    { type: 'input', text: 'kubectl create namespace psa-audit; kubectl label namespace psa-audit pod-security.kubernetes.io/audit=baseline' },
    { type: 'input', text: 'kubectl create namespace psa-warn; kubectl label namespace psa-warn pod-security.kubernetes.io/warn=baseline' },
    { type: 'input', text: 'cat <<\'EOF\' | kubectl apply -f -' },
    { type: 'input', text: 'kind: Pod  # host-network-pod with hostNetwork: true' },
    { type: 'input', text: 'EOF' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — version pinning, failure triage, cleanup"
---

<Win95Terminal
  title="Command Prompt — production label strategy"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl -n psa-audit get pod host-network-pod -o yaml | grep -A5 -B5 audit' },
    { type: 'input', text: 'kubectl create namespace psa-production' },
    { type: 'input', text: 'kubectl label namespace psa-production pod-security.kubernetes.io/enforce=baseline pod-security.kubernetes.io/enforce-version=v1.31 pod-security.kubernetes.io/audit=restricted pod-security.kubernetes.io/warn=restricted' },
    { type: 'input', text: 'kubectl get namespace psa-production --show-labels' },
    { type: 'input', text: 'kubectl -n psa-demo describe pod debug-violation' },
    { type: 'input', text: 'kubectl delete namespace psa-demo psa-enforce psa-audit psa-warn psa-production' },
    { type: 'success', text: 'PSA lab cleanup complete' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 06 — Key Commands"
windowIcon: "📋"
statusText: "Week 04 · Lab 06 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl config use-context kind-lab` | Switch to local cluster |
| `kubectl create namespace psa-demo` | Create PSA test namespace |
| `kubectl label namespace psa-demo pod-security.kubernetes.io/enforce=restricted ...` | Enable restricted mode |
| `kubectl get namespace psa-demo --show-labels` | Verify PSA labels |
| `cat <<'EOF' | kubectl apply -f -` | Apply test pod/deployment specs |
| `kubectl -n psa-demo describe deployment bad-nginx` | Inspect denied deployment |
| `kubectl -n psa-demo get replicasets` | Check ReplicaSet state |
| `kubectl -n psa-demo get pods` | Verify compliant pod runs |
| `kubectl -n psa-demo describe pod -l app=good-nginx` | Inspect pod security config |
| `kubectl create namespace psa-enforce` | Create enforce-mode namespace |
| `kubectl create namespace psa-audit` | Create audit-mode namespace |
| `kubectl create namespace psa-warn` | Create warn-mode namespace |
| `kubectl label namespace psa-enforce pod-security.kubernetes.io/enforce=baseline` | Set enforce mode |
| `kubectl label namespace psa-audit pod-security.kubernetes.io/audit=baseline` | Set audit mode |
| `kubectl label namespace psa-warn pod-security.kubernetes.io/warn=baseline` | Set warn mode |
| `kubectl -n psa-audit get pod host-network-pod -o yaml | grep -A5 -B5 audit` | Check audit signal |
| `kubectl create namespace psa-production` | Create production example namespace |
| `kubectl label namespace psa-production ... enforce-version=v1.31 ...` | Apply version-pinned policy labels |
| `kubectl get namespace psa-production --show-labels` | Verify production labels |
| `kubectl -n psa-demo describe pod debug-violation` | Diagnose admission violations |
| `kubectl delete namespace psa-demo psa-enforce psa-audit psa-warn psa-production` | Cleanup namespaces |
