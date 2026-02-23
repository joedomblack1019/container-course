![Week 2 overview hero image](../assets/generated/week-02-overview/hero.png)

# Week 2: Dockerfile Mastery

## Overview

**Duration:** 3 hours  
**Format:** Lecture + Hands-on Labs  

Bad images are slow to pull, expensive to store, and full of security vulnerabilities. Image optimization is a high-leverage skill that pays dividends in every deployment. A 1GB image pulled across 50 nodes is 50GB of network transfer.

By the end of this week, you'll transform bloated, inefficient Dockerfiles into lean, optimized, secure images.

---

## Learning Outcomes

By the end of this class, you will be able to:

1. Explain how layer caching works and structure Dockerfiles to maximize cache hits
2. Use multi-stage builds to separate build-time and runtime dependencies
3. Reduce an image size by 80%+ using appropriate base images and techniques
4. Write effective `.dockerignore` files to exclude unnecessary files
5. Scan an image for vulnerabilities using Trivy and interpret the findings

---

## Pre-Class Setup

You should have completed Week 1 and have a working Docker environment (Codespaces or local VM).

Verify your setup:

```bash
docker --version
docker run hello-world
```

---

## Class Agenda

| Time | Topic | Type |
|------|-------|------|
| 0:00 - 0:20 | Review: What is an image layer? | Discussion |
| 0:20 - 0:50 | Layer Caching Deep Dive: Why Order Matters | Lecture + Demo |
| 0:50 - 1:15 | **Lab 1:** Optimize a Poorly-Ordered Dockerfile | Hands-on |
| 1:15 - 1:30 | Break | — |
| 1:30 - 2:00 | Multi-Stage Builds: Separate Build from Runtime | Lecture + Demo |
| 2:00 - 2:30 | **Lab 2:** Convert a Fat Image to Multi-Stage | Hands-on |
| 2:30 - 2:50 | Security Scanning with Trivy | Demo + Practice |
| 2:50 - 3:00 | Wrap-up: The Image Size Challenge | — |

---

## Key Concepts

### Layer Caching: The Performance Game-Changer

Every Dockerfile instruction creates a new layer. Docker caches these layers to speed up builds.

**How caching works:**

1. Docker checks each instruction against its cache
2. If the instruction hasn't changed AND all previous layers are cached, Docker reuses the cached layer
3. Once any instruction changes, **that layer and ALL subsequent layers are rebuilt**
4. For `COPY` and `ADD`, Docker checks file contents (checksums), not just the instruction text

**The Golden Rule:** Put instructions that change frequently at the END of your Dockerfile.

### The Anti-Pattern: Cache-Busting Dependencies

```dockerfile
# ❌ BAD: Any code change invalidates dependency cache
FROM python:3.11-slim
WORKDIR /app
COPY . .                              # Copies EVERYTHING
RUN pip install -r requirements.txt   # Reinstalls deps every time
CMD ["python", "app.py"]
```

**What happens:**
1. You change `app.py`
2. `COPY . .` invalidates the cache (file contents changed)
3. `pip install` runs again, even though `requirements.txt` didn't change
4. Slow, wasteful rebuilds

### The Optimal Pattern: Dependencies First

```dockerfile
# ✅ GOOD: Dependencies cached until requirements.txt changes
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .               # Only copy dependency file
RUN pip install -r requirements.txt   # Cached unless requirements.txt changes
COPY . .                              # Code changes don't bust dependency cache
CMD ["python", "app.py"]
```

**What happens:**
1. You change `app.py`
2. First three layers are cached (FROM, WORKDIR, COPY requirements.txt, RUN pip)
3. Only `COPY . .` rebuilds
4. Fast, efficient builds

### Multi-Stage Builds: Separating Build from Runtime

Many applications need build tools (compilers, npm, cargo) that aren't needed at runtime. Multi-stage builds let you use one base image to build, then copy only the artifacts to a smaller runtime image.

**The Pattern:**

```dockerfile
# Stage 1: Build stage (has compilers, dev tools)
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci                            # Install ALL dependencies
COPY . .
RUN npm run build                     # Compile TypeScript, bundle, etc.

# Stage 2: Runtime stage (minimal, only production needs)
FROM node:18-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

**Benefits:**
- **Smaller images:** Build tools aren't in the final image
- **Faster deployments:** Less to pull and start
- **Better security:** Fewer packages = smaller attack surface
- **Cleaner separation:** Build concerns separated from runtime concerns

### Base Image Selection Matters

| Image | Size | Use Case | Trade-offs |
|-------|------|----------|-----------|
| `ubuntu:22.04` | ~77MB | Need apt, familiar environment | Larger, more packages |
| `debian:bookworm-slim` | ~52MB | Smaller Debian base | Still has apt/dpkg |
| `python:3.11-slim` | ~150MB | Python with essentials | Good balance for Python apps |
| `alpine:3.18` | ~7MB | Minimal, uses musl libc | Compatibility issues with some packages |
| `distroless/static` | ~2MB | No shell, maximum security | Debugging is harder, static binaries only |
| `scratch` | 0MB | Literally nothing | Static binaries only (Go, Rust) |

**Decision framework:**
- **Development/testing:** Full image (ubuntu, python:3.11) for debugging
- **Production web apps:** slim variants (python:3.11-slim, node:18-slim)
- **Production APIs (compiled):** Alpine or distroless for smallest size
- **Maximum security:** distroless or scratch (no shell = can't execute if compromised)

### The .dockerignore File

Like `.gitignore` but for Docker builds. Prevents unnecessary files from being sent to the Docker daemon.

```
# .dockerignore
.git/
.gitignore
node_modules/
*.md
.env
.vscode/
*.log
__pycache__/
*.pyc
tests/
docs/
```

**Why it matters:**
- Faster builds (smaller build context)
- Smaller images (if you use `COPY . .`)
- Security (don't accidentally copy secrets)

### Image Layer Visualization

Every instruction creates a layer:

```dockerfile
FROM python:3.11-slim           # Layer 1: Base image (120MB)
WORKDIR /app                    # Layer 2: Create /app directory (tiny)
COPY requirements.txt .         # Layer 3: Add requirements.txt (1KB)
RUN pip install -r requirements.txt  # Layer 4: Install packages (30MB)
COPY . .                        # Layer 5: Add application code (500KB)
CMD ["python", "app.py"]        # Layer 6: Metadata (no size)
```

View layers with:
```bash
docker history my-image:latest
```

---

## Labs

### Lab 1: Layer Optimization Challenge

📁 See [labs/lab-01-layer-optimization/](./labs/lab-01-layer-optimization/)

You'll:
- Start with a poorly-ordered Dockerfile that rebuilds slowly
- Analyze the cache behavior
- Restructure the Dockerfile for optimal caching
- Measure the improvement (1st build vs 2nd build time)

**Goal:** Reduce rebuild time from ~3 minutes to ~10 seconds

### Lab 2: Multi-Stage Migration

📁 See [labs/lab-02-multistage-build/](./labs/lab-02-multistage-build/)

You'll:
- Take a single-stage Go application (1.2GB image)
- Convert to multi-stage build
- Achieve a final image under 20MB (60x smaller!)
- Verify the application still works

**Goal:** Prove that bigger ≠ better. Shipping compilers to production is wasteful.

### Lab 3: Security Scanning with Trivy

📁 See [labs/lab-03-security-scanning/](./labs/lab-03-security-scanning/)

You'll:
- Install Trivy in your environment
- Scan one of your images for vulnerabilities
- Understand CVE severity levels (CRITICAL, HIGH, MEDIUM, LOW)
- Fix vulnerabilities by upgrading base images or dependencies
- Establish a security scanning workflow

**Goal:** No CRITICAL vulnerabilities in production images

---

## Generated Visualizations

### Lab 1: Layer Cache Benchmark

![Layer Cache Build Times](../assets/generated/week-02-layer-cache/build_times.png)

![Layer Cache Effectiveness](../assets/generated/week-02-layer-cache/cache_effectiveness.png)

### Lab 3: Trivy Vulnerability Trend

![Trivy Severity Breakdown](../assets/generated/week-02-trivy-scan/trivy_severity_stacked.png)

![Trivy High+Critical Trend](../assets/generated/week-02-trivy-scan/trivy_high_critical_trend.png)

---

## Discovery Questions

Answer these in your own words after completing the labs:

1. **Layer caching:** You changed line 15 of your Dockerfile. Will Docker rebuild layers 1-14? Why or why not?

2. **The COPY dilemma:** Why is `COPY requirements.txt .` followed by `COPY . .` better than just doing `COPY . .` once? Isn't that duplicating files?

3. **Multi-stage thinking:** In a multi-stage build, if you change source code in the builder stage, does the runtime stage need to rebuild? What about vice versa?

4. **Alpine gotchas:** You tried `FROM python:3.11-alpine` and got an error during `pip install` for a package with C extensions. Why? What would you need to add to make it work?

5. **Size vs Security:** An Alpine-based image is 50MB. A Debian-slim image is 180MB. Which is "better"? What factors would influence your decision?

6. **The scratch mystery:** If `FROM scratch` gives you a 0MB base, why can't you use it for a Python app? What would happen if you tried?

7. **Vulnerability strategy:** Trivy found 3 CRITICAL, 12 HIGH, and 45 MEDIUM vulnerabilities in your image. Which should you fix first? Can you ignore the MEDIUM ones?

---

## Homework

Complete these exercises in the container-gym before next class:

| Exercise | Time | Focus |
|----------|------|-------|
| `layer-detective` | 20 min | Identify cache-busting instruction in a slow Dockerfile |
| `multi-stage-migration` | 30 min | Convert a Node.js app to multi-stage build |
| `jerry-fat-image` | 25 min | Jerry's image is 2GB. Fix it. |
| `vulnerability-scan` | 15 min | Use Trivy to find and understand CVEs |

To start: `gym start layer-detective`

---

## Resources

### Required Reading
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) - Official Docker optimization guide
- [Multi-stage Builds](https://docs.docker.com/build/building/multi-stage/) - Official multi-stage documentation

### Tools
- [Trivy](https://aquasecurity.github.io/trivy/) - Vulnerability scanner
- [Dive](https://github.com/wagoodman/dive) - Explore image layers interactively
- [Docker Slim](https://github.com/slimtoolkit/slim) - Automated image optimization

### Reference
- [Base Image Selection Guide](https://docs.docker.com/develop/develop-images/baseimages/)
- [Python Docker Best Practices](https://github.com/docker-library/docs/tree/master/python#image-variants)
- [Understanding Image Layers](https://docs.docker.com/storage/storagedriver/#images-and-layers)

### Deep Dive (Optional)
- [Container Image Optimization](https://www.youtube.com/watch?v=wGz_cbtCiEA) - Practical optimization strategies
- [Distroless Base Images](https://github.com/GoogleContainerTools/distroless) - Google's minimal base images
- [Why Alpine is Bad for Python](https://pythonspeed.com/articles/alpine-docker-python/) - The musl libc problem

---

## Week 2 Challenge: The Image Size Competition

**Optional challenge for the competitive among you:**

Take the Python app from Week 1 and optimize it as much as possible while keeping it functional.

**Rules:**
1. Must be based on Python (no rewriting in Go!)
2. All endpoints must still work
3. Must pass a basic security scan (no CRITICAL vulnerabilities)

**Submission:**
- Push your optimized image to GHCR with tag `optimized-v1`
- Post your image size in the class Discord: `docker images --format "{{.Repository}}:{{.Tag}} - {{.Size}}"`

**Current record to beat:** 68MB (from last semester)

We'll feature the top 3 smallest images in next week's class!

---

## Next Week Preview

In Week 3, we'll move from single containers to **multi-container applications** with Docker Compose:
- Service discovery: How containers find each other by name
- Volumes and persistence: Making data survive container restarts  
- Networks: Segmenting your application for security
- Building a full WordPress stack (web + database + cache)

Get ready to graduate from toy apps to real, multi-tier architectures!
