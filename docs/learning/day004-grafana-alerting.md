# Day 004: Grafana 및 Alerting Rules 구성과 테스트

---

about: 학습 기록

**날짜:** 2025-11-14  **소요시간:** 3시간 30분

**난이도(2/5):** ⭐⭐

---

## 🎯 목표 (DoD)

- [O] 목표1: Day3 과정의 kube-prometheus-stack Helm 차트에 포함된 Grafana에 핵심 대시보드 2개(노드/파드) 가져오기
- [O] 목표2: 알람(경보) 생성: CrashLoopBackOff 감지
- [O] 목표3: 테스트 트리거 & 해제 해보며 변화 확인해보기

## 📚 학습 내용

## 개념 정리

### CrashLoopBackOff
Pod 컨테이너가 반복적으로 실패(크래시)하여 계속 재시작되는 상태

**발생원인**
- 애플리케이션 코드 오류
- 리소스 부족 ex) 메모리/CPU 초과
- 잘못된 설정 ex) 환경변수, ConfigMap, Secret 오류
- Liveness Probe 실패 ex)헬스체크 실패
- 의존성 문제 ex) DB 연결 불가 등

### Prometheus
오픈소스 시계열 메트릭 수집, 저장, 조회 시스템

**핵심기능**
- k8s 클러스터의 Pod, Node, 컨테이너 메트릭 자동 수집
- PromQL(Prometheus Query Language)로 메트릭 조회, 계산
- 알람 규칙(Alerting Rules) 설정으로 이상 상황 감지

> 조건 기반 알람을 자동 생성하는 모니터링 핵심 도구

### Prometheus Operator
프로메테우스를 CRD라는 **쿠버네티스 네이티브 방식**으로 쉽게 배포/관리하는 도구

**핵심 CRD**
- Prometheus: Prometheus 서버 인스턴스 정의
- ServiceMonitor: Service 기반 메트릭 수집 타겟 자동 등록
- PodMonitor: Pod 기반 메트릭 수집 타겟 자동 등록
- PrometheusRule: 알람/기록/규칙 정의
- Alertmanager: 알람 라우팅/전송 관리

> 프로메테우스 오퍼레이터는 CRD를 통해 프로메테우스 전체 라이프사이클(설치, 설정, 알람)을 k8s 방식으로 자동화함.

### PrometheusRule
Prometheus가 사용할 **알람규칙**과 **기록규칙**을 쿠버네티스 오브젝트로 정의하는 CRD

**역할**
- YAML로 알람 조건 작성
- Prometheus Operator가 자동으로 규칙 로드
- 규칙 변경 시에도 재시작 불필요(동적 로드)

## 🛠️ 실습 과정

## 1) Grafana에 핵심 대시보드 2개(노드/파드) 가져오기

**Grafana 포트포워딩**

`kubectl -n observability port-forward svc/kps-grafana 3000:80`  

- http://localhost:3000 관리자 로그인

**대시보드 가져오기**

1. 그라파나 좌측 메뉴 Dashboards → New → Import
2. 검색 또는 JSON 업로드
- **Kubernetes / Compute Resources / Pod**
- **Node Exporter / Nodes**

## 2) 알람(경보) 생성: CrashLoopBackOff 감지

### PrometheusRule 생성

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

<aside>
💡

PromQL 표현식 `increase(kube_pod_container_status_restarts_total[5m]) > 3`

- kube_pod_container_status_restarts_total:
    - kube-status-metrics가 제공하는 메트릭
    - 컨테이너가 재시작된 누적 횟수
- [5m]: 최근 5분간 데이터
- increase(): 5분간 증가량 계산
- >3: 증가량이 3회 초과 시 true

> ⇒ “최근 5분간 컨테이너가 3번 넘게 재시작되면 알람!”
> 
</aside>

`kubectl apply -f k8s/rules/crashloop-alert.yaml`
`kubectl -n observability get prometheusrule`

### 3) 검증: 알람 유도(테스트 파드) - 해제(테스트 파드 삭제)

**트리거**
```yaml
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
```

`kubectl apply -f k8s/faulty/faulty-pod.yaml`
`kubectl -n demo get pod faulty -w`

**해제(복구)**
`kubectl -n demo delete pod faulty`
**잠시 후 ALERT 상태가 Normal 전환 확인**


## 💡 회고+배운 점

1. 운영 준비 측면에서 시각화된 대시보드와 경보 알림은 중요함
2. CrashLoop는 MTTD(장애 인지 시간)과 MTTR(장애 복구 시간)를 좌우하는 알림임
3. 실제 장애 시, 자사 서비스의 경우 RPO 범위를 줄이는 부분
고객사의 경우 SLA 측면에서 손실을 줄일 수 있는 최소한의 장치로 생각됨.
4. 실무에서는 인프라+prod 환경 규모가 클 것이므로 단순 설정이 아닌 지속적인 보완-조정 등의 튜닝이 필요할 것으로 예상됨
5. 잘못된 튜닝에 따른 오경보를 주의해야할 필요가 있어 보임


## 🐛 에러+디버깅


## 🔗 관련 문서

- [docs/learning/day004-grafana-alerting.md]
- [관련 ADR] [docs/adr/004-why-rometheuusRule-and-grafana.md]

## ✅ 완료 여부

- [O]  문서화 완료 (`docs/learning/day004-grafana-alerting.md`)
- [O]  PR 생성 & Merge
