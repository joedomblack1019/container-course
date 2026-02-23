![Lab 2 hero image](../../../assets/generated/week-03-lab-02/hero.png)

# Lab 2: Network Debugging

**Time:** 30 minutes  
**Objective:** Diagnose and fix networking issues in a broken Docker Compose stack

---

## The Scenario

You've been handed a three-tier application: a frontend web server, a backend API, and a database. The Compose file has **three networking problems**. The application doesn't work. Your job is to find and fix each issue.

### Useful Documentation

The answers to every bug in this lab are in the official Docker docs. Get comfortable reading them — this is how you'll solve real problems on the job.

- [Networking in Compose](https://docs.docker.com/compose/how-tos/networking/) — How Compose creates networks and how service discovery works
- [Compose file: networks](https://docs.docker.com/reference/compose-file/networks/) — The `networks` key in a Compose file
- [Bridge network driver](https://docs.docker.com/engine/network/drivers/bridge/) — How bridge networks isolate containers and provide DNS resolution
- [Compose file: services](https://docs.docker.com/reference/compose-file/services/) — Service configuration including `environment`, `healthcheck`, `depends_on`
- [Environment variables in Compose](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/) — How to set and manage env vars
- [docker network inspect](https://docs.docker.com/reference/cli/docker/network/inspect/) — Inspect a network to see which containers are connected

---

## Setup

```bash
cd week-03/labs/lab-02-network-debugging/starter
```

You have:
- `docker-compose.yml` — The broken Compose file
- `api/` — A simple Python API that talks to the database
- `frontend/` — An nginx config that proxies to the API

### Start the Broken Stack

```bash
docker compose up -d --build
```

### Confirm It's Broken

```bash
curl localhost:8080
curl localhost:8080/api/items
```

The static page might load, but the API calls should fail (502 Bad Gateway, connection refused, or timeout). The application is broken. Time to investigate.

---

## Part 1: Map Out the Architecture

Before debugging, understand what the application *should* look like:

```
User → :8080 → frontend (nginx) → api:5000 → db:3306 (mysql)
```

Three services, three hops:

1. **frontend** — nginx reverse proxy, listens on port 80, forwards `/api/` to `api:5000`
2. **api** — Python Flask app, connects to `db:3306`, serves JSON
3. **db** — MySQL, stores data

Each hop is a potential failure point. Read [Networking in Compose](https://docs.docker.com/compose/how-tos/networking/) to understand how containers on the same network discover each other by service name.

---

## Part 2: Systematic Debugging

Work from the bottom of the stack up. If the database is broken, nothing above it will work.

### Check 1: Are All Containers Running?

```bash
docker compose ps
```

All three should show `Up`. If any are restarting or exited, check their logs first:

```bash
docker compose logs <service-name>
```

### Check 2: Can the API Reach the Database?

Get a shell in the API container and test connectivity:

```bash
docker compose exec api sh
```

Inside the container:

```bash
# Is DNS working? Can we resolve "db"?
getent hosts db

# Can we reach the database port?
nc -zv db 3306

# What about the hostname the API is configured to use?
echo $DB_HOST
getent hosts $DB_HOST

exit
```

If `getent hosts db` works but `getent hosts $DB_HOST` doesn't, the environment variable is pointing at the wrong hostname.

### Check 3: Can the Frontend Reach the API?

```bash
docker compose exec frontend sh
```

Inside the container:

```bash
# Can we resolve "api"?
getent hosts api

# Can we reach the API on the port nginx expects?
wget -qO- http://api:5000/health || echo "FAILED on 5000"

exit
```

If DNS resolution fails, the frontend and API are probably on different networks.

### Check 4: Inspect the Networks

```bash
# List all networks for this project
docker network ls | grep network-debugging

# Inspect each network to see which containers are on it
docker network inspect starter_frontend-net
docker network inspect starter_backend-net
```

Look at which containers are connected to which networks. Services can only communicate if they share at least one network. The docs on [bridge networks](https://docs.docker.com/engine/network/drivers/bridge/) explain why — each user-defined bridge is an isolated network segment with its own DNS resolver. Read the [`docker network inspect` reference](https://docs.docker.com/reference/cli/docker/network/inspect/) to understand the output.

### Check 5: Inspect the nginx Config

```bash
docker compose exec frontend cat /etc/nginx/conf.d/default.conf
```

What port is nginx proxying to? Does it match the port the API is listening on?

---

## Part 3: Find and Fix the Issues

Open `docker-compose.yml` and `frontend/nginx.conf`. There are **three problems** across these files. Use the debugging output from Part 2 to guide you.

**Hints for what to look for** (the docs will help you understand each one):
- Which services are on which networks? See [Compose file: networks](https://docs.docker.com/reference/compose-file/networks/)
- Do all services that need to talk share a network? See [Networking in Compose](https://docs.docker.com/compose/how-tos/networking/)
- Do the hostnames in environment variables match actual service names? See [Environment variables in Compose](https://docs.docker.com/compose/how-tos/environment-variables/set-environment-variables/)
- Do the ports in the nginx config match what the API actually listens on?

### Fixing

After each fix, restart and test:

```bash
docker compose down
docker compose up -d --build

# Test end-to-end
curl localhost:8080
curl localhost:8080/api/items
curl localhost:8080/api/health
```

---

## Part 4: Verify the Fix

When everything works, you should be able to:

```bash
# Frontend serves the page
curl -s localhost:8080

# API returns data through the frontend proxy
curl -s localhost:8080/api/items

# API health check passes
curl -s localhost:8080/api/health
```

### Bonus Verification: Network Isolation

Verify that the frontend **cannot** directly reach the database (good security practice):

```bash
docker compose exec frontend sh -c "nc -zv db 3306 2>&1 || echo 'Good: frontend cannot reach db directly'"
```

If the frontend can't reach the database, your network segmentation is working correctly. This is the whole point of user-defined bridge networks — read [Bridge network driver](https://docs.docker.com/engine/network/drivers/bridge/) to understand why the default bridge behaves differently from user-defined bridges.

---

## Part 5: Document Your Findings

For each issue you found, note:

1. **Symptom** — What error did you see?
2. **Root cause** — What was wrong in the configuration?
3. **Fix** — What did you change?
4. **How you found it** — Which debugging command revealed the issue?

---

## Checkpoint ✅

Before moving on, verify:

- [ ] All three services are running and healthy
- [ ] `curl localhost:8080` returns the frontend page
- [ ] `curl localhost:8080/api/items` returns JSON data from the database
- [ ] You can explain each networking issue you found
- [ ] You understand why services on different networks can't communicate

---

## Clean Up

```bash
docker compose down -v
```

---

## Next Lab

Continue to [Lab 3: Development Workflow](../lab-03-dev-workflow/)
