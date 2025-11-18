Dex는 OpenID Connect를 사용하여 다른 애플리케이션의 인증을 처리하는 identity service이다.

Dex는 다른 identity provider로의 커넥터 역할을 한다. Dex는 LDAP 서버, SAML provider, GitHub, Google, Active Directory와 같은 기존 identity provider에게 인증을 위임할 수 있다.

클라이언트가 Dex와 통신하기 위한 인증 로직을 한 번만 작성하면, Dex가 각 백엔드에 대한 프로토콜을 처리한다.

## ID Tokens

ID Token은 OpenID Connect에서 도입된 OAuth2 확장 기능이며 Dex의 핵심 기능이다. ID Token은 Dex가 서명한 JSON Web Token(JWT)으로, OAuth2 응답의 일부로 반환되어 최종 사용자의 신원을 증명한다. JWT 예시는 다음과 같다:

```yaml
eyJhbGciOiJSUzI1NiIsImtpZCI6IjlkNDQ3NDFmNzczYjkzOGNmNjVkZDMyNjY4NWI4NjE4MGMzMjRkOTkifQ.eyJpc3MiOiJodHRwOi8vMTI3LjAuMC4xOjU1NTYvZGV4Iiwic3ViIjoiQ2djeU16UXlOelE1RWdabmFYUm9kV0kiLCJhdWQiOiJleGFtcGxlLWFwcCIsImV4cCI6MTQ5Mjg4MjA0MiwiaWF0IjoxNDkyNzk1NjQyLCJhdF9oYXNoIjoiYmk5NmdPWFpTaHZsV1l0YWw5RXFpdyIsImVtYWlsIjoiZXJpYy5jaGlhbmdAY29yZW9zLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJncm91cHMiOlsiYWRtaW5zIiwiZGV2ZWxvcGVycyJdLCJuYW1lIjoiRXJpYyBDaGlhbmcifQ.OhROPq_0eP-zsQRjg87KZ4wGkjiQGnTi5QuG877AdJDb3R2ZCOk2Vkf5SdP8cPyb3VMqL32G4hLDayniiv8f1_ZXAde0sKrayfQ10XAXFgZl_P1yilkLdknxn6nbhDRVllpWcB12ki9vmAxklAr0B1C4kr5nI3-BZLrFcUR5sQbxwJj4oW1OuG6jJCNGHXGNTBTNEaM28eD-9nhfBeuBTzzO7BKwPsojjj4C9ogU4JQhGvm_l4yfVi0boSx8c0FX3JsiB0yLa1ZdJVWVl9m90XmbWRSD85pNDQHcWZP9hR6CMgbvGkZsgjG32qeRwUL_eNkNowSBNWLrGNPoON1gMg
```

ID Token은 어떤 클라이언트 앱이 사용자를 로그인시켰는지, 토큰이 언제 만료되는지, 그리고 사용자의 신원을 나타내는 표준 claim을 포함한다.

```json
{
  "iss": "http://127.0.0.1:5556/dex",
  "sub": "CgcyMzQyNzQ5EgZnaXRodWI",
  "aud": "example-app",
  "exp": 1492882042,
  "iat": 1492795642,
  "at_hash": "bi96gOXZShvlWYtal9Eqiw",
  "email": "jane.doe@coreos.com",
  "email_verified": true,
  "groups": [
    "admins",
    "developers"
  ],
  "name": "Jane Doe"
}
```

이 토큰은 Dex가 서명하고 표준 기반 claim을 포함하기 때문에, 다른 서비스에서 service-to-service 자격 증명으로 사용할 수 있다. Dex가 발급한 OpenID Connect ID Token를 사용할 수 있는 시스템은 다음과 같다:

- Kubernetes
- AWS STS

ID Token을 요청하거나 검증하는 방법에 대한 자세한 내용은 ["Writing apps that use dex"](https://dexidp.io/docs/using-dex/) 문서를 참고할 수 있다.

## Kubernetes와 Dex

Dex는 Custom Resource Definition을 사용하여 Kubernetes 클러스터 위에서 네이티브로 실행될 수 있다. 또, OpenID Connect 플러그인을 통해 API 서버 인증을 구동할 수 있다.

`kubernetes-dashboard`나 `kubectl`과 같은 클라이언트로도 Dex가 지원하는 identity provider를 통해 인증할 수 있다.

- Dex를 Kubernetes authenticator로 실행하는 방법: <https://dexidp.io/docs/kubernetes>

## Connectors

사용자가 Dex를 통해 로그인할 때, 사용자의 신원 정보는 보통 다른 사용자 관리 시스템(LDAP 디렉토리, GitHub organization 등)에 저장되어 있다.

Dex는 클라이언트 앱과 upstream identity provider 사이의 shim 역할도 할 수 있다. 클라이언트는 Dex를 쿼리하기 위해 OpenID Connect만 이해하면 되며, Dex는 다른 사용자 관리 시스템을 쿼리하기 위한 다양한 프로토콜을 구현한다.

![image](https://github.com/rlaisqls/TIL/assets/81006587/fc23e33b-616b-4ecc-a0d7-5ae658da23ca)

Dex는 GitHub, LinkedIn, Microsoft와 같은 특정 플랫폼을 대상으로 하는 커넥터뿐만 아니라 LDAP, SAML과 같은 확립된 프로토콜을 위한 커넥터도 구현한다.

커넥터의 프로토콜 제약으로 인해 Dex가 refresh token을 발급하거나 그룹 멤버십 claim을 반환하지 못할 수 있다. 예를 들어, SAML은 비대화형 방식으로 assertion을 갱신하는 방법을 제공하지 않기 때문에, 사용자가 SAML 커넥터를 통해 로그인하면 Dex는 클라이언트에게 refresh token을 발급하지 않는다. Refresh token 지원은 `kubectl`과 같이 오프라인 액세스가 필요한 클라이언트에 필수적이다.

## 참고

- [Dex 공식 문서](https://dexidp.io/docs/)
