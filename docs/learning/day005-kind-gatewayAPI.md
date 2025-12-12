# Day 005: kind 스모크 테스트 * Gateway API 학습 및 실습

---

about: 학습 기록

**날짜:** 2025-11-17  **소요시간:** 6시간

**난이도(4/5):** ⭐⭐⭐⭐

---

## 🎯 목표 (DoD)

- [O]  목표1: kind 클러스터 생성(컨트롤 플레인1+워커노드2)
- [O]  목표2: 포트 매핑 (80 -> 18080, 443 -> 18443) *기존 k3d 클러스터 포트 충돌 방지*
- [O]  목표3: Envoy Gateway 설치 및 CRD 적용
- [O]  목표4: demo APP 배포 및 HTTPRoute 트래픽 라우팅
- [O]  목표5: 스모크 테스트 성공 (curl을 통한 접근)

## 📚 학습 내용

### kind (Kubernetes IN Docker)
: Docker 컨테이너를 Kubernetes 노드처럼 보이게 해서 로컬에서 k8s 클러스터를 빠르게 띄우는 도구
- 개발/테스트 환경에서 빠른 k8s 검증용으로 활용
- CI/CD 파이프라인의 smoke test*
- 로컬 개발 환경
> **매커니즘**
- kind로 Docker 컨테이너를 “노드”처럼 보이게 해서 Kubernetes를 띄움
- “kubelet”이 각 노드 컨테이너 안에서 Pod를 관리하고, kind가 그 위를 포장하는 구조
>

*스모크 테스트란
: 작동해야 하는 것만 빠르고, 최소 사항으로 체크하여 모든 단계의 출발설을 통과시키는 점검*

### Gateway API (Ingress 대체 학습) 

**인그레스의 문제점**
- 오래된 API (deprecated ~26/03 예정)
- 컨트롤러마다 기능 제각각 (Nginx is not a Traefik)
- 보안 취약점 (Configuration Snippet 위험)
- 역할 분리 불명확

** Gateway API 개선점**
- 다음 리소스로 L7 트래픽을 표준화해서 관리
    - GatewayClass (인프라팀)
        - Listener 정의(포트/프로토콜)
        - TLS 설정
        - 권한 제어
    -> [연결]
    - HTTPRoute (개발팀)
        - Host  기반 라우팅
        - Path 기반 라우팅
        - 백엔드 Service 선택
=> "역할 분리가 명확함"

**Envoy Gateway**
- Gateway API 구현체(Envoy 기반)
- 컨트롤러 + 데이터플레인 포함
- 높은 성능 & CNCF 표준

### OCI(Open Container Initiative) 레지스트리

기존 Helm 리포지토리:
Helm Repo (index.yaml 기반)
- charts/
- charts-name/
- Chart.yaml

**OCI 기반 Helm 차트:**
Docker 처럼 각 차트가 이미지처럼 관리됨
 **장점**
- Vendor 독립적(Docker, Containerd, CRI-O 모두 호환)
- 보안(서명/검증 지원)
- 확장성

| 전체적인 실습 실행 단계:
1. kind 클러스터
2. 기본 파드/서비스/네트워크 배포 예제 실행
    - nginx 파드 생성
    - 서비스 노출
3. kubectl 명령, 내부 통신, 기본 오브젝트 정상 동작 확인


## 🛠️ 실습 과정

### kind 설치
**1 바이너리 다운로드**
`curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64`
**2 권한 부여**
`chmod +x ./kind`
**3 PATH에 이동**
`sudo mv ./kind /usr/local/bin/kind`
**4 확인**
`kind --version`

### kind 클러스터 생성
*Day1 k3d 클러스터 배포로 인한 포트 충돌 우회*

**문제 발생 지점**
`kind.yaml`
```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: dev

nodes:
  # Control Plane
  - role: control-plane
    image: kindest/node:v1.34.0
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
            cgroup-driver: systemd
      - |
        kind: KubeletConfiguration
        cgroupDriver: systemd
    extraPortMappings:
      - containerPort: 80
        hostPort: 18080
        protocol: TCP
      - containerPort: 443
        hostPort: 18443
        protocol: TCP
  
  # Worker
  - role: worker
    image: kindest/node:v1.34.0
    kubeadmConfigPatches:
      - |
        kind: JoinConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            cgroup-driver: systemd

# Global containerd 설정
containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
      SystemdCgroup = true
```

**생성 및 확인: **
`kind create cluster --name dev --config kind/kind.yaml --wait 10m`
`kubectl get nodes -o wide`
`kubectl get po -A`

---

### Envoy Gateway 설치

**Envoy Gateway 설치 (Helm OCI)**
`helm repo update`

- 패키지 in **Gateway API CRD, Envoy Gateway Contloller, Envoy Data Plane**
`helm install eg oci://docker.io/envoyproxy/gateway-helm -n envoy-gateway-system --create-namespace`

- 준비 상태(사용 가능해질 때까지 대기후) 확인
`kubectl wait --timeout=5m -n envoy-gateway-system deployment/envoy-gateway --for=condition=Available`
`kubectl get pods -n envoy-gateway-system`

### EG(Envoy Gateway) 리소스 적용
`kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/latest /quickstart.yaml -n default`
URL (버전 참고) - https://github.com/envoyproxy/gateway/releases/

- Gateway API 리소스 확인
`kubectl get gatewayclass`
`kubectl get gateway`
`kubectl get httproute`

- 포함된 것
    - GatewayClass/eg
    - Gateway/eg (namespace: default)
    - Sample backend service (httpbin or echo App)
    - HTTPRoute
- 확인
`kubectl get deploy, svc, po -n default`

### 테스트 앱(podinfo(helm) 배포)
```bash
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update

#default 네임스페이스에 설치 (Gateway와 같은 ns로 맞춰 단순화)
helm upgrade -i podinfo podinfo/podinfo --namespace default --create-namespace
```
- 서비스 포트 확인:
`kubectl get svc podinfo -n default -o yaml | grep -A5 ports`

### 테스트 앱(podinfo)용 HTTPRoute 생성 및 적용
**HTTPRoute로 Envoy Gateway -> Podinfo 연결**
`podinfo-httproute.yaml`
```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: podinfo
  namespace: default
spec:
  parentRefs:
    - name: eg        # quickstart에서 만든 Gateway 이름 (eg) :contentReference[oaicite:10]{index=10}
  hostnames:
    - "podinfo.local" # Host 헤더 또는 도메인
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /     # 모든 경로 매칭
      backendRefs:
        - name: podinfo # Service 이름 (helm release 이름과 동일)
          port: 9898    # <확인필요>: 위에서 실제 Service 포트 확인 후 맞추기
```

**적용: **
`kubectl apply -f podinfo-httproute.yaml`
| 매커니즘:
1. Gateway(eg) 들어오는 L4 Listener(포트/프로토콜) 정의
2. HTTPRoute(podinfo) Listener로 들어온 HTTP 요청 <Host: podinfo.local>, <Path Prefix `/`인 트래픽
3. Service/podinfo:9898로 넘김


### Port-forward 및 스모크 테스트
kind에는 (Minikube와 같이) LoadBalancer가 없으므로 port-forward
- Envoy 서비스 이름 찾기:
```bash
export ENVOY_SERVICES=$(
  kubectl get svc -n evnoy-gateway-system \
  --selector='gateway.envoyproxy.io/owning-gateway-namespace=default,gateway.envoyproxy.io/owning-gateway-name=eg' \
  -o jsonpath='{.items[0].metadata.name}'
)

echo $ENVOY_SERVICE
```
- 포트포워딩
`kubectl -n envoy-gateway-system port-forward service/${ENVOY_SERVICE} 8888:80`
- 스모크 테스트
`curl -v -H "Host: podinfo-local" http://localhost:8888



## 💡 회고+배운 점

1. 로컬 클러스터 장애는 대부분 포트/리소스/런타임(cgroup) 3개의 축에서 발생함.
2. 많이 사용되는 __공용 Ingress Level의 Gateway API 구현체 패턴: Envoy Gateway, kgateway, Gloo, Traefik__
3. Gateway API는 설계 상 역할 분리를 강제함 -> 이는 운영조직(플랫폼)과 개발조직(서비스) 분업에 유리한 구조임.

## 🐛 에러+디버깅

**발생한 문제:**
1. Day1의 k3d 로컬 클러스터가 80/8080 443/8443 Port/Process 점유로 인해 충돌
2. Control Plane 노드 정상시작 - 워커 노드 join 단계에서 `kubejoin` 타임아웃

**핵심 원인:**
1. 포트 충돌: 기존 로컬 클러스터/프로세스 점유
2. cgroup 설정 불일치

**해결 방법:**
1. kind의 hostPort 18080/18443 변경
2. containerd/systemd cgroup 일관성 적용 `kubeadmConfigPatches:` - `cgroup-driver: systemd`
(+control-plane 노드 버전 명시 `image: kindest/node:v1.34.0`

## 🔗 관련 문서

- [docs/learning/day-005-kind-gatewayAPI.md]
- [관련 ADR][docs/adr/005-why-kind-envoy-gateway-smoke.md]

## ✅ 완료 여부

- [X]  문서화 완료 (`docs/learning/day-005-kind-gatewayAPI.md`)
- [X]  PR 생성 & Merge
