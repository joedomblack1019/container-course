# Output Formatting Speed Drills

Target pace: 2-3 minutes per drill (25 minutes total).
Run these after Lab 4 Part 1, when your `kind-ops` cluster and `ops-lab` workload are running.
For each drill: write your command first, run it, and note one quick verification before opening the answer.

After these drills, complete the graded checkpoint in `starter/jsonpath-check.txt` and validate with:

```bash
bash starter/validate-jsonpath-check.sh ./jsonpath-check.txt
```

1. [ ] List all nodes sorted by creation timestamp.

<details>
<summary>Answer command</summary>

```bash
kubectl get nodes --sort-by=.metadata.creationTimestamp
```

</details>

2. [ ] Show only node names and kubelet versions.

<details>
<summary>Answer command</summary>

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,VERSION:.status.nodeInfo.kubeletVersion
```

</details>

3. [ ] Get all pod names in `ops-lab` as a space-separated list.

<details>
<summary>Answer command</summary>

```bash
kubectl get pods -n ops-lab -o jsonpath='{.items[*].metadata.name}'
```

</details>

4. [ ] Show each pod and the node it runs on in `ops-lab`.

<details>
<summary>Answer command</summary>

```bash
kubectl get pods -n ops-lab -o custom-columns=POD:.metadata.name,NODE:.spec.nodeName
```

</details>

5. [ ] List pods with restart counts (ascending output; descending is a follow-up challenge).

<details>
<summary>Answer command</summary>

```bash
kubectl get pods -A -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.containerStatuses[0].restartCount}{"\n"}{end}'
```

</details>

6. [ ] Get the internal IP of all nodes.

<details>
<summary>Answer command</summary>

```bash
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'
```

</details>

7. [ ] Find which node has the most allocatable CPU (start with a custom-columns view).

<details>
<summary>Answer command</summary>

```bash
kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu
```

</details>

8. [ ] Get the image used by each container in `ops-lab`.

<details>
<summary>Answer command</summary>

```bash
kubectl get pods -n ops-lab -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].image}{"\n"}{end}'
```

</details>

9. [ ] List PVs sorted by capacity.

<details>
<summary>Answer command</summary>

```bash
kubectl get pv --sort-by=.spec.capacity.storage
```

</details>

10. [ ] Get service names and ClusterIPs in `ops-lab`.

<details>
<summary>Answer command</summary>

```bash
kubectl get svc -n ops-lab -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.clusterIP}{"\n"}{end}'
```

</details>
