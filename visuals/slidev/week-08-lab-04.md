---
theme: default
title: Week 08 Lab 04 - Vault Integration Bonus
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "08"
lab: "Lab 04 · Vault Integration (Bonus)"
---

# Vault Integration (Bonus)
## Lab 04

- Install Vault dev mode on kind via Helm
- Create GitHub App credentials for API access
- Store app ID, installation ID, and private key in Vault
- Wire portfolio to Vault-backed credentials and verify live data

---
layout: win95
windowTitle: "Vault Dev Mode"
windowIcon: "🔐"
statusText: "Week 08 · Lab 04 · Learning mode caveats"
---

<Win95Dialog
  type="warning"
  title="Dev Mode Only"
  message="Vault dev mode is auto-unsealed and ephemeral."
  detail="Token is fixed (`root`) and secrets are lost on pod restart. Use only for labs, never production."
  :buttons="['Continue']"
  :active-button="0"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — install Vault and access UI"
---

<Win95Terminal
  title="Command Prompt — vault bootstrap"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'helm repo add hashicorp https://helm.releases.hashicorp.com' },
    { type: 'input', text: 'helm repo update' },
    { type: 'input', text: 'helm install vault hashicorp/vault --set &quot;server.dev.enabled=true&quot; --set &quot;server.dev.devRootToken=root&quot; --set &quot;server.resources.requests.memory=64Mi&quot; --set &quot;server.resources.requests.cpu=50m&quot; --set &quot;server.resources.limits.memory=256Mi&quot; --set &quot;server.resources.limits.cpu=200m&quot;' },
    { type: 'input', text: 'kubectl get pods -l app.kubernetes.io/name=vault -w' },
    { type: 'input', text: 'kubectl port-forward service/vault 8200:8200 &' },
    { type: 'success', text: 'Open http://localhost:8200 and login with token root' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — store GitHub App credentials"
---

<Win95Terminal
  title="Command Prompt — secret onboarding"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'export VAULT_ADDR=&quot;http://localhost:8200&quot;' },
    { type: 'input', text: 'export VAULT_TOKEN=&quot;root&quot;' },
    { type: 'input', text: 'vault secrets enable -path=secret kv-v2' },
    { type: 'input', text: 'vault kv put secret/github-app app_id=&quot;<YOUR_APP_ID>&quot; installation_id=&quot;<YOUR_INSTALLATION_ID>&quot; private_key=@<PATH_TO_YOUR_PRIVATE_KEY_PEM>' },
    { type: 'input', text: 'vault kv get secret/github-app' },
    { type: 'input', text: 'kubectl create secret generic vault-token --namespace=portfolio --from-literal=token=&quot;root&quot;' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — restart portfolio and verify integrations"
---

<Win95Terminal
  title="Command Prompt — runtime verification"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl rollout restart deployment/portfolio -n portfolio' },
    { type: 'input', text: 'kubectl get pods -n portfolio -w' },
    { type: 'input', text: 'kubectl port-forward -n portfolio service/portfolio-svc 5001:80 &' },
    { type: 'input', text: 'curl -s http://localhost:5001/api/status | python3 -m json.tool' },
    { type: 'success', text: 'Expected integrations: vault=connected, github_api=connected' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 04 — Key Commands"
windowIcon: "📋"
statusText: "Week 08 · Lab 04 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `helm repo add hashicorp https://helm.releases.hashicorp.com` | Add Vault chart repo |
| `helm install vault hashicorp/vault --set ...` | Install Vault in dev mode |
| `kubectl port-forward service/vault 8200:8200 &` | Access Vault UI/API locally |
| `export VAULT_ADDR="http://localhost:8200"` | Set Vault endpoint |
| `export VAULT_TOKEN="root"` | Set dev token |
| `vault secrets enable -path=secret kv-v2` | Enable KV v2 secrets engine |
| `vault kv put secret/github-app app_id="..." installation_id="..." private_key=@...` | Store GitHub App credentials |
| `vault kv get secret/github-app` | Verify stored fields |
| `kubectl create secret generic vault-token --namespace=portfolio --from-literal=token="root"` | Provide Vault token to app namespace |
| `kubectl rollout restart deployment/portfolio -n portfolio` | Reload deployment with secret wiring |
| `curl -s http://localhost:5001/api/status | python3 -m json.tool` | Verify integration connectivity |
