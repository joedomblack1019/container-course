# Week 8: GitOps with ArgoCD + DevSecOps Pipeline

## Overview

**Duration:** 3 hours
**Format:** Lecture + Hands-on Labs

You've spent seven weeks building containers by hand — Dockerfiles, multi-stage builds, Kustomize overlays, network policies, Helm charts. Every deployment was manual: you pushed code and either ran `kubectl apply` yourself or waited for someone else's automation to pick it up.

This week you own the full loop. You'll install ArgoCD on your own cluster, fork a portfolio template that you'll keep after the course, understand the 8-stage security pipeline protecting it, and deploy it via GitOps. When something breaks, you'll learn the only way to fix it.

The result: a working DevSecOps portfolio piece — your code, your pipeline, your cluster, your deployment. Something you can show an employer.

---

## Learning Outcomes

By the end of this class, you will be able to:

1. Install ArgoCD on a kind cluster using Helm and explain what each component does `CKA: Cluster Architecture, Installation and Configuration`
2. Run five DevSecOps tools locally (ruff, bandit, hadolint, trivy, kubeconform) and explain what each catches `CKA: Troubleshooting`
3. Read a CI/CD pipeline definition and explain its fail-fast stage ordering `CKA: Troubleshooting`
4. Deploy an application to Kubernetes via ArgoCD GitOps (push -> detect -> sync) `CKA: Cluster Architecture, Installation and Configuration`
5. Demonstrate that rollback in GitOps means reverting the source, not clicking a UI button `CKA: Troubleshooting`
6. Run a timed cluster-component troubleshooting sprint across DNS, scheduler symptoms, resource pressure, and multi-container log triage `CKA: Troubleshooting`
7. Design and validate an HA control-plane topology and failure workflow `CKA: Cluster Architecture, Installation and Configuration`
8. (Bonus) Integrate HashiCorp Vault for secrets management in a Kubernetes deployment `CKA: Cluster Architecture, Installation and Configuration`
9. Complete a timed CKA-style mixed-domain mock sprint with evidence capture and remediation mapping `CKA: Troubleshooting + Cluster Architecture, Installation and Configuration + Services and Networking + Workloads and Scheduling + Storage`

---

## Pre-Class Setup

Verify tools:

```bash
kubectl version --client
kind version
helm version
docker version
gh auth status
pip --version
```

You will also need a GitHub account and a fork of the [`devsecops-portfolio-template`](https://github.com/shart-cloud/container-devsecops-template) repository (Lab 1 walks you through this).

---

## Key Concepts

### GitOps: The Model

GitOps means Git is the single source of truth for your cluster state. An operator (ArgoCD) watches your repo and continuously reconciles the cluster to match what's in Git.

The core loop:
1. Developer pushes a change to Git
2. ArgoCD detects the change (polling or webhook)
3. ArgoCD renders the manifests (`kustomize build`)
4. ArgoCD compares rendered manifests to live cluster state
5. ArgoCD applies the diff

### ArgoCD Architecture

ArgoCD runs inside your cluster as a set of controllers:
- **API Server** — serves the UI and API
- **Repo Server** — clones repos, renders manifests (runs `kustomize build`)
- **Application Controller** — watches Applications, compares desired vs live state, syncs

### Polling vs Webhooks

ArgoCD polls Git by default (every 3 minutes, we'll lower it to 30s for labs). Webhooks are faster but require your cluster to be reachable from GitHub — not possible with a local kind cluster.

### Rollback in GitOps

This is the most important concept this week:

> In GitOps, rollback means reverting the commit in Git. ArgoCD re-syncs the reverted state. Clicking "Rollback" in the UI works temporarily, but if auto-sync is on, ArgoCD will re-sync the bad commit from Git within seconds. The fix is always in the source.

### DevSecOps Pipeline: Fail Fast

A good CI pipeline orders stages by cost: cheap, fast checks first — expensive checks later. The portfolio template's 8-stage pipeline follows this pattern:

1. **Code Quality** (ruff + bandit) — seconds, no build needed
2. **Dockerfile Scan** (hadolint + trivy config) — seconds, no build needed
3. **Build** — minutes, produces the image
4. **Container Scan** (trivy image) — needs the built image
5. **Push** (GHCR) — only on main, only if scans pass
6. **K8s Validation** (kubeconform) — validates manifests
7. **Integration Test** — starts the container, hits endpoints
8. **Update Tag** — commits new SHA back to Git (only on main)

If ruff finds a lint error in stage 1, you never waste time building a container. That's fail-fast.

### CRDs and Operators

The 2025 CKA curriculum added CRDs and operators explicitly. You don't need to write an operator, but you need to diagnose failures at this layer.

**What a CRD does:** A `CustomResourceDefinition` teaches the API server about a new object kind — `Application`, `Certificate`, `HelmRelease`, etc. Once a CRD is installed, you can `kubectl apply` a Custom Resource (CR) of that kind and the API server will accept and store it.

**What an operator does:** An operator is a controller (usually a Deployment in the cluster) that watches CRs and reconciles real infrastructure to match. ArgoCD's Application controller is an operator — it watches `Application` CRs and syncs clusters.

**The failure pattern to know:**

```bash
# If you apply a CR and the CRD isn't installed yet, you get:
# error: no kind "Application" is registered for version "argoproj.io/v1alpha1"

# Check what CRDs are installed
kubectl get crd
kubectl get crd applications.argoproj.io   # check a specific one

# Check if the operator (controller) is running and healthy
kubectl -n argocd get deployment argocd-application-controller
kubectl -n argocd logs deployment/argocd-application-controller --tail=50

# See the CR and its status conditions (operator writes status back here)
kubectl get application -n argocd my-app -o yaml | grep -A20 "status:"
```

> **Reference:** [Custom Resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) | [Operator Pattern](https://kubernetes.io/docs/concepts/extend-kubernetes/operator/)

### HA Control Plane + etcd Quorum

Lab 6 covers HA topology in detail. The exam tests whether you understand quorum and what happens when you lose a control-plane node — know this even if you only skim the lab.

**etcd quorum:** etcd requires a majority of members to agree before accepting writes. With `n` members, the cluster needs `(n/2)+1` members healthy to remain writable.

| Cluster size | Failure tolerance | Write availability |
|---|---|---|
| 1 member | 0 failures | Writes fail if the one node is lost |
| 3 members | 1 failure | Continues with 2 of 3 |
| 5 members | 2 failures | Continues with 3 of 5 |

**What happens when you lose a control-plane node:**
- If quorum is maintained (e.g. 2 of 3 etcd members still up): API server on remaining nodes continues serving reads and writes. Scheduling and reconciliation continue.
- If quorum is lost: API server goes read-only (existing pods keep running, kubelet continues, but no new scheduling or writes). Recovery requires restoring quorum — either by restarting the failed member or restoring from snapshot.

**Quick HA inspection commands:**
```bash
# Check etcd member list (run inside an etcd pod)
ETCD=$(kubectl -n kube-system get pods -l component=etcd -o name | head -1)
kubectl -n kube-system exec "$ETCD" -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  member list

# Confirm control-plane pods on each node
kubectl get pods -n kube-system -l tier=control-plane -o wide
```

> **Reference:** [HA Topology Options](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/) | [etcd Clustering](https://etcd.io/docs/v3.5/op-guide/clustering/)

### CKA Cluster Troubleshooting Triage Order

Lab 5 is the most CKA-aligned lab in the course. Whether or not you run it end-to-end, internalize this triage sequence — it covers 30% of the exam's Troubleshooting domain.

When something is broken on a cluster, check in this order:

```
1. Node health          kubectl get nodes
2. Control-plane pods   kubectl -n kube-system get pods -l tier=control-plane
3. DNS                  kubectl run dns-check --rm -it --image=busybox:1.36 -- nslookup kubernetes
4. Scheduler logs       kubectl -n kube-system logs deployment/kube-scheduler --tail=40
5. API server logs      kubectl -n kube-system logs kube-apiserver-<node> --tail=40
6. kubelet on node      journalctl -u kubelet -n 60 --no-pager   (SSH to node)
7. Events               kubectl get events -A --sort-by=.metadata.creationTimestamp | tail -40
8. Pod logs             kubectl logs <pod> -c <container> --previous
```

> **Rule of thumb:** Work from cluster-level down to pod-level. A failing node corrupts many pods; a missing DNS entry corrupts all pods on the cluster; a misconfigured deployment affects only one workload. Start broad, narrow down.

---

## Labs

### Lab 1: Install ArgoCD on kind with Helm (~40 min)

See [labs/lab-01-argocd-install/](./labs/lab-01-argocd-install/)

You will:
- Fork the portfolio template repo (you'll need it in Lab 3, but start CI running now)
- Install ArgoCD via Helm with a custom values file
- Access the ArgoCD UI via port-forward
- Extract the admin password and tour the interface

### Lab 2: CI/CD Pipeline Deep Dive (~50 min)

See [labs/lab-02-ci-pipeline-tools/](./labs/lab-02-ci-pipeline-tools/)

You will:
- Read the 8-stage CI pipeline and understand its fail-fast ordering
- Install and run five DevSecOps tools locally: ruff, bandit, hadolint, trivy, kubeconform
- Intentionally introduce security issues and watch the tools catch them
- Push a commit to your fork and watch CI run in GitHub Actions

### Lab 3: The GitOps Loop + Revert (~40 min)

See [labs/lab-03-gitops-loop/](./labs/lab-03-gitops-loop/)

You will:
- Point ArgoCD at your forked portfolio repo
- Push a change and watch ArgoCD auto-sync it to the cluster
- Break the deployment on purpose, attempt a UI rollback, and learn why it doesn't stick
- Fix it the right way with `git revert`

### Lab 4: Vault Integration (Bonus, ~30 min)

See [labs/lab-04-vault-integration/](./labs/lab-04-vault-integration/)

You will:
- Install Vault in dev mode on your kind cluster
- Create a GitHub App for API access
- Store credentials in Vault and wire them to the portfolio app
- See the dashboard come alive with live GitHub data

### Lab 5: Cluster Component Troubleshooting Sprint (~60 min)

> **CKA weight: Troubleshooting is 30% of the exam.** This lab is structured as a timed sprint across the exact failure categories the exam tests. Treat it as a required lab, not an extension — the triage sequence it builds is the most exam-relevant hour in the course.

See [labs/lab-05-cluster-component-troubleshooting/](./labs/lab-05-cluster-component-troubleshooting/)

You will:
- Run timed incidents for CoreDNS, scheduling failures, control-plane scheduler breakage, resource pressure, and multi-container pod triage
- Use `kubectl get events`, `describe`, logs, and control-plane checks to isolate root causes
- Document triage order and recovery commands like a real incident response runbook

### Lab 6 (CKA Extension): HA Control Plane Design + Simulation (~40 min)

See [labs/lab-06-ha-control-plane-design/](./labs/lab-06-ha-control-plane-design/)

You will:
- Build a multi-control-plane kind topology to visualize HA behavior
- Inspect etcd quorum and control-plane endpoint flow
- Simulate control-plane node loss and verify cluster continuity

### Lab 7 (CKA Capstone Draft): Timed Mock Sprint (~120 min)

See [labs/lab-07-cka-mock-sprint/](./labs/lab-07-cka-mock-sprint/)

You will:
- Run a timed 12-task mixed-domain sprint under exam-style constraints
- Capture command and verification evidence in a scoring worksheet
- Identify weak domains and map them to targeted `gymctl` remediation drills

---

## Discovery Questions

1. You click "Rollback" in the ArgoCD UI but auto-sync is enabled. What happens 30 seconds later, and why?
2. The CI pipeline runs code-quality first and container-scan fourth. Why not scan the container first?
3. Bandit found a medium-severity issue but the pipeline still passed. Trivy found a HIGH CVE and the pipeline failed. Why the different thresholds?
4. Your portfolio works locally with `docker run` but fails in Kubernetes. What's the first thing you check?
5. The CI pipeline's last job commits a new image tag back to Git. What prevents this from triggering an infinite pipeline loop?

---

## Homework

Homework exercises run in your DevContainer via **gymctl** (the [container-gym](https://github.com/shart-cloud/container-gym) CLI).

| Exercise | Time | Focus |
|----------|------|-------|
| `jerry-argo-out-of-sync` | 25 min | Debug an Application that won't sync (wrong path, bad creds, namespace issues) |
| `jerry-ci-pipeline-fix` | 25 min | Fix a broken GitHub Actions workflow |
| `jerry-coredns-loop` | 25 min | DNS outage triage and CoreDNS recovery |
| `jerry-node-notready-kubelet` | 25 min | Node NotReady incident diagnosis and recovery evidence |
| `34-jerry-init-container-stuck` | 25 min | Init:CrashLoopBackOff diagnosis in multi-container workloads |
| `37-jerry-scheduler-missing` | 25 min | Scheduler/API symptom triage from control-plane manifest issues |
| `jerry-crd-operator-broken` *(optional extension)* | 25 min | CRD and operator reconciliation triage |

---

## Resources

- ArgoCD Docs: https://argo-cd.readthedocs.io/en/stable/
- ArgoCD Helm Chart: https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd
- kubeconform: https://github.com/yannh/kubeconform
- Trivy: https://aquasecurity.github.io/trivy/
- Ruff: https://docs.astral.sh/ruff/
- Bandit: https://bandit.readthedocs.io/
- Hadolint: https://github.com/hadolint/hadolint
- GitHub Actions: https://docs.github.com/en/actions
- Custom Resources: https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/
- Operator Pattern: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
- HA Topology Options: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/
- Troubleshooting Clusters: https://kubernetes.io/docs/tasks/debug/debug-cluster/

---

## Course Wrap-Up

You started this course running `docker run nginx`. You're ending it with:
- A DevSecOps portfolio you own — code, pipeline, deployment
- An 8-stage CI/CD pipeline that catches bugs, vulnerabilities, and bad YAML before anything reaches your cluster
- ArgoCD watching your repo and syncing your cluster automatically
- The knowledge that in GitOps, the fix is always in the source

That's the full stack. Ship it.
