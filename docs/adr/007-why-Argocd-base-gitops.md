# ADR-XXX: [결정 제목]

**날짜:** 2025-11-24

**상태:** ✅ Accepted

---

## Context (배경)

**문제:**

- k8s 생태계의 선언적 운영+배포 자동화에 대한 경험이 없으며, 실무 운영 패턴을 체득해야함
- 명령을 통한 전통적인 수동 적용 및 운영(kubectl)은 재현성/Drift 통제가 어렵고, 팀단위 운영 방식과 괴리가 큼.

**현재 상황:**

- 실제 운영에서 중요한 개념인 Drift 감지, Self Heel, Reconciliation loop가 시각화된 환경 필요
- 이후 실무나 프로덕션 환경에서 Git 미러링, 버전 fix 등을 자연스럽게 다룰 필요 있음

---

## Decision (결정)

**선택한 방법:**

1. kind 클러스터에 ArgoCD를 공식 매니페스트로 설치
2. Argo CD UI 접근 port-forward로 단순화
3. podinfo Helm chart사용(버전 고정)
4. syncPolicy.automated 활성화 및 Gitops 핵심 루프(Sync/Prune/Self-heal) 실습 

**이유:**

1. 표준성: 공식 install.yaml은 표준적인 설치 로경
2. Gitops 루프 들여다보기: UI에서 Sync/Health, 리소스 트리를 즉시 확인    

---
    

## Alternatives Considered (대안 검토)

### 대안 1:Flux CD로 GitOps 구성

**장점:**

- GitOps에 정통한 경량 구성
- UI 의존도 낮음, Git 중심 운영

**단점:**

- UI기반 시각적 피드백 약함


---

## Consequences (결과)

**긍정적 영향:**

- ArgoCD가 클러스터 상태를 지속 재조정(Reconciliation) 하는 운영 모델 실습
- App of Apps 패턴으로 "확장 가능한" 애플리케이션 관리 구조 기반을 이해

**부정적 영향/트레이드오프:**

- automated + prune 조합의 설정 실수 시 **의도치 않은 리소스 삭제 위험** 가능성 존재
- raw URL 기반 설치 방식: 최신 stable을 가져옴 -> 버전 변동/재현성을 하락시기킬 가능성 존재

**향후 고려사항:**

- 버전 고정/미러링: targetRevision을 고정.

---

## References

- [학습 문서](docs/learn/day-007-argoCD-basic.md)
- [배포 앱](argoce/apps/podinfo-kind.yaml)
