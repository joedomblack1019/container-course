# CKA Mock Sprint Grading Rubric

Last updated: 2026-02-22

## Purpose

Provide consistent scoring for the Week 08 CKA mock sprint and ensure every learner gets actionable remediation feedback.

## Scoring Model

- Total score: **100 points**
- Passing target (CKA-ready): **>= 70**
- Strong pass: **>= 80**

## Domain Weights

- Troubleshooting: 30 points
- Cluster Architecture, Installation and Configuration: 25 points
- Services and Networking: 20 points
- Workloads and Scheduling: 15 points
- Storage: 10 points

## Task-Level Scoring

Each task is graded against three criteria:

1. **Correctness (60%)**
   - Final cluster state matches expected behavior
2. **Verification evidence (25%)**
   - Learner shows command-level proof (not just claim)
3. **Operational hygiene (15%)**
   - Uses safe, minimal, reversible changes

Example for an 8-point task:

- Correctness: 4.8 points
- Evidence: 2.0 points
- Hygiene: 1.2 points

Instructors may round to nearest 0.5 for speed.

## Partial Credit Rules

- **Full credit:** task solved and validated with correct evidence
- **High partial (60-80%):** mostly solved, one minor mismatch or weak evidence
- **Mid partial (30-50%):** correct direction but incomplete fix
- **Low partial (10-20%):** attempted but no effective remediation
- **Zero:** no attempt or harmful changes with no recovery

## Deduction Rules

- Missing verification evidence for a solved task: -15% of that task's points
- Wrong-cluster/context actions that affect unrelated resources: -25% of that task's points
- Unsafe destructive action without justification (for example, broad deletes): -25% of that task's points
- Repeated blind trial-and-error with no diagnostic commands: -10% of that task's points

## Evidence Standard

Minimum acceptable evidence for each task:

1. Command(s) run
2. Verification command
3. 1-2 line result summary tied to expected outcome

Evidence must be recorded in:

- `container-course/week-08/labs/lab-07-cka-mock-sprint/starter/mock-scorecard.md`

## Time and Attempt Policy

- Sprint duration: 120 minutes
- Learners can skip tasks and return later
- Scoring is based on end-of-sprint state and scorecard evidence

## Instructor Feedback Format

For each learner, provide:

1. Final score and pass band
2. Domain-by-domain score breakdown
3. Top 3 missed competencies
4. Assigned remediation scenarios from `gymctl`

## Remediation Mapping

- RBAC/admin auth -> `jerry-rbac-denied`
- Context targeting mistakes -> `jerry-kubeconfig-context-confusion`
- Service and endpoint failures -> `jerry-broken-service`, `jerry-nodeport-mystery`
- DNS/CoreDNS failures -> `jerry-coredns-loop`
- Scheduling/control-plane symptoms -> `jerry-scheduler-missing`, `jerry-static-pod-misconfigured`
- Node recovery -> `jerry-node-notready-kubelet`
- Storage binding/reclaim -> `jerry-pvc-pending-storageclass`, `jerry-reclaim-policy-surprise`
- etcd snapshot/restore -> `jerry-etcd-snapshot-missing`

## Readiness Interpretation

- **>= 80:** learner is on-track for exam execution; continue timed practice
- **70-79:** learner is close; assign targeted remediation and retest in 1 week
- **< 70:** learner needs focused domain drills before next full mock
