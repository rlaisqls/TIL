> https://www.youtube.com/watch?v=CyyRpjw2fWQ

### Oracle의 MVCC(Multi Version Concurrency Conrtol)

- 각자 자기 트랜잭션에서 수정한 내용만 조회하도록 하기 위해 Oracle에서 사용하는 방식
- 트랜잭션이 언제 수행되었는지를 기록하는 시간 정보 = SCN
  - DB 기동 후 트랜잭션 수행할 때마다 1 증가
  - 트랜잭션이 begin되면, 각 DB 세션의 메모리에 SCN 값을 복사해감
  - 새로운 값 + SCN을 복사 생성
  - 이후 자신의 SCN에 대한 값만을 읽으면 됨

### Postgresql의 TXID

- 동시성과 일관성을 맞추기 위해 Postgresql에선 SCN과 비슷한 TXID를 사용함
- TXID도 트랜잭션마다 1씩 증가
- 트랜잭션을 실행하는 프로세스에 TXID를 복사하여 기록함
- tuple 데이터에 TXID를 덧붙여 기록함
- tuple 데이터의 구조
  - tuple header
    - t_xmin (Oracle SCN과 비슷)
    - t_xmax
    - t_ctid
  - data
- 데이터를 수정하면 8kb 크기의 페이지에 데이터가 쭉 쌓임
  - 원본 데이터를 교체하지 않고 뒤에 이어서 저장
- 이전의 원본 데이터가 필요없어지면 vacuum 명령어로 지울 수 있음
- vacumm full: 원본 데이터 지우고 빈 공간 압축

### Postgresql의 MVCC

- postgresql에서 트랜잭션을 읽을 땐 자신보다 같거나 작은 튜플 데이터를 읽음 (현재 TXID보다 같거나 작은 t_xmin 값을 가지는 데이터 조회)
- TXID = 32bit
- 값이 한정되어 있으므로 2^32를 사용하면 3으로 돌아감 (0, 1, 2는 특수 값)
- 3으로 돌아가면 2^32는 과거 데이터가 되므로 읽을 수 있어야하는데, 이걸 숫자 대소비교만으로는 할 수 없게됨
- 그래서 postgresql에선 아래와 같이 정리함 (반으로 나눔)
  - 과거 = (TXID+1-2^32) ~ TXID
  - 미래 = TXID+1 ~ TXID+2^31
- 이 때문에 발생하는 문제를 Transaction Wraparound 문제라고 정의함

### Vaccum Freeze

- Transaction Wraparound 문제를 해결하기 위한 방법
- 테이블에 vaccum freeze를 수행하면 특정 조건에 맞는 튜플의 t_infomask 영역에 비트로 freeze 처리함
- 범위가 넘어가도 읽을 수 있게 하는 것

---
참고
- https://medium.com/@pawanpg0963/what-is-transaction-wraparound-in-postgresql-91c972266780
- https://americanopeople.tistory.com/369
- https://www.facebook.com/share/p/EM4MQuYEAJEcZNzH
- https://github.com/junhkang/postgresql/blob/main/%EA%B0%9C%EB%85%90/MVCC%20(Multi-Version%20Concurrency%20Control).md
