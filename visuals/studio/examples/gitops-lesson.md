---
id: week-08-gitops-loop
title: The GitOps Loop
visuals:
  profile: win98-classic
  hero:
    scene: gitops-loop
    title: GitOps Loop in One Look
    subtitle: Commit -> reconcile -> health -> drift correction
  gifs:
    - name: gitops-flow
      scene: gitops-loop
      title: Reconciliation Sequence
      subtitle: Desired state converges through continuous control.
      frames: 48
      fps: 6
  infoSlides:
    - name: summary
      scene: info-summary
      title: GitOps Mental Model
      subtitle: Keep this model in your head while debugging.
      bullets:
        - Git is the desired state contract.
        - Controllers close drift continuously, not once.
        - Revert commits are production rollbacks.
        - Health checks are part of reconciliation, not an afterthought.
    - name: etcd
      scene: etcd-replication
      title: Why etcd Quorum Matters
      subtitle: Reliability comes from majority agreement.
---

# Optional lesson notes

This body text is ignored by the visual generator.
