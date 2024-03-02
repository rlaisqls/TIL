
ELK는 Elasticsearch, Logstash 및 Kibana, 이 오픈 소스 프로젝트 세 개를 뜻하는 약자이다.

- Elasticsearch : 검색 및 분석 엔진
- Logstash : 여러 소스에 동시에 데이터를 수집하여 변환한 후 Elasticsearch 같은 “stash”로 전송하는 서버 사이드 데이터 처리 파이프라인
- Kibana : 사용자가 Elasticsearch에서 차트와 그래프를 이용해 데이터를 시각화

여기에 데이터 수집기인 Beats를 추가한 것을 ELK Stack이라고 한다. Beats를 추가하면 다른 서버에서 데이터를 가져오는 것도 가능해진다.

<img width="623" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/3f787f5d-b49a-49a9-aae5-058562b8bb55">

ubuntu 기준으로 elk를 구축해보겠다.

## Elasticsearch 설치

```bash
# 설치
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.8.1-amd64.deb
sudo dpkg -i elasticsearch-8.8.1-amd64.deb
 
# 메모리 수정
sudo vi /etc/elasticsearch/jvm.options
-Xms256m
-Xmx256m
```

설치된 프로그램의 파일은 아래와 같은 경로에 저장된다. 로그나 명령어를 실행하기 위해선 아래 파일 경로에 접근해야 하니 알아두면 좋다.

- 실행 파일 : `/usr/share/{프로그램명}`
- 로그 : `/var/log/{프로그램명}`
- 시스템 설정 파일 : `/etc/default/{프로그램명}`
- 설정 : `/etc/{프로그램명}`
- 데이터 저장 : `/var/lib/{프로그램명}`

Elasticsearch는 기본적으로 설치된 서버에서만 통신이 가능하게 설정이 되어있어서 외부접속을 허용하기 위해서는 추가 설정이 필요하다. network.host와 cluster부분을 바꾸고 실행해주자.

```bash
## Elasticsearch 외부 접속 허용 ##
# 수정
sudo vi /etc/elasticsearch/elasticsearch.yml
network.host: 0.0.0.0
cluster.initial_master_nodes: ["node-1", "node-2"]

# 재시작
sudo service elasticsearch restart

# 서비스 등록 및 시작
sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
curl -X GET "localhost:9200"
 
# 상태 확인
curl localhost:9200/_cat/indices?v
curl -X GET localhost:9200/_cat/health?v
curl -X GET localhost:9200/_cat/nodes?v
```

## Kibana

- Elasticsearch와 함께 작동하도록 설계된 오픈 소스 분석 및 시각화 플랫폼
- Elasticsearch 색인에 저장된 데이터를 검색, 보기 및 상호 작용
- 고급 데이터 분석을 쉽게 수행하고 다양한 차트, 테이블, 맵에서 데이터를 시각화
- 간단한 브라우저 기반의 인터페이스를 통해 실시간으로 Elasticsearch 쿼리의 변경 사항을 표시하는 동적 대시보드를 신속하게 만들고 공유

설치한 뒤 외부 트래픽을 허용하고, elasticSearch와 연결되도록 설정을 수정해준다. 
```bash
# Kibana 설치
wget https://artifacts.elastic.co/downloads/kibana/kibana-8.8.1-amd64.deb
sudo dpkg -i kibana-8.8.1-amd64.deb
 
# 설정 변경
vi /etc/kibana/kibana.yml
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://{your_es_ip}:9200"]
 
# 서비스 등록 및 시작
sudo systemctl daemon-reload
sudo systemctl enable kibana.service
sudo systemctl start kibana.service
```

서버에 웹으로 처음 접속해서 로그인 해보면 이런 화면이 보인다. 
<img width="639" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/0639a678-533c-4549-99e5-204855eab36f">

## Logstash 설치

```bash
# 설치
wget https://artifacts.elastic.co/downloads/logstash/logstash-8.8.1-amd64.deb
sudo dpkg -i logstash-8.8.1-amd64.deb
 
# 설정
vi /etc/logstash/logstash.yml

http:
  host: "0.0.0.0"

# 서비스 등록 및 시작
sudo systemctl daemon-reload
sudo systemctl enable logstash.service
sudo systemctl start logstash.service

# 상태 확인
tail -f /var/log/logstash/logstash-plain.log
```

정보를 받아와서 매핑할 형식을 `/etc/logstash/conf.d` 밑에 파일로 지정해준다.

나는 로깅용으로 써볼 생각이라 grok으로 log 패턴을 정의했다.

```bash
# grok 패턴 정의
PATTERN_LOG_LINE %{TIMESTAMP_ISO8601:timestamp} :: %{IP:ip} \[%{WORD:httpmethod}\] %{NUMBER:status} path : %{URIPATH:path} query : %{DATA:query} body : %{DATA:body}

input {
  beats {
    port => 5088
    type => "request"
  }       
}        
        
filter {
  if [type] == "request" {
    grok {
      match => { "message" => "%{PATTERN_LOG_LINE}" }
    }
    date {
      match => ["timestamp", "yyyy-MM-dd HH:mm:ss.SSS" ]
      target => "@timestamp" 
      timezone => "Asia/Seoul"
      locale => "ko"
    }
  } 
}

output {
  if [type] == "request" {
    elasticsearch {
      hosts => [ "localhost:9200" ]
      index => "satellite-request-%{+YYYY.MM.dd}"
    }
  }
}
```

## Beat 설치 
```bash
# 설치
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-7.15.1-amd64.deb
sudo dpkg -i filebeat-7.15.1-amd64.deb

# 설정

filebeat.inputs:
- type: filestream
  id: my-filestream-id
  enabled: true
  paths:
    - /home/repo/satellite/log/*.log # 로그 파일이 저장될 경로로 지정해준다.

# 서비스 등록 및 시작
sudo systemctl daemon-reload
sudo systemctl enable filebeat.service
sudo systemctl start filebeat.service
```

## kibana index 추가

`Stack Management > Index Management`에 들어가서 Logstash에 설정해놨던 정보랑 같은 이름의 index를 매핑하도록 추가해준다.

<img width="1077" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/68186839-dd55-41be-a13c-26f8d81a7483">

그러면 이런식으로 Discover에서 데이터를 확인하는 것이 가능하다.

이 데이터는 내 Spring 서버에서 파일로 출력한 로그 > Beat > Logstash > ElasticSearch > Kibana의 과정을 통해 보여지는 것이다. 지금은 기본적인 세팅만 해놨는데 다른 자세한 커스텀 설정을 많이 할 수 있는 것 같다.

<img width="1087" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/cb56961b-9a85-431b-be40-987cd3b37a0d">

---
참고
- https://discuss.elastic.co/t/best-practices-for-indexing-log-data/101891
- https://www.elastic.co/guide/en/logstash/7.6/introduction.html