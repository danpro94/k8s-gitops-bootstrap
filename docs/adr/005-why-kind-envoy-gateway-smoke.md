# ADR-005: [로컬 실습 kind + Envoy Gateway(Gateway API) + Smoke Test 결정]

**날짜:** 2025-11-17

**상태:** ✅ Accepted

---

## Context (배경)

**문제:**

- Linux 컨테이너 런타임(Docker/containerd) + Kubernetes + 트래픽 인그레스 계층 + CI에서의 배포 (스모크 테스트)까지  
“하나의 흐름”으로 내재화된 실습이 필요
- k3d/minikube 외 kind 클러스터 설치 경험 없음.

**현재 상황:**

- 로컬 환경에서 k3d 클러스터가 포트 점유로 충돌 발생
- 트래픽 진입을 표준적인 방식으로 학습하고, smoke test 검증하는루프 필요

---

## Decision (결정)

**선택한 방법:**

1. 로컬/CI k8s: kind
2. L7 진입 계층: Gateway API + Envoy Gateway
3. 배포: 로컬 포트포워드 + curl 스모크테스트

**이유:**

1. 이유 1: kind 클러스터 빠른 생성/삭제로 실습과 자동화에 적합
2. 이유 2: Gateway API는 역할 분리 구조로 엔터프라이즈 운영을 벤치마킹하기 좋은 표준 리소스. 
3. 이유 3: 실제 배포를 통해 잘못된 환경, 배포를 미리 학습
    
    ---
    

## Alternatives Considered (대안 검토)

### 대안 1: Ingress nginx

**장점:**

- 기존 사례와 자료가 많음

**단점:**

- ingress-nginx 프로젝트가 26/03 retirement 예정
- 향후 표준화 관점에서 Gateway API로 이동을 대비해야함

---

## Consequences (결과)

**긍정적 영향:**

- 로컬에서 **클러스터 - GW - 앱 -라우트 - 스모크테스트** 흐름 반복 학습 가능
- Git Actions 등 CI 확장성 좋음

**부정적 영향/트레이드오프:**

- 로컬 검증에 Port-forward로 테스트 환경 수준의 실습만 가능(운영 환경과 다름)

**향후 고려사항:**

- AWS EKS에 동일 패턴 이식 해보기(로드밸런서/도메인 등 포함)

---

## References

- (docs/learning/day-005-kind-gatewayAPI.md)
- [kind 공식 문서(QuickStart)](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Kubernetes Gateway API 개념 문서](https://gateway-api.sigs.k8s.io/)
- [Envoy Gateway 공식 문서](https://gateway.envoyproxy.io/docs/tasks/traffic/gatewayapi-support/)
