---
theme: default
title: Week 02 Lab 01 - Layer Optimization Challenge
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "02"
lab: "Lab 01 · Layer Optimization Challenge"
---

# Layer Optimization Challenge
## Lab 01

- Reproduce a slow, cache-busting image rebuild
- Fix Dockerfile instruction ordering for cache hits
- Add `.dockerignore` to reduce build context
- Compare cold-cache vs warm-cache build behavior

---
layout: win95
windowTitle: "The Cache-Busting Anti-Pattern"
windowIcon: "🐳"
statusText: "Week 02 · Lab 01 · Why rebuilds are slow"
---

## Why One-Line Changes Reinstall Everything

| Dockerfile line | Cache impact |
|---|---|
| `COPY . .` | Includes frequently changing files like `app.py` |
| `RUN pip install --no-cache-dir -r requirements.txt` | Re-runs whenever previous layer changes |

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# ❌ PROBLEM: Copies everything first
COPY . .

# This runs every time ANY file changes
RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "app.py"]
```

> Once any layer changes, that layer and all later layers rebuild.

---
layout: win95
windowTitle: "Optimized Dockerfile + .dockerignore"
windowIcon: "📄"
statusText: "Week 02 · Lab 01 · Correct layering"
---

## Fix: Dependencies First, App Later

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# ✅ Copy only what pip needs
COPY requirements.txt .

# This layer is cached unless requirements.txt changes
RUN pip install --no-cache-dir -r requirements.txt

# Copy everything else AFTER dependencies are installed
COPY . .

CMD ["python", "app.py"]
```

```text
__pycache__/
*.pyc
.git/
*.md
.env
tests/
```

---
layout: win95-terminal
termTitle: "Command Prompt — observe slow rebuild"
---

<Win95Terminal
  title="Command Prompt — layer optimization"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'comment', text: '# Setup and first cold-cache build' },
    { type: 'input', text: 'cd week-02/labs/lab-01-layer-optimization/starter' },
    { type: 'input', text: 'ls' },
    { type: 'input', text: 'time docker build -t data-processor:slow .' },
    { type: 'output', text: '... RUN pip install --no-cache-dir -r requirements.txt' },
    { type: 'comment', text: '# After changing app.py, rebuild is still slow' },
    { type: 'input', text: 'time docker build -t data-processor:slow .' },
    { type: 'output', text: '... RUN pip install --no-cache-dir -r requirements.txt' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — optimized rebuild + benchmark"
---

<Win95Terminal
  title="Command Prompt — optimized path"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'comment', text: '# Build optimized Dockerfile and verify cache reuse' },
    { type: 'input', text: 'time docker build -t data-processor:fast -f Dockerfile.optimized .' },
    { type: 'input', text: 'docker build -t data-processor:fast -f Dockerfile.optimized .' },
    { type: 'output', text: 'Step 3/5 : COPY requirements.txt .   ---> Using cache' },
    { type: 'output', text: 'Step 4/5 : RUN pip install --no-cache-dir -r requirements.txt   ---> Using cache' },
    { type: 'input', text: 'time docker build -t data-processor:fast -f Dockerfile.optimized .' },
    { type: 'success', text: 'Result: rebuild completes in ~5-10 seconds' },
    { type: 'comment', text: '# Optional benchmark script' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — bonus scripts and cleanup"
---

<Win95Terminal
  title="Command Prompt — scripts + cleanup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'time docker build -t data-processor:fast -f Dockerfile.optimized .' },
    { type: 'input', text: 'cd week-02/labs/lab-01-layer-optimization' },
    { type: 'input', text: 'python3 scripts/benchmark_build_cache.py' },
    { type: 'input', text: 'python3 scripts/benchmark_build_cache.py --no-charts' },
    { type: 'input', text: 'docker rmi data-processor:slow data-processor:fast' },
    { type: 'success', text: 'Cleanup complete' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 01 — Key Commands"
windowIcon: "📋"
statusText: "Week 02 · Lab 01 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `cd week-02/labs/lab-01-layer-optimization/starter` | Enter starter directory |
| `ls` | List starter files |
| `time docker build -t data-processor:slow .` | Time slow Dockerfile build |
| `time docker build -t data-processor:fast -f Dockerfile.optimized .` | Time optimized Dockerfile build |
| `docker build -t data-processor:fast -f Dockerfile.optimized .` | Show cache hit/miss lines |
| `cd week-02/labs/lab-01-layer-optimization` | Move to benchmark script directory |
| `python3 scripts/benchmark_build_cache.py` | Run benchmark and generate charts |
| `python3 scripts/benchmark_build_cache.py --no-charts` | Run benchmark without chart generation |
| `docker rmi data-processor:slow data-processor:fast` | Remove lab images |

---
layout: win95
windowTitle: "Cache Flow"
windowIcon: "🔁"
statusText: "Week 02 · Lab 01 · Rebuild behavior"
---

## Rebuild Decision Flow

<Win95Dialog
  type="info"
  title="Layer Cache Rule"
  message="Change in app.py should only rebuild COPY app layer, not dependencies."
  detail="Bad order: COPY . . -> RUN pip install (reinstall every edit)\nGood order: COPY requirements.txt -> RUN pip install -> COPY . ."
  :buttons="['Understood']"
  :active-button="0"
/>
