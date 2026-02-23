---
theme: default
title: Week 01 Lab 01 - Your First Container
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "01"
lab: "Lab 01 · Your First Container"
---
<!-- SLIDE 1 — Cover -->

# Your First Container
## Lab 01

- Pull `nginx:alpine`, run it, poke around
- Port mapping: host `8080` → container `80`
- `docker exec` to get a shell inside
- Logs, inspect, stop, remove

---
layout: win95
windowTitle: "docker run — What Actually Happens"
windowIcon: "🚀"
statusText: "Week 01 · Lab 01 · docker run decomposed"
---

## `docker run` in Three Steps

| Step | Command | What happens |
|---|---|---|
| **1 Pull** | `docker pull nginx:alpine` | Downloads layers from registry |
| **2 Create** | `docker create ...` | Allocates writeable layer, wires namespaces |
| **3 Start** | `docker start <id>` | Spawns the process (PID 1 in namespace) |

> `docker run` = pull (if needed) + create + start in one shot.

```bash
# Equivalent to docker run -d -p 8080:80 --name web nginx:alpine
docker pull nginx:alpine
docker create -p 8080:80 --name web nginx:alpine
docker start web
```

---
layout: win95-terminal
termTitle: "Command Prompt — docker pull / run / exec"
---

<Win95Terminal
  title="Command Prompt — docker"
  color="green"
  :crt="true"
  height="100%"
  :lines="[
    { type: 'comment', text: '# Pull the nginx alpine image' },
    { type: 'input',  text: 'docker pull nginx:alpine' },
    { type: 'output', text: 'alpine: Pulling from library/nginx' },
    { type: 'output', text: 'Status: Downloaded newer image for nginx:alpine' },
    { type: 'comment', text: '# Run detached, map port, give it a name' },
    { type: 'input',  text: 'docker run -d -p 8080:80 --name web nginx:alpine' },
    { type: 'output', text: 'a3f8c2e1d9b047f3c1a2b4e5d6f7g8h9i0j1' },
    { type: 'comment', text: '# Open a shell inside the running container' },
    { type: 'input',  text: 'docker exec -it web sh' },
    { type: 'success', text: '/ # cat /etc/os-release | head -2' },
    { type: 'output', text: 'NAME=Alpine Linux' },
    { type: 'output', text: 'ID=alpine' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — docker logs / ps / inspect"
---

<Win95Terminal
  title="Command Prompt — docker"
  color="green"
  :crt="true"
  height="100%"
  :lines="[
    { type: 'comment', text: '# Tail live container logs' },
    { type: 'input',  text: 'docker logs -f web' },
    { type: 'output', text: '10.0.0.1 - - [GET /] 200 ...' },
    { type: 'output', text: '10.0.0.1 - - [GET /favicon.ico] 404 ...' },
    { type: 'comment', text: '# List all containers (running + stopped)' },
    { type: 'input',  text: 'docker ps -a' },
    { type: 'output', text: 'CONTAINER ID  IMAGE          STATUS         NAMES' },
    { type: 'output', text: 'a3f8c2e1d9b0  nginx:alpine   Up 3 minutes   web' },
    { type: 'comment', text: '# Inspect networking config' },
    { type: 'input',  text: 'docker inspect web --format {{.NetworkSettings.IPAddress}}' },
    { type: 'output', text: '172.17.0.2' },
  ]"
/>

---
layout: win95
windowTitle: "Running Containers — Process View"
windowIcon: "🖥"
statusText: "Week 01 · Lab 01 · docker ps"
---

## Containers Are OS Processes

<Win95TaskManager
  title="Docker Task Manager — Running Containers"
  tab="Pods"
  :show-namespace="false"
  status-text="2 containers running | host port 8080"
  :processes="[
    { name: 'web  (nginx:alpine)',     pid: 'a3f8c2e1', cpu: 3,  memory: '12 MB',  status: 'Running'  },
    { name: 'nginx: worker process',   pid: 'a3f8c2e2', cpu: 1,  memory: '4 MB',   status: 'Running'  },
    { name: 'old-container (exited)',  pid: 'b9d12a00', cpu: 0,  memory: '0 MB',   status: 'Completed' },
  ]"
  selected-pid="a3f8c2e1"
/>

---
layout: win95
windowTitle: "Port Mapping — host:8080 → container:80"
windowIcon: "🔌"
statusText: "Week 01 · Lab 01 · -p 8080:80"
---

## Port Mapping Explained

<div style="display:flex; gap:20px; align-items:stretch; margin-top:8px; flex:1; min-height:0;">

<Win95Dialog
  type="info"
  title="Port Mapping"
  message="-p 8080:80 means: host port 8080 → container port 80"
  detail="curl http://localhost:8080 reaches nginx listening on :80 inside the container namespace."
  :buttons="['Got it']"
  :active-button="0"
  style="max-width:360px;"
/>

<div style="flex:1; display:flex; flex-direction:column; justify-content:center; gap:8px;">

### Host side
- `docker run -p **8080**:80`
- `curl localhost:**8080**` → works

### Container side
- nginx listens on `:**80**`
- That port is **not** accessible from the host directly

### Rule
`-p <host-port>:<container-port>`

</div>
</div>

---
layout: win95
windowTitle: "Lab 01 — Key Commands"
windowIcon: "📋"
statusText: "Week 01 · Lab 01 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `docker pull <image>` | Download image layers from registry |
| `docker run -d -p H:C --name N <image>` | Run detached, map ports, name it |
| `docker exec -it <name> sh` | Open interactive shell inside container |
| `docker logs -f <name>` | Stream live logs |
| `docker ps -a` | List all containers (any state) |
| `docker inspect <name>` | Full JSON metadata dump |
| `docker stop <name>` | Send SIGTERM → wait → SIGKILL |
| `docker rm <name>` | Delete stopped container |

---
layout: win95-desktop
week: "01"
lab: "Lab 02 · Build Your Python App"
---

# Build Your Python App
## Lab 02

- Write a `Dockerfile` from scratch
- `docker build` a Flask container
- Customize with environment variables
- Verify with `/health` and `/student` endpoints
