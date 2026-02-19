#!/usr/bin/env python3
"""
Capture a deployment rollout timeline and generate charts.
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
class DeploymentSample:
    timestamp_utc: str
    elapsed_seconds: float
    revision: Optional[int]
    desired_replicas: int
    replicas: int
    ready_replicas: int
    available_replicas: int
    updated_replicas: int
    unavailable_replicas: int
    pods_running: int
    pods_pending: int
    pods_failed: int
    pods_succeeded: int
    pods_unknown: int
    progressing_condition: Optional[str]
    available_condition: Optional[str]


@dataclass
class ActionEvent:
    name: str
    elapsed_seconds: float
    command: str
    return_code: int
    stderr: str


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Benchmark deployment scale/update/rollback timeline."
    )
    parser.add_argument("--namespace", default="default", help="Kubernetes namespace.")
    parser.add_argument("--deployment", default="student-app", help="Deployment name.")
    parser.add_argument("--sample-interval", type=float, default=3.0, help="Sampling interval in seconds.")
    parser.add_argument("--pre-seconds", type=int, default=20, help="Pre-action sampling seconds.")
    parser.add_argument("--scale-to", type=int, default=3, help="Replica count for scale action.")
    parser.add_argument("--after-scale-seconds", type=int, default=40, help="Sampling time after scale action.")
    parser.add_argument("--after-restart-seconds", type=int, default=60, help="Sampling time after rollout restart.")
    parser.add_argument("--after-undo-seconds", type=int, default=80, help="Sampling time after rollout undo.")
    parser.add_argument("--post-seconds", type=int, default=20, help="Final sampling time after all actions.")
    parser.add_argument(
        "--after-restore-seconds",
        type=int,
        default=20,
        help="Sampling time after restoring initial replica count.",
    )
    parser.add_argument(
        "--skip-actions",
        action="store_true",
        help="Only sample rollout state (do not run scale/restart/undo).",
    )
    parser.add_argument(
        "--no-restore-scale",
        action="store_true",
        help="Do not restore initial replica count after scripted actions.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Output directory for charts and JSON summary.",
    )
    parser.add_argument(
        "--no-charts",
        action="store_true",
        help="Skip chart generation (still writes JSON and markdown summary).",
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
        raise RuntimeError(
            f"Command failed ({result.returncode}): {' '.join(cmd)}\nSTDERR:\n{result.stderr.strip()}"
        )
    return result


def kubectl_json(args: List[str]) -> Dict[str, object]:
    result = run_cmd(["kubectl", *args, "-o", "json"], check=True)
    try:
        payload: Dict[str, object] = json.loads(result.stdout)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Failed to parse JSON: kubectl {' '.join(args)}") from exc
    return payload


def selector_from_deployment(dep_json: Dict[str, object]) -> str:
    spec = dep_json.get("spec", {})
    selector = spec.get("selector", {}) if isinstance(spec, dict) else {}
    match_labels = selector.get("matchLabels", {}) if isinstance(selector, dict) else {}
    if not isinstance(match_labels, dict) or not match_labels:
        raise RuntimeError("Deployment selector.matchLabels is missing; cannot list pods.")
    parts = [f"{k}={v}" for k, v in match_labels.items()]
    return ",".join(parts)


def condition_status(status: Dict[str, object], condition_type: str) -> Optional[str]:
    conditions = status.get("conditions", [])
    if not isinstance(conditions, list):
        return None
    for condition in conditions:
        if not isinstance(condition, dict):
            continue
        if str(condition.get("type")) == condition_type:
            return str(condition.get("status"))
    return None


def deployment_revision(dep_json: Dict[str, object]) -> Optional[int]:
    metadata = dep_json.get("metadata", {})
    if not isinstance(metadata, dict):
        return None
    annotations = metadata.get("annotations", {})
    if not isinstance(annotations, dict):
        return None
    value = annotations.get("deployment.kubernetes.io/revision")
    if value is None:
        return None
    try:
        return int(str(value))
    except ValueError:
        return None


def sample_deployment(namespace: str, deployment: str) -> DeploymentSample:
    dep_json = kubectl_json(["-n", namespace, "get", "deployment", deployment])
    selector = selector_from_deployment(dep_json)
    pods_json = kubectl_json(["-n", namespace, "get", "pods", "-l", selector])

    spec = dep_json.get("spec", {})
    status = dep_json.get("status", {})
    if not isinstance(spec, dict):
        spec = {}
    if not isinstance(status, dict):
        status = {}

    phase_counts = {
        "Running": 0,
        "Pending": 0,
        "Failed": 0,
        "Succeeded": 0,
        "Unknown": 0,
    }
    items = pods_json.get("items", [])
    if isinstance(items, list):
        for item in items:
            if not isinstance(item, dict):
                continue
            pod_status = item.get("status", {})
            if not isinstance(pod_status, dict):
                continue
            phase = str(pod_status.get("phase", "Unknown"))
            if phase not in phase_counts:
                phase = "Unknown"
            phase_counts[phase] += 1

    return DeploymentSample(
        timestamp_utc=datetime.now(timezone.utc).isoformat(),
        elapsed_seconds=0.0,
        revision=deployment_revision(dep_json),
        desired_replicas=int(spec.get("replicas", 0) or 0),
        replicas=int(status.get("replicas", 0) or 0),
        ready_replicas=int(status.get("readyReplicas", 0) or 0),
        available_replicas=int(status.get("availableReplicas", 0) or 0),
        updated_replicas=int(status.get("updatedReplicas", 0) or 0),
        unavailable_replicas=int(status.get("unavailableReplicas", 0) or 0),
        pods_running=phase_counts["Running"],
        pods_pending=phase_counts["Pending"],
        pods_failed=phase_counts["Failed"],
        pods_succeeded=phase_counts["Succeeded"],
        pods_unknown=phase_counts["Unknown"],
        progressing_condition=condition_status(status, "Progressing"),
        available_condition=condition_status(status, "Available"),
    )


def run_action(cmd: List[str], name: str, start_ts: float) -> ActionEvent:
    result = run_cmd(cmd, check=False)
    return ActionEvent(
        name=name,
        elapsed_seconds=round(time.monotonic() - start_ts, 2),
        command=" ".join(cmd),
        return_code=result.returncode,
        stderr=result.stderr.strip(),
    )


def values_or_nan(values: List[Optional[int]]) -> List[float]:
    out: List[float] = []
    for value in values:
        out.append(float(value) if value is not None else math.nan)
    return out


def generate_charts(
    samples: List[DeploymentSample],
    events: List[ActionEvent],
    output_dir: Path,
) -> List[str]:
    try:
        import matplotlib.pyplot as plt
    except ImportError as exc:
        raise RuntimeError(
            "matplotlib is required to generate charts. Install with: pip install matplotlib"
        ) from exc

    x = [sample.elapsed_seconds for sample in samples]

    rollout_chart = output_dir / "deployment_rollout_timeline.png"
    fig, ax = plt.subplots(figsize=(11, 5))
    ax.plot(x, [sample.desired_replicas for sample in samples], label="Desired", linewidth=2, color="#1d3557")
    ax.plot(x, [sample.replicas for sample in samples], label="Replicas", linewidth=2, color="#457b9d")
    ax.plot(x, [sample.updated_replicas for sample in samples], label="Updated", linewidth=2, color="#2a9d8f")
    ax.plot(x, [sample.ready_replicas for sample in samples], label="Ready", linewidth=2, color="#f4a261")
    ax.plot(x, [sample.available_replicas for sample in samples], label="Available", linewidth=2, color="#e76f51")

    for event in events:
        color = "#2a9d8f" if event.return_code == 0 else "#d62828"
        ax.axvline(event.elapsed_seconds, color=color, linestyle="--", alpha=0.7)
        ax.text(
            event.elapsed_seconds,
            ax.get_ylim()[1] * 0.95,
            event.name,
            rotation=90,
            va="top",
            ha="right",
            fontsize=8,
            color=color,
        )

    ax.set_title("Deployment Rollout Timeline")
    ax.set_xlabel("Elapsed seconds")
    ax.set_ylabel("Replica count")
    ax.set_axisbelow(True)
    ax.yaxis.grid(True, linestyle="--", alpha=0.35)
    ax.legend(loc="upper left")
    fig.tight_layout()
    fig.savefig(rollout_chart, dpi=160)
    plt.close(fig)

    pod_chart = output_dir / "deployment_pod_phase_timeline.png"
    fig, ax = plt.subplots(figsize=(11, 4.8))
    running = [sample.pods_running for sample in samples]
    pending = [sample.pods_pending for sample in samples]
    failed = [sample.pods_failed for sample in samples]
    succeeded = [sample.pods_succeeded for sample in samples]
    unknown = [sample.pods_unknown for sample in samples]
    ax.stackplot(
        x,
        running,
        pending,
        failed,
        succeeded,
        unknown,
        labels=["Running", "Pending", "Failed", "Succeeded", "Unknown"],
        colors=["#2a9d8f", "#f4a261", "#d62828", "#577590", "#8d99ae"],
        alpha=0.9,
    )

    revisions = values_or_nan([sample.revision for sample in samples])
    ax2 = ax.twinx()
    ax2.plot(x, revisions, color="#1d3557", linestyle="--", linewidth=1.8, label="Revision")
    ax2.set_ylabel("Deployment revision")

    for event in events:
        color = "#2a9d8f" if event.return_code == 0 else "#d62828"
        ax.axvline(event.elapsed_seconds, color=color, linestyle="--", alpha=0.35)

    handles_1, labels_1 = ax.get_legend_handles_labels()
    handles_2, labels_2 = ax2.get_legend_handles_labels()
    ax.legend(handles_1 + handles_2, labels_1 + labels_2, loc="upper left")
    ax.set_title("Pod Phase and Revision Timeline")
    ax.set_xlabel("Elapsed seconds")
    ax.set_ylabel("Pod count")
    ax.set_axisbelow(True)
    ax.yaxis.grid(True, linestyle="--", alpha=0.35)
    fig.tight_layout()
    fig.savefig(pod_chart, dpi=160)
    plt.close(fig)

    return [str(rollout_chart), str(pod_chart)]


def write_summary_markdown(
    output_dir: Path,
    namespace: str,
    deployment: str,
    samples: List[DeploymentSample],
    events: List[ActionEvent],
) -> Path:
    first = samples[0]
    last = samples[-1]
    max_ready = max(sample.ready_replicas for sample in samples)
    max_replicas = max(sample.replicas for sample in samples)
    revisions = [sample.revision for sample in samples if sample.revision is not None]
    revision_span = (min(revisions), max(revisions)) if revisions else (None, None)

    lines = [
        "# Deployment Rollout Timeline Summary",
        "",
        f"- Namespace: `{namespace}`",
        f"- Deployment: `{deployment}`",
        f"- Samples: `{len(samples)}`",
        f"- Initial replicas: `{first.replicas}`",
        f"- Final replicas: `{last.replicas}`",
        f"- Max replicas observed: `{max_replicas}`",
        f"- Max ready replicas observed: `{max_ready}`",
        f"- Revision range observed: `{revision_span[0]} -> {revision_span[1]}`",
        "",
        "| Event | Elapsed (s) | Status | Command |",
        "|---|---:|---|---|",
    ]

    if events:
        for event in events:
            status = "ok" if event.return_code == 0 else f"failed ({event.return_code})"
            lines.append(
                f"| `{event.name}` | {event.elapsed_seconds:.2f} | {status} | `{event.command}` |"
            )
            if event.stderr:
                lines.append(f"| `{event.name} stderr` |  |  | `{event.stderr}` |")
    else:
        lines.append("| `(no actions)` |  |  |  |")

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
        else course_root / "assets" / "generated" / "week-04-deploy-rollout"
    )
    output_dir.mkdir(parents=True, exist_ok=True)

    run_cmd(["kubectl", "version", "--client"], check=True)
    run_cmd(["kubectl", "-n", args.namespace, "get", "deployment", args.deployment], check=True)
    initial_dep = kubectl_json(["-n", args.namespace, "get", "deployment", args.deployment])
    initial_spec = initial_dep.get("spec", {})
    initial_replicas = int(initial_spec.get("replicas", 0) or 0) if isinstance(initial_spec, dict) else 0

    events: List[ActionEvent] = []
    samples: List[DeploymentSample] = []
    start_ts = time.monotonic()

    schedule: List[Dict[str, object]] = []
    if not args.skip_actions:
        t_scale = float(args.pre_seconds)
        t_restart = t_scale + float(args.after_scale_seconds)
        t_undo = t_restart + float(args.after_restart_seconds)
        schedule = [
            {
                "name": "scale",
                "time": t_scale,
                "cmd": [
                    "kubectl",
                    "-n",
                    args.namespace,
                    "scale",
                    "deployment",
                    args.deployment,
                    f"--replicas={args.scale_to}",
                ],
            },
            {
                "name": "rollout-restart",
                "time": t_restart,
                "cmd": [
                    "kubectl",
                    "-n",
                    args.namespace,
                    "rollout",
                    "restart",
                    f"deployment/{args.deployment}",
                ],
            },
            {
                "name": "rollout-undo",
                "time": t_undo,
                "cmd": [
                    "kubectl",
                    "-n",
                    args.namespace,
                    "rollout",
                    "undo",
                    f"deployment/{args.deployment}",
                ],
            },
        ]
        t_post = t_undo + float(args.after_undo_seconds) + float(args.post_seconds)
        end_time = t_post
        if not args.no_restore_scale:
            schedule.append(
                {
                    "name": "restore-scale",
                    "time": t_post,
                    "cmd": [
                        "kubectl",
                        "-n",
                        args.namespace,
                        "scale",
                        "deployment",
                        args.deployment,
                        f"--replicas={initial_replicas}",
                    ],
                }
            )
            end_time = t_post + float(args.after_restore_seconds)
    else:
        end_time = float(args.pre_seconds + args.post_seconds)

    next_sample = 0.0
    schedule_idx = 0

    while True:
        elapsed = time.monotonic() - start_ts
        if elapsed >= end_time:
            break

        while schedule_idx < len(schedule) and elapsed >= float(schedule[schedule_idx]["time"]):
            action = schedule[schedule_idx]
            event = run_action(
                action["cmd"],  # type: ignore[arg-type]
                str(action["name"]),
                start_ts,
            )
            events.append(event)
            schedule_idx += 1

        if elapsed >= next_sample:
            sample = sample_deployment(args.namespace, args.deployment)
            sample.elapsed_seconds = round(elapsed, 2)
            samples.append(sample)
            next_sample += args.sample_interval

        time.sleep(0.2)

    if not samples:
        raise RuntimeError("No samples captured; cannot produce timeline.")

    summary_path = write_summary_markdown(
        output_dir, args.namespace, args.deployment, samples, events
    )

    chart_paths: List[str] = []
    chart_error: Optional[str] = None
    if not args.no_charts:
        try:
            chart_paths = generate_charts(samples, events, output_dir)
        except RuntimeError as exc:
            chart_error = str(exc)

    payload = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "namespace": args.namespace,
        "deployment": args.deployment,
        "config": {
            "sample_interval": args.sample_interval,
            "pre_seconds": args.pre_seconds,
            "scale_to": args.scale_to,
            "after_scale_seconds": args.after_scale_seconds,
            "after_restart_seconds": args.after_restart_seconds,
            "after_undo_seconds": args.after_undo_seconds,
            "post_seconds": args.post_seconds,
            "after_restore_seconds": args.after_restore_seconds,
            "skip_actions": args.skip_actions,
            "no_restore_scale": args.no_restore_scale,
            "initial_replicas": initial_replicas,
        },
        "events": [asdict(event) for event in events],
        "samples": [asdict(sample) for sample in samples],
        "summary_markdown": str(summary_path),
        "charts": chart_paths,
    }
    if chart_error:
        payload["chart_error"] = chart_error

    json_path = output_dir / "results.json"
    json_path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    print(f"Rollout benchmark complete. Results written to: {output_dir}")
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
