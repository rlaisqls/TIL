
## Elasicsearch 검색 명령어

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
