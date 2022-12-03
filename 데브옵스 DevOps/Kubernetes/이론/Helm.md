# ⚓ Helm

Helm이란, kubernetes 패키지 관리를 도와주는 tool이다.  Node.js의 npm, Python의 pip와 같은 역할이라고 볼 수 있다.

## Chart

Helm은 차트라고 불리는 Package formet을 사용한다. 

차트는 Kubernetes Resouce들의 내용을 나타내는 파일들의 집합이다. 예를 들어 `Wordpress`의 차트는 아래와 같은 구조를 가지고있다.

```bash
wordpress/
      Chart.yaml               # chart에 대한 정보
      LICENSE                  # (선택사항) chart의 license에 대한 정보
      README.md                # (선택사항) 사람이 읽을 수 있는 README 파일
      requirements.yaml        # (선택사항) Chart의 dependency 리스트
      values.yaml              # Chart의 기본 설정값
      charts/                  # 이 차트가 의존하는 차트가 들어 있는 디렉터리
      templates/               # 설정값과 결함하여 menifest를 만들 template
      templates/NOTES.txt      # O선택사항) 짧은 사용 참고 사항이 포함된 텍스트파일
```

# 컴포넌트

Helm은 크게 client와 server(tiller). 이렇게 두가지 파트로 나뉘어져있다.

|이름|설명|
|-|-|
|client|end user를 위한 command line client. 주로 local chart 개발이나 repository managing, server(tiler)에 chart 설치 요청등 주로 chart의 정보를 관리함|
|server(tiller)|in-cluster 서버. chart의 배포, 릴리즈를 관리함|