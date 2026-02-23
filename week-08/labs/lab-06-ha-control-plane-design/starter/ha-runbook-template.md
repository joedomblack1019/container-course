# HA Control Plane Incident Runbook Template

1. Confirm API server reachability and client impact.
2. Check etcd member health and quorum.
3. Identify failed control-plane node and failure domain.
4. Recover or replace failed node.
5. Re-validate scheduler/controller-manager leadership.
6. Confirm workload health and close incident.
