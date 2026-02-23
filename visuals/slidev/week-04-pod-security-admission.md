---
theme: default
title: Week 04 Lab 06 - Pod Security Admission Deep Dive
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 06 · Pod Security Admission"
---

# Pod Security Admission
## Deep Dive

- Namespace labels define enforcement level
- Admission denies unsafe specs **early**
- Secure defaults let workloads pass

---
layout: win95
windowTitle: "PSA — Pod Security Standards Levels"
windowIcon: "🔒"
statusText: "Week 04 · Lab 06 · pod-security.kubernetes.io"
---

## PSS Levels at a Glance

| Level | Risk Profile | Typical Outcome |
|---|---|---|
| `privileged` | No restrictions | Most pods admitted |
| `baseline` | Block known risky settings | Some pods denied |
| `restricted` | Strong hardening required | Many defaults denied until fixed |

```yaml
# Label your namespace to enforce a level
kubectl label namespace my-app \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted
```

---
layout: win95
windowTitle: "PSA Admission Flow — Step 1: Label the Namespace"
windowIcon: "🔒"
statusText: "Setting enforcement level on namespace"
---

## Step 1: Label the Namespace

<PsaAdmissionFlow :active-step="1" />

`pod-security.kubernetes.io/enforce=restricted`

---
layout: win95
windowTitle: "PSA Admission Flow — Step 2: Admission Check"
windowIcon: "🔒"
statusText: "Evaluating pod spec against PSS restricted profile"
---

## Step 2: Admission Evaluates Pod Spec

<PsaAdmissionFlow :active-step="2" />

Missing security context fields trigger policy violations.

---
layout: win95
windowTitle: "PSA Admission Flow — Step 3: Denied"
windowIcon: "🔒"
statusText: "403 Forbidden — pod rejected by admission controller"
---

## Step 3: Denied With Evidence

<PsaAdmissionFlow :active-step="3" :compact="true" />

<Win95Dialog
  type="error"
  title="Kubernetes Admission Controller"
  message='pods "my-pod" is forbidden: violates PodSecurity "restricted:latest"'
  detail="spec.containers[0].securityContext.allowPrivilegeEscalation: Forbidden
spec.containers[0].securityContext.capabilities.drop: Required value
spec.containers[0].securityContext.runAsNonRoot: Required value"
  :buttons="['Details >>','OK']"
  :active-button="1"
  style="margin-top:10px;"
/>

---
layout: win95
windowTitle: "PSA Admission Flow — Step 4: Remediate & Re-Apply"
windowIcon: "🔒"
statusText: "Pod admitted after securityContext fix"
---

## Step 4: Remediate and Re-Apply

<PsaAdmissionFlow :active-step="4" />

```yaml
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
  seccompProfile:
    type: RuntimeDefault
```
