# Upgrade Planning Checklist

1. Record current API server and kubelet versions.
2. Confirm target version and supported skew.
3. Upgrade control plane components first.
4. Drain/upgrade/uncordon workers one at a time.
5. Validate workload health and events after each node.
6. Keep rollback notes before every disruptive step.
