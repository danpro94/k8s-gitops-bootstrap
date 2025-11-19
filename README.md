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

## Day4: Observability & Alerting
- **Grafana** : Nodes/Pods 대시보드 improt -> 자원/헬스체크 모니터링
- **Alert** : 'PodCrashLooping' 룰 운영
    - Rule: `increase(kube_pod_container_status+total[5m]) > 3 for 2m`
    - 목적: 비정상 Pod 재시작 및 빠른 감지

## Day5-6: kind + Envoy Gateway + Gateway API Smoke Test

### 목표
- kind 클러스터 Ready 상태 (O)
- Envoy Gateway 및 Gateway API 리소스(GatewayClass/Gateway/HTTPRoute) 설치 (O)
- podinfo Helm 차트 배포(Service/podinfo) (O)
- HTTPRoute가 Gateway `eg`에 붙어 `podinfo` 로 라우팅 (O)
- 로컬에서 아래 명령이 200 OK 응답 확인 (O)
  ```bash
  curl -H "Host: podinfo.local" http://localhost:8888

### 개념 정리 Gateway API(k8s 표준)

**기존 Ingress(deprecated 예정) 와의 차이점**

Ingress 문제점

- 오래된 API, 컨트롤러마다 기능 제각각
- 유지보수 자원 부족, 과도한 유연성으로 보안 취약, Configuration Snippet 같은 위험 누적

**Gateway API**

- 다음 리소스로 L7 트래픽을 표준화해서 관리
    - Gateway Class - “인프라팀” 컨트롤러 선택 등 정의
    - Gateway - “인프라팀” 혹은 “플랫폼팀” 리스너, TLS 설정 등 관리
    - HTTPRoute - “개발팁” 자신의 서비스, HTTP Route만 작성
- “역할 분리”가 명확함

**Envoy Gateway: Envoy 기반 Gateway API 구현체 (컨트롤러+데이터플레인)**

_oci (Open Container Initiative): OCI 레지스트리는 전통적인 리포지토리 방식이 아닌, index.yaml 파일없이 컨테이너 이미지처럼 차트를 관리 → 컨테이너 기술 생태계에서 벤더-종속성 제거_
_ - oci 주소는 리포지토리가 아닌 개별 차트 자체를 가리키므로 helm install /pull을 oci 주소와 함께 직접 사용_


