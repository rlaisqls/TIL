
## DH 키교환 (Diffie–Hellman key exchange)

- 1976년 Whitfield Diffie와 Martin E. Hellman이 <New Direction in Cryptograhy>라는 제목의 논문으로 발표한 키 교환 알고리즘
- 곱셈군에서의 이산로그문제를 기반으로 함

- 이산로그 문제
  - gˣ ≡ h (mod p)를 만족하는 지수 x를 찾는 문제
  - e.g. 2 = 3ˣ mod 5를 만족하는 x는 3

- 키 쌍을 생성하는 방법
  1. 모든 참가자는 큰 소수 p와  생성원 g에 동의해야 한다.
  2. 각 참가자는 비밀 키가 되는 난수 x를 생성한다.
  3. 각 참가자는 공개 키를 gˣ mod p와 같이 파생한다.

- 동작
  - 앨리스는 비밀키 a와 A = g^a mod p를 가지고 있다.
  - 밥은 비밀키 b와 공개키 B = g^b mod p를 가지고 있다.
  
  - 공유 비밀은 g^ab mod p. 밥의 공개키를 알고 있는 앨리스는 공유 비밀을 B^a mod p로 계산할 수 있다. (밥도 마찬가지)
    - CDH(Computational Diffie-Hellman assumption): 공개키 g^a mod p, g^b mod p를 관찰하는 것이 g^ab mod p를 계산하는데 도움이 되지 않는다는 가정
    - DDH(Desisional Diffie-Hellman assumption): g^a mod p, g^b mod p, z mod p가 주어졌을 때 후자의 요소가 g^ab mod p인지 임의 요소인지 확정할 수 없다는 가정

- DLP가 어려운 이유는 대소 관계의 불규칙성 때문이다. 이러한 계산적 어려움이 Diffie-Hellman, ElGamal 등의 암호 알고리즘의 안전성 기반이 된다.

  - 실수에서는 a > b이면 logₐ a > logₐ b가 성립
  - 유한체에서는 이러한 대소 관계가 보장되지 않음
  - gˣ mod p의 값은 x가 증가해도 불규칙하게 분포

  - 예시: 2ˣ (mod 13)

    ```
    | x | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
    |---|---|---|---|---|---|---|---|---|---|-----|-----|-----|
    | 2ˣ | 2 | 4 | 8 | 3 | 6 | 12 | 11 | 9 | 5 | 10 | 7 | 1 |
    ```

  - x가 증가해도 2ˣ mod 13의 값은 규칙 없이 분산되어 있다. 암호에서 사용하는 큰 소수 p (예: 2²⁰⁴⁸)의 경우:

  - 탐색 공간: 약 10⁶¹⁹개의 정수
  - 최선의 알고리즘(Pohlig-Hellman): O(√n) 시간 복잡도
  - 2²⁰⁴⁸의 제곱근도 2¹⁰²⁴ > 10³⁰⁰으로 실질적으로 계산 불가능

## ECDH 키교환 (Elliptic curve Diffie–Hellman key exchange)

타원곡선 암호는 일반 DLP 대신 타원곡선 위의 점 연산을 사용한다:

- **일반 DLP**: gˣ ≡ h (mod p)에서 x 찾기
- **ECDLP**: Q = xP (타원곡선 위의 점)에서 x 찾기

### secp256k1

비트코인은 secp256k1 곡선을 사용한다.

- 공개키 암호를 위한 타원 곡선은 다음 매개변수로 정의된다.
  - 곡선 y² = x³ + ax + b에서의 a와 b
  - 유한체의 위수인 소수 p
  - 생성점 G의 x좌표 x, y
  - G로 생성한 군의 위수

- 이 중 비트코인은 secp2561 곡선을 사용한다. 해당 곡선의 매개변수는 다음과 같다.
  - a=0, b=7 (y² = x³+7)
  - p = 2^256 - 2^32 - 977
  - G = (0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798, 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8)
  - n = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141

---

참고

- 밑부터 시작하는 비트코인 (Programming Bitcoin by Jimmy Song, O'Reilly)
- 리얼월드 암호학 - 데이비드 웡 저 임지순 역
