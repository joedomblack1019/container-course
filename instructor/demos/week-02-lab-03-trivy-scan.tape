# Demo: Security Scanning with Trivy
# Week 2, Lab 3 — Scan a deliberately vulnerable image, see the CVE report
#
# Prerequisites: Docker installed, trivy installed
# NOTE: Uses a taller window and smaller font to fit Trivy's wide table output.
#       The vulnerable image and trivy DB are prepared in hidden setup.

Output ../../assets/generated/week-02-lab-03/demo.gif

Require docker
Require trivy

Set Shell "bash"
Set FontFamily "Monaspace Neon"
Set FontSize 14
Set Width 1200
Set Height 700
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
Type "cp -a ../week-02/labs/lab-03-security-scanning/starter/. $DEMO/"
Enter
Type "cd $DEMO"
Enter
Sleep 300ms
# Build the intentionally vulnerable image
Type "docker build -t vulnerable-app:v1 . -q 2>/dev/null"
Enter
Sleep 30s
# Pre-download the vulnerability database so the visible scan is fast
Type "trivy image --download-db-only 2>/dev/null"
Enter
Sleep 30s
Type "clear"
Enter
Sleep 500ms
Show

# --- Visible Demo ---

# Scan the vulnerable image — CRITICAL and HIGH only
Type "trivy image --severity CRITICAL,HIGH vulnerable-app:v1"
Enter
Sleep 15s

# Let the viewer absorb the wall of CVEs
Sleep 3s

# Also scan the Dockerfile for misconfigurations
Type "trivy config Dockerfile"
Enter
Sleep 10s

# --- Hidden Cleanup ---
Hide
Type "docker rmi vulnerable-app:v1 2>/dev/null"
Enter
Type "rm -rf $DEMO"
Enter
Sleep 1s
