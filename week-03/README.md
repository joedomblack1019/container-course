![Week 3 overview hero image](../assets/generated/week-03-overview/hero.png)

# Week 3: Compose & Local Development

## Overview

**Duration:** 3 hours  
**Format:** Lecture + Hands-on Labs  

Real applications aren't a single container. They're a web server talking to a database backed by a cache fronted by a reverse proxy. Docker Compose lets you define and run multi-container applications with a single file, and it introduces concepts—service discovery, networks, volumes—that map directly to Kubernetes.

By the end of this week, you'll deploy a full WordPress stack, debug broken container networking, and build a development workflow with live code reloading.

---

## Learning Outcomes

By the end of this class, you will be able to:

1. Define a multi-service application in `docker-compose.yml`
2. Explain how Docker DNS enables service discovery by container name
3. Use named volumes for persistent data and bind mounts for development workflows
4. Implement health checks for service dependencies
5. Debug networking issues between containers

---

## Pre-Class Setup

You should have completed Week 2 and have a working Docker environment with Docker Compose available.

Verify your setup:

```bash
docker --version
docker compose version
```

> **Note:** Modern Docker ships `docker compose` (v2) as a plugin. If you have `docker-compose` (v1, with the hyphen), it works the same way for everything in this course. We'll use `docker compose` (no hyphen) throughout.

---

## Class Agenda

| Time | Topic | Type |
|------|-------|------|
| 0:00 - 0:20 | From Single Container to Multi-Container: Why Orchestration | Lecture |
| 0:20 - 0:50 | Compose File Anatomy: Services, Networks, Volumes | Lecture + Demo |
| 0:50 - 1:20 | **Lab 1:** WordPress + MySQL with Compose | Hands-on |
| 1:20 - 1:35 | Break | — |
| 1:35 - 2:00 | Networking Deep Dive: Bridge Networks, DNS Resolution | Lecture + Demo |
| 2:00 - 2:30 | **Lab 2:** Debug a Broken Compose Network | Hands-on |
| 2:30 - 2:50 | **Lab 3:** Development Workflows with Bind Mounts | Hands-on |
| 2:50 - 3:00 | Wrap-up: Compose → Kubernetes Comparison Preview | — |

---

## Key Concepts

### Why Compose?

Without Compose, running a WordPress site requires something like this:

```bash
docker network create wp-net

docker run -d --name db \
  --network wp-net \
  -e MYSQL_ROOT_PASSWORD=rootpass \
  -e MYSQL_DATABASE=wordpress \
  -v db-data:/var/lib/mysql \
  mysql:8.0

docker run -d --name wordpress \
  --network wp-net \
  -e WORDPRESS_DB_HOST=db \
  -e WORDPRESS_DB_PASSWORD=rootpass \
  -p 8080:80 \
  wordpress:latest
```

Two containers, one network, one volume, a dozen flags. Now imagine doing this for 5 services. With Compose, you declare it once in YAML and run `docker compose up`.

### Compose File Structure

```yaml
services:
  web:
    build: .
    ports:
      - "8080:80"
    environment:
      - DATABASE_URL=mysql://db:3306/app
    depends_on:
      db:
        condition: service_healthy
    networks:
      - frontend
      - backend

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: app
    volumes:
      - db-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - backend

volumes:
  db-data:

networks:
  frontend:
  backend:
```

The top-level keys: `services` defines your containers, `volumes` declares persistent storage, and `networks` sets up isolated communication channels.

### Service Discovery: How Containers Find Each Other

When you define services in a Compose file, Docker automatically sets up DNS resolution so containers can reach each other **by service name**.

```yaml
services:
  web:
    environment:
      - DATABASE_HOST=db    # "db" resolves to the database container's IP
  db:
    image: mysql:8.0
```

How it works under the hood:

- Compose creates a default bridge network for the project
- Docker runs an embedded DNS server at `127.0.0.11` inside each container
- Service names are registered as DNS records
- `db` resolves to whatever IP the database container gets assigned
- No hardcoded IPs, no manual configuration

This is the same pattern Kubernetes uses (service names → DNS → pod IPs), just at a smaller scale.

### Volume Types

| Type | Syntax | Use Case | Data Lifecycle |
|------|--------|----------|----------------|
| Named Volume | `db-data:/var/lib/mysql` | Persistent data, managed by Docker | Survives `docker compose down`, removed by `down -v` |
| Bind Mount | `./src:/app/src` | Development, code syncing from host | Lives on host filesystem |
| tmpfs | `tmpfs: /tmp` | Ephemeral, memory-backed | Gone when container stops |

Named volumes are the right choice for database data. Bind mounts are the right choice for development workflows where you want code changes on your host to show up inside the container immediately.

### Health Checks and depends_on

`depends_on` without a condition only waits for the container to *start*—not for the service inside it to be *ready*. A MySQL container might take 30 seconds to initialize, but `depends_on` returns after 1 second when the container process begins.

```yaml
# ❌ BAD: App starts before database is ready
depends_on:
  - db

# ✅ GOOD: App waits until database passes health check
depends_on:
  db:
    condition: service_healthy
```

The health check tells Docker how to determine if a service is actually ready:

```yaml
healthcheck:
  test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
  interval: 10s      # Check every 10 seconds
  timeout: 5s        # Fail if check takes longer than 5 seconds
  retries: 5         # Mark unhealthy after 5 consecutive failures
  start_period: 30s  # Grace period for slow-starting services
```

### Docker Compose Commands

```bash
docker compose up              # Start all services (foreground)
docker compose up -d           # Start all services (detached)
docker compose down            # Stop and remove containers + networks
docker compose down -v         # Also remove named volumes (DATA LOSS!)
docker compose ps              # List running services
docker compose logs            # View logs for all services
docker compose logs -f web     # Follow logs for a specific service
docker compose exec web bash   # Shell into a running service
docker compose build           # Rebuild images
docker compose restart web     # Restart a specific service
```

### Compose → Kubernetes Mental Map

| Compose | Kubernetes | Notes |
|---------|------------|-------|
| `services:` | Deployment + Service | K8s splits "what to run" from "how to reach it" |
| `ports:` | Service (NodePort/LoadBalancer) | External access |
| `depends_on:` | (no direct equivalent) | Use init containers or readiness probes |
| `volumes:` | PersistentVolumeClaim | Decoupled from pod spec |
| `networks:` | NetworkPolicy | Default K8s is "all can talk to all" |
| `environment:` | ConfigMap / Secret | Externalized configuration |
| `healthcheck:` | livenessProbe / readinessProbe | Same concept, more granular in K8s |

---

## Labs

### Lab 1: WordPress + MySQL Stack

📁 See [labs/lab-01-compose-wordpress/](./labs/lab-01-compose-wordpress/)

You'll:
- Write a `docker-compose.yml` from scratch
- Deploy WordPress with a MySQL backend
- Observe service discovery (WordPress finds MySQL by name)
- Verify data persistence through container restarts
- Explore the created networks and volumes

**Goal:** A working WordPress site backed by MySQL, with persistent data.

### Lab 2: Network Debugging

📁 See [labs/lab-02-network-debugging/](./labs/lab-02-network-debugging/)

You'll:
- Start from a broken Compose file where services can't talk to each other
- Diagnose the network issues using DNS lookups and connectivity tests
- Fix the configuration
- Verify end-to-end connectivity

**Goal:** Understand how Compose networking works by fixing it when it breaks.

### Lab 3: Development Workflow

📁 See [labs/lab-03-dev-workflow/](./labs/lab-03-dev-workflow/)

You'll:
- Build a Flask app with live reloading via bind mounts
- Make code changes that appear instantly without rebuilding
- Add a Redis cache as a second service
- Compare the development experience with and without bind mounts

**Goal:** A productive development workflow where code changes are reflected immediately.

---

## Discovery Questions

Answer these in your own words after completing the labs:

1. You ran `docker compose down` and then `docker compose up` again. Your WordPress site still has all its posts and settings. Why? What command would make you lose everything?

2. In the WordPress stack, you set `WORDPRESS_DB_HOST=db`. Where does the hostname `db` come from? What IP address does it resolve to? Will that IP be the same next time you start the stack?

3. Your Compose file has two networks: `frontend` and `backend`. The web server is on both, the database is only on `backend`. Why is this a better design than putting everything on one network?

4. You used `depends_on` with `condition: service_healthy`. What happens if you use `depends_on` without a condition? What's the failure mode—does the web container crash, hang, or something else?

5. During Lab 3, you edited `app.py` on your host and the change appeared in the container immediately. How is this different from `COPY app.py .` in a Dockerfile? When would you use each approach?

6. Can two separate Compose projects (different `docker-compose.yml` files) have services with the same name? What happens to networking if they do?

---

## Homework

Complete these exercises in the container-gym before next class:

| Exercise | Time | Focus |
|----------|------|-------|
| `service-discovery` | 20 min | Fix DNS resolution between services |
| `volume-persistence` | 20 min | Data must survive container restart |
| `jerry-wrong-network` | 25 min | Jerry put services on different networks |
| `healthcheck-cascade` | 20 min | Proper startup ordering with health checks |

To start: `gym start service-discovery`

---

## Resources

### Required Reading
- [Compose Specification](https://docs.docker.com/compose/compose-file/) - The full Compose file reference

### Reference
- [Networking in Compose](https://docs.docker.com/compose/networking/) - How Compose sets up networks
- [Docker Compose CLI Reference](https://docs.docker.com/compose/reference/) - All Compose commands
- [Use Volumes](https://docs.docker.com/storage/volumes/) - Volume management
- [Healthcheck in Compose](https://docs.docker.com/compose/compose-file/05-services/#healthcheck) - Health check syntax

### Deep Dive (Optional)
- [Container Networking From Scratch](https://labs.iximiuz.com/tutorials/container-networking-from-scratch) - Build a container network by hand
- [12-Factor App: Config](https://12factor.net/config) - Why config belongs in the environment
- [Docker DNS Deep Dive](https://docs.docker.com/network/drivers/bridge/#differences-between-user-defined-bridges-and-the-default-bridge) - User-defined bridge vs default bridge

---

## Next Week Preview

In Week 4, we cross the bridge from Docker to **Kubernetes**:
- Control plane architecture (API server, etcd, scheduler, controllers)
- The reconciliation loop: desired state vs actual state
- Core objects: Pods, Deployments, Services
- Your first deployment on the shared cluster

Everything you've learned about containers, networking, and service discovery applies directly—Kubernetes just does it across multiple machines with self-healing built in.
