---
theme: default
title: Week 03 Lab 02 - Network Debugging
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "03"
lab: "Lab 02 · Network Debugging"
---

# Network Debugging
## Lab 02

- Reproduce a broken three-tier Compose stack
- Debug DNS, connectivity, and network membership issues
- Inspect nginx proxy and service-to-service ports
- Apply fixes and verify end-to-end API flow

---
layout: win95
windowTitle: "Target Architecture"
windowIcon: "🌐"
statusText: "Week 03 · Lab 02 · Expected traffic path"
---

## Intended Request Flow

```text
User -> :8080 -> frontend (nginx) -> api:5000 -> db:3306 (mysql)
```

| Hop | Expected behavior |
|---|---|
| `frontend -> api` | DNS for `api` resolves and port matches nginx upstream |
| `api -> db` | DNS for `db` resolves and DB host env var is valid |
| Network design | Services that must talk share at least one network |

---
layout: win95-terminal
termTitle: "Command Prompt — reproduce failure"
---

<Win95Terminal
  title="Command Prompt — broken stack baseline"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd week-03/labs/lab-02-network-debugging/starter' },
    { type: 'input', text: 'docker compose up -d --build' },
    { type: 'input', text: 'curl localhost:8080' },
    { type: 'input', text: 'curl localhost:8080/api/items' },
    { type: 'error', text: '502 Bad Gateway / connection refused / timeout' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — bottom-up checks"
---

<Win95Terminal
  title="Command Prompt — service diagnostics"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker compose ps' },
    { type: 'input', text: 'docker compose logs <service-name>' },
    { type: 'input', text: 'docker compose exec api sh' },
    { type: 'input', text: 'getent hosts db' },
    { type: 'input', text: 'nc -zv db 3306' },
    { type: 'input', text: 'echo $DB_HOST' },
    { type: 'input', text: 'getent hosts $DB_HOST' },
    { type: 'input', text: 'exit' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — frontend and network inspection"
---

<Win95Terminal
  title="Command Prompt — frontend path checks"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker compose exec frontend sh' },
    { type: 'input', text: 'getent hosts api' },
    { type: 'input', text: 'wget -qO- http://api:5000/health || echo &quot;FAILED on 5000&quot;' },
    { type: 'input', text: 'exit' },
    { type: 'input', text: 'docker network ls | grep network-debugging' },
    { type: 'input', text: 'docker network inspect starter_frontend-net' },
    { type: 'input', text: 'docker network inspect starter_backend-net' },
    { type: 'input', text: 'docker compose exec frontend cat /etc/nginx/conf.d/default.conf' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — validate fixes"
---

<Win95Terminal
  title="Command Prompt — fixed stack verification"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker compose down' },
    { type: 'input', text: 'docker compose up -d --build' },
    { type: 'input', text: 'curl localhost:8080' },
    { type: 'input', text: 'curl localhost:8080/api/items' },
    { type: 'input', text: 'curl localhost:8080/api/health' },
    { type: 'input', text: 'curl -s localhost:8080' },
    { type: 'input', text: 'curl -s localhost:8080/api/items' },
    { type: 'input', text: 'curl -s localhost:8080/api/health' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — isolation check and cleanup"
---

<Win95Terminal
  title="Command Prompt — segmentation verification"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker compose exec frontend sh -c &quot;nc -zv db 3306 2>&1 || echo Good_frontend_cannot_reach_db_directly&quot;' },
    { type: 'success', text: 'Good: frontend cannot reach db directly' },
    { type: 'input', text: 'docker compose down -v' },
    { type: 'success', text: 'Lab cleanup complete' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 02 — Key Commands"
windowIcon: "📋"
statusText: "Week 03 · Lab 02 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `cd week-03/labs/lab-02-network-debugging/starter` | Enter broken stack starter |
| `docker compose up -d --build` | Start and build broken stack |
| `curl localhost:8080` | Test frontend root response |
| `curl localhost:8080/api/items` | Test proxied API path |
| `docker compose ps` | Check container status |
| `docker compose logs <service-name>` | Inspect logs for a specific service |
| `docker compose exec api sh` | Enter API container shell |
| `getent hosts db` | DNS lookup for DB service |
| `nc -zv db 3306` | Check TCP reachability to MySQL |
| `echo $DB_HOST` | Print DB host env var in API container |
| `getent hosts $DB_HOST` | Resolve configured DB hostname |
| `docker compose exec frontend sh` | Enter frontend container shell |
| `getent hosts api` | DNS lookup for API service |
| `wget -qO- http://api:5000/health || echo "FAILED on 5000"` | Probe API from frontend container |
| `docker network ls | grep network-debugging` | List project networks |
| `docker network inspect starter_frontend-net` | Inspect frontend network membership |
| `docker network inspect starter_backend-net` | Inspect backend network membership |
| `docker compose exec frontend cat /etc/nginx/conf.d/default.conf` | Inspect nginx upstream config |
| `docker compose down` | Stop/remove stack before retest |
| `curl localhost:8080/api/health` | Verify health path through proxy |
| `curl -s localhost:8080` | Silent frontend verification |
| `curl -s localhost:8080/api/items` | Silent API-data verification |
| `curl -s localhost:8080/api/health` | Silent API-health verification |
| `docker compose exec frontend sh -c "nc -zv db 3306 2>&1 || echo 'Good: frontend cannot reach db directly'"` | Verify frontend cannot reach DB directly |
| `docker compose down -v` | Final cleanup including volumes |

---
layout: win95
windowTitle: "Debug Loop"
windowIcon: "🧪"
statusText: "Week 03 · Lab 02 · Symptom to root cause"
---

## Troubleshooting Sequence

```text
Reproduce failure -> docker compose ps/logs
       -> exec into api/frontend for DNS + port tests
       -> inspect networks + nginx upstream
       -> apply fixes in compose/nginx config
       -> rebuild and validate end-to-end curls
```
