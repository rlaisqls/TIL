# PostgreSQL 명령어

#### 유저 생성
```
CREATE ROLE name [ [ WITH ] option [ ... ] ]
```

```
where option can be:

      SUPERUSER | NOSUPERUSER
    | CREATEDB | NOCREATEDB
    | CREATEROLE | NOCREATEROLE
    | INHERIT | NOINHERIT
    | LOGIN | NOLOGIN
    | REPLICATION | NOREPLICATION
    | BYPASSRLS | NOBYPASSRLS
    | CONNECTION LIMIT connlimit
    | [ ENCRYPTED ] PASSWORD 'password' | PASSWORD NULL
    | VALID UNTIL 'timestamp'
    | IN ROLE role_name [, ...]
    | IN GROUP role_name [, ...]
    | ROLE role_name [, ...]
    | ADMIN role_name [, ...]
    | USER role_name [, ...]
    | SYSID uid
```

#### example
```
CREATE ROLE rladmsqls WITH LOGIN PASSWORD ‘password’;
ALTER ROLE rladmsqls CREATEDB;
```

####  테이블 리스트 보기
```
 \dt
 ```

 #### 유저 리스트 보기
 ```
 \du
 ```

 #### database 목록 보기
```
  \l
```

#### database에 연결하기

```
 \connect study
```

## pg_ctl

#### 사용법
 ```
pg_ctl start   [-w] [-t SECS] [-D DATADIR] [-s] [-l FILENAME] [-o "OPTIONS"]
pg_ctl stop    [-W] [-t SECS] [-D DATADIR] [-s] [-m SHUTDOWN-MODE]
pg_ctl restart [-w] [-t SECS] [-D DATADIR] [-s] [-m SHUTDOWN-MODE]
               [-o "OPTIONS"]
pg_ctl reload  [-D DATADIR] [-s]
pg_ctl status  [-D DATADIR]
pg_ctl kill    시그널이름 PID
pg_ctl register   [-N SERVICENAME] [-U USERNAME] [-P PASSWORD] [-D DATADIR]
                  [-w] [-t SECS] [-o "OPTIONS"]
pg_ctl unregister [-N 서비스이름]
```

#### brew

```
brew services start postgresql
brew services stop postgresql
```
 
