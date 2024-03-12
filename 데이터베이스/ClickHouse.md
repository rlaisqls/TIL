

### 다운로드

- mac에서는 brew를 사용해 설치할 수 있다. (https://formulae.brew.sh/cask/clickhouse)

    ```bash
    brew install --cask clickhouse
    ```

- 그 외 환경에서는 curl을 사용해 설치할 수 있다.

    ```bash
    curl https://clickhouse.com/ | sh
    ```

- 잘 설치되었는지 확인

    ```bash
    ./clickhouse client
    ./clickhouse local
    ```

### 실행

아래 명령어로 데몬을 실행할 수 있다.

```bash
sudo clickhouse start
```

### 접속

기본적으로 client 명령어를 사용하면 `localhost:9000`에 있는 로컬 DB에 접속한다.

```bash
./clickhouse client
or
clickhouse-client
```

옵션으로 host와 port, 계정 등을 직접 지정할 수 있다.

```bash
./clickhouse client  -h some_ip.com --port 9000 -u some_user --password some_password -d some_db
or
clickhouse-client -h some_ip.com --port 9000 -u some_user --password some_password -d some_db
```