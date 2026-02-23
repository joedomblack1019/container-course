![Lab 08 Jobs and CronJobs](../../../assets/generated/week-04-lab-08/hero.png)
![Lab 08 batch workloads and scheduling](../../../assets/generated/week-04-lab-08/flow.gif)

---

# Lab 8: Jobs and CronJobs

**Time:** 25-30 minutes  
**Objective:** Understand Kubernetes batch workloads — when to use them, how they behave, and how to debug them

---

## The Story

Deployments run forever. That's what you want for a web server. But not everything should run forever. Database migrations, report generation, cleanup scripts, cache warming — these are tasks that should run, complete, and stop. If you wrap them in a Deployment, Kubernetes will restart them when they finish successfully. That's the opposite of what you want.

Kubernetes has two batch primitives built for this: **Job** for "run this once" and **CronJob** for "run this on a schedule." Both are CKA exam staples.

---

## Jobs vs Deployments — The Model

```
Deployment
  spec.replicas: 3
  → controller keeps 3 pods running forever
  → if a pod exits 0 (success), controller restarts it
  → designed for long-running services

Job
  spec.completions: 3
  spec.parallelism: 2
  → controller runs pods until N successful completions
  → if a pod exits 0, it counts as done — no restart
  → if a pod exits non-zero, it retries up to backoffLimit
  → designed for finite tasks
```

---

## Part 1: Your First Job

Create a simple Job that performs a database backup simulation:

```yaml
# backup-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: db-backup
spec:
  completions: 1
  backoffLimit: 3
  template:
    spec:
      restartPolicy: Never    # Required for Jobs — OnFailure is the other valid option
      containers:
      - name: backup
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          echo "Starting backup at $(date)"
          sleep 5
          echo "Backup complete. Wrote 142MB to s3://jerry-backups/$(date +%Y%m%d).tar.gz"
```

Apply it and observe:

```bash
kubectl apply -f backup-job.yaml

# Watch the pod run and complete
kubectl get pods -w

# Once complete, check the job status
kubectl get job db-backup
kubectl describe job db-backup
```

Notice: the pod status shows `Completed`, not `Running`. The job's `COMPLETIONS` column shows `1/1`.

Now try to understand the lifecycle:

```bash
# Logs are still accessible after completion
kubectl logs job/db-backup

# The pod is not deleted automatically — it sticks around for inspection
kubectl get pod -l job-name=db-backup
```

---

## Part 2: Parallel Jobs

Jobs can run multiple completions in parallel. This is useful for processing work queues.

```yaml
# parallel-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: process-reports
spec:
  completions: 6      # Need 6 successful completions total
  parallelism: 2      # Run 2 pods at a time
  backoffLimit: 2
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: processor
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          echo "Worker $HOSTNAME processing report chunk"
          sleep $((RANDOM % 8 + 2))
          echo "Done"
```

```bash
kubectl apply -f parallel-job.yaml

# Watch pods — you'll see at most 2 running simultaneously
kubectl get pods -w -l job-name=process-reports

# Watch the job progress
kubectl get job process-reports -w
```

Explore the key fields:

```bash
kubectl explain job.spec.completions
kubectl explain job.spec.parallelism
kubectl explain job.spec.backoffLimit
kubectl explain job.spec.activeDeadlineSeconds
```

---

## Part 3: Job Failure and Retry Behavior

Create a job that fails deterministically to observe retry behavior:

```yaml
# failing-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: jerry-migration
spec:
  backoffLimit: 3    # Retry up to 3 times before giving up
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: migrate
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          echo "Running migration..."
          echo "ERROR: connection refused to postgres:5432"
          exit 1    # Simulate a failure
```

```bash
kubectl apply -f failing-job.yaml

# Watch — you'll see pods created, fail, retry, fail, retry...
kubectl get pods -w -l job-name=jerry-migration

# After backoffLimit is exhausted, check job status
kubectl describe job jerry-migration
```

Look for `Failed` in the Conditions and `Warning BackoffLimitExceeded` in the events.

```bash
# The individual pod logs tell the story
kubectl logs -l job-name=jerry-migration --prefix
```

---

## Part 4: CronJob — Scheduled Execution

CronJob is a Job factory on a schedule. It uses standard cron syntax.

```yaml
# cleanup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: nightly-cleanup
spec:
  schedule: "*/2 * * * *"    # Every 2 minutes (use short interval for lab observation)
  concurrencyPolicy: Forbid  # Don't start a new run if the previous is still running
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          containers:
          - name: cleanup
            image: busybox:1.36
            command:
            - sh
            - -c
            - |
              echo "Cleanup run at $(date)"
              echo "Deleted 47 expired sessions"
              echo "Freed 1.2GB temp storage"
```

```bash
kubectl apply -f cleanup-cronjob.yaml

# Watch for the first job to be created (within 2 minutes)
kubectl get cronjob nightly-cleanup -w

# Once a run fires, watch the job and pod
kubectl get jobs -w
kubectl get pods -w
```

Inspect the CronJob after a couple of runs:

```bash
kubectl describe cronjob nightly-cleanup
```

Look at:
- `Last Schedule` — when it last fired
- `Active` — any currently running jobs
- The job history (last 3 successful, last 1 failed per your limits)

Explore key fields:

```bash
kubectl explain cronjob.spec.concurrencyPolicy
kubectl explain cronjob.spec.successfulJobsHistoryLimit
kubectl explain cronjob.spec.startingDeadlineSeconds
```

---

## Part 5: Triggering a CronJob Manually

On the CKA exam you may be asked to trigger a CronJob immediately without waiting for its schedule:

```bash
# Imperative — create a Job from a CronJob on demand
kubectl create job --from=cronjob/nightly-cleanup manual-cleanup-01

# Watch it run
kubectl get job manual-cleanup-01
kubectl logs job/manual-cleanup-01
```

This is a common exam pattern. The `--from` flag reads the CronJob's `jobTemplate` and fires it immediately.

---

## Part 6: TTL Controller — Auto-Cleanup

By default, completed job pods stick around (which is why you can still read logs). In production you usually want them cleaned up automatically:

```yaml
# job-with-ttl.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: with-ttl
spec:
  ttlSecondsAfterFinished: 60    # Auto-delete job and pods 60 seconds after completion
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: task
        image: busybox:1.36
        command: ["sh", "-c", "echo done && exit 0"]
```

```bash
kubectl apply -f job-with-ttl.yaml
kubectl get job with-ttl -w
# After it completes, wait 60 seconds — job and pods disappear automatically
```

---

## CronJob Concurrency Policies

| Policy | Behavior |
|--------|----------|
| `Allow` | (default) Start a new job even if the previous is still running. Can overlap. |
| `Forbid` | Skip the new run if the previous job is still running. |
| `Replace` | Cancel the previous job and start a new one. |

For cleanup jobs, `Forbid` is usually safest. For stateless jobs, `Allow` is fine.

---

## Imperative Commands — Exam Speed

The exam rewards knowing both imperative and declarative approaches:

```bash
# Create a one-shot Job imperatively
kubectl create job db-seed --image=busybox:1.36 -- sh -c "echo seeding && sleep 3"

# Create a CronJob imperatively
kubectl create cronjob heartbeat --image=busybox:1.36 --schedule="*/5 * * * *" -- sh -c "echo ping"

# Trigger a CronJob manually
kubectl create job --from=cronjob/heartbeat heartbeat-manual-01

# Watch job completion
kubectl get job db-seed -w
```

---

## Discovery Questions

1. A Job's pod exits with code 0. The Job has `completions: 1`. What happens to the pod — does Kubernetes restart it? Why not?

2. You set `backoffLimit: 4` on a Job. The pod fails 5 times. What is the final state of the Job, and how would you find out what went wrong?

3. A CronJob with `concurrencyPolicy: Forbid` is scheduled every minute, but the task takes 90 seconds. What happens to the second scheduled run? What about the third?

4. You want a Job to give up entirely if it hasn't finished within 10 minutes regardless of retry count. Which field do you set and on which object?

5. Your nightly Job cleans up old database records. It completed successfully at 2 AM. At 9 AM you want to see the logs. Is this possible by default? What controls how long completed job pods are retained?

---

## Cleanup

```bash
kubectl delete job db-backup process-reports jerry-migration with-ttl db-seed --ignore-not-found
kubectl delete cronjob nightly-cleanup heartbeat --ignore-not-found
```

---

## Key Takeaways

- **Job**: run a task to completion — pods exit 0 and stay done, no restart
- **CronJob**: Job on a schedule — creates a new Job object each time it fires
- `restartPolicy: Never` creates a new pod on failure; `OnFailure` restarts the same pod
- `backoffLimit` controls total retry attempts; `activeDeadlineSeconds` caps total runtime
- `ttlSecondsAfterFinished` auto-cleans completed jobs and their pods
- Know all three `concurrencyPolicy` values — `Forbid` is the safe default for most scheduled tasks
- CKA expects both imperative (`kubectl create job`, `kubectl create cronjob`) and declarative YAML approaches
