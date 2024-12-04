### Session 모드, Transaction 모드

PgBouncer를 비롯한 Database Proxy에는 커넥션 풀을 사용하는 모드가 크게 두 가지 있다.

- Session 모드
- 클라이언트가 PgBouncer에 맺는 커넥션과 PgBouncer에서 DB에 맺는 커넥션을 1:1 대응하여 실행하는 모드
- 세션 풀을 PgBouncer에서 관리하여, 기존보다 더 안정적인 풀링을 할 수 있다는 장점이 있다.

- Transaction 모드
- 클라이언트에서 실행하는 트랜잭션별로 PgBouncer 풀의 커넥션을 배정받아 실행하는 모드
- 생성된 커넥션이 낭비될 가능성을 줄이기 때문에, 총 커넥션 갯수를 더 적게 유지할 수 있다.
- 각 애플리케이션에서 가지고 있는 커넥션 수의 합이 실제 DB 커넥션 수보다 적을 수 있다.

Session 모드와 Transaction 모드의 특징을 비교하기 위해 아래와 같은 상황을 가정하고 테스트하면 설명된 내용처럼 실행된다.

- 상황:
  - 서버 1, 서버 2가 PgBouncer에 커넥션 하나로 연결되어있고
  - PgBouncer 커넥션 풀의 최대 크기가 1 일 때
  - 각 서버가 “3초 걸리는 쿼리를 실행하고, 코드상에서 3초 sleep하는 요청”을 직렬로 처리하는 상황

- Session 모드
  - 서버 1이 PgBouncer에 연결하면 해당 커넥션을 서버 1이 점유하여 커넥션이 고갈된다.
  - 커넥션이 고갈된 상태이므로 서버 2는 DB에 연결하지 못하고 계속 기다리게 된다.

- Transaction 모드
  - 서버 1이 PgBouncer에 연결해도 커넥션 하나 전체를 점유하는 게 아니라, 트랜잭션을 실제로 실행하는 동안만 사용한다. 트랜잭션 사용이 끝나면 서버 1에서 PgBouncer로의 커넥션은 유지되고 PgBouncer의 DB 커넥션은 내부적으로 유휴 상태로 전환된다. 따라서 서버 1의 요청이 코드상에서 sleep하는 동안 서버 2가 요청에 대한 쿼리를 실행할 수 있다. 결과적으로 하나의 커넥션을 나눠 사용하는 형태가 된다.

이처럼 트랜잭션 모드를 사용하는 경우 전체 커넥션 수를 줄이는 효과를 볼 수 있다.

### 서버 커넥션 라운드로빈

커넥션 풀에서 커넥션 목록을 관리하는 방식이 크게 두 가지 있다.

- LIFO
  - 최근에 사용이 끝난 커넥션을 먼저 꺼내 쓰는 것이다.
  - 최근에 사용이 끝난 커넥션은 따끈따끈한 상태일 가능성이 높아서, 재요청 했을 때 성능이 가장 좋을 것으로 예상되기 때문에 많은 커넥션 풀에서 기본적으로 LIFO 방식을 사용한다.

- 라운드 로빈
  - 사용이 가장 옛날에 끝난 커넥션을 꺼내 쓰는 것이다. (사용이 끝난 건 리스트 맨 마지막으로)
  - 커넥션을 고루고루 순서대로 쓸 수 있다. 이 방식을 사용하면 서버 커넥션이 여러 종착지에 분산되어야 하는 경우 부하를 더 효율적으로 분산할 수 있다.
  - 방치되는 커넥션이 생길 가능성이 LIFO보다 적기에 풀 크기가 좀 더 크게 유지될 수 있다는 단점이 있다.

#### PgBouncer `server_round_robin` 옵션

- pg-pool의 idle 커넥션 관리는 LIFO이다. (뒤에서 넣고 뒤에서 빼기 <https://github.com/brianc/node-postgres/blob/92cb640fd316972e323ced6256b2acd89b1b58e0/packages/pg-pool/index.js#L377> )
- pgbouncer는 기본 LIFO (앞에서 넣고 앞에서 빼기), 설정시 round robin (FIFO) 방식을 사용할 수 있다. <https://github.com/pgbouncer/pgbouncer/blob/1dbde965e6782f6800eb4d1bb6b4d4002bfd1323/src/objects.c#L345>

### pgbouncer 디버깅

`pgbouncer.ini`에 `stats_users`를 추가한다.

```
stats_users = myuser
```

해당 유저로 pgbouncer 데이터베이스에 접근한다. DB 접근 후 `SHOW HELP;`로 명령어 목록을 볼 수 있다.

```
psql -p 6432 -U myuser -W pgbouncer

pgbouncer=# SHOW HELP;
NOTICE:  Console usage
DETAIL:
        SHOW HELP|CONFIG|DATABASES|POOLS|CLIENTS|SERVERS|USERS|VERSION
        SHOW PEERS|PEER_POOLS
        SHOW FDS|SOCKETS|ACTIVE_SOCKETS|LISTS|MEM|STATE
        SHOW DNS_HOSTS|DNS_ZONES
        SHOW STATS|STATS_TOTALS|STATS_AVERAGES|TOTALS
        SET key = arg
        RELOAD
        PAUSE [<db>]
        RESUME [<db>]
        DISABLE <db>
        ENABLE <db>
        RECONNECT [<db>]
        KILL <db>
        SUSPEND
        SHUTDOWN
        SHUTDOWN WAIT_FOR_SERVERS|WAIT_FOR_CLIENTS
        WAIT_CLOSE [<db>]
SHOW

pgbouncer=# SHOW POOLS;
 database  |   user    | cl_active | cl_waiting | cl_active_cancel_req | cl_waiting_cancel_req | sv_active | sv_active_cancel | sv_being_canceled | sv_idle | sv_used | sv_tested | sv_login | maxwait | maxwait_us |  pool_mode
-----------+-----------+-----------+------------+----------------------+-----------------------+-----------+------------------+-------------------+---------+---------+-----------+----------+---------+------------+-------------
 pgbouncer | pgbouncer |         1 |          0 |                    0 |                     0 |         0 |                0 |                 0 |       0 |       0 |         0 |        0 |       0 |          0 | statement
 postgres  | postgres  |         0 |          0 |                    0 |                     0 |         0 |                0 |                 0 |       0 |       1 |         0 |        0 |       0 |          0 | transaction
(2 rows)
```
