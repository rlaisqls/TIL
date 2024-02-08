# SMTP의 보안 시스템

- SMTP는 MARC, DKIM, SPF 등 세 가지 방법으로 이메일에 대한 보안을 지킨다. 함께 사용하면 스팸 발송자, 피싱 공격자 등 권한이 없는 당사자가 소유하지 않은 도메인을 대신하여 이메일을 보내는 것을 막을 수 있다.

- SPF, DKIM, DMARC를 올바르게 설정하지 않은 도메인에서는 이메일이 스팸으로 격리되거나 수신자에게 전달되지 않을 수 있다. 또한 스팸 발송자가 자신을 사칭할 위험도 있다.

- DKIM, SPF, DMARC 레코드는 모두 DNS TXT 레코드로 저장된다.

## 1. SPF (Sender Policy Framework)

- SPF는 누군가(google.com)로부터 메일이 발송되었을 때, 이 메일의 발송지(111.111.111.111)가 진짜 해당 도메인인 google.com으로부터 발송된 메일인지 확인하는 시스템이다.
- 만약 이 주소가 진짜라면 google.com은 DNS 서버에 '이 IP로 보낸 것은 저(google.com)입니다.' 라고 등록한다. 이를 SPF record (혹은 TXT record)라고 한다. 
- 즉, 특정 도메인이 DNS 서버에 자신의 메일 서버를 등록시키고, 메일 수신자가 발송 서버를 검증할 수 있도록 만든 것이다.

- 어떤 스팸 업자가 구글의 이름을 사칭해서 발송 도메인을 spam@google.com이라고 위조했다고 하자. SPF가 없을 때, 대다수의 사용자들은 이 스팸 메일을 받아도 "구글에서 보낸 것이니 믿을만 하겠지?" 라고 생각해서 열어보게 될 것이다.
- 이를 방지하기 위해서 수신 메일 서버들은 어떤 송신 메일 서버로부터 어떤 메일을 수신했을 때, 이 도메인에 해당 송신 메일 서버가 유효한 서버인지 검증하는 것이다. google은 DNS 서버에 자신이 허가한 메일 송신 서버를 등록해둠으로서 스팸업자들이 자신을 사칭하는 것을 예방할 수 있다. 

<img width="462" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/428a461b-1fda-4aae-b9b9-e975454ed6bc">

```
v=spf1 a mx include:spf.mtasv.net include:_spf.google.com include:cmail1.com ~all
```

|항목|입력값 및 설명|
|-|-|
|`v`|SPF 버전을 나타낸다. (e.g. `spf1`)|
|`include`|include 뒤에 붙은 도메인의 SPF 레코드에 있는 IP 주소와 도메인을 이 도메인의 인증된 발신자 목록에 추가한다. (e.g. `_spf.google.com`, `amazonses.com`, `servers.mcsv.net`|
|`~all`|도메인의 인증된 발신자 목록에 없는 모든 IP 주소와 도메인에 대해 소프트 페일(Soft Fail)을 설정한다는 의미이다. 수신 서버에게 이메일을 거부하거나 스팸으로 처리할 것을 권장하지만 강제하지는 않는다. 다른 정책으로는 `-all` (메일을 받지 않고 SPF 검증에 실패했다고 표시), `?all` (메일을 받되 SPF 검증과 관계없이 처리), `+all` (모든 메일을 받고 SPF 검증에 성공했다고 표시) 등이 있다.|

- **발신자별 SPF 레코드**
  
    |발신자|레코드|용도|
    |-|-|-|
    |Google Workspace|`_spf.google.com`|Gmail 클라이언트에서 메일 발송|
    |Amazon SES|`amazonses.com`|Amazon SES에서 메일 발송|
    |MailChimp|`servers.mcsv.net`|MailChimp에서 메일 발송
    |Atlassian|`_spf.atlassian.net`|Atlassian에서 메일 발송|

### 2. DomainKeys Indetified Mail (DKIM) 

- DKIM은 메일이 전송 중에 다른 사람(해커 등)에 의해서 변조되지 않았는지를 검증하는 절차이다.
- 도메인 사용자는 DKIM을 사용하여 수신자가 메일을 받았을 때 이 메일이 변조되지 않았다는 것을 확인하고, 이를 증명해야한다.
- DKIM은 공개키/사설키를 사용한다. 도메인이 메일을 발송할 때, 발송 서버는 사설키로 해시값을 만들고 이를 헤더에 넣어 발송하고, 메일 수신 서버가 메일을 받으면 발송자의 도메인의 DNS에 있는 공개키로 복호화한다. 복호화한 해시값을 확인하여 메일이 중간에 변조되었는지를 확인할 수 있다.
- DKIM 레코드 이름은 다음 형식을 따른다.
    ```
    [selector]._domainkey.[domain]
    ```
   - `selector`는 도메인에서 사용하는 이메일 서비스 공급자가 발급한 특수 값이다. selector는 DKIM 헤더에 포함되어 이메일 서버가 DNS에서 필요한 DKIM 조회를 수행할 수 있도록 한다.
   - `_domainkey`는 모든 DKIM 레코드 이름에 포함된다.
   - `domain`은 이메일 도메인 이름이다.

- DKIM 레코드 값은 아래와 같은 구조이다.

```
pm._domainkey.domain.com IN TXT
k=rsa\; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDOCTHqIIQhGNISLchxDvv2X8NfkW7MEHGmtawoUgVUb8V1vXhGikCwYNqFR5swP6UCxCutX81B3+5SCDJ3rMYcu3tC/E9hd1phV+cjftSFLeJ+xe+3xwK+V18kM46kBPYvcZ/38USzMBa0XqDYw7LuMGmYf3gA/yJhaexYXa/PYwIDAQAB
```

- `v=DKIM1`은 이 TXT 레코드가 DKIM으로 해석되어야 한다는 의미이고, `p` 뒤에 오는 값은 공개 키를 나타낸다.

### 3. DMARC (Domain-based Message Authentication, Reporting and Conformance)

- DMARC는 spoofing (발신자 정보를 위조하는 것)을 예방하기 위해 만들어진 보안 방법이다. DMARC는 위에서 소개한 SPF와 DKIM에 종합보고서인 Reporting을 추가한 방식이다.
- DMARC를 채택한다면 일반적으로 하루에 한 번 종합 보고서;`Aggregate reports` 를 받게 된다. 이 보고서는 XML 파일로 보내지며 해당 도메인으로부터 보내진 (혹은 보내졌다고 위조된) 메일들이 DMARC 인증 절차를 통과했는지를 알려준다. 이를 통해 발신측은 정상 메시지 중 인증 실패 비율이나 얼마나 많은 사칭 메일이 발송되고 있는가를 파악할 수 있게 한다.
-  SPF 와 DKIM은 좋은 인증 방식이지만 각각에는 허점이 있다. SPF는 중간에 메일이 변조되어서 피싱 메일로 바뀌어도 이를 검증할 수 없고, DKIM의 경우는 해당 메일 자체가 피싱 사이트에서 왔어도 검증할 수 없다. 그래서 DMARC 는 이 둘을 모두 사용하여 1. 메일이 제대로 된 곳에서 왔는지 2. 메일이 위/변조되지 않았는지를 검증한다. 

- DMARC 레코드 값은 아래와 같은 구조이다.

```
v=DMARC1; p=none; aspf=r; adkim=r; rua=mailto:report@example.com
```

|항목|입력값 및 설명|비고|
|-|-|-|
|`v`|반드시 가장 먼저 선언되어야 함</br>‘DMARC1’로 입력|필수|
|`p`|반드시 v 다음에 선언되어야 함</br>수신 서버에서 DMARC로 인증되지 않은 메일에 대한 처리 방법</br>- none : 아무런 조치를 하지 않고 메일을 수신한다.</br>- quarantine : 스팸메일함으로 수신한다.</br>- reject : 수신을 차단하고, 반송처리한다.|필수|
|sp|하위 도메인에서 전송된 메일에 대한 정책</br>- none : 아무런 조치를 하지 않고 메일을 수신한다.</br>- quarantine : 스팸메일함으로 수신한다.</br>- reject : 수신을 차단하고, 반송처리한다.||
|`aspf`|메일 정보와 SPF 서명의 문자열 일치 여부 설정</br>- s : 모두 일치해야한다.</br>- r : 부분일치를 허용한다.||
|`adkim`|메일 정보와 DKIM 서명의 문자열 일치 여부를 설정</br>- s : 모두 일치해야한다.</br>- r : 부분일치를 허용한다.||
|`rua`|해당 도메인의 DMARC 처리 보고서를 수신할 이메일 주소이다. 메일 주소 앞에 ‘mailto:’를 입력한다. 쉼표(,) 를 연결하여 여러 이메일 주소를 지정할 수 있다.||

### 이메일이 SPF, DKIM, DMARC를 통과했는지 확인하는 방법

- "세부 정보 표시" 또는 "원본 표시" 등 옵션으로 헤더를 포함한 이메일의 전체 버전을 확인해보면 헤더에 SPF, DKIM, DMARC의 결과 추가된 것을 볼 수 있다.

    ```
    arc=pass (i=1 spf=pass spfdomain=example.com dkim=pass
    dkdomain=example.com dmarc=pass fromdomain=example.com);
    ```

- "pass"라는 단어가 표시되면 이메일이 인증 검사를 통과했다는 뜻이다. 예를 들어 "spf=pass"는 이메일이 SPF에 실패하지 않았으며 도메인의 SPF 레코드에 나열된 IP 주소를 가진 인증된 서버에서 전송되었음을 의미한다.
- 위의 예시에서는 이메일이 SPF, DKIM, DMARC 세 가지를 모두 통과했으며 메일 서버에서는 이 이메일이 사칭자가 아닌 실제 example.com에서 보낸 것임을 확인할 수 있다.

---
참고
- https://en.wikipedia.org/wiki/Sender_Policy_Framework
- https://postmarkapp.com/guides/spf
- https://postmarkapp.com/guides/dkim
- https://en.wikipedia.org/wiki/DMARC
- https://help.worksmobile.com/kr/administrator/service/mail/advanced-setting/what-is-dmarc/
- https://www.cloudflare.com/ko-kr/learning/dns/dns-records/dns-dkim-record/