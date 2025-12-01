# ADR-002: Dev Container 기반 로컬 개발환경+GHCR CI Pipeline 결정

**날짜:** 2025-11-12

**상태:** ✅ Accepted

---

## Context (배경)

**문제:**

기존 온프레미스/Windows/Azure 위주의 경험은 있으나, **컨테이너-k8s-CI 파이프라인의 직접적 경험 부족**.
__앞으로의 k8s-gitops-bootstrap__
- 로컬에서 k3d/kind 클러스터
- GitOps(ArgoCD)까지 연결
=> 쉽고 빠르게 재현 가능한 개발환경+기본 보안 포함된 CI라인 필
수

**현재 상황:**
DevOps bootstrap 과정에서 k3d, Helm, GitHub Actions, GHCR, Trivy, SBOM 등 지속적인 활용이 필요하므로 "템플릿 필요"

-> 현대의 개발 환경에서는 MSA가 일반화되어 그에 걸맞는 DevOps 관점에서의 빠르고 효율적이면서 동시에 최소한의
안전을 보장하는 표준적인 개발환경 구축을 진행해야하며 자동화 해야함. 

---

## Decision (결정)

**선택한 방법:**

VS Code Dev Container + WSL2 + k3d + GHCR 기반 CI 파이프라인

- 개발환경 표준화
    - .devcontainer/devcontainer.json 으로 Ubuntu Dev Container 정의
    - setup.sh 로 kubectl/helm/k3d 자동 설치
    - Docker 소켓(/var/run/docker.sock) 바인딩으로 Docker outside of Docker(DooD) 사용

- 레포지토리 정책
    - 깃 Actions - Workflows permission: `Read and write` 부여
    - main 브랜치 보호 규칙 적용 (-f push 금지, PR 리뷰(but owner bypass))\

- CI 파이프라인
`.gihub/workflows/ci.yaml`
    - 코드 checkout
    - 컨테이너 이미지 빌드 -> GHCR 푸시
    - Trivy 이미지 스캔 (but `exit-code=0`: 학습 단계 실패 처리 안함)
    - Syft 기반 SBOM 생성 -> Github Artifacts 업로드
    

**이유:**

1. EaC : DevContainer+setup.sh로 빠르게 동일한 개발 환경 재현 가능
2. 로컬-클라우드 패턴 일치: "툴 체인"은 그대로, 대상 클러스터만 변경하면 되는 EKS/GKE 실습환경
3. 보안 CI 적용: GHCR, Trivy, SBOM으로 이미지 빌드를 보안스캔+메타데이터 생성 패턴을 익힘.
4. GitHub 네이티브 워크플로: 관리가 직관적


---

## Alternatives Considered (대안 검토)

### 대안 1: Dev Container 없이 WSL2 로컬 환경 직접 설치
**장점:**
- 조금 더 가볍고 빠름

**단점:**
- 추후 패키지 달라짐
- 별도 문서를 확인하면서 준비해야함

### 대안 2: VM 기반 개발 환경 (VMWare + Ubuntu) + 호스트 VS Code
**장점:**
- 격리성 강함

**단점:**
-무겁고 느림
-컴퓨팅 환경을 바꾸며(Desktop,Laptop) 학습 시 각 환경에 VM 따로 관리해야함

---

## Consequences (결과)

**긍정적 영향:**

- 빠른 환경 구성
- 보안 내재화 CI 경험 실습

**부정적 영향/트레이드오프:**

- CI Github Actions+GHCR로 묶여있어 다른 CI 옮길때 마이그레이션 필요


**향후 고려사항:**

- 취약점 강화 추가 작업 필요

---

## References

- DevContainers 공식 문서: https://containers.dev/
- DevContainer Features: https://containers.dev/features
- Helm: https://helm.sh/docs/
- WSL2: https://learn.microsoft.com/ko-kr/windows/wsl/
- k3d: https://k3d.io/stable/
- Trivy Action: (GitHub Marketplace 링크 등)
- Syft/SBOM: Anchore 문서


