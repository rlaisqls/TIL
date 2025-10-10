
- 비트코인 스크립트는 트랜잭션 출력의 사용 조건을 정의하는 스택 기반 프로그래밍 언어이다.
- ScriptPubKey와 ScriptSig 모두 같은 방식으로 파싱된다.
- 파싱을 시작하고 처음 읽은 한 바이트 값이 n이고 이 값이 `0x01`~`0x4b`(1~75) 사이의 값이면 n바이트 길이만큼 이어서 읽은 숫자를 한 원소로 간주한다. 그렇지 않으면 그 바이트 값은 오피 코드를 의미한다. [연산자, 오피코드 대응 표](https://en.bitcoin.it/wiki/Script)

- 비트코인의 스크립트에선 반복문을 허용하지 않는다. (튜링 완전하지 않다.)
  - 튜링 완전한 스마트 계약 언어인 Solidity를 이용하는 이더리움은 gas라는 단위를 프로그램 실행 대가로 지불하도록 강제하여 해결한다.

- 거래를 하기 위해선 이전 트랜잭션의 해제 스크립트(ScriptPubKey)로 코인을 해제 후, 이번 트랜잭션의 잠금 스크립트(ScriptSig)로 잠가야 한다. 따라서 이전 트랜잭션 정보를 가져와야한다.

- 비트코인에서 해제 스크립트는 잠금 스크립트와 분리되어 실행된다. 이는 해제 스크립트가 잠금 스크립트 실행에 영향을 주지 않도록 하기 위해서이다. 결합하여 실행하는 경우, 해제 스크립트에서 잠금하지 않고 return 1하여 종료되는 허점이 생긴다.

인증키 등을 이용한 표준 스크립트 뿐만 아니라, 덧셈 문제를 푸는 등의 잠금/해제 스크립트를 작성하는 것도 가능하다.

- 일례로 Peter Todd가 해시 충돌을 찾은 사람이 가져갈 수 있도록 잠근 비트코인이 있다.
- 구글이 2017년 2월 SHA-1에 대한 해시 충돌을 찾았고, 이외 SHA에 대한 해시 충돌을 찾으면 해제할 수 있는 비트코인도 있다.
- 참고
  - <https://bitcointalk.org/index.php?topic=293382>
  - <https://security.googleblog.com/2017/02/announcing-first-sha1-collision.html>

### P2PK (Pay to Public Key)

비트코인 초기에 널리 사용된 가장 단순한 형태의 스크립트이다.

- ECDSA 서명 공개키로 보내고, 비밀키 소유자는 서명을 통해 비트코인을 해제하고 사용할 수 있다.

- 스크립트
  - ScriptSig: `<signature>`
  - ScriptPubKey: `<pubkey> OP_CHECKSIG`
    - `OP_CHECKSIG`는 앞의 2개 원소를 꺼내어 공개키로 서명이 올바른지 확인한다.
    - 서명이 올바르면 스택 위에 1을, 아니면 0을 올린다.

- 초기 IP to IP 지불이나 채굴 비트코인이 있는 출력에 사용되었다. 하지만 IP to IP 지불 시스템은 MITM 공격에 취약해 점차 사용하지 않게 되었다.
- 사람간의 거래에선 공개키의 길이가 길어 불편하고, UTXO 집합의 크기를 많이 차지한다는 단점이 있다.

### P2PKH (Pay to Public Key Hash)

P2PK 스크립트 대비 짧은 주소를 사용하고, hash160으로 추가 보호한다는 장점이 있다.

- SEC 형식 공개키가 잠금 스크립트가 아닌 해제 스크립트에 있다는 차이가 있다.
  - P2PK는 ScriptPubKey에 공개키가 직접 노출되어 블록체인에 영구적으로 기록되지만, P2PKH는 코인을 사용하는 시점(ScriptSig)까지 공개키가 드러나지 않는다.
  - 양자 컴퓨터의 Shor's algorithm은 공개키로부터 개인키를 계산할 수 있는데, P2PKH에서는 사용하지 않은 UTXO의 경우 공개키가 노출되지 않아 양자 컴퓨터 공격에 대한 시간적 여유를 확보할 수 있다.
  - 공격자가 개인키를 얻으려면 먼저 hash160(SHA256 + RIPEMD160)을 역산하여 공개키를 찾고, 그 다음 ECDSA를 깨서 개인키를 찾아야 하는 이중 보호층이 있다.

- 스크립트
  - ScriptSig

    ```
    <signature>
    <publickey>
    ```

  - ScriptPubKey

    ```
    OP_DUP
    OP_HASH160
    <publickey hash>
    OP_EQUALVERIFY
    OP_CHECKSIG
    ```

- 주소 생성
  - Base58 인코딩, version 바이트 `0x00` (메인넷) / `0x6f` (테스트넷)
  - 해싱 대상: 압축 혹은 비압축 SEC 형식 공개키
  - 최종 주소: 메인넷 `1`, 테스트넷 `m` 또는 `n`으로 시작

- z 계산 및 검증
  - 서명 생성 시 z 계산
    1. 현재 트랜잭션의 모든 입력 ScriptSig를 빈 값으로 교체
    2. 현재 입력의 ScriptSig만 이전 출력의 ScriptPubKey로 교체
       - `OP_DUP OP_HASH160 <pubkey hash> OP_EQUALVERIFY OP_CHECKSIG`
    3. 수정된 트랜잭션을 이중 SHA-256 해시하여 z 생성
  - 검증 시: `OP_CHECKSIG`가 동일한 방식으로 z를 재계산하고 서명 검증

### P2MS (Pay to Multi-Signature)

여러 공개키로 비트코인을 잠그고, 그 중 일부(또는 전부)의 서명을 요구하여 잠금을 해제하는 스크립트이다.

- m-of-n 표기법을 사용한다. (예: 2-of-3는 3개의 공개키 중 2개의 서명이 필요함)

- 스크립트 (2-of-3 multisig 예시)
  - ScriptSig

    ```
    OP_0
    <signature1>
    <signature2>
    ```

    - `OP_CHECKMULTISIG`는 많은 서명과 공개키를 가져와 유효한 서명의수가 기준 이상인지 여부는 1, 0으로 반환하는 명령어이다.
      - 스택 원소를 m+n+2개보다 한 개 더 가져오도록 (off-by-one) 잘못 구현되어 있어서 더미 값(`OP_0`)을 넣어줘야 한다. 이 원소가 실제로 계산에 사용되지는 않는다.

  - ScriptPubKey

    ```
    OP_2
    <pubkey1>
    <pubkey2>
    <pubkey3>
    OP_3
    OP_CHECKMULTISIG
    ```

- 블록체인에서 P2MS를 직접 사용하는 것은 드물며, 대부분 P2SH나 P2WSH로 래핑되어 사용된다.
- 노드 중계를 위해 최대 3개의 공개키로 제한된다.

### P2SH (Pay to Script Hash)

P2MS(다중 서명)는 여러 공개키를 ScriptPubKey에 직접 포함해야 하므로 스크립트가 매우 길어진다. P2SH는 복잡한 스크립트를 20바이트 해시로 압축하여 이러한 문제를 해결한다.

- BIP16에서 도입되었으며, 2012년 4월 1일부터 활성화되었다.

- 스크립트
  - ScriptSig

    ```
    <signature1>
    <signature2>
    <redeemScript>
    ```

    - 실제 스크립트 로직이 포함된 redeemScript를 제공해야 한다.
    - redeemScript는 송금받을 때 공개되지 않고, 코인을 사용할 때 공개된다.

  - ScriptPubKey

    ```
    OP_HASH160
    <redeemScriptHash>
    OP_EQUAL
    ```

    - redeemScript를 hash160으로 해시한 값만 저장한다.

- 주소 생성
  - Base58 인코딩, version 바이트 `0x05` (메인넷) / `0xc4` (테스트넷)
  - 해싱 대상: redeemScript
  - 최종 주소: 메인넷 `3`, 테스트넷 `2`로 시작
  - 주소만으로는 내부 스크립트 종류를 알 수 없음 (multisig, P2WPKH 등)

- 검증 방식
  - ScriptPubKey가 `OP_HASH160 <20바이트 해시> OP_EQUAL` 패턴이면 P2SH로 인식한다.
  - 2단계 검증을 수행한다.
    1. 해시 검증: ScriptSig의 마지막 원소(redeemScript)를 hash160으로 해시하여 ScriptPubKey의 해시값과 일치하는지 확인
    2. 스크립트 실행: 일치하면 redeemScript를 역직렬화하여 나머지 ScriptSig 원소들과 함께 실행
  - 두 단계 모두 통과해야 트랜잭션이 유효하다.

- z 계산 및 검증
  - 서명 생성 시 z 계산
    1. 현재 트랜잭션의 모든 입력 ScriptSig를 빈 값으로 교체
    2. 현재 입력의 ScriptSig만 redeemScript로 교체
       - 예: 2-of-3 multisig의 경우 `OP_2 <pubkey1> <pubkey2> <pubkey3> OP_3 OP_CHECKMULTISIG`
    3. 수정된 트랜잭션을 이중 SHA-256 해시하여 z 생성
  - 검증 시: redeemScript 내부의 `OP_CHECKSIG` (또는 `OP_CHECKMULTISIG`)가 동일한 방식으로 z를 재계산하고 서명 검증

- redeemScript의 최대 크기는 520바이트로 제한, 스크립트 실행 시 스택 원소는 최대 201개로 제한된다.
- 반복문을 방지하기 위해 P2SH는 중첩될 수 없다. (P2SH 안에 또 다른 P2SH를 넣을 수 없음)

## Segwit (Segregated Witness)

세그윗은 segregated witness의 약자로 비트코인 네트워크에서 2017년 활성화된 소프트포크이다.

- 수학에서 witness는 어떤 조건을 만족하는 수의 존재를 증명할 때 그러한 수의 예로 들 수 있는 특정 값을들 말한다. 암호학의 맥락에서 보면 서명이나, 공개키 등을 witness라고 할 수 있다. 왜냐하면 각각 서명 검증 조건식과 공개키 암호 조건식을 만족하는 특정값이기 때문이다.
- Segregated witness는 이러한 witness에 해당하는 서명이나 공개키를 스크립트에서 분리하여 떼어놓는다(segregation)는 의미이다.

트랜잭션 직렬화 형식

- 일반 트랜잭션: `[Version 4byte][Input count][Inputs]...[Outputs]...[Locktime 4byte]`
- Segwit 트랜잭션: `[Version 4byte][Marker 0x00][Flag 0x01][Input count][Inputs]...[Outputs]...[Witness]...[Locktime 4byte]`
- Version(4바이트) 다음의 **5번째 바이트가 marker** `0x00`이고, 6번째 바이트가 flag `0x01`이다.
- 이 marker와 flag로 노드는 segwit 트랜잭션임을 인식하고 witness 데이터를 파싱한다.
- marker와 flag는 트랜잭션 해시(TXID) 계산에 포함되지 않는다.

Segwit의 효과

- 트랜잭션이 작아져 블록 크기가 증가
- Transaction malleability(가변성) 문제 해결
  - 트랜잭션 의미는 유지하면서 트랜잭션 ID가 변경될 수 있는 성질을 말한다. 라이트닝 네트워크에서 가장 작은 단위인 결제 채널을 만들 때 트랜잭션 ID가 변할 수 있다는 사실은 중요한 고려 사항이다. 트랜잭션 ID가 변할 수 있으면 결제 채널을 안전하게 만드는 것이 어려워진다.
  - 서명을 다시 생성하지 않고 조작 가능한 유일한 필드는 각 입력에 있는 해제 스크립트이기 때문에,
    - 트랜잭션 ID가 변경될 수 있다는 것은 **해제 스크립트가 변경될 수 있다**는 의미이다.
    - 예를 들어, 서명 생성시 얻은 `(r, s)`와 `(r, -s)`가 모두 유효한 서명이기에 가변성 문제가 발생한다. 각 노드에서는 일단 s와 -s 중 N/2보다 작은 것을 취해서 문제를 해결한다. 또한, `OP_CHECKMULTISIG`의 off-by-one 버그도 가변성 문제를 야기한다.
  - 이는 트랜잭션 ID가 고정되지 않은 결제 체널에서 문제가 된다. (블록체인에 들어가면 트랜잭션 ID가 고정되므로 상관없다.)
  - 증인필드는 트랜잭션 해싱에 들어가지 않는 필드이므로, **해제 스크립트가 변경되어도 ID가 변경되지 않게 된다**.
- Quadratic hashing(이차 해싱) 문제 해결
- 오프라인 지갑 수수료 계산의 보안 강화

## Segwit v0 스크립트 타입

### P2WPKH (Pay to Witness Public Key Hash)

Segwit의 가장 기본적인 트랜잭션 형식이다.

- [BIP0141](https://github.com/bitcoin/bips/blob/master/bip-0141.mediawiki)과 [BIP0143](https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki)에서 정의되었다.
- P2PKH의 segwit 버전으로, 서명과 공개키를 witness 필드로 분리한 형태이다.

- 스크립트
  - ScriptSig: `(empty)`
    - witness 필드로 분리되어 ScriptSig는 비어있다.

  - ScriptPubKey

    ```
    OP_0
    <20-byte pubkey hash>
    ```

    - `OP_0`은 witness version 0을 의미한다.
    - 20바이트 공개키 해시가 뒤따른다.

  - Witness

    ```
    <signature>
    <pubkey>
    ```

    - 서명과 공개키가 witness 필드에 위치한다.
    - 이 데이터는 트랜잭션 ID 계산에 포함되지 않는다.

- 주소 생성
  - Bech32 인코딩 사용 ([BIP0173](https://github.com/bitcoin/bips/blob/master/bip-0173.mediawiki))
  - 해싱 대상: 공개키를 hash160 → 20바이트
  - HRP(Human Readable Part): 메인넷 `bc`, 테스트넷 `tb`
  - Witness version 0 + 20바이트 해시를 5비트 그룹으로 변환 후 Bech32 체크섬 추가
  - 최종 주소: `bc1q` 또는 `tb1q`로 시작 (예: `bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4`)
  - Base58 대비 장점: 대소문자 구분 없음, 오류 검출 우수, QR 코드 효율성 향상

- z 계산 및 검증
  - 서명 생성 시 z 계산 (BIP0143 서명 해싱)
    - P2PKH와 달리 더 효율적인 해싱 방식을 사용한다.
    - 각 입력마다 모든 이전 출력을 다시 해싱하지 않고, 한 번만 해싱한다.
    - 계산 복잡도가 O(n²)에서 O(n)으로 개선된다.
    - 주요 해시 컴포넌트
      1. `hashPrevouts`: 모든 입력의 outpoint를 이중 SHA-256 해시
      2. `hashSequence`: 모든 입력의 sequence를 이중 SHA-256 해시
      3. `hashOutputs`: 모든 출력을 이중 SHA-256 해시
    - 최종 z는 이러한 컴포넌트들과 현재 입력 정보를 결합하여 생성
  - 검증 시: witness 필드의 서명과 공개키를 사용하여 동일한 방식으로 검증

### P2WSH (Pay to Witness Script Hash)

P2WSH는 P2SH의 Segwit 버전으로, 복잡한 스크립트를 32바이트 해시로 압축하는 스크립트이다.

- [BIP0141](https://github.com/bitcoin/bips/blob/master/bip-0141.mediawiki)에서 정의되었다.
- P2SH와 유사하지만 witness 필드를 사용하여 트랜잭션 가변성 문제를 해결한다.

- 스크립트
  - ScriptSig: `(empty)`
    - witness 필드로 분리되어 ScriptSig는 비어있다.

  - ScriptPubKey

    ```
    OP_0
    <32-byte script hash>
    ```

    - `OP_0`은 witness version 0을 의미한다.
    - 32바이트 스크립트 해시가 뒤따른다. (P2SH의 20바이트와 다름)

  - Witness

    ```
    <signature1>
    <signature2>
    ...
    <witnessScript>
    ```

    - witnessScript가 witness 필드의 마지막 원소로 위치한다.
    - witnessScript는 P2SH의 redeemScript와 유사한 역할을 한다.

- 주소 생성
  - Bech32 인코딩 사용
  - 해싱 대상: witnessScript를 SHA-256으로 해시 → 32바이트
  - 최종 주소: `bc1q`로 시작 (메인넷)
  - P2WPKH보다 긴 주소 (witnessScript 해시가 32바이트)

- 검증 방식
  - 2단계 검증 수행
    1. 해시 검증: witness 필드의 마지막 원소(witnessScript)를 SHA-256으로 해시하여 ScriptPubKey의 해시값과 일치하는지 확인
    2. 스크립트 실행: 일치하면 witnessScript를 역직렬화하여 나머지 witness 원소들과 함께 실행

- P2SH와의 차이점
  - witnessScript 크기 제한이 10,000바이트로 P2SH의 520바이트보다 훨씬 큼
  - SHA-256 사용 (P2SH는 hash160)
  - witness 필드 사용으로 트랜잭션 가변성 해결
  - 더 효율적인 수수료 구조

### P2SH-P2WPKH (Pay to Script Hash - Pay to Witness Public Key Hash)

P2WPKH를 P2SH로 래핑한 형태이다.

- 구형 지갑도 P2SH 주소로 segwit 출력에 송금할 수 있게 한다. 초기 Segwit 도입 시기에 널리 사용되었다.
  - 현재는 대부분의 지갑이 Segwit을 지원하므로 네이티브 P2WPKH 사용이 권장된다.
  - 하위 호환성이 중요한 경우에만 사용을 고려한다.

- 스크립트
  - ScriptSig: `<redeemScript>`
    - redeemScript는 `OP_0 <20-byte pubkey hash>`이다.
    - 실제 서명과 공개키는 witness 필드에 위치한다.

  - ScriptPubKey

    ```
    OP_HASH160
    <20-byte redeemScript hash>
    OP_EQUAL
    ```

    - P2SH 형식과 동일하다.
    - redeemScript를 hash160으로 해시한 값을 저장한다.

  - Witness

    ```
    <signature>
    <pubkey>
    ```

    - P2WPKH와 동일하게 서명과 공개키가 witness 필드에 위치한다.

- 주소 생성
  - P2SH와 동일한 Base58 인코딩 과정 사용
  - 해싱 대상: redeemScript (`OP_0 <20-byte pubkey hash>`)
  - 최종 주소: 메인넷 `3`, 테스트넷 `2`로 시작 (예: `3J98t1WpEZ73CNmYviecrnyiWrnqRhWNLy`)
  - 외부적으로는 일반 P2SH와 구분 불가능 (코인 사용 시 redeemScript 공개되어야 드러남)

- 검증 방식
  - 2단계 검증을 수행한다.
    1. P2SH 검증: ScriptSig의 redeemScript를 hash160으로 해시하여 ScriptPubKey의 해시값과 일치하는지 확인
    2. Segwit 검증: redeemScript가 `OP_0 <20-byte hash>` 패턴이면 witness 필드로 P2WPKH 검증 수행
  - 두 단계 모두 통과해야 트랜잭션이 유효하다.

- z 계산 및 검증
  - 서명 생성 시 z 계산
    - P2WPKH와 동일한 BIP0143 해싱 방식을 사용한다.
    - redeemScript(`OP_0 <20-byte pubkey hash>`)의 공개키 해시를 사용하여 z를 생성한다.
  - 검증 시: witness 필드의 데이터로 동일한 방식으로 z를 재계산하고 서명 검증

- 장점
  - 하위 호환성: 구형 지갑도 P2SH 주소로 송금 가능
  - Segwit 혜택: 트랜잭션 가변성 해결, 효율적인 해싱, 낮은 수수료

- 단점
  - P2WPKH보다 약간 큰 트랜잭션 크기 (redeemScript 포함)
  - 네이티브 P2WPKH보다 약간 높은 수수료
  - 2단계 검증으로 인한 추가 연산

- 사용 시기

### P2SH-P2WSH (Pay to Script Hash - Pay to Witness Script Hash)

P2WSH를 P2SH로 래핑한 형태이다.

- P2SH-P2WPKH와 유사하지만 복잡한 스크립트를 지원한다.

- 스크립트
  - ScriptSig: `<redeemScript>`
    - redeemScript는 `OP_0 <32-byte script hash>`이다.

  - ScriptPubKey

    ```
    OP_HASH160
    <20-byte redeemScript hash>
    OP_EQUAL
    ```

  - Witness

    ```
    <signature1>
    <signature2>
    ...
    <witnessScript>
    ```

- 주소 생성
  - P2SH 형식으로 메인넷 `3`으로 시작
  - 외부에서 일반 P2SH와 구분 불가능

## Taproot (Segwit v1)

Taproot는 2021년 11월 활성화된 비트코인의 주요 업그레이드로, witness version 1을 사용하는 새로운 스크립트 타입이다.

- [BIP340](https://github.com/bitcoin/bips/blob/master/bip-0340.mediawiki), [BIP341](https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki), [BIP342](https://github.com/bitcoin/bips/blob/master/bip-0342.mediawiki)에서 정의되었다.
- 핵심 아이디어는 키 경로(key path)와 스크립트 경로(script path) 지출을 하나의 출력 타입으로 통합하는 것이다.

- Schnorr 서명 방식을 도입하여 ECDSA를 대체한다.
  - 키 집계(key aggregation)로 여러 공개키를 하나로 결합할 수 있다.
  - 서명 크기가 64바이트로 ECDSA의 71-72바이트보다 작다.
  - 배치 검증으로 여러 서명을 한 번에 효율적으로 검증할 수 있다.

- MAST(Merkelized Alternative Script Tree)를 사용하여 복잡한 스크립트 조건을 머클 트리로 구성한다.
  - 실제 사용된 조건만 공개하여 프라이버시를 향상시킨다.
  - 스크립트 크기 제약이 완화된다.

- Tapscript는 Taproot 출력에서 사용되는 새로운 스크립트 버전이다.
  - `OP_CHECKSIGADD` 등 새로운 오피코드를 지원한다.
  - 미래 확장성을 위한 예약 비트를 포함한다.

### P2TR (Pay to Taproot)

- 스크립트
  - ScriptSig: `(empty)`
    - 완전한 Segwit 구조로 ScriptSig는 비어있다.

  - ScriptPubKey

    ```
    OP_1
    <32-byte taproot output>
    ```

    - `OP_1`은 witness version 1을 의미한다.
    - 32바이트 x-only 공개키 (또는 tweaked 공개키)를 사용한다.

  - Witness (키 경로 지출)

    ```
    <schnorr signature>
    ```

    - 단일 Schnorr 서명만 필요하다 (64바이트).

  - Witness (스크립트 경로 지출)

    ```
    <input1>
    <input2>
    ...
    <script>
    <control block>
    ```

    - script는 실제 실행할 Tapscript이다.
    - control block에는 머클 증명과 internal key 정보가 포함된다.

- 주소 생성
  - Bech32m 인코딩을 사용한다 ([BIP0350](https://github.com/bitcoin/bips/blob/master/bip-0350.mediawiki)).
  - 32바이트 x-only 공개키를 사용한다.
  - 최종 주소는 `bc1p`로 시작하며 (메인넷), 62자 길이이다.
  - 예: `bc1p0xlxvlhemja6c4dqv22uapctqupfhlxm9h8z3k2e72q4k9hcz7vqzk5jj0`

- Taproot 출력 생성
  - Internal key P를 선택한다 (32바이트 x-only). 단일 키 또는 여러 키의 집계를 사용할 수 있다.
  - Tapscript tree를 구성한다. 여러 스크립트를 머클 트리로 구성하며, 각 리프는 하나의 스크립트이다.
  - Tweak를 계산한다: `t = tagged_hash("TapTweak", P || merkle_root)`. Tagged hash는 도메인 분리를 제공한다.
  - Taproot output key를 생성한다: `Q = P + t·G`. Q가 ScriptPubKey에 들어가는 32바이트 공개키가 된다.

- 지출 방식
  - 키 경로 지출: internal key의 소유자가 단독으로 지출한다. Schnorr 서명 하나만 필요하며, 가장 효율적이고 프라이버시가 높다. 외부에서 스크립트 존재 여부를 알 수 없다.
  - 스크립트 경로 지출: Tapscript tree의 특정 스크립트를 사용한다. 해당 스크립트와 머클 증명을 제공하며, 사용된 스크립트만 공개된다. 다른 대안 스크립트는 비공개로 유지된다.

- Taproot의 장점
  - 프라이버시: 모든 출력이 동일한 형태(32바이트 공개키)로 보이며, 단일 서명과 멀티시그를 구분할 수 없다. 사용되지 않은 스크립트 조건은 비공개된다.
  - 효율성: Schnorr 서명으로 서명 크기가 감소하고, 키 경로 지출 시 최소한의 witness 데이터만 필요하다. 스크립트 경로도 필요한 부분만 공개한다.
  - 유연성: 복잡한 다중 조건 스크립트를 지원하고, 키 집계로 멀티시그를 효율화한다. 향후 확장 가능한 구조를 제공한다.
  - 비용: P2WPKH 대비 입력 비용이 약 15% 감소하며, 배치 검증으로 전체 네트워크 효율이 향상된다.

- 이전 버전과의 비교
  - P2PKH/P2SH는 witness version이 없고, `1` 또는 `3`으로 시작하는 주소를 사용하며, ECDSA 서명(71-72바이트)을 사용한다.
  - P2WPKH/P2WSH는 witness version 0(`OP_0`)을 사용하고, `bc1q`로 시작하는 주소를 사용하며, ECDSA 서명을 사용한다.
  - P2TR은 witness version 1(`OP_1`)을 사용하고, `bc1p`로 시작하는 주소를 사용하며, Schnorr 서명(64바이트)을 사용한다.
  - P2PKH/P2SH와 P2WPKH/P2WSH는 멀티시그 시 모든 키가 노출되고 스크립트가 전부 공개되지만, P2TR은 멀티시그가 단일 키처럼 보이고 사용된 스크립트만 공개된다.

- 사용 예시
  - 단일 서명 지갑: internal key로 개인 키를 사용하고, Tapscript tree 없이(또는 비상용 복구 스크립트만 포함) 키 경로로 지출한다.
  - 멀티시그 (2-of-2): MuSig2로 두 키를 집계하여 internal key로 사용하고, 키 경로로 협력 지출한다. 외부에서 멀티시그 여부를 알 수 없다.
  - 복잡한 조건부 지출: internal key를 기본 지출 조건으로 사용하고, Tapscript tree에 타임락 후 단독 지출, 비상 복구 키 등 여러 대안 조건을 구성한다. 가장 일반적인 경로만 공개된다.

## 참고

- <https://teachbitcoin.io/presentations/transaction_sighash.html>
- <https://developer.bitcoin.org/devguide/transactions.html>
- <https://learnmeabitcoin.com/technical/script/>
- <https://learnmeabitcoin.com/technical/script/p2pkh/>
- <https://learnmeabitcoin.com/technical/script/p2tr/>
- <https://en.bitcoin.it/wiki/OP_CHECKMULTISIG>
- <https://opcodeexplained.com/opcodes/OP_CHECKMULTISIG.html>
- BIP 문서
  - [BIP16 - P2SH](https://github.com/bitcoin/bips/blob/master/bip-0016.mediawiki)
  - [BIP141 - Segwit](https://github.com/bitcoin/bips/blob/master/bip-0141.mediawiki)
  - [BIP143 - Segwit 서명](https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki)
  - [BIP340 - Schnorr 서명](https://github.com/bitcoin/bips/blob/master/bip-0340.mediawiki)
  - [BIP341 - Taproot](https://github.com/bitcoin/bips/blob/master/bip-0341.mediawiki)
  - [BIP342 - Tapscript](https://github.com/bitcoin/bips/blob/master/bip-0342.mediawiki)
