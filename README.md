# README
## k8s-gitops-bootstrap

### 목표
  - WSL2 + k3d(또는 Docker Desktop + kind) + Helm을 이용해 30–40분 내 재현 가능한 로컬 Kubernetes 배포/관측/시크릿 부트스트랩
  - 이후 GitOps(EKS/GKE) 로 확장

---

### 주요 구성
- Cluster: WSL2 + k3d(K3s on Docker) · (대안) Docker Desktop + kind
- Packaging: Helm
- Observability: kube-prometheus-stack(Prometheus/Grafana/Alertmanager)
- Secrets: SealedSecrets(Git 시크릿 미포함)
- CI(샘플): GitHub Actions — 컨테이너 Build → Scan(Trivy) → SBOM
- (예정) GitOps: Argo CD(App of Apps) 로 infra/ · apps/ 분리 배포

