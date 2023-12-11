# DNS 서버

**DNS(Domain Name System)** : 사람이 식별하기 쉬운 도메인 이름을 컴퓨터가 식별하기 위한 네트워크 주소(IP)간의 변환을 수행하기 위한 시스템 (TCP,UDP/53)
- **데몬 이름** : named
- 기본 DNS 서버 주소에 대한 정보는 `/etc/resolv.conf` 파일에 저장되어 있다.

- **Recursive 네임 서버** (Cache DNS 서버)
  - 서버에 질의가 들어오면 자신의 캐시에 저장된 정보 또는 반복적 질의를 통해 그 결과를 호스트에게 응답해주는 네임서버
  - **반복적 질의(Iterative Query):** Recursive 네임 서버가 각 네임서버(Authoritative 네임서버)로 질의하는 방식
  - **재귀적 질의(Recursive Query)** : 호스트가 Recursive 네임서버로 질의할 때 사용되는 방식
  
-  **Authoritative 네임서버** (DNS 서버)
   - 특정 도메인에 대한 정보를 관리하면서 해당 도메인에 대한 질의에만 응답해주는 네임서버
   - Zone(Zone) : 네임서버가 관리하는 도메인 영역
   - Zone 파일(ZoneFile): 관리 도메인에 대한 정보를 담고 있는 파일. 이 파일을 읽어 질의에 응답한다.
   - Zone 전송(Zone Transfer) : 마스터에 있는 원본 Zone 데이터를 슬레이브가 동기화 하는 작업

-  DNS 서버는 마스터(master) 네임서버와 슬레이브(Slave) 네임서버로 구분된다.
`*` master - slave OR Primary - Secondary

### 네임서버 환경 설정 (`/etc/named.conf`)

```json
$ vi /etc/named.conf

acl “allow_user” {192.168.10.50; 192.168.10.51; 192.168.10.52; };

options {
    directory “/var/named”;           // zone 파일들의 위치 지정
    allow-query {any};                // 네임서버에 질의할 수 있는 대상 지정 
    recursive no;                     // 재귀적 질의 허용 여부
    forward only;                     // 자신에게 들어온 질의 요청을 다른 서버로 넘기는 옵션 
    forwarders {192.168.11.10 };
};

zone "shionista.com" IN {
    type master;                      // master 네임서버임을 의미
    file "shionista.com.db";          // 관리하는 도메인의 리소스 레코드 정보를 담고 있는 Zone 파일명을 의미 
};

zone "10.168.192.in-addr.arpa" IN {    // 리버스 도메인. in-addr.arpa 도메인의 하위 도메인으로 구성한다. 
    type master;
    file "shionista.com.db.rev";
};

zone “.” IN {
    type hint;                        // 루트 도메인 type은 hint로 지정한다.
    file “named.ca”;
};
```

### Zone 파일

내부 네트워크에서 작동하는 DNS 서버를 만들기 위해서는, 네트워크 내의 영역에 대한 "IP: 사이트 주소"가 매칭된 정보를 DNS 서버에 저장해놓아야 한다. 이 정보를 저장하는 파일을 Zone 파일이라고 한다.

```bash
$ORIGIN  {영역명}.
$TTL       {TTL 시간}

{영역명}      IN     SOA    {DNS 서버 주소}         {DNS 관리자 메일주소}.    (
                           {Zone 파일 개정번호 입력}
                           {보조 DNS 서버 사용 시, Refresh 타임 입력}
                           {보조 DNS 서버 사용 시, Retry 타임 입력}
                           {보조 DNS 서버 사용 시, Zone 파일 파기 유예기간 설정}
                           {네거티브 캐시 유효기간 설정} 
                           )

{영역명}      IN     NS     {DNS 서버 도메인 주소}
{영역명}      IN     MX     {우선 순위 번호 입력}     {메일 서버 도메인 주소 입력}
{서버1 Host}  IN     A      {서버1 IP 주소 입력}          
{서버2 Host}  IN     A      {서버2 IP 주소 입력}
```

### DNS 관련 명령어

- `named-checkconf` : 네임서버 환경 설정 파일(`/etc/named.conf`)을 검사
- `named-checkzone` : 존 파일(`/var/named/`)을 검사
- `rndc`
  - 네임서버 제어 명령어 (구 ndc 명령어)
  - [stop] : 네임서버 중지
  - [status] : 네임서버 상태 정보 출력
  - [reload] : 존 파일을 다시 로드
  - [flush] : 네임서버의 캐시 제거
- `nslookup`
  - DNS 관련된 각종 정보를 확인할 수 있는 명령어
  - [server IP_ADDRESS] : 질의할 DNS 서버 지정
  - [set type = RECORD] : 질의할 레코드 유형 지정
