# RUNBOOK - k8s-gitops-bootstrap

## 1. 대시보드 링크
- Nodes: Grafana -> Dashboards -> Kubernetes Nodes
- Pods: Grafana -> Dashboards -> Kubernetes / Compute Resources / Node(Pods)
- 기본 필터: `Namespace=demo`

## 2. 알람 (운용중)
 **PodCrashLooping (warning)**
- Rule: `increase(kube-pod_container_status_restats_total[5m]) > 3 for 2m`
- 목적: 비정상 파드 재시작 및 빠른 식별

## 3. 증상별 점검 및 복구
### 3-1) CrashLoopBackOff
**예상 원인**
- 이미지 태그/엔트리포인트 오류
- Config/Secret 누락
- 자원 제한

**점검 명령**
kubectl -n demo describe pod <파드명>
kubectl -n demo logs <파드> -c <컨테이너> --previous
kubectl -n demo get events --sort-by=metadata.creationTimestamp | tail -n 30

**복구 절차**
1. Log로 원인 파악 (이미지-환경-프로브)
2. 수정 커밋 -> 이미지 리빌드/태깅 -> Heml 값 반영 -> 재배포
3. Alert 상태 "Resolved" 되는지 확인(대시보드 혹은 Alerting 메뉴)
