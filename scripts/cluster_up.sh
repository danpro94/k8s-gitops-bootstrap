#!/usr/bin/env bash
set -euo pipefail
k3d cluster create dev --agents 2 --port "8080:80@loadbalancer"
helm repo add podinfo https://stefanprodan.github.io/podinfo || true
helm repo update
kubectl create ns demo || true
kelm upgrade --install podinfo podinfo/podinfo -n demo -f k8s/values-podinfo.yaml
