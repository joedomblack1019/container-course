---
theme: default
title: Week 04 Lab 05 - RBAC Authorization Deep Dive
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 05 · RBAC Authorization"
---

# RBAC Authorization
## Deep Dive

- Who can do **what**, in which **namespace**
- Why `can-i` answers yes or no
- How bindings control blast radius

---
layout: win95
windowTitle: "RBAC — Core Relationships"
windowIcon: "🔐"
statusText: "Week 04 · Lab 05 · kubectl auth can-i"
---

## Core RBAC Relationships

<RbacRelationshipMap />

---
layout: win95
windowTitle: "RBAC Decision Engine — Step 1: Subject Identity"
windowIcon: "🔐"
statusText: "Identifying subject: system:serviceaccount:rbac-lab:trainee"
---

## Step 1: Subject Identity

<RbacDecisionFlow :active-step="1" />

`kubectl auth can-i list pods --as=system:serviceaccount:rbac-lab:trainee -n rbac-lab`

---
layout: win95
windowTitle: "RBAC Decision Engine — Step 2: Binding Lookup"
windowIcon: "🔐"
statusText: "Scanning RoleBindings in namespace: rbac-lab"
---

## Step 2: Binding Lookup

<RbacDecisionFlow :active-step="2" />

`RoleBinding trainee-pod-reader` connects identity to role rules.

---
layout: win95
windowTitle: "RBAC Decision Engine — Step 3: Rule Evaluation"
windowIcon: "🔐"
statusText: "Evaluating: verb=list resource=pods apiGroup=core"
---

## Step 3: Rule Evaluation

<RbacDecisionFlow :active-step="3" />

The authorizer checks `verb + resource + namespace` against role rules.

---
layout: win95
windowTitle: "RBAC Decision Engine — Step 4: Decision"
windowIcon: "🔐"
statusText: "Authorization complete"
---

## Step 4: Allow or Deny

<RbacDecisionFlow :active-step="4" />

- List pods: `yes`
- Delete pods: `no`
