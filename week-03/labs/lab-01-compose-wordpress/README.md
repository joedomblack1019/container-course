![Lab 1 hero image](../../../assets/generated/week-03-lab-01/hero.png)

# Lab 1: WordPress + MySQL with Compose

**Time:** 30 minutes  
**Objective:** Deploy a multi-service application using Docker Compose, observe service discovery, and verify data persistence

---

## The Goal

Deploy a working WordPress site backed by a MySQL database. No manual `docker run` commands. One file, one command.

---

## Background: How Compose Orchestrates Multi-Container Apps

Compose is a local application model, not just a shortcut for long `docker run` commands. A Compose file declares services, networks, and volumes as one unit so Docker can create a consistent runtime graph every time. In this lab, WordPress and MySQL are separate services with different startup behavior, but Compose makes them part of one managed stack.

Service-to-service connectivity works through an auto-created network and embedded DNS. Each service name becomes a resolvable hostname on that network, so `WORDPRESS_DB_HOST: db` is not a magic string; it is a DNS name that resolves to the database container. This is the same pattern you later use in Kubernetes Services, just with Compose's local network scope.

Startup order and readiness are different problems. `depends_on` controls when Compose starts containers, but without a health check you can still start WordPress before MySQL is actually accepting connections. Adding a database health check plus `condition: service_healthy` turns this into readiness-aware startup and removes a common source of intermittent boot failures.

Volumes are the persistence boundary in this architecture. Containers are replaceable processes, while MySQL data must survive container recreation, so the database writes to a named volume managed outside the container filesystem. In AWS terms, think of this like replacing an EC2 instance while reattaching the same durable storage.

If you keep these four concepts in mind (application graph, network DNS, readiness gating, and persistent volumes), every command in this lab will feel mechanical instead of magical. For deeper details, see the official Docker Compose documentation: https://docs.docker.com/compose/.

---

## Part 1: Write the Compose File

Create a new `docker-compose.yml` in the `starter` directory:

```bash
cd week-03/labs/lab-01-compose-wordpress/starter
```

Open your editor and create `docker-compose.yml`. Build it step by step.

### Step 1: Define the Database Service

Start with MySQL:

```yaml
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    volumes:
      - db-data:/var/lib/mysql

volumes:
  db-data:
```

What's happening here:
- `image: mysql:8.0` — Pull MySQL 8.0 from Docker Hub
- `environment:` — Set the env vars MySQL expects on first start to create a database and user
- `volumes:` — Mount a named volume so the data directory persists
- The top-level `volumes:` block declares `db-data` as a Docker-managed volume

### Step 2: Add a Health Check to MySQL

MySQL takes a few seconds to initialize. We need to know when it's actually ready:

```yaml
services:
  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    volumes:
      - db-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

volumes:
  db-data:
```

The health check runs `mysqladmin ping` every 10 seconds. Docker marks the container as `healthy` once the check passes, or `unhealthy` after 5 consecutive failures.

### Step 3: Add WordPress

Now add the WordPress service that depends on the database:

```yaml
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "8080:80"
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: wordpress
      WORDPRESS_DB_NAME: wordpress
    depends_on:
      db:
        condition: service_healthy

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress
    volumes:
      - db-data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

volumes:
  db-data:
```

Notice `WORDPRESS_DB_HOST: db`. That's service discovery in action. WordPress will resolve the hostname `db` to the MySQL container's IP address via Docker's embedded DNS.

---

## Part 2: Start the Stack

```bash
docker compose up -d
```

Watch the output. You should see:
- A network being created (e.g., `starter_default`)
- The `db-data` volume being created
- Both containers starting

### Check Status

```bash
docker compose ps
```

You should see both services with status `Up`. The `db` service should show `(healthy)` after ~30 seconds.

If `db` shows `(health: starting)`, wait a moment and check again:

```bash
# Watch until healthy
watch docker compose ps
```

(Press `Ctrl+C` to stop watching.)

---

## Part 3: Access WordPress

**In Codespaces:** Click the "Ports" tab and open port 8080.

**In a VM:**

```bash
curl -s localhost:8080 | head -20
```

Or open `http://localhost:8080` in a browser.

You should see the WordPress setup wizard. Pick a language and complete the installation with any username/password you like. Write a test blog post—we'll verify it survives a restart.

---

## Part 4: Explore What Compose Created

### Inspect the Network

```bash
docker network ls
```

Compose created a network (something like `starter_default`). Inspect it:

```bash
docker network inspect starter_default
```

You'll see both containers listed with their IP addresses. This is the bridge network where DNS resolution happens.

### Inspect the Volume

```bash
docker volume ls
docker volume inspect starter_db-data
```

This shows where Docker stores the MySQL data on the host filesystem.

### Test DNS Resolution

Get a shell inside the WordPress container and look up the database:

```bash
docker compose exec wordpress bash
```

Inside the container:

```bash
# What DNS server is configured?
cat /etc/resolv.conf

# Can we resolve the "db" service name?
getent hosts db

# Can we reach MySQL?
apt-get update && apt-get install -y default-mysql-client
mysql -h db -u wordpress -pwordpress -e "SHOW DATABASES;"

exit
```

The hostname `db` resolved to the MySQL container's IP address. No hardcoded IPs anywhere.

---

## Part 5: Verify Data Persistence

### Stop Everything

```bash
docker compose down
```

This removes the containers and the network. But **not the volume**.

```bash
docker volume ls | grep db-data
```

The volume is still there.

### Start It Back Up

```bash
docker compose up -d
```

Wait for the health check to pass, then access WordPress again. Your blog post is still there. The MySQL data survived because it's stored in the named volume, not inside the container.

### Now Try Destroying the Volume

```bash
docker compose down -v
```

The `-v` flag removes named volumes too. If you start again:

```bash
docker compose up -d
```

WordPress shows the setup wizard again. All data is gone.

> **Key lesson:** `docker compose down` is safe. `docker compose down -v` is destructive. Know the difference.

---

## Part 6: View Logs

```bash
# All services
docker compose logs

# Just WordPress, following in real-time
docker compose logs -f wordpress

# Just the last 20 lines of MySQL
docker compose logs --tail 20 db
```

Make a request to WordPress and watch the log output:

```bash
# In another terminal
curl localhost:8080 > /dev/null
```

---

## Checkpoint ✅

Before moving on, verify you can:

- [ ] Write a `docker-compose.yml` with multiple services
- [ ] Explain what `WORDPRESS_DB_HOST: db` does and why it works
- [ ] Start and stop a Compose stack with `up -d` and `down`
- [ ] Explain the difference between `down` and `down -v`
- [ ] Verify data persistence through a restart cycle
- [ ] Use `docker compose logs` and `docker compose exec`

---

## Clean Up

```bash
docker compose down -v
```

---

## Demo

![Docker Compose Demo](../../../assets/week-03-lab-01-compose-up.gif)

---

## Next Lab

Continue to [Lab 2: Network Debugging](../lab-02-network-debugging/)
