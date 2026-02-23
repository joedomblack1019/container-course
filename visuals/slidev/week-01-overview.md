---
theme: default
title: Week 01 - Containers Fundamentals
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "01"
lab: "Week 01 · Containers Fundamentals"
---
<!-- SLIDE 1 — Cover -->

# Containers Fundamentals
## Week 01

- Linux processes wearing **clever disguises**
- From `docker run` to your own registry push
- Four labs, one deployed app

---
layout: win95
windowTitle: "Week 01 — What Is a Container?"
windowIcon: "📦"
statusText: "Week 01 · Containers Fundamentals"
---

## What Is a Container?

| Primitive | What it does |
|---|---|
| **Namespace** | Isolates view of the OS (pid, net, mnt, user, uts) |
| **cgroup** | Caps resource use — CPU, memory, I/O |
| **Union FS** | Layered, copy-on-write filesystem |
| **Image** | Read-only filesystem snapshot |
| **Container** | A process with namespaces + cgroup + union layer |

> A container is **not a VM**. It shares the host kernel — just with blinders on.

---
layout: win95-terminal
termTitle: "Command Prompt — docker run"
---

<Win95Terminal
  title="Command Prompt — docker"
  color="green"
  :crt="true"
  height="100%"
  :lines="[
    { type: 'comment', text: '# Week 01 · Lab 01 — Your first container' },
    { type: 'input',  text: 'docker run hello-world' },
    { type: 'output', text: 'Hello from Docker!' },
    { type: 'output', text: 'This message shows that your installation appears to be working correctly.' },
    { type: 'comment', text: '# Run nginx and expose port 8080' },
    { type: 'input',  text: 'docker run -d -p 8080:80 --name web nginx:alpine' },
    { type: 'output', text: 'a3f8c2e1d9b047f3c1a2b4e5d6f7g8h9' },
    { type: 'input',  text: 'docker exec -it web sh' },
    { type: 'success', text: '/ # hostname' },
    { type: 'output', text: 'a3f8c2e1d9b0' },
    { type: 'output', text: 'Inside the container!' },
  ]"
/>

---
layout: win95
windowTitle: "Week 01 — Lab Roadmap"
windowIcon: "🗺"
statusText: "Week 01 · Four labs · ~2 hours total"
---

## Lab Roadmap

<Win95TaskManager
  title="Week 01 — Lab Queue"
  tab="Pods"
  status-text="4 labs queued | Est. 120 min"
  :processes="[
    { name: 'lab-01-first-container',          pid: 1, cpu: 0, memory: '30 min', status: 'Running'   },
    { name: 'lab-02-python-app',               pid: 2, cpu: 0, memory: '40 min', status: 'Pending'   },
    { name: 'lab-03-registries',               pid: 3, cpu: 0, memory: '20 min', status: 'Pending'   },
    { name: 'lab-04-lifecycle-investigation',  pid: 4, cpu: 0, memory: '30 min', status: 'Pending'   },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — docker build"
---

<Win95Terminal
  title="Command Prompt — docker build"
  color="amber"
  :crt="true"
  height="100%"
  :lines="[
    { type: 'comment', text: '# Week 01 · Lab 02 — Build your Python app' },
    { type: 'input',  text: 'docker build -t my-python-app:v1 .' },
    { type: 'output', text: '[1/4] FROM python:3.12-slim' },
    { type: 'output', text: '[2/4] WORKDIR /app' },
    { type: 'output', text: '[3/4] COPY requirements.txt . && pip install -r requirements.txt' },
    { type: 'output', text: '[4/4] COPY . .' },
    { type: 'success', text: 'Successfully built 7a4b9c1d2e3f' },
    { type: 'comment', text: '# Run and verify the app' },
    { type: 'input',  text: 'docker run -p 5000:5000 -e STUDENT_NAME=You my-python-app:v1' },
    { type: 'success', text: '* Running on http://0.0.0.0:5000' },
  ]"
/>

---
layout: win95
windowTitle: "Week 01 — What You Will Build"
windowIcon: "🐍"
statusText: "Week 01 · Python Flask → GHCR → class k8s cluster"
---

## End-to-End Journey

<Win95Window title="Deployment Progress — Week 01 Pipeline" style="margin-bottom:14px;">
  <div style="padding:12px; display:flex; flex-direction:column; gap:12px;">
    <Win95ProgressBar :value="100" label="Write app.py + Dockerfile"  sublabel="Lab 02 complete"              color="#006400" />
    <Win95ProgressBar :value="100" label="docker build my-python-app" sublabel="Image built locally"           color="#006400" />
    <Win95ProgressBar :value="100" label="Push to GHCR"               sublabel="ghcr.io/you/container-course"  color="#000080" />
    <Win95ProgressBar :value="66"  label="Deploy to class cluster"    sublabel="PR submitted — deploying..."  color="#000080" :animated="true" />
  </div>
</Win95Window>

<Win95Dialog
  type="info"
  title="Assignment Goal"
  message="Your Flask container will run on the class Kubernetes cluster at your unique URL."
  :buttons="['OK']"
  style="max-width:440px;"
/>

---
layout: win95
windowTitle: "Week 01 — Learning Outcomes"
windowIcon: "🎓"
statusText: "Week 01 · Complete"
---

## Learning Outcomes

| After Week 01 you can... | |
|---|---|
| Explain containers using Linux primitives | namespaces, cgroups, union FS |
| Pull and run any public container image | `docker pull`, `docker run` |
| Build a custom image from a Dockerfile | `docker build` |
| Debug running containers | `docker exec`, `docker logs` |
| Push images to Docker Hub and GHCR | `docker tag`, `docker push` |
| Describe the container lifecycle | created → running → stopped → removed |

---
layout: win95-desktop
week: "01"
lab: "Lab 01 · Your First Container"
---

# Your First Container
## Lab 01

- Pull `nginx:alpine` and run it
- Map port 8080 → 80
- Explore with `docker exec`
- Inspect logs and metadata
