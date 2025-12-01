# Day 002: davcontainer를 활용한 k8s-gitops-bootstrap 프로젝트 환경 표준화

---

about: 학습 기록

**날짜:** 2025-11-12  **소요시간:** 4시간

**난이도(3/5):** ⭐⭐⭐

---

## 🎯 목표 (DoD)

- [O] 목표1: Github Repository 정책 설정
- [O] 목표2: Dev Container 구성 및 환경표준화
- [O] 목표3: 샘플 앱 배포 및 CI Workflows 활성화

## 📚 학습 내용

### 깃허브 레포 정책
- Workflow permissions
Actions를 구동할 수 있도록 코드를 읽기(Read)와 더불어 수정/배포(Write) 권한을 부여
- Branch Protection
    - main branch(=production)의 Human Error를 방지하기 위한 main 브랜치 보호 규칙 개념
    - main 외 branch(=dev)에서 main으로 merge 전 본인 외 PR Review 강제를 통해 안전 장치 마련

### 로컬 구조와 설계 패턴
- k8s/: **선언적 데이터**가 위치 (무엇을 만들 것인가)
- scripts/: **명령형 로직**이 위치 (어떻게 실행할 것인가)
- **데이터** 와 **로직** 은 분리하는 것이 유지보수성 확보됨

### Dev container
: 개발 환경을 컨테이너화함에 따라 표준화되고 어디서든 재현할 수 있는 개발환경의 제공이 목적
- 컨테이너 구성 핵심 파일 `.devcontainer/devcontainer.json`


## 🛠️ 실습 과정
### 1 로컬 구조 초안 만들기
```Plain Text
k8s-gitops-bootstrap/
README.md #프로젝트 소개
.github/
|-workflows/
||-ci.yaml #프로젝트 Github Actions용 ci workflows 정의
|-dependabot.yml #종속성 보안취약점 PR 점검 workflows 정의
app/
|-html/
||-Dockerfile #샘플앱 배포용
.devcontainer/
|-devcontainer.json #기본 이미지, features, scripts용 Tool 정의
|-setup.sh # 툴설치 자동화 스크립트
.gitignore #민감파일/비밀 등 제외용
```

### 2 Repository 생성 및 정책 세팅
- Settings → Actions → General: Workflow permissions Read and write 체크
- Settings → Branches: Branch protection(Require PR review 1명, Require status checks는 CI 붙인 뒤 활성)
    - Branch rules
    1. 삭제 제한: 권한 사용자만 브랜치, 태그 삭제
    2. merge 전 필수적인 Pull request: main에 병합하기 전 PR 생성 및 승인을 강제
    3. 강제 푸쉬 금지: --force 옵션 명령과 같이 원격 저장소 내용 강제 덮어쓰기 금지
 -> 학습 및 실습 편의상 Bypass list에 본인을 추가함.

### 3 devcontainer init
1. `.devcontainer/devcontainer.json` 정의
- 이름 및 기본 이미지: k8s-gitops / ubuntu
- 기능 설치: Git, docker-in-docker (from github container registry.io)
- 컨테이너 생성후 실행(postCreateCommand): bash .devcontainer/setup.sh (한번만 실행됨)
- 컨테이너 내 작업 사용자 설정(remoteUser): vscode
- ⭐**(중요) 도커 소켓(/var/run/docker.sock) 바인딩(=컨테이너에 마운트)**
    => 도커 CLI 명령을 컨테이너 내에서 **HOST(PC) 도커 엔진과 직접 연동**

```json
{
        "name": "k8s-gitops",
        "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
        "features": {
                "ghcr.io/devcontainers/features/git:1": {},
                "ghcr.io/devcontainers/features/docker-in-docker:2": {}
        },
"postCreateCommand": "bash .devcontainer/setup.sh",
"remoteUser": "vscode",
"mounts": ["source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"]
}
```


2. `.devcontainer/setup.sh` 정의
역할: 컨테이너 생성/빌드시 한번만 실행되어 툴 설치 자동화
- `set -euo pipefail` 을 통해 스크립트 안전(오류 검출) 확보
    - `-e`: 에러 발생시 즉시 종료
    - `-u`: 선언되지 않은 미설정 변수 참조시 오류 발생 시키기
    - `-o pipefail`: 오류 발생 코드를 반환
- apt 패키지 매니저를 통한 update후 curl gnupg ca-certificates 설치
- kubectl, helm, k3d 설치


```bash
#!/usr/bin/env bash
set -euo pipefail
apt-get update && apt-get install -y curl gnupg ca-certificates
# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && mv kubectl /usr/local/bin/
# helm
curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
# k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

### 4. 샘플 앱 (빌드 테스트용) 정의
- /app/Dockerfile
    
    ```docker
    # app/Dockerfile
    FROM cgr.dev/chainguard/nginx:latest
    COPY ./html /usr/share/nginx/html
    ```
    
    <aside>
    💡
    
    Chainguard 이미지란…?
    
    :이미지의 크기와 컴포넌트를 줄여 취약점은 작게 유지하고, 보안은 높임.
    
    - 보안 최적화된 최소 이미지
    - 불필요한 패키지 제거
    - CI/CD에서 스캔 시 취약점 적음
    </aside>
    
- /app/html/index.html
    
    ```docker
    <!-- app/html/index.html -->
    <!doctype html>
    <html><body>
    <h1>Local GitOps Bootstrap</h1>
    <p>Build: {{ GIT_SHA }}</p>
    </body></html>
    ```

### 5. Github Action CI Workflow 정의
CI Workflow 구조: 코드변경 -> 자동빌드 -> 자동푸시 -> 자동스캔(Trivy 보안) -> SBOM 생성 -> 자동배지 -> 레지스트리 저장
`.github/workflows/ci.yaml` 

<aside>
💡

Github Action의 CI(지속적 통합) 워크플로우이며 디렉터리명과 ci.yaml 파일명은 Github에서 정한 규칙이다.

</aside>

- 워크플로 이름: ci
- 트리거 조건: (이벤트)main 브랜치에 push 발생 시
    - `on:`
        
          `push:` 
        
              `branches: [ "main" ]`
        
          `pull_request:`
        
- permissions: Github 토큰 권한 설정(읽기, 패키지 쓰기 등)
    - content: read #레포 코드 읽기 권한
    - id-token: write #OpenID Connect 토큰 발급 권한
    - packages: write #GHCR 이미지 푸시 권한
    
    > 이 워크플로는 GHCR에만 푸시할 수 있으며, Github 설정을 건드릴 수 없어 보안 침해 시  피해 범위가 최소화된다. 즉, 최소 권한 원칙이  반영되어 있다.
    > 
- jobs: build-scan-push(작업): `runs-on: ubuntu-latest` : 최신 우분투 환경에서 실행
- steps
    1. **`actions/checkout@v4`**: 코드 저장소 클론
    2. Git 커밋 SHA 단축 버전(**`GIT_SHA`**) 환경 변수로 선언
    3. **`docker/setup-buildx-action@v3`**: Docker Buildx 설정(멀티플랫폼 빌드 지원)
    4. **`docker/login-action@v3`**: GHCR (ghcr.io) 로그인
    5. Build & Push 도커 이미지:
        - **`docker build -t ghcr.io/저장소명/web:GIT_SHA app`**
        - **`docker push ghcr.io/저장소명/web:GIT_SHA`**

```docker
#ci.yaml
name: ci
on:
  push:
    branches: [ "main" ]
  pull_request:

permissions:
  contents: read
  id-token: write
  packages: write

jobs:
  build-scan-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set vars
        run: echo "GIT_SHA=${GITHUB_SHA::7}" >> $GITHUB_ENV

      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build & push image
        run: |
          docker build -t ghcr.io/${{ github.repository }}/web:${GIT_SHA} app
          docker push ghcr.io/${{ github.repository }}/web:${GIT_SHA}

      - name: Install trivy
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: image
          image-ref: ghcr.io/${{ github.repository }}/web:${{ env.GIT_SHA }}
          format: 'table'
          exit-code: '0'
          vuln-type: 'os,library'

      - name: SBOM (syft)
        uses: anchore/sbom-action@v0
        with:
          image: ghcr.io/${{ github.repository }}/web:${{ env.GIT_SHA }}
          upload-artifact: true
          artifact-name: sbom-${{ env.GIT_SHA }}
```

**Trivy : 보안 스캔 동작 매커니즘**

1. 빌드 이미지 분석
    - 이미지 파일 시스템 추출
    - OS 패키지 목록 작성(apt 등)
    - 애플리케이션 라이브러리 목록 작성
2. Trivy 보유 데이터베이스 내 알려진 취약점 비교
3. 보고서 생성

→ exit-code: ‘0’ :학습 및 실습중으로 “취약점이 있어도  워크플로 계속 진행” 적용 (추후 상향 조정)

**SBOM (Software BIll of Materials) 개념**

: 공급망 투명성에 의거하며, 포함된 라이브러리를 모두 명시하는 것

- 이미지에서 모든 패키지(OS 레벨, APP레벨, 빌드 도구) 발견후 SBOM 생성
- Github Artifacts로 저장되어 다운로드 가능하게 제공

## 💡 회고+배운 점

1. EaC (Environment as Code)라는 IaC의 확장 개념 새롭게 알게됨
2. bash script 명령줄 패턴 set -euo pipefail 새롭게 알게됨
3. 컴퓨팅(PC-WSL2 Host)+가상화(Dev Container(VSCode)-k3d 클러스터(Sibling Containers)) 구조와 DooD(Docker outside of Docker) 개념, 소켓 바인딩에 따른 동작 원리를 새롭게 인지함
4. 현대적 DevOps의 CI 패턴 새롭게 알게됨
5. Trivy, SBOM 개념을 파악: 배포 전 이 이미지가 적절한지 검사, 이미지에 포함된 것들을 투명하게 공개
 



## 🐛 에러+디버깅
### 없음
**발생한 문제:**

**핵심 원인:**

**해결 방법:**

## 🔗 관련 문서

- https://containers.dev/
- https://containers.dev/features
- https://helm.sh/docs/
- https://learn.microsoft.com/ko-kr/windows/wsl/
- https://k3d.io/stable/

## ✅ 완료 여부

- [O] 문서화 완료 (`docs/learning/day002-devcontainerinit-환경표준화.md`)
- [O] PR 생성 & Merge
- [O] 로컬에서 테스트 빌드
- [O] Github Actions 탭에서 각 Step 별 실행 상황 확인
- [O] 완료 후 GHCR 이미지 확인
- [O] Artifacts 탭에서 SBOM 다운로드 및 확인
