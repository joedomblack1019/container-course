![Lab 1 hero image](../../../assets/generated/week-02-lab-01/hero.png)

# Lab 1: Layer Optimization Challenge

**Time:** 25 minutes  
**Goal:** Fix a cache-busting Dockerfile and reduce rebuild time from minutes to seconds

---

## The Problem

You inherited a Python data processing app with a slow Dockerfile. Every tiny code change triggers a full dependency reinstall (300+ packages, 3+ minutes).

Your job: Fix the layer ordering to maximize cache hits.

---

## Setup

```bash
cd week-02/labs/lab-01-layer-optimization/starter
ls
```

You'll see:
- `app.py` - Main application (you'll modify this)
- `requirements.txt` - Dependencies (you won't change this)
- `data/` - Sample data files
- `Dockerfile` - **THE PROBLEM**

---

## Part 1: Observe the Problem

### First Build (Cold Cache)

Build the image and time it:

```bash
time docker build -t data-processor:slow .
```

Note the time. Probably 2-4 minutes depending on your connection.

### Make a Tiny Code Change

Edit `app.py` and change the welcome message:

```python
# Change this line
print("Data Processor v1.0")

# To this
print("Data Processor v1.1")
```

Save the file.

### Rebuild and Watch It Suffer

```bash
time docker build -t data-processor:slow .
```

**What happened?** Despite changing ONE LINE, Docker reinstalled all 300+ packages. Why?

---

## Part 2: Analyze the Dockerfile

Open `Dockerfile` and examine the layer order:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# ❌ PROBLEM: Copies everything first
COPY . .

# This runs every time ANY file changes
RUN pip install --no-cache-dir -r requirements.txt

CMD ["python", "app.py"]
```

**The issue:** `COPY . .` includes `app.py`, which changes frequently. This invalidates the cache for ALL subsequent layers, including the expensive `pip install`.

---

## Part 3: Fix It

Create a new file called `Dockerfile.optimized` with better layer ordering:

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

---

## Part 4: Test the Fix

### Build the Optimized Version

```bash
time docker build -t data-processor:fast -f Dockerfile.optimized .
```

First build still takes 2-4 minutes (cold cache, same as before).

### Now Change app.py Again

```python
print("Data Processor v1.2")  # Another version bump
```

### Rebuild and Marvel

```bash
time docker build -t data-processor:fast -f Dockerfile.optimized .
```

**Result:** Should complete in ~5-10 seconds!

---

## Part 5: Understand What Happened

Run this to see which layers were cached:

```bash
docker build -t data-processor:fast -f Dockerfile.optimized .
```

Look for lines that say `CACHED`:

```
Step 2/5 : WORKDIR /app
 ---> Using cache
Step 3/5 : COPY requirements.txt .
 ---> Using cache
Step 4/5 : RUN pip install --no-cache-dir -r requirements.txt
 ---> Using cache
Step 5/5 : COPY . .
 ---> a1b2c3d4e5f6
```

Only the final `COPY . .` rebuilt!

---

## Part 6: Add .dockerignore (Bonus Optimization)

Create a `.dockerignore` file to exclude unnecessary files:

```
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
*.so
.git/
.gitignore
*.md
.vscode/
.idea/
*.log
.env
tests/
*.pytest_cache
```

Rebuild:

```bash
time docker build -t data-processor:fast -f Dockerfile.optimized .
```

Even faster! Smaller build context means less to send to Docker daemon.

---

## Part 7 (Optional): Generate Benchmark Charts from Real Runs

If you want hard numbers (plus charts) for before/after comparison, run:

```bash
cd week-02/labs/lab-01-layer-optimization
python3 scripts/benchmark_build_cache.py
```

Requirements:
- Docker running
- Python 3
- `matplotlib` installed (for PNG chart output)

If `matplotlib` is not available yet, you can still collect benchmark data:

```bash
python3 scripts/benchmark_build_cache.py --no-charts
```

This runs four real builds:
- `slow_cold` (`Dockerfile`, `--no-cache`)
- `slow_rebuild` (`Dockerfile`, after a tiny `app.py` change)
- `fast_cold` (`Dockerfile.optimized`, `--no-cache`)
- `fast_rebuild` (`Dockerfile.optimized`, after a tiny `app.py` change)

Artifacts are written to:

```text
assets/generated/week-02-layer-cache/
  build_times.png
  cache_effectiveness.png
  summary.md
  results.json
  logs/
```

Use those files to show measured speedup and cache-hit differences in class.

![Build Time Benchmark Chart](../../../assets/generated/week-02-layer-cache/build_times.png)

![Layer Cache Effectiveness Chart](../../../assets/generated/week-02-layer-cache/cache_effectiveness.png)

---

## Checkpoint ✅

You should now understand:

- [ ] Why `COPY . .` before `RUN pip install` is an anti-pattern
- [ ] Layer caching relies on instruction order AND file contents
- [ ] Frequently-changing files belong at the END of the Dockerfile
- [ ] `.dockerignore` reduces build context size
- [ ] The difference between cold cache (first build) and warm cache (rebuild)

---

## Challenge: Make It Even Better

The `data/` directory has large CSV files that rarely change, but `COPY . .` includes them.

Can you:
1. Copy `data/` separately BEFORE copying `app.py`?
2. Measure if this improves cache hits when only `app.py` changes?

**Hint:** You can have multiple `COPY` instructions:

```dockerfile
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY data/ ./data/
COPY app.py .
CMD ["python", "app.py"]
```

---

## Clean Up

```bash
docker rmi data-processor:slow data-processor:fast
```

---

## Demo

![Layer Optimization Demo](../../../assets/week-02-lab-01-layer-cache.gif)

---

## Key Takeaway

> **Put frequently-changing files at the END of your Dockerfile.**

This single principle will save you hours of build time over your career.
