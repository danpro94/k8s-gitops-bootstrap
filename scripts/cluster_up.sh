#!/usr/bin/env bash
set -euo pipfail
k3d cluster create dev --agetns 2 --port "8080:80@loadbalancer"
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update
kubectl create ns demo || true
kelm upgrade --install podinfo podinfo/podinfo -n demo -f k8s/values-podinfo.yaml
