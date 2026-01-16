### 1. bind를 설치한다

bind(Berkely Internet Name Domain)는 DNS를 구축, 운영하기 위한 Linux 툴이다. 검증되고 안정적인 DNS 서버이며, 많은 DNS 서버에서 사용된다.

```
yum -y install bind bind-chroot bind-utils
```

### 2. `/etc/named.conf` 파일에서 DNS 서버로 사용할 포트를 열어준다

```conf
options {
        // listen-on port 53 { 127.0.0.1; };
        // listen-on-v6 port 53 { 127.0.0.1; };
        listen-on port 53 { any; };
        listen-on-v6 port 53 { any; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        recursing-file  "/var/named/data/named.recursing";
        secroots-file   "/var/named/data/named.secroots";
        // allow-query { localhost; };
        allow-query     { any; };
        ...
}
```

### 3. `/etc/named.rfc1912.zones` 파일에 도메인 정보를 추가한다

```conf
...
zone "example.com" IN {
    type master;
    file "example.com";
    allow-update { none; };
}
```

### 4. `/var/named/example.com.zone` 위치에 zone 파일을 생성한다

```conf
@   IN          SOA     test.org. test.org. (
                                199609203 ; Serial
                                8h        ; Refresh
                                120m      ; Retry
                                7d        ; Expire
                                24h)      ; Minimum TTL

                NS      bbb

                MX      1 alias

                A       100.100.100.100

www             A       100.100.100.100
bbb             A       100.100.100.100
*               A       100.100.100.100

alias           CNAME   www
alias-chain     CNAME   alias

*.wildcard      CNAME   www

no-service 86400 IN MX 0 .
```

```
chown root:named /var/named/example.com.zone
```

### 5. named service를 restart한다

```
service named restart
system enabled named
```

---
참고

- <https://www.redhat.com/sysadmin/dns-configuration-introduction>
- <https://www.cherryservers.com/blog/how-to-install-and-configure-a-private-bind-dns-server-on-ubuntu-22-04>
- <https://www.isc.org/bind/>
