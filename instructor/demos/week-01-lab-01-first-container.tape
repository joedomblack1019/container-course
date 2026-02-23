# Demo: Your First Container
# Week 1, Lab 1 — docker run -> docker ps -> curl -> exec -> lifecycle
#
# Prerequisites: Docker installed
# NOTE: nginx image is pre-pulled in hidden setup so `docker run` is instant.

Output ../../assets/generated/week-01-lab-01/demo.gif

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
# Pre-pull nginx so run is instant
Type "docker pull nginx -q 2>/dev/null"
Enter
Sleep 20s
# Clean up any leftovers
Type "docker rm -f my-nginx 2>/dev/null"
Enter
Sleep 1s
Type "clear"
Enter
Sleep 500ms
Show

# --- Visible Demo ---

# Run nginx in the background with port mapping
Type "docker run -d --name my-nginx -p 8080:80 nginx"
Enter
Sleep 3s

# Show it running
Type "docker ps"
Enter
Sleep 4s

# Hit the web server
Type "curl -s localhost:8080 | head -5"
Enter
Sleep 4s

# Look inside the running container
Type "docker exec my-nginx hostname"
Enter
Sleep 3s

Type "docker exec my-nginx ls /usr/share/nginx/html"
Enter
Sleep 3s

# Check the logs — our curl request is there
Type "docker logs my-nginx"
Enter
Sleep 4s

# Stop it — container still exists
Type "docker stop my-nginx"
Enter
Sleep 3s

Type "docker ps -a --filter name=my-nginx"
Enter
Sleep 4s

# Start it back up — it remembers everything
Type "docker start my-nginx"
Enter
Sleep 2s

Type "curl -s localhost:8080 | head -5"
Enter
Sleep 4s

# --- Hidden Cleanup ---
Hide
Type "docker rm -f my-nginx 2>/dev/null"
Enter
Sleep 1s
