---
theme: default
title: Week 06 Lab 03 - NetworkPolicies Break It Fix It Lock It Down
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "06"
lab: "Lab 03 · NetworkPolicies"
---

# NetworkPolicies
## Lab 03

- Apply namespace-wide default deny policy
- Restore required DNS, gateway, app-to-redis, and kuma flows
- Verify monitors and public URLs recover incrementally
- Commit final least-privilege policy into GitOps

---
layout: win95
windowTitle: "Policy Strategy"
windowIcon: "🧱"
statusText: "Week 06 · Lab 03 · break then allow"
---

## Incremental Hardening Sequence

1. Default deny all ingress/egress
2. Allow DNS egress
3. Allow gateway ingress to app and kuma
4. Allow app <-> redis flows
5. Allow kuma monitoring egress + app ingress

---
layout: win95
windowTitle: "Admission and Enforcement Note"
windowIcon: "🛡"
statusText: "Week 06 · Lab 03 · CNI enforcement dependency"
---

<Win95Dialog
  type="warning"
  title="NetworkPolicy Prerequisite"
  message="Policies are only enforced if the cluster CNI supports NetworkPolicy."
  detail="The shared cluster uses Cilium, so policy objects affect real traffic. On non-enforcing CNIs, objects exist but traffic remains allow-all."
  :buttons="['Got it']"
  :active-button="0"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — baseline and default deny"
---

<Win95Terminal
  title="Command Prompt — lock down namespace"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl config use-context ziyotek-prod' },
    { type: 'input', text: 'kubectl get pods -n student-<YOUR_GITHUB_USERNAME>-dev' },
    { type: 'input', text: 'kubectl auth can-i create networkpolicy -n student-<YOUR_GITHUB_USERNAME>-dev' },
    { type: 'input', text: 'curl -s https://<YOUR_GITHUB_USERNAME>.dev.lab.shart.cloud/health' },
    { type: 'input', text: 'kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<\'EOF\'' },
    { type: 'input', text: 'kind: NetworkPolicy  # default-deny-all with ingress:[] egress:[]' },
    { type: 'input', text: 'EOF' },
    { type: 'error', text: 'Expected: monitors and public traffic fail until allows are added' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — allow DNS and gateway ingress"
---

<Win95Terminal
  title="Command Prompt — recover core routing"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<\'EOF\'' },
    { type: 'input', text: 'kind: NetworkPolicy  # allow-dns-egress to kube-dns UDP/TCP 53' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<\'EOF\'' },
    { type: 'input', text: 'kind: NetworkPolicy  # allow-gateway-ingress to ports 5000 and 3001' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'curl -s https://<YOUR_GITHUB_USERNAME>.status.lab.shart.cloud/ | head' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — allow app redis and kuma flows"
---

<Win95Terminal
  title="Command Prompt — restore app dependencies"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<\'EOF\'' },
    { type: 'input', text: 'kind: NetworkPolicy  # allow-app-to-redis egress 6379' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<\'EOF\'' },
    { type: 'input', text: 'kind: NetworkPolicy  # allow-redis-from-app ingress 6379' },
    { type: 'input', text: 'EOF' },
    { type: 'input', text: 'kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<\'EOF\'' },
    { type: 'input', text: 'kind: NetworkPolicy  # allow-kuma-monitoring and allow-app-from-kuma' },
    { type: 'input', text: 'EOF' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — apply final policy and optional charts"
---

<Win95Terminal
  title="Command Prompt — final state"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f solution/network-policy.yaml' },
    { type: 'input', text: 'kubectl get networkpolicy -n student-<YOUR_GITHUB_USERNAME>-dev' },
    { type: 'input', text: 'cd week-06/labs/lab-03-network-policies' },
    { type: 'input', text: 'python3 scripts/benchmark_networkpolicy_matrix.py' },
    { type: 'input', text: 'python3 scripts/benchmark_networkpolicy_matrix.py --no-charts' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 03 — Key Commands"
windowIcon: "📋"
statusText: "Week 06 · Lab 03 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl auth can-i create networkpolicy -n student-<YOUR_GITHUB_USERNAME>-dev` | Verify RBAC before policy changes |
| `kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF' ... default-deny-all ... EOF` | Block all pod ingress/egress |
| `kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF' ... allow-dns-egress ... EOF` | Restore DNS egress |
| `kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF' ... allow-gateway-ingress ... EOF` | Allow gateway to app/kuma |
| `kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF' ... allow-app-to-redis ... EOF` | Allow app egress to redis |
| `kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF' ... allow-redis-from-app ... EOF` | Allow redis ingress from app |
| `kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF' ... allow-kuma-monitoring ... EOF` | Allow kuma egress to app + internet |
| `kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f - <<'EOF' ... allow-app-from-kuma ... EOF` | Allow app ingress from kuma |
| `kubectl apply -n student-<YOUR_GITHUB_USERNAME>-dev -f solution/network-policy.yaml` | Apply final combined policy file |
| `kubectl get networkpolicy -n student-<YOUR_GITHUB_USERNAME>-dev` | List active policies |
| `python3 scripts/benchmark_networkpolicy_matrix.py` | Generate reachability charts |
