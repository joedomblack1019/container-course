![Lab 3 hero image](../../../assets/generated/week-01-lab-03/hero.png)

# Lab 3: Push to Container Registries

**Time:** 20 minutes  
**Objective:** Push your container image to Docker Hub and GitHub Container Registry

---

## Overview

Container registries are like GitHub for container images. They store and distribute images so others can pull them.

We'll use two registries:
- **Docker Hub** - The default public registry, widely used
- **GitHub Container Registry (GHCR)** - Integrated with GitHub, great for projects

---

## Background: How Container Registries Work

A registry stores image content as immutable layers plus a manifest that lists which layers make up a tagged image. When you push, Docker uploads only layers the registry does not already have, then publishes the tag by writing or updating the manifest reference. That is why pushes can be fast after small changes and why you often see "layer already exists" during uploads.

A tag is a movable pointer, not a cryptographic identity. `my-app:v1` can be retagged to different content later unless your team enforces immutability policies, while a digest like `@sha256:...` uniquely identifies exact bytes. In production systems, tags are convenient for humans and digests are safer for deterministic deployments.

Auth and authorization are separate concerns here. `docker login` stores credentials locally, but actual push or pull permissions come from registry-side policies tied to your account or token scopes. In AWS terms, this is similar to authenticating your CLI and then being allowed or denied by ECR/IAM policy for a specific repository action.

Docker Hub and GHCR both implement OCI distribution, so the mechanics are the same even though account model and defaults differ. Docker Hub defaults to a global namespace model, while GHCR aligns image access with GitHub users, orgs, and repository permissions. The command sequence in this lab is mostly about naming and credentials, not different image formats.

Keep one practical rule in mind as you work: push once, then verify by pulling into a clean local state so you know the registry copy is truly usable by other systems. For deeper reference, see the Docker registry documentation: https://docs.docker.com/docker-hub/repos/.

---

## Part 1: Docker Hub

### Create a Docker Hub Account

1. Go to [hub.docker.com](https://hub.docker.com)
2. Sign up for a free account
3. Remember your username—you'll need it for tagging images

### Login to Docker Hub

```bash
docker login
```

Enter your Docker Hub username and password when prompted.

> **Security Note:** This stores credentials in `~/.docker/config.json`. In production, use credential helpers or CI/CD secrets.

### Tag Your Image for Docker Hub

Docker Hub images follow the format: `username/image-name:tag`

```bash
# Replace YOUR_DOCKERHUB_USERNAME with your actual username
docker tag my-python-app:v1 YOUR_DOCKERHUB_USERNAME/my-python-app:v1
```

For example, if your username is `jsmith`:
```bash
docker tag my-python-app:v1 jsmith/my-python-app:v1
```

### Push to Docker Hub

```bash
docker push YOUR_DOCKERHUB_USERNAME/my-python-app:v1
```

Watch the layers upload! If a layer already exists in the registry, it skips uploading (deduplication).

### Verify on Docker Hub

1. Go to [hub.docker.com](https://hub.docker.com)
2. Click on your profile → Repositories
3. You should see `my-python-app`

### Pull It Back (Test)

Let's verify by removing the local image and pulling:

```bash
# Remove local images
docker rmi YOUR_DOCKERHUB_USERNAME/my-python-app:v1
docker rmi my-python-app:v1

# Pull from Docker Hub
docker pull YOUR_DOCKERHUB_USERNAME/my-python-app:v1

# Run it
docker run -d --name test -p 5000:5000 YOUR_DOCKERHUB_USERNAME/my-python-app:v1
curl localhost:5000

# Clean up
docker rm -f test
```

It works! Your image is now publicly available.

---

## Part 2: GitHub Container Registry (GHCR)

GHCR is integrated with GitHub and is great for projects because:
- Images can be linked to repositories
- Access control follows GitHub permissions
- No separate account needed

### Authenticate with GHCR

You'll need a GitHub Personal Access Token (PAT) with `write:packages` permission.

#### Create a PAT:

1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a name like "Container Registry"
4. Select scopes:
   - `write:packages` (this also grants `read:packages`)
   - `delete:packages` (optional, for cleanup)
5. Click "Generate token"
6. **Copy the token immediately** - you won't see it again!

#### Login to GHCR:

```bash
# Replace YOUR_GITHUB_USERNAME and YOUR_TOKEN
echo "YOUR_TOKEN" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin
```

For example:
```bash
echo "ghp_abc123..." | docker login ghcr.io -u jsmith --password-stdin
```

**In Codespaces:** You're already authenticated! Try:
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin
```

### Tag Your Image for GHCR

GHCR images follow the format: `ghcr.io/username/image-name:tag`

```bash
docker tag my-python-app:v1 ghcr.io/YOUR_GITHUB_USERNAME/my-python-app:v1
```

### Push to GHCR

```bash
docker push ghcr.io/YOUR_GITHUB_USERNAME/my-python-app:v1
```

### Verify on GitHub

1. Go to your GitHub profile → Packages
2. Or go to `github.com/YOUR_USERNAME?tab=packages`
3. You should see `my-python-app`

### Make the Package Public (Optional)

By default, GHCR packages are private. To make it public:

1. Go to the package on GitHub
2. Click "Package settings"
3. Scroll to "Danger Zone"
4. Click "Change visibility" → Public

---

## Part 3: Assignment - Push Your Student Container (REQUIRED)

**⚠️ IMPORTANT: This section is required for completing the week's assignment!**

You must push your containerized application (with your name from Lab 2) to GHCR in your forked repository. This will be used for the cluster deployment where all student containers will run together.

### Step 1: Verify Your Container Has Your Name

First, ensure your container from Lab 2 includes your student information:

```bash
# Run your container from Lab 2
docker run -d --name test -p 5000:5000 my-python-app:v2-student

# Verify your name appears
curl localhost:5000/student

# Should show:
# {"name": "Your Name", "github_username": "your-username", "container_tag": "v2-student"}

docker rm -f test
```

**If your name shows "YOUR_NAME_HERE", go back to Lab 2 Part 6 and complete it first!**

### Step 2: Tag for Your Fork's GHCR

Use this exact naming pattern (required for the cluster deployment):

```bash
# Replace YOUR_GITHUB_USERNAME with your actual GitHub username
docker tag my-python-app:v2-student ghcr.io/YOUR_GITHUB_USERNAME/container-course-student:latest
docker tag my-python-app:v2-student ghcr.io/YOUR_GITHUB_USERNAME/container-course-student:v2-student
```

### Step 3: Push to GHCR

```bash
# Login if not already
echo "YOUR_PAT" | docker login ghcr.io -u YOUR_GITHUB_USERNAME --password-stdin

# Push both tags
docker push ghcr.io/YOUR_GITHUB_USERNAME/container-course-student:latest
docker push ghcr.io/YOUR_GITHUB_USERNAME/container-course-student:v2-student
```

### Step 4: Make Your Package Public

**This is required so the cluster can pull your image!**

1. Go to your GitHub profile → Packages
2. Click on `container-course-student`
3. Click "Package settings"
4. Scroll to "Danger Zone"
5. Click "Change visibility" → **Public**
6. Confirm by typing the package name

### Step 5: Verify Your Image URL

Test that your image is publicly accessible:

```bash
# This should work without authentication
docker logout ghcr.io
docker pull ghcr.io/YOUR_GITHUB_USERNAME/container-course-student:latest
```

### Step 6: Record Your Image URL

Save this URL - you'll need it for the PR submission:
```
ghcr.io/YOUR_GITHUB_USERNAME/container-course-student:latest
```

---

## Part 4: Submit Your Container to the Class Deployment (REQUIRED)

After pushing your container to GHCR, you need to submit it to the master deployment list. All student containers will be deployed to a Kubernetes cluster where you can see everyone's work running together!

### Step 1: Fork the Deployment Repository

1. Go to: `https://github.com/ziyotek-edu/container-gitops`
2. Click "Fork" to create your own copy
3. Clone your fork locally:

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/container-gitops
cd container-gitops
```

### Step 2: Add Your Container to the Deployment List

Edit the `students/week-01.yaml` file and add your entry:

```yaml
students:
  # ... existing entries ...

  - name: "Your Full Name"
    github_username: "your-github-username"
    container_image: "ghcr.io/your-github-username/container-course-student:latest"
    student_endpoint: "/student"
    health_endpoint: "/health"
    port: 5000
```

### Step 3: Create a Pull Request

```bash
# Create a new branch
git checkout -b add-YOUR_GITHUB_USERNAME-week01

# Add your changes
git add students/week-01.yaml

# Commit with a descriptive message
git commit -m "Add YOUR_NAME to Week 01 deployment list"

# Push to your fork
git push origin add-YOUR_GITHUB_USERNAME-week01
```

### Step 4: Open the Pull Request

1. Go to your fork on GitHub
2. Click "Pull requests" → "New pull request"
3. Ensure it's going from your branch to the main repo's main branch
4. Title: "Add [Your Name] - Week 01 Submission"
5. Description should include:
   - Your container URL
   - Confirmation that `/student` endpoint works
   - Any special notes about your implementation

### Step 5: Verify Your Deployment

Once your PR is merged, your container will be automatically deployed! You can check:

1. **Your App**: `https://container-course.lab.shart.cloud/students/YOUR_GITHUB_USERNAME`
2. **Class Gallery**: `https://container-course.lab.shart.cloud/gallery`

The cluster will:
- Pull your container from GHCR
- Deploy it with proper resource limits
- Expose it at a unique URL
- Monitor health via your `/health` endpoint
- Display your info from `/student` in the gallery

---

## Part 5: The Full Tagging Strategy

In real projects, you typically push multiple tags:

```bash
# Build the image
docker build -t my-python-app:v1.2.3 .

# Tag with multiple variants
docker tag my-python-app:v1.2.3 ghcr.io/user/my-python-app:v1.2.3
docker tag my-python-app:v1.2.3 ghcr.io/user/my-python-app:v1.2
docker tag my-python-app:v1.2.3 ghcr.io/user/my-python-app:v1
docker tag my-python-app:v1.2.3 ghcr.io/user/my-python-app:latest

# Push all tags
docker push ghcr.io/user/my-python-app:v1.2.3
docker push ghcr.io/user/my-python-app:v1.2
docker push ghcr.io/user/my-python-app:v1
docker push ghcr.io/user/my-python-app:latest
```

This allows users to:
- Pin to exact version: `v1.2.3` (safest, won't change)
- Float on patch: `v1.2` (gets `v1.2.4`, `v1.2.5`, etc.)
- Float on minor: `v1` (gets `v1.3.0`, `v1.4.0`, etc.)
- Always latest: `latest` (dangerous in production!)

---

## Part 5: Pulling Images in CI/CD (Preview)

In Week 8, we'll set up GitHub Actions to build and push automatically. Here's a preview:

```yaml
# .github/workflows/build.yaml
name: Build and Push

on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Login to GHCR
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and Push
        uses: docker/build-push-action@v5
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}/my-app:${{ github.sha }}
```

No hardcoded credentials—GitHub provides them automatically!

---

## Checkpoint ✅

Before moving on, verify you have completed:

**Required for Assignment:**
- [ ] **Your container includes your name (from Lab 2)**
- [ ] **Pushed your student container to GHCR**
- [ ] **Made your GHCR package public**
- [ ] **Submitted PR to deployment repository**
- [ ] **Your container URL is: ghcr.io/YOUR_USERNAME/container-course-student:latest**

**Skills Learned:**
- [ ] Login to Docker Hub
- [ ] Tag and push an image to Docker Hub
- [ ] Login to GHCR with a PAT (or Codespaces token)
- [ ] Tag and push an image to GHCR
- [ ] Explain the difference between Docker Hub and GHCR
- [ ] View your packages on GitHub

---

## Clean Up

You can leave the images in the registries—they're useful for future labs!

Locally, clean up:
```bash
docker rm -f $(docker ps -aq) 2>/dev/null || true
docker system prune -f
```

---

## Common Issues

### "denied: permission denied"

- Docker Hub: Check you're logged in (`docker login`)
- GHCR: Check your PAT has `write:packages` scope
- GHCR: Image path must start with `ghcr.io/YOUR_USERNAME/`

### "unauthorized: authentication required"

Login expired. Run `docker login` or `docker login ghcr.io` again.

### "name unknown: repository does not exist"

The image path is wrong. Double-check:
- Docker Hub: `username/image:tag`
- GHCR: `ghcr.io/username/image:tag`

---

## Summary

| Registry | Image Format | Login Command |
|----------|--------------|---------------|
| Docker Hub | `username/image:tag` | `docker login` |
| GHCR | `ghcr.io/username/image:tag` | `docker login ghcr.io` |

Both registries:
- Store layers efficiently (deduplication)
- Support public and private images
- Work with `docker pull` and `docker push`

GHCR advantages:
- Integrated with GitHub permissions
- `GITHUB_TOKEN` works in Actions (no secrets to manage)
- Packages linked to repos

Docker Hub advantages:
- Default registry (no prefix needed for pull)
- Larger ecosystem of public images
- Official images for popular software

---

## Demo

![Container Registries Demo](../../../assets/generated/week-01-lab-03/demo.gif)

---

## Next Steps

You've completed Week 1! 🎉

For homework:
- Complete the gym exercises: `container-lifecycle`, `port-mapping-puzzle`, `exec-detective`
- Review the Discovery Questions in the main README
- Read the [Docker Overview](https://docs.docker.com/get-started/overview/) if you haven't

Next week, we'll dive into **Dockerfile Mastery**: layer caching, multi-stage builds, and security scanning.
