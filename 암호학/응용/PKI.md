
PKI(Public Key Infrastructure)는 공개 키 암호화를 실제 시스템에서 안전하게 사용할 수 있도록 만든 인프라이다.

공개 키 암호화는 수학적으로 안전하지만, 실제로 사용하려면 "이 공개 키가 정말 Alice의 것인가?"라는 질문에 답해야 한다. PKI는 이 문제를 중앙화된 신뢰 체계로 해결한다.

키 인증은 공개 키 암호화의 근본적인 문제이다. Bob이 Alice에게 암호화된 메시지를 보내려 한다고 하자. Bob은 Alice의 공개 키가 필요하다. 하지만 누군가 Alice의 공개 키라며 다른 키를 건네줄 수 있다. 이것이 중간자 공격(Man-in-the-Middle, MITM)이다.

```
[정상적인 경우]
Bob → Alice의 진짜 공개 키로 암호화 → Alice만 복호화 가능

[중간자 공격]
Bob → 공격자의 공개 키로 암호화 (Alice의 키라고 속임) → 공격자가 복호화
```

PKI는 신뢰할 수 있는 제3자(Certificate Authority, CA)를 통해 이 문제를 해결한다. CA가 "이 공개 키는 정말 Alice의 것입니다"라고 보증해주는 것이다.

## 구성 요소

### 1. Certificate Authority (CA)

CA는 디지털 인증서를 발급하는 신뢰할 수 있는 기관이다. CA의 역할은 다음과 같다.

- 인증서 신청자의 신원 확인
- 디지털 인증서 발급
- 인증서의 유효성 관리
- 손상된 인증서 폐기

대표적인 CA로는 DigiCert, Let's Encrypt, GlobalSign, Comodo 등이 있다.

### 2. Registration Authority (RA)

RA는 CA를 대신해서 신원 확인을 수행하는 기관이다. CA가 직접 모든 신청자를 확인하기 어렵기 때문에, RA가 중간 역할을 한다.

- 인증서 신청 접수
- 신청자의 신원 확인
- CA에 인증서 발급 요청 전달

큰 조직에서는 CA가 RA 역할도 함께 수행하기도 한다.

### 3. Digital Certificate (디지털 인증서)

디지털 인증서는 공개 키와 소유자 정보를 CA가 서명한 전자 문서다. 일종의 "전자 신분증"이다.

인증서에 포함되는 정보:

- 소유자 정보: 이름, 조직, 이메일 주소 등
- 공개 키: 소유자의 공개 키
- 발급자 정보: 이 인증서를 발급한 CA
- 유효 기간: 시작일과 만료일
- 일련번호: 인증서를 고유하게 식별하는 번호
- 서명 알고리즘: CA가 사용한 서명 알고리즘
- CA의 디지털 서명: CA가 위 모든 정보를 자신의 개인 키로 서명한 것

가장 널리 사용되는 인증서 형식은 X.509이다.

### 4. Certificate Revocation List (CRL)

CRL은 만료 전에 폐기된 인증서 목록이다.

인증서는 유효 기간이 있지만, 다음과 같은 이유로 만료 전에 폐기될 수 있다.

- 개인 키가 유출됨
- 인증서 정보가 변경됨 (회사명 변경 등)
- CA가 손상됨

CRL은 CA가 주기적으로 업데이트하여 배포한다. 클라이언트는 인증서를 검증할 때 CRL을 확인하여 폐기 여부를 체크한다.

### 5. Online Certificate Status Protocol (OCSP)

OCSP는 CRL의 대안이다. CRL은 전체 폐기 목록을 다운로드해야 하지만, OCSP는 특정 인증서의 상태만 실시간으로 조회한다.

```
클라이언트 → OCSP 서버: "이 인증서 유효한가요?"
OCSP 서버 → 클라이언트: "유효함" 또는 "폐기됨"
```

현대의 브라우저들은 주로 OCSP를 사용한다. 더 효율적이고 실시간 정보를 얻을 수 있기 때문이다.

## PKI의 작동 원리

### 인증서 발급 과정

1. 키 쌍 생성: Alice가 자신의 개인 키와 공개 키를 생성한다.

2. CSR 생성: Alice가 Certificate Signing Request(CSR)를 만든다. CSR에는 공개 키와 신원 정보(이름, 조직, 도메인 등)가 포함된다.

3. 신원 확인: CA(또는 RA)가 Alice의 신원을 확인한다.
   - Domain Validation (DV): 도메인 소유권만 확인 (이메일이나 DNS 레코드로)
   - Organization Validation (OV): 조직의 실존 여부 확인
   - Extended Validation (EV): 엄격한 신원 확인 (법적 실체, 물리적 주소 등)

4. 인증서 발급: CA가 CSR에 자신의 개인 키로 서명하여 인증서를 발급한다.

5. 인증서 배포: Alice가 발급받은 인증서를 자신의 서버에 설치한다.

```
[Alice 측]
1. 개인 키 생성: private_key
2. 공개 키 생성: public_key
3. CSR 생성: {public_key, alice.com, 조직 정보}
4. CSR을 CA에 제출

[CA 측]
1. Alice의 신원 확인 (alice.com의 소유자인지 확인)
2. CSR 검토
3. CA의 개인 키로 서명
   certificate = Sign(CA_private_key, {public_key, alice.com, 유효기간, ...})
4. 인증서를 Alice에게 발급

[Alice 측]
1. 인증서를 서버에 설치
```

### 인증서 검증 과정

Bob이 Alice의 웹사이트(alice.com)에 접속할 때, 브라우저는 다음 과정을 거쳐 인증서를 검증한다.

1. 인증서 받기: 서버가 TLS 핸드셰이크 중에 인증서를 보낸다.
2. 서명 검증: 브라우저가 CA의 공개 키로 인증서의 서명을 검증한다.

   ```
   Verify(CA_public_key, certificate_signature) == certificate_data
   ```

3. 신뢰 체인 확인: 인증서가 신뢰할 수 있는 CA로부터 발급되었는지 확인한다. (뒤에서 자세히 설명)
4. 유효 기간 확인: 현재 시각이 인증서의 유효 기간 내에 있는지 확인한다.
5. 도메인 확인: 인증서의 도메인이 접속하려는 도메인과 일치하는지 확인한다.
6. 폐기 여부 확인: CRL이나 OCSP를 통해 인증서가 폐기되지 않았는지 확인한다.

모든 검증을 통과하면 브라우저는 서버의 공개 키를 신뢰하고 TLS 세션을 시작한다.

## 신뢰 체인 (Chain of Trust)

실제 PKI에서는 단순히 하나의 CA만 있는 것이 아니라, CA들의 계층 구조가 있다.

### Root CA

Root CA는 신뢰 체인의 최상위에 있는 CA다. Root CA의 인증서는 자기 자신이 서명한다. (self-signed certificate)

브라우저와 운영체제는 미리 신뢰하는 Root CA의 인증서를 내장하고 있다. 이것을 "Trust Store"라고 한다.

```bash
# macOS에서 신뢰하는 Root CA 목록 보기
security find-certificate -a /System/Library/Keychains/SystemRootCertificates.keychain

# Linux에서 (Ubuntu/Debian 기준)
ls /etc/ssl/certs/
```

### Intermediate CA

Root CA의 개인 키는 매우 중요하기 때문에 일상적인 인증서 발급에 사용하지 않는다. 대신 Root CA가 Intermediate CA의 인증서를 발급하고, Intermediate CA가 실제 사용자의 인증서를 발급한다.

```
Root CA (자체 서명)
  ├─ Intermediate CA 1 (Root CA가 서명)
  │   ├─ alice.com (Intermediate CA 1이 서명)
  │   └─ bob.com (Intermediate CA 1이 서명)
  └─ Intermediate CA 2 (Root CA가 서명)
      └─ carol.com (Intermediate CA 2가 서명)
```

### 체인 검증 과정

alice.com의 인증서를 검증한다고 하자.

1. alice.com 인증서를 받는다. 이 인증서는 Intermediate CA 1이 서명했다고 표시되어 있다.

2. Intermediate CA 1의 인증서를 받는다. 이 인증서는 Root CA가 서명했다고 표시되어 있다.

3. Root CA의 인증서는 브라우저의 Trust Store에 이미 있다.

4. 역순으로 검증한다.
   - Root CA의 인증서를 Trust Store에서 확인 (자체 서명이므로 신뢰)
   - Root CA의 공개 키로 Intermediate CA 1의 서명 검증
   - Intermediate CA 1의 공개 키로 alice.com의 서명 검증

5. 모든 단계가 성공하면 alice.com의 인증서를 신뢰한다.

```
[검증 순서]
alice.com 인증서
  ← Intermediate CA 1의 공개 키로 검증
      Intermediate CA 1 인증서
        ← Root CA의 공개 키로 검증
            Root CA 인증서
              ← Trust Store에 있으므로 신뢰
```

이 방식의 장점은 Root CA의 개인 키를 오프라인에 안전하게 보관할 수 있다는 것이다. Intermediate CA가 손상되어도 Root CA로 해당 Intermediate CA를 폐기하고 새로 발급할 수 있다.

## 실제 사용 사례

### 1. HTTPS / TLS

PKI의 가장 흔한 사용 사례는 웹사이트의 HTTPS다.

서버는 TLS 인증서를 가지고 있고, 클라이언트(브라우저)는 이 인증서를 검증한다. 인증서가 유효하면 브라우저와 서버 사이에 암호화된 통신이 시작된다.

```
브라우저 → 서버: "alice.com에 접속하고 싶어요"
서버 → 브라우저: "여기 제 인증서입니다"
브라우저: [인증서 검증]
브라우저: [세션 키 생성 및 서버 공개 키로 암호화]
브라우저 → 서버: [암호화된 세션 키]
서버: [개인 키로 세션 키 복호화]
브라우저 ↔ 서버: [세션 키로 암호화된 통신]
```

브라우저 주소창의 자물쇠 아이콘을 클릭하면 인증서 정보를 볼 수 있다.

### 2. 코드 서명 (Code Signing)

소프트웨어 개발자가 자신의 프로그램에 서명할 때 PKI를 사용한다.

- Windows의 .exe 파일 서명
- macOS의 앱 공증(Notarization)
- 모바일 앱 서명 (iOS, Android)
- 브라우저 확장 프로그램 서명

운영체제는 서명을 검증하여 신뢰할 수 있는 개발자의 소프트웨어인지 확인한다. 서명되지 않은 프로그램을 실행하면 경고가 뜬다.

### 3. 이메일 암호화 및 서명 (S/MIME)

S/MIME은 이메일을 암호화하고 서명하는 표준이다. PKI 인증서를 사용한다.

- 발신자는 자신의 개인 키로 이메일에 서명한다.
- 수신자의 공개 키로 이메일을 암호화한다.
- 수신자는 자신의 개인 키로 복호화하고, 발신자의 공개 키로 서명을 검증한다.

GPG와 달리 S/MIME은 중앙화된 CA를 사용한다는 차이가 있다.

### 4. VPN 및 기업 네트워크

기업 내부 네트워크에서도 PKI를 사용한다.

- 직원의 인증서를 발급하여 네트워크 접근 통제
- VPN 접속 시 인증서 기반 인증
- Wi-Fi 접속 시 802.1X 인증

기업은 자체 CA를 운영하여 내부 인증서를 관리한다.

### 5. IoT 기기 인증

IoT 기기들이 서버와 통신할 때 PKI를 사용하여 상호 인증한다.

- 기기가 정품인지 확인 (기기 인증서)
- 서버가 신뢰할 수 있는지 확인 (서버 인증서)

각 기기에 고유한 인증서를 내장하여 위조를 방지한다.

## 장점

- 수백만 개의 인증서를 효율적으로 관리할 수 있다.
- Let's Encrypt 같은 서비스는 인증서 발급과 갱신을 자동화한다.
- Root CA를 안전하게 보호하면서도 일상적인 인증서 발급이 가능하다.
- X.509, TLS 등 국제 표준을 따른다.
- 모든 브라우저와 운영체제가 같은 PKI 시스템을 이해한다.

## 단점

1. CA를 신뢰해야 한다. CA가 손상되거나 부패하면 전체 시스템이 위험해진다.
   역사적으로 여러 CA가 해킹당하거나 잘못된 인증서를 발급한 사례가 있다.
   - 2011년: DigiNotar 해킹으로 수백 개의 위조 인증서 발급
   - 2015년: Symantec이 수만 개의 부적절한 인증서 발급

2. 상용 CA의 인증서는 비싸다. (EV 인증서는 연간 수백 달러)
   Let's Encrypt가 무료 인증서를 제공하면서 이 문제가 많이 완화되었다.

3. PKI 시스템을 올바르게 구축하고 관리하는 것은 어렵다.

4. 폐기에 대해 CRL과 OCSP 모두 완벽하지 않다.
   - CRL은 크기가 크고 업데이트가 느리다.
   - OCSP는 프라이버시 문제가 있다. (CA가 사용자가 어떤 사이트를 방문하는지 알 수 있다)

5. Root CA가 손상되면 해당 CA가 발급한 모든 인증서를 신뢰할 수 없게 된다. (단일 실패 지점)

## Certificate Transparency

CA의 잘못된 인증서 발급을 감시하기 위해 Certificate Transparency(CT)가 도입되었다.

CT는 모든 발급된 인증서를 공개 로그에 기록한다. 누구나 이 로그를 조회할 수 있다.

```
CA가 alice.com의 인증서 발급
  → CT 로그에 기록
    → alice.com 소유자가 로그를 모니터링
      → 자신이 요청하지 않은 인증서가 발급되면 즉시 알 수 있음
```

현대의 브라우저(Chrome, Safari 등)는 CT 로그에 기록되지 않은 인증서를 거부한다. 이로써 CA가 몰래 위조 인증서를 발급하는 것을 방지한다.

CT 로그는 누구나 검색할 수 있다.

- <https://crt.sh/>
- <https://transparencyreport.google.com/https/certificates>

자신의 도메인에 대해 발급된 모든 인증서를 확인할 수 있다.

## DANE

DNS-based Authentication of Named Entities(DANE)는 PKI의 대안이다.

DANE은 CA에 의존하지 않고, DNS 자체를 신뢰의 기반으로 사용한다. DNSSEC으로 보호된 DNS 레코드에 인증서 정보를 직접 게시한다.

```
alice.com의 TLSA 레코드 (DNSSEC으로 서명됨):
"이 도메인의 인증서 지문은 abc123...입니다"
```

클라이언트는 CA 체인 대신 DNSSEC을 검증하여 인증서를 신뢰한다.

장점:

- CA에 의존하지 않음
- 도메인 소유자가 완전한 통제권을 가짐

단점:

- DNSSEC 도입이 느림
- 브라우저 지원이 미흡함
- 설정이 복잡함

현재는 주로 이메일 서버(SMTP) 사이의 통신에서 사용된다.

## Private PKI

조직은 내부용으로 자체 CA를 운영할 수 있다. 이것을 Private PKI라고 한다.

공개 CA는 인터넷의 모든 사람이 신뢰하지만, Private CA는 조직 내부에서만 신뢰한다.

사용 사례:

- 내부 웹 서비스에 TLS 적용
- 직원 인증서 발급
- 기기 인증

조직은 직원의 컴퓨터에 자체 Root CA 인증서를 설치한다. 그러면 내부 서비스의 인증서를 신뢰하게 된다.

오픈소스 도구:

- OpenSSL: 명령줄 기반 CA 운영
- Easy-RSA: OpenVPN과 함께 사용되는 간단한 CA
- CFSSL: Cloudflare의 PKI 도구
- Boulder: Let's Encrypt가 사용하는 CA 소프트웨어

상용 솔루션:

- Microsoft Active Directory Certificate Services
- HashiCorp Vault
- Smallstep

## Let's Encrypt

Let's Encrypt는 2015년에 등장한 무료 CA다.

모든 인증서를 무료로 발급하고, ACME Protocol을 통해 인증서 발급과 갱신을 완전히 자동화한다. 인증서를 Certificate Transparency 로그에 기록한다.

### ACME Protocol

Automatic Certificate Management Environment(ACME)는 Let's Encrypt가 만든 인증서 자동화 프로토콜이다.

```bash
# Certbot을 사용한 인증서 발급
sudo certbot --nginx -d alice.com

# 과정:
# 1. ACME 서버에 계정 등록
# 2. alice.com에 대한 인증서 요청
# 3. 도메인 소유권 증명 챌린지
#    - HTTP-01: 특정 경로에 파일 배치
#    - DNS-01: DNS TXT 레코드 추가
# 4. 챌린지 통과하면 인증서 발급
# 5. 웹 서버에 인증서 설치
# 6. 90일마다 자동 갱신
```

Let's Encrypt의 등장으로 HTTPS가 표준이 되었다. 2025년 현재 웹의 대부분이 HTTPS를 사용한다.

## PKI의 미래

### Post-Quantum Cryptography

현재의 PKI는 RSA와 ECDSA에 기반한다. 하지만 충분히 강력한 양자 컴퓨터가 등장하면 이 알고리즘들은 깨질 수 있다.

NIST는 양자 내성 암호 알고리즘을 표준화하고 있다. PKI도 이런 알고리즘으로 전환해야 한다.

- CRYSTALS-Dilithium (서명)
- CRYSTALS-Kyber (키 교환)

### Decentralized Identity

블록체인 기반의 탈중앙화 신원 관리가 연구되고 있다. CA 없이도 신원을 증명할 수 있는 방법이다.

- DID (Decentralized Identifier)
- Verifiable Credentials

하지만 아직 초기 단계이고, 실제 대규모 도입은 요원하다.

### 더 짧은 인증서 수명

Apple은 2020년에 인증서 최대 유효 기간을 398일(약 13개월)로 제한했다. Let's Encrypt는 90일을 사용한다.

앞으로 인증서 수명이 더 짧아질 가능성이 있다. 자동화가 필수가 될 것이다.

## 정리

PKI는 공개 키 암호화를 실용적으로 만든 시스템이다.

- CA가 디지털 인증서를 발급하여 공개 키의 소유자를 보증한다.
- 신뢰 체인을 통해 Root CA부터 최종 인증서까지 검증한다.
- HTTPS, 코드 서명, 이메일 암호화 등 다양한 분야에 사용된다.

PKI의 핵심은 신뢰다. CA를 신뢰하고, CA는 인증서 소유자의 신원을 확인한다. 이 신뢰 체계가 인터넷 보안의 기반이다.

하지만 중앙화된 신뢰 모델은 단점도 있다. CA가 손상되거나 잘못된 인증서를 발급할 수 있다. Certificate Transparency 같은 메커니즘으로 이를 완화하려 하지만, 근본적인 한계는 남는다.

GPG의 Web of Trust는 탈중앙화된 대안이지만, 확장성과 사용성에서 PKI에 비해 떨어진다. 현실적으로 대규모 시스템에는 PKI가 더 적합하다.

결국 완벽한 시스템은 없다. PKI는 현재로서는 가장 실용적인 해결책이다.

---

참고

- <https://en.wikipedia.org/wiki/Public_key_infrastructure>
- <https://letsencrypt.org/how-it-works/>
- <https://certificate.transparency.dev/>
- <https://www.rfc-editor.org/rfc/rfc5280> (X.509)
- <https://www.rfc-editor.org/rfc/rfc8555> (ACME)
- <https://www.cloudflare.com/learning/ssl/what-is-pki/>
