---
theme: default
title: Week 05 Lab 05 - StorageClass Reclaim Policy and Access Modes
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "05"
lab: "Lab 05 · StorageClass Reclaim Policy and Access Modes"
---

# StorageClass Reclaim Policy and Access Modes
## Lab 05

- Create StorageClasses with `Delete`, `Retain`, and expansion behavior
- Observe PV lifecycle differences after PVC deletion
- Reproduce access-mode mismatch (`RWX` on local-path)
- Test block volume mode and PVC expansion behavior

---
layout: win95
windowTitle: "Storage Object Model"
windowIcon: "💽"
statusText: "Week 05 · Lab 05 · SC -> PV -> PVC -> Pod"
---

## Object Relationship

```text
StorageClass (policy)
   -> dynamic provisioner creates PV
PersistentVolume (actual storage resource)
   <- binds claim
PersistentVolumeClaim (request)
   <- mounted by pod
Pod (consumes volume)
```

---
layout: win95
windowTitle: "Reclaim and Access Modes"
windowIcon: "🧪"
statusText: "Week 05 · Lab 05 · Behavior comparisons"
---

## Key Differences

| Setting | Behavior |
|---|---|
| `reclaimPolicy: Delete` | PV and underlying storage removed with PVC |
| `reclaimPolicy: Retain` | PV remains in released state for manual action |
| `ReadWriteOnce` | One node read/write |
| `ReadWriteMany` | Multi-node read/write (not supported by local-path) |

---
layout: win95-terminal
termTitle: "Command Prompt — setup namespace and storageclasses"
---

<Win95Terminal
  title="Command Prompt — storage baseline"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config use-context kind-lab' },
    { type: 'input', text: 'kubectl get storageclass' },
    { type: 'input', text: 'kubectl create namespace storage-lab' },
    { type: 'input', text: 'cat <<\'EOF\' | kubectl apply -f -' },
    { type: 'input', text: 'kind: StorageClass  # local-delete, local-retain, local-expandable' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl get storageclass local-delete local-retain local-expandable' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — dynamic provisioning tests"
---

<Win95Terminal
  title="Command Prompt — delete vs retain"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cat <<\'EOF\' | kubectl -n storage-lab apply -f -' },
    { type: 'input', text: 'kind: PersistentVolumeClaim + Pod  # pvc-delete + writer-delete' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl -n storage-lab get pvc pvc-delete; kubectl -n storage-lab get pod writer-delete; kubectl get pv | grep pvc-delete || true' },
    { type: 'input', text: 'cat <<\'EOF\' | kubectl -n storage-lab apply -f -' },
    { type: 'input', text: 'kind: PersistentVolumeClaim + Pod  # pvc-retain + writer-retain' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl -n storage-lab get pvc pvc-retain; kubectl get pv | grep pvc-retain || true' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — reclaim policy observation"
---

<Win95Terminal
  title="Command Prompt — reclaim outcomes"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl -n storage-lab delete pod writer-delete writer-retain' },
    { type: 'input', text: 'kubectl -n storage-lab delete pvc pvc-delete pvc-retain' },
    { type: 'input', text: 'kubectl get pv' },
    { type: 'success', text: 'Delete class cleaned up; Retain class left PV released' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — access mode mismatch and block mode"
---

<Win95Terminal
  title="Command Prompt — pending PVC diagnostics"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cat <<\'EOF\' | kubectl -n storage-lab apply -f -' },
    { type: 'input', text: 'kind: PersistentVolumeClaim  # pvc-rwx with ReadWriteMany on local-delete' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl -n storage-lab get pvc pvc-rwx; kubectl -n storage-lab describe pvc pvc-rwx' },
    { type: 'input', text: 'kubectl -n storage-lab get events --sort-by=.metadata.creationTimestamp | tail -20' },
    { type: 'input', text: 'kubectl apply -f starter/pvc-block.yaml' },
    { type: 'input', text: 'kubectl -n storage-lab get pvc pvc-block-mode; kubectl -n storage-lab describe pvc pvc-block-mode' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — expansion and cleanup"
---

<Win95Terminal
  title="Command Prompt — expansion checks"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cat <<\'EOF\' | kubectl -n storage-lab apply -f -' },
    { type: 'input', text: 'kind: PersistentVolumeClaim + Pod  # pvc-expandable + writer-expandable' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl -n storage-lab patch pvc pvc-expandable -p \'{&quot;spec&quot;:{&quot;resources&quot;:{&quot;requests&quot;:{&quot;storage&quot;:&quot;2Gi&quot;}}}}\'' },
    { type: 'input', text: 'kubectl -n storage-lab get pvc pvc-expandable; kubectl -n storage-lab describe pvc pvc-expandable' },
    { type: 'input', text: 'kubectl -n storage-lab apply -f starter/pvc-delete.yaml; kubectl -n storage-lab patch pvc pvc-delete -p \'{&quot;spec&quot;:{&quot;resources&quot;:{&quot;requests&quot;:{&quot;storage&quot;:&quot;2Gi&quot;}}}}\' || true' },
    { type: 'input', text: 'kubectl -n storage-lab delete pvc pvc-rwx pvc-block-mode pvc-filesystem pvc-expandable pvc-delete --ignore-not-found; kubectl -n storage-lab delete pod filesystem-pod writer-expandable --ignore-not-found; kubectl delete namespace storage-lab; kubectl delete storageclass local-delete local-retain local-expandable' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 05 — Key Commands"
windowIcon: "📋"
statusText: "Week 05 · Lab 05 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl config use-context kind-lab` | Use local kind context |
| `kubectl get storageclass` | List current StorageClasses |
| `kubectl create namespace storage-lab` | Create lab namespace |
| `cat <<'EOF' | kubectl apply -f -` | Apply inline StorageClass/PVC/Pod specs |
| `kubectl get storageclass local-delete local-retain local-expandable` | Verify lab StorageClasses |
| `kubectl -n storage-lab get pvc pvc-delete` | Check delete-policy claim |
| `kubectl -n storage-lab get pvc pvc-retain` | Check retain-policy claim |
| `kubectl get pv` | Observe PV lifecycle state |
| `kubectl -n storage-lab delete pvc pvc-delete pvc-retain` | Trigger reclaim behavior |
| `kubectl -n storage-lab get pvc pvc-rwx` | Check RWX claim status |
| `kubectl -n storage-lab describe pvc pvc-rwx` | Diagnose RWX pending reason |
| `kubectl -n storage-lab get events --sort-by=.metadata.creationTimestamp | tail -20` | Inspect recent storage events |
| `kubectl apply -f starter/pvc-block.yaml` | Create block-mode PVC |
| `kubectl -n storage-lab describe pvc pvc-block-mode` | Inspect block-mode capability result |
| `kubectl -n storage-lab patch pvc pvc-expandable -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}'` | Expand PVC size |
| `kubectl -n storage-lab patch pvc pvc-delete -p '{"spec":{"resources":{"requests":{"storage":"2Gi"}}}}' || true` | Show expansion failure on non-expandable class |
| `kubectl -n storage-lab delete pvc ... --ignore-not-found` | Cleanup PVCs |
| `kubectl -n storage-lab delete pod ... --ignore-not-found` | Cleanup pods |
| `kubectl delete namespace storage-lab` | Remove lab namespace |
| `kubectl delete storageclass local-delete local-retain local-expandable` | Remove test StorageClasses |
