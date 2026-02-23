![Lab 06 CNI Plugin Comparison](../../../assets/generated/week-06-lab-06/hero.png)
![Lab 06 kindnet Calico Cilium comparison workflow](../../../assets/generated/week-06-lab-06/flow.gif)

---

# Lab 6: CNI Plugin Comparison (CKA Extension)

**Time:** 45–55 minutes
**Objective:** Bootstrap kind clusters with three different CNIs, observe exactly what changes between them, and build a decision framework for choosing the right CNI in production.

---

## The Story

This is a classic platform trap: teams apply NetworkPolicies, assume they are protected, and only discover during an incident that their CNI never enforced the rules. Everything looked valid in YAML, but enforcement was missing at the data-plane layer. In this lab, you will reproduce that mismatch, then compare kindnet, Calico, and Cilium so you can diagnose quickly and choose the right CNI for real production constraints.

---

## CKA Objectives Mapped

- Install a CNI plugin into a cluster that has no network provider
- Understand the role of the CNI in pod networking and NetworkPolicy enforcement
- Choose an appropriate CNI for a given scenario (exam knowledge question)

---

## Background: What a CNI Actually Does

When a pod is created, kubelet needs to do three things at the network level:

1. **Assign the pod an IP address** — from the cluster's pod CIDR
2. **Connect the pod to the cluster network** — so other pods can reach it
3. **Enforce NetworkPolicy rules** — if any exist that select this pod

The Container Network Interface (CNI) is the plugin that does all three. Kubernetes defines the interface; the CNI provides the implementation.

```
kubelet creates pod
    │
    └─► calls CNI plugin binary
              │
              ├─► allocates IP from pod CIDR  (IPAM)
              ├─► creates veth pair, bridges node interface
              └─► programs kernel rules for NetworkPolicy enforcement
```

**The critical operational fact:** Not all CNIs implement step 3. Some only do steps 1 and 2. If you apply a NetworkPolicy on a cluster whose CNI does not enforce policies, the objects exist in etcd but have zero effect on traffic. No error, no warning — traffic just flows.

This lab makes that difference visible.

---

## CNI Landscape

| CNI | Networking model | NetworkPolicy enforcement | L7 policy | Observability | Common use case |
|---|---|---|---|---|---|
| **kindnet** | Simple L2 bridge | **No** | No | Minimal | kind local dev, CNI-agnostic testing |
| **Flannel** | VXLAN overlay | No (needs Calico on top) | No | Minimal | Simplest multi-node overlay |
| **Calico** | BGP or VXLAN | **Yes** | No (base) | Moderate | Production bare-metal, VMs, air-gapped |
| **Cilium** | eBPF | **Yes** | **Yes** | Hubble (full flow visibility) | Cloud-native, service mesh, shared clusters |
| **Weave** | Mesh overlay | Yes | No | Moderate | Legacy; largely superseded |

The shared cluster in this course runs **Cilium**. This lab gives you the hands-on comparison with kindnet and Calico, and explains when you'd choose Cilium instead.

---

## Prerequisites

This lab spins up dedicated kind clusters. Each cluster uses CPU and memory from your host. Run clusters sequentially — create and delete before moving to the next.

Starter assets are in [`starter/`](./starter/):

- `kind-calico.yaml`
- `kind-cilium.yaml`
- `test-workloads.yaml`
- `deny-policy.yaml`

---

## Part 1: The Default CNI (kindnet)

Create a standard kind cluster. Unless you pass `disableDefaultCNI: true`, kind installs kindnet automatically.

This first cluster is your baseline networking environment: simple pod-to-pod routing with minimal features.

```bash
kind create cluster --name cni-default
kubectl config use-context kind-cni-default
kubectl get nodes
```

Notice: you are confirming both cluster creation and context targeting before any policy tests. If you run later commands in the wrong context, every comparison in this lab becomes unreliable.

Wait for the node to reach `Ready`. kindnet provides pod IPs immediately; pods can communicate across the cluster.

Deploy the test workloads — an nginx server and a curl client:

You are creating a tiny controlled traffic path (`client` -> `server`) so policy effects are obvious and repeatable.

```bash
kubectl apply -f starter/test-workloads.yaml
kubectl wait --for=condition=Ready pod/server pod/client --timeout=60s
```

Notice: wait for explicit `Ready` before testing traffic. Otherwise a failed curl could be startup timing noise instead of a networking signal.

Verify connectivity from client to server:

```bash
kubectl exec client -- curl -s --max-time 5 http://server
```

Notice: this successful response is your known-good baseline. You need this proof so later denial behavior can be attributed to policy enforcement, not app health.

Operator mindset: establish a clean baseline path before evaluating controls.

You should see the nginx welcome page HTML — pods are communicating normally.

---

## Part 2: NetworkPolicy Does Nothing on kindnet

Now apply a NetworkPolicy that should deny all ingress to the server pod:

You are intentionally creating an expectation mismatch: valid policy object, unchanged traffic. This is the key lesson of non-enforcing CNIs.

```bash
kubectl apply -f starter/deny-policy.yaml
kubectl get networkpolicy deny-server-ingress
kubectl describe networkpolicy deny-server-ingress
```

Notice: these commands prove API acceptance and policy shape, not enforcement. Kubernetes can store a correct policy object even when the CNI ignores it at runtime.

The policy exists. The spec is correct. Now test connectivity:

```bash
kubectl exec client -- curl -s --max-time 5 http://server
```

Notice: success here is the diagnostic signal. If deny policy is present but traffic still flows, enforcement is missing in the data plane.

**The request still succeeds.** You'll see the nginx HTML again.

This is not a bug in your policy. kindnet does not implement NetworkPolicy enforcement. It assigns IPs and routes traffic between pods — nothing more. The API accepts the `NetworkPolicy` object, stores it in etcd, and does nothing with it, because kindnet never reads policy objects.

Run a final check to confirm the policy is syntactically valid:

This check removes the "maybe my YAML is wrong" doubt and keeps your diagnosis focused on CNI capability.

```bash
kubectl describe networkpolicy deny-server-ingress
# Look for: "Allowing ingress traffic:" — it should say "0 Ingress rules blocking all ingress traffic"
# The description is accurate. kindnet just doesn't act on it.
```

Operator mindset: separate object validity from runtime enforcement.

Record this in your notes: **NetworkPolicy on kindnet = audit trail only**. It's a common source of "my NetworkPolicy doesn't work" incidents when a team moves a manifest from a Cilium/Calico cluster to a kindnet dev cluster, or uses Flannel without a NetworkPolicy-capable add-on.

---

## Part 3: What Happens Without Any CNI

Delete the default cluster and create one with the CNI disabled:

Now you move from "CNI with limited features" to "no CNI at all" to see exactly where cluster behavior breaks.

```bash
kind delete cluster --name cni-default

kind create cluster --name cni-calico --config starter/kind-calico.yaml
kubectl config use-context kind-cni-calico
```

Notice: this cluster is intentionally incomplete. The point is to observe the failure signature kubelet reports when networking is absent.

Check node status:

```bash
kubectl get nodes
```

Notice: `NotReady` here is expected and useful evidence, not a surprise error.

The node shows `NotReady`. Check why:

```bash
kubectl describe node cni-calico-control-plane | grep -A10 "Conditions:"
```

Notice: look specifically for `NetworkPluginNotReady`. That phrase is your high-confidence indicator that node readiness is blocked by missing CNI.

You'll see a condition like:

```
Ready  False  ...  KubeletNotReady  container runtime network not ready: NetworkReady=false
                                    reason:NetworkPluginNotReady message:Network plugin returns error...
```

Now try to deploy a pod:

You are validating downstream impact: without CNI, workload scheduling and pod networking cannot proceed normally.

```bash
kubectl run probe --image=nginx:1.27
kubectl get pods -w
```

Notice: `Pending` confirms the cluster control plane is alive, but pod networking prerequisites are not satisfied.

The pod stays `Pending`. Check why:

```bash
kubectl describe pod probe | grep -A5 Events:
```

Notice: pod events tell you the scheduler/runtime reason directly, which is faster than guessing from status alone.

The pod can't be scheduled to a node without a working network plugin. The CNI is a hard requirement for pod networking, not a nice-to-have.

Delete the probe pod — you'll bring up the real workloads after installing Calico:

```bash
kubectl delete pod probe --ignore-not-found
```

Operator mindset: prove the failure chain from node condition -> pod symptom before installing a fix.

---

## Part 4: Install Calico

Apply the Calico manifest. This installs the `calico-node` DaemonSet (handles routing and policy enforcement), the `calico-kube-controllers` Deployment (syncs Kubernetes resources into Calico's datastore), and the Calico CRDs:

This is your targeted remediation: add a CNI that provides both connectivity and NetworkPolicy enforcement.

```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/calico.yaml
```

Notice: one apply introduces multiple moving parts (DaemonSet, controllers, CRDs). Expect a short convergence window before nodes recover.

Wait for the Calico components to come up:

```bash
kubectl -n kube-system rollout status daemonset/calico-node --timeout=180s
kubectl -n kube-system rollout status deployment/calico-kube-controllers --timeout=120s
```

Notice: these rollout checks are your safety gate. Do not test workloads until both components report healthy.

Check node status again:

```bash
kubectl get nodes
```

Notice: `Ready` is your first proof the missing dependency was fixed.

Both nodes should now show `Ready`. The CNI provided what kubelet needed.

Inspect the Calico DaemonSet to understand its configuration:

This is the config-level verification step that prevents subtle IPAM mistakes.

```bash
kubectl -n kube-system get daemonset calico-node -o yaml | grep -A5 "CALICO_IPV4POOL_CIDR"
```

Notice: matching pod CIDR and Calico pool is not cosmetic; mismatch here causes hard-to-debug routing failures later.

This shows Calico's IPAM pool — the range it carves pod IPs from. It matches `192.168.0.0/16` because we set `podSubnet` in the kind config to match Calico's default. If they conflict, pods get IPs from the wrong range and routing breaks.

Look at what Calico installed:

```bash
kubectl -n kube-system get pods -l k8s-app=calico-node
kubectl -n kube-system get pods -l app=calico-kube-controllers
kubectl get crd | grep calico
```

Operator mindset: after installing infrastructure, verify components, control plane status, and config alignment.

The CRDs include `felixconfigurations`, `ippools`, `networkpolicies` (Calico's own extended variant), and more. Calico has its own policy model that extends Kubernetes NetworkPolicy — but for this lab we'll use standard `networking.k8s.io/v1` NetworkPolicy objects.

---

## Part 5: Calico Enforces NetworkPolicy

Deploy the same test workloads:

You are rerunning the exact traffic experiment from Part 2 so the only variable is the CNI.

```bash
kubectl apply -f starter/test-workloads.yaml
kubectl wait --for=condition=Ready pod/server pod/client --timeout=90s
```

Notice: identical workloads and policy files make this an apples-to-apples enforcement comparison.

Verify pod IPs are in the Calico pool (192.168.x.x):

```bash
kubectl get pods -o wide
```

Notice: if pod IPs are outside the expected pool, stop and fix IPAM alignment before trusting policy behavior.

Test baseline connectivity — it should work:

```bash
kubectl exec client -- curl -s --max-time 5 http://server
```

Notice: this confirms application path is healthy before introducing deny rules.

Now apply the same deny policy you used in Part 2:

```bash
kubectl apply -f starter/deny-policy.yaml
```

Notice: same policy, different outcome is the core comparison result for this lab.

Test again:

```bash
kubectl exec client -- curl -s --max-time 5 http://server
```

Notice: timeout/reset now indicates active enforcement, not app failure.

This time the connection hangs, then fails with a timeout or connection reset. The policy is being enforced.

To confirm it's the policy and not a pod issue:

```bash
# Server pod is still running and healthy
kubectl get pod server

# The policy is what changed
kubectl describe networkpolicy deny-server-ingress
```

Notice: this is your causality check: workload healthy + traffic blocked + deny policy present.

Remove the policy and verify connectivity returns:

```bash
kubectl delete networkpolicy deny-server-ingress
kubectl exec client -- curl -s --max-time 5 http://server
```

Operator mindset: test both directions (deny and recovery), not just one state.

Traffic flows again. Calico is reacting to NetworkPolicy creates and deletes in real time.

---

## Part 6: How Calico Enforces Policies

Calico enforces NetworkPolicy through its per-node agent: **Felix**. Felix runs inside the `calico-node` pod on each worker node and programs iptables (or eBPF, depending on version) rules based on policy objects it watches from the API server.

Look at what Felix programmed on the worker node:

You are connecting Kubernetes objects to actual kernel enforcement artifacts.

```bash
# Exec into the calico-node pod on the worker
CALICO_NODE=$(kubectl -n kube-system get pods -l k8s-app=calico-node -o name | grep worker | head -1)
kubectl -n kube-system exec "$CALICO_NODE" -- iptables-save | grep -i cali | head -40
```

Notice: `cali-` chains are concrete proof that policy intent has been compiled into dataplane rules.

You'll see `cali-` prefixed chains — these are Calico's iptables chains that implement the traffic rules. Each NetworkPolicy becomes a set of iptables rules that the kernel evaluates for every packet.

Calico logs also show policy evaluation:

```bash
kubectl -n kube-system logs "$CALICO_NODE" -c calico-node --tail=50 | grep -i "policy\|felix" | head -20
```

Operator mindset: correlate control-plane objects with data-plane evidence.

---

## Part 7: Cilium — eBPF and Beyond NetworkPolicy

Clean up the Calico cluster before creating the Cilium one:

You are preventing cross-cluster context drift and resource contention before the next comparison.

```bash
kind delete cluster --name cni-calico
```

Notice: clean teardown keeps the experiment deterministic and avoids confusing "which cluster am I on?" mistakes.

Cilium replaces iptables with **eBPF** programs loaded directly into the Linux kernel. This removes iptables from the data path entirely — each packet evaluation goes through a BPF map lookup instead of traversing a chain of rules.

The differences over Calico:

| Capability | Calico | Cilium |
|---|---|---|
| Data plane | iptables / nftables | eBPF |
| NetworkPolicy | Standard `networking.k8s.io/v1` | Standard + `CiliumNetworkPolicy` (L7) |
| L7 policy (HTTP paths, gRPC) | No | Yes |
| Flow observability | No built-in | Hubble (per-pod flow visibility) |
| Service mesh | No | Cilium Mesh (mutual auth, encryption) |
| Scale (iptables rule growth) | Degrades linearly | Constant-time map lookups |
| Complexity | Moderate | Higher (requires kernel ≥ 5.4) |

The shared cluster in this course already runs Cilium. Use it to verify enforcement is working there too:

This gives you a fast reality check against a production-like environment without full reinstall overhead.

```bash
kubectl config use-context ziyotek-prod
kubectl -n kube-system get pods -l k8s-app=cilium | head
```

Notice: seeing healthy Cilium agents validates that the cluster is running an enforcing CNI with eBPF datapath.

**Optional: Install Cilium in kind**

If the `cilium` CLI is available in your DevContainer:

```bash
which cilium && cilium version || echo "cilium CLI not available"
```

Notice: this preflight avoids dead-end install steps when the CLI is unavailable.

If available:

This optional sequence mirrors the Calico experiment so you can compare behavior and tooling side-by-side.

```bash
kind create cluster --name cni-cilium --config starter/kind-cilium.yaml
kubectl config use-context kind-cni-cilium

# Install Cilium (fetches and applies the correct manifests for the current kernel version)
cilium install
cilium status --wait

kubectl get nodes
kubectl apply -f starter/test-workloads.yaml
kubectl wait --for=condition=Ready pod/server pod/client --timeout=90s

# Verify connectivity
kubectl exec client -- curl -s --max-time 5 http://server

# Apply deny policy
kubectl apply -f starter/deny-policy.yaml
kubectl exec client -- curl -s --max-time 5 http://server  # should time out

# Cilium status shows active policies
cilium policy get

kind delete cluster --name cni-cilium
```

Operator mindset: keep comparisons controlled by changing one major variable at a time.

---

## Part 8: CKA CNI Selection Guide

The CKA exam includes knowledge-based questions: *"Which CNI would you use for..."* These are the patterns to know:

Treat this section as operational decision training, not trivia. In real work and on exams, picking the wrong CNI means either missing features (no enforcement) or unnecessary complexity.

**"Install a network plugin so pods can communicate"**
→ Any CNI works. For exam scenarios on kubeadm clusters, Calico is the most commonly tested choice.
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.0/manifests/calico.yaml
```

Notice: this command is useful under pressure because it restores baseline pod networking and policy capability in one move.

Operator mindset: choose for required capability first, then optimize for observability and scale.

**"NetworkPolicy is applied but not enforced"**
→ The CNI doesn't support enforcement. Switch to Calico or Cilium, or check that the existing CNI's policy enforcement is enabled.

**"Need L7 NetworkPolicy (allow GET /api but deny POST)"**
→ Cilium with `CiliumNetworkPolicy`. Standard NetworkPolicy is L3/L4 only.

**"Running on bare-metal servers with your own BGP routers"**
→ Calico with BGP mode. Calico can peer with upstream routers and advertise pod CIDRs directly — no overlay needed.

**"Need per-flow observability (who talked to who, rejected by which policy)"**
→ Cilium with Hubble. It provides flow-level metrics and UI without modifying applications.

**"Simplest possible setup for local development"**
→ kindnet (the default in kind). No additional steps, sufficient for testing workloads that don't rely on NetworkPolicy.

**"Cluster is using Flannel and NetworkPolicies aren't working"**
→ Flannel does not enforce NetworkPolicy in its base form. Install Calico as a NetworkPolicy controller alongside Flannel, or migrate to a CNI that provides full enforcement.

---

## Validation Checklist

You are done when:

- You observed that NetworkPolicy objects on a kindnet cluster have no effect on traffic
- You created a cluster with `disableDefaultCNI: true` and saw pods stuck in `Pending` without a CNI
- You installed Calico and saw nodes reach `Ready` and pods get IPs from `192.168.x.x`
- You applied the same deny policy on Calico and observed connections timing out
- You deleted the policy and confirmed traffic resumed
- You can explain in one sentence why kindnet ignores NetworkPolicy
- You can name the correct CNI for at least three of the CKA selection scenarios

---

## Cleanup

```bash
kind delete cluster --name cni-default   2>/dev/null || true
kind delete cluster --name cni-calico    2>/dev/null || true
kind delete cluster --name cni-cilium    2>/dev/null || true
kubectl config use-context ziyotek-prod  2>/dev/null || true
```

---

## Discovery Questions

1. **The missing enforcement:** You have a cluster running Flannel. A teammate applies a NetworkPolicy to block inter-pod traffic. Does it work? What is the fastest way to confirm whether it's being enforced, without reading the Flannel documentation?

2. **IPAM conflict:** You create a kind cluster with `podSubnet: "10.244.0.0/16"` and then install Calico without changing its default `CALICO_IPV4POOL_CIDR` (which defaults to `192.168.0.0/16`). What happens to pod IPs? What would you see in `kubectl get pods -o wide`?

3. **eBPF advantage:** A cluster with Calico has 5,000 pods and 200 NetworkPolicy objects. An iptables rule is added for every allowed flow. Why might this cause latency issues that the same cluster running Cilium with eBPF does not have?

4. **CKA scenario:** A kubeadm cluster has been bootstrapped but pods cannot communicate. `kubectl get nodes` shows both nodes `Ready`. What is the likely missing component, and what command would install Calico to fix it?

5. **Policy priority:** Calico has its own `CiliumNetworkPolicy`-equivalent: `NetworkPolicy.crd.projectcalico.org/v3`. If you apply both a `networking.k8s.io/v1` NetworkPolicy (allow) and a Calico v3 NetworkPolicy (deny) to the same pod, what is the precedence rule? *(Hint: look up Calico's policy ordering documentation.)*

---

## Reinforcement Scenario

- `33-jerry-wrong-cni-config` — CNI misconfiguration causing pod networking failure; diagnose from node status, pod events, and CNI logs

---

## Further Reading

- [Kubernetes Network Plugins](https://kubernetes.io/docs/concepts/extend-kubernetes/compute-storage-net/network-plugins/)
- [Calico installation docs](https://docs.tigera.io/calico/latest/getting-started/kubernetes/kind)
- [Cilium installation for kind](https://docs.cilium.io/en/stable/installation/kind/)
- [CNI specification](https://github.com/containernetworking/cni/blob/main/SPEC.md)
- [NetworkPolicy and CNI enforcement (Kubernetes docs)](https://kubernetes.io/docs/concepts/services-networking/network-policies/#prerequisites)
