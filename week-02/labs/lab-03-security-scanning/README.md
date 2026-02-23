![Lab 3 hero image](../../../assets/generated/week-02-lab-03/hero.png)

# Lab 3: Security Scanning with Trivy

**Time:** 20 minutes  
**Goal:** Scan container images for vulnerabilities and learn to fix common security issues

---

## The Problem

Your images work, but are they secure? Container images can contain:
- Vulnerable OS packages (CVEs in base image)
- Outdated application dependencies with known exploits
- Misconfigurations that expose your application to attacks

**Trivy** is a vulnerability scanner that helps you find and fix these issues before deployment.

---

## Part 1: Install Trivy

### In Codespaces / Local Linux

```bash
# Download and install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin v0.50.0

# Verify installation
trivy --version
```

### Alternative: Use Trivy via Docker

If you can't install locally, run Trivy as a container:

```bash
alias trivy="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest"
trivy --version
```

---

## Part 2: Scan a Public Image

Let's start by scanning a well-known image to understand the output.

### Scan Alpine

```bash
trivy image alpine:3.18
```

You'll see output like:

```
alpine:3.18 (alpine 3.18.4)
===========================
Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)
```

Alpine is usually clean! Let's try something older...

### Scan an Older Python Image

```bash
trivy image python:3.9-slim
```

This will likely show vulnerabilities:

```
python:3.9-slim (debian 11.8)
==============================
Total: 45 (UNKNOWN: 0, LOW: 12, MEDIUM: 18, HIGH: 12, CRITICAL: 3)

┌──────────────────┬────────────────┬──────────┬────────────┬───────────────────┬───────────────┬────────────────────────────────────┐
│     Library      │ Vulnerability  │ Severity │  Status    │ Installed Version │ Fixed Version │              Title                 │
├──────────────────┼────────────────┼──────────┼────────────┼───────────────────┼───────────────┼────────────────────────────────────┤
│ libssl1.1        │ CVE-2023-12345 │ CRITICAL │ fixed      │ 1.1.1n-0          │ 1.1.1w-0      │ OpenSSL: Remote Code Execution     │
│ libc6            │ CVE-2023-54321 │ HIGH     │ fixed      │ 2.31-13           │ 2.31-15       │ glibc: Buffer Overflow             │
└──────────────────┴────────────────┴──────────┴────────────┴───────────────────┴───────────────┴────────────────────────────────────┘
```

---

## Part 3: Understand CVE Severity Levels

Trivy categorizes vulnerabilities by severity:

| Severity | Meaning | Action |
|----------|---------|--------|
| **CRITICAL** | Actively exploited, remote code execution | **Fix immediately** |
| **HIGH** | Serious impact, requires user interaction | **Fix before production** |
| **MEDIUM** | Moderate impact, limited scope | Fix when convenient |
| **LOW** | Minor issues, theoretical exploits | Optional to fix |
| **UNKNOWN** | Not yet categorized | Investigate |

**Production Rule:** No CRITICAL or HIGH vulnerabilities.

---

## Part 4: Build and Scan a Vulnerable Image

### Setup

```bash
cd week-02/labs/lab-03-security-scanning/starter
ls
```

You'll see:
- `app.py` - Simple Flask app
- `requirements.txt` - Deliberately outdated dependencies
- `Dockerfile` - Uses an old base image

### Build the Vulnerable Image

```bash
docker build -t vulnerable-app:v1 .
```

### Scan It

```bash
trivy image vulnerable-app:v1
```

**Challenge:** Count the vulnerabilities:
- How many CRITICAL?
- How many HIGH?
- What packages are affected?

### Filter by Severity

See only CRITICAL and HIGH:

```bash
trivy image --severity CRITICAL,HIGH vulnerable-app:v1
```

### Output to a File

```bash
trivy image --severity CRITICAL,HIGH -f table -o scan-results.txt vulnerable-app:v1
cat scan-results.txt
```

---

## Part 5: Fix the Vulnerabilities

### Strategy 1: Upgrade the Base Image

Open `Dockerfile`:

```dockerfile
FROM python:3.9-slim  # Old version with vulnerabilities
```

Change to the latest:

```dockerfile
FROM python:3.11-slim  # Newer, more secure
```

Rebuild and rescan:

```bash
docker build -t vulnerable-app:v2 .
trivy image --severity CRITICAL,HIGH vulnerable-app:v2
```

**Result:** Fewer OS-level vulnerabilities!

### Strategy 2: Upgrade Application Dependencies

Open `requirements.txt`:

```
flask==2.0.1        # Old version
requests==2.25.1    # Old version
```

Update to latest stable versions:

```
flask==3.0.0
requests==2.31.0
```

Rebuild and rescan:

```bash
docker build -t vulnerable-app:v3 .
trivy image --severity CRITICAL,HIGH vulnerable-app:v3
```

**Result:** Application dependency vulnerabilities fixed!

### Strategy 3: Use Multi-Stage Builds (Bonus)

Even better - use multi-stage to reduce the attack surface:

```dockerfile
# Build stage
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user -r requirements.txt

# Runtime stage
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY app.py .
ENV PATH=/root/.local/bin:$PATH
CMD ["python", "app.py"]
```

This removes pip and setuptools from the final image.

---

## Part 6: Scan for Misconfigurations

Trivy can also find Docker misconfigurations:

```bash
trivy config Dockerfile
```

This checks for:
- Running as root (security risk)
- Missing health checks
- Using `latest` tag
- Exposed secrets

**Example output:**

```
Dockerfile (dockerfile)
=======================
Tests: 23 (SUCCESSES: 20, FAILURES: 3)
Failures: 3

CRITICAL: Specify at least 1 USER command
──────────────────────────────────────────
Containers should not run as root

   4 [ WORKDIR /app
   5 [ COPY . .
   6 [ CMD ["python", "app.py"]
```

---

## Part 7: Continuous Scanning Workflow

### Scan Before You Push

Add this to your workflow:

```bash
# Build
docker build -t myapp:latest .

# Scan
trivy image --severity CRITICAL,HIGH --exit-code 1 myapp:latest

# If scan passes (exit code 0), push
docker push myapp:latest
```

The `--exit-code 1` flag makes Trivy return a non-zero exit code if vulnerabilities are found, which fails CI/CD pipelines.

### GitHub Actions Integration

```yaml
# .github/workflows/security-scan.yml
name: Security Scan

on: [push]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build image
        run: docker build -t ${{ github.repository }}:${{ github.sha }} .
      
      - name: Run Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ github.repository }}:${{ github.sha }}
          severity: 'CRITICAL,HIGH'
          exit-code: '1'
```

---

## Part 8: Understanding False Positives

Sometimes Trivy reports vulnerabilities that don't apply to your use case.

### Example: Debian Package Vulnerabilities

```
libcurl4: CVE-2023-XXXXX (CRITICAL)
```

**Questions to ask:**
1. Does my application actually use this package?
2. Is the vulnerable code path reachable in my container?
3. Is there a compensating control (firewall, network policy)?

### Ignoring Specific CVEs

Create `.trivyignore`:

```
# This CVE doesn't affect our use case
CVE-2023-12345

# This package isn't used by our application
CVE-2023-54321
```

Use with caution and document WHY you're ignoring it!

---

## Part 9 (Optional): Generate Trivy Trend Charts from Real Scans

If you want measured before/after vulnerability trends for `v1`, `v2`, and `v3`:

```bash
cd week-02/labs/lab-03-security-scanning
python3 scripts/benchmark_trivy_scan.py
```

Requirements:
- Docker running
- Trivy installed (`trivy --version`)
- Python 3
- `matplotlib` installed (for PNG chart output)

If `matplotlib` is not available yet, you can still collect scan data:

```bash
python3 scripts/benchmark_trivy_scan.py --no-charts
```

Artifacts are written to:

```text
assets/generated/week-02-trivy-scan/
  trivy_severity_stacked.png
  trivy_high_critical_trend.png
  summary.md
  results.json
  logs/
  scans/
```

![Trivy Severity Breakdown Chart](../../../assets/generated/week-02-trivy-scan/trivy_severity_stacked.png)

![Trivy High+Critical Trend Chart](../../../assets/generated/week-02-trivy-scan/trivy_high_critical_trend.png)

---

## Checkpoint ✅

You should now be able to:

- [ ] Install and run Trivy
- [ ] Scan images and interpret CVE reports
- [ ] Understand severity levels (CRITICAL, HIGH, MEDIUM, LOW)
- [ ] Fix vulnerabilities by upgrading base images
- [ ] Fix vulnerabilities by upgrading dependencies
- [ ] Scan Dockerfiles for misconfigurations
- [ ] Integrate Trivy into a CI/CD pipeline

---

## Challenge: Achieve Zero CRITICAL Vulnerabilities

Using the starter image:

1. Build and scan to see the baseline
2. Upgrade base image to latest Python slim
3. Update all dependencies to latest stable versions
4. Add a non-root USER to the Dockerfile
5. Scan again - are all CRITICAL and HIGH vulnerabilities gone?

**Goal:** `Total: X (CRITICAL: 0, HIGH: 0)`

---

## Real-World Security Practices

### What to Fix First

Priority order:
1. **CRITICAL in network-exposed services** - Immediate fix
2. **HIGH in production** - Fix before next deploy
3. **MEDIUM** - Fix in next sprint
4. **LOW** - Fix when convenient

### Security is a Process, Not a Point-in-Time

- Scan regularly (daily in CI/CD)
- New CVEs are published constantly
- An image that's clean today might be vulnerable tomorrow
- Automate scanning in your deployment pipeline

### Defense in Depth

Image scanning is ONE layer:
- **Network policies** - Limit what containers can reach
- **Runtime security** - Detect anomalous behavior (Falco)
- **Least privilege** - Run as non-root, drop capabilities
- **Immutable infrastructure** - Don't patch, rebuild

---

## Clean Up

```bash
docker rmi vulnerable-app:v1 vulnerable-app:v2 vulnerable-app:v3
rm scan-results.txt
```

---

## Resources

- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [CVE Database](https://cve.mitre.org/)
- [Snyk Vulnerability Database](https://security.snyk.io/)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)

---

## Demo

![Trivy Security Scan Demo](../../../assets/week-02-lab-03-trivy-scan.gif)

---

## Key Takeaway

> **Scan early, scan often. Fix CRITICAL and HIGH before production.**

Security isn't a checkbox—it's a continuous process.
