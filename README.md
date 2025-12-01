# README
## k8s-gitops-bootstrap

![ci](https://github.com/<OWNER>/<REPO>/actions/workflows/ci.yaml/badge.svg)
[![License](https://img.shields.io/badge/license-Unlicense-blue.svg)](LICENSE)

> **WSL2 + k3d + Helm 기반 로컬 Kubernetes 부트스트랩, 30분 내 재현 가능**
> GitOps(Argo CD) + Observability(Prometheus/Grafana) + Secrets(SealedSecrets) 통합 실습 환경

## 🎯 What is this?
이 프로젝트는 **로컬 → 클라우드(EKS/GKE) GitOps 워크플로우**를 학습하고 실전 배포하기 위한 부트스트랩 환경입니다.

**핵심 기능:**
- ⚡ **30분 내 로컬 K8s 클러스터 구축** (WSL2 + k3d)
- 📊 **관측성 스택** (kube-prometheus-stack: Prometheus/Grafana/Alertmanager)
- 🔐 **안전한 시크릿 관리** (SealedSecrets)
- 🚀 **GitOps 자동화** (Argo CD App of Apps)

---

## 🚀 Quick Start (5분)

### 1. k3d 클러스터 생성
```bash
k3d cluster create lab --agents 2

### 2. Helm으로 관측성 스택 설치
```bash
helm install kps prometheus-community/kube-prometheus-stack -n observability --create-namespace

### 3. Grafana 접속
```bash
kubectl port-forward -n observability svc/kps-grafana 3000:80
# 브라우저 접속: http://localhost:3000 (ID: admin / PW: prom-operator)


