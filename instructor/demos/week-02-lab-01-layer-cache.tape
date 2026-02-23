# Demo: Layer Optimization — From 3 Minutes to 5 Seconds
# Week 2, Lab 1 — Bad layer order vs optimized: watch the cache do its thing
#
# Prerequisites: Docker installed
# NOTE: python:3.11-slim and all pip dependencies are pre-installed during
#       hidden setup. Both the slow and optimized Dockerfiles are built once
#       (cold cache) so the visible demo can show the dramatic rebuild difference.

Output ../../assets/generated/week-02-lab-01/demo.gif

Require docker

Set Shell "bash"
Set FontFamily "Monaspace Neon"
Set FontSize 16
Set Width 1200
Set Height 600
Set Theme "Catppuccin Mocha"
Set TypingSpeed 40ms
Set Padding 20

# --- Hidden Setup ---
Hide
Type "export PS1='$ '"
Enter
Sleep 300ms
Type "DEMO=$(mktemp -d)"
Enter
Sleep 300ms
Type "SRC=../week-02/labs/lab-01-layer-optimization/starter"
Enter
Type "cp $SRC/app.py $SRC/requirements.txt $SRC/Dockerfile $DEMO/"
Enter
Type "cp ../week-02/labs/lab-01-layer-optimization/solution/Dockerfile.optimized $DEMO/"
Enter
Type "cd $DEMO"
Enter
Sleep 300ms
# Pre-pull base image
Type "docker pull python:3.11-slim -q 2>/dev/null"
Enter
Sleep 20s
# Cold-build both so pip packages are cached in Docker layer cache
Type "docker build -t data-processor:slow . -q 2>/dev/null"
Enter
Sleep 120s
Type "docker build -t data-processor:fast -f Dockerfile.optimized . -q 2>/dev/null"
Enter
Sleep 120s
# Clean images but keep the build cache
Type "docker rmi data-processor:slow data-processor:fast 2>/dev/null"
Enter
Sleep 2s
Type "clear"
Enter
Sleep 500ms
Show

# --- Visible Demo ---

# Show the bad Dockerfile
Type "cat Dockerfile"
Enter
Sleep 5s

# Build with the bad layer order (uses cache from hidden cold build)
Type "time docker build -t data-processor:slow . 2>&1 | tail -8"
Enter
Sleep 15s

# Make a tiny code change
Type "sed -i 's/v1.0/v1.1/' app.py"
Enter
Sleep 2s

# Rebuild — everything re-runs because COPY . . busted the cache
Type "time docker build -t data-processor:slow . 2>&1 | tail -8"
Enter
Sleep 60s

# Now show the optimized Dockerfile
Type "cat Dockerfile.optimized"
Enter
Sleep 5s

# Make another tiny change
Type "sed -i 's/v1.1/v1.2/' app.py"
Enter
Sleep 2s

# Rebuild with optimized order — pip install is CACHED
Type "time docker build -t data-processor:fast -f Dockerfile.optimized . 2>&1 | tail -8"
Enter
Sleep 15s

# --- Hidden Cleanup ---
Hide
Type "docker rmi data-processor:slow data-processor:fast 2>/dev/null"
Enter
Type "rm -rf $DEMO"
Enter
Sleep 1s
