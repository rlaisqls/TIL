
비잔틴 장애 허용(Byzantine Fault Tolerance, BFT)은 분산 컴퓨팅 시스템에서 일부 노드가 악의적으로 행동하거나 임의로 실패하더라도 시스템이 합의에 도달하고 정상적으로 작동할 수 있는 능력이다. 이는 1982년 Leslie Lamport가 제시한 "비잔틴 장군 문제(Byzantine Generals Problem)"에서 유래했다.

- 비잔틴 장군 문제
  - 여러 비잔틴 장군들이 도시를 포위하고 있고, 메신저를 통해 통신하며 공격 또는 후퇴를 결정해야 하는 상황이다. 문제는 일부 장군이나 메신저가 배신자일 수 있으며, 이들이 잘못된 정보를 전달할 수 있다는 점이다. 충성스러운 장군들은 배신자가 있더라도 동일한 작전 계획에 합의해야 한다.

- 신뢰할 수 없는 환경에서 합의가 필요한 다양한 시스템에 사용된다.
  - 분산 데이터베이스: CockroachDB, TiDB 등에서 일관성 보장을 위해 사용
  - 클라우드 스토리지: Azure Storage, Google Spanner 등에서 데이터 복제에 활용

- 전체 n개의 노드가 있을 때 최대 f개의 비잔틴 노드를 허용하는 기본적인 조건은 `n ≥ 3f + 1`이다.
  - 4개 노드: 최대 1개 비잔틴 노드 허용
  - 7개 노드: 최대 2개 비잔틴 노드 허용
  - 10개 노드: 최대 3개 비잔틴 노드 허용
  - 이 조건이 필요한 이유는 충성스러운 노드들이 과반수를 확보하고 비잔틴 노드의 거짓 정보를 식별하기 위해서다.

- PBFT (Practical Byzantine Fault Tolerance): 1999년 Miguel Castro와 Barbara Liskov가 제안한 실용적인 BFT 알고리즘이다.
  - 3단계 프로토콜(Pre-prepare, Prepare, Commit)을 통해 합의를 달성한다.
  - 비동기 네트워크 환경에서도 동작할 수 있다.
  - O(n²) 통신 복잡도를 가지며, 노드 수가 증가하면 성능이 저하되는 한계가 있다.

  ```
  1. Pre-prepare: Primary가 클라이언트 요청을 받아 다른 노드들에게 전파
  2. Prepare: 각 노드가 요청을 검증하고 다른 노드들에게 prepare 메시지 전송
  3. Commit: 2f+1개 이상의 prepare 메시지를 받으면 commit 메시지 전송
  4. Reply: 2f+1개 이상의 commit 메시지를 받으면 클라이언트에게 응답
  ```

---

참고:

- <https://www.microsoft.com/en-us/research/publication/byzantine-generals-problem/>
- <http://pmg.csail.mit.edu/papers/osdi99.pdf>
- <https://arxiv.org/abs/1803.05069>
- <https://tendermint.com/static/docs/tendermint.pdf>
