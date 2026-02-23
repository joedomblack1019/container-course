---
theme: default
title: Week 04 Lab 08 - Jobs and CronJobs
drawings:
  persist: false
mdc: true
layout: win95-desktop
week: "04"
lab: "Lab 08 · Jobs and CronJobs"
---

# Jobs and CronJobs
## Lab 08

- Understand when to use Job vs Deployment for finite tasks
- Observe parallel completions, retry behavior, and backoff
- Schedule recurring work with CronJob and concurrency policies
- Practice imperative commands for the CKA exam

---
layout: win95
windowTitle: "Job vs Deployment — The Model"
windowIcon: "⚙️"
statusText: "Week 04 · Lab 08 · batch workload primitives"
---

## Deployment vs Job vs CronJob

| Kind | Lifecycle | Use for |
|---|---|---|
| **Deployment** | Runs forever — restarts on exit 0 | Long-running services (web, API) |
| **Job** | Runs until N successful completions, then stops | One-shot tasks — migrations, backups, reports |
| **CronJob** | Creates a new Job on a schedule | Recurring tasks — nightly cleanup, heartbeat |

`restartPolicy: Never` → new pod per failure · `OnFailure` → restart same pod

---
layout: win95-terminal
termTitle: "Command Prompt — first Job and parallel Job"
---

<Win95Terminal
  title="Command Prompt — batch basics"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f backup-job.yaml' },
    { type: 'input', text: 'kubectl get pods -w' },
    { type: 'input', text: 'kubectl get job db-backup' },
    { type: 'input', text: 'kubectl describe job db-backup' },
    { type: 'input', text: 'kubectl logs job/db-backup' },
    { type: 'input', text: 'kubectl get pod -l job-name=db-backup' },
    { type: 'input', text: 'kubectl apply -f parallel-job.yaml' },
    { type: 'input', text: 'kubectl get pods -w -l job-name=process-reports' },
    { type: 'input', text: 'kubectl get job process-reports -w' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — failure and retry behavior"
---

<Win95Terminal
  title="Command Prompt — backoff and failure"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f failing-job.yaml' },
    { type: 'input', text: 'kubectl get pods -w -l job-name=jerry-migration' },
    { type: 'input', text: 'kubectl describe job jerry-migration' },
    { type: 'input', text: 'kubectl logs -l job-name=jerry-migration --prefix' },
    { type: 'input', text: 'kubectl explain job.spec.backoffLimit' },
    { type: 'input', text: 'kubectl explain job.spec.activeDeadlineSeconds' },
    { type: 'input', text: 'kubectl explain job.spec.completions' },
    { type: 'input', text: 'kubectl explain job.spec.parallelism' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — CronJob and manual trigger"
---

<Win95Terminal
  title="Command Prompt — scheduled execution"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f cleanup-cronjob.yaml' },
    { type: 'input', text: 'kubectl get cronjob nightly-cleanup -w' },
    { type: 'input', text: 'kubectl get jobs -w' },
    { type: 'input', text: 'kubectl describe cronjob nightly-cleanup' },
    { type: 'input', text: 'kubectl create job --from=cronjob/nightly-cleanup manual-cleanup-01' },
    { type: 'input', text: 'kubectl get job manual-cleanup-01' },
    { type: 'input', text: 'kubectl logs job/manual-cleanup-01' },
    { type: 'input', text: 'kubectl explain cronjob.spec.concurrencyPolicy' },
  ]"
/>

---
layout: win95-terminal
termTitle: "Command Prompt — TTL controller and imperative commands"
---

<Win95Terminal
  title="Command Prompt — exam speed and cleanup"
  color="green"
  :crt="true"
  prompt="$ "
  height="100%"
  :lines="[
    { type: 'input', text: 'kubectl apply -f job-with-ttl.yaml' },
    { type: 'input', text: 'kubectl get job with-ttl -w' },
    { type: 'input', text: 'kubectl create job db-seed --image=busybox:1.36 -- sh -c &quot;echo seeding && sleep 3&quot;' },
    { type: 'input', text: 'kubectl create cronjob heartbeat --image=busybox:1.36 --schedule=&quot;*/5 * * * *&quot; -- sh -c &quot;echo ping&quot;' },
    { type: 'input', text: 'kubectl create job --from=cronjob/heartbeat heartbeat-manual-01' },
    { type: 'input', text: 'kubectl get job db-seed -w' },
    { type: 'input', text: 'kubectl delete job db-backup process-reports jerry-migration with-ttl db-seed --ignore-not-found' },
    { type: 'input', text: 'kubectl delete cronjob nightly-cleanup heartbeat --ignore-not-found' },
  ]"
/>

---
layout: win95
windowTitle: "Lab 08 — Key Commands"
windowIcon: "📋"
statusText: "Week 04 · Lab 08 · Reference"
---

## Key Commands

| Command | What it does |
|---|---|
| `kubectl apply -f backup-job.yaml` | Create a one-shot Job |
| `kubectl get job <name>` | Show completions status |
| `kubectl describe job <name>` | Inspect retry events and conditions |
| `kubectl logs job/<name>` | Fetch logs from a Job's pod |
| `kubectl get pod -l job-name=<name>` | Find pods owned by a Job |
| `kubectl logs -l job-name=<name> --prefix` | Logs from all retry pods |
| `kubectl get cronjob <name> -w` | Watch CronJob schedule and last fire |
| `kubectl describe cronjob <name>` | Show history, active jobs, last schedule |
| `kubectl create job --from=cronjob/<name> <job-name>` | Trigger a CronJob manually |
| `kubectl create job <name> --image=<img> -- <cmd>` | Imperative one-shot Job |
| `kubectl create cronjob <name> --image=<img> --schedule="<cron>"` | Imperative CronJob |
| `kubectl explain job.spec.backoffLimit` | Retry limit before Job fails |
| `kubectl explain job.spec.activeDeadlineSeconds` | Hard time cap on a Job |
| `kubectl explain job.spec.completions` | Required successful pod count |
| `kubectl explain job.spec.parallelism` | Concurrent pods allowed |
| `kubectl explain cronjob.spec.concurrencyPolicy` | Allow / Forbid / Replace |
| `kubectl explain cronjob.spec.successfulJobsHistoryLimit` | How many completed Jobs to keep |
| `kubectl explain cronjob.spec.startingDeadlineSeconds` | How late a scheduled run can start |
