
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

- Ethereum은 초기에 Proof of Work를 사용했으나, 2022년 The Merge 업데이트를 통해 Proof of Stake로 전환했다. 블록체인에서 사용되는 다양한 합의 알고리즘에 대한 자세한 내용은 [합의 알고리즘](./합의%20알고리즘.md) 문서를 참고한다.

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

    Ethereum의 이중 레이어 구조 (The Merge 이후)

  2022년 9월 "The Merge" 이후 이더리움은 두 개의 레이어로 분리되었습니다:

  ┌─────────────────────────────────────┐
  │   Consensus Layer (CL) - Caplin     │  ← 비콘 체인
  │   "무엇이 정당한 블록인가?"         │
  └─────────────────┬───────────────────┘
                    │ Engine API
  ┌─────────────────▼───────────────────┐
  │   Execution Layer (EL) - Erigon     │  ← 원래 이더리움
  │   "트랜잭션을 어떻게 실행하는가?"   │
  └─────────────────────────────────────┘

  CL (Consensus Layer)의 역할:

  1. PoS 합의 관리

  - 검증자(Validator) 관리
  - 32 ETH 스테이킹
  - 블록 제안자 선정
  - Attestation (투표) 수집

  2. 체인 선택 규칙 (Fork Choice)

  // 어떤 체인이 정당한가?
  - LMD-GHOST 알고리즘
  - Finality (최종성) 결정
  - Reorg (재구성) 처리

  3. Beacon Block 생성

- [Gasper](https://ethereum.org/developers/docs/consensus-mechanisms/pos/gasper/)
  - <https://ethereum.org/developers/docs/consensus-mechanisms/>
  - [Casper FFG proof-of-stakeopens in a new tab](https://arxiv.org/abs/1710.09437)와 [GHOST fork-choice rule](https://arxiv.org/abs/2003.03052)를 합쳐 설계한 지분 증명 알고리즘이다.
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
