![Lab 02 CI CD Pipeline Deep Dive](../../../assets/generated/week-08-lab-02/hero.png)
![Lab 02 pipeline tools workflow](../../../assets/generated/week-08-lab-02/flow.gif)

---

# Lab 2: CI/CD Pipeline Deep Dive

**Time:** 50 minutes
**Objective:** Understand the 8-stage DevSecOps pipeline by running each tool locally, seeing what each one catches, and intentionally breaking things to read the output before CI automates it for you.

---

## The Story

You have been pushing code and trusting that things work. In production, that trust is not enough.

Every commit that reaches your cluster passed through a gauntlet of automated checks first. Code quality gates catch mistakes before they become bugs. Security scanners catch vulnerabilities before they become incidents. Kubernetes manifest validation catches misconfigurations before ArgoCD tries to apply them and fails in production.

The portfolio template has an 8-stage pipeline that runs all of these checks. Before you let it run automatically in GitHub, you are going to run every tool yourself. When a tool flags something — and you will make it flag things on purpose — you will know exactly what it caught and why. CI is not magic. It is just a script that runs the same tools you are about to run.

---

## Background: The DevSecOps Pipeline Model

### Why pipelines are structured the way they are

A well-designed CI pipeline is built around two principles: **fail fast** and **parallelize safely**.

Fail fast means cheap checks run before expensive ones. If `ruff` finds a syntax error in 3 seconds, there is no point spending 2 minutes building a container image. The pipeline should reject bad commits as early and cheaply as possible.

Parallelize safely means independent checks run at the same time. The Kubernetes manifest validation does not need a built container image to check if the YAML is valid — it can run in parallel with the container build track, then both tracks converge at the final deploy step.

```
commit
  |
  v
[code-quality]  <-- ruff + bandit (runs first, no dependencies)
  |
  +---------------------------+
  |                           |
  v                           v
[dockerfile-scan]        [k8s-validate]  <-- parallel tracks
  |                           |
  v                           |
[build]                       |
  |                           |
  +--+                        |
  |  |                        |
  v  v                        |
[container-scan] [integration-test]      |
  |         |                 |
  v         +--------+--------+
[push]               |
  |                  v
  +---------> [update-tag]  <-- converge here, main branch only
```

### The 8 stages

| Stage | Tool(s) | What it catches | Depends on |
|---|---|---|---|
| `code-quality` | ruff, bandit | Style errors, security anti-patterns in Python | Nothing |
| `dockerfile-scan` | hadolint, trivy config | Bad Dockerfile practices, misconfigurations | code-quality |
| `build` | docker build | Build failures, missing files, broken dependencies | dockerfile-scan |
| `container-scan` | trivy image | Known CVEs in installed packages | build |
| `push` | GHCR | Publishes image (main branch only) | build + container-scan |
| `k8s-validate` | kubeconform | Invalid Kubernetes API schemas, typos in manifests | code-quality |
| `integration-test` | curl/pytest | Runtime failures — does the container actually start and respond? | build |
| `update-tag` | git commit | Writes new image SHA back to Git for ArgoCD to pick up | push + k8s-validate + integration-test |

Notice: `k8s-validate` depends only on `code-quality`, not on `build`. Kubernetes manifest validation does not need a container image — it only needs the YAML files. This is intentional: if the manifests are broken, you want to know before you waste time building and scanning an image that ArgoCD will fail to apply anyway.

**Further reading:**
- [GitHub Actions workflow syntax](https://docs.github.com/en/actions/writing-workflows/workflow-syntax-for-github-actions)
- [Trivy documentation](https://aquasecurity.github.io/trivy/)
- [kubeconform](https://github.com/yannh/kubeconform)

---

## Prerequisites

You should have your fork of `devsecops-portfolio-template` cloned locally (from Lab 1):

```bash
cd devsecops-portfolio-template
```

Read the pipeline file before touching any tools:

```bash
cat .github/workflows/ci.yaml
```

Notice: reading the pipeline file first is not optional. Every tool you are about to run locally is called in this file. Understanding the pipeline structure makes the tool outputs meaningful instead of just being noise.

Operator mindset: understand the automation before trusting it. If you cannot read the pipeline, you cannot debug it.

---

## Part 1: Read the Pipeline

Open `.github/workflows/ci.yaml` in your editor. Identify:

- Which job runs first with no dependencies
- Which jobs run in parallel after `code-quality`
- Which jobs only run on the `main` branch (look for `if:` conditions)
- How jobs declare their dependencies (look for `needs:`)

Answer before moving on: why does `k8s-validate` depend on `code-quality` but not on `build`?

---

## Part 2: Code Quality — ruff + bandit

### Install

```bash
pip install ruff bandit
```

### Run ruff

```bash
ruff check app/
```

Ruff is a Python linter written in Rust. It checks for syntax errors, unused imports, style violations, and common logic mistakes. It should pass cleanly on the template.

### Run bandit

```bash
bandit -r app/
```

Bandit is a Static Application Security Testing (SAST) tool. It does not check for style — it checks for dangerous patterns in your code: hardcoded credentials, use of `eval()`, insecure SSL settings, subprocess calls with `shell=True`. It scans the source code without running it.

Read the output. Note the severity levels (LOW, MEDIUM, HIGH) and confidence levels. The distinction matters: a HIGH severity finding with LOW confidence is less urgent than a MEDIUM finding with HIGH confidence.

### Break it on purpose

Add this line inside any function in `app/app.py`, for example at the top of the `health()` function:

```python
result = eval("1 + 1")  # nosec: intentional for lab
```

Run bandit again:

```bash
bandit -r app/
```

Notice: bandit flags `eval()` as B307 — the use of Python's `eval` for untrusted input is a well-known code injection vector. Ruff would not catch this because it is syntactically valid Python. SAST and linting solve different problems.

Undo the change:

```bash
git checkout app/app.py
```

### How CI uses these

Look at the `code-quality` job in `ci.yaml`. Ruff runs with `--output-format=github` so failures appear as inline PR annotations. Bandit outputs JSON and a script filters for HIGH severity findings — medium findings log a warning but do not fail the build. That threshold is a deliberate policy decision, not a default.

Operator mindset: CI gates encode policy. Know what threshold each tool is configured to enforce and why.

---

## Part 3: Dockerfile Security — hadolint + trivy config

### Install hadolint

```bash
curl -sL https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -o hadolint
chmod +x hadolint
sudo mv hadolint /usr/local/bin/
```

### Run hadolint

```bash
hadolint app/Dockerfile
```

Hadolint lints Dockerfiles against a set of best practice rules. It checks things like: pinned base image versions, `apt-get` without cleanup, missing `HEALTHCHECK`, running as root, and shell best practices. The template follows these rules, so it should pass cleanly.

### Install trivy

```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin
```

### Run trivy config

```bash
trivy config app/
```

Trivy's config mode scans Dockerfiles and other infrastructure-as-code files for security misconfigurations. It catches things hadolint does not — running as root, exposed secrets baked into layers, missing security directives.

### Break it on purpose

In `app/Dockerfile`, find the `USER` line and change it:

```dockerfile
# Change this:
USER appuser
# To this:
USER root
```

Run both tools:

```bash
hadolint app/Dockerfile
trivy config app/
```

Notice: both tools flag running as root, but they report it differently. Hadolint calls it DL3002. Trivy calls it a misconfiguration with a CVE-style reference. In CI, either failure blocks the pipeline before the image is ever built — catching the problem when it is cheap to fix (edit a line) rather than after it reaches production (root process escaping a container).

Undo the change:

```bash
git checkout app/Dockerfile
```

Operator mindset: Dockerfile security checks run before the build because fixing a Dockerfile is free. Fixing a production incident caused by a root container is not.

---

## Part 4: Container Build + Image Scan

### Build the image

```bash
docker build -t portfolio-test app/
```

This runs the same multi-stage build that CI runs. Stage 1 installs dependencies in a full build environment. Stage 2 copies only the built artifacts into a clean, minimal runtime image. The final image does not contain build tools — only what the app needs to run.

### Scan the built image

```bash
trivy image portfolio-test
```

This is different from `trivy config` — instead of reading the Dockerfile, it inspects the actual image layers for known CVEs in every installed package. The output shows vulnerabilities by severity: CRITICAL, HIGH, MEDIUM, LOW.

Run the CI gate version — the one that actually fails the pipeline:

```bash
trivy image --severity CRITICAL,HIGH --exit-code 1 portfolio-test
```

Notice: `--exit-code 1` makes trivy return a non-zero exit code when it finds matches at the specified severity. CI systems treat non-zero exit codes as failures. This is how every automated gate works — the tool reports what it found, and the exit code determines pass or fail. If trivy exits 0, the pipeline continues. If it exits 1, it stops.

Notice: you ran trivy twice on the same code — once on the Dockerfile (`trivy config`) and once on the built image (`trivy image`). These catch different things. `trivy config` catches bad practices in how you write the Dockerfile. `trivy image` catches CVEs in the packages that ended up inside the resulting image. A perfectly written Dockerfile using a base image with unpatched vulnerabilities will pass `trivy config` and fail `trivy image`.

Operator mindset: scanning the Dockerfile and scanning the image are not redundant — they are complementary checks that catch failures at different layers.

---

## Part 5: Kubernetes Manifest Validation — kubeconform

### Install kubeconform

```bash
curl -sL https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz | tar xz
sudo mv kubeconform /usr/local/bin/
```

### Validate the manifests

```bash
kubectl kustomize k8s/overlays/local | kubeconform -strict -ignore-missing-schemas -summary
```

This does two things in sequence. First, `kubectl kustomize` renders the Kustomize overlay into plain YAML — the exact same thing ArgoCD's repo server does when it reads your Git repo. Second, `kubeconform` validates that YAML against the official Kubernetes API schema: correct `apiVersion` values, all required fields present, correct field types.

The `-strict` flag rejects unknown fields, catching typos like `replica` instead of `replicas`. The `-ignore-missing-schemas` flag skips CRDs without built-in schemas rather than erroring on them.

### Break it on purpose

Edit `k8s/base/deployment.yaml`. Change the `apiVersion`:

```yaml
# Change:
apiVersion: apps/v1
# To:
apiVersion: apps/v999
```

Run validation again:

```bash
kubectl kustomize k8s/overlays/local | kubeconform -strict -ignore-missing-schemas -summary
```

Notice: kubeconform rejects `apps/v999` because it is not a real Kubernetes API version. ArgoCD would have caught this too — but only when it tried to sync and the API server rejected the manifest. Catching it in CI means the bad manifest never reaches the cluster, never blocks a sync, and never shows up in the ArgoCD UI as a `SyncFailed` error.

Undo the change:

```bash
git checkout k8s/base/deployment.yaml
```

Operator mindset: manifest validation in CI is a fast pre-flight check for what ArgoCD would eventually reject anyway. Catch it early when the fix is a one-line edit, not during an incident.

---

## Part 6: Watch It Run in GitHub

Now that you have run every tool by hand, push a commit and watch CI automate the same sequence.

Make a small, valid change to trigger a pipeline run:

```bash
# Edit k8s/base/configmap.yaml — change the BIO field
git add k8s/base/configmap.yaml
git commit -m "personalize bio"
git push
```

Go to your fork on GitHub → **Actions** tab. Watch the pipeline run. You should see:

- `code-quality` passes (ruff + bandit find nothing wrong)
- `dockerfile-scan` passes (hadolint + trivy-config find nothing wrong)
- `build` succeeds
- `container-scan` passes
- `k8s-validate` passes (kubeconform approves the manifests)
- `integration-test` passes (container starts, endpoints respond)

Notice: the green checkmarks map exactly to the tools you just ran locally. CI is not a black box — it is the same tools, the same commands, automated and run on every commit. When CI fails, you can reproduce the failure locally with the exact command from the workflow file.

Operator mindset: if you cannot reproduce a CI failure locally, you do not understand it well enough to fix it reliably.

### The image tag update

After the pipeline goes green, look at your fork's commit history. You will see a new commit from `github-actions[bot]` with a message like:

```
ci: update image tag to sha-abc1234
```

This is the `update-tag` job (Job 8) writing back to your repository. It ran:

```bash
kustomize edit set image ghcr.io/OWNER/devops-portfolio=ghcr.io/<YOUR_GITHUB_USERNAME>/devops-portfolio:sha-abc1234
```

Open `k8s/base/kustomization.yaml` and confirm the image entry now points to your username and the new SHA:

```yaml
images:
- name: ghcr.io/OWNER/devops-portfolio
  newName: ghcr.io/<YOUR_GITHUB_USERNAME>/devops-portfolio
  newTag: sha-abc1234
```

You do not need to edit this file manually. CI owns it. Every time a commit merges to `main` and the pipeline passes, CI updates this file with the new image SHA. ArgoCD reads this file from Git and deploys whatever tag is written there — this is the link between your CI pipeline and your GitOps deployment.

Notice: **do not manually edit `k8s/base/kustomization.yaml` to change the image tag**. That is CI's job. If you push a manual change, CI will overwrite it on the next run anyway.

### Make your container image public

After the pipeline goes green, the `push` and `update-tag` jobs will have published your image to GitHub Container Registry (GHCR) and committed the new image SHA back to `k8s/base/kustomization.yaml`.

By default, GHCR packages are private. Your kind cluster has no credentials to pull a private image, so ArgoCD will fail with `ImagePullBackOff` in Lab 3 unless you make it public now.

1. Go to `https://github.com/<YOUR_GITHUB_USERNAME>/devsecops-portfolio-template/pkgs/container/devops-portfolio`
2. Click **Package settings**
3. Scroll to **Danger Zone** → **Change visibility** → set to **Public**
4. Confirm

Notice: in production you would configure imagePullSecrets in the cluster instead of making images public. For this lab, public visibility keeps the setup simple and focused on the GitOps workflow rather than credential management.

---

## Verification Checklist

You are done when you can:

- Name all 8 pipeline stages in order and explain what each one catches
- Explain why cheap checks run before expensive ones, and why two tracks run in parallel
- Have run all five tools locally: ruff, bandit, hadolint, trivy, kubeconform
- Have triggered at least three tool failures intentionally: `eval` → bandit, `USER root` → hadolint/trivy, bad `apiVersion` → kubeconform
- Have pushed a commit and watched CI run all stages green on your fork
- Explain the difference between `trivy config` (Dockerfile static scan) and `trivy image` (CVE scan of built image)

---

## Reinforcement Scenarios

- `jerry-pipeline-secret-leak`
- `jerry-trivy-false-positive`
