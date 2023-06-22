# Logstash

Logstash는 실시간 파이프라인 기능을 가진 데이터 수집 엔진 오픈소스이다. Logstash는 서로 다른 소스의 데이터를 동적으로 통합하고 원하는 대상으로 데이터를 정규화 할 수 있는 능력을 가진다.

다양한 입력과 필터 및 출력 플러그인을 통해, 모든 유형의 이벤트를 보강하고 변환할 수 있으며, 많은 기본 코텍이 처리 과정을 단순화한다. 따라서 Logstash는 더 많은 양과 다양한 데이터를 활용하여 통찰력 있게 볼 수 있게 해 준다.

<img width="551" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/8a8742b2-2793-4b40-881c-687f46cd9a71">

## Logtash 파이프라인

Logstash의 전체적인 파이프라인에는 INPUTS과 FILTERS, 그리고 OUTPUT이 있다. 

이 중에서 2가지의 필수적인 요소는 INPUTS과 OUTPUTS이고, 파싱 여부에 따라 필터는 선택적으로 사용이 가능하다.

<img width="873" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/075e737d-8b11-47fe-9f45-ec2f9dbed496">

### Logstash.yml

Logstash 실행을 컨트롤하는 setting 파일이다.

다른 설정 말고 초기 설정은 아래와 같이 2가지만 세팅되어 있다.

```yml
path.data : /var/lib/logstash
path.logs : /var/log/logstash
```

### jvm.option

이 파일을 통해 힙 사이즈를 조절할 수 있다. 초기 세팅은 아래와 같다

```bash
# 초기 total heapsize
-Xms1g 

# 최대 heap size
-Xmx1g
```

### Pipline.yml

현재는 단일 파이프라인으로 구성되어 있는데, 하나의 인스턴스에서 여러 개의 파이프라인을 실행할 경우 추가해준다.

`/etc/logstash/con.d`밑에 있는 `.conf` 파일로 연결되어있다.

```bash
- pipeline.id: main
  path.config: "/etc/logstash/conf.d/*.conf"
```
 
### conf.d/custom.conf
conf 파일명은 원하는 대로 설정해주면 된다. 위 pipline.yml 파일에서 직접 지정해서 작성하거나 *. conf로 작성한다.

---
### INPUT

```bash
# input
input {
  beats {
    port => 5044
    host => "0.0.0.0"
    client_inactivity_timeout => 86400
  }
}
```

- 파일 비트로부터 데이터를 받을 때는 input을 beats로 설정한다.

- 파일비트로부터 데이터를 받을 포트 지정 (기본 포트 5044)

- 호스트 상관없이 모든 데이터를 받을 경우 호스트는 0.0.0.0으로 작성

---
### FILTER

엘라스틱에 전달하기 전에 원하는 데이터의 타입, 형태 등으로 필터링/전처리하는 과정

#### [예제 1] 실제 사용하는 필터의 2가지 예제

```bash
filter {
  if "IMP" in [log][file][path] {
    mutate {
      gsub => ["message", ", ", "| "]
    }
    grok {
      match => { "message" => ["%{NUMBER:[imp][date]},%{NUMBER:[imp][h]},%{NUMBER:[imp][cu_id]},%{NUMBER:[imp][au_id]},%{NUMBER:[imp][pu_id]},%{WORD:[imp][c_key]},%{WORD:[imp][p_key]},%{GREEDYDATA:[imp][no_info]},%{NUMBER:[imp][place_id]},%{WORD:[imp][nation]},%{WORD:[imp][device]},%{NUMBER:[imp][no_info2]},%{NUMBER:[imp][user_key]},%{WORD:[imp][p_set_id]},%{GREEDYDATA:[imp][url]},\"%{TIMESTAMP_ISO8601:[imp][cre_tt]}\",%{GREEDYDATA:[imp][remote_addr]},%{NUMBER:[click][ar_id]}"]}
      remove_field => ["message"]
      }
    grok {
      match => { "message" => ["%{NUMBER:[imp][date]},%{NUMBER:[imp][h]},%{NUMBER:[imp][cu_id]},%{NUMBER:[imp][au_id]},%{NUMBER:[imp][pu_id]},%{WORD:[imp][c_key]},%{WORD:[imp][p_key]},%{GREEDYDATA:[imp][no_info]},%{NUMBER:[imp][place_id]},%{WORD:[imp][nation]},%{WORD:[imp][device]},%{NUMBER:[imp][no_info2]},%{NUMBER:[imp][user_key]},%{WORD:[imp][p_set_id]},%{GREEDYDATA:[imp][url]},\"%{TIMESTAMP_ISO8601:[imp][cre_tt]}\""]
      remove_field => ["message"]
      }
    }
    date {
      match => [ "[imp][cre_tt]", "YYYY-MM-dd H:m:s" ]
      target => "@timestamp"
      timezone => "Asia/Seoul"
    }
    mutate {
      gsub => [ '[imp][url]', '"', '']
      convert => ["[imp][au_id]","integer"]
      convert => ["[imp][cu_id]","integer"]
      convert => ["[imp][date]","integer"]
      convert => ["[imp][h]","integer"]
      convert => ["[imp][place_id]","integer"]
      convert => ["[imp][pu_id]","integer"]
    }
  }
}
```

1.  [log][file][path] : 로그의 위치
    - 노출 로그를 정제하는 과정으로 우선 log를 읽어오는 경로로 다른 로그와 구분해준다.
  
2. mutate의 gsub 
   - 가장 상단에서 grok에 보낼 메시지를 미리 전처리할 작업이 있을 때 사용
   - 현재는 `,` 구분자를 `|` 로 변경하는 작업을 진행함
   - 사용법 : mutate { gsub => [필드명, 원래 값, 변경할 값] }

3. grok 플러그인
   - 우선 읽어들인 로그는 message안에 담겨서 온다.
   - grok을 여러 번 사용하면, multiple grok을 적용할 수 있다. 
     - 하나의 grok 패턴에서 파싱이 안되면 message가 그대로 다음 grok으로 넘어오게 되고 재시도를 한다.
     - 하지만, 여러 개에 grok에 파싱이 되는 메시지의 경우 여러 번 grok이 적용되는 문제도 발생하니 주의해서 사용해야 한다.
   - 사용법 : grok { match => {"message" => [grok 정규표현식] }, removed_field => [지우고 싶은 필드명]  }

4. date 플러그인
   - 엘라스틱에 데이터가 저장될 때, 엘라스틱에 데이터를 보내는 시간이 아닌 실제 로그 파일에 찍힌/적힌 시간으로 엘라스틱에 적재하기 위해 원하는 filed로 재 설정을 해줘야 한다.
   - 사용법: `data { match => {변경할 필드명, 날짜 format }, target => "@timestamp", timezone=>"Asia/Seoul" }`

5. mutate 플러그인
   - 위에서 설명한 gsub 외에도 다양한 기능이 존재
   - elastic에 로그스테이시에서 파싱한 데이터가 넘어갈 경우, 필드의 타입을 변경해주어야 원하는 타입으로 데이터가 들어간다. 
   - 데이터 타입을 변경하지 않고 적재하면 무조건 string으로 넘어간다.
   - 사용법: `mutate { convert => [ 변경할 필드명, 데이터 타입 ] }`

#### [예제 2] 실제 사용하는 필터의 2가지 예제

```bash
filter {
    if "access" in [log][file][path] {
    grok {
      match => {"message" => ["%{IPORHOST:[nginx][access][remote_ip]} - \[%{HTTPDATE:[nginx][access][time]}\] \"%{WORD:[nginx][access][method]} %{GREEDYDATA:[nginx][access][url]}\?%{GREEDYDATA:[nginx][access][params]} HTTP/%{NUMBER:[nginx][access][http_version]}\" %{NUMBER:[nginx][access][response_code]} %{NUMBER:[nginx][access][body_sent][bytes]} \"%{DATA:[nginx][access][agent]}\" \"%{GREEDYDATA:[nginx][access][private_ip]}\" %{NUMBER:[nginx][access][request_time]} %{NUMBER:[nginx][access][request_length]}"]}
      remove_field => ["message"]
    }
    kv {
      field_split => "&?"
      source => "[nginx][access][params]"
      remove_field => "[nginx][access][params]"
    }
		mutate {
      remove_field => ["agent"]
			rename => { "@timestamp" => "read_timestamp" }
			add_field => { "read_timestamp" => "%{@timestamp}" }
    }
    date {
      match => [ "[nginx][access][time]", "dd/MMM/YYYY:H:m:s Z" ]
      target => "@timestamp"
      timezone => "Asia/Seoul"
    }
  }
}
```

#### 1. [log][file][path] : 로그의 위치
   - 로그를 정제하는 과정으로 우선 log를 읽어오는 경로로 다른 로그와 구분해준다.
   - 여기서는 로그 경로에 "access"가 포함되어 있으면 이곳에서 필터링이 된다

#### 2. grok 패턴 적용
   - 작성한 grok 패턴이 나의 로그에 잘 적용되는지 확인하기 위해서는 다양한 툴이 존재하지만, kibana에 존재하는 툴을 사용하면 좋다.
   - Dev Tools > Grok Debugger 에서 sample data와 grok pattern을 입력하고 simulate 버튼을 누르면 작성한 grok 패턴이 잘 적용되는지를 미리 알 수 있다.

#### 3. kv 필터 플러그인
   - key "구분자" value 구조의 데이터를 분류하는데 특화되어있다.
   - 여기서는 &? 구분자를 사용하여 nginx의 access param을 분리하는데 사용하였다.
   - 사용법: `filter { kv { source ⇒ 필드명, field_split ⇒ 구분자로 필드분리, value_split ⇒ 구분자로 key value 분리 } }`

#### 4. mutate 플러그인 
   - 위에서 부터 자주 사용 된 플러그인으로 필드 삭제, 필드명 변경, 필드 추가 등 다양한 기능이 더 존재한다.
   - 사용법: filter { mutate { remove_field ⇒ 삭제할 필드, rename ⇒ 필드명 변경, add_field ⇒ 필드추가 } }

--- 

### OUTPUT

- fileBeat로부터 데이터를 받아 로그스테이시에서 전처리를 한 데이터를 전송할 곳을 지정
```bash
# 기본 틀
output {
    elasticsearch {
        index => "%{[some_field][sub_field]}-%{+YYYY.MM.dd}"
    }
}
```

- 여러개의 파일비트에서 하나의 로그스테이시로 보낼 경우, 파일에 따라 다른 인덱스명으로 엘라스틱에 적재를 해야할 경우는 아래와 같이 조건문을 사용하여 다양한 인덱스로 보내준다.

```bash
output {
  if "IMP_PRODUCT" in [log][file][path] {
    elasticsearch {
      hosts => ["ip 주소:9200"]
      manage_template => false
      index => "2020-imp-%{[@metadata][beat]}-%{[host][name]}"
    }
  }
  else if "CLICK" in [log][file][path] {
    elasticsearch {
      hosts => ["ip 주소:9200"]
      manage_template => false
      index => "2020-click-%{[@metadata][beat]}-%{[host][name]}"
    }
  }
}
```
 

---
참고
- https://www.elastic.co/guide/en/logstash/7.6/introduction.html