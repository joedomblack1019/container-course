# Layer Cache Benchmark Results

| Build | Dockerfile | Cold Cache | Duration (s) | Cached Steps | Total Steps | Cache Hit % | pip install Cached |
|---|---|---:|---:|---:|---:|---:|---:|
| `slow_cold` | `Dockerfile` | yes | 67.115 | 0 | 5 | 0.0% | no |
| `slow_rebuild` | `Dockerfile` | no | 64.952 | 1 | 5 | 20.0% | no |
| `fast_cold` | `Dockerfile.optimized` | yes | 66.779 | 0 | 6 | 0.0% | no |
| `fast_rebuild` | `Dockerfile.optimized` | no | 0.427 | 3 | 6 | 50.0% | yes |

## Key Comparison

- Slow rebuild: **64.952s**
- Fast rebuild: **0.427s**
- Time saved: **64.525s**
- Speedup: **152.11x**
