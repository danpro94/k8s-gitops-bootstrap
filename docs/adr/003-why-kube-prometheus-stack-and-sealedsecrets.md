# ADR-003: 로컬 k3d 관측 스택 kube-prometheus-stack & 시크릿 관리 SealedSecrets

**날짜:** 2025-11-13

**상태:** ✅ Accepted

---

## Context (배경)

**문제:**

- **클러스터 내부에서 무슨 작업이 진행되는지** 확인 불가
- k3d/kind/EKS에 다양한 마이크로서비스를 올릴 경우 다음 옵저버빌리티 체계 필요
    - 노드/파드/컨테이너 상태
    - 리소스 사용량
    - 에러율, 응답시간

- Secret을 안전하게 버전 관리할 장치 없음 

**현재 상황:**

- 로컬 학습+실습용 k3d 클러스터 사용
- 이후 EKS, GKE 등 (멀티) 클라우드 이전 계획
- 옵저버빌리티 도구, 시크릿 관리 도구 옵션이 다수 존재함
    ex)oby: Prometeus / Grafana 개별 설치, SaaS:Datadog, NewRelic 등, 시크릿: .env, SOPS, 외부서비스
---

## Decision (결정)

**선택한 방법:**

- kube-prometheus-stack Helm Chart로 옵저버빌리티 스택 구축
    - namespace: observability
    - Grafana Service type: `NortPort` -> 로컬: `port-forward` `localhost:3000`

- Bitnami의 SealedSecrets를 이용한 Git 암호화 상태 저장
    - namespaece: kube-system (SealedSecrets Controller)


**이유:**

1. 세트로 제공되는 운영 대시보드 기본을 빠르게 학습 및 실습
2. GitOps 친화적
3. 이후 EKS/GKE에서도 동일하게 재사용 가능(클라우드 확장성)

---
    

## Alternatives Considered (대안 검토)

### 대안 1: Prometheus+Grafana 개별 설치

**장점:**

- 세밀한 리소스 조정 및 내부 동작 깊이있게 이해할 수 있음

**단점:**

- 초기 셋업이 길어지며 구성, 관리 복잡도 증가

### 대안 2: 매니지드/SaaS 이용 (Datadog, Grafana Cloud)

**장점:**

- 운영 편의성

**단점:**

- 과금 및 학습 단계에서 비효율적

### 대안 3: k8s Secret+.gitignore로 관리

**장점:**
- 도입이 가장 쉬움

**단점:**
- GitOps 관점과 어긋나는 원칙
(지난 GKE 실습 프로젝트에서 Secret 노출로 인한 Project 및 Repository Terminated 경험)

---

## Consequences (결과)

**긍정적 영향:**

- 운영/시스템 모니터링 감각 향상(지표 기반 시스템 관측)
- 보안 중요성 내제화
- 클라우드 확장 가능한 패턴

**부정적 영향/트레이드오프:**

- SealedSecrets의 **클러스터별 키쌍 분리**에 따라, 클러스터 생성 시 공개키 다시 발급 받아야하는 관리 필요


**향후 고려사항:**

- k-p-s values 튜닝 
- 클라우드 환경에서 다른 보안 패턴 검토

---

## References

- https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack
- https://prometheus-operator.dev/docs/getting-started/introduction/
- https://github.com/bitnami-labs/sealed-secrets
