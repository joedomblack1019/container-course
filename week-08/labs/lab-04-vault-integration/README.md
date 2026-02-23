![Lab 04 Vault Integration Bonus](../../../assets/generated/week-08-lab-04/hero.png)
![Lab 04 Vault secret injection workflow](../../../assets/generated/week-08-lab-04/flow.gif)

---

# Lab 4: Vault Integration (Bonus)

**Time:** 30 minutes
**Objective:** Store GitHub App credentials in Vault and wire them to the portfolio for live dashboard data

---

## The Story

Your portfolio is running, but if you visit the dashboard page, it says "GitHub data unavailable." That's because the app needs GitHub API credentials to show live pipeline data — recent Actions runs, commits, and container packages. Those credentials belong in a secrets manager, not in a ConfigMap or hardcoded in source.

Enter Vault. You'll install it in dev mode, create a GitHub App for API access, store the credentials in Vault, and watch the dashboard come alive.

---

## Starting Point

You should have:
- ArgoCD running on your kind cluster (from Lab 1)
- Your portfolio deployed via ArgoCD (from Lab 3)
- The portfolio accessible via port-forward

---

## Part 1: Install Vault in Dev Mode

Add the HashiCorp Helm repo and install Vault:

```bash
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

```bash
helm install vault hashicorp/vault \
  --set "server.dev.enabled=true" \
  --set "server.dev.devRootToken=root" \
  --set "server.resources.requests.memory=64Mi" \
  --set "server.resources.requests.cpu=50m" \
  --set "server.resources.limits.memory=256Mi" \
  --set "server.resources.limits.cpu=200m"
```

Wait for the pod:

```bash
kubectl get pods -l app.kubernetes.io/name=vault -w
```

**Dev mode** means:
- **Auto-unsealed** — no need for unseal keys (production Vault requires a manual unseal process)
- **Root token: `root`** — easy to authenticate (production Vault uses proper auth methods)
- **Ephemeral storage** — everything is lost on pod restart (production uses persistent storage)

Dev mode is perfect for learning. Never use it in production.

Port-forward to the Vault UI:

```bash
kubectl port-forward service/vault 8200:8200 &
```

Open `http://localhost:8200` and sign in with token `root`.

---

## Part 2: Create a GitHub App

The portfolio app authenticates to GitHub's API as a GitHub App, not with a personal access token. Apps have fine-grained permissions and don't consume your personal rate limit.

1. Go to **https://github.com/settings/apps/new**

2. Fill in:
   - **GitHub App name:** `<YOUR_GITHUB_USERNAME>-portfolio` (must be globally unique)
   - **Homepage URL:** `http://localhost:5001` (or any URL)
   - **Webhook:** Uncheck "Active" (we don't need webhooks)

3. Set permissions (Repository permissions only):
   - **Actions:** Read-only
   - **Contents:** Read-only
   - **Metadata:** Read-only (auto-selected)

4. Under "Where can this GitHub App be installed?" select **Only on this account**

5. Click **Create GitHub App**

6. Note your **App ID** (shown at the top of the app settings page)

7. Scroll down to **Private keys** → click **Generate a private key**
   - A `.pem` file downloads — save it somewhere safe

8. Install the app on your account:
   - From the app settings page, click **Install App** in the left sidebar
   - Click **Install** next to your account
   - Select **Only select repositories** → choose your `container-devsecops-template` fork
   - Click **Install**

9. Note the **Installation ID** from the URL: `https://github.com/settings/installations/<INSTALLATION_ID>`

You now have three pieces of information:
- **App ID** (e.g., `123456`)
- **Installation ID** (e.g., `78901234`)
- **Private key file** (the `.pem` you downloaded)

---

## Part 3: Store Credentials in Vault

The portfolio template includes a `vault/setup.sh` script, but you're going to run each command by hand so you understand what it does.

### Set up your environment

```bash
export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="root"
```

### Enable the KV v2 secrets engine

```bash
vault secrets enable -path=secret kv-v2
```

If it says "path is already in use," that's fine — dev mode may have it enabled already.

### Store the GitHub App credentials

```bash
vault kv put secret/github-app \
  app_id="<YOUR_APP_ID>" \
  installation_id="<YOUR_INSTALLATION_ID>" \
  private_key=@<PATH_TO_YOUR_PRIVATE_KEY_PEM>
```

Replace the placeholders:
- `<YOUR_APP_ID>` — the App ID from step 6 above
- `<YOUR_INSTALLATION_ID>` — the Installation ID from step 9 above
- `<PATH_TO_YOUR_PRIVATE_KEY_PEM>` — the path to the `.pem` file you downloaded

The `@` prefix tells Vault to read the value from a file instead of inline.

### Verify the secret was stored

```bash
vault kv get secret/github-app
```

You should see `app_id`, `installation_id`, and `private_key` fields.

### Create the Kubernetes secret for the Vault token

The portfolio pod needs a Vault token to authenticate. Create a Kubernetes secret in the `portfolio` namespace:

```bash
kubectl create secret generic vault-token \
  --namespace=portfolio \
  --from-literal=token="root"
```

This secret is already referenced in the local overlay's Kustomize patch — the deployment injects it as the `VAULT_TOKEN` environment variable.

---

## Part 4: Verify

The portfolio pod needs to restart to pick up the new Vault token. You can either wait for ArgoCD to reconcile, or force a rollout:

```bash
kubectl rollout restart deployment/portfolio -n portfolio
```

Wait for the new pod to be ready:

```bash
kubectl get pods -n portfolio -w
```

Now check the portfolio dashboard:

```bash
# Re-establish port-forward if needed
kubectl port-forward -n portfolio service/portfolio-svc 5001:80 &
```

Open `http://localhost:5001/dashboard`. You should now see:
- Recent GitHub Actions pipeline runs
- Recent commits
- Container package information

The app authenticates as your GitHub App, reads data from the GitHub API, and displays it. The credentials never left Vault — the app fetches them at runtime.

### Verify via the API

```bash
curl -s http://localhost:5001/api/status | python3 -m json.tool
```

Check the `integrations` section:
- `vault` should show `connected`
- `github_api` should show `connected`

---

## Checkpoint

You are done when:
- [ ] Vault is running in dev mode on your cluster
- [ ] You created a GitHub App with Actions/Contents/Metadata read permissions
- [ ] Credentials are stored in Vault at `secret/github-app`
- [ ] The `vault-token` Kubernetes secret exists in the `portfolio` namespace
- [ ] The portfolio dashboard shows live GitHub data (Actions runs, commits, packages)
- [ ] `/api/status` shows both vault and github_api as `connected`
