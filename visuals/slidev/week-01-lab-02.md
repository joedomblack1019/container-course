---
theme: default
title: Week 01 Lab 02 - Build Your Python App
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "01"
lab: "Lab 02 · Build Your Python App"
---
<!-- SLIDE 1 — Cover -->

# Build Your Python App
## Lab 02

- Write a `Dockerfile` from a base image
- Build a containerized Flask app
- Customize with environment variables
- Push a tagged image for submission

---
layout: win95
windowTitle: "Dockerfile — Anatomy"
windowIcon: "📄"
statusText: "Week 01 · Lab 02 · Dockerfile instructions"
---

## Dockerfile Anatomy

| Instruction | Purpose |
|---|---|
| `FROM python:3.12-slim` | Base image — the starting layer |
| `WORKDIR /app` | Set working directory for all following steps |
| `COPY requirements.txt .` | Copy dependency list first (cache layer) |
| `RUN pip install -r requirements.txt` | Install deps — cached if requirements unchanged |
| `COPY . .` | Copy app source code |
| `EXPOSE 5000` | Document the port (hint, not a firewall rule) |
| `CMD ["python", "app.py"]` | Default command when container starts |

> Order matters: stable layers first, frequently-changing layers last.

---
layout: win95-terminal
termTitle: "Command Prompt — docker build"
---

<Win95Terminal
  title="Command Prompt — docker build"
  color="green"
  :crt="true"
  height="100%"
  :lines="[
    { type: 'comment', text: '# Build the image from the current directory' },
    { type: 'input',  text: 'docker build -t my-python-app:v1 .' },
    { type: 'output', text: '[1/5] FROM python:3.12-slim' },
    { type: 'output', text: '[2/5] WORKDIR /app' },
    { type: 'output', text: '[3/5] COPY requirements.txt .' },
    { type: 'output', text: '[4/5] RUN pip install -r requirements.txt' },
    { type: 'output', text: '[5/5] COPY . .' },
    { type: 'success', text: 'Successfully built 7a4b9c1d2e3f' },
    { type: 'success', text: 'Successfully tagged my-python-app:v1' },
    { type: 'comment', text: '# List images' },
    { type: 'input',  text: 'docker images my-python-app' },
    { type: 'output', text: 'REPOSITORY       TAG   IMAGE ID      SIZE' },
    { type: 'output', text: 'my-python-app    v1    7a4b9c1d2e3f  148MB' },
  ]"
/>

---
layout: win95
windowTitle: "docker build — Layer Cache"
windowIcon: "📦"
statusText: "Week 01 · Lab 02 · Build layers"
---

## Build Layers — Cached vs Rebuilt

<Win95Window title="docker build — Layer Progress" style="margin-bottom:14px;">
  <div style="padding:12px; display:flex; flex-direction:column; gap:11px;">
    <Win95ProgressBar :value="100" label="FROM python:3.12-slim"              sublabel="CACHED — unchanged base"              color="#808080" />
    <Win95ProgressBar :value="100" label="WORKDIR /app"                       sublabel="CACHED — no change"                   color="#808080" />
    <Win95ProgressBar :value="100" label="COPY requirements.txt + pip install" sublabel="CACHED — deps unchanged"             color="#808080" />
    <Win95ProgressBar :value="100" label="COPY . ."                           sublabel="REBUILT — source changed"             color="#000080" />
    <Win95ProgressBar :value="100" label="Image tagged my-python-app:v1"      sublabel="Done — 148 MB"                       color="#006400" />
  </div>
</Win95Window>

> Cache breaks at the first changed layer — everything after rebuilds.
> Put `COPY requirements.txt` **before** `COPY . .` to keep pip cached.

---
layout: win95-terminal
termTitle: "Command Prompt — docker run (Flask app)"
---

<Win95Terminal
  title="Command Prompt — docker run"
  color="amber"
  :crt="true"
  height="100%"
  :lines="[
    { type: 'comment', text: '# Run app with your name and a custom greeting' },
    { type: 'input',  text: 'docker run -d -p 5000:5000 -e STUDENT_NAME=Alex --name flask-app my-python-app:v1' },
    { type: 'output', text: 'c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6g7' },
    { type: 'comment', text: '# Verify the app is alive' },
    { type: 'input',  text: 'curl http://localhost:5000/health' },
    { type: 'success', text: '{status: ok, student: Alex}' },
    { type: 'comment', text: '# Check student endpoint' },
    { type: 'input',  text: 'curl http://localhost:5000/student' },
    { type: 'success', text: '{name: Alex, env: development, port: 5000}' },
  ]"
/>

---
layout: win95
windowTitle: "Image vs Container"
windowIcon: "🔍"
statusText: "Week 01 · Lab 02 · Image = blueprint, Container = instance"
---

## Image vs Container

<div style="display:flex; gap:20px; align-items:flex-start; margin-top:8px;">

<Win95Dialog
  type="info"
  title="Key Distinction"
  message="An image is a read-only blueprint. A container is a running instance of that image."
  detail="You can run many containers from one image. Each gets its own writable layer on top."
  :buttons="['OK']"
  :active-button="0"
  style="max-width:360px;"
/>

<div style="flex:1">

### Image (read-only)
```
my-python-app:v1
├── python:3.12-slim layer
├── /app workdir layer
├── pip packages layer
└── source code layer
```

### Container (writable layer on top)
```
my-python-app:v1 + thin R/W layer
```
- All writes go to R/W layer
- Deleted on `docker rm`

</div>
</div>

---
layout: win95
windowTitle: "Lab 02 — Submission: Tag v2"
windowIcon: "🏷"
statusText: "Week 01 · Lab 02 · Tag with your student name"
---

## Submission Tag

```bash
# Add your name to the image
docker build \
  --build-arg STUDENT_NAME="Your Name" \
  -t my-python-app:v2-student \
  .

# Verify the tag
docker images my-python-app
# REPOSITORY      TAG          IMAGE ID      SIZE
# my-python-app   v2-student   9b8a7c6d5e4f  148MB
# my-python-app   v1           7a4b9c1d2e3f  148MB
```

> Label your image `v2-student` before pushing in Lab 03.

---
layout: win95-desktop
week: "01"
lab: "Lab 03 · Push to Registries"
---

# Push to Registries
## Lab 03

- Tag your image for Docker Hub and GHCR
- `docker login` to both registries
- Push `my-python-app:v2-student`
- Submit PR to deploy to the class cluster
