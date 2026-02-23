---
theme: default
title: Week 02 Lab 03 - Security Scanning with Trivy
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "02"
lab: "Lab 03 · Security Scanning with Trivy"
---

# Security Scanning with Trivy
## Lab 03

- Install Trivy and scan baseline public images
- Build and scan a deliberately vulnerable application image
- Reduce findings by upgrading base image and dependencies
- Add a CI-style vulnerability gate before pushing images

---
layout: win95
windowTitle: "Severity Model and Fix Priority"
windowIcon: "🛡"
statusText: "Week 02 · Lab 03 · CVE triage"
---

## Trivy Severity Levels

| Severity | Meaning | Action |
|---|---|---|
| **CRITICAL** | Actively exploited, remote code execution | **Fix immediately** |
| **HIGH** | Serious impact, requires user interaction | **Fix before production** |
| **MEDIUM** | Moderate impact, limited scope | Fix when convenient |
| **LOW** | Minor issues, theoretical exploits | Optional to fix |
| **UNKNOWN** | Not yet categorized | Investigate |

> Production rule in the lab: no `CRITICAL` or `HIGH` vulnerabilities.

---
layout: win95
windowTitle: "Dockerfile Remediation Example"
windowIcon: "📄"
statusText: "Week 02 · Lab 03 · Upgrade base + deps"
---

## Base Image Upgrade

```dockerfile
FROM python:3.9-slim  # Old version with vulnerabilities
```

```dockerfile
FROM python:3.11-slim  # Newer, more secure
```

## Dependency Upgrade

```text
flask==2.0.1
requests==2.25.1
```

```text
flask==3.0.0
requests==2.31.0
```

---
layout: win95-terminal
termTitle: "Command Prompt — install and baseline scans"
---

<Win95Terminal
  title="Command Prompt — trivy setup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'comment', text: '# Install Trivy (Linux) and verify' },
    { type: 'input', text: 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.50.0' },
    { type: 'input', text: 'trivy --version' },
    { type: 'comment', text: '# Alternative containerized trivy command' },
    { type: 'input', text: 'docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image alpine:3.18' },
    { type: 'input', text: 'trivy image alpine:3.18' },
    { type: 'output', text: 'Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)' },
    { type: 'input', text: 'trivy image python:3.9-slim' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — vulnerable app scan and filtering"
---

<Win95Terminal
  title="Command Prompt — vulnerability triage"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd week-02/labs/lab-03-security-scanning/starter' },
    { type: 'input', text: 'ls' },
    { type: 'input', text: 'docker build -t vulnerable-app:v1 .' },
    { type: 'input', text: 'trivy image vulnerable-app:v1' },
    { type: 'input', text: 'trivy image --severity CRITICAL,HIGH vulnerable-app:v1' },
    { type: 'input', text: 'trivy image --severity CRITICAL,HIGH -f table -o scan-results.txt vulnerable-app:v1' },
    { type: 'input', text: 'cat scan-results.txt' },
    { type: 'error', text: 'CRITICAL and HIGH vulnerabilities detected' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — remediation, config scan, CI gate"
---

<Win95Terminal
  title="Command Prompt — remediation workflow"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'docker build -t vulnerable-app:v2 .' },
    { type: 'input', text: 'trivy image --severity CRITICAL,HIGH vulnerable-app:v2' },
    { type: 'input', text: 'docker build -t vulnerable-app:v3 .' },
    { type: 'input', text: 'trivy image --severity CRITICAL,HIGH vulnerable-app:v3' },
    { type: 'input', text: 'trivy config Dockerfile' },
    { type: 'input', text: 'docker build -t myapp:latest .' },
    { type: 'input', text: 'trivy image --severity CRITICAL,HIGH --exit-code 1 myapp:latest' },
    { type: 'input', text: 'docker push myapp:latest' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — optional benchmark and cleanup"
---

<Win95Terminal
  title="Command Prompt — trend charts + cleanup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'cd week-02/labs/lab-03-security-scanning' },
    { type: 'input', text: 'python3 scripts/benchmark_trivy_scan.py' },
    { type: 'input', text: 'python3 scripts/benchmark_trivy_scan.py --no-charts' },
    { type: 'input', text: 'docker rmi vulnerable-app:v1 vulnerable-app:v2 vulnerable-app:v3' },
    { type: 'input', text: 'rm scan-results.txt' },
    { type: 'success', text: 'Lab cleanup complete' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 03 — Key Commands"
windowIcon: "📋"
statusText: "Week 02 · Lab 03 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.50.0` | Install Trivy |
| `trivy --version` | Verify Trivy installation |
| `alias trivy="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest"` | Use Trivy through Docker |
| `trivy image alpine:3.18` | Scan baseline Alpine image |
| `trivy image python:3.9-slim` | Scan older Python image |
| `cd week-02/labs/lab-03-security-scanning/starter` | Enter starter directory |
| `ls` | List starter files |
| `docker build -t vulnerable-app:v1 .` | Build vulnerable app image |
| `trivy image vulnerable-app:v1` | Full scan of vulnerable image |
| `trivy image --severity CRITICAL,HIGH vulnerable-app:v1` | Filter scan by severe findings |
| `trivy image --severity CRITICAL,HIGH -f table -o scan-results.txt vulnerable-app:v1` | Save severe findings to file |
| `cat scan-results.txt` | View saved scan report |
| `docker build -t vulnerable-app:v2 .` | Rebuild after base-image update |
| `trivy image --severity CRITICAL,HIGH vulnerable-app:v2` | Rescan v2 image |
| `docker build -t vulnerable-app:v3 .` | Rebuild after dependency updates |
| `trivy image --severity CRITICAL,HIGH vulnerable-app:v3` | Rescan v3 image |
| `trivy config Dockerfile` | Scan Dockerfile misconfigurations |
| `docker build -t myapp:latest .` | Build app for CI gate |
| `trivy image --severity CRITICAL,HIGH --exit-code 1 myapp:latest` | Fail pipeline on severe findings |
| `docker push myapp:latest` | Push image if scan passes |
| `cd week-02/labs/lab-03-security-scanning` | Move to benchmark script directory |
| `python3 scripts/benchmark_trivy_scan.py` | Generate trend data and charts |
| `python3 scripts/benchmark_trivy_scan.py --no-charts` | Collect trend data only |
| `docker rmi vulnerable-app:v1 vulnerable-app:v2 vulnerable-app:v3` | Remove lab images |
| `rm scan-results.txt` | Remove local scan artifact |

---
layout: win95
windowTitle: "Security Scan Flow"
windowIcon: "🔍"
statusText: "Week 02 · Lab 03 · Build -> scan -> push"
---

## Pipeline Flow

```text
docker build -t myapp:latest .
        |
        v
trivy image --severity CRITICAL,HIGH --exit-code 1 myapp:latest
        |
        +-- fail -> fix Dockerfile/dependencies -> rebuild
        |
        +-- pass -> docker push myapp:latest
```
