## SRV (Service) 레코드

- SRV(Service) 레코드는 특정 서비스를 제공하는 서버의 위치를 지정하기 위한 레코드이다.
 일반적인 A 레코드나 CNAME 레코드와 달리, SRV 레코드는 서비스명과 프로토콜, 우선순위(priority), 가중치(weight), 포트(port), 호스트 이름(target)을 함께 명시한다.
- SRV 레코드를 사용하면 포트나 호스트 이름이 바뀌어도 클라이언트는 SRV 레코드만 다시 조회하면 되므로 유연성이 높고, 서비스 수준에서의 로드 밸런싱 또는 고가용성 구성이 가능해진다.

```bash
# 구조
_service._proto.name. TTL class SRV priority weight port target

# 예시
_sip._tcp.example.com. 3600 IN SRV 10 60 5060 sipserver.example.com.
```

- `_service`: 서비스 이름(예: `_sip`, `_ldap`)
- `_proto`: 프로토콜 종류 (`_tcp` 또는 `_udp`)
- `priority`: 낮을수록 우선순위가 높음
- `weight`: 동일한 priority를 가진 서버 간 부하 분산 시 사용
- `port`: 해당 서비스가 열려있는 포트 번호
- `target`: 실제 서비스를 제공하는 호스트명

### 예시

- MongoDB Atlas (mongodb+srv)
 • `mongodb+srv://cluster.example.com/test`처럼 SRV 레코드를 사용하면 MongoDB 클라이언트가 자동으로 포트, 레플리카 셋 멤버 등의 정보를 조회하여 연결 설정을 단순화할 수 있다.
 • 클라이언트는 `_mongodb._tcp.cluster.example.com`에 대해 SRV 조회를 수행하여 접속 대상과 포트를 알아낸다.
- 그 외에도 [SIP](https://www.ietf.org/rfc/rfc3263.txt), [XMPP](https://en.wikipedia.org/wiki/XMPP), [LDAP](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol) 등 다양한 네트워크 서비스에서 자동 서비스 탐색에 사용된다.

---

## NAPTR (Naming Authority Pointer) 레코드

NAPTR 레코드는 주로 **URI 기반 서비스(예: VoIP, ENUM, SIP)** 를 위한 서비스 디스커버리에 사용되며, 일반적으로 SRV 레코드와 연계되어 사용된다. **정규 표현식(Regex) 기반의 매핑, 서비스 및 프로토콜 지정** 등을 통해 특정 리소스에 대한 접근 정보를 제공한다.

```bash
# 구조
name TTL class NAPTR order preference flags service regexp replacement

# 예시
example.com. 86400 IN NAPTR 100 10 “U” “SIP+D2U” “!^.*$!sip:info@example.com!” .
```

- `order`: 처리 우선순위 (낮을수록 우선)
- `preference`: 동일 order 내 우선순위
- `flags`: 결과 처리 방식 (`U`: URI, `S`: SRV로 연계, `A`: A 레코드)
- `service`: 사용되는 서비스와 프로토콜 (예: `SIP+D2U`: SIP over UDP)
- `regexp`: 정규표현식을 통한 변환 (ex: 전화번호 → URI)
- `replacement`: 대체 도메인 이름 또는 URI

### 예시

- [ENUM](https://en.wikipedia.org/wiki/Telephone_number_mapping) 에서 국제 전화번호를 SIP 주소로 변환하는데 사용된다. (정규식 사용)
- [SIP](https://www.ietf.org/rfc/rfc3263.txt) 클라이언트는 통신 경로를 동적으로 결정하기 위해  NAPTR → SRV → A/AAAA 레코드를 순차적으로 질의한다.

---

참고

- <https://en.wikipedia.org/wiki/SRV_record>
- <https://en.wikipedia.org/wiki/NAPTR_record>
- <https://blog.naver.com/ptupark/130097418840>
- <https://www.mongodb.com/docs/manual/reference/connection-string/#dns-seedlist-connection-format>
- <https://datatracker.ietf.org/doc/html/rfc2782>
- <https://datatracker.ietf.org/doc/html/rfc2915>
- <https://www.ietf.org/rfc/rfc2915.txt>
