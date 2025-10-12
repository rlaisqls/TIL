
> <https://ethereum.org/history/>
> <https://ethereum.github.io/yellowpaper/paper.pdf>
> <https://github.com/chronaeon/beigepaper>
> <https://github.com/ethereum/EIPs>
> <https://ethereumclassic.org>

> 머클 패트리샤 트리: <https://ethereum.org/developers/docs/data-structures-and-encoding/patricia-merkle-trie>
> 이대시 작업증명 알고리즘: <https://github.com/ethereum/research/wiki/Casper-Version-2.1-Implementation-Guide>
> 게스 클라이언트: <https://geth.ethereum.org>

- Parity 이더리움 클라이언트: <https://parity.io>
  - <https://github.com/paritytech>

> [levelDB](https://github.com/google/leveldb)(블록체인의 로컬 사본을 저장하는데 가장 자주 사용됨)

### 개요

- 비트코인은 스크립트 머니의 개념을 적용한 최초의 탈중앙화 합의 프로토콜이다. 다시 말해 제한된 프로그램 실행의 참/거짓 상태에 따라 암호화폐 거래가 가능하다는 것이다. 초기에는 비트코인이 화폐 정도로 취급되었으나, 더 많은 가치를 저장하는 수단으로 바라보는 의견이 많아졌다.

- 이 흐름에서 [Colored Coin](https://en.wikipedia.org/wiki/Colored_Coins)가 개발되었다.
  - Coloerd Coin은 주식이나 금과 같은 실제 자산을 비트코인 블록체인 위에 표현하고 관리할 수 있게 한다. Coloerd Coin의 목적은 누구나 비트코인 블록체인 위에서 자신만의 고유한 디지털 화폐를 발행할 수 있는 프로토콜 역할을 하는 것이다. 이 프로토콜에서 사용자는 특정 비트코인 UTXO에 공개적으로 색깔을 부여함으로써 새로운 화폐를 발행할 수 있다. 이러한 추가 정보를 비트코인의 스크립트 언어 메타데이터에 담아 거래할 수 있도록 한다.

- 이후 비트코인을 스케일링하는 솔루션이 진화하면서 Mastercoin(현재 Omni Layer)이 개발되었다. 마스터코인은 비트코인 블록체인 위에 구축된 메타 프로토콜로, 프로그래밍 가능한 돈 개념을 이어 발전시키기 위해 아래 개념들을 구현하였다
  - Smart contract: 계약 당사자가 사전에 협의한 내용을 미리 프로그래밍해 전자 계약서에 넣어두고, 조건이 충족되면 자동으로 실행되는 시스템
  - Token: 비트코인 블록체인 위에서 사용자 정의 자산을 표현하는 개념이다.
    - 비트코인 트랜잭션의 메타데이터(OP_RETURN 등)에 토큰 정보를 인코딩한다.
    - 실제로는 아주 작은 양의 비트코인(dust amount)을 전송하면서, 그 트랜잭션에 토큰 전송 정보를 담는다.
    - 누구나 자신만의 토큰을 발행할 수 있으며, 주식, 채권, 포인트, 게임 아이템 등 다양한 자산을 나타낼 수 있다.
    - Colored Coin이 특정 UTXO에 "색깔"을 입히는 방식이었다면, Mastercoin은 더 체계적인 토큰 발행/관리 프로토콜을 제공했다.
  - <https://bitcoinmagazine.com/technical/mastercoin-a-second-generation-protocol-on-the-bitcoin-blockchain-1383603310>

  - 현재는 이름에 Omni Layer로 변경되어 비트코인 블록체인 위에서 작동하는 레이어 2 프로토콜로 동작한다. `OP_RETURN` 필드가 추가되면 옴니레이어로 볼 수 있다.
  - 작동 방식:
    1. 사용자가 비트코인 트랜잭션을 생성한다.
    2. `OP_RETURN` 필드에 Omni Layer 프로토콜 데이터를 인코딩한다. (최대 80바이트)
    3. 이 트랜잭션이 비트코인 블록체인에 기록된다.
    4. Omni Layer 노드들이 비트코인 블록을 스캔하며 Omni 프로토콜 트랜잭션을 추출하고 해석한다.
    5. 별도의 Omni Layer 상태를 관리하여 토큰 잔액과 소유권을 추적한다.

  ```
  비트코인 트랜잭션:
  Input: 0.001 BTC
  Output 1: 0.0001 BTC (to receiver)
  Output 2: 0.0008 BTC (change)
  Output 3: OP_RETURN <Omni Protocol Data>
           ↑
           예: "Send 100 USDT from A to B"
  ```

- 가장 성공한 Omni Layer 토큰으로 Tether (USDT)가 있다.
  - USD와 1:1로 페깅된 스테이블코인으로, 암호화폐 거래소에서 법정화폐 대용으로 널리 사용된다. Tether Limited가 발행하며, 예비금으로 실제 USD를 보유한다고 주장한다.
  - `OP_RETURN` 필드 값 `6f6d6e69000000000000000f1000000001dcd6500`이 UDST 트랜잭션 내용을 담고 있다.
    - `6f6d6e69`: omni 트랜잭션임을 나타내는 플래그
    - `000000000`: Simple send 트랜잭션 유형
    - `000000f1`: 속성 타입 값(31), 31은 USDT를 뜻하며 모든 옴니레이어 속성은 Omnixplore에서 확인할 수 있음
    - `000000001dcd6500`: 보낼 양이 5.0임을 뜻함. 옴니레이어 트랜잭션에는 모두 소수점 이하 8자리가 있다.
  - 현재는 Ethereum(ERC-20), Tron(TRC-20), BSC 등 여러 블록체인에서도 발행되지만, 여전히 Omni Layer에서도 작동한다.

- Omni Layer는 비트코인 블록 생성 시간(~10분)으로 인해 느린 전송 속도, 높은 수수료 등이 문제가 되었다.
- 이에 Vitalik Buterin이 2013년 Ethereum 백서를 발표하고 2015년 메인넷을 출시했다.
  - 비트코인의 제한적인 스크립팅 언어와 달리, Ethereum은 튜링 완전한 프로그래밍 언어(Solidity)를 제공한다.
  - Mastercoin/Omni Layer가 비트코인 위에 메타 프로토콜을 구축한 것과 달리, Ethereum은 처음부터 스마트 컨트랙트를 위해 설계된 독립적인 블록체인이다.
  - 장점:
    - 더 빠른 블록 생성 시간 (~12-15초)
    - 유연한 스마트 컨트랙트 개발 환경
    - ERC-20, ERC-721 같은 표준화된 토큰 인터페이스
    - 복잡한 탈중앙화 애플리케이션(DApp) 구축 가능

- Ether(ETH)와 Gas
  - Ether(ETH): Ethereum 네트워크의 기본 암호화폐다.
    - 네트워크 참여자들에게 보상을 제공한다. (채굴자/검증자)
    - 스마트 컨트랙트 실행 비용을 지불하는 수단이다.
    - 가치 저장 수단이자 담보 자산으로 사용된다.
    - 최소 단위는 wei (1 ETH = 10^18 wei)

  - Gas: Ethereum에서 계산 작업의 비용을 측정하는 단위다.
    - 모든 EVM 연산(덧셈, 곱셈, 저장소 접근 등)은 정해진 gas 비용이 있다.
    - Gas는 스팸 방지와 네트워크 리소스 관리를 위한 메커니즘이다.
    - 무한 루프나 악의적인 코드가 네트워크를 마비시키는 것을 방지한다.

  ```
  Gas 계산 구조:

  Gas Limit: 사용자가 지불할 의향이 있는 최대 gas 양
  Gas Price: gas 1단위당 wei로 표현된 가격 (Gwei로 표시)

  트랜잭션 수수료 = Gas Used × Gas Price

  예시:
  Gas Limit: 100,000
  Gas Price: 50 Gwei (50 × 10^9 wei)
  실제 사용: 80,000 gas

  수수료 = 80,000 × 50 × 10^9 wei = 0.004 ETH
  환불 = (100,000 - 80,000) × 50 × 10^9 wei = 0.001 ETH
  ```

  - Gas의 필요성:
    - 계산량에 따른 공정한 비용 부과: 복잡한 연산일수록 더 많은 gas 소비
    - 네트워크 혼잡도 반영: 사용자가 gas price를 높게 설정하면 더 빠른 처리
    - DoS 공격 방지: 공격자가 무한 루프를 실행해도 gas가 소진되면 중단됨
    - 저장소 비용: 블록체인 상태를 영구적으로 저장하는 것은 높은 gas 비용 부과

  - [EIP-1559](https://eips.ethereum.org/EIPS/eip-1559) (2021년 도입): Gas 메커니즘을 개선했다.
    - Base Fee: 네트워크가 동적으로 조정하는 기본 수수료 (소각됨)
    - Priority Fee (Tip): 채굴자/검증자에게 주는 팁
    - 총 수수료 = (Base Fee + Priority Fee) × Gas Used
    - Base Fee 소각으로 ETH의 디플레이션 효과 발생

### EVM

- Ethereum Virtual Machine, EVM은 JVM 사양과 유사한 계산 및 스토리지의 추상화를 제공하는 가상 계산 엔진이다.
  - JVM에서 Java, Scala, C# 등 고급 언어의 바이트코드 명령어 집합을 컴파일해 실행하는 것처럼, EVM은 LLL, Serpent, Mutan, Solidity 같은 고수준 스마트 컨드랙트 프로그래밍 언어를 컴파일해 실행한다.
- EVM은 실행 순서가 외부에서 구성되기 때문에 스케줄링 기능이 없다. 쯕, 이더리움 클라이언트가 검증된 블록 트랜잭션을 통해 어떤 스마트 컨트랙트가 어떤 순서로 실행되어야 하는지를 결정한다. 이러한 의미에서 이더이움 월드 컴퓨터는 자바스크립트처럼 단일 스레드이다.
- 이더리움 상태
  - EVM의 작업은 이더리움 프로토콜에 정의된 대로 스마트 컨트랙트 코드의 실행 결과로 유효한 상태 변화를 계산하여 이더리움 상태를 업데이트하는 것이다.
  - 가장 상위 레벨의 상태로 World state(160비트의 이더리움 주소값을 계정에 매핑한 것)가 있다.
  - 각 이더리움 주소는 아래 요소들을 포함한다.
    - balance: wei 단위 이더 잔액
    - nonce: 계정이 EOA 인 경우 해당 계정에서 성공적으로 전송한 트랜잭션의 수, 컨트랙트 계정의 경우 생성된 컨트랙트의 수)
    - storage: 스마트 컨트랙트에서만 사용하는 영구 데이터 저장소
    - program code: 스마트 컨트엔트에서만 사용하는 코드

### Ethereum 2.0

- [Beacon Chain](https://ethereum.org/roadmap/beacon-chain/)
  - Ethereum2.0에서 새로운 블록체인은 모든 샤드 체인에 합의를 제공함으로써 네트워크가 동기화되도록 보장한다. 각 샤드 체인은 샤드 블록에 트랜잭션을 추가하고 Beason chain 및 모든 샤드 체인에 추가할 새 블록을 제안하는 역할을 하는 검증자를 가진다.
  - 검증자는 비콘 체인에 의해 활성화되며 자박적으로 또는 잘못된 행동으로 인해 비활성화 될 수 있다.
- [Gasper](https://ethereum.org/developers/docs/consensus-mechanisms/pos/gasper/)
  - <https://ethereum.org/developers/docs/consensus-mechanisms/>
  - [Casper FFG proof-of-stakeopens in a new tab](https://arxiv.org/abs/1710.09437)와 [GHOST fork-choice rule](https://arxiv.org/abs/2003.03052)를 합쳐 설계한 지분 증명 알고리즘이다.
  - Ethereum은 초기에 Proof of Work를 사용했으나, 2022년 The Merge 업데이트를 통해 Proof of Stake로 전환, 2.0에서 Gasper로 전환했다.
  - Byzantine fault tolerant(비잔틴 장애 허용)으로, 일부 노드가 신회할 수 없고 책임감이 있더라도 합의에 도달할 수 있다는 것을 의미한다.
  - 잘못된 동작을 한 검증자는 스테이킹된 균형에 의해 불이익을 받는다. 이해 관계가 있는 검증자의 2/3가 합의에 도달하면 체인은 검증될 수 있다.

- Fork choice rule
  - 검증자가 포크(검증자로부터 가장 많은 표를 받은 블록)에서 어떤 체인을 따라갈지 결정하는 데 도움이 되는 규칙이다.
  - 네트워크는 블록 생성 시 어떤 검증자가 블록을 제안할지를 결정하기 위해 랜덤 넘버 하트비트(Random number heartbeat) 를 사용하지만,
  - 만으로는 네트워크가 단일한 체인에 합의하도록 보장할 수 없다.
  - 따라서 각 검증자는 블록 제안 이후 포크 선택 규칙(Fork Choice Rule) 을 사용해 “어떤 체인이 가장 정당한 체인인지”를 판단한다. 예를 들어 Ethereum의 LMD-GHOST (Latest Message Driven – Greediest Heaviest Observed SubTree) 규칙에서는 가장 많은 검증자 투표(가장 무거운 서브트리)를 받은 블록을 따라가는 방식으로 체인을 선택한다.
  - 이렇게 함으로써 네트워크는 임의성(Randomness)으로 블록 제안자를 정하고, 포크 선택 규칙으로 모든 검증자가 동일한 “최종 합의된 체인”으로 수렴하도록 보장한다.

- Deposit contract(예치 콘트랙트)
  - 비콘 체인의 균형을 잡을 수 있는 콘드랙트이다. 이더리움 1.0 네트워크에 존재한다.
  - 콘트랙트의 ETH는 일단 입금되면 1.0 sp트워크에 쓸 수 없다. 검증자가 되기 위해 필요한 최소 보증금은 32ETH이다.
  - 대부분의 증거 시스템과 마찬가지로, 검증자 역할을 한 것에 대한 재정적 보상이 있다.

- 정직한 검증자 프레임워크
  - ethereum 2.0 네트어크를 안전하게 유지하기 위해 검증자들이 따라야 하는 일련의 기분이 있다. 여기에는 제안된 블록에 서명하고 투표를 위해 사용 가능한 개인 키와 활성 검증자가 되어 생성된 자금을 회수하기 위한 별도의 개인키가 포함돼 있는데, 이는 오프라인에 안전하게 저장되어야 한다.
  - 해당 공개키는 Validator Deposit Contract와 함께 트랜잭션의 일부로 등록된다.

- 네트워크 내 샤딩은 가스 비용이 증가하고 원자적인 트랜잭션 또는 한 번에 모든 트랜잭션을 수행하는 기능이 제거되는 결과를 가져온다. 이는 ethereum 2.0이 금용적 플랫폼에서 소프트웨어 플랫폼으로 변화할 가능성을 높일 것이다.
