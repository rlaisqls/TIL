# ELK

ELK는 Elasticsearch, Logstash 및 Kibana, 이 오픈 소스 프로젝트 세 개를 뜻하는 약자이다.

- Elasticsearch : 검색 및 분석 엔진
- Logstash : 여러 소스에 동시에 데이터를 수집하여 변환한 후 Elasticsearch 같은 “stash”로 전송하는 서버 사이드 데이터 처리 파이프라인
- Kibana : 사용자가 Elasticsearch에서 차트와 그래프를 이용해 데이터를 시각화

여기에 경량의 단일 목적 데이터 수집기인 Beats를 추가한 것을 ELK Stack이라고 한다.

## 설치

ubuntu 환경에서 8.8.1 버전으로 진행할 것이다.

`wget`을 통해 다운로드 받은 뒤 설치하였다.

```bash
## 다운로드 ##
# elastic search
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.8.1-amd64.deb

# 키바나 
wget https://artifacts.elastic.co/downloads/kibana/kibana-8.8.1-amd64.deb

# logstash
wget https://artifacts.elastic.co/downloads/logstash/logstash-8.8.1-amd64.deb

# filebeat
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.8.1-amd64.deb

## 설치 ##
# elastic search
sudo dpkg -i elasticsearch-8.8.1-amd64.deb

# 키바나
sudo dpkg -i kibana-8.8.1-amd64.deb

# logstash
sudo dpkg -i logstash-8.8.1-amd64.deb

# filebeat
sudo dpkg -i filebeat-8.8.1-amd64.deb
```

elasticserch와 kibana를 설치한다.

```bash
$ sudo service elasticsearch start
$ service elasticsearch status
● elasticsearch.service - Elasticsearch
     Loaded: loaded (/lib/systemd/system/elasticsearch.service; disabled; vendor preset: enabled)
     Active: active (running) since Tue 2023-06-20 23:36:22 UTC; 1min 5s ago
       Docs: https://www.elastic.co
   Main PID: 1260926 (java)
      Tasks: 61 (limit: 4404)
     Memory: 2.1G
        CPU: 45.852s
     CGroup: /system.slice/elasticsearch.service
             ├─1260926 /usr/share/elasticsearch/jdk/bin/java -Xshare:auto -Des.networkaddress.cache.ttl=60 -Des.networkaddress.cache.negative.ttl=10 -XX:+AlwaysPreTouch -Xss1m -Djava.awt.hea>
             └─1261132 /usr/share/elasticsearch/modules/x-pack-ml/platform/linux-x86_64/bin/controller

$ sudo service kibana start
$ service kibana status
● kibana.service - Kibana
     Loaded: loaded (/etc/systemd/system/kibana.service; disabled; vendor preset: enabled)
     Active: active (running) since Tue 2023-06-20 23:37:48 UTC; 1min 53s ago
       Docs: https://www.elastic.co
   Main PID: 1261571 (node)
      Tasks: 14 (limit: 4404)
     Memory: 54.6M
        CPU: 1.400s
     CGroup: /system.slice/kibana.service
             ├─1261571 /usr/share/kibana/bin/../node/bin/node /usr/share/kibana/bin/../src/cli/dist --logging.dest=/var/log/kibana/kibana.log --pid.file=/run/kibana/kibana.pid
             └─1261583 /usr/share/kibana/node/bin/node --preserve-symlinks-main --preserve-symlinks /usr/share/kibana/src/cli/dist --logging.dest=/var/log/kibana/kibana.log --pid.file=/run/k>

Jun 20 23:37:48 ip-172-31-45-55 systemd[1]: Started Kibana.
```

설치된 프로그램의 파일은 아래와 같은 경로에 저장된다.

- 실행 파일 : `/usr/share/{프로그램명}`
- 로그 : `/var/log/{프로그램명}`
- 시스템 설정 파일 : `/etc/default/{프로그램명}`
- 설정 : `/etc/{프로그램명}`
- 데이터 저장 : `/var/lib/{프로그램명}`

### 외부접속 허용
Elasticsearch는 기본적으로 설치된 서버에서만 통신이 가능하게 설정이 되어있어서 외부접속을 허용하기 위해서는 추가 설정이 필요하다. network.host와 cluster부분을 바꿔주자.

```bash
## Elasticsearch 외부 접속 허용 ##
# 수정
sudo vi /etc/elasticsearch/elasticsearch.yml
network.host: 0.0.0.0
cluster.initial_master_nodes: ["node-1", "node-2"]

# 재시작
sudo service elasticsearch restart

## 키바나 외부 접속 허용##
# 수정
sudo vi /etc/kibana/kibana.yml
server.host: "0.0.0.0"

# 재시작
sudo service kibana restart
```

### Elasicsearch CRUD

#### 클러스터 상태 (Health)
- 클러스터가 어떻게 진행되고 있는지 기본적인 확인
- 클러스터 상태를 확인하기 위해 `_cat` API를 사용
- curl를 사용하여 수행 가능 -> 노드 정보: GET `/_cat/nodes?v` 상태 정보 : GET `/_cat/health?v`
  - Elasticsearch에서 _언더바가 붙은 것들이 API
  - v는 상세하게 보여달라는 의미
- 녹색 : 모든 것이 정상 동작
- 노란색 : 모든 데이터를 사용 가능하지만 일부 복제본은 아직 할당되지 않음(클러스터는 완전히 동작)
- 빨간색 : 어떤 이유로든 일부 데이터를 사용 불가능(클러스터가 부분적으로만 동작)

#### 데이터베이스(index)가 가진 데이터 확인하기

- index는 일반 RDB에서의 DB 역할
- 모든 인덱스 항목을 조회
- GET `/_cat/indices?v`
  
#### 데이터 구조

- 인덱스와 도큐먼트의 단위로 구성 (타입은 deprecated)
- 도큐먼트는 엘라스틱서치의 데이터가 저장되는 최소 단위
- 여러 개의 도큐먼트가 하나의 인덱스를 구성

- 입력 : PUT
   - `ip:9200/index1/type1/1 -d ‘{“num”:1,”name:”test”}’`
- 조회 : GET
   - `ip:9200/index1/type1/1`
- 삭제 : DELETE
   - `ip:9200/index1/type1/1`
- 업데이트 : POST
   - `ip:9200/index1/type1/1_update -d ‘{doc: {“age”:99}}’`
7.X부터는 PUT과 POST 혼용 가능

## 실습

`IP:5601` 으로 키바나에 접속한 후 왼쪽 탭에서 Devtools 탭을 클릭하여 테스트해 볼 수 있다.

<details>
   <summary>api</summary>
   <div markdown="1">
      ```bash
         # index와 doc 만들기
         # customer 는 인덱스명, 1은 doc의 id
         POST /customer/_doc/1
         {
         "name":"choi",
         "age":25
         }

         # _update로 수정하기
         POST /customer/_doc/1/_update
         {
         "doc": {
            "name":"change"
         }
         }

         # script 사용
         POST /customer/_doc/1/_update
         {
         "script" : {
            "inline": "if(ctx._source.age==25) {ctx._source.age++}"
         }
         }

         # 조회하기
         GET /customer/_doc/1

         # 삭제하기
         DELETE /customer
      ```
   </div>
</details>

### 배치 프로세스

- 작업을 일괄적으로 수행할 수 있는 기능
- 최대한 적은 네트워크 왕복으로 가능한 빨리 여러 작업을 수행할 수 있는 효율적인 매커니즘
- 하나의 행동이 실패해도 그 행동의 나머지는 행동을 계속해서 처리
- API가 반환되면 각 액션에 대한 상태가 전송된 순서대로 제공되므로 특정 액션이 실패했는지 여부를 확인 가능

<details>
   <summary>api</summary>
   <div markdown="1">
      ```bash
         ## 키바나의 Devtools에서 진행 ##

         # 벌크 저장
         POST /customer/_bulk
         {"index":{"_id":"1"}}
         {"name":"choi"}
         {"index":{"_id":"2"}}
         {"name":"kim"}

         # 조회
         GET /customer/_doc/1
         GET /customer/_doc/2

         # 수정 및 삭제
         POST /customer/_bulk
         {"update":{"_id":"1"}}
         {"doc":{"age":18}}
         {"delete":{"_id":"2"}}

         # 조회
         GET /customer/_doc/1
         GET /customer/_doc/2
      ```
   </div>
</details>

### 검색 API

- 검색 API는 요청 URI나 요청 본문을 통해 검색 매개 변수를 보내서 실행할 수 있다.
- 검색용 REST API는 _search 엔드 포인트에서 액세스할 수 있다.

#### URI를 통해 검색하기
```bash
GET /bank/_search?q=*&sort=account_number:asc&pretty
```

- bank 인덱스
- q=*: q는 쿼리, *는 모든것을 의미 -> 인덱스의 모든 문서를 검색을 지시한 것, 특정 단어 검색을 원한다면 특정 단어를 명시
- sort: 정렬
- asc: 오름차순
- pretty: 이쁘게 출력


- took: 검색하는데 걸린 시간 (밀리 초)
- timed_out: 검색 시간이 초과되었는지 여부 알림
- _shards: 검색된 파편의 수와 성공/실패한 파편의 수를 알림
- hits: 검색 결과
- hits.total: 검색 조건과 일치하는 총 문서 수
- max_score: 가장 높은 점수를 취득한 doc 를 명시, null의 경우 없다는 뜻
- hits.hits: 검색 결과의 실제 배열(기본값은 처음 10개)
- hits.sort: 결과 정렬키

<details>
   <summary>명령어</summary>
   <div markdown="1">
      ```bash
         # 전체 인덱스의 title필드에서 time검색
         /_search?q=title:time

         # 다중 조건 검색 -> and 또는 or
         /_search?q=title:time AND machine

         # 점수 계산에서 사용된 상세값 출력
         /_search?q=title:time&explain

         # doc 출력 생략
         /_search?q=title:time&_source=false

         # 특정 source 출력
         /_search?q=title:time&_source=title,author

         # 정렬
         /_search?q=title:time&sort=pages
         /_search?q=title:time&sort=pages:desc
      ```
   </div>
</details>

#### 본문을 통해 검색하기 - Query DSL

Elasticsearch에서 쿼리를 실행하는데 사용할 수 있는 JSON 스타일 도메인 관련 언어이다. URI에 `q=*` 대신 JSON 스타일 쿼리 요청 본문을 제공하면 된다.

<details>
   <summary>명령어</summary>
   <div markdown="1">
      ```bash
         # match_all 쿼리는 지정된 색인의 모든 문서를 검색
         POST /bank/_search
         {
            "query": {"match_all": {}}    
         }

         # 1개만 조회
         # size dafult = 10
         POST /bank/_search
         {
            "query": {"match_all": {}},
            "size":1
         }

         # from 매개변수에서 시작하여 size만큼의 문서를 반환
         # 즉, 10 ~ 19 까지
         # from default = 0
         POST /bank/_search
         {
            "query": {"match_all": {}},
            "from": 10,
            "size": 10
         }

         # balance 필드 기준 내림차순 정렬하고 상위 10개
         POST /bank/_search
         {
            "query": {"match_all": {}},
            "sort": {"balance":{"order":"desc"}
         }

         # 특정 필드만 출력
         POST /bank/_search
         {
            "query": {"match_all": {}},
            "_source": ["account_number","balance"]
         }

         # address가 mail lain인 것을 반환
         # 일치순으로 나옴 -> mail lane, mail, lane 이런 식
         POST /bank/_search
         {
            "query": {"match": {"address": "mail lane"}}
         }

         # address가 mail lain과 완벽 일치 반환
         POST /bank/_search
         {
            "query": {"match_phrase": {"address": "mail lane"}}
         }

         # address가 maill과 lane을 포함하는 모든 계정 반환
         POST /bank/_search
         {
            "query": {
               "bool": {
                     "must": [
                        {"match": {"address": "mill"}},
                        {"match": {"address": "lane"}}
                     ]
               }
            }
         }

         # mill은 포함하지만 lane은 포함하지 않는 모든 계정 반환
         POST /bank/_search
         {
            "query": {
               "bool": {
                     "must": [
                        {"match": {"address": "mill"}},               
                     ],
                     "must_not": [
                        {"match": {"address": "lane"}}
                     ]
               }
            }
         }

         # match_all 쿼리는 지정된 색인의 모든 문서를 검색
         POST /bank/_search
         {
            "query": {"match_all": {}}    
         }

         # 1개만 조회
         # size dafult = 10
         POST /bank/_search
         {
            "query": {"match_all": {}},
            "size":1
         }

         # from 매개변수에서 시작하여 size만큼의 문서를 반환
         # 즉, 10 ~ 19 까지
         # from default = 0
         POST /bank/_search
         {
            "query": {"match_all": {}},
            "from": 10,
            "size": 10
         }

         # balance 필드 기준 내림차순 정렬하고 상위 10개
         POST /bank/_search
         {
            "query": {"match_all": {}},
            "sort": {"balance":{"order":"desc"}
         }

         # 특정 필드만 출력
         POST /bank/_search
         {
            "query": {"match_all": {}},
            "_source": ["account_number","balance"]
         }

         # address가 mail lain인 것을 반환
         # 일치순으로 나옴 -> mail lane, mail, lane 이런 식
         POST /bank/_search
         {
            "query": {"match": {"address": "mail lane"}}
         }

         # address가 mail lain과 완벽 일치 반환
         POST /bank/_search
         {
            "query": {"match_phrase": {"address": "mail lane"}}
         }

         # address가 maill과 lane을 포함하는 모든 계정 반환
         POST /bank/_search
         {
            "query": {
               "bool": {
                     "must": [
                        {"match": {"address": "mill"}},
                        {"match": {"address": "lane"}}
                     ]
               }
            }
         }

         # mill은 포함하지만 lane은 포함하지 않는 모든 계정 반환
         POST /bank/_search
         {
            "query": {
               "bool": {
                     "must": [
                        {"match": {"address": "mill"}},               
                     ],
                     "must_not": [
                        {"match": {"address": "lane"}}
                     ]
               }
            }
         }
      ```
   </div>
</details>

## Kibana

- Elasticsearch와 함께 작동하도록 설계된 오픈 소스 분석 및 시각화 플랫폼
- Elasticsearch 색인에 저장된 데이터를 검색, 보기 및 상호 작용
- 고급 데이터 분석을 쉽게 수행하고 다양한 차트, 테이블, 맵에서 데이터를 시각화
- 간단한 브라우저 기반의 인터페이스를 통해 실시간으로 Elasticsearch 쿼리의 변경 사항을 표시하는 동적 대시보드를 신속하게 만들고 공유

### Kibana 시각화 준비하기

수집한 데이터나 로그를 Kibana에서 확인하려면 Kibana의 index pattern에 등록하는 작업이 필요하다.

Index의 패턴을 검색해준다. logstash를 사용했다면 logstash- 형태의 패턴이다.