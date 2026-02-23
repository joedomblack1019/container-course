#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/export-deck.sh <deck-id>

Deck IDs:
  - win95-showcase
  - week-01-overview  week-01-lab-01  week-01-lab-02  week-01-lab-03  week-01-lab-04
  - week-02-overview  week-02-lab-01  week-02-lab-02  week-02-lab-03
  - week-03-overview  week-03-lab-01  week-03-lab-02  week-03-lab-03
  - week-04-overview  week-04-lab-01  week-04-lab-02  week-04-lab-03
  - week-04-lab-04  week-04-lab-04b  week-04-lab-05  week-04-lab-06  week-04-lab-07  week-04-lab-08
  - week-04-rbac-authz  week-04-pod-security-admission
  - week-05-overview  week-05-lab-01  week-05-lab-02  week-05-lab-03  week-05-lab-04  week-05-lab-05
  - week-06-overview  week-06-lab-01  week-06-lab-02  week-06-lab-03  week-06-lab-04  week-06-lab-05  week-06-lab-06
  - week-07-overview  week-07-lab-01  week-07-lab-02  week-07-lab-03  week-07-lab-04  week-07-lab-05  week-07-lab-06  week-07-lab-07  week-07-lab-08
  - week-08-overview  week-08-lab-01  week-08-lab-02  week-08-lab-03  week-08-lab-04  week-08-lab-05  week-08-lab-06
  - week-08-gitops-loop
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

DECK_ID="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
COURSE_DIR="$(cd "${ROOT_DIR}/../.." && pwd)"
ASSETS_DIR="${COURSE_DIR}/assets/generated"
TMP_ROOT="${ROOT_DIR}/.tmp"
SLIDEV_BIN="${ROOT_DIR}/node_modules/.bin/slidev"

if [[ ! -x "${SLIDEV_BIN}" ]]; then
  echo "Missing Slidev CLI at ${SLIDEV_BIN}."
  echo "Run: cd ${ROOT_DIR} && npm install"
  exit 1
fi

slide_file=""
out_dir=""
title=""
hero_slide=1
content_slide=2
gif_slides=()
lab_readme_rel_path=""
hero_alt=""
gif_alt=""

case "${DECK_ID}" in
  week-01-overview)
    slide_file="${ROOT_DIR}/week-01-overview.md"
    out_dir="${ASSETS_DIR}/week-01-overview"
    title="Week 01 Containers Fundamentals Overview"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../assets/generated/week-01-overview"
    hero_alt="Week 01 Containers Fundamentals"
    gif_alt="Week 01 Lab Roadmap and Pipeline"
    ;;
  week-01-lab-01)
    slide_file="${ROOT_DIR}/week-01-lab-01.md"
    out_dir="${ASSETS_DIR}/week-01-lab-01"
    title="Week 01 Lab 01 Your First Container"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-01-lab-01"
    hero_alt="Lab 01 Your First Container"
    gif_alt="Lab 01 docker pull run exec logs"
    ;;
  week-01-lab-02)
    slide_file="${ROOT_DIR}/week-01-lab-02.md"
    out_dir="${ASSETS_DIR}/week-01-lab-02"
    title="Week 01 Lab 02 Build Your Python App"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-01-lab-02"
    hero_alt="Lab 02 Build Your Python App"
    gif_alt="Lab 02 docker build layers and run"
    ;;
  week-01-lab-03)
    slide_file="${ROOT_DIR}/week-01-lab-03.md"
    out_dir="${ASSETS_DIR}/week-01-lab-03"
    title="Week 01 Lab 03 Push to Container Registries"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-01-lab-03"
    hero_alt="Lab 03 Push to Registries"
    gif_alt="Lab 03 docker tag push to Docker Hub and GHCR"
    ;;
  week-01-lab-04)
    slide_file="${ROOT_DIR}/week-01-lab-04.md"
    out_dir="${ASSETS_DIR}/week-01-lab-04"
    title="Week 01 Lab 04 Container Lifecycle Investigation"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-01-lab-04"
    hero_alt="Lab 04 Container Lifecycle Investigation"
    gif_alt="Lab 04 lifecycle states and data persistence"
    ;;
  week-02-overview)
    slide_file="${ROOT_DIR}/week-02-overview.md"
    out_dir="${ASSETS_DIR}/week-02-overview"
    title="Week 02 Dockerfile Mastery Overview"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../assets/generated/week-02-overview"
    hero_alt="Week 02 Dockerfile Mastery"
    gif_alt="Week 02 optimization and security roadmap"
    ;;
  week-02-lab-01)
    slide_file="${ROOT_DIR}/week-02-lab-01.md"
    out_dir="${ASSETS_DIR}/week-02-lab-01"
    title="Week 02 Lab 01 Layer Optimization Challenge"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-02-lab-01"
    hero_alt="Lab 01 Layer Optimization Challenge"
    gif_alt="Lab 01 Docker layer cache optimization"
    ;;
  week-02-lab-02)
    slide_file="${ROOT_DIR}/week-02-lab-02.md"
    out_dir="${ASSETS_DIR}/week-02-lab-02"
    title="Week 02 Lab 02 Multi-Stage Build Migration"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-02-lab-02"
    hero_alt="Lab 02 Multi-Stage Build Migration"
    gif_alt="Lab 02 multi-stage build pipeline"
    ;;
  week-02-lab-03)
    slide_file="${ROOT_DIR}/week-02-lab-03.md"
    out_dir="${ASSETS_DIR}/week-02-lab-03"
    title="Week 02 Lab 03 Security Scanning with Trivy"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-02-lab-03"
    hero_alt="Lab 03 Security Scanning with Trivy"
    gif_alt="Lab 03 Trivy vulnerability scanning workflow"
    ;;
  week-03-overview)
    slide_file="${ROOT_DIR}/week-03-overview.md"
    out_dir="${ASSETS_DIR}/week-03-overview"
    title="Week 03 Compose and Local Development Overview"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../assets/generated/week-03-overview"
    hero_alt="Week 03 Compose and Local Development"
    gif_alt="Week 03 compose learning roadmap"
    ;;
  week-03-lab-01)
    slide_file="${ROOT_DIR}/week-03-lab-01.md"
    out_dir="${ASSETS_DIR}/week-03-lab-01"
    title="Week 03 Lab 01 WordPress and MySQL with Compose"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-03-lab-01"
    hero_alt="Lab 01 WordPress and MySQL with Compose"
    gif_alt="Lab 01 compose stack workflow"
    ;;
  week-03-lab-02)
    slide_file="${ROOT_DIR}/week-03-lab-02.md"
    out_dir="${ASSETS_DIR}/week-03-lab-02"
    title="Week 03 Lab 02 Network Debugging"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-03-lab-02"
    hero_alt="Lab 02 Network Debugging"
    gif_alt="Lab 02 network debugging workflow"
    ;;
  week-03-lab-03)
    slide_file="${ROOT_DIR}/week-03-lab-03.md"
    out_dir="${ASSETS_DIR}/week-03-lab-03"
    title="Week 03 Lab 03 Development Workflow with Bind Mounts"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-03-lab-03"
    hero_alt="Lab 03 Development Workflow with Bind Mounts"
    gif_alt="Lab 03 bind mount development workflow"
    ;;
  win95-showcase)
    slide_file="${ROOT_DIR}/win95-showcase.md"
    out_dir="${ASSETS_DIR}/win95-showcase"
    title="Win95 Component Showcase"
    gif_slides=(2 3 4 5 6 7 8)
    lab_readme_rel_path="../../../assets/generated/win95-showcase"
    hero_alt="Win95 Showcase Hero"
    gif_alt="Win95 Component Showcase"
    ;;
  week-04-overview)
    slide_file="${ROOT_DIR}/week-04-overview.md"
    out_dir="${ASSETS_DIR}/week-04-overview"
    title="Week 04 Kubernetes Architecture and First Deployment Overview"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../assets/generated/week-04-overview"
    hero_alt="Week 04 Kubernetes Architecture and First Deployment"
    gif_alt="Week 04 learning roadmap"
    ;;
  week-04-lab-01)
    slide_file="${ROOT_DIR}/week-04-lab-01.md"
    out_dir="${ASSETS_DIR}/week-04-lab-01"
    title="Week 04 Lab 01 Create Your kind Cluster and Explore"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-04-lab-01"
    hero_alt="Lab 01 Create Your kind Cluster and Explore"
    gif_alt="Lab 01 kind cluster bootstrap and exploration"
    ;;
  week-04-lab-02)
    slide_file="${ROOT_DIR}/week-04-lab-02.md"
    out_dir="${ASSETS_DIR}/week-04-lab-02"
    title="Week 04 Lab 02 Deploy Scale Update Debug"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-04-lab-02"
    hero_alt="Lab 02 Deploy Scale Update Debug"
    gif_alt="Lab 02 deployment lifecycle workflow"
    ;;
  week-04-lab-03)
    slide_file="${ROOT_DIR}/week-04-lab-03.md"
    out_dir="${ASSETS_DIR}/week-04-lab-03"
    title="Week 04 Lab 03 Deploy to Dev via GitOps"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-04-lab-03"
    hero_alt="Lab 03 Deploy to Dev via GitOps"
    gif_alt="Lab 03 GitOps submission workflow"
    ;;
  week-04-lab-04)
    slide_file="${ROOT_DIR}/week-04-lab-04.md"
    out_dir="${ASSETS_DIR}/week-04-lab-04"
    title="Week 04 Lab 04 kubeadm Bootstrap Foundations"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-04-lab-04"
    hero_alt="Lab 04 kubeadm Bootstrap Foundations"
    gif_alt="Lab 04 kubeadm init and node join workflow"
    ;;
  week-04-lab-04b)
    slide_file="${ROOT_DIR}/week-04-lab-04b.md"
    out_dir="${ASSETS_DIR}/week-04-lab-04b"
    title="Week 04 Lab 04b kubeadm Full Lifecycle on VirtualBox"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-04-lab-04b"
    hero_alt="Lab 04b kubeadm Full Lifecycle on VirtualBox"
    gif_alt="Lab 04b VirtualBox cluster workflow"
    ;;
  week-04-lab-05)
    slide_file="${ROOT_DIR}/week-04-lab-05.md"
    out_dir="${ASSETS_DIR}/week-04-lab-05"
    title="Week 04 Lab 05 RBAC Authorization Deep Dive"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-04-lab-05"
    hero_alt="Lab 05 RBAC Authorization Deep Dive"
    gif_alt="Lab 05 RBAC roles and bindings workflow"
    ;;
  week-04-lab-06)
    slide_file="${ROOT_DIR}/week-04-lab-06.md"
    out_dir="${ASSETS_DIR}/week-04-lab-06"
    title="Week 04 Lab 06 Pod Security Admission Deep Dive"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-04-lab-06"
    hero_alt="Lab 06 Pod Security Admission Deep Dive"
    gif_alt="Lab 06 Pod Security Admission enforcement workflow"
    ;;
  week-04-lab-07)
    slide_file="${ROOT_DIR}/week-04-lab-07.md"
    out_dir="${ASSETS_DIR}/week-04-lab-07"
    title="Week 04 Lab 07 Extension Interfaces Deep Dive"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-04-lab-07"
    hero_alt="Lab 07 Extension Interfaces Deep Dive"
    gif_alt="Lab 07 CRI CNI CSI discovery workflow"
    ;;
  week-05-overview)
    slide_file="${ROOT_DIR}/week-05-overview.md"
    out_dir="${ASSETS_DIR}/week-05-overview"
    title="Week 05 Configuration Secrets and State Overview"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../assets/generated/week-05-overview"
    hero_alt="Week 05 Configuration Secrets and State"
    gif_alt="Week 05 learning roadmap"
    ;;
  week-05-lab-01)
    slide_file="${ROOT_DIR}/week-05-lab-01.md"
    out_dir="${ASSETS_DIR}/week-05-lab-01"
    title="Week 05 Lab 01 Helm for Vault Manifests for Redis"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-05-lab-01"
    hero_alt="Lab 01 Helm for Vault Manifests for Redis"
    gif_alt="Lab 01 Helm install and Redis manifest workflow"
    ;;
  week-05-lab-02)
    slide_file="${ROOT_DIR}/week-05-lab-02.md"
    out_dir="${ASSETS_DIR}/week-05-lab-02"
    title="Week 05 Lab 02 Wire Your App to Redis"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-05-lab-02"
    hero_alt="Lab 02 Wire Your App to Redis"
    gif_alt="Lab 02 ConfigMap and wiring workflow"
    ;;
  week-05-lab-03)
    slide_file="${ROOT_DIR}/week-05-lab-03.md"
    out_dir="${ASSETS_DIR}/week-05-lab-03"
    title="Week 05 Lab 03 Ship Redis to Production"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-05-lab-03"
    hero_alt="Lab 03 Ship Redis to Production"
    gif_alt="Lab 03 production Redis deployment workflow"
    ;;
  week-05-lab-04)
    slide_file="${ROOT_DIR}/week-05-lab-04.md"
    out_dir="${ASSETS_DIR}/week-05-lab-04"
    title="Week 05 Lab 04 etcd Snapshot and Restore Drill"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-05-lab-04"
    hero_alt="Lab 04 etcd Snapshot and Restore Drill"
    gif_alt="Lab 04 etcd backup and restore workflow"
    ;;
  week-05-lab-05)
    slide_file="${ROOT_DIR}/week-05-lab-05.md"
    out_dir="${ASSETS_DIR}/week-05-lab-05"
    title="Week 05 Lab 05 StorageClass Reclaim Policy and Access Modes"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-05-lab-05"
    hero_alt="Lab 05 StorageClass Reclaim Policy and Access Modes"
    gif_alt="Lab 05 storage class and PVC workflow"
    ;;
  week-06-overview)
    slide_file="${ROOT_DIR}/week-06-overview.md"
    out_dir="${ASSETS_DIR}/week-06-overview"
    title="Week 06 Networking and Security Overview"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../assets/generated/week-06-overview"
    hero_alt="Week 06 Networking and Security"
    gif_alt="Week 06 learning roadmap"
    ;;
  week-06-lab-01)
    slide_file="${ROOT_DIR}/week-06-lab-01.md"
    out_dir="${ASSETS_DIR}/week-06-lab-01"
    title="Week 06 Lab 01 Ingress in kind"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-06-lab-01"
    hero_alt="Lab 01 Ingress in kind"
    gif_alt="Lab 01 Ingress controller and routing workflow"
    ;;
  week-06-lab-02)
    slide_file="${ROOT_DIR}/week-06-lab-02.md"
    out_dir="${ASSETS_DIR}/week-06-lab-02"
    title="Week 06 Lab 02 Gateway API on the Shared Cluster"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-06-lab-02"
    hero_alt="Lab 02 Gateway API on the Shared Cluster"
    gif_alt="Lab 02 Gateway API routing workflow"
    ;;
  week-06-lab-03)
    slide_file="${ROOT_DIR}/week-06-lab-03.md"
    out_dir="${ASSETS_DIR}/week-06-lab-03"
    title="Week 06 Lab 03 NetworkPolicies Break It Fix It Lock It Down"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-06-lab-03"
    hero_alt="Lab 03 NetworkPolicies Break It Fix It Lock It Down"
    gif_alt="Lab 03 NetworkPolicy enforcement workflow"
    ;;
  week-06-lab-04)
    slide_file="${ROOT_DIR}/week-06-lab-04.md"
    out_dir="${ASSETS_DIR}/week-06-lab-04"
    title="Week 06 Lab 04 Service Types and Endpoint Debugging"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-06-lab-04"
    hero_alt="Lab 04 Service Types and Endpoint Debugging"
    gif_alt="Lab 04 NodePort LoadBalancer and endpoint workflow"
    ;;
  week-06-lab-05)
    slide_file="${ROOT_DIR}/week-06-lab-05.md"
    out_dir="${ASSETS_DIR}/week-06-lab-05"
    title="Week 06 Lab 05 CoreDNS Troubleshooting Sprint"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-06-lab-05"
    hero_alt="Lab 05 CoreDNS Troubleshooting Sprint"
    gif_alt="Lab 05 CoreDNS diagnosis workflow"
    ;;
  week-06-lab-06)
    slide_file="${ROOT_DIR}/week-06-lab-06.md"
    out_dir="${ASSETS_DIR}/week-06-lab-06"
    title="Week 06 Lab 06 CNI Plugin Comparison"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-06-lab-06"
    hero_alt="Lab 06 CNI Plugin Comparison"
    gif_alt="Lab 06 kindnet Calico Cilium comparison workflow"
    ;;
  week-07-overview)
    slide_file="${ROOT_DIR}/week-07-overview.md"
    out_dir="${ASSETS_DIR}/week-07-overview"
    title="Week 07 Production Kustomize and Metrics Exporting Overview"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../assets/generated/week-07-overview"
    hero_alt="Week 07 Production Kustomize and Metrics Exporting"
    gif_alt="Week 07 learning roadmap"
    ;;
  week-07-lab-01)
    slide_file="${ROOT_DIR}/week-07-lab-01.md"
    out_dir="${ASSETS_DIR}/week-07-lab-01"
    title="Week 07 Lab 01 Production Kustomize"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-07-lab-01"
    hero_alt="Lab 01 Production Kustomize"
    gif_alt="Lab 01 Kustomize overlay workflow"
    ;;
  week-07-lab-02)
    slide_file="${ROOT_DIR}/week-07-lab-02.md"
    out_dir="${ASSETS_DIR}/week-07-lab-02"
    title="Week 07 Lab 02 Build a Redis Metrics Exporter"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-07-lab-02"
    hero_alt="Lab 02 Build a Redis Metrics Exporter"
    gif_alt="Lab 02 metrics exporter build workflow"
    ;;
  week-07-lab-03)
    slide_file="${ROOT_DIR}/week-07-lab-03.md"
    out_dir="${ASSETS_DIR}/week-07-lab-03"
    title="Week 07 Lab 03 Scrape With Prometheus"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-07-lab-03"
    hero_alt="Lab 03 Scrape With Prometheus"
    gif_alt="Lab 03 Prometheus scrape and query workflow"
    ;;
  week-07-lab-04)
    slide_file="${ROOT_DIR}/week-07-lab-04.md"
    out_dir="${ASSETS_DIR}/week-07-lab-04"
    title="Week 07 Lab 04 Node Lifecycle and Upgrade Planning"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-07-lab-04"
    hero_alt="Lab 04 Node Lifecycle and Upgrade Planning"
    gif_alt="Lab 04 drain cordon upgrade workflow"
    ;;
  week-07-lab-05)
    slide_file="${ROOT_DIR}/week-07-lab-05.md"
    out_dir="${ASSETS_DIR}/week-07-lab-05"
    title="Week 07 Lab 05 Horizontal Pod Autoscaler"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-07-lab-05"
    hero_alt="Lab 05 Horizontal Pod Autoscaler"
    gif_alt="Lab 05 HPA scale-out workflow"
    ;;
  week-07-lab-06)
    slide_file="${ROOT_DIR}/week-07-lab-06.md"
    out_dir="${ASSETS_DIR}/week-07-lab-06"
    title="Week 07 Lab 06 Scheduling Constraints Deep Dive"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-07-lab-06"
    hero_alt="Lab 06 Scheduling Constraints Deep Dive"
    gif_alt="Lab 06 affinity taint toleration workflow"
    ;;
  week-07-lab-07)
    slide_file="${ROOT_DIR}/week-07-lab-07.md"
    out_dir="${ASSETS_DIR}/week-07-lab-07"
    title="Week 07 Lab 07 Resource Observation with kubectl top"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-07-lab-07"
    hero_alt="Lab 07 Resource Observation with kubectl top"
    gif_alt="Lab 07 kubectl top and resource triage workflow"
    ;;
  week-08-overview)
    slide_file="${ROOT_DIR}/week-08-overview.md"
    out_dir="${ASSETS_DIR}/week-08-overview"
    title="Week 08 GitOps with ArgoCD and DevSecOps Pipeline Overview"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../assets/generated/week-08-overview"
    hero_alt="Week 08 GitOps with ArgoCD and DevSecOps Pipeline"
    gif_alt="Week 08 learning roadmap"
    ;;
  week-08-lab-01)
    slide_file="${ROOT_DIR}/week-08-lab-01.md"
    out_dir="${ASSETS_DIR}/week-08-lab-01"
    title="Week 08 Lab 01 Install ArgoCD on kind with Helm"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-08-lab-01"
    hero_alt="Lab 01 Install ArgoCD on kind with Helm"
    gif_alt="Lab 01 ArgoCD install and UI workflow"
    ;;
  week-08-lab-02)
    slide_file="${ROOT_DIR}/week-08-lab-02.md"
    out_dir="${ASSETS_DIR}/week-08-lab-02"
    title="Week 08 Lab 02 CI CD Pipeline Deep Dive"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-08-lab-02"
    hero_alt="Lab 02 CI CD Pipeline Deep Dive"
    gif_alt="Lab 02 pipeline tools workflow"
    ;;
  week-08-lab-03)
    slide_file="${ROOT_DIR}/week-08-lab-03.md"
    out_dir="${ASSETS_DIR}/week-08-lab-03"
    title="Week 08 Lab 03 The GitOps Loop and Revert"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-08-lab-03"
    hero_alt="Lab 03 The GitOps Loop and Revert"
    gif_alt="Lab 03 GitOps reconcile and revert workflow"
    ;;
  week-08-lab-04)
    slide_file="${ROOT_DIR}/week-08-lab-04.md"
    out_dir="${ASSETS_DIR}/week-08-lab-04"
    title="Week 08 Lab 04 Vault Integration Bonus"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-08-lab-04"
    hero_alt="Lab 04 Vault Integration Bonus"
    gif_alt="Lab 04 Vault secret injection workflow"
    ;;
  week-08-lab-05)
    slide_file="${ROOT_DIR}/week-08-lab-05.md"
    out_dir="${ASSETS_DIR}/week-08-lab-05"
    title="Week 08 Lab 05 Troubleshooting Playbook Sprint"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-08-lab-05"
    hero_alt="Lab 05 Troubleshooting Playbook Sprint"
    gif_alt="Lab 05 cluster component troubleshooting workflow"
    ;;
  week-08-lab-06)
    slide_file="${ROOT_DIR}/week-08-lab-06.md"
    out_dir="${ASSETS_DIR}/week-08-lab-06"
    title="Week 08 Lab 06 HA Control Plane Design and Simulation"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-08-lab-06"
    hero_alt="Lab 06 HA Control Plane Design and Simulation"
    gif_alt="Lab 06 HA control plane design workflow"
    ;;
  week-04-rbac-authz)
    slide_file="${ROOT_DIR}/week-04-rbac-authz.md"
    out_dir="${ASSETS_DIR}/week-04-rbac-authz"
    title="Week 04 Lab 05 RBAC Authorization Deep Dive"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-04-rbac-authz"
    hero_alt="RBAC Authorization Hero"
    gif_alt="RBAC Authorization Decision Flow"
    ;;
  week-04-pod-security-admission)
    slide_file="${ROOT_DIR}/week-04-pod-security-admission.md"
    out_dir="${ASSETS_DIR}/week-04-pod-security-admission"
    title="Week 04 Lab 06 Pod Security Admission Deep Dive"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-04-pod-security-admission"
    hero_alt="Pod Security Admission Hero"
    gif_alt="Pod Security Admission Flow"
    ;;
  week-04-lab-08)
    slide_file="${ROOT_DIR}/week-04-lab-08.md"
    out_dir="${ASSETS_DIR}/week-04-lab-08"
    title="Week 04 Lab 08 Jobs and CronJobs"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-04-lab-08"
    hero_alt="Lab 08 Jobs and CronJobs"
    gif_alt="Lab 08 batch workloads and scheduling"
    ;;
  week-07-lab-08)
    slide_file="${ROOT_DIR}/week-07-lab-08.md"
    out_dir="${ASSETS_DIR}/week-07-lab-08"
    title="Week 07 Lab 08 VPA Right-Sizing Resource Requests"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-07-lab-08"
    hero_alt="Lab 08 VPA Right-Sizing"
    gif_alt="Lab 08 VPA recommendation and apply workflow"
    ;;
  week-08-gitops-loop)
    slide_file="${ROOT_DIR}/week-08-gitops-loop.md"
    out_dir="${ASSETS_DIR}/week-08-gitops-loop"
    title="Week 08 Lab 03 GitOps Loop and Revert"
    gif_slides=(3 4 5 6)
    lab_readme_rel_path="../../../assets/generated/week-08-gitops-loop"
    hero_alt="GitOps Loop Hero"
    gif_alt="GitOps Reconcile Flow"
    ;;
  *)
    echo "Unknown deck id: ${DECK_ID}"
    usage
    exit 1
    ;;
esac

if [[ ! -f "${slide_file}" ]]; then
  echo "Slide file not found: ${slide_file}"
  exit 1
fi

tmp_dir="${TMP_ROOT}/${DECK_ID}"
rm -rf "${tmp_dir}"
mkdir -p "${tmp_dir}" "${out_dir}/slides"

echo "Exporting PNG slides for ${DECK_ID}..."
"${SLIDEV_BIN}" export "${slide_file}" --format png --output "${tmp_dir}"

mapfile -t rendered < <(find "${tmp_dir}" -type f -name '*.png' | sort -V)
if [[ ${#rendered[@]} -eq 0 ]]; then
  echo "No PNG slides found under ${tmp_dir}"
  exit 1
fi

for idx in "${!rendered[@]}"; do
  n=$((idx + 1))
  cp "${rendered[$idx]}" "${out_dir}/slides/slide-$(printf '%02d' "${n}").png"
done

pick_slide() {
  local one_based="$1"
  local zero_based=$((one_based - 1))
  if (( zero_based < 0 || zero_based >= ${#rendered[@]} )); then
    echo "Slide index ${one_based} out of range (available: ${#rendered[@]})" >&2
    exit 1
  fi
  echo "${rendered[$zero_based]}"
}

cp "$(pick_slide "${hero_slide}")" "${out_dir}/hero.png"
cp "$(pick_slide "${content_slide}")" "${out_dir}/content.png"

frames=()
for s in "${gif_slides[@]}"; do
  zero_based=$((s - 1))
  if (( zero_based >= 0 && zero_based < ${#rendered[@]} )); then
    frames+=("${rendered[$zero_based]}")
  fi
done

if [[ ${#frames[@]} -eq 0 ]]; then
  start_index=1
  if (( ${#rendered[@]} > 1 )); then
    start_index=2
  fi
  end_index=$(( start_index + 3 ))
  if (( end_index > ${#rendered[@]} )); then
    end_index=${#rendered[@]}
  fi
  for ((i=start_index; i<=end_index; i++)); do
    frames+=("$(pick_slide "${i}")")
  done
fi

make_gif() {
  local target="$1"
  shift
  local -a frame_args=("$@")

  if command -v magick >/dev/null 2>&1; then
    magick -delay 220 "${frame_args[@]}" -loop 0 "${target}"
    return
  fi

  if command -v convert >/dev/null 2>&1; then
    convert -delay 220 "${frame_args[@]}" -loop 0 "${target}"
    return
  fi

  if command -v ffmpeg >/dev/null 2>&1; then
    local ff_list
    ff_list="$(mktemp)"
    trap 'rm -f "${ff_list}"' RETURN
    for frame in "${frame_args[@]}"; do
      printf "file '%s'\n" "${frame}" >> "${ff_list}"
      printf "duration 2.2\n" >> "${ff_list}"
    done
    ffmpeg -y -f concat -safe 0 -i "${ff_list}" -vf "fps=10,scale=1280:-1:flags=lanczos" "${target}" >/dev/null 2>&1
    rm -f "${ff_list}"
    trap - RETURN
    return
  fi

  echo "No GIF backend found. Install ImageMagick or ffmpeg."
  exit 1
}

make_gif "${out_dir}/flow.gif" "${frames[@]}"

cat > "${out_dir}/summary.md" <<EOF
# ${title}

- Deck ID: \`${DECK_ID}\`
- Source deck: \`${slide_file#${COURSE_DIR}/}\`
- Generated slides: ${#rendered[@]}
- Generated assets:
  - \`hero.png\`
  - \`content.png\`
  - \`flow.gif\`
EOF

cat > "${out_dir}/embed-snippet.md" <<EOF
![${hero_alt}](${lab_readme_rel_path}/hero.png)
![${gif_alt}](${lab_readme_rel_path}/flow.gif)
EOF

echo "Generated assets in ${out_dir}"
