![Lab 05 Troubleshooting Playbook Sprint](../../../assets/generated/week-08-lab-05/hero.png)
![Lab 05 cluster component troubleshooting workflow](../../../assets/generated/week-08-lab-05/flow.gif)

---

# Lab 5: Troubleshooting Playbook Sprint

**Time:** 60 minutes
**Objective:** Use the CKA troubleshooting playbook to systematically triage and resolve cluster incidents under time pressure.

---

## CKA Objectives Mapped

- **Troubleshoot cluster and nodes** (30% weight) - Node health, kubelet recovery, resource pressure
- **Troubleshoot cluster components** (30% weight) - Control plane failures, static pod debugging
- **Monitor cluster and application resource usage** (30% weight) - Resource hog identification, metrics-server
- **Manage and evaluate container output streams** (30% weight) - Multi-container log analysis
- **Troubleshoot services and networking** (30% weight) - DNS resolution, service discovery

---

## Background: A Fast Triage Model for Cluster Incidents

When Kubernetes incidents feel chaotic, the fastest path is classifying the symptom before running commands. Start by asking what scope is broken: one pod, one namespace, one node, or cluster-wide behavior. Scope narrows root cause quickly, because a single namespace outage usually points to workload config or policy, while cluster-wide scheduling or DNS failures usually point to control-plane components or shared system services.

Use a control-loop mental model while triaging. The API server is the front door, etcd is persistent state, scheduler places pods, controller manager reconciles desired versus actual, kubelet enforces pod state on nodes, and CoreDNS handles service discovery. If new pods stay Pending cluster-wide, suspect scheduler or capacity before touching app manifests. If pods run but cannot resolve service names, suspect CoreDNS and network path before changing deployments.

Distinguish control-plane failures from data-plane failures. Control-plane issues break creation, scheduling, and reconciliation. Data-plane issues break traffic, DNS, or node execution for already-created workloads. In AWS terms, this is similar to separating a control API outage from an instance-level runtime problem: the first blocks orchestration, the second blocks execution.

For speed under exam pressure, run the same short sequence every time: validate symptom, identify blast radius, inspect events in time order, then check the component most likely tied to that symptom domain. This avoids random command spam and gives you evidence for each decision. The incidents in this lab are designed to reward that sequence, not memorized one-off fixes.

If you need a deeper reference while practicing, use the official Kubernetes troubleshooting guide as a supplement to the class playbook: https://kubernetes.io/docs/tasks/debug/.

---

## Prerequisites

**MANDATORY:** Read and bookmark the [CKA Troubleshooting Playbook](../../../references/troubleshooting-playbook.md) before starting this lab.

Use a local kind cluster only:

```bash
kubectl config use-context kind-lab
kubectl get nodes
```

Deploy baseline workload:

```bash
kubectl apply -f starter/baseline-workload.yaml
kubectl -n sprint-lab rollout status deploy/web --timeout=60s
```

---

## How This Lab Works

This is **playbook-driven incident response training**. You will face 5 incidents. For each one:

1. **You get 12 minutes maximum**
2. **You receive only a symptom description** — no step-by-step instructions
3. **You must identify which playbook runbook applies**
4. **You follow the runbook's triage sequence**
5. **You record your evidence in the scorecard**

**No step-by-step guides are provided.** The troubleshooting playbook IS your guide. This simulates the CKA exam where you must apply systematic thinking under time pressure.

---

## Incident 1: DNS Resolution is Failing Cluster-Wide

**Symptom:** Users report that service-to-service calls are failing with name resolution errors. Pods cannot resolve service names like `web.sprint-lab.svc.cluster.local`.

**Your task:** Open the troubleshooting playbook. Determine which runbook section applies. Follow its triage sequence. Fix the issue.

**Time limit:** 12 minutes

<details>
<summary><strong>Instructor: Inject this fault</strong></summary>

```bash
./instructor/inject-coredns-failure.sh
```

Verify fault:
```bash
kubectl run dns-test --image=busybox:1.36 --restart=Never --rm -it -- nslookup web.sprint-lab.svc.cluster.local
# Should fail with NXDOMAIN
```

</details>

---

## Incident 2: Pods are Stuck Pending After a Maintenance Window

**Symptom:** After Jerry's maintenance window, new pods in the sprint-lab namespace are stuck Pending. The web deployment was running fine before maintenance but new replicas won't schedule.

**Your task:** Use the playbook to identify the scheduling problem. Fix it so workloads can schedule normally.

**Time limit:** 12 minutes

<details>
<summary><strong>Instructor: Inject this fault</strong></summary>

```bash
# Taint worker node and deploy pending app with nodeSelector
NODE="$(kubectl get nodes -o name | grep -v control-plane | head -1 | cut -d/ -f2)"
kubectl taint node "$NODE" sprint=blocked:NoSchedule

# Deploy app that targets the tainted node
kubectl apply -f starter/pending-app.yaml
kubectl -n sprint-lab patch deployment pending-app --type=json -p="[{\"op\":\"replace\",\"path\":\"/spec/template/spec/nodeSelector/kubernetes.io~1hostname\",\"value\":\"$NODE\"}]"
```

Verify fault:
```bash
kubectl -n sprint-lab get pods
# Should see pending-app pods in Pending state
```

</details>

---

## Incident 3: A Control Plane Component is Misbehaving

**Symptom:** New pods across ALL namespaces are stuck Pending, but existing pods continue to run fine. This started suddenly and affects the entire cluster.

**Your task:** This is cluster-wide (not namespace-specific) so it's likely a control plane issue. Use the playbook to identify which component and fix it.

**Time limit:** 12 minutes

<details>
<summary><strong>Instructor: Inject this fault</strong></summary>

```bash
./instructor/inject-scheduler-break.sh
```

Verify fault:
```bash
kubectl run test-schedule --image=registry.k8s.io/pause:3.10 --restart=Never
kubectl get pod test-schedule
# Should remain Pending indefinitely
```

</details>

---

## Incident 4: Resource Pressure Investigation

**Symptom:** The cluster feels slow and a deployment can't get its requested replicas scheduled. Resource constraints appear to be blocking normal workload deployment.

**Your task:** Use the playbook to identify resource hogs and restore normal scheduling capacity.

**Time limit:** 12 minutes

<details>
<summary><strong>Instructor: Inject this fault</strong></summary>

```bash
./instructor/inject-resource-hog.sh
```

Verify fault:
```bash
kubectl -n sprint-lab get pods
# victim-app should have some replicas Pending
kubectl top nodes  # Should work after metrics-server installs
```

</details>

---

## Incident 5 (Bonus, Time Permitting): Multi-Container Pod Log Triage

**Symptom:** A new deployment is stuck with pods showing `Init:CrashLoopBackOff`. The deployment includes multiple containers and you need to identify which specific container is failing.

**Your task:** Use the playbook to debug multi-container pod failures and get the deployment running.

**Time limit:** 12 minutes

This incident maps directly to init-container exam patterns such as `34-jerry-init-container-stuck`.

<details>
<summary><strong>Instructor: Inject this fault</strong></summary>

```bash
./instructor/inject-multi-container-failure.sh
```

Verify fault:
```bash
kubectl -n sprint-lab get pods
# multi-container-app should show Init:CrashLoopBackOff
```

</details>

---

## Scorecard

Record your findings for each incident in [`starter/sprint-scorecard.md`](./starter/sprint-scorecard.md).

**Passing criteria:**
- At least 4 of 5 incidents resolved within time limits
- Each incident includes the correct runbook reference
- Evidence commands and verification steps documented
- No "blind fixes" — every fix must include root cause identification

**Time management tips:**
- If stuck on one incident for >8 minutes, record partial findings and move on
- The playbook runbooks are designed for 5-7 minute resolution when followed systematically
- Practice the triage sequences until they become muscle memory

---

## Cleanup

```bash
kubectl delete namespace sprint-lab
kubectl delete pod test-schedule --ignore-not-found
kubectl delete pod dns-test --ignore-not-found

# Clean up any remaining taints
for node in $(kubectl get nodes -o name | cut -d/ -f2); do
  kubectl taint node "$node" sprint=blocked:NoSchedule- 2>/dev/null || true
done

# Restore CoreDNS if needed
if [ -f /tmp/coredns-backup.yaml ]; then
  kubectl apply -f /tmp/coredns-backup.yaml
  kubectl -n kube-system rollout restart deployment/coredns
  rm -f /tmp/coredns-backup.yaml
fi

# Restore scheduler if needed
NODE=$(kubectl get nodes -o name | grep control-plane | head -1 | cut -d/ -f2)
if docker exec "$NODE" test -f /tmp/kube-scheduler-backup.yaml; then
  docker exec "$NODE" cp /tmp/kube-scheduler-backup.yaml /etc/kubernetes/manifests/kube-scheduler.yaml
fi
```

---

## Reinforcement Practice

After completing this lab, practice these individual scenarios to reinforce specific skills:

- `gymctl start jerry-coredns-loop` — DNS/CoreDNS troubleshooting
- `gymctl start jerry-node-notready-kubelet` — Node health recovery
- `gymctl start jerry-etcd-snapshot-missing` — Control plane backup/restore
- `gymctl start jerry-pod-unschedulable-taint` — Scheduling constraints
- `gymctl start jerry-static-pod-misconfigured` — Static pod debugging
- `gymctl start jerry-container-log-mystery` — Multi-container log analysis
- `gymctl start 34-jerry-init-container-stuck` — Init:CrashLoopBackOff root-cause triage
- `gymctl start jerry-resource-hog-hunt` — Resource monitoring and cleanup
- `gymctl start 37-jerry-scheduler-missing` — Control-plane scheduling outage triage

**Goal:** Build the systematic troubleshooting mindset that the CKA exam requires. Each playbook runbook should become an automatic response to its symptom pattern.
