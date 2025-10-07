
## 해시 함수

- 해시 함수는 데이터를 입력으로 받고 고유한 바이트 문자열을 생성한다. 출력을 다이제스트, 혹은 해시라고 한다.
- 해시의 특징 3가지가 있다.
  - 역상 저항성(Preimage resistance): 역상(`Preimage == y`) 추측에 저항하는(Resistance) 성질
    - 최초, 해시값(y)이 확인된 상태
    - 입력값(x)을 찾는 것은 계산적으로 불가능
  - 제2 역상 저항성(Second preimage resistance): 역상 추측에 저항하는 성질
    - 최초, 입력값(x)이 확인된 상태
    - 동일한 해시값(y)이 나오는 다른 입력값(x')을 찾는 것은 계산적으로 불가능
  - 충돌 저항성(Collision resistance): 서로 다른 입력값 추측에 저항하는 성질.
    - 서로 다른 입력값은 동일한 해시값을 생성(Collision)

- 아래와 같은 openssl 명령으로 파일의 해시를 얻을 수 있다.

   ```bash
   $ openssl dgst -sha256 tmp
   SHA2-256(tmp)= e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
   ```

- 해시 다이제스트의 크기 (생일 문제)
  - 한 방에 여러 사람이 있을 때, 최소 50%의 확률로 두 사람이 같은 생일을 가지려면, 단 23명만 무작위로 선출하면 된다.
  - 이처럼, 2^n가지 가능성이 있는 공간에서 문자열을 무작위로 생성할 때, 약 2^n/2의 문자열만 생성해보면 50% 확률로 충돌이 발생할 수 있다. (동일한 다이제스트가 나올 수 있다)
  - 그렇기에 해시에서도 이처럼 128비트의 보안으로 충돌을 피하려면 대략 256비트의 다이제스트를 생성해야한다.

- **SHA-2**
  - 여러 버전이 있다 (SHA-224, SHA-256, SHA-384, SHA-512, SHA-512/224, SHA-512/256)
  - 오늘날 SHA-256가 주로 사용된다.
  - SHA-2는 압축 함수를 반복적으로 호출하여 메시지를 해시하는 머클-담고르 구조이다.
  - 압축함수: 몇 개의 데이터를 받고 더 적은 데이터를 반환하는 함수
  - 동작 과정:
    1. 해시하려는 입력에 패딩을 적용한 다음 입력을 압축 함수에 맞는 블록으로 자른다.
    2. 압축 함수의 이전 출력을 압축 함수에 대한 두 번째 인수로 사용하여 압축 함수를 메시지 블록에 반복적으로 적용한다. 최종 출력이 다이제스트가 된다.
  - 길이 확장 공격(length extension attack)에 취약하다.
    - 공격자가 해시값 H(m)과 메시지 m의 길이를 알 때, m의 내용을 모르더라도 H(m || padding || m')을 계산할 수 있다.

- **SHA-3**
  - 여러 버전이 있다. (SHA-3-224, SHA-3-256, SHA-3-384, SHA-3-512)
  - SHA-3는 스펀지 구조(sponge construction)로 제작되었다.
  - 입력을 받아 동일한 크기의 출력을 반환하는 Keccak-f라는 순열을 기반으로 한다.
  - 동작 과정:
    1. 입력과 출력을 r(rate)부분과 c(capacity) 부분으로 임의로 나눈다.
       - (버전마다 다른 파라미터를 사용한다. c는 비밀로 취급해야하며 c가 클수록 스펀지 구조가 더 안전하다고 한다.)
    2. 순열 입력의 r과 입력을 XOR한다.
    3. 마지막 상태의 r을 사용한다.
  - 길이 확장 공격에 면역이다.

- SHA-2, SHA-3은 고정 길이만 출력할 수 있는데 반해 임의의 길이의 출력을 생성할 수 있는 함수를 SHA-3에서 XOF로 정의하고 조프로 발음한다.
- SHAKE, cSHAKE 두개의 표준화된 XOF가 있다.

- **SHAKE**
  - SHAKE128과 SHAKE256 두 가지 버전이 있다.
  - 기본적으로 SHA-3와 구조가 동일하지만 속도가 더 빠르며 짜내기 단계에서 원하는 만큼 순열 연산을 할 수 있다.

- **cSHAKE (customizable SHAKE)**
  - SHAKE의 확장 버전으로 사용자 정의가 가능하다.
  - 함수 이름과 custom 문자열을 입력으로 받아 도메인 분리를 제공한다.

  - TupleHash: cSHAKE를 기반으로 하고 cSHAKE와 동일한 표준(NIST SP 800-185)으로 지정된 함수이다.
    - 값 목록을 해시할 때, 단순하게 나열한 string대로 해싱하면 `hash("abc" || "d")`와 `hash("ab" || "cd")` 처럼 서로 다른 값이 같아질 수 있다
    - 따라서`TupleHash(["abc", "d"]) = cSHAKE([3, "abc", 1, "d"])`처럼 각 함목의 글자 수를 함께 해싱하는 방식이며, 상황에 따라 유요하게 쓸 수 있다.

---

## MAC(message authentication code)

- 동일한 키를 공유하는 하나 이상의 당사자가 메시지의 무결성과 신뢰성을 확인할 수 있도록 하는 대칭 암호학 알고리즘이다. 해시함수 비밀키 있는 버전이다.
  - 메시지 및 관련 인증 태그의 신뢰성을 확인하기 위해 메시지의 인증 태그와 비밀 키를 다시 계산한 다음 두 인증 태그를 비교한다. 두 인증 태그가 서로 다르면 메시지가 변조된 것이다.
  - 수신된 인증 태그와 계산된 인증 태그를 항상 상수 시간에 비교해야 한다.

- 대부분의 실용적 MAC은 PRF(Pseudorandom Function) 구조를 가지고 있다
  - PRF는 키를 입력으로 받아 무작위처럼 보이는 출력을 생성하는 함수이다. 실제로는 결정론적(deterministic)이지만 출력이 진짜 무작위 함수와 구분할 수 없어야 한다.
  - PRF는 키 유도 함수(KDF), 스트림 암호, 블록 암호 등 다양한 암호학적 응용에 사용된다.

- 주의해야할 문제

  - 리플레이 공격의 위험 있음
    - 카운터를 추가해 대응 가능
    - 카운터가 증가하지 않은, 똑같은 요청 그대로 보내면 유효하지 않은 것으로 판단
    - 카운터는 고정 길이로 사용해야함. 가변 길이라면 카운터 1인 메세지를 바탕으로 11을 유추할 수 있기 때문

  - 주기적 인증 태그 검증
    - 수신한 인증 태그와 계산한 인증 태그의 비교는 상수 시간에 이뤄져야함.
    - 답변이 늦으면 '앞쪽까지는 일치하는군'하며 유추할 수 있기 때문

- **HMAC (Hash-based Message Authentication Code)**

  - HMAC은 해시 함수를 기반으로 한 MAC 알고리즘으로, 가장 널리 사용되는 MAC 구조이다.
  - RFC 2104에 정의되어 있으며 모든 암호학적 해시 함수와 함께 사용할 수 있다. 하지만 대부분 SHA-2와 함께 사용된다.
  - 구조:
  - 두 번의 해시 연산을 수행한다. 따라서 길이 확장 공격에 면역이다.
  - `HMAC(K, m) = H((K ⊕ opad) || H((K ⊕ ipad) || m))`
    - K: 비밀 키
    - m: 메시지
    - H: 해시 함수 (SHA-256, SHA-512 등)
    - ipad: 내부 패딩 (0x36을 반복)
    - opad: 외부 패딩 (0x5c를 반복)

  ```
  # OpenSSL로 HMAC 생성
  $ echo -n "message" | openssl dgst -sha256 -hmac "secret-key"
  HMAC-SHA256(stdin)= 8b5f48702995c1598c573db1e21866a9b825d4a794d169d7060a03605796360b
  ```

- **KMAC (Keccak Message Authentication Code)**

  - KMAC은 SHA-3의 스펀지 구조를 기반으로 한 MAC 알고리즘이다. NIST SP 800-185에 정의되어 있으며, cSHAKE를 기반으로 구현되었다.

  - 가변 길이 출력을 지원한다. (XOF 기능)
  - 커스텀 문자열(customization string)을 지원하여 도메인 분리가 가능하다.
  - HMAC보다 더 간단한 구조로 구현되어 있다.
  
      ```python
      # Python cryptography 라이브러리 예시
      from hashlib import shake_256
              
      def kmac256(key, data, length, custom=b''):
          # KMAC256의 간소화된 개념적 구현
          # 실제로는 cSHAKE256 기반으로 구현됨
          pass
      ```

### HKDF (HMAC-based Extract-and-Expand Key Derivation Function)

- HKDF는 HMAC을 기반으로 한 키 유도 함수(KDF)로, 하나의 키 자료로부터 여러 암호학적 키를 안전하게 유도한다.
- RFC 5869에 정의되어 있으며, TLS 1.3 등에서 표준으로 사용된다.
- 약한 엔트로피 소스로부터 강력한 키를 유도할 수 있다.
- Info 파라미터를 통한 도메인 분리로 키 재사용 공격을 방지한다.

- 파라미터
  - IKM (Input Keying Material): 초기 키 자료 (예: Diffie-Hellman 공유 비밀)
  - Salt: 선택적 랜덤 값으로 키 자료의 엔트로피를 강화한다.
  - Info: 응용 프로그램별 컨텍스트 정보로 도메인 분리를 제공한다.
  - Length: 출력 키 자료의 길이

- 동작 흐름
  - Extract: 입력 키 자료(IKM)에서 고정 길이의 의사 난수 키(PRK)를 추출한다.
    - `PRK = HMAC(salt, IKM)`
  - Expand: PRK로부터 원하는 길이의 출력 키 자료(OKM)를 확장한다.
    - `OKM = HMAC(PRK, info || counter)`

  ```python
  from cryptography.hazmat.primitives import hashes
  from cryptography.hazmat.primitives.kdf.hkdf import HKDF
  
  # 마스터 키로부터 여러 키 유도
  hkdf = HKDF(
      algorithm=hashes.SHA256(),
      length=32,
      salt=b'optional-salt',
      info=b'application-specific-context',
  )
  derived_key = hkdf.derive(b'master-key-material')
  ```

---
참고

- 리얼월드 암호학 - 데이비드 웡 저 임지순 역
- <https://www.fortinet.com/resources/cyberglossary/message-authentication-code>
- <https://en.wikipedia.org/wiki/Message_authentication_code>
- <https://www.rfc-editor.org/rfc/rfc5869>
- <https://en.wikipedia.org/wiki/HKDF>
- <https://en.wikipedia.org/wiki/Extendable-output_function>
