# Day 003: 메트릭, 시각화 실습 및 암호화 시크릿 도구

---

about: 학습 기록

**날짜:** 2025-11-13  **소요시간:** 4시간

**난이도(3/5):** ⭐⭐⭐

---

## 🎯 목표 (DoD)

- [O] 목표1: k3d 클러스터에 kube-prometheus-stack 설치로 모니터링 환경 구축
- [O] 목표2: Grafana UI 접속하여 메트릭 시각화 및 대시보드 확인
- [O] 목표3: SealedSecrets 컨트롤러 설치 및 시크릿

## 📚 학습 내용

# 개념 정리
### 관측 (Observability)

- 시스템 내부 상태를 외부에서 이해할 수 있도록 데이터 수집-시각화 체계
- 로그, 메트릭(수치 데이터), 트레이스 등의 데이터를 통한 시스템 헬스 체크, 성능, 오류 원인을 파악

### **kube-prometheus-stack**

**Prometheus, Alertmanager, Grafana** 등이 포함된 완전한 쿠버네티스 관측 솔루션 스택이 포함된 **Helm 차트 패키지**.

- Prometheus : 시계열 메트릭 수집 및 저장
- Prometheus Operator : CRD(k8s 네이티브)방식의 배포/관리 도구
- Alertmanager : 조건에 따른 알림 전송
- Grafana : 시각화 대시보드 제공
- Kube-state-metrics: K8s 리소스 상태 메트릭
- Node-exporter: 노드 하드웨어 메트릭
- 기본 대시보드+알람 규칙(사전 구성)

### SealedSecrets

**Bitnami가 제공하는 ‘암호화된 시크릿’을 Git에 안전하게 저장할 수 있도록 하는 도구**

- 동작: SealedSecrets 컨트롤러가 클러스터 내에서 암호 해독하여 정상 Secret로 변환 배포
- 공개키와 개인키를 통해  암호화/복호화 작업 수행
- 왜 사용하나..? k8s의 기본 시크릿 문제
    - Secret 리소트는 Base64 인코딩된 상태로  저장 → 보안 취약점 존재
    - Git 등 버전 관리에 직접 Plain Secret 저장 →  유출 위험

[첫 암호화 과정]

1. 공개키를 이용한 Plain Secret 파일 암호화 (SealedSecret 생성)
2. SealedSecret을 Git에 체크인
3. 클러스터에 배포하면 컨트롤러가 해독 후 사용 가능한 Secret로 변환

## 🛠️ 실습 과정

### kube-prometheus-stack 설치
`helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
```bash
helm upgrade --install kps prometheus-community/kube-prometheus-stack \
  -n observability --create-namespace \
  --set grafana.adminPassword='pasw123' \
  --set grafana.service.type=NodePort
```

**파드, 서비스 확인**
`kubectl -n observability get po, svc`

**Grafana NodePort 확인 및 포트포워딩**
`kubectl -n observability port-forward svc/kps-grafana 3000:80`

**Grafana UI 접속 후 대시보드 확인**


### SealedSecrets Controller 설치 및 시크릿 생성후 암호화
### SealedSecrets 컨트롤러 설치

1. 깃허브 API를 통한 **최신 버전 동적 추출**
`KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/tags | jq -r '.[0].name' | cut -c 2-)`
    - **curl → HTTP 요청 도구**
    - **-s → Silent 모드 (진행 상황 표시 X)**
    - **https://api.github.com/repos/bitnami-labs/sealed-secrets/tags → 깃허브 API 엔드포인트**

2. 바이너리 다운로드
`curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"`
    
    - **curl → HTTP 요청 도구**
    - **-O → 원본 파일명으로 저장**
    - **-L → 리다이렉트 따라가기 (GitHub 리다이렉트 처리)**
        
        <aside>
        GitHub의 release download 링크는 다른 서버로 리다이렉트됨
        </aside>
        
3. 압축 해제
`tar -xzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz`
4. 시스템에 설치
`sudo install -m 755 kubeseal /usr/local/bin/kubeseal`
    - **sudo** → 관리자 권한으로 실행
    - **install** → 파일을 지정 위치에 복사 + 권한 설정
    - **-m 755** → 권한 설정 (rwxr-xr-x)
    - **/usr/local/bin/kubeseal** → 시스템 경로에 저장
        
        <aside>
        /usr/local/bin
        - Unix 시스템의 관례
        - PATH에 자동 포함됨
        - 터미널 어디서든 **`kubeseal`** 명령 사용 가능
        </aside>


### SealedSecrets 생성 및 암호화

**1 평문 시크릿 생성.yaml**

- 쿠버네티스 ‘Secret’ 리소스를 YAML 매니페스트로 정의
- **stringData -** 평문 값 입력(Base64 인코딩은 kubectl 이 자동으로 함)
- 미암호화 상태

`cat > secret-db.yaml <<'YAML'`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-cred
  namespace: demo
type: Opaque
stringData:
  DB_USER: demo
  DB_PASS: 321passw
```

`YAML`

**2 kubeseal로 암호화 (WSL에 kubeseal 설치 필요)**

```yaml
kubeseal --cert mycert.pem --format yaml < secret-db.yaml > sealed-secret-db.yaml
```

- **kubeseal** → 암호화 도구
- **-cert mycert.pem** → "이 공개키를 사용해서 암호화해" 지정
- **-format yaml** → 출력 포맷을 YAML로 (기본값)
- **< secret-db.yaml** → 표준 입력으로 평문 Secret YAML 받음
- **> sealed-secret-db.yaml** → 암호화된 결과를 파일로 저장

### 클러스터에 적용

`kubectl apply -f sealed-secret-db.yaml`
```
#내부 동작
1. SealedSecret 리소스가 클러스터에 생성됨
2. etcd에 저장됨 (암호화된 상태 유지)
3. Controller가 감시(watch) 시작
4. 자동으로 개인키로 복호화
5. 일반 Secret으로 변환해 생성
6. Pod가 Secret 참조 가능
```

```
#동작 검증
# SealedSecret 확인
kubectl get sealedsecret -n demo
# 암호화된 리소스 목록

# 자동 생성된 Secret 확인
kubectl get secret -n demo
# 실제 Secret이 생성되었는지 확인

# Secret 값 복호화 확인
kubectl get secret -n demo db-cred -o jsonpath='{.data.DB_PASS}' | base64 -d
# 출력: secpyungmoon (원본 평문!)
```

## 💡 회고+배운 점

1. 과거 경력중 익숙했던 Monitoring와 Observability의 차이점
- Monitoring: 사전에 정의된 메트릭 즉, 수집했던 것들만 확인
- Observability: 미리 정의하지 않은 것도 추적해서 확인할 수 있는 체계
2. 시계열 데이터의 중요성: 패턴을 파악하여 "이상 감지"를 할 수 있음. 단순 스냅샷으로는 불가능
3. 프로메테우스가 널리 쓰이는 이유 (시계열 특화+agent가 필요 없는 Pull 모델+강력한 쿼리(promQL) 언어+k8s 표준
- "Pull Model, Push Model이란..?
    - Pull Model(none-agent 방식) : 프로메테우스가 주도권을 가지고 메트릭 Request - Kubelet, 앱 메트릭 Response - 수집
    - 장점: 장애추적 쉬움, 부하 제어, 중복 메트릭 제거 쉬움 <-> 단점: 방화벽 문제(프로메테우스가 내부 접근해야함)
    - Push Model(agent가 밀어냄) : 앱이 주도권을 가지고 메트릭 Request - 메트릭 서버
    - 언제 사용하나?: 단기 작업(배치 잡, 람다), 외부 시스템(클라우드 함수)
4. Prometheus Operator와 CRD
- k8s native화 되어 ServiceMonitor CRD(Custom Resource Definition) 작성만으로 프로메테우스 설정
5. Alertmanager: 문제를 감지하여, 즉시 모니터링이 가능하도록 하는 체계의 시작점.
    - "설정" 개념이 아닌 점 주의 -> 허위 알림을 개선하기 위한 지속적 개선 및 튜닝 필요
6. SealedSecrets 패러다임
: Secret를 암호화해서 Git에 저장하는 방식으로 다음과 같은 매커니즘
| 공개키-개인키 비대칭 암호화
| 1. 로컬에서 kubeseal이 공개키로 평문 -> 암호화 (sealed-secret.yaml)
| 2. 클러스터의 SealedSecrets 컨트롤러가 개인키로 복호화 (일반 Secret로 변환=Pod 사용)
| 3. 개인키는 클러스터 안에만 존재 (외부 접근 불가능)
|=> 암호화된 상태로 Git에 저장 = "GitOps 핵심"
7. SealedSecret 최소 보안 패턴은 소규모에만 적합(wyh? etcd가 뚫리면 끝.) -> Vault까지 고려한 설계 필요

## 🐛 에러+디버깅

**발생한 문제:**
SealedSecrets 컨트롤러 설치 + 첫 시크릿 과정중 kubectl apply -f sealed-secret-db.yaml 매니페스트를 통한 생성시 "error: no objects passed to apply" 발생

**핵심 원인:**
: Contoller 이름 미일치
- kubeseal이 sealed-secrets-controller 이름의 deployment 찾지 못함
- 공개키 fetch 실패
- 빈 파일, 암호화 실패

Controller 이름은 일치해야 함
Helm Release: sealed-secrets
Controller Deployment 이름: sealed-secrets-controller


**해결 방법:**
set -e

cd ~/kubeseal-install
rm -f kubeseal*

###버전 확인
KUBESEAL_VERSION=$(curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/tags | jq -r '.[0].name' | cut -c 2-)

###공식 깃허브에서 버전 압축 파일 다운
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v${KUBESEAL_VERSION}/kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz"

압축 해제
tar -xzf kubeseal-${KUBESEAL_VERSION}-linux-amd64.tar.gz

설치
sudo install -m 755 kubeseal /usr/local/bin/kubeseal

설치 검증
kubeseal --version
which kubeseal


## 🔗 관련 문서

- docs/laerning/day003-observability+씰.md
- https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- https://github.com/bitnami-labs/sealed-secrets
- 

## ✅ 완료 여부

- [O]  문서화 완료 (`docs/learning/day003-observability+씰.md`)
- [O]  PR 생성 & Merge
