---
theme: default
title: Week 02 Lab 02 - Multi-Stage Build Migration
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "02"
lab: "Lab 02 · Multi-Stage Build Migration"
---

# Multi-Stage Build Migration
## Lab 02

- Measure the size impact of a single-stage Go image
- Split build and runtime with multi-stage Dockerfile
- Ship only the compiled binary in a lean runtime image
- Verify endpoints still work after optimization

---
layout: win95
windowTitle: "Single-Stage vs Multi-Stage"
windowIcon: "📦"
statusText: "Week 02 · Lab 02 · Image size and attack surface"
---

## Why the Current Image Is Huge

| Approach | Final image includes | Typical size |
|---|---|---|
| **Single-stage** | Go compiler, build cache, source, runtime | `1.0-1.2GB` |
| **Multi-stage** | Runtime base + compiled binary only | `12-18MB` |

> Build dependencies belong in builder stages, not production runtime.

---
layout: win95
windowTitle: "Dockerfile Migration"
windowIcon: "📄"
statusText: "Week 02 · Lab 02 · Builder and runtime stages"
---

## Multi-Stage Dockerfile

```dockerfile
# Stage 1: Build
FROM golang:1.21 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server .

# Stage 2: Runtime
FROM alpine:3.18

WORKDIR /app

COPY --from=builder /app/server .

EXPOSE 8080

RUN adduser -D -u 1000 appuser
USER appuser

CMD ["./server"]
```

---
layout: win95-terminal
termTitle: "Command Prompt — build and test fat image"
---

<Win95Terminal
  title="Command Prompt — single-stage baseline"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd week-02/labs/lab-02-multistage-build/starter' },
    { type: 'input', text: 'ls' },
    { type: 'input', text: 'cat main.go' },
    { type: 'comment', text: '# Optional local run if Go is installed' },
    { type: 'input', text: 'go run main.go' },
    { type: 'input', text: 'curl localhost:8080/health' },
    { type: 'input', text: 'docker build -t go-api:fat .' },
    { type: 'input', text: 'docker images go-api:fat' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — verify fat then build lean"
---

<Win95Terminal
  title="Command Prompt — fat vs lean"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker run -d -p 8080:8080 --name api-fat go-api:fat' },
    { type: 'input', text: 'curl localhost:8080/health' },
    { type: 'input', text: 'curl localhost:8080/info' },
    { type: 'input', text: 'docker rm -f api-fat' },
    { type: 'input', text: 'docker build -t go-api:lean -f Dockerfile.multistage .' },
    { type: 'input', text: 'docker images | grep go-api' },
    { type: 'output', text: 'go-api:lean    <tag>    12-18MB' },
    { type: 'output', text: 'go-api:fat     <tag>    1.0-1.2GB' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — verify lean + scratch + cleanup"
---

<Win95Terminal
  title="Command Prompt — runtime verification"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker run -d -p 8080:8080 --name api-lean go-api:lean' },
    { type: 'input', text: 'curl localhost:8080/health' },
    { type: 'input', text: 'curl localhost:8080/info' },
    { type: 'input', text: 'curl -X POST -d message=Hello localhost:8080/echo' },
    { type: 'input', text: 'docker rm -f api-lean' },
    { type: 'input', text: 'docker build -t go-api:scratch -f Dockerfile.scratch .' },
    { type: 'input', text: 'docker images | grep go-api' },
    { type: 'input', text: 'docker rmi go-api:fat go-api:lean go-api:scratch' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 02 — Key Commands"
windowIcon: "📋"
statusText: "Week 02 · Lab 02 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `cd week-02/labs/lab-02-multistage-build/starter` | Enter lab starter |
| `ls` | List starter files |
| `cat main.go` | Inspect API code |
| `go run main.go` | Run API locally (optional) |
| `curl localhost:8080/health` | Check health endpoint |
| `docker build -t go-api:fat .` | Build single-stage image |
| `docker images go-api:fat` | Show fat image size |
| `docker run -d -p 8080:8080 --name api-fat go-api:fat` | Run fat image |
| `curl localhost:8080/info` | Test info endpoint |
| `docker rm -f api-fat` | Stop/remove fat container |
| `docker build -t go-api:lean -f Dockerfile.multistage .` | Build multi-stage image |
| `docker images | grep go-api` | Compare image sizes |
| `docker run -d -p 8080:8080 --name api-lean go-api:lean` | Run lean image |
| `curl -X POST -d '{"message": "Hello"}' localhost:8080/echo` | Test echo endpoint |
| `docker rm -f api-lean` | Stop/remove lean container |
| `docker build -t go-api:scratch -f Dockerfile.scratch .` | Build scratch runtime variant |
| `docker rmi go-api:fat go-api:lean go-api:scratch` | Remove all lab images |

---
layout: win95
windowTitle: "Build Artifact Flow"
windowIcon: "🔀"
statusText: "Week 02 · Lab 02 · Multi-stage relationship"
---

## Stage-to-Stage Flow

```text
builder stage (golang:1.21)
  -> go mod download
  -> go build -o server
  -> artifact: /app/server

runtime stage (alpine:3.18)
  -> COPY --from=builder /app/server .
  -> run ./server as non-root user
```
