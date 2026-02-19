# CoreDNS Triage Checklist

1. Validate DNS failure from a workload pod (`nslookup`).
2. Inspect CoreDNS pod status and restarts.
3. Review CoreDNS logs for forwarding/loop/plugin errors.
4. Inspect CoreDNS ConfigMap for broken upstream/forward config.
5. Restore known-good config and confirm rollout.
6. Re-verify DNS lookups from workload pods.
