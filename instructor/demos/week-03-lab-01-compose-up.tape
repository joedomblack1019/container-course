# Demo: Docker Compose — WordPress + MySQL in One Command
# Week 3, Lab 1 — docker compose up -> health checks -> WordPress responds
#
# Prerequisites: Docker installed (with compose plugin)
# NOTE: Images are pre-pulled in hidden setup. The MySQL health check wait
#       (~40s) is also hidden so the viewer sees the stack go from "up" to
#       "healthy" without staring at a timer.

Output ../../assets/generated/week-03-lab-01/demo.gif

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
Type "cp ../week-03/labs/lab-01-compose-wordpress/solution/docker-compose.yml $DEMO/"
Enter
Type "cd $DEMO"
Enter
Sleep 300ms
# Pre-pull images so compose up is fast
Type "docker pull wordpress:latest -q 2>/dev/null"
Enter
Sleep 30s
Type "docker pull mysql:8.0 -q 2>/dev/null"
Enter
Sleep 30s
# Clean up any leftover stack
Type "docker compose down -v 2>/dev/null"
Enter
Sleep 3s
Type "clear"
Enter
Sleep 500ms
Show

# --- Visible Demo ---

# Show the compose file
Type "cat docker-compose.yml"
Enter
Sleep 7s

# Bring up the entire stack — one command
Type "docker compose up -d"
Enter
Sleep 8s

# Wait for MySQL health check (hidden — takes ~40s)
Hide
Sleep 45s
Show

# Show both services running and healthy
Type "docker compose ps"
Enter
Sleep 5s

# WordPress is responding
Type "curl -s localhost:8080 | head -20"
Enter
Sleep 5s

# Clean teardown
Type "docker compose down -v"
Enter
Sleep 8s

# --- Hidden Cleanup ---
Hide
Type "rm -rf $DEMO"
Enter
Sleep 1s
