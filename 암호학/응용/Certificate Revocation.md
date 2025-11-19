
인증서는 유효 기간이 있지만, 다음과 같은 이유로 만료 전에 폐기될 수 있다.

- 개인 키가 유출됨
- 인증서 정보가 변경됨 (회사명 변경 등)
- CA가 손상됨
- 도메인 소유권 변경
- 암호화 알고리즘 약화

인증서 폐기를 관리하는 방법에는 CRL, OCSP, OCSP Stapling, CRLite 등이 있다.

#### Certificate Revocation List (CRL)

CRL은 만료 전에 폐기된 인증서 목록이다. CA가 주기적으로 업데이트하여 배포한다. 클라이언트는 인증서를 검증할 때 CRL을 확인하여 폐기 여부를 체크한다.

실제 데이터는 아래와 같이 서명된 데이터 구조다.

- 발행자(Issuer): 이 CRL을 발행한 CA의 이름
- 발행 시각(This Update): CRL이 발행된 시각
- 다음 발행 시각(Next Update): 다음 CRL이 발행될 예정 시각
- 폐기된 인증서 목록: 각 항목은 다음을 포함한다
  - 인증서 일련번호(Serial Number)
  - 폐기 시각(Revocation Date)
  - 폐기 사유(Reason Code) - 선택사항

```
Certificate Revocation List (CRL):
    Version: 2
    Signature Algorithm: sha256WithRSAEncryption
    Issuer: CN=Example CA
    Last Update: Nov 20 00:00:00 2025 GMT
    Next Update: Nov 27 00:00:00 2025 GMT
    Revoked Certificates:
        Serial Number: 1A2B3C4D5E6F
            Revocation Date: Nov 15 10:30:00 2025 GMT
            Reason Code: Key Compromise
        Serial Number: 7F8E9D0C1B2A
            Revocation Date: Nov 18 15:45:00 2025 GMT
            Reason Code: Superseded
```

클라이언트가 서버 인증서를 검증할 때:

1. 인증서에서 CRL Distribution Point를 찾는다.

   ```
   X509v3 CRL Distribution Points:
       Full Name:
           URI:http://crl.example.com/ca.crl
   ```

2. 해당 URL에서 CRL을 다운로드한다.

3. CRL의 서명을 검증하여 CA가 발행한 것이 맞는지 확인한다.

4. CRL에서 인증서의 일련번호를 찾는다.
   - 목록에 없으면: 인증서는 유효하다.
   - 목록에 있으면: 인증서는 폐기되었다.

### Online Certificate Status Protocol (OCSP)

CRL 방식은 확장성에 문제가 있다. CA가 발급한 인증서가 많으면 CRL 파일이 매우 커진다는 것이다. 대형 CA는 수백만 개의 인증서를 발급하는데, 폐기된 인증서가 수만 개라면 CRL 크기가 수 MB에 달할 수 있다. (캐싱을 할 수도 없다)

OCSP(Online Certificate Status Protocol)는 CRL의 대안으로 등장했다. CRL이 "모든 폐기된 인증서의 목록"을 제공한다면, OCSP는 "특정 인증서가 폐기되었는지"만 답한다.

```
클라이언트 → OCSP 서버: "이 인증서 유효한가요?"
OCSP 서버 → 클라이언트: "유효함" 또는 "폐기됨"
```

현대의 브라우저들은 주로 OCSP를 사용한다. 더 효율적이고 실시간 정보를 얻을 수 있기 때문이다.

OCSP의 동작 방식은 다음과 같다. 요청-응답으로 동작한다.

1. 클라이언트가 인증서에서 OCSP Responder 주소를 찾는다.

   ```
   Authority Information Access:
       OCSP - URI:http://ocsp.example.com
   ```

2. 클라이언트가 OCSP 요청을 만든다.

   ```
   OCSP Request:
       Certificate Serial Number: 1A2B3C4D5E6F
       Certificate Issuer: CN=Example CA
   ```

3. OCSP Responder가 응답한다.

   ```
   OCSP Response:
       Response Status: successful
       Certificate Status: good / revoked / unknown
       This Update: Nov 20 12:00:00 2025 GMT
       Next Update: Nov 20 13:00:00 2025 GMT
   ```

4. 클라이언트가 응답의 서명을 검증하고 인증서 상태를 확인한다. 상태는 아래 세 개 중 하나이다.
    - good: 인증서가 유효하고 폐기되지 않았다.
    - revoked: 인증서가 폐기되었다. 폐기 시각과 사유도 포함된다.
    - unknown: OCSP Responder가 이 인증서에 대해 알지 못한다.

### OCSP Stapling

OCSP도 완벽하지 않다. 실제 사용에서 몇 가지 문제가 있다.

- 클라이언트가 OCSP 요청을 보내면, OCSP Responder는 클라이언트가 어떤 사이트에 접속하려는지 알 수 있다. 사용자의 브라우징 기록이 CA에 노출되는 셈이다. 예를 들어 사용자가 `bank.example.com`에 접속하면, CA의 OCSP 서버에 해당 사이트의 인증서 확인 요청이 간다. CA는 "이 IP 주소의 사용자가 이 은행 사이트에 접속하려 한다"는 정보를 얻게 된다.

- HTTPS 연결을 맺을 때마다 추가로 OCSP 요청을 보내야 하므로, 연결 속도가 느려진다. OCSP 서버가 응답하지 않으면 더욱 지연된다.

- OCSP 서버에 문제가 생기면 곤란해진다. 둘 중 하나의 선택지가 있다.
  - Hard Fail: OCSP 응답을 받지 못하면 인증서를 거부한다. 안전하지만, OCSP 서버 장애 시 모든 사이트가 접속 불가능해진다.
  - Soft Fail: OCSP 응답을 받지 못하면 인증서를 승인한다. 편리하지만, 공격자가 OCSP 요청을 차단하면 폐기된 인증서도 통과시킨다.
  - 대부분의 브라우저는 Soft Fail을 기본값으로 사용한다. 사용성을 택한 것이다.

OCSP Stapling은 OCSP의 문제를 해결한다. 핵심 아이디어는 "서버가 미리 OCSP 응답을 받아두고, 클라이언트에게 직접 전달한다"는 것이다.

1. 서버가 주기적으로 CA의 OCSP Responder에 자신의 인증서 상태를 질의한다.
2. CA가 서명된 OCSP 응답을 보낸다. 이 응답은 유효기간이 있다(보통 몇 시간).
3. 서버는 이 OCSP 응답을 캐시한다.
4. 클라이언트가 TLS 핸드셰이크를 시작하면, 서버는 인증서와 함께 OCSP 응답도 보낸다("staple"한다).
5. 클라이언트는 OCSP 응답의 서명을 확인하고(CA의 공개 키로), 인증서 상태를 즉시 알 수 있다.

```
Client                      Server                  OCSP Responder
  |                           |                            |
  | ---- ClientHello -------> |                            |
  |                           |                            |
  |                           | <-- (미리 받아둔 OCSP 응답) |
  |                           |                            |
  | <-- ServerHello --------- |                            |
  |     Certificate           |                            |
  |     CertificateStatus     |                            |
  |     (OCSP Response)       |                            |
  |                           |                            |
```

이 방식으로 아래 장점을 얻을 수 있다.

- 클라이언트가 CA에 직접 요청하지 않으므로, CA는 사용자의 브라우징 기록을 알 수 없다.
- 클라이언트가 별도의 OCSP 요청을 보낼 필요가 없다. TLS 핸드셰이크 중에 한 번에 모든 정보를 받는다.
- 클라이언트가 OCSP 서버에 접근할 필요가 없으므로, OCSP 서버 장애의 영향을 받지 않는다.
- 서버가 한 번 받은 OCSP 응답을 여러 클라이언트에게 재사용할 수 있다. OCSP 서버의 부하가 줄어든다.

하지만 OCSP Stapling도 완벽하지 않다.

- 서버 의존성: 서버가 OCSP Stapling을 지원해야 한다. 모든 서버가 지원하는 것은 아니다.
- 신뢰 문제: 폐기된 인증서를 가진 서버가 의도적으로 오래된(폐기 전의) OCSP 응답을 보낼 수 있다. 하지만 OCSP 응답에는 발행 시각과 유효기간이 포함되므로, 클라이언트가 너무 오래된 응답을 거부할 수 있다.
- Must-Staple: 이 문제를 해결하기 위해 인증서에 "Must-Staple" 확장을 추가할 수 있다. 이 확장이 있으면 클라이언트는 OCSP Stapling이 없는 연결을 거부한다.

```
X509v3 TLS Feature:
    status_request (OCSP Must-Staple)
```

## CRLite

최근 Firefox는 CRLite라는 새로운 방식을 도입했다. CRLite는 CRL과 OCSP의 장점을 결합한다.

CRLite는 모든 폐기된 인증서의 정보를 블룸 필터(Bloom Filter)로 압축한다. 블룸 필터는 어떤 원소가 집합에 있는지 확률적으로 빠르게 검사할 수 있는 자료구조다.

1. 모든 CA의 CRL을 수집한다.
2. 폐기된 인증서들을 블룸 필터에 추가한다.
3. 압축된 필터를 브라우저에 배포한다.
4. 브라우저는 로컬에서 필터를 확인한다.

CRLite는 아래 장점을 가진다.

- 모든 확인이 로컬에서 이루어진다. 제3자에게 어떤 정보도 전송하지 않는다.
- 네트워크 요청이 필요 없다. 즉각적인 확인이 가능하다.
- 블룸 필터의 압축 덕분에 수백만 개의 폐기된 인증서 정보가 수 MB 정도로 압축된다.

하지만 한계도 있다.

- 블룸 필터는 확률적 자료구조이므로 오탐이 있을 수 있다. 폐기되지 않은 인증서를 폐기되었다고 잘못 판단할 수 있다. 이 경우 OCSP로 재확인한다.
- 필터를 주기적으로 업데이트해야 한다. 하지만 OCSP보다는 덜 빈번하고, 차분 업데이트로 효율적이다.
- 현재 Firefox만 완전히 지원한다. 다른 브라우저는 아직 실험 단계다.

---

참고

- <https://datatracker.ietf.org/doc/html/rfc5280>
- <https://datatracker.ietf.org/doc/html/rfc6960>
- <https://datatracker.ietf.org/doc/html/rfc6066>
- <https://datatracker.ietf.org/doc/html/rfc6962>
- <https://letsencrypt.org/docs/revoking/>
- <https://scotthelme.co.uk/ocsp-must-staple/>
- <https://www.grc.com/revocation/ocsp-must-staple.htm>
- <https://www.netcraft.com/blog/heartbleed-certificate-revocation/>
- <https://blog.mozilla.org/security/2020/01/09/crlite-part-1-all-web-pki-revocations-compressed/>
- <https://blog.mozilla.org/security/2020/01/21/crlite-part-2-end-to-end-design/>
