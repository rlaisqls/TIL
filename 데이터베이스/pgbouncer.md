
### pgbouncer 디버깅

`pgbouncer.ini`에 stats_users를 추가한다.

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
