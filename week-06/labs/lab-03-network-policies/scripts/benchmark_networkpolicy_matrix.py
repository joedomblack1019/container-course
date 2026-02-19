#!/usr/bin/env python3
"""
Generate before/after NetworkPolicy reachability charts from policy YAML.
"""

from __future__ import annotations

import argparse
import ipaddress
import json
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import yaml


@dataclass
class Entity:
    key: str
    namespace: Optional[str]
    labels: Dict[str, str]
    ip: Optional[str] = None
    external: bool = False


@dataclass
class Flow:
    name: str
    source: str
    destination: str
    port: int
    protocol: str
    should_work_after_policy: bool


@dataclass
class FlowResult:
    name: str
    source: str
    destination: str
    port: int
    protocol: str
    allowed_before: bool
    allowed_after: bool
    should_work_after_policy: bool


SEVERITY_GREEN = "#2a9d8f"
SEVERITY_RED = "#d62828"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate NetworkPolicy reachability matrix charts."
    )
    parser.add_argument(
        "--policy-file",
        type=Path,
        default=Path("solution/network-policy.yaml"),
        help="Path to combined NetworkPolicy YAML.",
    )
    parser.add_argument(
        "--policy-namespace",
        default="student-dev",
        help="Namespace where policies apply when metadata.namespace is omitted.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Output directory for charts and summaries.",
    )
    parser.add_argument(
        "--no-charts",
        action="store_true",
        help="Skip chart generation (still writes JSON and markdown summary).",
    )
    return parser.parse_args()


def namespace_labels(namespace: str) -> Dict[str, str]:
    return {"kubernetes.io/metadata.name": namespace}


def selector_matches(selector: Optional[Dict[str, object]], labels: Dict[str, str]) -> bool:
    if selector is None:
        return True
    if not isinstance(selector, dict):
        return False

    match_labels = selector.get("matchLabels", {})
    if isinstance(match_labels, dict):
        for key, value in match_labels.items():
            if labels.get(str(key)) != str(value):
                return False

    expressions = selector.get("matchExpressions", [])
    if isinstance(expressions, list):
        for expression in expressions:
            if not isinstance(expression, dict):
                return False
            key = str(expression.get("key", ""))
            operator = str(expression.get("operator", ""))
            values = expression.get("values", [])
            values_set = {str(v) for v in values} if isinstance(values, list) else set()
            present = key in labels

            if operator == "In":
                if not present or labels[key] not in values_set:
                    return False
            elif operator == "NotIn":
                if present and labels[key] in values_set:
                    return False
            elif operator == "Exists":
                if not present:
                    return False
            elif operator == "DoesNotExist":
                if present:
                    return False
            else:
                return False
    return True


def policy_has_ingress(np_spec: Dict[str, object]) -> bool:
    policy_types = np_spec.get("policyTypes")
    if isinstance(policy_types, list):
        return "Ingress" in policy_types
    return "ingress" in np_spec


def policy_has_egress(np_spec: Dict[str, object]) -> bool:
    policy_types = np_spec.get("policyTypes")
    if isinstance(policy_types, list):
        return "Egress" in policy_types
    return "egress" in np_spec


def policy_selects_pod(np_spec: Dict[str, object], pod: Entity) -> bool:
    selector = np_spec.get("podSelector", {})
    return selector_matches(selector if isinstance(selector, dict) else {}, pod.labels)


def port_matches(rule_ports: Optional[List[object]], flow_port: int, flow_protocol: str) -> bool:
    if not rule_ports:
        return True
    for port_entry in rule_ports:
        if not isinstance(port_entry, dict):
            continue
        protocol = str(port_entry.get("protocol", "TCP")).upper()
        if protocol != flow_protocol.upper():
            continue
        port_value = port_entry.get("port")
        if isinstance(port_value, int) and port_value == flow_port:
            return True
        if isinstance(port_value, str):
            try:
                if int(port_value) == flow_port:
                    return True
            except ValueError:
                continue
    return False


def ipblock_matches(ipblock: Dict[str, object], source_ip: Optional[str]) -> bool:
    if source_ip is None:
        return False
    cidr = ipblock.get("cidr")
    if not isinstance(cidr, str):
        return False
    try:
        source_addr = ipaddress.ip_address(source_ip)
        network = ipaddress.ip_network(cidr, strict=False)
    except ValueError:
        return False
    if source_addr not in network:
        return False

    excludes = ipblock.get("except", [])
    if isinstance(excludes, list):
        for exclude_cidr in excludes:
            if not isinstance(exclude_cidr, str):
                continue
            try:
                excluded_network = ipaddress.ip_network(exclude_cidr, strict=False)
            except ValueError:
                continue
            if source_addr in excluded_network:
                return False
    return True


def peer_matches(
    peer: Dict[str, object],
    *,
    source: Entity,
    policy_namespace: str,
) -> bool:
    if "ipBlock" in peer:
        ipblock = peer.get("ipBlock")
        if isinstance(ipblock, dict):
            return ipblock_matches(ipblock, source.ip)
        return False

    ns_selector_obj = peer.get("namespaceSelector")
    pod_selector_obj = peer.get("podSelector")

    if ns_selector_obj is None and pod_selector_obj is None:
        return True

    namespace_ok = True
    if ns_selector_obj is not None:
        if source.namespace is None:
            namespace_ok = False
        else:
            namespace_ok = selector_matches(
                ns_selector_obj if isinstance(ns_selector_obj, dict) else {},
                namespace_labels(source.namespace),
            )
    elif pod_selector_obj is not None:
        namespace_ok = source.namespace == policy_namespace

    pod_ok = True
    if pod_selector_obj is not None:
        pod_ok = selector_matches(
            pod_selector_obj if isinstance(pod_selector_obj, dict) else {},
            source.labels,
        )

    return namespace_ok and pod_ok


def ingress_allowed(
    policies: List[Dict[str, object]],
    destination: Entity,
    source: Entity,
    port: int,
    protocol: str,
) -> bool:
    if destination.external:
        return True

    selected: List[Dict[str, object]] = []
    for policy in policies:
        policy_ns = str(policy["namespace"])
        if destination.namespace != policy_ns:
            continue
        spec = policy["spec"]
        if policy_has_ingress(spec) and policy_selects_pod(spec, destination):
            selected.append(policy)

    if not selected:
        return True

    for policy in selected:
        spec = policy["spec"]
        rules = spec.get("ingress", [])
        if not isinstance(rules, list):
            continue
        for rule in rules:
            if not isinstance(rule, dict):
                continue
            if not port_matches(rule.get("ports"), port, protocol):
                continue
            peers = rule.get("from")
            if peers is None:
                return True
            if isinstance(peers, list):
                for peer in peers:
                    if isinstance(peer, dict) and peer_matches(
                        peer, source=source, policy_namespace=str(policy["namespace"])
                    ):
                        return True
    return False


def egress_allowed(
    policies: List[Dict[str, object]],
    source: Entity,
    destination: Entity,
    port: int,
    protocol: str,
) -> bool:
    if source.external:
        return True

    selected: List[Dict[str, object]] = []
    for policy in policies:
        policy_ns = str(policy["namespace"])
        if source.namespace != policy_ns:
            continue
        spec = policy["spec"]
        if policy_has_egress(spec) and policy_selects_pod(spec, source):
            selected.append(policy)

    if not selected:
        return True

    for policy in selected:
        spec = policy["spec"]
        rules = spec.get("egress", [])
        if not isinstance(rules, list):
            continue
        for rule in rules:
            if not isinstance(rule, dict):
                continue
            if not port_matches(rule.get("ports"), port, protocol):
                continue
            peers = rule.get("to")
            if peers is None:
                return True
            if isinstance(peers, list):
                for peer in peers:
                    peer_source = Entity(
                        key=destination.key,
                        namespace=destination.namespace,
                        labels=destination.labels,
                        ip=destination.ip,
                        external=destination.external,
                    )
                    if isinstance(peer, dict) and peer_matches(
                        peer,
                        source=peer_source,
                        policy_namespace=str(policy["namespace"]),
                    ):
                        return True
    return False


def flow_allowed_after_policy(
    policies: List[Dict[str, object]],
    source: Entity,
    destination: Entity,
    port: int,
    protocol: str,
) -> bool:
    return egress_allowed(policies, source, destination, port, protocol) and ingress_allowed(
        policies, destination, source, port, protocol
    )


def load_policies(policy_file: Path, default_namespace: str) -> List[Dict[str, object]]:
    data = policy_file.read_text(encoding="utf-8")
    docs = list(yaml.safe_load_all(data))
    out: List[Dict[str, object]] = []
    for doc in docs:
        if not isinstance(doc, dict):
            continue
        if str(doc.get("kind")) != "NetworkPolicy":
            continue
        metadata = doc.get("metadata", {})
        spec = doc.get("spec", {})
        if not isinstance(metadata, dict) or not isinstance(spec, dict):
            continue
        namespace = str(metadata.get("namespace", default_namespace))
        out.append(
            {
                "name": str(metadata.get("name", "unnamed-policy")),
                "namespace": namespace,
                "spec": spec,
            }
        )
    return out


def flow_definitions() -> List[Flow]:
    return [
        Flow(
            name="Gateway to student-app",
            source="gateway",
            destination="student-app",
            port=5000,
            protocol="TCP",
            should_work_after_policy=True,
        ),
        Flow(
            name="Gateway to uptime-kuma",
            source="gateway",
            destination="uptime-kuma",
            port=3001,
            protocol="TCP",
            should_work_after_policy=True,
        ),
        Flow(
            name="student-app to redis",
            source="student-app",
            destination="redis",
            port=6379,
            protocol="TCP",
            should_work_after_policy=True,
        ),
        Flow(
            name="uptime-kuma to student-app",
            source="uptime-kuma",
            destination="student-app",
            port=5000,
            protocol="TCP",
            should_work_after_policy=True,
        ),
        Flow(
            name="uptime-kuma to internet HTTPS",
            source="uptime-kuma",
            destination="internet",
            port=443,
            protocol="TCP",
            should_work_after_policy=True,
        ),
        Flow(
            name="student-app to internet HTTPS",
            source="student-app",
            destination="internet",
            port=443,
            protocol="TCP",
            should_work_after_policy=False,
        ),
        Flow(
            name="redis to internet HTTPS",
            source="redis",
            destination="internet",
            port=443,
            protocol="TCP",
            should_work_after_policy=False,
        ),
        Flow(
            name="student-app to DNS",
            source="student-app",
            destination="dns",
            port=53,
            protocol="UDP",
            should_work_after_policy=True,
        ),
        Flow(
            name="redis to DNS",
            source="redis",
            destination="dns",
            port=53,
            protocol="UDP",
            should_work_after_policy=True,
        ),
        Flow(
            name="uptime-kuma to DNS",
            source="uptime-kuma",
            destination="dns",
            port=53,
            protocol="UDP",
            should_work_after_policy=True,
        ),
        Flow(
            name="Gateway to redis",
            source="gateway",
            destination="redis",
            port=6379,
            protocol="TCP",
            should_work_after_policy=False,
        ),
        Flow(
            name="uptime-kuma to redis",
            source="uptime-kuma",
            destination="redis",
            port=6379,
            protocol="TCP",
            should_work_after_policy=False,
        ),
    ]


def entities(policy_namespace: str) -> Dict[str, Entity]:
    return {
        "gateway": Entity(
            key="gateway",
            namespace="kube-system",
            labels={"app": "gateway"},
            ip="10.96.10.10",
        ),
        "student-app": Entity(
            key="student-app",
            namespace=policy_namespace,
            labels={"app": "student-app"},
            ip="10.244.0.11",
        ),
        "redis": Entity(
            key="redis",
            namespace=policy_namespace,
            labels={"app": "redis"},
            ip="10.244.0.12",
        ),
        "uptime-kuma": Entity(
            key="uptime-kuma",
            namespace=policy_namespace,
            labels={"app": "uptime-kuma"},
            ip="10.244.0.13",
        ),
        "dns": Entity(
            key="dns",
            namespace="kube-system",
            labels={"k8s-app": "kube-dns"},
            ip="10.96.0.10",
        ),
        "internet": Entity(
            key="internet",
            namespace=None,
            labels={},
            ip="8.8.8.8",
            external=True,
        ),
    }


def evaluate_flows(
    policy_list: List[Dict[str, object]],
    policy_namespace: str,
) -> Tuple[List[FlowResult], Dict[str, int]]:
    entity_map = entities(policy_namespace)
    results: List[FlowResult] = []
    mismatch_count = 0
    before_allow_count = 0
    after_allow_count = 0

    for flow in flow_definitions():
        src = entity_map[flow.source]
        dst = entity_map[flow.destination]
        allowed_before = True
        allowed_after = flow_allowed_after_policy(
            policy_list, src, dst, flow.port, flow.protocol
        )
        if allowed_before:
            before_allow_count += 1
        if allowed_after:
            after_allow_count += 1
        if allowed_after != flow.should_work_after_policy:
            mismatch_count += 1

        results.append(
            FlowResult(
                name=flow.name,
                source=flow.source,
                destination=flow.destination,
                port=flow.port,
                protocol=flow.protocol,
                allowed_before=allowed_before,
                allowed_after=allowed_after,
                should_work_after_policy=flow.should_work_after_policy,
            )
        )

    summary = {
        "total_flows": len(results),
        "allowed_before": before_allow_count,
        "allowed_after": after_allow_count,
        "expected_after_allow": sum(1 for f in flow_definitions() if f.should_work_after_policy),
        "expectation_mismatches": mismatch_count,
    }
    return results, summary


def generate_charts(results: List[FlowResult], output_dir: Path) -> List[str]:
    try:
        import matplotlib.pyplot as plt
        from matplotlib.colors import ListedColormap
    except ImportError as exc:
        raise RuntimeError(
            "matplotlib is required to generate charts. Install with: pip install matplotlib"
        ) from exc

    matrix_path = output_dir / "networkpolicy_flow_matrix.png"
    rows = [f"{result.source} -> {result.destination}:{result.port}/{result.protocol}" for result in results]
    values = [[1 if result.allowed_before else 0, 1 if result.allowed_after else 0] for result in results]

    fig, ax = plt.subplots(figsize=(9, max(6, 0.45 * len(results))))
    cmap = ListedColormap([SEVERITY_RED, SEVERITY_GREEN])
    ax.imshow(values, cmap=cmap, aspect="auto", vmin=0, vmax=1)
    ax.set_xticks([0, 1], labels=["Before (default allow)", "After (solution policy)"])
    ax.set_yticks(list(range(len(rows))), labels=rows)
    ax.set_title("NetworkPolicy Reachability Matrix")
    ax.set_xlabel("Scenario")
    ax.set_ylabel("Flow")
    for row_idx, row in enumerate(values):
        for col_idx, val in enumerate(row):
            ax.text(col_idx, row_idx, "ALLOW" if val else "DENY", ha="center", va="center", color="white", fontsize=8)
    fig.tight_layout()
    fig.savefig(matrix_path, dpi=160)
    plt.close(fig)

    source_path = output_dir / "networkpolicy_allowed_by_source.png"
    sources = sorted(set(result.source for result in results))
    before_counts = []
    after_counts = []
    for source in sources:
        src_results = [result for result in results if result.source == source]
        before_counts.append(sum(1 for result in src_results if result.allowed_before))
        after_counts.append(sum(1 for result in src_results if result.allowed_after))

    x = list(range(len(sources)))
    width = 0.38
    fig, ax = plt.subplots(figsize=(10, 4.8))
    ax.bar([i - width / 2 for i in x], before_counts, width=width, color="#9aa0a6", label="Before")
    ax.bar([i + width / 2 for i in x], after_counts, width=width, color="#2a9d8f", label="After")
    ax.set_xticks(x, labels=sources)
    ax.set_ylabel("Allowed flow count")
    ax.set_title("Allowed Flows by Source")
    ax.set_axisbelow(True)
    ax.yaxis.grid(True, linestyle="--", alpha=0.35)
    ax.legend()
    fig.tight_layout()
    fig.savefig(source_path, dpi=160)
    plt.close(fig)

    return [str(matrix_path), str(source_path)]


def write_summary_markdown(
    output_dir: Path,
    policy_file: Path,
    policy_namespace: str,
    results: List[FlowResult],
    summary: Dict[str, int],
) -> Path:
    lines = [
        "# NetworkPolicy Reachability Summary",
        "",
        f"- Policy file: `{policy_file}`",
        f"- Evaluated namespace: `{policy_namespace}`",
        f"- Total flows evaluated: `{summary['total_flows']}`",
        f"- Allowed before policy: `{summary['allowed_before']}`",
        f"- Allowed after policy: `{summary['allowed_after']}`",
        f"- Expected allowed after policy: `{summary['expected_after_allow']}`",
        f"- Expectation mismatches: `{summary['expectation_mismatches']}`",
        "",
        "| Flow | Before | After | Expected After |",
        "|---|---:|---:|---:|",
    ]

    for result in results:
        lines.append(
            f"| `{result.name}` | "
            f"{'ALLOW' if result.allowed_before else 'DENY'} | "
            f"{'ALLOW' if result.allowed_after else 'DENY'} | "
            f"{'ALLOW' if result.should_work_after_policy else 'DENY'} |"
        )

    out = output_dir / "summary.md"
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return out


def main() -> None:
    args = parse_args()
    script_dir = Path(__file__).resolve().parent
    lab_dir = script_dir.parent
    course_root = lab_dir.parents[2]
    output_dir = (
        args.output_dir
        if args.output_dir
        else course_root / "assets" / "generated" / "week-06-network-policies"
    )
    output_dir.mkdir(parents=True, exist_ok=True)

    policy_file = args.policy_file
    if not policy_file.is_absolute():
        policy_file = lab_dir / policy_file
    if not policy_file.exists():
        raise FileNotFoundError(f"Policy file not found: {policy_file}")

    policies = load_policies(policy_file, args.policy_namespace)
    if not policies:
        raise RuntimeError(f"No NetworkPolicy documents found in: {policy_file}")

    results, summary = evaluate_flows(policies, args.policy_namespace)
    summary_path = write_summary_markdown(
        output_dir, policy_file, args.policy_namespace, results, summary
    )

    chart_paths: List[str] = []
    chart_error: Optional[str] = None
    if not args.no_charts:
        try:
            chart_paths = generate_charts(results, output_dir)
        except RuntimeError as exc:
            chart_error = str(exc)

    payload = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "policy_file": str(policy_file),
        "policy_namespace": args.policy_namespace,
        "summary": summary,
        "flows": [asdict(result) for result in results],
        "summary_markdown": str(summary_path),
        "charts": chart_paths,
    }
    if chart_error:
        payload["chart_error"] = chart_error

    json_path = output_dir / "results.json"
    json_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    print(f"NetworkPolicy benchmark complete. Results written to: {output_dir}")
    print(f"- JSON: {json_path}")
    print(f"- Summary: {summary_path}")
    if chart_paths:
        print("- Charts:")
        for chart in chart_paths:
            print(f"  - {chart}")
    elif args.no_charts:
        print("- Charts: skipped (--no-charts)")
    elif chart_error:
        print(f"- Charts: not generated ({chart_error})")


if __name__ == "__main__":
    main()
