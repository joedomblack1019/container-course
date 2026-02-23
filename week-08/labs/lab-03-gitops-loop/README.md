![Lab 03 The GitOps Loop and Revert](../../../assets/generated/week-08-lab-03/hero.png)
![Lab 03 GitOps reconcile and revert workflow](../../../assets/generated/week-08-lab-03/flow.gif)

---

# Lab 3: The GitOps Loop + Revert

**Time:** 40 minutes
**Objective:** Deploy your portfolio via ArgoCD, experience the GitOps loop, and learn that rollback means reverting the source

---

## The Story

You've installed ArgoCD (Lab 1) and understand the security pipeline protecting your code (Lab 2). Now connect them: point ArgoCD at your fork, push a change, and watch the full loop close — Git changed, ArgoCD detected, cluster synced.

Then you'll break it. And you'll learn that the only way to fix it is in Git.

---

## Starting Point

You should have:
- ArgoCD running on your kind cluster (from Lab 1)
- Your fork of `container-devsecops-template` cloned locally (from Lab 1)
- The ArgoCD UI accessible at `localhost:8080` (re-run the port-forward if needed)

```bash
# Verify ArgoCD is running
kubectl get pods -n argocd

# Re-establish port-forward if needed
kubectl port-forward service/argocd-server -n argocd 8080:443 &
```

---

## Part 1: Personalize Your Portfolio

Before deploying, make it yours. In your clone of `container-devsecops-template`:

Edit `k8s/base/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: portfolio-config
data:
  STUDENT_NAME: "<YOUR_NAME>"
  GITHUB_USERNAME: "<YOUR_GITHUB_USERNAME>"
  GITHUB_REPO: "container-devsecops-template"
  BIO: "<A sentence or two about yourself>"
  VAULT_ADDR: "http://vault.default:8200"
  VAULT_SECRET_PATH: "secret/data/github-app"
```

Replace the placeholders with your actual information. This ConfigMap is what the portfolio app reads to display your name, bio, and GitHub data.

Commit and push:

```bash
cd container-devsecops-template
git add k8s/base/configmap.yaml
git commit -m "personalize portfolio config"
git push
```

---

## Part 2: Configure the ArgoCD Application

A starter `application.yaml` is in this lab's [`starter/`](./starter/) directory. Copy it into your portfolio repo:

```bash
cp <path-to-this-lab>/starter/application.yaml argocd/application.yaml
```

Or edit the existing `argocd/application.yaml` in your fork. Either way, replace `<YOUR_GITHUB_USERNAME>` with your actual GitHub username:

```yaml
spec:
  source:
    repoURL: https://github.com/<YOUR_GITHUB_USERNAME>/container-devsecops-template.git
```

Key fields to understand:
- **`repoURL`** — your fork (public repo, no credentials needed)
- **`targetRevision: main`** — ArgoCD watches the `main` branch
- **`path: k8s/overlays/local`** — ArgoCD runs `kustomize build` on this path
- **`automated`** — ArgoCD syncs automatically when it detects changes
- **`prune: true`** — resources deleted from Git get deleted from the cluster
- **`selfHeal: true`** — manual changes to the cluster get reverted to match Git
- **`CreateNamespace=true`** — ArgoCD creates the `portfolio` namespace if it doesn't exist

---

## Part 3: Deploy the Application

Apply the Application manifest to your cluster:

```bash
kubectl apply -f argocd/application.yaml
```

Now watch what happens:

1. Open the ArgoCD UI at `http://localhost:8080`
2. You should see a new Application called **portfolio** appear
3. ArgoCD clones your repo, runs `kustomize build k8s/overlays/local`, and compares the output to the cluster
4. Since nothing exists yet, everything is new — ArgoCD creates the namespace, deployment, service, configmap, and service account

Watch the pods come up:

```bash
kubectl get pods -n portfolio -w
```

Once the pod is Running, port-forward to see your portfolio:

```bash
kubectl port-forward -n portfolio service/portfolio-svc 5001:80 &
```

Open `http://localhost:5001` — you should see your portfolio with your name and bio.

**This is GitOps.** You didn't run `kubectl apply` on your manifests. You told ArgoCD "watch this repo" and it deployed everything. From now on, the cluster follows Git.

---

## Part 4: Push a Change

Edit something visible. In your `container-devsecops-template` clone, change the bio in `k8s/base/configmap.yaml`:

```yaml
  BIO: "Week 8 capstone — deployed via ArgoCD GitOps"
```

Commit and push:

```bash
git add k8s/base/configmap.yaml
git commit -m "update bio text"
git push
```

Now wait. Watch the ArgoCD UI — within 30 seconds (our polling interval from Lab 1), ArgoCD detects the new commit. The Application briefly shows **OutOfSync**, then syncs automatically.

Refresh your portfolio at `http://localhost:5001`. The bio updated — without you touching kubectl.

**This is the GitOps loop:** Git changed → ArgoCD detected → cluster synced.

---

## Part 5: Break It

Now let's see what happens when things go wrong.

Edit `k8s/base/deployment.yaml` in your fork. Change the image to a tag that doesn't exist:

```yaml
images:
  - name: ghcr.io/OWNER/devops-portfolio
    newTag: sha-doesnotexist
```

Wait — that's in `kustomization.yaml`, not `deployment.yaml`. Edit `k8s/base/kustomization.yaml` instead:

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

Watch the ArgoCD UI. Within 30 seconds:
1. ArgoCD detects the change and syncs
2. Kubernetes tries to pull `sha-doesnotexist` — it doesn't exist
3. The pod goes into **ImagePullBackOff**
4. The Application turns yellow/red — **Degraded**

Your portfolio is down. Refreshing `localhost:5001` fails.

---

## Part 6: The Wrong Fix

This is where the lesson gets interesting.

In the ArgoCD UI:
1. Click on the **portfolio** Application
2. Click **History and Rollback** (clock icon)
3. Find the previous revision (before the bad commit)
4. Click **Rollback**

The pod recovers! Your portfolio is back! Problem solved... right?

**Wait 30 seconds.**

ArgoCD re-syncs from Git. The bad commit is still there. The `sha-doesnotexist` tag re-applies. The pod goes back to ImagePullBackOff. Your portfolio breaks again.

**The lesson:** In GitOps, the cluster follows Git. The UI rollback is temporary — it's a band-aid that ArgoCD's auto-sync peels off immediately. As long as the bad commit is in Git, ArgoCD will faithfully re-apply it.

---

## Part 7: The Right Fix

The real rollback is a `git revert`:

```bash
git revert HEAD --no-edit
git push
```

This creates a new commit that undoes the bad change. Now watch ArgoCD:
1. ArgoCD detects the revert commit (within 30 seconds)
2. ArgoCD syncs — the image tag goes back to what it was before
3. Kubernetes pulls the correct image
4. The pod comes back up
5. Your portfolio is back — **permanently**

Refresh `http://localhost:5001`. It works. And it will keep working, because Git is now correct.

**This is how you fix things in GitOps.** Not by clicking buttons in a UI, not by running `kubectl` commands against the cluster. You fix the source, and the operator does the rest.

---

## Checkpoint

You are done when:
- [ ] Portfolio is deployed via ArgoCD (Application shows Synced + Healthy)
- [ ] You pushed a change and saw it auto-sync to the cluster
- [ ] You broke the deployment with a bad image tag
- [ ] You tried the UI rollback and saw ArgoCD re-sync the bad state
- [ ] You fixed it with `git revert` and saw the permanent recovery
- [ ] You can explain: _"In GitOps, the cluster follows Git. Rollback means reverting the commit."_

---

## Clean Up

If you want to remove the portfolio from your cluster:

```bash
kubectl delete application portfolio -n argocd
```

ArgoCD will prune all the resources it created (because we set `prune: true`).
