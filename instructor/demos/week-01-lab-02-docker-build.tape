# Demo: Building Your First Python Container
# Week 1, Lab 2 — Dockerfile -> docker build -> docker run -> curl
#
# Prerequisites: Docker installed
# NOTE: Sleep values may need tuning for your machine's build speed.
#       Base image is pre-pulled in hidden setup to keep the visible build fast.

Output ../../assets/generated/week-01-lab-02/demo.gif

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
Type "SRC=../../week-01/labs/lab-02-python-app"
Enter
Type "cp $SRC/starter/app.py $SRC/starter/requirements.txt $DEMO/"
Enter
Type "cp $SRC/solution/Dockerfile $DEMO/"
Enter
Type "cd $DEMO"
Enter
Sleep 300ms
Type "docker pull python:3.11-slim -q 2>/dev/null"
Enter
Sleep 20s
Type "docker rm -f myapp 2>/dev/null; docker rmi my-python-app:v1 2>/dev/null"
Enter
Sleep 2s
Type "clear"
Enter
Sleep 500ms
Show

# --- Visible Demo ---

# Show the Dockerfile students will write
Type "cat Dockerfile"
Enter
Sleep 5s

# Build the image — watch each layer execute
Type "docker build -t my-python-app:v1 ."
Enter
Sleep 25s

# Check what we built
Type "docker images my-python-app"
Enter
Sleep 3s

# Run the container
Type "docker run -d --name myapp -p 5000:5000 my-python-app:v1"
Enter
Sleep 2s

# Test it
Type "curl -s localhost:5000"
Enter
Sleep 5s

# --- Hidden Cleanup ---
Hide
Type "docker rm -f myapp 2>/dev/null"
Enter
Type "docker rmi my-python-app:v1 2>/dev/null"
Enter
Type "rm -rf $DEMO"
Enter
Sleep 1s
