
SSL 인증서 형식은 다양하지만, 모두 ASN.1(Abstract Syntax Notation 1) 형식 데이터를 기계가 읽을 수 있는 방식으로 인코딩하는 방법의 차이임. x509 인증서도 이 형식으로 정의됨.

기본 개념:
- ASN.1: 데이터 구조를 정의하는 표준 표기법
- X.509: ASN.1로 정의된 공개키 인증서 표준
- DER (Distinguished Encoding Rules): ASN.1을 바이너리로 인코딩하는 규칙
- PEM: DER을 Base64로 인코딩하고 평문 앵커 라인 추가

`.csr` (Certificate Signing Request):
- 인증서 서명 요청 파일
- 실제 형식은 RFC 2986에 정의된 PKCS10
- 인증 기관에 제출하기 위해 일부 애플리케이션에서 생성 가능
- 요청된 인증서의 주체, 조직, 상태 등 주요 세부 정보와 서명할 공개 키 포함
- CA에서 서명하고 인증서 반환
- 반환된 인증서는 공개 인증서(공개 키 포함, 개인 키 미포함)이며 여러 형식 가능

`.pem`:
- PEM 자체는 인증서가 아니라 데이터 인코딩 방식
- X.509 인증서가 PEM으로 인코딩되는 대표적 데이터 유형
- X.509 인증서(구조는 ASN.1로 정의)를 ASN.1 DER로 인코딩한 후 Base64 인코딩하고 평문 앵커 라인(BEGIN CERTIFICATE와 END CERTIFICATE) 사이에 배치
- RFC 1422(1421~1424 시리즈의 일부)에 정의
- 공개 인증서만 포함하거나(Apache 설치의 경우, CA 인증서 파일 /etc/ssl/certs), 공개 키, 개인 키, 루트 인증서를 포함한 전체 인증서 체인 포함 가능
- PKCS10 형식을 PEM으로 변환할 수 있어 CSR도 인코딩 가능
- 이름은 Privacy Enhanced Mail(PEM)에서 유래, 실패한 보안 이메일 방법이었지만 컨테이너 형식은 살아남음
- x509 ASN.1 키의 base64 변환
- RFC에 의해 관리, 텍스트 기반이므로 변환/전송 오류에 덜 취약해 오픈소스 소프트웨어에서 선호
- 다양한 확장자 가능(`.pem`, `.key`, `.cer`, `.cert` 등)

`.key`:
- 일반적으로 PEM 형식 파일로 특정 인증서의 개인 키만 포함
- 관례적 이름일 뿐 표준화된 이름 아님
- Apache 설치에서 /etc/ssl/private에 자주 위치
- 파일 권한이 매우 중요하며, 잘못 설정되면 일부 프로그램에서 인증서 로드 거부

`.pkcs12` `.pfx` `.p12`:
- RSA의 PKCS(Public-Key Cryptography Standards)에서 정의
- "12" 변형은 Microsoft에서 향상시켰으며 나중에 RFC 7292로 제출
- 공개 및 개인 인증서 쌍을 모두 포함하는 비밀번호 보호 컨테이너 형식
- `.pem` 파일과 달리 완전히 암호화됨
- 평문 PEM 형식보다 향상된 보안 제공
- 개인 키 및 인증서 체인 자료 포함 가능
- Windows 시스템에서 선호
- OpenSSL로 공개 및 개인 키를 포함한 `.pem` 파일로 변환 가능: `openssl pkcs12 -in file-to-convert.p12 -out converted-file.pem -nodes`
- openssl로 PEM 형식으로 자유롭게 변환 가능

`.der`:
- ASN.1 구문을 바이너리로 인코딩하는 방법
- .pem 파일은 Base64로 인코딩된 .der 파일
- PEM의 상위 형식, base64 인코딩된 PEM 파일의 바이너리 버전으로 생각하면 유용
- OpenSSL로 .pem으로 변환 가능: `openssl x509 -inform der -in to-convert.der -out converted.pem`
- Windows에서 인증서 파일로 인식
- Windows는 기본적으로 다른 확장자를 가진 .DER 형식 파일로 인증서 내보냄
- Windows 외부에서는 일반적으로 많이 사용 안됨

`.cert` `.cer` `.crt`:
- 다른 확장자를 가진 `.pem`(또는 드물게 `.der`) 형식 파일
- Windows Explorer에서 인증서로 인식됨 (.pem은 인식 안됨)

`.p7b` `.keystore`:
- RFC 2315에 PKCS 번호 7로 정의
- Windows에서 인증서 교환에 사용되는 형식
- Java에서 기본적으로 이해하며 종종 .keystore 확장자 사용
- `.pem` 스타일 인증서와 달리 인증 경로 인증서를 포함하는 정의된 방법 있음
- Java에서 사용하고 Windows에서 지원하는 개방형 표준
- 개인 키 자료 미포함

`.crl`:
- 인증서 폐기 목록(Certificate Revocation List)
- 인증 기관에서 만료 전 인증서를 무효화하는 방법으로 생성
- CA 웹사이트에서 다운로드 가능

요약:

인증서와 구성 요소를 제시하는 네 가지 주요 방법:
- PEM: RFC에 의해 관리, 텍스트 기반이므로 변환/전송 오류에 덜 취약, 오픈소스 소프트웨어에서 선호, 다양한 확장자 가능
- PKCS7: Java에서 사용하고 Windows에서 지원하는 개방형 표준, 개인 키 자료 미포함
- PKCS12: Microsoft 비공개 표준이었으나 나중에 RFC로 정의, 평문 PEM 형식보다 향상된 보안 제공, 개인 키 및 인증서 체인 자료 포함 가능, Windows 시스템에서 선호, openssl로 PEM 형식으로 자유롭게 변환 가능
- DER: PEM의 상위 형식, base64 인코딩된 PEM 파일의 바이너리 버전, Windows 외부에서는 일반적으로 많이 사용 안됨

---

참고:
- https://stackoverflow.com/questions/991758/openssl-pem-key
- https://gist.github.com/kirilkirkov/4c73da883088b6ff7420c49af1561b2b
