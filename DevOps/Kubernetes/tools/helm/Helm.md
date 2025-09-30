
Helm이란, kubernetes 패키지 관리를 도와주는 tool이다.  Node.js의 npm, Python의 pip와 같은 역할이라고 볼 수 있다.

## Chart

Helm은 차트라고 불리는 Package formet을 사용한다.

차트는 Kubernetes Resouce들의 내용을 나타내는 파일들의 집합이다. 예를 들어 `Wordpress`의 차트는 아래와 같은 구조를 가지고있다.

```bash
wordpress/
Chart.yaml          # chart에 대한 정보
LICENSE             # (optional) chart의 license에 대한 정보
README.md           # (optional) 사람이 읽을 수 있는 README 파일
requirements.yaml   # (optional) Chart의 dependency 리스트
values.yaml         # Chart의 기본 설정값
charts/             # 이 차트가 의존하는 차트가 들어 있는 디렉터리
templates/          # 설정값과 결함하여 menifest를 만들 template
templates/NOTES.txt # (optional) 짧은 사용 참고 사항이 포함된 텍스트파일
```

# 컴포넌트

Helm은 크게 client와 server(tiller). 이렇게 두가지 파트로 나뉘어져있다.

|이름|설명|
|-|-|
|client|end user를 위한 command line client. 주로 local chart 개발이나 repository managing, server(tiler)에 chart 설치 요청등 주로 chart의 정보를 관리함|
|server(tiller)|in-cluster 서버. chart의 배포, 릴리즈를 관리함|

## Helm Diff Plugin

Helm diff는 Helm의 플러그인으로, 배포 전후의 차이를 미리 확인할 수 있는 도구이다.

### Three-Way Merge

Helm diff의 three-way merge 옵션(`--three-way-merge`)은 Kubernetes 클러스터의 현재 상태, Helm 릴리즈의 마지막 배포 상태, 그리고 새로운 변경사항을 비교하는 기능이다.

- 일반적인 diff는 마지막 배포된 manifest와 새로운 manifest만 비교한다.
- Three-way merge: 클러스터의 실제 상태까지 고려하여 세 가지 상태를 비교한다.
  - Last deployed manifest (Helm이 마지막으로 배포한 상태)
  - Current cluster state (현재 클러스터의 실제 상태)
  - New manifest (새로 적용하려는 상태)

```bash
# three-way merge 옵션 사용
helm diff upgrade <release-name> <chart> --three-way-merge

# 일반 diff와 비교
helm diff upgrade <release-name> <chart>
```

- `--three-way-merge` 옵션은 Pulumi의 refresh와 유사하게 클러스터의 현재 상태를 반영하는 옵션이지만, `disableValidationOnInstall: true` 옵션과 함께 사용할 수 없다.
  - Three-way merge는 클러스터의 현재 상태를 가져와서 비교하는 과정에서 Kubernetes 객체의 유효성을 검증, `disableValidationOnInstall: true`는 설치 시 유효성 검증을 건너뜀
  - 두 설정이 충돌하면서 특히 CRD(Custom Resource Definitions) 처리 시 "unable to build kubernetes objects from new release manifest" 같은 에러가 발생할 수 있다.
  - Three-way merge가 현재 상태를 읽고 비교하려면 객체 검증이 필요한데, disableValidation이 이를 비활성화하기 때문이다.
  - <https://github.com/databus23/helm-diff/issues/385>
