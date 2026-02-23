# Container Registries Demo - Docker Hub and GHCR
# Shows real login, tag, push workflow with actual commands

Output ../../assets/generated/week-01-lab-03/demo.gif

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
# Clean up any existing tags
Type "docker rmi jlgore/jerry-fat-test:v2 ghcr.io/jlgore/jerry-fat-test:v2 2>/dev/null || true"
Enter
Sleep 2s
Type "clear"
Enter
Sleep 500ms
Show

# --- Visible Demo ---

Type "# Container Registries Demo - Lab 03"
Enter
Type "# Let's push jerry-fat-test to both Docker Hub and GHCR"
Enter
Sleep 2s

Type "# First, let's see our current images"
Enter
Type "docker images | grep jerry-fat-test"
Enter
Sleep 2s

Type "# Part 1: Docker Hub Workflow"
Enter
Sleep 1s
Type "# Step 1: Login to Docker Hub (will prompt for credentials)"
Enter
Type "docker login"
Enter
Sleep 4s

Type "# Step 2: Tag for Docker Hub (format: username/image:tag)"
Enter
Type "docker tag jerry-fat-test:v2 jlgore/jerry-fat-test:v2"
Enter
Sleep 1s

Type "# Step 3: Push to Docker Hub"
Enter
Type "docker push jlgore/jerry-fat-test:v2"
Enter
Sleep 8s

Type "# Part 2: GitHub Container Registry (GHCR)"
Enter
Sleep 1s
Type "# Step 1: Get GitHub token and login"
Enter
Type "gh auth token | docker login ghcr.io -u jlgore --password-stdin"
Enter
Sleep 2s

Type "# Step 2: Tag for GHCR (format: ghcr.io/username/image:tag)"
Enter
Type "docker tag jerry-fat-test:v2 ghcr.io/jlgore/jerry-fat-test:v2"
Enter
Sleep 1s

Type "# Step 3: Push to GHCR"
Enter
Type "docker push ghcr.io/jlgore/jerry-fat-test:v2"
Enter
Sleep 8s

Type "# Let's verify both tags exist locally"
Enter
Type "docker images | grep jerry-fat-test"
Enter
Sleep 2s

Type "# Success! Same image, different registry paths:"
Enter
Type "# Docker Hub: jlgore/jerry-fat-test:v2"
Enter
Type "# GHCR:       ghcr.io/jlgore/jerry-fat-test:v2"
Enter
Sleep 2s

Type "# Both are now publicly available for docker pull!"
Enter

# --- Hidden Cleanup ---
Hide
Type "# Clean up the demo tags"
Enter
Type "docker rmi jlgore/jerry-fat-test:v2 ghcr.io/jlgore/jerry-fat-test:v2 2>/dev/null || true"
Enter
Sleep 2s

Sleep 3s