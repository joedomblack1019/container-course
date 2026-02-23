![Lab 3 hero image](../../../assets/generated/week-03-lab-03/hero.png)

# Lab 3: Development Workflow with Bind Mounts

**Time:** 20 minutes  
**Objective:** Build a development environment where code changes appear instantly without rebuilding images

---

## The Problem

So far, every code change required a `docker build` → `docker run` cycle. For development, that's slow and painful. You want to edit code on your host and see changes immediately inside the container.

The solution: **bind mounts** — map a directory on your host directly into the container's filesystem.

---

## Part 1: The Slow Way (Without Bind Mounts)

### Examine the Application

```bash
cd week-03/labs/lab-03-dev-workflow/starter
cat app.py
```

It's a Flask app with a visit counter backed by Redis.

### Build and Run the Normal Way

```bash
docker compose -f docker-compose.prod.yml up -d --build
```

Test it:

```bash
curl localhost:5000
curl localhost:5000
curl localhost:5000
```

Each request increments the counter. Now make a change:

### Edit app.py

Change the greeting in `app.py`:

```python
# Change this:
return f"Hello! This page has been viewed {count} times.\nHostname: {hostname}\n"

# To this:
return f"Welcome! You are visitor number {count}.\n"
```

### Check — Did It Update?

```bash
curl localhost:5000
```

**Nope.** Still the old message. You need to rebuild:

```bash
docker compose -f docker-compose.prod.yml up -d --build
curl localhost:5000
```

Now it shows the new message, but the counter reset because you recreated the container. Slow, disruptive.

```bash
docker compose -f docker-compose.prod.yml down
```

---

## Part 2: The Fast Way (With Bind Mounts)

### Start the Dev Compose File

```bash
docker compose -f docker-compose.dev.yml up -d --build
```

Examine what's different in `docker-compose.dev.yml`:

```bash
cat docker-compose.dev.yml
```

The key difference is the bind mount:

```yaml
volumes:
  - ./app.py:/app/app.py    # Host file → Container file
```

And the Flask environment variable:

```yaml
environment:
  - FLASK_DEBUG=1            # Enable auto-reload on code changes
```

### Test It

```bash
curl localhost:5000
```

### Now Edit app.py Again

Change the greeting back or to something new. Save the file.

### Check Immediately

```bash
curl localhost:5000
```

**The change appeared instantly.** No rebuild, no restart. Flask detected the file change (via the bind mount) and reloaded automatically.

---

## Part 3: Understand the Mechanics

### What's Happening

```
Host filesystem                    Container filesystem
─────────────────                  ─────────────────────
./app.py  ←── bind mount ──→     /app/app.py
(your editor)                      (Flask reads this)
```

When you save `app.py` on your host, the container sees the exact same file—it's the same bytes on disk, not a copy. Combined with Flask's debug mode auto-reload, changes appear in under a second.

### Bind Mount vs Named Volume vs COPY

| Approach | When to Use | Behavior |
|----------|-------------|----------|
| `COPY app.py .` (Dockerfile) | Production builds | File is baked into image at build time |
| `./app.py:/app/app.py` (bind mount) | Development | Host and container share the same file |
| `data:/app/data` (named volume) | Persistent data | Docker manages storage, survives restarts |

### Verify the Redis Data Persists

```bash
# Hit the counter a few times
curl localhost:5000
curl localhost:5000
curl localhost:5000

# Restart the app (NOT redis)
docker compose -f docker-compose.dev.yml restart web

# Counter should still be there
curl localhost:5000
```

The count survives because Redis holds the data, not the Flask app.

---

## Part 4: Explore the Redis Service

```bash
# Shell into redis
docker compose -f docker-compose.dev.yml exec redis redis-cli
```

Inside the Redis CLI:

```
GET hits
INCR hits
GET hits
exit
```

You can see and manipulate the counter directly.

### Check Service Discovery

```bash
docker compose -f docker-compose.dev.yml exec web sh -c "getent hosts redis"
```

Flask connects to Redis using the hostname `redis`—same DNS-based service discovery pattern from Lab 1.

---

## Checkpoint ✅

Before wrapping up, verify:

- [ ] You can edit `app.py` and see changes without rebuilding
- [ ] You understand the difference between bind mounts and `COPY`
- [ ] The Redis counter persists across Flask restarts
- [ ] You can articulate when to use bind mounts (dev) vs COPY (prod)

---

## Clean Up

```bash
docker compose -f docker-compose.dev.yml down -v
```

---

## Key Takeaways

Bind mounts are for **development only**. In production, your code should be baked into the image with `COPY`—that's what makes images portable and reproducible. The pattern is:

- **Dev:** Bind mounts + debug mode for fast iteration
- **Prod:** Multi-stage build + optimized image for deployment

You'll see this same pattern in Kubernetes: development uses tools like Skaffold or Tilt for fast feedback, while production uses immutable images deployed via GitOps.
