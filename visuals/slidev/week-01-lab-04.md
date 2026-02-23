---
theme: default
title: Week 01 Lab 04 - Container Lifecycle Investigation
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "01"
lab: "Lab 04 · Lifecycle Investigation"
---
<!-- SLIDE 1 — Cover -->

# Lifecycle Investigation
## Lab 04

- Discover container states **on your own**
- Trace the full lifecycle: create → run → pause → stop → rm
- Answer: what survives a stop? What survives an rm?
- Complete the worksheet with evidence

---
layout: win95
windowTitle: "Container State Machine"
windowIcon: "♻"
statusText: "Week 01 · Lab 04 · States and transitions"
---

## Container States

| State | How you get there | What's running |
|---|---|---|
| **created** | `docker create` | Nothing — namespace allocated |
| **running** | `docker start` / `docker run` | PID 1 alive |
| **paused** | `docker pause` | Frozen — cgroup SIGSTOP |
| **stopped** | `docker stop` (SIGTERM → SIGKILL) | PID 1 dead, layer preserved |
| **removed** | `docker rm` | Gone — writable layer deleted |

```
docker create ──▶ [created]
                      │ docker start
                      ▼
              ┌── [running] ──┐ docker pause
              │               ▼
              │          [paused] ──▶ docker unpause ──▶ [running]
              │ docker stop / kill
              ▼
          [stopped/exited] ──▶ docker rm ──▶ [removed]
```

---
layout: win95-terminal
termTitle: "Command Prompt — lifecycle commands"
---

<Win95Terminal
  title="Command Prompt — docker lifecycle"
  color="green"
  :crt="true"
  height="100%"
  :lines="[
    { type: 'comment', text: '# Create without starting' },
    { type: 'input',  text: 'docker create --name test-life alpine sleep 300' },
    { type: 'output', text: 'f1e2d3c4b5a6...' },
    { type: 'input',  text: 'docker ps -a --filter name=test-life --format {{.Status}}' },
    { type: 'output', text: 'Created' },
    { type: 'comment', text: '# Start it' },
    { type: 'input',  text: 'docker start test-life && docker ps --filter name=test-life --format {{.Status}}' },
    { type: 'output', text: 'Up Less than a second' },
    { type: 'comment', text: '# Pause and verify' },
    { type: 'input',  text: 'docker pause test-life && docker ps --filter name=test-life --format {{.Status}}' },
    { type: 'output', text: 'Up 4 seconds (Paused)' },
    { type: 'comment', text: '# Unpause, stop, remove' },
    { type: 'input',  text: 'docker unpause test-life && docker stop test-life && docker rm test-life' },
    { type: 'success', text: 'test-life' },
  ]"
/>

---
layout: win95
windowTitle: "Containers in All States — Task Manager"
windowIcon: "🖥"
statusText: "Week 01 · Lab 04 · docker ps -a"
---

## All Lifecycle States at Once

<Win95TaskManager
  title="Docker Task Manager — All States"
  tab="Pods"
  status-text="5 containers | 1 running | 1 paused | 2 exited | 1 created"
  :processes="[
    { name: 'web         (nginx:alpine)',  pid: 'a1b2', cpu: 3,  memory: '12 MB', status: 'Running'    },
    { name: 'frozen-job  (alpine)',        pid: 'c3d4', cpu: 0,  memory: '1 MB',  status: 'Pending'    },
    { name: 'crashed-app (my-app:v1)',     pid: 'e5f6', cpu: 0,  memory: '0 MB',  status: 'Error'      },
    { name: 'old-task    (busybox)',       pid: 'g7h8', cpu: 0,  memory: '0 MB',  status: 'Completed'  },
    { name: 'not-started (alpine)',        pid: 'i9j0', cpu: 0,  memory: '0 MB',  status: 'Pending'    },
  ]"
  selected-pid="a1b2"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — data persistence experiment"
---

<Win95Terminal
  title="Command Prompt — data persistence"
  color="amber"
  :crt="true"
  height="100%"
  :lines="[
    { type: 'comment', text: '# Write a file inside a running container' },
    { type: 'input',  text: 'docker run -d --name data-test alpine sleep 300' },
    { type: 'input',  text: 'docker exec data-test sh -c echo hello > /tmp/myfile.txt' },
    { type: 'input',  text: 'docker exec data-test cat /tmp/myfile.txt' },
    { type: 'success', text: 'hello' },
    { type: 'comment', text: '# Stop and restart — data survives stop' },
    { type: 'input',  text: 'docker stop data-test && docker start data-test' },
    { type: 'input',  text: 'docker exec data-test cat /tmp/myfile.txt' },
    { type: 'success', text: 'hello' },
    { type: 'comment', text: '# Remove — data is gone forever' },
    { type: 'input',  text: 'docker rm data-test && docker run --rm alpine cat /tmp/myfile.txt' },
    { type: 'error',  text: 'cat: /tmp/myfile.txt: No such file or directory' },
  ]"
/>

---
layout: win95
windowTitle: "Data Persistence — What Survives?"
windowIcon: "💾"
statusText: "Week 01 · Lab 04 · Writable container layer"
---

## Data Survival Rules

<div style="display:flex; gap:20px; align-items:flex-start; margin-top:8px;">

<Win95Dialog
  type="question"
  title="Lifecycle Investigation"
  message="Does data written inside a container survive a docker stop?"
  detail="YES — the writable layer persists until docker rm. Data is lost only on removal."
  :buttons="['Yes', 'No']"
  :active-button="0"
  style="max-width:360px;"
/>

<div style="flex:1">

| Event | Writable layer | Image layers |
|---|---|---|
| `docker stop` | **Preserved** | Preserved |
| `docker start` | **Preserved** | Preserved |
| `docker rm` | **Deleted** | Preserved |
| `docker rmi` | N/A | **Deleted** |

### To persist data across `rm`
- Mount a **volume**: `docker run -v mydata:/data`
- Mount a **bind mount**: `docker run -v $(pwd):/data`

</div>
</div>

---
layout: win95
windowTitle: "Lab 04 — Worksheet Key Findings"
windowIcon: "📝"
statusText: "Week 01 · Lab 04 · Complete your worksheet"
---

## Worksheet: Key Questions

| Question | Hint command | Your answer |
|---|---|---|
| What states exist? | `docker ps -a --format "{{.Status}}"` | |
| What exits on `docker stop`? | `docker inspect` + `docker stats` | |
| Data after `stop`? | write → stop → start → check | |
| Data after `rm`? | write → rm → new container → check | |
| Difference: `stop` vs `kill`? | compare exit codes + timing | |
| Image vs container count? | `docker images` vs `docker ps -a` | |

> Complete the `WORKSHEET.md` in `lab-04-lifecycle-investigation/` with your findings and evidence.

---
layout: win95-desktop
week: "02"
lab: "Week 02 · Image Layers & Optimization"
---

# Image Layers & Optimization
## Week 02

- Why layer order **dramatically** affects build speed
- Multi-stage builds to shrink final image size
- Trivy: scanning images for known CVEs
