# Deployment Rollout Timeline Summary

- Namespace: `rollout-bench`
- Deployment: `rollout-app`
- Samples: `33`
- Initial replicas: `1`
- Final replicas: `1`
- Max replicas observed: `4`
- Max ready replicas observed: `3`
- Revision range observed: `5 -> 7`

| Event | Elapsed (s) | Status | Command |
|---|---:|---|---|
| `scale` | 5.34 | ok | `kubectl -n rollout-bench scale deployment rollout-app --replicas=3` |
| `rollout-restart` | 15.50 | ok | `kubectl -n rollout-bench rollout restart deployment/rollout-app` |
| `rollout-undo` | 30.59 | ok | `kubectl -n rollout-bench rollout undo deployment/rollout-app` |
| `restore-scale` | 55.82 | ok | `kubectl -n rollout-bench scale deployment rollout-app --replicas=1` |
