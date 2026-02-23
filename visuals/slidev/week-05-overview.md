---
theme: default
title: Week 05 - Configuration, Secrets and State
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "05"
lab: "Week 05 · Configuration, Secrets & State"
---

# Configuration, Secrets & State
## Week 05

- Install third-party software with Helm
- Wire apps with ConfigMaps, Secrets, and PVC-backed storage
- Compare secret-management and storage lifecycle strategies

---
layout: win95
windowTitle: "Week 05 — Lab Roadmap"
windowIcon: "🗺"
statusText: "Week 05 · Five labs"
---

## Lab Sequence

<Win95TaskManager
  title="Week 05 — Lab Queue"
  tab="Pods"
  status-text="5 labs queued"
  :show-namespace="false"
  :processes="[
    { name: 'lab-01-helm-redis-and-vault',          pid: 1, cpu: 0, memory: '45 min', status: 'Running' },
    { name: 'lab-02-configmaps-and-wiring',          pid: 2, cpu: 0, memory: '35 min', status: 'Pending' },
    { name: 'lab-03-ship-redis-to-prod',             pid: 3, cpu: 0, memory: '30 min', status: 'Pending' },
    { name: 'lab-04-etcd-snapshot-restore',          pid: 4, cpu: 0, memory: '55 min', status: 'Pending' },
    { name: 'lab-05-storageclass-reclaim-accessmode', pid: 5, cpu: 0, memory: '55 min', status: 'Pending' }
  ]"
/>

---
layout: win95
windowTitle: "Week 05 — Twelve-Factor Focus"
windowIcon: "📘"
statusText: "Week 05 · Factors III, IV, VI"
---

## Factors Used This Week

| Factor | Applied through |
|---|---|
| **III: Config** | ConfigMaps + Secrets |
| **IV: Backing services** | Redis as external dependency |
| **VI: Stateless processes** | Pod restart resilience via Redis/PVC |

---
layout: win95-terminal
termTitle: "Command Prompt — week workflow highlights"
---

<Win95Terminal
  title="Command Prompt — week 05"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'helm install vault hashicorp/vault -f starter/vault-values.yaml' },
    { type: 'input', text: 'kubectl apply -f configmap.yaml -f secret.yaml -f deployment.yaml -f service.yaml' },
    { type: 'input', text: 'kubectl kustomize student-infra/students/<YOUR_GITHUB_USERNAME>/' },
    { type: 'input', text: 'kubectl -n kube-system exec &quot;$ETCD_POD&quot; -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /var/lib/etcd/snapshot.db' },
    { type: 'input', text: 'kubectl get storageclass local-delete local-retain local-expandable' },
  ]"
/>

---
layout: win95
windowTitle: "Week 05 — Outcome"
windowIcon: "✅"
statusText: "Week 05 · Ready for networking + security"
---

## End State

<Win95Dialog
  type="info"
  title="Production Pattern"
  message="Application logic stays in images; environment-specific state and credentials stay in cluster-managed resources."
  detail="By the end of Week 05 you can ship an app with Redis backing service, recover control-plane state with etcd snapshots, and reason about storage behavior under failure and deletion workflows."
  :buttons="['OK']"
  :active-button="0"
/>
