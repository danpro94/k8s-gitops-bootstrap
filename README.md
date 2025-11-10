# k8s-local-gitops-bootstrap (Day1 Short Sprint)

## 문제
- 로컬에서 k8s/Helm/Ingress 동작을 빠르게 재현 가능한 템플릿 필요.

## 설계
- WSL2 + k3d(k3s) + Traefik Ingress
- Helm 차트로 앱 배포, 포트포워딩: host:8080 -> cluster:80
```
Traefik Ingress:
쿠버네티스 환경에서 외부 트래픽을 내부 서비스로 라우팅하는 데 쓰는
Traefik이라는 역방향 프록시 기반의 Ingress Controller
```

# 실행
```bash
./scripts/cluster_up.sh
# 열기 http://localhost:8080
