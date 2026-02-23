# NetworkPolicy Reachability Summary

- Policy file: `/home/jg/git/shart-cloud-gh/containers/container-course/week-06/labs/lab-03-network-policies/solution/network-policy.yaml`
- Evaluated namespace: `student-dev`
- Total flows evaluated: `12`
- Allowed before policy: `12`
- Allowed after policy: `8`
- Expected allowed after policy: `8`
- Expectation mismatches: `0`

| Flow | Before | After | Expected After |
|---|---:|---:|---:|
| `Gateway to student-app` | ALLOW | ALLOW | ALLOW |
| `Gateway to uptime-kuma` | ALLOW | ALLOW | ALLOW |
| `student-app to redis` | ALLOW | ALLOW | ALLOW |
| `uptime-kuma to student-app` | ALLOW | ALLOW | ALLOW |
| `uptime-kuma to internet HTTPS` | ALLOW | ALLOW | ALLOW |
| `student-app to internet HTTPS` | ALLOW | DENY | DENY |
| `redis to internet HTTPS` | ALLOW | DENY | DENY |
| `student-app to DNS` | ALLOW | ALLOW | ALLOW |
| `redis to DNS` | ALLOW | ALLOW | ALLOW |
| `uptime-kuma to DNS` | ALLOW | ALLOW | ALLOW |
| `Gateway to redis` | ALLOW | DENY | DENY |
| `uptime-kuma to redis` | ALLOW | DENY | DENY |
