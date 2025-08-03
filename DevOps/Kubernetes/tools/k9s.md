```sh
# 기본 kubeconfig 사용
$ k9s

# 기본이 아닌 kubeconfig 사용
$ k9s --kubeconfig /path/to/kubeconfig

# 기본이 아닌 context 사용
$ k9s --context fooctx

# 읽기 전용 모드
$ k9s --readonly

# 정보 확인 (설정, 로그, 화면 덤프 위치)
$ k9s info
```

### 리소스 목록 조회

- 특정 리소스 목록 조회:

        :<resource>: 리소스 목록 조회, 예: 모든 Pod 목록 조회하려면 :pod
        :<resource> <namespace>: 특정 네임스페이스의 리소스 목록 조회

- 사용 가능한 모든 리소스/API 목록 조회:

        :aliases 또는 Ctrl-a: 사용 가능한 모든 별칭과 리소스 목록 조회
        :crd: 모든 CRD 목록 조회
        :apiservices: 모든 API 서비스 목록 조회

- 필터링

        /<filter>: 정규식 필터
        /!<filter>: 역방향 정규식 필터
        /-l <label>: 레이블로 필터링
        /-f <filter>: 퍼지 매치

### 네임스페이스 선택

    - :namespace 입력 후, 위아래 키로 원하는 네임스페이스 선택, Enter로 선택

### 컨텍스트 선택

    :ctx: 컨텍스트 목록 조회 후 목록에서 선택
    :ctx <context>: 지정된 컨텍스트로 전환

### 암호화된 시크릿 보기

- `:secrets`를 입력하여 시크릿 목록 조회 후

    x로 시크릿 복호화
    Esc로 복호화 화면 종료

### 키 매핑

- 오른손을 움직이지 않고 위아래 이동:
    - `j`: 아래로
    - `k`: 위로
    - `h`: 왼쪽
    - `l`: 오른쪽
- `SPACE`: 여러 줄 선택 (예: Ctrl-d로 삭제)
- `y`: yaml 보기
- `d`: 설명 보기
- `v`: 조회
- `e`: 편집
- `l`: 로그
- `w`: 줄바꿈
- `r`: 자동 새로고침
- `s`:
    - Deployment 화면: 레플리카 수 조정
    - Pod 또는 Container 화면: 쉘 접속
- `x`: 시크릿 디코딩
- `f`: 전체화면. 팁: 복사 전에 전체화면 모드로 전환하면 | 문자가 복사되지 않음
- `Ctrl-d`: 삭제
- `Ctrl-k`: 강제 종료 (확인 없음)
- `Ctrl-w`: 넓은 컬럼 토글 (kubectl ... -o wide와 동일)
- `Ctrl-z`: 오류 상태 토글
- `Ctrl-e`: 헤더 숨기기
- `Ctrl-s`: 출력 내용(예: YAML)을 디스크에 저장
- `Ctrl-l`: 롤백

### 정렬

- `Shift-c`: CPU로 정렬
- `Shift-m`: MEMORY로 정렬
- `Shift-s`: STATUS로 정렬
- `Shift-p`: namespace로 정렬
- `Shift-n`: name으로 정렬
- `Shift-o`: node로 정렬
- `Shift-i`: IP 주소로 정렬
- `Shift-a`: 컨테이너 나이로 정렬
- `Shift-t`: 재시작 횟수로 정렬
- `Shift-r`: Pod 준비 상태로 정렬

### Helm

    - :helm: helm 릴리스 조회
    - :helm NAMESPACE: 특정 네임스페이스의 릴리스 조회

### 사용자

- "user" 객체는 없지만 k9s에서 `:users`로 모든 사용자 조회 가능

### 뷰

XRay 뷰
- `:xray RESOURCE`, 예: :xray deploy

Pulse 뷰

- `:pulse`: Kubernetes 클러스터의 일반 정보 표시

Popeye 뷰

- `:popeye` 또는 `pop`: 정확성 기준에 따라 모든 리소스를 검사하고 설명과 함께 결과 "등급" 표시. https://popeyecli.io

### 디스크 파일 보기

  - `:dir /path`

예: :dir /tmp는 로컬 디스크의 /tmp 폴더를 보여줌. 일반적인 사용 사례: Ctrl-s로 yaml 저장 후 :dir /tmp/k9s-screens-root에서 찾아서 파일을 찾고, e를 눌러 편집하고 a를 눌러 적용

종료

  - `Esc`: 보기/명령/필터 모드에서 빠져나가기
  - `:q` 또는 `Ctrl-c`: k9s 종료

### 헤더의 의미

대부분의 헤더는 이해하기 쉬우며, 특별한 것들:

  - `%CPU/R`: 요청된 CPU의 백분율
  - `%CPU/L`: 제한된 CPU의 백분율
  - `%MEM/R`: 요청된 메모리의 백분율
  - `%MEM/L`: 제한된 메모리의 백분율
  - `CPU/A`: 할당 가능한 CPU

Pod:

  - pf: 포트포워드

Container:

  - PROBES(L:R): Liveness와 Readiness 프로브

### 리소스 사용량

화면 왼쪽 상단에서 CPU와 MEM 사용량 확인;

Node와 Pod 페이지에서 사용량 확인;

다음과 동일함:

```
$ kubectl top nodes
$ kubectl top pods

$ kubectl top node <node_name>
```

### 커스터마이징

  - `$HOME/.k9s/views.yml`: 리소스 목록의 컬럼 뷰 커스터마이징
  - `$HOME/.k9s/plugin.yml`: 플러그인 관리
  - `$XDG_CONFIG_HOME/k9s/config.yml`: k9s 설정
  - `$XDG_CONFIG_HOME/k9s/alias.yml`: 사용자 정의 별칭 정의
  - `$XDG_CONFIG_HOME/k9s/hotkey.yml`: 사용자 정의 단축키 정의
  - `$XDG_CONFIG_HOME/k9s/plugin.yml`: 플러그인 관리

### 로그 설정 변경 방법

`~/.config/k9s/config.yml` 변경:

```
logger:
  tail: 500
  buffer: 5000
  sinceSeconds: -1
```

무슨 일이 일어나고 있는지 모니터링하는 방법:

  - :event (또는 :ev): 이벤트 스트림 보기
  - :pod: Pod 목록 보기, Shift-a로 나이별 정렬
  - :job: Job 목록 보기, 기본적으로 시간순으로 정렬

### 벤치마크

k9s는 기본적인 HTTP 로드 생성기를 포함합니다.

활성화하려면 Pod에서 포트 포워딩을 구성해야 합니다. Pod를 선택하고 SHIFT + f를 누르고, 포트포워드 메뉴로 이동합니다(pf 별칭 사용).

포트를 선택하고 CTRL + b를 누르면 벤치마크가 시작됩니다. 결과는 후속 분석을 위해 /tmp에 저장됩니다.

벤치마크 구성을 변경하려면 `$HOME/.k9s/bench-<my_context>.yml` 파일을 생성합니다(각 클러스터마다 고유).

### 플러그인

https://github.com/derailed/k9s/tree/master/plugins

---
### 참고
- https://k9scli.io
- https://github.com/derailed/k9s

