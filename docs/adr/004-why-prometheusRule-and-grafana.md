# ADR-004: CrashLoopBackOff 감지용 PrometheusRule 및 Grafana 대시보드 결정

**날짜:** 2025-11-14

**상태:** ✅ Accepted

---

## Context (배경)

**문제:**
- Day3에 `kube-prometheus-stack` 설치까지는 진행했으나 실제 장애 감지는 못하는 상태
- k8s 러닝커브 및 초반에 주로 부딪히는 이슈로 꼽히는 'CrashLoopBackOff' 상태에 대한 인지 부족 및 확인 방법 모름.

**현재 상황:**
- k3d dev 클러스터, `kube-prometheus-stack`(include Prometheus Operator, Alertmanager, Grafana) 배포
- 어떤 지표 대시보드가 필요한지 직접 골라야 함
- PrometheusRule 작성 경험 부족

---

## Decision (결정)

**선택한 방법:**

1. Grafana 대시보드 선택
- kps-grafana 서비스 포트포워딩 localhost:3000
- Grafana UI에서 다음 대시보드 Import
    - K8S Dashboard
-> 노드 자원 모니터링

2. CrashLoopBackOff 경보 Rule 정의
- Rules: 컨테이너 재시작 / 5분 이내 3회 초과 / 이상 상태 2분 마다 알람 발생
```yaml
# k8s/rules/crashloop-alert.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: kps-crashloop-alert
  namespace: observability
  labels:
    release: kps   # 설치된 kube-prometheus-stack의 release 이름과 일치 (기본: kps)
spec:
  groups:
  - name: k8s-runtime.rules
    rules:
    - alert: PodCrashLooping
      expr: |
        increase(kube_pod_container_status_restarts_total[5m]) > 3
      for: 2m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.pod }} is crashing frequently"
        description: "Container {{ $labels.container }} in pod {{ $labels.pod }} restarted >3 times in 5m."
```


3. 테스트용 faulty Pod 생성 및 Rule 검증
#k8s/faulty/faulty-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: faulty
  namespace: demo
spec:
  restartPolicy: Always
  containers:
  - name: bad
    image: busybox:1.36
    command: ["sh", "-c", "echo 'boom'; exit 1"]


4. 1~3 결정을 기반으로 RUNBOOK.md 생성


**이유:**

1. 잘못된 설정, Out Of Memory, 의존성 이슈 등 여러 문제가 CrashLoopBackOff로 발생
2. PrometheusRule은 k8s 네이티브 방식, GitOps배포 가능, 재시작 없이 규칙 변경/추가 가능, yaml+코드리뷰 확장성
3. 커뮤니티 대시보드를 십분 활용
4. RUNBOOK을 통한 추가 표준화
    
    ---
    

## Alternatives Considered (대안 검토)

### 대안 1: 대시보드만 확인/알람 미설정
**장점:**

- 구현이 간단

**단점:**

- 실제 운영과 괴리가 큼(사람이 상시 대시보드 확인 불가)

### 대안 2: Grafana UI에서만 알람 정의

**장점:**

- 초기 설정이 간편하고, 직관적임

**단점:**

- 알람의 정의를 코드화할 수 없음 (즉, 버전관리/코드리뷰 어려움)

---

## Consequences (결과)

**긍정적 영향:**

- 알람을 코드(yaml)로 관리할 수 있는 기반 지식 마련 및 경험
- 해당 알람을 버전관리 할 수 있음

**부정적 영향/트레이드오프:**

- CrashLoopBackOff 알람만으로는 운영 전반의 한계가 있음

**향후 고려사항:**

- 다양한 패턴의 Rule 추가
- 알람 Workflow를 추가 도구를 사용하여 개선

---

## References

- [공식 문서]https://github.com/prometheus-operator/prometheus-operator
- [공식 문서]https://grafana.com/grafana/dashboards/15661-k8s-dashboard-en-20250125/
- [k8s-gitops-bootstrap rule][k8s/rules/crashloop-alert.yaml](https://github.com/danpro94/k8s-gitops-bootstrap/blob/main/k8s/rules/crashloop-alert.yaml)
- [k8s-gitops-bootstrap 런북v1][scripts/RUNBOOK.md](https://github.com/danpro94/k8s-gitops-bootstrap/blob/main/RUNBOOK.md)
