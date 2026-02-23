# Week-by-Week Build Plan (6 Weeks)

Last updated: 2026-02-22

## Goal

Ship the highest-impact improvements first while keeping instructor workload predictable.

## Week 1

Focus: CKA timed synthesis foundation

- Build skeleton for required mock sprint lab
- Draft scoring rubric by CKA domain weight
- Define remediation worksheet format

Deliverables:

- `week-08/labs/lab-07-cka-mock-sprint/README.md` (draft)
- `instructor/docs/CKA_MOCK_GRADING_RUBRIC.md` (draft)

Exit criteria:

- At least 12 draft tasks written and mapped to domains
- Instructor can run a dry walkthrough in <= 2h 15m

## Week 2

Focus: Workloads/scheduling hardening + CLI drills

- Promote key optional scheduling/autoscaling sections to required
- Add CLI speed drill pack and answer keys

Deliverables:

- Updated `week-07/README.md` and relevant labs
- `instructor/docs/CKA_CLI_SPEED_DRILLS.md`

Exit criteria:

- Required Week 07 checklist includes HPA + scheduling constraints + batch ops
- Drill pack tested by one instructor and one learner

## Week 3

Focus: GitOps promotion process

- Build dev -> staging -> prod promotion lab flow
- Add rollback runbook (Git revert first principle)

Deliverables:

- `week-08/labs/lab-08-gitops-promotion-pipeline/README.md`
- starter manifests/overlays for three environments

Exit criteria:

- Promotion flow reproducible end-to-end
- Rollback path validated through reconciliation evidence

## Week 4

Focus: ArgoCD scaling pattern + policy gates

- Build ApplicationSet multi-app lab
- Add policy-as-code gate lab with CI + admission feedback

Deliverables:

- `week-08/labs/lab-09-argocd-applicationset-multitenant/README.md`
- `week-08/labs/lab-10-policy-gates/README.md`

Exit criteria:

- At least 3 policy failures are reproducible and teachable
- AppSet lab includes one broken-generator troubleshooting case

## Week 5

Focus: Modern auth + secrets lifecycle

- Add OIDC vs workload token model lab
- Add secrets lifecycle and rotation lab

Deliverables:

- `week-04/labs/lab-09-identity-oidc-and-workload-tokens/README.md`
- `week-05/labs/lab-06-secrets-lifecycle-gitops/README.md`

Exit criteria:

- Learner can inspect projected token claims and explain audience use
- Rotation exercise validates before/after behavior

## Week 6

Focus: Observability operations + final quality pass

- Add alerting + SLO triage lab
- Run documentation parity pass across top-level course and gym docs

Deliverables:

- `week-07/labs/lab-09-alerting-and-slo-triage/README.md`
- Updated `container-course/README.md` and `gymctl/README.md`

Exit criteria:

- One alert-driven incident can be triaged to root cause in <= 20 minutes
- No stale status/count references remain in high-visibility docs

## Recommended Cadence

- Monday: planning + scope lock
- Tuesday-Thursday: content build
- Friday: validation dry-runs + docs polish

## Validation Checklist (Each Week)

- Lab README includes prerequisites, step-by-step tasks, verification commands, and cleanup
- At least one realistic failure mode is included
- Homework mapping references real `gymctl` names exactly
- Instructor notes include timing guidance and common learner failure patterns
