# Demo: Kubernetes Deploy, Scale & Self-Healing
# Week 4, Lab 2 — kubectl apply -> scale -> delete pod -> watch it come back
#
# Prerequisites:
#   - kind cluster named "lab" running:  kind create cluster --name lab
#   - kubectl configured for the kind cluster
# NOTE: The student-app:v4 image is built and loaded into kind during hidden
#       setup. Pod readiness depends on the readiness probe (5-15s).

Output ../../assets/generated/week-04-lab-02/demo.gif

Require kubectl

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
Type "SRC=../week-04/labs/lab-02-deploy-and-scale"
Enter
# Build the student app image and load into kind
Type "docker build -t student-app:v4 $SRC/starter/ -q 2>/dev/null"
Enter
Sleep 20s
Type "kind load docker-image student-app:v4 --name lab 2>/dev/null"
Enter
Sleep 15s
# Copy manifests and set replicas to 1 for the demo
Type "cp $SRC/solution/deployment.yaml $SRC/solution/service.yaml $DEMO/"
Enter
Type "sed -i 's/replicas: 3/replicas: 1/' $DEMO/deployment.yaml"
Enter
Type "cd $DEMO"
Enter
Sleep 300ms
# Clean up any previous deployment
Type "kubectl delete deployment student-app 2>/dev/null; kubectl delete svc student-app-svc 2>/dev/null"
Enter
Sleep 5s
Type "clear"
Enter
Sleep 500ms
Show

# --- Visible Demo ---

# Deploy the application
Type "kubectl apply -f deployment.yaml"
Enter
Sleep 3s

Type "kubectl apply -f service.yaml"
Enter
Sleep 2s

# Watch the pod start
Type "kubectl get pods -w"
Enter
Sleep 15s
Ctrl+C
Sleep 1s

# Scale to 3 replicas
Type "kubectl scale deployment student-app --replicas=3"
Enter
Sleep 3s

# Hidden wait for pods to be ready
Hide
Sleep 15s
Show

Type "kubectl get pods"
Enter
Sleep 5s

# Self-healing: delete a pod and watch Kubernetes replace it
Type "kubectl delete pod $(kubectl get pods -l app=student-app -o jsonpath='{.items[0].metadata.name}') --grace-period=1"
Enter
Sleep 5s

Type "kubectl get pods"
Enter
Sleep 5s

# --- Hidden Cleanup ---
Hide
Type "kubectl delete -f deployment.yaml -f service.yaml 2>/dev/null"
Enter
Type "rm -rf $DEMO"
Enter
Sleep 3s
