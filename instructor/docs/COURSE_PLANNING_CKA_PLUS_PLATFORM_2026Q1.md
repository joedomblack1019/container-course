# Course Planning: CKA + Platform Skills (2026 Q1)

Last updated: 2026-02-22

## Purpose

Define a practical build plan for the next iteration of `container-course` so we can:

1. Strengthen CKA exam readiness (especially timed execution and workloads/scheduling repetition)
2. Expand non-CKA production skills (GitOps release process, modern auth patterns, observability operations)
3. Ship improvements in a sequence that fits instructor and content-author bandwidth

## Planning Assumptions

- CKA baseline domains and weights (current LF/CNCF):
  - Troubleshooting: 30%
  - Cluster Architecture, Installation and Configuration: 25%
  - Services and Networking: 20%
  - Workloads and Scheduling: 15%
  - Storage: 10%
- Existing course and gym already provide broad domain coverage from Week 04-08.
- Highest ROI is now integration depth, exam-pressure simulation, and modern platform workflows.

## Current Position

Strengths:

- Strong troubleshooting, cluster admin, and networking labs across Weeks 04-08
- Deep scenario inventory in `gymctl` for failure-based learning
- Good GitOps and ArgoCD fundamentals already in Week 08

Main gaps to close next:

1. No full timed mixed-domain CKA-style mock as a required artifact
2. Workloads/scheduling topics exist, but some are still optional or low-repetition
3. GitOps promotion workflow (dev -> staging -> prod) needs first-class treatment
4. OIDC is present for user auth flow, but workload identity/token model depth is limited
5. Monitoring covers metrics and scrape basics; alerting/SLO incident operations are thin

## Objectives for This Planning Cycle

1. Add one required CKA mock sprint with scoring and remediation loop
2. Convert key workloads/scheduling extension content into required practice
3. Add production GitOps release governance labs (promotion, policy, rollback)
4. Add modern auth module (user identity vs workload identity model)
5. Add observability operations module (alerts + SLO triage)

## Delivery Phases

### Phase 1 (Immediate, highest ROI)

- CKA Mock Sprint (required capstone)
- Workloads/Scheduling hardening (HPA, CronJob, affinity, PDB-safe maintenance)
- Docs and inventory alignment cleanup

### Phase 2 (Platform delivery maturity)

- GitOps promotion pipeline (dev -> staging -> prod)
- ArgoCD ApplicationSet multi-app pattern
- Policy-as-code gate in CI + admission

### Phase 3 (Platform operations maturity)

- Modern Kubernetes auth deep dive (OIDC + projected SA tokens + audiences)
- Secrets lifecycle in GitOps (SOPS/Vault path comparison)
- Observability v2 (Alertmanager + SLO + incident runbook)

### Phase 4 (Optional advanced)

- Logging/tracing correlation module (Loki/OTel)
- Compound control-plane incident chain drills

## Success Metrics

CKA readiness metrics:

- >= 70% average score on required timed mock sprint across two attempts
- <= 15 minutes median resolution time for core troubleshooting incidents by final week

Platform readiness metrics:

- Learners can execute dev -> staging -> prod GitOps promotion with policy gates
- Learners can perform rollback via Git revert and explain why UI-only rollback is transient
- Learners can triage one alert-to-root-cause scenario with evidence

## Deliverables

- New/updated lab READMEs and starter assets in Week 07-08 folders
- New/updated `gymctl` scenarios where reinforcement is missing
- Instructor runbooks for timed execution and grading
- Updated top-level course docs to match current week and exercise reality

## Risks and Mitigations

- Risk: Scope creep from "nice-to-have" platform topics
  - Mitigation: Keep Phase 1 mandatory, Phase 4 explicitly optional
- Risk: Learner overload in Week 08
  - Mitigation: Move some repeated drills to Week 07 pre-work
- Risk: Tooling complexity in local environments
  - Mitigation: Prefer reproducible kind-based scripts and preflight checks

## Decision Log

- 2026-02-22: Prioritize CKA timed synthesis + GitOps promotion depth before adding tracing stack complexity.
