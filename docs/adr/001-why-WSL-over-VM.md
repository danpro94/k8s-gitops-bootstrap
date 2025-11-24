# ADR-001: 로컬 Kubernetes 학습환경 WSL2+k3d(+kind) 결정

**날짜:** 2025-11-12

**상태:** ✅ Accepted

---

## Context (배경)

**문제:**

기존 온프레미스/Windows/Azure 기반 시스템 엔지니어 직무에서 경력 개발을 위한 컨테이너 및 클라우드 네이티브(Cloud-Native) 중심 Kubernetes 생태계에 대한 실무 역량 확보가 필요함. Linux 환경의 컨테이너 오케스트레이션 경험 부족.

**현재 상황:**

Linux, Docker, k8s, CI/CD 파이프라인을 아우르는 시스템 플로우 내제화 필요 및 학습 및 실습을 위해 쾌적하게 구동되는 로컬 환경 구축 필요함.

---

## Decision (결정)

**선택한 방법:**

WSL2 + k3d (with Helm)

**이유:**

1. 빠른 속도 및 효율성: k3s 기반으로 컨터이내 내 노드 실행으로, VM 대비 부팅속도가 빠르고 전체적으로
가벼워 학습 중 잦은 설정 초기화와 반복 실습에 이점
2. WSL2로 Linux 네이티브 경험: 제한적인 하드웨어 리소스 중 상대적으로 고성능의 Windows 환경을 유지하면서
WSL2를 통해 실제 Linux 커널 위에서 실습 가능. 리눅스 서버 환경의 트러블슈팅 역량을 기르는 데에도 최적화.
3. 현업 표준 도구와 호환성: Helm을 통한 패키지(chart) 관리 방식으로 배포 표준을 로컬에서 실습해볼 수 있음.

---

## Alternatives Considered (대안 검토)

### 대안 1: VMware Workstation Pro + Ubuntu VM + Minikube

**장점:**

- 완전히 격리된 OS 환경
- GUI 기반 Linux 데스크톱 환경 경험

**단점:**

- Guest OS를 구동해야하므로 H/W 리소스 점유율 높음
- 부팅 및 클러스터 프로비저닝 속도 (빠른 학습 사이클 저해)

### 대안 2: kind (Kubernetes in Docker)
#### 학습 목적 상 kind도 병행하여 차이점 익힐 예정

**장점:**

- CNCF 공식 프로젝트, 표준 쿠버네티스(Upstream)과 유사한 환경
- CI/CD 파이프라인 통합 테스트에 널리 사용됨.

**단점:**

- 이미지 로딩 속도

---

## Consequences (결과)

**긍정적 영향:**

- 빠르고 가볍게 멀티 노드 클러스터 구축이 가능함
- 클라우드 이식성 높음
- 비용 절감 및 실무 아키텍처 벤치마킹 가능


**부정적 영향/트레이드오프:**

- 경량화 한계
- 윈도우 한정 이슈 발생 가능성(WIN 11)

**향후 고려사항:**

- 로컬 환경 숙달 - AWS Free Tier 활용 EKS 확장 - Hybrid Cloud CD 파이프라인

---

## References

- [k3d] https://k3d.io/stable/
- [Microsoft:WSL 설치] (https://learn.microsoft.com/ko-kr/windows/wsl/install)

