# VHS Demo Recordings for Container Course
#
# Usage:
#   make all              Record all demos (sequentially)
#   make week-01-build    Record a specific demo
#   make week-01-first    Record week 1 lab 1 demo
#   make week-02-layer    Record week 2 lab 1 demo
#   make clean            Remove generated GIFs
#
# Prerequisites:
#   - Docker installed and running
#   - VHS installed (go install github.com/charmbracelet/vhs@latest)
#   - trivy installed (for week-02-trivy)
#   - kind cluster named "lab" running (for week-04-k8s):
#       kind create cluster --name lab
#
# Timing:
#   Sleep values in the .tape files are estimates. If a demo looks wrong
#   (commands typed over running output, or long dead pauses), adjust the
#   Sleep values in the corresponding .tape file for your machine.

GENERATED := ../../assets/generated

.PHONY: all clean \
        week-01-first week-01-build week-01-registries week-01-lifecycle \
        week-02-layer week-02-multistage week-02-trivy \
        week-03-compose week-04-k8s week-04-kubeadm

all: week-01-first week-01-build week-01-registries week-01-lifecycle week-02-layer week-02-multistage week-02-trivy week-03-compose week-04-k8s week-04-kubeadm

week-01-first:
	@mkdir -p $(GENERATED)/week-01-lab-01
	vhs week-01-lab-01-first-container.tape

week-01-build:
	@mkdir -p $(GENERATED)/week-01-lab-02
	vhs week-01-lab-02-docker-build.tape

week-01-registries:
	@mkdir -p $(GENERATED)/week-01-lab-03
	vhs week-01-lab-03-registries.tape

week-01-lifecycle:
	@mkdir -p $(GENERATED)/week-01-lab-04
	vhs week-01-lab-04-lifecycle-demo.tape

week-02-layer:
	@mkdir -p $(GENERATED)/week-02-lab-01
	vhs week-02-lab-01-layer-cache.tape

week-02-multistage:
	@mkdir -p $(GENERATED)/week-02-lab-02
	vhs week-02-lab-02-multistage.tape

week-02-trivy:
	@mkdir -p $(GENERATED)/week-02-lab-03
	vhs week-02-lab-03-trivy-scan.tape

week-03-compose:
	@mkdir -p $(GENERATED)/week-03-lab-01
	vhs week-03-lab-01-compose-up.tape

week-04-k8s:
	@mkdir -p $(GENERATED)/week-04-lab-02
	vhs week-04-lab-02-k8s-deploy.tape

week-04-kubeadm:
	@mkdir -p $(GENERATED)/week-04-lab-04
	vhs week-04-lab-04-kubeadm-bootstrap.tape

clean:
	rm -f $(GENERATED)/week-0*/demo.gif
