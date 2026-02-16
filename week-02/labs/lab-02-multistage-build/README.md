# Lab 2: Multi-Stage Build Migration

**Time:** 30 minutes  
**Goal:** Convert a 1GB+ Go application image to under 20MB using multi-stage builds

---

## The Problem

You have a simple Go web API. The current Dockerfile includes the entire Go toolchain in the final image. This means:
- **Large image:** 1GB+ for a 10MB binary
- **Slow deployments:** Pulling 1GB across the network
- **Security risk:** Compilers and build tools in production
- **Wasted resources:** 99% of the image is unused at runtime

Your job: Use multi-stage builds to ship only what's needed.

---

## Setup

```bash
cd week-02/labs/lab-02-multistage-build/starter
ls
```

You'll see:
- `main.go` - Simple web API
- `go.mod` - Go module definition
- `Dockerfile` - **Single-stage build (the problem)**

---

## Part 1: Understand the Application

### Examine the Code

```bash
cat main.go
```

It's a simple REST API with:
- Health check endpoint (`/health`)
- Info endpoint (`/info`)
- Echo endpoint (`/echo`)

### Test It Locally (Optional)

If you have Go installed:

```bash
go run main.go
# In another terminal:
curl localhost:8080/health
```

---

## Part 2: Build the Fat Image

### Build with the Single-Stage Dockerfile

```bash
docker build -t go-api:fat .
```

### Check the Size

```bash
docker images go-api:fat
```

**Result:** Probably 1.0-1.2GB! 😱

### But Does It Work?

```bash
docker run -d -p 8080:8080 --name api-fat go-api:fat

curl localhost:8080/health
curl localhost:8080/info

docker rm -f api-fat
```

It works... but at what cost?

---

## Part 3: Analyze the Problem

Look at the current Dockerfile:

```dockerfile
FROM golang:1.21

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o server .

EXPOSE 8080

CMD ["./server"]
```

**What's included in this image?**
- Full Go compiler and toolchain (~800MB)
- Build cache and intermediate files
- Source code (not needed at runtime)
- All of Debian (golang image is based on Debian)

**What do we actually need at runtime?**
- Just the compiled `server` binary (~10MB)

---

## Part 4: Create a Multi-Stage Build

Create a new file: `Dockerfile.multistage`

### Stage 1: Builder

```dockerfile
# Stage 1: Build the application
FROM golang:1.21 AS builder

WORKDIR /app

# Copy dependency files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the binary
# CGO_ENABLED=0 creates a static binary (no C library dependencies)
# -ldflags="-w -s" strips debug info for smaller binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server .
```

### Stage 2: Runtime

```dockerfile
# Stage 2: Create minimal runtime image
FROM alpine:3.18

WORKDIR /app

# Copy ONLY the compiled binary from builder stage
COPY --from=builder /app/server .

EXPOSE 8080

# Run as non-root for security
RUN adduser -D -u 1000 appuser
USER appuser

CMD ["./server"]
```

### Complete Multi-Stage Dockerfile

Your `Dockerfile.multistage` should look like:

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

## Part 5: Build and Compare

### Build the Multi-Stage Version

```bash
docker build -t go-api:lean -f Dockerfile.multistage .
```

### Compare Sizes

```bash
docker images | grep go-api
```

**Results:**
```
go-api:lean    <tag>    12-18MB     # Multi-stage
go-api:fat     <tag>    1.0-1.2GB   # Single-stage
```

**Size reduction:** ~60-100x smaller! 🎉

---

## Part 6: Verify It Still Works

```bash
# Run the lean version
docker run -d -p 8080:8080 --name api-lean go-api:lean

# Test all endpoints
curl localhost:8080/health
curl localhost:8080/info
curl -X POST -d '{"message": "Hello"}' localhost:8080/echo

# Clean up
docker rm -f api-lean
```

Everything works, but the image is 60x smaller!

---

## Part 7: Understand the Magic

### How COPY --from Works

```dockerfile
COPY --from=builder /app/server .
```

This copies the `server` binary from the `builder` stage into the current stage. The builder stage itself is **not included** in the final image.

### Why Alpine?

Alpine Linux is:
- Tiny (~7MB base)
- Has a package manager (apk)
- Secure (minimal attack surface)

For Go static binaries, you could even use `FROM scratch` (0MB base), but Alpine gives you a shell for debugging.

### The Build Flags Explained

```bash
CGO_ENABLED=0      # Don't use C libraries (creates static binary)
GOOS=linux         # Target Linux (even if building on Mac/Windows)
-ldflags="-w -s"   # Strip debug symbols (-w) and symbol table (-s)
```

These flags create the smallest possible binary.

---

## Part 8: Use Scratch for Ultimate Minimalism (Advanced)

Want to go even smaller? Use `scratch`:

```dockerfile
# Stage 1: Builder (same as before)
FROM golang:1.21 AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server .

# Stage 2: Scratch (literally nothing)
FROM scratch

COPY --from=builder /app/server /server

EXPOSE 8080

CMD ["/server"]
```

Build it:

```bash
docker build -t go-api:scratch -f Dockerfile.scratch .
docker images | grep go-api
```

**Result:** ~10-12MB (just the binary!)

**Trade-off:** No shell for debugging. If the app crashes, you can't `docker exec` into it to investigate.

---

## Checkpoint ✅

You should now understand:

- [ ] Multi-stage builds use multiple `FROM` statements
- [ ] Earlier stages can build artifacts
- [ ] `COPY --from=<stage>` copies files between stages
- [ ] Only the final stage becomes the image
- [ ] Build stages can use different base images
- [ ] Static binaries (CGO_ENABLED=0) enable minimal base images
- [ ] `scratch` is the ultimate minimal base (0MB)

---

## Challenge: Optimize the Python App from Week 1

Can you apply multi-stage builds to the Python Flask app from Week 1?

**Hint:** Python can't create static binaries like Go, but you can:
1. Use a full Python image to install dependencies
2. Copy only the installed packages to a slim runtime image
3. Skip pip, setuptools, and other build tools in the final image

This is harder than Go but possible with tools like `pip install --target`.

---

## Real-World Impact

Imagine deploying this API to Kubernetes with 100 pods:

| Image Type | Image Size | Total Network Transfer | Pod Startup Time |
|------------|------------|----------------------|------------------|
| Fat (single-stage) | 1.2GB | 120GB | ~30-45 seconds |
| Lean (multi-stage) | 15MB | 1.5GB | ~2-3 seconds |

**Savings:**
- 118.5GB less network transfer
- 10-15x faster pod startup
- Lower storage costs
- Smaller attack surface

---

## Clean Up

```bash
docker rmi go-api:fat go-api:lean go-api:scratch
```

---

## Demo

![Multi-Stage Build Demo](../../../assets/week-02-lab-02-multistage.gif)

---

## Key Takeaway

> **Multi-stage builds separate build-time dependencies from runtime dependencies.**

Ship what you need. Leave the rest behind.
