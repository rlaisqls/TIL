
OIDC (Open ID Connect) 인증 방법은 OAuth2 위에서 동작하는 인증으로, Github이나 Google과 같이 서드 파티에서 부여받은 OAuth 권한을 통해 쿠버네티스의 인증을 수행한다. 기존에 사용하던 OAuth 인증 방법을 쿠버네티스에 그대로 가져온다고 생각하면 이해하기 쉽다. OIDC 인증 방법은 OAuth + JWT 토큰을 사용한다는 점에서 Webhook Token 인증 방법과 차이점을 갖는다.

OAuth 토큰을 관리하기 위한 중간 서버를 구현한 [Dex](https://github.com/dexidp/dex/)를 사용하여 OIDC 인증을 구현해보자.

## Dex Concept

Dex는 서드 파티로부터 OAuth 인증 토큰을 가져와 관리하는 인증 도구이다. OAuth를 사용하기 위해 반드시 Dex를 써야 하는 것은 아니지만, Dex는 OAuth 서드 파티와의 중간 매개체 역할을 해주기 때문에 OAuth의 인증 토큰의 발급, 저장 및 관리를 좀 더 수월하게 해결할 수 있다. Dex는 LDAP, Github, SAML 세 가지 종류의 서드 파티를 Stable로 지원하고 있다. 

우리가 직접 서비스를 개발하려 할 때 OAuth 로그인을 구현하고 싶다면 Dex를 사용해 OAuth 관리를 위임할 수도 있다. 즉, k8s가 아니더라도 Dex를 통해 OAuth 토큰을 관리하고 사용할 수 있으며, 그 기능을 k8s에서 OIDC로서 이용하는 것 뿐이다. 이는 Dex Github의 Getting Started 문서의 예제를 직접 따라해 보면 쉽게 이해할 수 있다.

### Dex Workflow

<img width="543" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/408f5d37-e7a6-49f3-b919-8570d8d42f3d">


1. 애플리케이션 (여기서는 k8s) 사용자가 Dex 클라이언트 App에 접속한다.
2. Dex 클라이언트 App이 Dex의 웹 페이지로 Redirect 한다.
3. Dex 웹 페이지에서는 인증 수단을 선택할 수 있다. 예를 들어, Github을 선택하면 사용자는 Github로 Redirect 된다.
4. Github 웹 페이지에서 Dex에게 권한을 허가하면, Dex 클라이언트 App은 사용자에게 Access Token을 반환한다.
5. 사용자는 Access Token (JWT) 를 Bearer 헤더에 담아서 k8s API 서버로 전송한다.
6. k8s API 서버는 해당 토큰이 유효한지 검증하기 위해 Dex 서버와 통신한다.
7. 인증이 정상적으로 수행되면 API 서버는 API 요청을 수행한다.

> Dex 클라이언트 App : Dex의 기능을 사용하기 위한 별도의 서버를 뜻하며, 사용자가 최초로 접속하는 Endpoint가 된다. 사용자가 Dex의 API를 직접 호출하는 대신, Dex를 사용할 수 있는 별도의 클라이언트 서버에 접근해 사용하는 것이다. Dex 클라이언트 App은 Dex의 웹 페이지로 Redirect 할 수 있어야 하기 때문에 가능하면 MVC와 같은 웹 페이지로 구현하는 것이 권장된다. 

## Dex 설치

### domain 준비

<img width="681" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/b5987272-3796-41af-827d-3ed8afca39ea">

Dex 서버는 쿠버네티스 클러스터 내부에서 구동되는데, 이 Dex 서버는 쿠버네티스 API 서버 뿐만 아니라 사용자의 웹 브라우저에서도 접근이 가능해야 한다. 환경에 맞게 doamin을 준비하여 연결할 수 있도록 하자.

### Dex 소스코드 내려받기 & 인증서 생성하기

먼저 Dex를 내려 받은 뒤 컴파일한다. Go 1.7 버전 이상이 설치되어 있어야 하며, GOPATH가 설정되어 있어야 한다.

```bash
$ go get github.com/dexidp/dex
$ cd $GOPATH/src/github.com/dexidp/dex
$ make
```

스크립트를 실행하면 `example/k8s/ssl` 디렉터리에 인증서가 생성된다. k8s secret으로 미리 등록해주자.

```bash
$ kubectl create secret tls dex.example.com.tls -n oidc --cert=ssl/cert.pem --key=ssl/key.pem
```

### API 서버 실행 옵션 추가하기

API 서버를 dex와 이어주기 위해 아래 설정이 필요하다. 

```bash
# OIDC를 담당하는 서버의 URL, 자신의 domain으로 변경
--oidc-ssuer-url=https://dex.example.com:32000

# Dex 클라이언트 App의 이름
--oidc-client-id=example-app

# JWT 토큰의 내용 중 User로 사용될 Claim 항목 입력
# email이 아닌 다른 클레임(ex. `sub`)이 사용되는 경우 --oidc-issuer-url의 값으로 접두어가 붙는다.
--oidc-username-claim=email

#  JWT 토큰의 내용 중 Group으로 사용될 Claim 항목
--oidc-groups-claim=groups

# --oidc-ssuer-url에 대해 인증할 수 있는 존재하는 pem key로 변경
--oidc-ca-file=/etc/ssl/certs/openid-ca.pem 
```

### Secret 생성 및 Dex 서버 생성하기

Github에서 OAuth App 인증 키를 받아오자. Github의 Organization에서 상단의 [Settings]를 선택한 다음,  좌측 하단의 [Developser Settings]에서 [OAuth Apps]를 선택한다. 

<img width="771" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/016f7127-ea72-4b46-8a03-b66c1618e407">

Application name에는 OAuth App 이름을 적절히 입력한다. Homepage URL은 OAuth와 그다지 상관 없는 단순 메타데이터인 것 같지만, Dex의 주소를 입력해 주었다. Authorization callback URL에는 위 그림과 같이 [`Dex 주소 + /callback`] 을 입력한 뒤, Register application 버튼을 클릭한다. Dex 주소는 반드시 HTTPS를 사용한다는 점에 유의한다.

Client ID와 Client Secret이 출력되는데, 두 값을 잘 복사해 놓는다. 이 값으로 쿠버네티스에서 Secret을 생성해야 한다.

<img width="770" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/b5002954-95b1-477a-9f98-4acea37d1433">

Client ID/Secret 값을 저장하는 쿠버네티스 Secret 리소스를 생성한다. 위에서 복사한 값을 client-id와 client-secret에 붙여넣는다.

```bash
$ kubectl create secret \
    generic github-client \
    --from-literal=client-id=6d7109... \
    --from-literal=client-secret=ef5fc0a95028e37...
```

Dex 클라이언트 App이 Dex 서버의 공개 인증서를 사용할 수 있도록 시크릿을 생성한다.

```bash
$ pwd
/root/go/src/github.com/dexidp/dex
 
$ kubectl create secret generic -n oidc dex-k8s-app --from-file examples/k8s/ssl/ca.pem
secret/dex-k8s-app created
```

마지막으로, Dex 서버를 쿠버네티스에 생성하면 된다. [helm chart](https://github.com/dexidp/helm-charts/tree/master/charts/dex)에서 values를 적절하게 수정해서 install 해주자. (앞에서 생성했던 secret들을 명시해주어야 한다.)

```bash
helm repo add dex https://charts.dexidp.io
helm install dex dex/dex -n oidc --create-namespace --version v0.15.2
```

DNS 전파가 될 때까지 약 5분이 소요된다. 설정한 domain으로 접속해보면 Dex 클라이언트 App으로 접근할 수 있다.

OAuth를 위한 몇 가지 정보를 입력할 수 있는데, 꼭 입력하지 않아도 된다. Login 버튼을 클릭하면 Dex로 Redirect 된다.

<img width="550" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/074cf7e0-1e8a-4c95-9dc3-899d499b15fb">

Github을 선택하면 Github 페이지로 Redirect 된다. Dex에게 권한을 부여해주고 Authorize 버튼을 클릭하면 Access Token이 반환됨과 동시에 redirectURIs로 설정했던 도메인으로 Redirect 된다.

<img width="1261" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/599e5f46-8973-4b55-8d4d-d12292ce2e09">

여러 토큰들이 웹 페이지에 출력된다.

OAuth 토큰에 관련된 데이터들은 Dex의 CRD에 저장되어 관리되기 때문에, 우리가 눈여겨 볼만한 부분은 ID Token과 Claim 부분이다. 이제 ID Token을 통해 쿠버네티스에 인증할 수 있으며, Claim의 email 항목이 User로 간주된다. 따라서 앞으로 Bearer 토큰 부분에 ID Token을 넣어서 API를 호출하면 되고, email이라는 User에 Role Binding 등을 부여해주면 된다.

<img width="762" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/436d7687-d91c-494f-b253-34f3a6d215b5">

---
참고
- https://dexidp.io/docs/kubernetes/
- https://loft.sh/blog/dex-for-kubernetes-how-does-it-work/