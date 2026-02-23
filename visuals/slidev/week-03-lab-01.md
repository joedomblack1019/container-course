---
theme: default
title: Week 03 Lab 01 - WordPress + MySQL with Compose
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "03"
lab: "Lab 01 · WordPress + MySQL with Compose"
---

# WordPress + MySQL with Compose
## Lab 01

- Write `docker-compose.yml` for WordPress and MySQL
- Use health checks with `depends_on` readiness gating
- Verify service discovery (`WORDPRESS_DB_HOST: db`)
- Prove persistence with `down` vs `down -v`

---
layout: win95
windowTitle: "Compose File — Final Stack"
windowIcon: "🐳"
statusText: "Week 03 · Lab 01 · services, healthcheck, volume"
---

## `docker-compose.yml`

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

---
layout: win95-terminal
termTitle: "Command Prompt — bring up stack and access site"
---

<Win95Terminal
  title="Command Prompt — compose startup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd week-03/labs/lab-01-compose-wordpress/starter' },
    { type: 'input', text: 'docker compose up -d' },
    { type: 'output', text: 'Network starter_default  Created' },
    { type: 'output', text: 'Volume starter_db-data  Created' },
    { type: 'input', text: 'docker compose ps' },
    { type: 'output', text: 'db  Up (health: starting)' },
    { type: 'input', text: 'watch docker compose ps' },
    { type: 'input', text: 'curl -s localhost:8080 | head -20' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — inspect network, volume, and DNS"
---

<Win95Terminal
  title="Command Prompt — compose introspection"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker network ls' },
    { type: 'input', text: 'docker network inspect starter_default' },
    { type: 'input', text: 'docker volume ls' },
    { type: 'input', text: 'docker volume inspect starter_db-data' },
    { type: 'input', text: 'docker compose exec wordpress bash' },
    { type: 'input', text: 'cat /etc/resolv.conf' },
    { type: 'input', text: 'getent hosts db' },
    { type: 'input', text: 'apt-get update && apt-get install -y default-mysql-client' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — persistence test, logs, cleanup"
---

<Win95Terminal
  title="Command Prompt — lifecycle checks"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'mysql -h db -u wordpress -pwordpress -e &quot;SHOW DATABASES;&quot;' },
    { type: 'input', text: 'exit' },
    { type: 'input', text: 'docker compose down' },
    { type: 'input', text: 'docker volume ls | grep db-data' },
    { type: 'input', text: 'docker compose up -d' },
    { type: 'input', text: 'docker compose down -v' },
    { type: 'input', text: 'docker compose up -d' },
    { type: 'input', text: 'docker compose logs --tail 20 db' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — logs follow and final cleanup"
---

<Win95Terminal
  title="Command Prompt — logs + final cleanup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker compose logs' },
    { type: 'input', text: 'docker compose logs -f wordpress' },
    { type: 'input', text: 'curl localhost:8080 > /dev/null' },
    { type: 'input', text: 'docker compose down -v' },
    { type: 'success', text: 'Lab cleanup complete' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 01 — Key Commands"
windowIcon: "📋"
statusText: "Week 03 · Lab 01 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `cd week-03/labs/lab-01-compose-wordpress/starter` | Enter starter directory |
| `docker compose up -d` | Start stack in detached mode |
| `docker compose ps` | Check service status and health |
| `watch docker compose ps` | Watch until DB becomes healthy |
| `curl -s localhost:8080 | head -20` | Fetch WordPress response snippet |
| `docker network ls` | List Docker networks |
| `docker network inspect starter_default` | Inspect Compose-created network |
| `docker volume ls` | List Docker volumes |
| `docker volume inspect starter_db-data` | Inspect DB volume |
| `docker compose exec wordpress bash` | Shell into WordPress container |
| `cat /etc/resolv.conf` | Show DNS config inside container |
| `getent hosts db` | Resolve MySQL service name |
| `apt-get update && apt-get install -y default-mysql-client` | Install MySQL client in container |
| `mysql -h db -u wordpress -pwordpress -e "SHOW DATABASES;"` | Verify DB connectivity |
| `exit` | Leave container shell |
| `docker compose down` | Stop/remove containers and network |
| `docker volume ls | grep db-data` | Verify volume persists after `down` |
| `docker compose down -v` | Remove containers, network, and volumes |
| `docker compose logs` | Show all service logs |
| `docker compose logs -f wordpress` | Follow WordPress logs |
| `docker compose logs --tail 20 db` | Show last 20 MySQL log lines |
| `curl localhost:8080 > /dev/null` | Trigger request for log observation |

---
layout: win95
windowTitle: "Stack Relationship"
windowIcon: "🔗"
statusText: "Week 03 · Lab 01 · Service flow"
---

## Service and Persistence Flow

```text
User -> localhost:8080 -> wordpress service -> db service (hostname: db)
                                           |
                                           -> named volume: db-data (/var/lib/mysql)

docker compose down      -> containers removed, volume kept
docker compose down -v   -> containers and volume removed
```
