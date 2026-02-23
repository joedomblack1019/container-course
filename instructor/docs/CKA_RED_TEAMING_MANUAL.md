# CKA Red Teaming Manual: Comprehensive Failure Testing

**Purpose:** Stress-test every lab and gym scenario to identify failure modes, edge cases, and potential student blockers before delivery.

**Last updated:** 2026-02-17

---

## Red Teaming Philosophy

**Assume Murphy's Law:** Everything that can go wrong, will go wrong, at the worst possible time.

**Test Categories:**
1. **Infrastructure Failures** - Network, disk, memory, CPU
2. **Permission Issues** - RBAC, filesystem, context confusion
3. **Timing Problems** - Race conditions, timeouts, startup delays
4. **Environment Corruption** - Previous student artifacts, conflicting configs
5. **Human Error Simulation** - Typos, wrong commands, skipped steps
6. **Resource Exhaustion** - Limits hit, storage full, quotas exceeded

---

## Week 04 Labs

### Lab: kubeadm Bootstrap (`lab-04-kubeadm-bootstrap`)

#### Infrastructure Attack Vectors
```bash
# Network interference during bootstrap
sudo iptables -A INPUT -p tcp --dport 6443 -j DROP  # Block API server
sudo iptables -A INPUT -p tcp --dport 2379 -j DROP  # Block etcd

# Disk space exhaustion
dd if=/dev/zero of=/tmp/fillup bs=1M count=1000  # Fill /tmp
df -h  # Verify low space

# Memory pressure during init
stress --vm 2 --vm-bytes 1G --timeout 300s &  # Background memory pressure

# Container runtime down
sudo systemctl stop containerd
sudo kubeadm init --pod-network-cidr=10.244.0.0/16  # Should fail
```

#### Permission Chaos
```bash
# Wrong filesystem permissions
sudo chmod 000 /var/lib/kubelet
sudo chmod 000 /etc/kubernetes

# SELinux/AppArmor interference
sudo setenforce 1  # If SELinux available
sudo systemctl start apparmor  # If AppArmor available

# User context confusion
su - nobody -c "kubectl get nodes"  # Wrong user
unset KUBECONFIG && kubectl get nodes  # No kubeconfig
```

#### Timing and Race Conditions
```bash
# Rapid init/reset cycles
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 &
sleep 5
sudo kubeadm reset -f  # Reset while init running

# CNI timing issues
kubectl apply -f flannel.yml
kubectl get pods -n kube-system -w  # Watch for CrashLoopBackOff
sudo systemctl restart kubelet  # Restart during CNI deployment
```

#### Environment Corruption
```bash
# Leftover artifacts from previous runs
ls -la /etc/kubernetes/  # Should be empty after reset
ls -la /var/lib/etcd/     # Should be empty after reset
docker ps -a | grep k8s   # Should be empty after reset

# Conflicting cluster configs
kubectl config set-cluster fake --server=https://fake:6443
kubectl config use-context fake
kubeadm token create --print-join-command  # Should fail with wrong context
```

#### Resource Exhaustion Scenarios
```bash
# PID limit hit during bootstrap
echo 100 | sudo tee /proc/sys/kernel/pid_max
sudo kubeadm init --pod-network-cidr=10.244.0.0/16  # Should fail

# Port conflicts
sudo nc -l 6443 &  # Block API server port
sudo kubeadm init --pod-network-cidr=10.244.0.0/16  # Should fail
```

**Expected Student Blockers:**
- Forgotten `sudo` prefix causing permission errors
- Wrong pod CIDR causing CNI conflicts with existing networks
- Skipping kubeconfig setup causing "connection refused" errors
- Confusing init output with actual success vs partial success

---

### Lab: RBAC Authorization (`lab-05-rbac-authz`)

#### Permission Edge Cases
```bash
# Context switching during RBAC work
kubectl config use-context wrong-cluster
kubectl auth can-i create pods  # Should fail or return different result

# Service account token issues
kubectl create sa test-sa
kubectl get sa test-sa -o yaml | grep secrets  # Check token creation
kubectl auth can-i create pods --as=system:serviceaccount:default:test-sa

# Cluster vs namespaced role confusion
kubectl create clusterrole test-role --verb=get --resource=pods
kubectl create rolebinding test-bind --clusterrole=test-role --user=test-user
kubectl auth can-i get pods --as=test-user -n kube-system  # Should fail
```

#### API Server Stress
```bash
# Concurrent RBAC rule evaluation
for i in {1..50}; do
  kubectl auth can-i create pods --as=user$i &
done
wait  # Check for API server overload

# Invalid resource types
kubectl auth can-i get nonexistent --as=test-user  # Should fail gracefully

# Malformed subjects in bindings
kubectl create rolebinding bad-binding --clusterrole=view --user=""  # Empty user
kubectl create rolebinding bad-binding --clusterrole=view --user="user with spaces"
```

#### Timing Issues
```bash
# Role created but binding not yet propagated
kubectl create role test-role --verb=get --resource=pods
kubectl create rolebinding test-bind --role=test-role --user=test-user &
kubectl auth can-i get pods --as=test-user  # Might be eventual consistency issue
```

**Expected Student Blockers:**
- Forgetting `--as` flag in `kubectl auth can-i` commands
- ClusterRole vs Role confusion (namespace scope)
- Binding wrong subject types (User vs ServiceAccount vs Group)
- Case sensitivity in usernames and group names

---

## Week 05 Labs

### Lab: etcd Snapshot and Restore (`lab-04-etcd-snapshot-restore`)

#### Certificate and TLS Chaos
```bash
# Wrong certificate paths
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/ca.crt \
  --cert=/tmp/fake.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /tmp/snapshot.db  # Should fail

# Certificate expired simulation
sudo rm /etc/kubernetes/pki/etcd/server.crt
sudo openssl x509 -req -in /dev/null -signkey /etc/kubernetes/pki/etcd/server.key \
  -out /etc/kubernetes/pki/etcd/server.crt -not_before -1 -not_after 0  # Expired cert
```

#### Storage and Filesystem Issues
```bash
# Disk full during snapshot
dd if=/dev/zero of=/var/lib/etcd/fillup bs=1M count=100  # Fill etcd data dir
ETCDCTL_API=3 etcdctl snapshot save /var/lib/etcd/snapshot.db  # Should fail

# Permission denied on snapshot location
sudo chmod 000 /var/lib/etcd-backups/
ETCDCTL_API=3 etcdctl snapshot save /var/lib/etcd-backups/snapshot.db

# Corrupted snapshot file
echo "corrupted" > /tmp/snapshot.db
ETCDCTL_API=3 etcdctl snapshot status /tmp/snapshot.db  # Should fail
```

#### etcd Process Interference
```bash
# etcd not running
sudo systemctl stop etcd  # If systemd managed
sudo kill $(pgrep etcd)   # If static pod, will restart

# Multiple etcd endpoints confusion
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379,https://fake-endpoint:2379 \
  snapshot save /tmp/snapshot.db  # Should handle endpoint failure
```

#### Restore Timing Issues
```bash
# Restore while API server running (dangerous)
ETCDCTL_API=3 etcdctl snapshot restore /tmp/snapshot.db \
  --data-dir=/var/lib/etcd-new
sudo systemctl stop kubelet  # Stop static pods
sudo mv /var/lib/etcd /var/lib/etcd-backup
sudo mv /var/lib/etcd-new /var/lib/etcd
sudo systemctl start kubelet  # Restart with new data

# API server still writing during restore
kubectl create configmap test-data --from-literal=key=value &
# Simultaneously restore older snapshot
```

**Expected Student Blockers:**
- Wrong etcdctl API version (missing `ETCDCTL_API=3`)
- Certificate path confusion between different etcd setups
- Forgetting to stop API server during actual restore
- Snapshot path permissions in container vs host filesystem

---

### Lab: StorageClass and Reclaim Policy (`lab-05-storageclass-reclaim-accessmode`)

#### Storage Provisioner Failures
```bash
# No storage provisioner available
kubectl delete storageclass standard  # Remove default storage class
kubectl create pvc test-pvc --image=nginx  # Should stay Pending

# Provisioner resource exhaustion
# Create 100 PVCs to exhaust storage quota
for i in {1..100}; do
  kubectl create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc-$i
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 10Gi
EOF
done
```

#### Access Mode Conflicts
```bash
# Multiple pods trying ReadWriteOnce on different nodes
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: rwo-test
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rwo-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rwo-test
  template:
    metadata:
      labels:
        app: rwo-test
    spec:
      containers:
      - name: test
        image: nginx
        volumeMounts:
        - name: storage
          mountPath: /data
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: rwo-test
EOF
# Pods should get stuck if scheduled on different nodes
```

#### Reclaim Policy Edge Cases
```bash
# Delete PVC with Retain policy, verify PV remains
kubectl patch pv test-pv -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
kubectl delete pvc test-pvc
kubectl get pv  # Should show Released, not Deleted

# Delete PVC with Delete policy, verify data loss
kubectl patch pv test-pv -p '{"spec":{"persistentVolumeReclaimPolicy":"Delete"}}'
kubectl delete pvc test-pvc
kubectl get pv  # Should be deleted completely

# Node failure during reclaim
sudo systemctl stop kubelet  # Simulate node failure
kubectl delete pvc test-pvc  # Should handle gracefully
```

#### File System Corruption
```bash
# Corrupt underlying storage
kubectl exec -it pod-with-pvc -- dd if=/dev/urandom of=/data/corrupt bs=1M count=1000
kubectl exec -it pod-with-pvc -- sync
sudo systemctl stop kubelet
# Corrupt filesystem at host level
sudo dd if=/dev/urandom of=/var/lib/kubelet/pods/*/volumes/*/corrupt bs=1M count=10
sudo systemctl start kubelet
```

**Expected Student Blockers:**
- AccessMode restrictions not understood (RWO vs RWX vs ROX)
- Reclaim policy behavior surprises (data loss)
- PVC stuck in Terminating due to pod still using it
- Storage class default selection confusion

---

## Week 06 Labs

### Lab: Service Types and Load Balancing (`lab-04-service-types-nodeport-loadbalancer`)

#### Network Connectivity Chaos
```bash
# Port conflicts on nodes
sudo nc -l 30080 &  # Block NodePort range
kubectl expose deployment test-app --type=NodePort --port=80 --target-port=8080
kubectl get svc  # Should allocate different port or fail

# Firewall interference
sudo iptables -A INPUT -p tcp --dport 30000:32767 -j DROP  # Block NodePort range
curl http://localhost:30080  # Should fail

# DNS resolution issues
sudo systemctl stop systemd-resolved  # Break local DNS
curl http://test-service  # Should fail
```

#### Load Balancer Provisioning Failures
```bash
# No load balancer provider in kind/local
kubectl expose deployment test-app --type=LoadBalancer --port=80
kubectl get svc  # Should show <pending> indefinitely

# Multiple LoadBalancer services competing
for i in {1..10}; do
  kubectl expose deployment test-app-$i --name=lb-$i --type=LoadBalancer --port=80 &
done
# Check if cloud provider handles concurrent requests gracefully
```

#### Endpoint Reconciliation Issues
```bash
# Pods not ready but endpoints exist
kubectl patch deployment test-app -p='{"spec":{"template":{"spec":{"containers":[{"name":"test","readinessProbe":null}]}}}}'
kubectl delete pods -l app=test-app  # Force recreation
kubectl get endpoints test-service  # Should show pod IPs even if not ready

# Pod deletion during endpoint update
kubectl scale deployment test-app --replicas=10
kubectl delete pod -l app=test-app &  # Delete pods while scaling
kubectl get endpoints test-service -w  # Watch endpoint churn
```

#### Service Mesh / CNI Conflicts
```bash
# Conflicting service CIDRs
kubectl create service clusterip test-svc-1 --tcp=80:80
kubectl create service clusterip test-svc-2 --tcp=80:80
kubectl get svc -o wide  # Check for IP conflicts

# Pod network vs service network overlap
kubectl run test-pod --image=nginx --restart=Never
kubectl exec test-pod -- curl 10.96.0.1  # Try to reach service network from pod
```

**Expected Student Blockers:**
- LoadBalancer external IP stuck pending in local environments
- NodePort range restrictions (30000-32767)
- Service selector mismatches causing no endpoints
- Network policy blocking service access

---

### Lab: CoreDNS Troubleshooting (`lab-05-coredns-troubleshooting`)

#### DNS Resolution Breakage
```bash
# CoreDNS config corruption
kubectl edit configmap coredns -n kube-system
# Add syntax error to Corefile, save, and restart CoreDNS
kubectl rollout restart deployment/coredns -n kube-system

# DNS cache poisoning
kubectl run dns-test --image=busybox --restart=Never -- nslookup kubernetes.default
kubectl exec dns-test -- echo "1.2.3.4 kubernetes.default" >> /etc/hosts

# Upstream DNS failures
kubectl patch configmap coredns -n kube-system --patch='
data:
  Corefile: |
    .:53 {
        forward . 192.0.2.1  # Non-existent upstream DNS
        cache 30
    }'
kubectl rollout restart deployment/coredns -n kube-system
```

#### Resource Exhaustion
```bash
# CoreDNS memory limit hit
kubectl patch deployment coredns -n kube-system -p='
spec:
  template:
    spec:
      containers:
      - name: coredns
        resources:
          limits:
            memory: 10Mi  # Unreasonably low
          requests:
            memory: 10Mi'

# Concurrent DNS queries overwhelming CoreDNS
for i in {1..1000}; do
  kubectl run dns-flood-$i --image=busybox --restart=Never -- \
    nslookup kubernetes.default &
done
```

#### Network Policy Interference
```bash
# Block DNS traffic
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: block-dns
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - ports:
    - protocol: TCP
      port: 80
EOF
# DNS should fail from default namespace pods
```

#### Service Discovery Edge Cases
```bash
# Service without selector (manual endpoints)
kubectl create service clusterip manual-svc --tcp=80:80
# No endpoints created automatically
kubectl run test-pod --image=nginx --restart=Never
kubectl exec test-pod -- nslookup manual-svc  # Should resolve but connect fail

# Headless service with ready vs not-ready pods
kubectl create service clusterip headless-svc --tcp=80:80 --cluster-ip=None
kubectl patch deployment test-app --patch='
spec:
  template:
    spec:
      containers:
      - name: test
        readinessProbe:
          httpGet:
            path: /nonexistent
            port: 80'
# Headless service should include non-ready pod IPs
```

**Expected Student Blockers:**
- CoreDNS pod not running but other DNS tools work
- Search domain confusion (short names vs FQDN)
- Network policies blocking port 53 traffic
- Service discovery failing due to selector mismatches

---

## Week 07 Labs

### Lab: Node Lifecycle and Upgrade (`lab-04-node-lifecycle-and-upgrade`)

#### Drain Operation Failures
```bash
# PodDisruptionBudget blocking drain
kubectl apply -f - <<EOF
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: strict-pdb
spec:
  minAvailable: 100%
  selector:
    matchLabels:
      app: critical
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: critical
  template:
    metadata:
      labels:
        app: critical
    spec:
      containers:
      - name: app
        image: nginx
EOF
kubectl cordon node-1
kubectl drain node-1 --ignore-daemonsets  # Should be blocked by PDB
```

#### Node Resource Exhaustion During Drain
```bash
# Fill up remaining nodes during drain
kubectl drain node-1 --ignore-daemonsets &
# While drain in progress, fill up other nodes
kubectl run resource-hog --image=nginx --requests='memory=1000Gi'  # Impossible to schedule

# Drain with insufficient capacity
kubectl taint nodes node-2 key=value:NoSchedule
kubectl taint nodes node-3 key=value:NoSchedule
kubectl drain node-1 --ignore-daemonsets  # Nowhere for pods to go
```

#### Upgrade Version Skew Issues
```bash
# Wrong upgrade order (workers before control plane)
kubectl drain node-worker-1 --ignore-daemonsets
ssh node-worker-1 "sudo apt update && sudo apt install kubectl=1.29.0-00 kubelet=1.29.0-00"
ssh node-worker-1 "sudo systemctl restart kubelet"
kubectl get nodes  # Check version skew warnings

# Skipped intermediate versions
# Jump from 1.27 directly to 1.29 (should be staged through 1.28)
sudo kubeadm upgrade plan v1.29.0  # Should warn about version gaps
```

#### Network Disruption During Upgrade
```bash
# Network interruption during kubeadm upgrade
sudo kubeadm upgrade apply v1.28.0 &
sleep 30
sudo iptables -A INPUT -p tcp --dport 6443 -j DROP  # Block API server mid-upgrade
sleep 60
sudo iptables -D INPUT -p tcp --dport 6443 -j DROP  # Restore connection
```

#### Rollback Scenarios
```bash
# Upgrade fails mid-process, need to rollback
sudo kubeadm upgrade apply v1.28.0
# Simulate failure by corrupting manifests
sudo rm /etc/kubernetes/manifests/kube-apiserver.yaml
sudo systemctl restart kubelet
# Now need to recover from backup manifests
```

**Expected Student Blockers:**
- Forgetting to uncordon nodes after maintenance
- PDB preventing drain operations
- Version skew confusion (worker > control plane forbidden)
- Upgrade steps done in wrong order

---

### Lab: HPA Autoscaling (`lab-05-hpa-autoscaling`)

#### Metrics API Failures
```bash
# metrics-server down
kubectl scale deployment metrics-server -n kube-system --replicas=0
kubectl autoscale deployment test-app --cpu-percent=50 --min=1 --max=5
kubectl get hpa  # Should show <unknown>/50%

# Metrics API registration broken
kubectl delete apiservice v1beta1.metrics.k8s.io
kubectl get hpa  # Should show error condition
```

#### Resource Request Misconfigurations
```bash
# No resource requests defined
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: no-requests-app
spec:
  selector:
    matchLabels:
      app: no-requests
  template:
    metadata:
      labels:
        app: no-requests
    spec:
      containers:
      - name: app
        image: nginx
        # No resource requests
EOF
kubectl autoscale deployment no-requests-app --cpu-percent=50 --min=1 --max=5
# HPA should fail to calculate utilization percentage
```

#### Scaling Conflicts
```bash
# Manual scaling vs HPA conflict
kubectl autoscale deployment test-app --cpu-percent=50 --min=1 --max=5
kubectl scale deployment test-app --replicas=10  # Manual override
kubectl get deployment test-app  # Check which wins
kubectl get hpa  # Check HPA reaction

# Multiple HPAs targeting same deployment
kubectl autoscale deployment test-app --cpu-percent=50 --min=1 --max=5 --name=hpa-1
kubectl autoscale deployment test-app --cpu-percent=70 --min=2 --max=10 --name=hpa-2
kubectl get hpa  # Both should exist but conflict
```

#### Load Generation Edge Cases
```bash
# Load generator fails to reach target
kubectl run load-generator --image=busybox --restart=Never -- \
  sh -c "while true; do wget -q -O- http://nonexistent-service; done"
kubectl get hpa -w  # Should show no CPU increase

# Load generator overwhelming the application
for i in {1..100}; do
  kubectl run load-$i --image=busybox --restart=Never -- \
    sh -c "while true; do wget -q -O- http://test-app-svc; done" &
done
# Application might crash before HPA can scale
```

#### Metrics Collection Delays
```bash
# Rapid scale events during metrics collection lag
kubectl autoscale deployment test-app --cpu-percent=10 --min=1 --max=20  # Very low threshold
# Generate burst load
kubectl run burst-load --image=busybox --restart=Never -- \
  sh -c "for i in {1..1000}; do wget -q -O- http://test-app-svc; done"
kubectl get hpa -w  # Watch for HPA thrashing
```

**Expected Student Blockers:**
- Missing resource requests causing HPA failure
- metrics-server not working in kind (needs --kubelet-insecure-tls)
- HPA stuck on <unknown> metrics due to connection issues
- Scale up happening but scale down delayed due to stabilization

---

## Week 08 Labs

### Lab: Cluster Component Troubleshooting (`lab-05-cluster-component-troubleshooting`)

#### API Server Cascading Failures
```bash
# etcd connectivity loss
sudo iptables -A OUTPUT -p tcp --dport 2379 -j DROP
kubectl get nodes  # Should fail or timeout

# API server certificate expiry
sudo mv /etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.crt.backup
sudo openssl x509 -req -in /dev/null -signkey /etc/kubernetes/pki/apiserver.key \
  -out /etc/kubernetes/pki/apiserver.crt -days -1  # Expired cert
sudo systemctl restart kubelet
kubectl get nodes  # Should fail with certificate error
```

#### Scheduler Dysfunction
```bash
# Scheduler resource exhaustion
kubectl patch deployment kube-scheduler -n kube-system -p='
spec:
  template:
    spec:
      containers:
      - name: kube-scheduler
        resources:
          limits:
            memory: 50Mi  # Too low for scheduler
          requests:
            memory: 50Mi'

# Scheduler policy corruption
kubectl edit configmap scheduler-config -n kube-system
# Add invalid JSON/YAML syntax and restart scheduler

# Node taints blocking all scheduling
kubectl taint nodes --all key=value:NoSchedule --overwrite
kubectl run test-pod --image=nginx --restart=Never
kubectl get pods  # Should be stuck Pending
```

#### Controller Manager Issues
```bash
# Controller manager leader election failure
kubectl delete pod -n kube-system -l component=kube-controller-manager
# Start second controller manager instance manually to create split-brain
docker run -d --name=rogue-controller-manager \
  k8s.gcr.io/kube-controller-manager:v1.28.0 \
  --kubeconfig=/etc/kubernetes/controller-manager.conf

# Service account token controller failure
kubectl delete secret default-token-* -n default
kubectl create pod test-pod --image=nginx
kubectl describe pod test-pod  # Should fail to mount service account token
```

#### kubelet Node-Level Failures
```bash
# Container runtime failure
sudo systemctl stop containerd
kubectl run test-pod --image=nginx --restart=Never
kubectl get pods -w  # Should show ContainerCreating -> Error

# Disk pressure on node
dd if=/dev/zero of=/var/lib/kubelet/fillup bs=1M count=1000
kubectl describe nodes  # Should show DiskPressure condition
kubectl run test-pod --image=nginx --restart=Never  # Should not schedule

# kubelet config corruption
sudo vim /var/lib/kubelet/config.yaml  # Add syntax error
sudo systemctl restart kubelet
kubectl get nodes  # Node should go NotReady
```

#### Multi-Component Cascading Failure
```bash
# Simulate realistic outage scenario
# 1. Network partition between control plane and etcd
sudo iptables -A INPUT -p tcp --dport 2379 -j DROP
# 2. One node runs out of disk space
dd if=/dev/zero of=/var/log/fillup bs=1M count=500
# 3. High load causes scheduler to become unresponsive
stress --cpu 8 --timeout 300 &
# 4. Student must triage and fix in order of impact
```

**Expected Student Blockers:**
- Component log location confusion (/var/log vs journalctl)
- Static pod manifest location confusion
- Service vs static pod restart procedures
- Cascading failure root cause identification

---

## gymctl Scenario Red Teaming

### High-Impact Scenarios

#### `jerry-etcd-snapshot-missing`
```bash
# Test etcd snapshot under disk pressure
cd gymctl && ./gym run jerry-etcd-snapshot-missing
# While scenario running, fill up the etcd backup location
kubectl exec -it etcd-pod -- dd if=/dev/zero of=/var/lib/etcd-backups/fillup bs=1M count=100

# Test with corrupted etcd certificates
kubectl exec -it etcd-pod -- mv /etc/kubernetes/pki/etcd/server.crt /tmp/
# Student should get TLS handshake failures

# Test concurrent access to etcd
kubectl exec -it etcd-pod -- sh -c "
while true; do
  ETCDCTL_API=3 etcdctl snapshot save /tmp/snapshot-\$(date +%s).db
done" &
# Student snapshot should succeed despite concurrent access
```

#### `jerry-node-notready-kubelet`
```bash
# Test kubelet failure with high pod churn
cd gymctl && ./gym run jerry-node-notready-kubelet
# Generate high pod creation/deletion rate during scenario
for i in {1..100}; do
  kubectl run stress-pod-$i --image=nginx --restart=Never
  kubectl delete pod stress-pod-$i &
done

# Test with resource pressure
stress --vm 2 --vm-bytes 500M --timeout 300 &
# kubelet should handle memory pressure gracefully

# Test with corrupted kubelet state
sudo rm -rf /var/lib/kubelet/pods/*
sudo systemctl restart kubelet
# Pods should be recreated but node recovery should still work
```

#### `jerry-hpa-not-scaling`
```bash
# Test metrics-server under load
cd gymctl && ./gym run jerry-hpa-not-scaling
# Generate metrics collection stress
for i in {1..50}; do
  kubectl run metrics-stress-$i --image=busybox --restart=Never -- \
    sh -c "while true; do cat /proc/meminfo; sleep 0.1; done" &
done
# metrics-server should handle load and HPA should still function
```

### Edge Case Testing Matrix

#### Resource Exhaustion
```bash
# Test all scenarios under memory pressure
echo 3 | sudo tee /proc/sys/vm/drop_caches
stress --vm 1 --vm-bytes 80% --timeout 600 &

# Test all scenarios under CPU pressure
stress --cpu 8 --timeout 600 &

# Test all scenarios under disk pressure
dd if=/dev/zero of=/tmp/fillup bs=1M count=1000
```

#### Network Partitioning
```bash
# Test scenarios with intermittent network issues
while true; do
  sudo iptables -A INPUT -p tcp --dport 6443 -j DROP
  sleep 10
  sudo iptables -D INPUT -p tcp --dport 6443 -j DROP
  sleep 20
done &
```

#### Timing Attacks
```bash
# Test scenarios with rapid cluster state changes
while true; do
  kubectl create namespace temp-ns-$(date +%s)
  kubectl create configmap temp-cm --from-literal=key=value -n temp-ns-*
  kubectl delete namespace temp-ns-*
  sleep 5
done &
```

---

## Student Environment Corruption Testing

### Pre-Lab State Validation
```bash
# Check for leftover artifacts from previous students
kubectl get all --all-namespaces | grep -v "kube-system\|default\|kube-public"
docker ps -a | grep -v "k8s.gcr.io"
sudo netstat -tlnp | grep ":30"  # Check for blocked NodePort range

# Validate clean kubeconfig
kubectl config get-contexts
kubectl config current-context

# Check filesystem permissions
ls -la /var/lib/kubelet/
ls -la /etc/kubernetes/
```

### Mid-Lab State Corruption
```bash
# Simulate student making wrong changes
kubectl config use-context wrong-context
kubectl create namespace accidental-namespace
kubectl apply -f /dev/stdin <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: leftover-config
  namespace: kube-system
data:
  corrupt: "data"
EOF

# Create resource quotas that interfere
kubectl create namespace student-work
kubectl apply -f - <<EOF
apiVersion: v1
kind: ResourceQuota
metadata:
  name: interfering-quota
  namespace: student-work
spec:
  hard:
    requests.cpu: "100m"
    requests.memory: 100Mi
    persistentvolumeclaims: "0"
EOF
```

### Post-Lab Cleanup Validation
```bash
# Verify complete cleanup
kubectl get all --all-namespaces | wc -l  # Should return baseline count
kubectl get pv | grep -v "Available\|Bound"  # Should be empty
kubectl get storageclasses | wc -l  # Should return expected count
sudo systemctl status kubelet containerd  # Should be active

# Check for resource leaks
kubectl top nodes
kubectl top pods --all-namespaces | head -10
df -h | grep -E "(kubelet|containerd|etcd)"
```

---

## Automated Red Team Testing Scripts

### Quick Lab Validation Script
```bash
#!/bin/bash
# red-team-quick.sh - Run basic failure scenarios against a lab

LAB_PATH="$1"
TEST_TYPE="$2"  # "infrastructure", "permissions", "timing", "resources"

case $TEST_TYPE in
  "infrastructure")
    echo "Testing infrastructure failures..."
    sudo systemctl stop containerd &
    sleep 30
    sudo systemctl start containerd
    ;;
  "permissions")
    echo "Testing permission issues..."
    sudo chmod 000 /var/lib/kubelet
    sleep 10
    sudo chmod 755 /var/lib/kubelet
    ;;
  "timing")
    echo "Testing timing issues..."
    # Rapid kubectl commands
    for i in {1..20}; do kubectl get nodes &; done
    wait
    ;;
  "resources")
    echo "Testing resource exhaustion..."
    stress --vm 2 --vm-bytes 1G --timeout 60 &
    ;;
esac

echo "Red team test completed for $LAB_PATH"
```

### Comprehensive Lab Stress Test
```bash
#!/bin/bash
# red-team-comprehensive.sh - Full failure scenario testing

# Test each lab under multiple failure conditions
LABS=("lab-04-kubeadm-bootstrap" "lab-05-rbac-authz" "lab-04-etcd-snapshot-restore"
      "lab-05-storageclass-reclaim-accessmode" "lab-04-service-types-nodeport-loadbalancer"
      "lab-05-coredns-troubleshooting" "lab-04-node-lifecycle-and-upgrade"
      "lab-05-hpa-autoscaling" "lab-05-cluster-component-troubleshooting")

for lab in "${LABS[@]}"; do
  echo "=== Red teaming $lab ==="

  # Test under each failure condition
  for test in infrastructure permissions timing resources; do
    echo "--- Testing $test failures ---"
    ./red-team-quick.sh "$lab" "$test"
    sleep 30  # Cool-down between tests
  done

  echo "=== $lab red team testing complete ==="
done
```

---

## Success Criteria for Red Team Testing

### Lab Resilience Standards
- ✅ Lab instructions work despite 90% of common environmental issues
- ✅ Failure modes are documented with clear recovery procedures
- ✅ Students can recover from mistakes without full environment reset
- ✅ Time pressure doesn't cause dangerous shortcuts or skipped safety checks

### Scenario Robustness Standards
- ✅ gymctl scenarios pass under resource pressure (80% CPU, 80% memory)
- ✅ Scenarios handle concurrent kubectl operations gracefully
- ✅ Check scripts validate behavior, not just resource presence
- ✅ Scenarios recover cleanly from partial completion states

### Student Experience Standards
- ✅ Error messages guide students toward correct solutions
- ✅ Common mistakes are caught early with helpful hints
- ✅ Catastrophic failures (cluster unusable) are prevented or documented
- ✅ Alternative approaches work when primary path fails

---

**Red Team Testing Status: 📋 FRAMEWORK COMPLETE - AWAITING EXECUTION**

This manual provides comprehensive failure scenarios for every lab and gym exercise. Execute these tests in a dedicated environment before course delivery to identify and fix potential student blockers.