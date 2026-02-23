# Kubeadm Upgrade Runbook

## Pre-Flight
- Current control plane version: ___
- Current kubelet versions: ___
- Target version: ___
- Version skew OK? (kubelet <= 1 minor behind API server): ___

## Control Plane Upgrade
1. `kubeadm upgrade plan` output reviewed: [ ]
2. `kubeadm upgrade apply v___`: [ ]
3. Verify: `kubectl get nodes` shows updated control plane: [ ]

## Worker Node Upgrade (repeat per worker)
- Node name: ___
1. `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data`: [ ]
2. Upgrade kubelet + kubectl packages: [ ]
3. `kubeadm upgrade node`: [ ]
4. `systemctl daemon-reload && systemctl restart kubelet`: [ ]
5. `kubectl uncordon <node>`: [ ]
6. Verify node shows Ready + correct version: [ ]

## Post-Upgrade Validation
- All nodes Ready: [ ]
- All system pods healthy: `kubectl -n kube-system get pods`: [ ]
- Application workloads running: [ ]
