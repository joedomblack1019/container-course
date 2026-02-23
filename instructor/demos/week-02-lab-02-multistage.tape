# Demo: Multi-Stage Builds — From 1GB to 15MB
# Week 2, Lab 2 — Compare single-stage vs multi-stage image sizes
#
# Prerequisites: Docker installed
# NOTE: Both images are built in hidden setup. The visible demo focuses on
#       showing the Dockerfiles and the dramatic size comparison.

Output ../../assets/generated/week-02-lab-02/demo.gif

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
Type "cp -a ../week-02/labs/lab-02-multistage-build/starter/. $DEMO/"
Enter
Type "cp ../week-02/labs/lab-02-multistage-build/solution/Dockerfile.multistage $DEMO/"
Enter
Type "cd $DEMO"
Enter
Sleep 300ms
# Pre-pull base images
Type "docker pull golang:1.21 -q 2>/dev/null"
Enter
Sleep 30s
Type "docker pull alpine:3.18 -q 2>/dev/null"
Enter
Sleep 15s
# Build both images ahead of time
Type "docker build -t go-api:fat . -q 2>/dev/null"
Enter
Sleep 90s
Type "docker build -t go-api:lean -f Dockerfile.multistage . -q 2>/dev/null"
Enter
Sleep 90s
Type "docker rm -f api-test 2>/dev/null"
Enter
Sleep 1s
Type "clear"
Enter
Sleep 500ms
Show

# --- Visible Demo ---

# Show the single-stage Dockerfile (the problem)
Type "cat Dockerfile"
Enter
Sleep 5s

# Show the multi-stage Dockerfile (the fix)
Type "cat Dockerfile.multistage"
Enter
Sleep 7s

# The payoff — size comparison
Type "docker images go-api"
Enter
Sleep 5s

# Prove the lean image still works
Type "docker run -d -p 8080:8080 --name api-test go-api:lean"
Enter
Sleep 2s

Type "curl -s localhost:8080/health"
Enter
Sleep 3s

Type "curl -s localhost:8080/info | python3 -m json.tool"
Enter
Sleep 4s

# --- Hidden Cleanup ---
Hide
Type "docker rm -f api-test 2>/dev/null"
Enter
Type "docker rmi go-api:fat go-api:lean 2>/dev/null"
Enter
Type "rm -rf $DEMO"
Enter
Sleep 1s
