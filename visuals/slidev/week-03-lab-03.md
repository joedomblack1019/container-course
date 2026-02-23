---
theme: default
title: Week 03 Lab 03 - Development Workflow with Bind Mounts
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "03"
lab: "Lab 03 · Development Workflow with Bind Mounts"
---

# Development Workflow with Bind Mounts
## Lab 03

- Compare slow rebuild workflow vs bind-mount workflow
- Use `docker-compose.dev.yml` for live code reload
- Verify Redis-backed state survives web container restart
- Practice service discovery from `web` to `redis`

---
layout: win95
windowTitle: "Prod vs Dev Compose"
windowIcon: "⚙"
statusText: "Week 03 · Lab 03 · Fast iteration setup"
---

## What Changes in Development Mode

| Mode | Pattern | Effect |
|---|---|---|
| **Prod** | Code baked with `COPY` | Requires rebuild to see edits |
| **Dev** | Bind mount `./app.py:/app/app.py` | Edits appear instantly |
| **Dev** | `FLASK_DEBUG=1` | Auto-reload on file changes |

```yaml
volumes:
  - ./app.py:/app/app.py

environment:
  - FLASK_DEBUG=1
```

---
layout: win95-terminal
termTitle: "Command Prompt — slow workflow baseline"
---

<Win95Terminal
  title="Command Prompt — without bind mounts"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd week-03/labs/lab-03-dev-workflow/starter' },
    { type: 'input', text: 'cat app.py' },
    { type: 'input', text: 'docker compose -f docker-compose.prod.yml up -d --build' },
    { type: 'input', text: 'curl localhost:5000' },
    { type: 'input', text: 'curl localhost:5000' },
    { type: 'input', text: 'curl localhost:5000' },
    { type: 'input', text: 'curl localhost:5000' },
    { type: 'comment', text: '# Edit app.py and response does not change until rebuild' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — rebuild cycle then switch to dev"
---

<Win95Terminal
  title="Command Prompt — rebuild required in prod mode"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker compose -f docker-compose.prod.yml up -d --build' },
    { type: 'input', text: 'curl localhost:5000' },
    { type: 'input', text: 'docker compose -f docker-compose.prod.yml down' },
    { type: 'input', text: 'docker compose -f docker-compose.dev.yml up -d --build' },
    { type: 'input', text: 'cat docker-compose.dev.yml' },
    { type: 'input', text: 'curl localhost:5000' },
    { type: 'success', text: 'Dev stack running with bind mount + FLASK_DEBUG=1' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — live reload and redis persistence"
---

<Win95Terminal
  title="Command Prompt — fast feedback loop"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'comment', text: '# Edit app.py, save file, then re-request immediately' },
    { type: 'input', text: 'curl localhost:5000' },
    { type: 'input', text: 'curl localhost:5000' },
    { type: 'input', text: 'curl localhost:5000' },
    { type: 'input', text: 'docker compose -f docker-compose.dev.yml restart web' },
    { type: 'input', text: 'curl localhost:5000' },
    { type: 'success', text: 'Counter value persists because Redis stores the state' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — redis inspection, service DNS, cleanup"
---

<Win95Terminal
  title="Command Prompt — redis and networking checks"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker compose -f docker-compose.dev.yml exec redis redis-cli' },
    { type: 'input', text: 'GET hits' },
    { type: 'input', text: 'INCR hits' },
    { type: 'input', text: 'GET hits' },
    { type: 'input', text: 'exit' },
    { type: 'input', text: 'docker compose -f docker-compose.dev.yml exec web sh -c &quot;getent hosts redis&quot;' },
    { type: 'input', text: 'docker compose -f docker-compose.dev.yml down -v' },
    { type: 'success', text: 'Lab cleanup complete' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 03 — Key Commands"
windowIcon: "📋"
statusText: "Week 03 · Lab 03 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `cd week-03/labs/lab-03-dev-workflow/starter` | Enter starter directory |
| `cat app.py` | Inspect Flask app source |
| `docker compose -f docker-compose.prod.yml up -d --build` | Build/start production-style stack |
| `curl localhost:5000` | Test app and increment counter |
| `docker compose -f docker-compose.prod.yml down` | Stop production stack |
| `docker compose -f docker-compose.dev.yml up -d --build` | Build/start development stack |
| `cat docker-compose.dev.yml` | Inspect bind-mount and debug config |
| `docker compose -f docker-compose.dev.yml restart web` | Restart only web service |
| `docker compose -f docker-compose.dev.yml exec redis redis-cli` | Enter Redis CLI |
| `GET hits` | Read counter value in Redis |
| `INCR hits` | Increment counter directly in Redis |
| `exit` | Leave Redis CLI |
| `docker compose -f docker-compose.dev.yml exec web sh -c "getent hosts redis"` | Verify service discovery from web to redis |
| `docker compose -f docker-compose.dev.yml down -v` | Stop stack and remove volumes |

---
layout: win95
windowTitle: "Dev Loop Diagram"
windowIcon: "🔁"
statusText: "Week 03 · Lab 03 · Edit-save-request cycle"
---

## Iteration Cycle

```text
Edit app.py on host
   -> bind mount updates /app/app.py in container
   -> FLASK_DEBUG=1 reloads app process
   -> curl localhost:5000 shows change immediately

Redis remains separate, so counter data survives web restarts.
```
