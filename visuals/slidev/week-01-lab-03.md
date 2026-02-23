---
theme: default
title: Week 01 Lab 03 - Push to Container Registries
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "01"
lab: "Lab 03 · Push to Registries"
---
<!-- SLIDE 1 — Cover -->

# Push to Registries
## Lab 03

- Tag and push to **Docker Hub**
- Tag and push to **GitHub Container Registry**
- Make your GHCR package public
- Submit the class deployment PR

---
layout: win95
windowTitle: "Container Registries — Docker Hub vs GHCR"
windowIcon: "🌐"
statusText: "Week 01 · Lab 03 · Where images live"
---

## Registry Comparison

| | Docker Hub | GitHub Container Registry |
|---|---|---|
| **URL** | `docker.io/you/image` | `ghcr.io/you/image` |
| **Auth** | Docker Hub token | GitHub PAT (`write:packages`) |
| **Free tier** | Public + 1 private | Unlimited public |
| **Class use** | Optional warm-up | **Required for submission** |
| **Namespace** | `username/image-name` | `ghcr.io/username/image-name` |

> The class cluster pulls from **GHCR**. Docker Hub is practice.

---
layout: win95-terminal
termTitle: "Command Prompt — docker push to Docker Hub"
---

<Win95Terminal
  title="Command Prompt — Docker Hub push"
  color="green"
  :crt="true"
  height="100%"
  :lines="[
    { type: 'comment', text: '# Login to Docker Hub' },
    { type: 'input',  text: 'docker login' },
    { type: 'output', text: 'Username: yourusername' },
    { type: 'output', text: 'Password: ••••••••••••' },
    { type: 'success', text: 'Login Succeeded' },
    { type: 'comment', text: '# Tag the image for Docker Hub' },
    { type: 'input',  text: 'docker tag my-python-app:v2-student yourusername/my-python-app:v2-student' },
    { type: 'comment', text: '# Push to Docker Hub' },
    { type: 'input',  text: 'docker push yourusername/my-python-app:v2-student' },
    { type: 'output', text: 'The push refers to repository [docker.io/yourusername/my-python-app]' },
    { type: 'output', text: 'v2-student: digest: sha256:9b8a... size: 1234' },
    { type: 'success', text: 'Push complete' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — docker push to GHCR"
---

<Win95Terminal
  title="Command Prompt — GHCR push"
  color="green"
  :crt="true"
  height="100%"
  :lines="[
    { type: 'comment', text: '# Login to GitHub Container Registry with PAT' },
    { type: 'input',  text: 'echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin' },
    { type: 'success', text: 'Login Succeeded' },
    { type: 'comment', text: '# Tag for GHCR (required naming for class deployment)' },
    { type: 'input',  text: 'docker tag my-python-app:v2-student ghcr.io/yourusername/container-course-student:latest' },
    { type: 'comment', text: '# Push to GHCR' },
    { type: 'input',  text: 'docker push ghcr.io/yourusername/container-course-student:latest' },
    { type: 'output', text: 'The push refers to repository [ghcr.io/yourusername/container-course-student]' },
    { type: 'output', text: 'latest: digest: sha256:9b8a... size: 1234' },
    { type: 'success', text: 'Push complete' },
  ]"
/>

---
layout: win95
windowTitle: "Image Push — Layer Upload Progress"
windowIcon: "📤"
statusText: "Week 01 · Lab 03 · Pushing layers"
---

## Pushing Layers to GHCR

<Win95TaskManager
  title="GHCR Layer Upload"
  tab="Pods"
  status-text="5 layers | 3 cached | 2 pushed"
  :processes="[
    { name: 'sha256:a3f8 — python:3.12-slim base', pid: 'L1', cpu: 0,  memory: '74 MB',  status: 'Completed' },
    { name: 'sha256:b2c1 — WORKDIR /app',           pid: 'L2', cpu: 0,  memory: '0 MB',   status: 'Completed' },
    { name: 'sha256:c9d4 — pip packages',            pid: 'L3', cpu: 0,  memory: '62 MB',  status: 'Completed' },
    { name: 'sha256:d7e2 — app source code',         pid: 'L4', cpu: 45, memory: '8 MB',   status: 'Running'   },
    { name: 'sha256:e5f0 — metadata manifest',       pid: 'L5', cpu: 0,  memory: '1 KB',   status: 'Pending'   },
  ]"
  selected-pid="L4"
/>

---
layout: win95
windowTitle: "Class Deployment — Your Container is Live!"
windowIcon: "🌍"
statusText: "Week 01 · Lab 03 · Deployed to class cluster"
---

## Submit the Deployment PR

<div style="display:flex; gap:20px; align-items:flex-start; margin-top:8px;">

<Win95Dialog
  type="info"
  title="Container Deployed!"
  message="Your container is running on the class Kubernetes cluster."
  detail="Access it at: https://yourusername.containers.class.example.com"
  :buttons="['Open URL', 'OK']"
  :active-button="1"
  style="max-width:380px;"
/>

<div style="flex:1">

### PR Checklist
1. Fork `container-gitops` repo
2. Add your YAML to `students/`
3. Set `image: ghcr.io/you/container-course-student:latest`
4. Open PR → CI deploys it
5. Visit your URL and screenshot it

### YAML snippet
```yaml
name: "Your Name"
github: "yourusername"
image: ghcr.io/yourusername/container-course-student:latest
```

</div>
</div>

---
layout: win95
windowTitle: "Lab 03 — Assignment Checklist"
windowIcon: "✅"
statusText: "Week 01 · Lab 03 · Complete"
---

## Assignment Checklist

| Step | Command | Done? |
|---|---|---|
| Build `v2-student` image | `docker build -t my-python-app:v2-student .` | |
| Push to Docker Hub | `docker push you/my-python-app:v2-student` | |
| Tag for GHCR | `docker tag ... ghcr.io/you/container-course-student:latest` | |
| Push to GHCR | `docker push ghcr.io/you/container-course-student:latest` | |
| Make GHCR package public | GitHub → Packages → Change visibility | |
| Submit deployment PR | Add YAML to `container-gitops/students/` | |
| Verify your URL works | `curl https://you.containers.class.example.com/student` | |

---
layout: win95-desktop
week: "01"
lab: "Lab 04 · Lifecycle Investigation"
---

# Lifecycle Investigation
## Lab 04

- Discover container states independently
- Experiment with `create`, `start`, `pause`, `stop`, `kill`, `rm`
- Investigate: what happens to data after `stop`? After `rm`?
- Complete the worksheet with your findings
