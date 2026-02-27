![Lab 03 The GitOps Loop and Revert](../../../assets/generated/week-08-lab-03/hero.png)
![Lab 03 GitOps reconcile and revert workflow](../../../assets/generated/week-08-lab-03/flow.gif)

---

# Lab 3: The GitOps Loop + Revert

**Time:** 40 minutes
**Objective:** Deploy your portfolio via ArgoCD, experience the full GitOps loop, break it deliberately, discover why the UI rollback is a trap, and learn that the only permanent fix is in Git.

---

## The Story

It is 11 PM. You pushed a commit to main. Thirty seconds later, your portfolio is broken. ArgoCD synced the bad commit automatically, the pod is in `ImagePullBackOff`, and the UI is down.

You open the ArgoCD interface, find the previous working revision in the history, click rollback, and the pod comes back. Relieved, you close your laptop.

At 11:31 PM, ArgoCD runs its next reconciliation cycle. The bad commit is still in Git. ArgoCD syncs it again. The pod breaks again.

This lab is about understanding why that happened and internalizing the only correct response: you do not fix a GitOps cluster by clicking buttons or running `kubectl`. You fix it by fixing Git, and then the operator fixes the cluster.

---

## CKA Objectives Mapped

- Understand declarative configuration management
- Use rollback strategies appropriate to a GitOps workflow
- Diagnose and recover from `ImagePullBackOff` and `SyncFailed` application states

---

## Background: What GitOps Actually Means

### The core principle

GitOps is a model where a Git repository is the **single source of truth** for what the cluster should contain. An operator (ArgoCD in this course) continuously enforces that truth by comparing the desired state in Git against the actual state in the cluster and reconciling any differences.

This has one consequence that surprises almost everyone the first time they encounter it: **the cluster is read-only from your perspective**. If you make a change directly in the cluster — with `kubectl apply`, with the ArgoCD UI sync, with a rollback button — and that change is not reflected in Git, the operator will undo it at the next reconciliation cycle.

```
+-------------+         +--------------------+         +-------------+
|             |  push   |                    |  sync   |             |
|  Developer  +-------->+    Git Repository  +-------->+   ArgoCD    |
|             |         |   (source of truth)|         |  Operator   |
+-------------+         +--------------------+         +------+------+
                                                              |
                                  Git is authoritative        | reconcile
                                  Cluster follows Git         v
                                                       +--------------+
                                                       |  Kubernetes  |
                                                       |   Cluster    |
                                                       |   (follows)  |
                                                       +--------------+
```

### Why the UI rollback is a trap

The ArgoCD UI rollback button deploys a previous rendered manifest directly to the cluster. It does not create a Git commit. It does not revert your repository. It reaches past Git and applies state directly — which is exactly what ArgoCD is designed to prevent you from doing.

With `automated` sync and `selfHeal: true` enabled (as in our Application), ArgoCD will detect that the cluster no longer matches what Git says and re-sync within 30 seconds (our configured interval). The rollback is undone automatically. You are back where you started.

This is not a bug. It is the intended behavior. ArgoCD's selfHeal feature exists precisely to close the gap between what humans do to clusters manually and what Git says should be there. The lesson is: if you want a permanent change, it must go through Git.

### The correct rollback: git revert

`git revert` creates a new commit that is the inverse of a previous commit. It does not rewrite history — it adds a forward commit that undoes a past change. This is the safe way to roll back in a shared repository because it preserves the full history of what happened and why.

Once the revert commit is on `main`, ArgoCD picks it up at the next reconciliation cycle, renders the now-corrected manifests, and applies them to the cluster. The cluster recovers because Git is now correct, not because you patched the cluster directly.

**Further reading:**
- [ArgoCD Application Specification](https://argo-cd.readthedocs.io/en/stable/user-guide/application-specification/)
- [ArgoCD Sync Policies](https://argo-cd.readthedocs.io/en/stable/user-guide/auto_sync/)
- [git revert (git docs)](https://git-scm.com/docs/git-revert)

---

## Prerequisites

You should have:
- ArgoCD running on your kind cluster (from Lab 1)
- Your fork of `devsecops-portfolio-template` cloned locally (from Lab 1)
- The ArgoCD UI accessible at `localhost:8080`
- Your GHCR package set to **public** (from Lab 2) — if you skipped this, go to `https://github.com/<YOUR_GITHUB_USERNAME>/devsecops-portfolio-template/pkgs/container/devops-portfolio` → Package settings → Change visibility → Public

Verify before starting:

```bash
kubectl get pods -n argocd
```

Re-establish the port-forward if needed:

```bash
kubectl port-forward service/argocd-server -n argocd 8080:443 &
```

---

## Part 1: Personalize Your Portfolio

Before deploying, make the content yours. In your `devsecops-portfolio-template` clone, edit `k8s/base/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: portfolio-config
data:
  STUDENT_NAME: "<YOUR_NAME>"
  GITHUB_USERNAME: "<YOUR_GITHUB_USERNAME>"
  GITHUB_REPO: "devsecops-portfolio-template"
  BIO: "<A sentence or two about yourself>"
  VAULT_ADDR: "http://vault.default:8200"
  VAULT_SECRET_PATH: "secret/data/github-app"
```

Commit and push:

```bash
git add k8s/base/configmap.yaml
git commit -m "personalize portfolio config"
git push
```

Notice: you are pushing to your fork's `main` branch. This triggers the CI pipeline you examined in Lab 2. The pipeline runs in parallel with the ArgoCD setup you are about to do — by the time you apply the ArgoCD Application manifest, CI will likely have already passed.

---

## Part 2: Configure the ArgoCD Application

A starter `application.yaml` is in [`starter/`](./starter/). It defines the ArgoCD Application resource — the object that tells ArgoCD which repo to watch, which path to render, and which cluster/namespace to sync into.

Edit `argocd/application.yaml` in your fork and replace `<YOUR_GITHUB_USERNAME>`:

```yaml
spec:
  source:
    repoURL: https://github.com/<YOUR_GITHUB_USERNAME>/devsecops-portfolio-template.git
```

Key fields and what they control:

```yaml
spec:
  source:
    targetRevision: main        # Watch the main branch
    path: k8s/overlays/local    # Run kustomize build on this path

  syncPolicy:
    automated:
      prune: true               # Delete resources removed from Git
      selfHeal: true            # Revert manual cluster changes back to Git state

  syncOptions:
    - CreateNamespace=true      # Create the portfolio namespace if it doesn't exist
```

Notice: `selfHeal: true` is the setting that makes the UI rollback ineffective. With self-healing enabled, ArgoCD actively monitors for drift between Git and the cluster and corrects it on the next cycle. This is what enforces Git as the single source of truth. You will see it in action in Part 6.

Operator mindset: read every field in an Application manifest before applying it. `prune: true` means resources deleted from Git will be deleted from the cluster — which is powerful but destructive if you misunderstand the scope.

---

## Part 3: Deploy via ArgoCD

First, commit and push your updated `application.yaml` to your fork:

```bash
git add argocd/application.yaml
git commit -m "configure argocd application for my fork"
git push
```

This is done in your `devsecops-portfolio-template` Codespace. Now switch to your **container-course Codespace** where the kind cluster is running, and apply the manifest directly from GitHub:

```bash
kubectl apply -f https://raw.githubusercontent.com/<YOUR_GITHUB_USERNAME>/devsecops-portfolio-template/main/argocd/application.yaml
```

Notice: you are applying from a URL, not a local file. This means you are pulling the manifest from the same source of truth that ArgoCD will watch — no file copying or repo cloning required in the cluster Codespace.

Open the ArgoCD UI at `http://localhost:8080`. Watch the **portfolio** Application appear and begin syncing.

ArgoCD is doing the following in sequence:
1. Cloning your fork from GitHub
2. Running `kustomize build k8s/overlays/local` to render the manifests
3. Comparing the output against the cluster (nothing exists yet — everything is new)
4. Applying the diff — creating the namespace, Deployment, Service, ConfigMap, and ServiceAccount

The app references a `vault-token` secret for its Vault integration. Vault is not set up until Lab 4 — create a placeholder now so the pod can start:

```bash
kubectl create secret generic vault-token \
  --from-literal=token=placeholder \
  -n portfolio
```

The app handles Vault being unavailable gracefully. You will see `vault: disconnected` in the `/api/status` response — this is expected and intentional until Lab 4.

Watch the pods come up:

```bash
kubectl get pods -n portfolio -w
```

Once Running, port-forward to see your portfolio:

```bash
kubectl port-forward -n portfolio service/portfolio-svc 5001:80 &
```

Open `http://localhost:5001`. Your name and bio should appear.

Notice: you did not run `kubectl apply` on any of your manifests. You applied one ArgoCD Application manifest, and ArgoCD deployed everything else. From this point forward, you will not use `kubectl apply` on your portfolio manifests again — Git is the only input.

Operator mindset: the moment you start managing application manifests directly with kubectl alongside a GitOps operator, you have two sources of truth competing with each other. Choose one.

---

## Part 4: Push a Change and Watch It Sync

Edit the bio in `k8s/base/configmap.yaml`:

```yaml
  BIO: "Week 8 capstone — deployed via ArgoCD GitOps"
```

Commit and push:

```bash
git add k8s/base/configmap.yaml
git commit -m "update bio text"
git push
```

Wait up to 30 seconds. Watch the ArgoCD UI — the Application briefly shows **OutOfSync**, then syncs automatically.

Refresh `http://localhost:5001`. The bio updated without you touching kubectl.

Notice: ArgoCD detected the new commit via polling (every 30 seconds in our configuration). In production you can also configure a Git webhook to notify ArgoCD of new commits immediately, which is faster than polling and reduces unnecessary clone operations.

This is the GitOps loop closing: Git changed, ArgoCD detected it, the cluster synced to match.

---

## Part 5: Break It

Edit `k8s/base/kustomization.yaml`. Change the image tag to one that does not exist:

```yaml
images:
  - name: ghcr.io/OWNER/devops-portfolio
    newTag: sha-doesnotexist
```

Commit and push:

```bash
git add k8s/base/kustomization.yaml
git commit -m "break: use nonexistent image tag"
git push
```

Within 30 seconds ArgoCD detects the commit, syncs, and Kubernetes tries to pull `sha-doesnotexist`. The image does not exist in the registry. The pod enters `ImagePullBackOff`.

```bash
kubectl get pods -n portfolio
kubectl describe pod -n portfolio -l app=portfolio | grep -A10 Events
```

Notice: the pod is in `ImagePullBackOff`, not `CrashLoopBackOff`. These are different failure modes. `ImagePullBackOff` means Kubernetes cannot pull the container image — the container never starts. `CrashLoopBackOff` means the container starts but immediately exits. Both leave the pod non-functional, but the diagnosis path is different. `Events` in `kubectl describe` tells you which one you have and why.

In the ArgoCD UI the Application is **Degraded** — ArgoCD successfully synced the Git state to the cluster (sync succeeded), but the resulting workload is unhealthy (health check failed). Synced and Healthy are independent signals.

Operator mindset: in ArgoCD, Synced means Git matches the cluster. Healthy means the workload is actually running. You can be Synced but Degraded — which is exactly what a bad image tag produces.

---

## Part 6: The Wrong Fix (and Why It Fails)

In the ArgoCD UI:
1. Click on the **portfolio** Application
2. Click **History and Rollback** (clock icon)
3. Find the revision before the bad commit
4. Click **Rollback**

The pod recovers. Your portfolio comes back. It feels fixed.

Wait 30 seconds.

ArgoCD re-syncs from Git. The bad commit is still on `main`. `sha-doesnotexist` re-applies. The pod breaks again.

Notice: this is `selfHeal: true` working exactly as designed. ArgoCD detected that the cluster no longer matched what Git said, and corrected it. The UI rollback bypassed Git — so ArgoCD treated it as drift and reverted it. If you had `selfHeal: false`, the UI rollback would persist until the next push to Git. But you would still be in a broken state where Git and the cluster disagree, which is a dangerous place to be.

Operator mindset: the UI rollback is a debugging tool, not a recovery strategy. It tells you "the previous state worked" — that information goes into a `git revert`. It does not replace one.

---

## Part 7: The Right Fix

```bash
git revert HEAD --no-edit
git push
```

Watch ArgoCD:
1. Detects the revert commit within 30 seconds
2. Syncs — the image tag reverts to the last working SHA
3. Kubernetes pulls the correct image
4. Pod comes back up — Synced and Healthy

```bash
kubectl get pods -n portfolio
```

Refresh `http://localhost:5001`. Your portfolio is back — permanently, because Git is now correct.

Notice: `git revert HEAD --no-edit` created a new commit on `main` that is the inverse of the last commit. It did not delete the bad commit — the history still shows what happened and when. In production this audit trail matters: you can see exactly when the bad tag was pushed, who pushed it, when the revert happened, and what changed. Rewriting history with `git reset --hard` and a force push would destroy that.

Operator mindset: in GitOps, the recovery story is in Git. `git revert` preserves the audit trail. Force-pushing to erase history destroys it. Use `revert`.

---

## Verification Checklist

You are done when:

- Portfolio is deployed via ArgoCD — Application shows Synced + Healthy
- You pushed a change and saw it auto-sync to the cluster within 30 seconds
- You broke the Deployment with a bad image tag and can explain the difference between Synced and Healthy
- You used the UI rollback and watched ArgoCD undo it at the next reconciliation cycle
- You fixed it permanently with `git revert` and saw Synced + Healthy return
- You can explain: in GitOps, rollback means reverting the commit — not clicking a button

---

## Cleanup

To remove the portfolio from your cluster:

```bash
kubectl delete application portfolio -n argocd
```

ArgoCD will prune all the resources it created because `prune: true` is set. The namespace, Deployment, Service, and ConfigMap are all removed.

---

## Reinforcement Scenarios

- `jerry-gitops-manual-override`
- `jerry-argocd-sync-loop`
- `jerry-image-pull-backoff`
