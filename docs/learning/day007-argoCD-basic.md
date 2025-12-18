# Day 007: ArgoCD Basic with kind

---

about: 학습 기록

**날짜:** 2025-11-24  **소요시간: 3시간**

**난이도(2/5):** ⭐⭐

---

# 본 시점부터 k8s-gitops-bootstrap Milestone2로 진행
### 마일스톤 요약
1. GitOps 레이어 추가
  - [수동]helm upgrade / kubectl apply 작업 과정을 -> [자동]ArgoCD(App of Apps)로 전환
  - infra / 관측, Envoy Gateway 등 + apps/podinfo,demo-app)

2. 클라우드 첫 단계 - EKS 세션형 클러스터
  - 로컬 검증 Helm/Gateway 패턴 중 "핵심 서브셋"을 EKS로 Migration 후 올려보기
  - 수동 + 가벼운 CI 실습 진행

3. 운영 고도화 기반 마련
  - EKS / 로컬 모두에서 HPA, SLO 정의 (트래픽 가용 계획, 측정 시나리오 및 실행은 추후)

" 목표: ArgoCD 기초 -> GitOps 자동화 -> EKS 클라우드 배포 -> Observability 통합
" 결과: kind와 클라우드(EKS)에서 동일한 GitOps 워크플로우 구현

## 🎯 목표 (DoD)

- [X] 목표1: ArgoCD 로컬 환경 구축
- [X] 목표2: 앱 배포 및 UI에서 상태 확인 

## 📚 학습 내용

### 1 선언형 시스템과 Argo CD
- GitOps: 정의된 yaml을 Git에 올림
-> 이 때, Argo CD가 이 선언을 보고 맞춘다.

### 2 GitOps 개념과 중요성
: 시스템의 상태를 정의하는 유일한 기준이 Git Repository
-> 이는 수동으로 클러스터에서 설정을 바꿔도(실수로) Git에 정의된 내용과 다르므로
Argo CD는 이를, 틀린 상태(Drift)로 간주하고 Git의 상태로 되돌림(Self-Heel)

### 3 Argo CD의 이해 (GitOps의 엔진)
**핵심 컴포넌트 -- 동작 원리**
: ArgoCD는 여러 역할로 나뉜다.
- API Server / UI : 화면과 명령을 내리는 창구
- Repo Server: Git 저장소의 주기적인 변경사항 점검, YAML 문법이 맞는지 확인하고 해석함.
- Application Controller:
  - Reconciliation Loop(재조정 루프): Git 상태 <-> 실제 K8s 클러스터 상태를 비교
  - 다르면, OutOfSync 판정을 내리고, 동기화(Sync) 수행

### 4 App of Apps 패턴
: 애플리케이션을 관리하는 애플리케이션
- Root App 하나만 ArgoCD에 등록하면, 이 앱이 가리키는 폴더 안의 다른 앱 설정파일(Child App)을 찾아 자동 등록


## 🛠️ 실습 과정

### 1 ArgoCD 설치(공식 매니페스트)
1. Create a namespace
`kubectl create namespace argocd`

2. Apply install.yaml from ArgoCD official (raw URL)
`kubectl apply -n argocd \
-f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`
   - remarks: Currently Stable branch: 3.x (2025-11기준 Major=3.2.0)

### 2 ArgoCD UI 접속 (port-forward)
1. Argo CD 서버 포트포워딩 (8081)
`kubectl -n argocd port-forward svc/argocd-server 8081:443`
2. http://localhost:8081 접속
  - 초기 비밀번호 확인 및 접속: `argocd-inital-admin-secret 의 pw 필드`

### 3 Gitops Application 생성 (podinfo)
- helm update 및 podinfo 최신 버전 확인
`helm repo update`
`helm search repo podinfo`
- 네임스페이스 생성: gitops-demo
- `argocd/apps/podinfo-kind.yaml`
  - 차트 이름: podinfo
  - Heml 차트 저장소: yaml 파일 참조
  - 버전: 6.9.3 (2025-11 기준, 최신)
  - 현재 클러스터, gitops-deml 네임스페이스에 배포
  - ⭐syncPolicy:
    - automated: #Git과 실제 클러스터 상태가 달라지면 알아서 Sync/Prune

- 생성: `kubectl apply -f argocd/apps/podinfo-kind.yaml`
- 확인: `kubectl -n argocd get application`


## 💡 회고+배운 점

1. ArgoCD ...install.yaml 만으로 컨트롤러+UI 세트구성 간단
2. GitOps의 Application 리소스와 할 수 있는 것들
  - 어떤 chart, 어떤 revision, 어떤  ns에서 어떻게 관리할 지 정의 가능
  - 실제 배포는 Argo가 수행 - 엔지니어는 Git/YAML만 관리
3. 툴 설치 방식에 대한 이해
- Github raw URL / Helm repo
  - 대부분의 프로젝트 공식 Maintainer팀+Contributor들이 Git 레포지토리 안에 manifests 디렉터리를 만들고 관리.
  - 배포 편의(한 줄 설치)상 **URL을 공식 문서에 명시하는 패턴**이 사실상 관례
  - 도구 연동 Helm repo, Kustomize, Argo CD 등 k8s 생태계 도구들은 모두 Git/HTTP 받은후 적용 방식을 기본 지원.
(프로덕션 에서는...)
- 사내 Git repo로 Pork or Vendoring후 버전 고정
- helm chart도 버전을 명시적으로 고정(targetRevision)하고, 차트 자체를 사내 artifact repo에 미러링 경우 많음.

## 🐛 에러+디버깅

None

## 🔗 관련 문서

- [관련 ADR](007-why-Argocd-base-gitops.md)

## ✅ 완료 여부

- [X] 문서화 완료 (`docs/learning/day007-argoCD-basic.md`)
- [X]  PR 생성 & Merge
