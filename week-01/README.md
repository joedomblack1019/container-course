![Week 1 overview hero image](../assets/generated/week-01-overview/hero.png)

# Week 1: Container Fundamentals

## Overview

**Duration:** 3 hours  
**Format:** Lecture + Hands-on Labs  

By the end of this week, you'll understand what containers actually are (not magic, not VMs), build your first container image, and push it to a registry where others can use it.

---

## Learning Outcomes

By the end of this class, you will be able to:

1. Explain what a container is using Linux primitives (namespaces, cgroups)
2. Articulate why containers exist and what problems they solve
3. Pull, run, and inspect containers from public registries
4. Build a container image from a Dockerfile
5. Push images to Docker Hub and GitHub Container Registry
6. Use `docker exec` and `docker logs` to debug running containers

---

## Pre-Class Setup

Choose ONE of the following environments:

### Option A: GitHub Codespaces (Recommended)

1. Fork this repository to your GitHub account
2. Click **Code** → **Codespaces** → **Create codespace on main**
3. Wait for the environment to build (~2-3 minutes)
4. Verify: `docker run hello-world`

### Option B: Local VM with Docker CE

Follow the [Docker CE Installation Guide](./INSTALL-DOCKER.md) for Rocky Linux 8.

---

## Class Agenda

| Time | Topic | Type |
|------|-------|------|
| 0:00 - 0:30 | The Deployment Problem: Why Containers Exist | Lecture |
| 0:30 - 0:45 | Containers vs VMs: What's Actually Happening | Lecture |
| 0:45 - 1:15 | **Lab 1:** First Container - Pull, Run, Explore | Hands-on |
| 1:15 - 1:30 | Break | — |
| 1:30 - 1:50 | Dockerfile Anatomy: Building Images | Lecture |
| 1:50 - 2:30 | **Lab 2:** Build Your Python App Container | Hands-on |
| 2:30 - 2:50 | **Lab 3:** Push to Docker Hub & GHCR | Hands-on |
| 2:50 - 3:00 | Wrap-up & Homework Introduction | — |

---

## Key Concepts

### The Deployment Problem

Before containers, deploying software was painful:

```
Developer: "It works on my machine!"
Ops: "Well, your machine isn't in production."
```

The problems:
- Different OS versions, libraries, configurations between dev and prod
- "Works on my machine" syndrome
- Dependency conflicts ("DLL hell", Python version mismatches)
- Slow, error-prone deployments

Containers solve this by packaging the application AND its environment together.

### Containers vs Virtual Machines

**Virtual Machines** virtualize hardware:
```
┌─────────────────────────────────────────┐
│            Your Application             │
├─────────────────────────────────────────┤
│           Guest OS (Linux)              │  ← Full OS copy
├─────────────────────────────────────────┤
│              Hypervisor                 │
├─────────────────────────────────────────┤
│           Host OS / Hardware            │
└─────────────────────────────────────────┘
```

**Containers** virtualize the operating system:
```
┌──────────┐ ┌──────────┐ ┌──────────┐
│  App A   │ │  App B   │ │  App C   │
├──────────┤ ├──────────┤ ├──────────┤
│ Bins/Libs│ │ Bins/Libs│ │ Bins/Libs│
└──────────┴─┴──────────┴─┴──────────┘
┌─────────────────────────────────────────┐
│           Container Runtime             │
├─────────────────────────────────────────┤
│         Host OS (shared kernel)         │
└─────────────────────────────────────────┘
```

Key differences:
| Aspect | VM | Container |
|--------|----|-----------| 
| Boot time | Minutes | Seconds |
| Size | GBs | MBs |
| Isolation | Hardware-level | Process-level |
| Kernel | Own kernel | Shared with host |
| Overhead | High | Low |

### How Containers Work (Linux Primitives)

Containers aren't magic—they're built on Linux kernel features:

**Namespaces** - Isolation of what a process can *see*:
- `pid` - Process IDs (container sees its own process tree)
- `net` - Network interfaces (container has its own network stack)
- `mnt` - Mount points (container has its own filesystem view)
- `user` - User IDs (root in container ≠ root on host)
- `uts` - Hostname (container has its own hostname)

**cgroups** - Limits on what a process can *use*:
- CPU limits
- Memory limits  
- I/O bandwidth
- Process count

**Union Filesystem** - Layered, copy-on-write filesystem:
- Base image is read-only
- Changes write to a new layer
- Efficient storage and sharing

### Docker CLI Mental Model

```bash
# These are equivalent:
docker run nginx
# equals
docker create nginx + docker start <container>

# Common patterns:
docker run nginx              # Runs in foreground, see output
docker run -d nginx           # Runs detached (background)
docker run -it ubuntu bash    # Interactive terminal
docker run -p 8080:80 nginx   # Map host port 8080 to container port 80
```

---

## Labs

### Lab 1: First Container

📁 See [labs/lab-01-first-container/](./labs/lab-01-first-container/)

You'll:
- Pull and run an nginx container
- Explore the running container with `exec`
- View logs and inspect container details
- Understand port mapping

### Lab 2: Build Your Python App

📁 See [labs/lab-02-python-app/](./labs/lab-02-python-app/)

You'll:
- Examine a simple Python application
- Write a Dockerfile from scratch
- Build and tag your image
- Run your containerized application
- Customize the app and rebuild

### Lab 3: Push to Registries

📁 See [labs/lab-03-registries/](./labs/lab-03-registries/)

You'll:
- Create accounts on Docker Hub and understand GHCR
- Authenticate to both registries
- Tag and push your image
- Pull your image on a different machine (or fresh environment)

---

## Discovery Questions

Answer these in your own words after completing the labs:

1. What happens if you run `docker run nginx` without the `-d` flag? Why might you want each behavior?

2. When you ran `docker exec -it <container> /bin/sh`, you got a shell inside the container. Is this a new process? What namespace(s) is it joining?

3. You built an image and it was ~150MB. The base Python image is ~120MB. Where did the other ~30MB come from? How could you see the layers?

4. If you delete a running container (`docker rm -f`), what happens to:
   - The running process?
   - Any files written inside the container?
   - The image you built?

5. What's the difference between `docker push myapp:latest` and `docker push ghcr.io/username/myapp:latest`? Where does each go?

---

## Homework

Complete these exercises in the container-gym before next class:

| Exercise | Time | Focus |
|----------|------|-------|
| `container-lifecycle` | 15 min | Start, stop, restart, remove, logs |
| `port-mapping-puzzle` | 20 min | Expose containers correctly |
| `exec-detective` | 15 min | Debug a misbehaving container |

To start: `gym start container-lifecycle`

---

## Resources

### Required Reading
- [Docker Overview](https://docs.docker.com/get-started/overview/) - Official Docker concepts

### Reference
- [Dockerfile Reference](https://docs.docker.com/engine/reference/dockerfile/)
- [Docker CLI Reference](https://docs.docker.com/engine/reference/commandline/cli/)
- [GitHub Container Registry Docs](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

### Deep Dive (Optional)
- [What even is a container?](https://www.youtube.com/watch?v=8fi7uSYlOdc) - Liz Rice live-codes a container from scratch
- [Namespaces in Go](https://medium.com/@teddyking/linux-namespaces-850489d3ccf) - Understanding the primitives

---

## Next Week Preview

In Week 2, we'll focus on **Dockerfile Mastery**:
- Layer caching and why instruction order matters
- Multi-stage builds for smaller, more secure images
- Security scanning with Trivy
- The image size challenge: from 1GB to <100MB
