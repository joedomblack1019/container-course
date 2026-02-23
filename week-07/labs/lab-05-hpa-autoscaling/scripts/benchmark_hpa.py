#!/usr/bin/env python3
"""
Capture HPA behavior over time and generate autoscaling charts.
"""

from __future__ import annotations

import argparse
import json
import math
import subprocess
import time
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional


@dataclass
class Sample:
    timestamp_utc: str
    elapsed_seconds: float
    load_active: bool
    hpa_name: str
    deployment_name: str
    target_cpu_utilization: Optional[int]
    current_cpu_utilization: Optional[int]
    current_replicas: int
    desired_replicas: int
    deployment_replicas: int
    deployment_ready_replicas: int
    deployment_available_replicas: int
    deployment_updated_replicas: int
    condition_able_to_scale: Optional[str]
    condition_scaling_active: Optional[str]
    condition_scaling_limited: Optional[str]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Benchmark and visualize HPA autoscaling behavior over time."
    )
    parser.add_argument("--namespace", default="default", help="Kubernetes namespace.")
    parser.add_argument("--deployment", default="student-app", help="Deployment name.")
    parser.add_argument("--hpa", default="student-app-hpa", help="HPA name.")
    parser.add_argument("--service", default="student-app-svc", help="Service name hit by load generator.")
    parser.add_argument("--load-pod-name", default="load-gen-bench", help="Load-generator pod name.")
    parser.add_argument(
        "--sample-interval",
        type=float,
        default=5.0,
        help="Sampling interval in seconds.",
    )
    parser.add_argument(
        "--load-seconds",
        type=int,
        default=120,
        help="Seconds to keep load generator running.",
    )
    parser.add_argument(
        "--cooldown-seconds",
        type=int,
        default=180,
        help="Seconds to continue sampling after load stops.",
    )
    parser.add_argument(
        "--skip-load",
        action="store_true",
        help="Do not create load generator pod (sample only).",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Output directory for charts, logs, and results JSON.",
    )
    parser.add_argument(
        "--no-charts",
        action="store_true",
        help="Skip chart generation (still writes JSON and summary).",
    )
    return parser.parse_args()


def run_cmd(cmd: List[str], *, check: bool = False) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if check and result.returncode != 0:
        joined = " ".join(cmd)
        raise RuntimeError(
            f"Command failed ({result.returncode}): {joined}\nSTDERR:\n{result.stderr.strip()}"
        )
    return result


def kubectl_json(args: List[str]) -> Dict[str, object]:
    result = run_cmd(["kubectl", *args, "-o", "json"], check=True)
    try:
        payload: Dict[str, object] = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Failed to parse JSON for kubectl {' '.join(args)}") from exc
    return payload


def get_condition(status: Dict[str, object], condition_type: str) -> Optional[str]:
    conditions = status.get("conditions", [])
    if not isinstance(conditions, list):
        return None
    for condition in conditions:
        if not isinstance(condition, dict):
            continue
        if str(condition.get("type")) == condition_type:
            return str(condition.get("status"))
    return None


def hpa_cpu_values(hpa: Dict[str, object]) -> Dict[str, Optional[int]]:
    spec = hpa.get("spec", {})
    status = hpa.get("status", {})

    target_util: Optional[int] = None
    metrics = spec.get("metrics", []) if isinstance(spec, dict) else []
    if isinstance(metrics, list):
        for metric in metrics:
            if not isinstance(metric, dict):
                continue
            if metric.get("type") != "Resource":
                continue
            resource = metric.get("resource", {})
            if not isinstance(resource, dict):
                continue
            if resource.get("name") != "cpu":
                continue
            target = resource.get("target", {})
            if isinstance(target, dict) and isinstance(target.get("averageUtilization"), int):
                target_util = int(target["averageUtilization"])
            break

    current_util: Optional[int] = None
    current_metrics = status.get("currentMetrics", []) if isinstance(status, dict) else []
    if isinstance(current_metrics, list):
        for metric in current_metrics:
            if not isinstance(metric, dict):
                continue
            if metric.get("type") != "Resource":
                continue
            resource = metric.get("resource", {})
            if not isinstance(resource, dict):
                continue
            if resource.get("name") != "cpu":
                continue
            current = resource.get("current", {})
            if isinstance(current, dict) and isinstance(current.get("averageUtilization"), int):
                current_util = int(current["averageUtilization"])
            break

    return {"target": target_util, "current": current_util}


def ensure_prereqs(namespace: str, hpa_name: str, deployment_name: str) -> None:
    run_cmd(["kubectl", "version", "--client"], check=True)
    hpa_check = run_cmd(["kubectl", "-n", namespace, "get", "hpa", hpa_name], check=False)
    if hpa_check.returncode != 0:
        stderr = hpa_check.stderr.strip()
        if "NotFound" in stderr:
            raise RuntimeError(
                f"HPA '{hpa_name}' not found in namespace '{namespace}'. "
                "Create it first (Part 2/3) or pass the correct name with --hpa."
            )
        raise RuntimeError(
            f"Unable to read HPA '{hpa_name}' in namespace '{namespace}'.\nSTDERR:\n{stderr}"
        )

    deploy_check = run_cmd(
        ["kubectl", "-n", namespace, "get", "deployment", deployment_name], check=False
    )
    if deploy_check.returncode != 0:
        stderr = deploy_check.stderr.strip()
        if "NotFound" in stderr:
            raise RuntimeError(
                f"Deployment '{deployment_name}' not found in namespace '{namespace}'. "
                "Deploy it first or pass the correct name with --deployment."
            )
        raise RuntimeError(
            f"Unable to read deployment '{deployment_name}' in namespace '{namespace}'.\nSTDERR:\n{stderr}"
        )


def create_load_pod(namespace: str, pod_name: str, service_name: str) -> None:
    run_cmd(
        ["kubectl", "-n", namespace, "delete", "pod", pod_name, "--ignore-not-found=true"],
        check=False,
    )
    load_cmd = (
        f"while true; do wget -q -O- http://{service_name} >/dev/null; done"
    )
    run_cmd(
        [
            "kubectl",
            "-n",
            namespace,
            "run",
            pod_name,
            "--restart=Never",
            "--image=busybox",
            "--",
            "/bin/sh",
            "-c",
            load_cmd,
        ],
        check=True,
    )


def delete_load_pod(namespace: str, pod_name: str) -> None:
    run_cmd(
        [
            "kubectl",
            "-n",
            namespace,
            "delete",
            "pod",
            pod_name,
            "--ignore-not-found=true",
            "--wait=false",
        ],
        check=False,
    )


def take_sample(
    *,
    namespace: str,
    hpa_name: str,
    deployment_name: str,
    elapsed_seconds: float,
    load_active: bool,
) -> Sample:
    hpa = kubectl_json(["-n", namespace, "get", "hpa", hpa_name])
    deployment = kubectl_json(["-n", namespace, "get", "deployment", deployment_name])

    hpa_status = hpa.get("status", {})
    deployment_status = deployment.get("status", {})
    cpu = hpa_cpu_values(hpa)

    current_replicas = int(hpa_status.get("currentReplicas", 0)) if isinstance(hpa_status, dict) else 0
    desired_replicas = int(hpa_status.get("desiredReplicas", 0)) if isinstance(hpa_status, dict) else 0

    dep_replicas = int(deployment_status.get("replicas", 0)) if isinstance(deployment_status, dict) else 0
    dep_ready = int(deployment_status.get("readyReplicas", 0)) if isinstance(deployment_status, dict) else 0
    dep_available = (
        int(deployment_status.get("availableReplicas", 0))
        if isinstance(deployment_status, dict)
        else 0
    )
    dep_updated = (
        int(deployment_status.get("updatedReplicas", 0))
        if isinstance(deployment_status, dict)
        else 0
    )

    return Sample(
        timestamp_utc=datetime.now(timezone.utc).isoformat(),
        elapsed_seconds=round(elapsed_seconds, 2),
        load_active=load_active,
        hpa_name=hpa_name,
        deployment_name=deployment_name,
        target_cpu_utilization=cpu["target"],
        current_cpu_utilization=cpu["current"],
        current_replicas=current_replicas,
        desired_replicas=desired_replicas,
        deployment_replicas=dep_replicas,
        deployment_ready_replicas=dep_ready,
        deployment_available_replicas=dep_available,
        deployment_updated_replicas=dep_updated,
        condition_able_to_scale=get_condition(hpa_status, "AbleToScale")
        if isinstance(hpa_status, dict)
        else None,
        condition_scaling_active=get_condition(hpa_status, "ScalingActive")
        if isinstance(hpa_status, dict)
        else None,
        condition_scaling_limited=get_condition(hpa_status, "ScalingLimited")
        if isinstance(hpa_status, dict)
        else None,
    )


def chart_values(values: List[Optional[int]]) -> List[float]:
    out: List[float] = []
    for value in values:
        out.append(float(value) if value is not None else math.nan)
    return out


def generate_charts(samples: List[Sample], output_dir: Path, load_seconds: int) -> List[str]:
    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise RuntimeError(
            "matplotlib is required to generate charts. Install with: pip install matplotlib"
        ) from exc

    x = [sample.elapsed_seconds for sample in samples]

    hpa_timeline = output_dir / "hpa_timeline.png"
    fig, ax_left = plt.subplots(figsize=(11, 5))
    ax_right = ax_left.twinx()

    cpu_current = chart_values([sample.current_cpu_utilization for sample in samples])
    cpu_target = chart_values([sample.target_cpu_utilization for sample in samples])
    current_rep = [sample.current_replicas for sample in samples]
    desired_rep = [sample.desired_replicas for sample in samples]

    ax_left.plot(x, cpu_current, color="#d62828", linewidth=2, marker="o", markersize=3, label="CPU % (current)")
    ax_left.plot(x, cpu_target, color="#f77f00", linewidth=1.8, linestyle="--", label="CPU % (target)")
    ax_left.set_ylabel("CPU Utilization (%)")
    ax_left.set_xlabel("Elapsed seconds")
    ax_left.set_axisbelow(True)
    ax_left.yaxis.grid(True, linestyle="--", alpha=0.35)

    ax_right.plot(x, current_rep, color="#1d3557", linewidth=2, marker="o", markersize=3, label="Current replicas")
    ax_right.plot(x, desired_rep, color="#2a9d8f", linewidth=2, marker="o", markersize=3, label="Desired replicas")
    ax_right.set_ylabel("Replicas")

    ax_left.axvspan(0, load_seconds, color="#a8dadc", alpha=0.25, label="Load active window")
    ax_left.set_title("HPA Timeline: CPU Target vs Replica Decisions")

    handles_left, labels_left = ax_left.get_legend_handles_labels()
    handles_right, labels_right = ax_right.get_legend_handles_labels()
    ax_left.legend(handles_left + handles_right, labels_left + labels_right, loc="upper left")
    fig.tight_layout()
    fig.savefig(hpa_timeline, dpi=160)
    plt.close(fig)

    deployment_timeline = output_dir / "deployment_replica_timeline.png"
    fig, ax = plt.subplots(figsize=(11, 4.8))
    ax.plot(x, [sample.deployment_replicas for sample in samples], label="Deployment replicas", linewidth=2, color="#264653")
    ax.plot(x, [sample.deployment_ready_replicas for sample in samples], label="Ready replicas", linewidth=2, color="#2a9d8f")
    ax.plot(x, [sample.deployment_available_replicas for sample in samples], label="Available replicas", linewidth=2, color="#457b9d")
    ax.plot(x, [sample.deployment_updated_replicas for sample in samples], label="Updated replicas", linewidth=2, color="#e76f51")
    ax.axvspan(0, load_seconds, color="#a8dadc", alpha=0.25, label="Load active window")
    ax.set_title("Deployment Replica State Over Time")
    ax.set_xlabel("Elapsed seconds")
    ax.set_ylabel("Replicas")
    ax.set_axisbelow(True)
    ax.yaxis.grid(True, linestyle="--", alpha=0.35)
    ax.legend(loc="upper left")
    fig.tight_layout()
    fig.savefig(deployment_timeline, dpi=160)
    plt.close(fig)

    return [str(hpa_timeline), str(deployment_timeline)]


def summarize(samples: List[Sample], args: argparse.Namespace) -> Dict[str, object]:
    initial = samples[0]
    max_current = max(sample.current_replicas for sample in samples)
    max_desired = max(sample.desired_replicas for sample in samples)
    final = samples[-1]

    first_scale_up_second: Optional[float] = None
    for sample in samples:
        if sample.current_replicas > initial.current_replicas or sample.desired_replicas > initial.desired_replicas:
            first_scale_up_second = sample.elapsed_seconds
            break

    current_cpu_values = [
        sample.current_cpu_utilization
        for sample in samples
        if sample.current_cpu_utilization is not None
    ]
    avg_cpu = round(sum(current_cpu_values) / len(current_cpu_values), 2) if current_cpu_values else None

    return {
        "namespace": args.namespace,
        "hpa": args.hpa,
        "deployment": args.deployment,
        "sample_count": len(samples),
        "sample_interval_seconds": args.sample_interval,
        "load_seconds": args.load_seconds,
        "cooldown_seconds": args.cooldown_seconds,
        "max_current_replicas": max_current,
        "max_desired_replicas": max_desired,
        "initial_current_replicas": initial.current_replicas,
        "final_current_replicas": final.current_replicas,
        "first_scale_up_second": first_scale_up_second,
        "average_cpu_utilization_percent": avg_cpu,
    }


def write_summary_md(output_dir: Path, summary: Dict[str, object]) -> Path:
    lines = [
        "# HPA Benchmark Summary",
        "",
        f"- Namespace: `{summary['namespace']}`",
        f"- HPA: `{summary['hpa']}`",
        f"- Deployment: `{summary['deployment']}`",
        f"- Samples: `{summary['sample_count']}`",
        f"- Max current replicas: `{summary['max_current_replicas']}`",
        f"- Max desired replicas: `{summary['max_desired_replicas']}`",
        f"- Initial current replicas: `{summary['initial_current_replicas']}`",
        f"- Final current replicas: `{summary['final_current_replicas']}`",
        f"- First scale-up observed at: `{summary['first_scale_up_second']}` seconds",
        f"- Average observed CPU utilization: `{summary['average_cpu_utilization_percent']}`%",
    ]
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
        else course_root / "assets" / "generated" / "week-07-hpa-autoscaling"
    )
    output_dir.mkdir(parents=True, exist_ok=True)

    ensure_prereqs(args.namespace, args.hpa, args.deployment)

    total_seconds = args.load_seconds + args.cooldown_seconds
    start = time.monotonic()
    next_tick = 0.0
    load_active = False
    load_stopped = False
    samples: List[Sample] = []

    if not args.skip_load:
        create_load_pod(args.namespace, args.load_pod_name, args.service)
        load_active = True

    try:
        while True:
            elapsed = time.monotonic() - start
            if elapsed >= total_seconds:
                break

            if load_active and elapsed >= args.load_seconds and not load_stopped:
                delete_load_pod(args.namespace, args.load_pod_name)
                load_active = False
                load_stopped = True

            if elapsed >= next_tick:
                sample = take_sample(
                    namespace=args.namespace,
                    hpa_name=args.hpa,
                    deployment_name=args.deployment,
                    elapsed_seconds=elapsed,
                    load_active=load_active,
                )
                samples.append(sample)
                next_tick += args.sample_interval

            time.sleep(0.2)
    finally:
        if not args.skip_load:
            delete_load_pod(args.namespace, args.load_pod_name)

    if not samples:
        raise RuntimeError("No samples collected. Check kubectl access and HPA state.")

    summary = summarize(samples, args)
    summary_path = write_summary_md(output_dir, summary)

    chart_paths: List[str] = []
    chart_error: Optional[str] = None
    if not args.no_charts:
        try:
            chart_paths = generate_charts(samples, output_dir, args.load_seconds)
        except RuntimeError as exc:
            chart_error = str(exc)

    payload = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "summary": summary,
        "samples": [asdict(sample) for sample in samples],
        "charts": chart_paths,
        "summary_markdown": str(summary_path),
    }
    if chart_error:
        payload["chart_error"] = chart_error

    json_path = output_dir / "results.json"
    json_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    print(f"HPA benchmark complete. Results written to: {output_dir}")
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
