![Lab 02 CI CD Pipeline Deep Dive](../../../assets/generated/week-08-lab-02/hero.png)
![Lab 02 pipeline tools workflow](../../../assets/generated/week-08-lab-02/flow.gif)

---

# Lab 2: CI/CD Pipeline Deep Dive

**Time:** 50 minutes
**Objective:** Understand the 8-stage DevSecOps pipeline by running each tool locally

---

## The Story

You've been pushing code and trusting that "it works." But in production, every commit passes through security gates before it reaches a cluster. The portfolio template has an 8-stage pipeline that checks code quality, scans for vulnerabilities, validates Kubernetes manifests, and runs integration tests — all before a single byte touches your cluster.

Before you let it run in GitHub, you're going to understand each tool by running it yourself. When a tool flags something, you'll know exactly what it caught and why.

---

## Starting Point

You should have your fork of `container-devsecops-template` cloned locally (from Lab 1).

```bash
cd container-devsecops-template
```

---

## Part 1: Read the Pipeline

Open `.github/workflows/ci.yaml` in your editor. This is the full pipeline. Read through it and identify the 8 jobs:

| Stage | Job Name | What It Does | Depends On |
|-------|----------|-------------|------------|
| 1 | `code-quality` | Lint (ruff) + SAST (bandit) | Nothing — runs first |
| 2 | `dockerfile-scan` | Hadolint + Trivy config scan | code-quality |
| 3 | `build` | Multi-stage Docker build | dockerfile-scan |
| 4 | `container-scan` | Trivy image vulnerability scan | build |
| 5 | `push` | Push to GHCR (main only) | build + container-scan |
| 6 | `k8s-validate` | kubeconform on Kustomize output | code-quality |
| 7 | `integration-test` | Start container, hit endpoints | build |
| 8 | `update-tag` | Commit new image SHA to Git (main only) | push + k8s-validate + integration-test |

Notice the structure:
- **Cheap checks run first.** Code quality takes seconds and needs no build. If ruff finds a lint error, you never waste minutes building a container.
- **The build is the gate.** Everything after stage 3 needs the built image.
- **Two parallel tracks** after code-quality: one track builds/scans the container (stages 2→3→4→5), the other validates K8s manifests (stage 6). They converge at stage 8.
- **Main-only stages** (push, update-tag) only run on merge to main — PRs get all the checks but don't publish.

**Question to think about:** Why does `k8s-validate` depend on `code-quality` but not on `build`?

---

## Part 2: Code Quality — ruff + bandit

### Install the tools

```bash
pip install ruff bandit
```

### Run ruff (linter)

```bash
ruff check app/
```

This should pass cleanly. Ruff checks for Python style issues, unused imports, and common mistakes — fast, because it's written in Rust.

### Run bandit (security scanner)

```bash
bandit -r app/
```

Bandit is a Static Application Security Testing (SAST) tool. It scans Python code for common security issues: hardcoded passwords, use of `eval()`, insecure SSL settings, subprocess calls with shell=True, etc.

Read the output. Note the severity levels (LOW, MEDIUM, HIGH) and confidence levels.

### Break it on purpose

Open `app/app.py` and add this line somewhere inside a function (e.g., at the top of the `health()` function):

```python
result = eval("1 + 1")  # nosec: intentional for lab
```

Run bandit again:

```bash
bandit -r app/
```

You should see a new finding — bandit flags `eval()` as a security issue (B307). This is exactly what SAST catches: dangerous function calls that a linter wouldn't flag.

**Undo the change** before continuing:

```bash
git checkout app/app.py
```

### How the pipeline uses these

Look at the `code-quality` job in `ci.yaml`:
- Ruff runs with `--output-format=github` so errors show as annotations on the PR
- Bandit outputs JSON, then a script checks for HIGH-severity issues. Medium issues log a warning but don't fail the build — the threshold is intentional.

---

## Part 3: Dockerfile Security — hadolint + trivy

### Install hadolint

```bash
# Linux (amd64)
curl -sL https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 -o hadolint
chmod +x hadolint
sudo mv hadolint /usr/local/bin/
```

### Run hadolint

```bash
hadolint app/Dockerfile
```

Hadolint is a Dockerfile linter that enforces best practices. It checks things like: pinned base image versions, avoiding `apt-get` without cleanup, running as root, missing `HEALTHCHECK`, and shell best practices.

If it passes cleanly, good — the template follows best practices.

### Install trivy

```bash
# Linux (amd64)
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin
```

### Run trivy config scan

```bash
trivy config app/
```

Trivy's config mode scans Dockerfiles (and other IaC files) for security misconfigurations — running as root, exposed secrets, missing security directives.

### Break it on purpose

Open `app/Dockerfile` and change the `USER` line. Find:

```dockerfile
USER appuser
```

Change it to:

```dockerfile
USER root
```

Run both tools again:

```bash
hadolint app/Dockerfile
trivy config app/
```

Both should flag running as root. Hadolint will warn about DL3002 (last user should not be root). Trivy will flag it as a misconfiguration.

**Undo the change:**

```bash
git checkout app/Dockerfile
```

---

## Part 4: Container Build + Scan

### Build the image

```bash
docker build -t portfolio-test app/
```

This runs the same multi-stage build that CI runs. Stage 1 installs dependencies, stage 2 copies them into a clean runtime image.

### Scan the built image

```bash
trivy image portfolio-test
```

This is different from `trivy config` — it scans the actual container image for known CVEs in installed packages. The output shows vulnerabilities by severity: CRITICAL, HIGH, MEDIUM, LOW.

In CI, the pipeline fails if any CRITICAL or HIGH vulnerabilities are found:

```bash
trivy image --severity CRITICAL,HIGH --exit-code 1 portfolio-test
```

The `--exit-code 1` flag makes trivy return a non-zero exit code (failure) if it finds matches. This is how CI gates work — the tool's exit code determines pass/fail.

**Think about it:** Why does the pipeline scan the Dockerfile (stage 2) _and_ the built image (stage 4)? Because they catch different things. Hadolint/trivy-config catch bad practices in how you _write_ the Dockerfile. Trivy-image catches vulnerabilities in the packages _inside_ the resulting image. A perfectly-written Dockerfile can still produce an image with CVEs if the base image has them.

---

## Part 5: Kubernetes Validation — kubeconform

### Install kubeconform

```bash
curl -sL https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-linux-amd64.tar.gz | tar xz
sudo mv kubeconform /usr/local/bin/
```

### Validate the manifests

```bash
kubectl kustomize k8s/overlays/local | kubeconform -strict -ignore-missing-schemas -summary
```

This does two things:
1. `kubectl kustomize` renders the Kustomize overlay into plain YAML (same thing ArgoCD's repo server does)
2. `kubeconform` validates that YAML against the Kubernetes API schema — correct `apiVersion`, required fields present, correct types

The `-strict` flag rejects unknown fields (catches typos like `replicas` spelled as `replica`). The `-ignore-missing-schemas` flag skips CRDs that don't have built-in schemas.

### Break it on purpose

Edit `k8s/base/deployment.yaml`. Change the `apiVersion`:

```yaml
# Change this:
apiVersion: apps/v1
# To this:
apiVersion: apps/v999
```

Run the validation again:

```bash
kubectl kustomize k8s/overlays/local | kubeconform -strict -ignore-missing-schemas -summary
```

Kubeconform should reject it — `apps/v999` isn't a real API version. This is exactly the kind of error that CI catches before merge, preventing ArgoCD from trying to apply broken manifests.

**Undo the change:**

```bash
git checkout k8s/base/deployment.yaml
```

---

## Part 6: See It Run in GitHub

Now that you've run each tool by hand, push a commit to your fork and watch CI automate the same checks.

1. Make a small, valid change. Edit `k8s/base/configmap.yaml` — change the `BIO` field to something about you:

```bash
# Edit the file, then:
git add k8s/base/configmap.yaml
git commit -m "personalize bio"
git push
```

2. Open your fork on GitHub → **Actions** tab
3. Watch the pipeline run. You should see the stages execute in the order you studied:
   - Code Quality passes (ruff + bandit find nothing wrong)
   - Dockerfile Scan passes (hadolint + trivy find nothing wrong)
   - Build succeeds
   - Container Scan passes
   - K8s Validation passes (kubeconform approves the manifests)
   - Integration Test passes (container starts, endpoints respond)

Each green checkmark is a tool you just ran by hand. CI runs them all, every time, automatically.

---

## Checkpoint

You are done when you can:
- [ ] Name all 8 pipeline stages in order
- [ ] Explain why cheap checks run before expensive ones
- [ ] Have run 5 tools locally: ruff, bandit, hadolint, trivy, kubeconform
- [ ] Have seen red output from at least 3 tools (eval→bandit, USER root→hadolint/trivy, bad apiVersion→kubeconform)
- [ ] Have pushed a commit and watched CI run on your fork
- [ ] Can explain the difference between `trivy config` (Dockerfile scan) and `trivy image` (CVE scan)

---

## Take It Further

**`act` — run GitHub Actions locally.** The [act](https://github.com/nektos/act) tool lets you run your full GitHub Actions workflow locally via Docker. It's useful for debugging CI without pushing commits, but it adds install complexity and can hit docker-in-docker issues in Codespaces. Worth knowing about, not required for this lab.
