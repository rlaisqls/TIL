
NoSQL이라는 용어는 관계형 데이터베이스(RDBMS) 유형에서 벗어난 경량 DBMS류를 부르게 위한 용어이다.

NoSQL에는 다양한 DB들이 있는데, 각 DB에서 데이터를 저장하는 유형은 Key–value store, Document store, Graph 세가지 유형으로 나뉠 수 있다.  

## Key–value store

Key–value store(KV) 모델은, 데이터는 키와 값의 쌍으로 컬렉션을 표현하는 모델이다. 연관배열(map, dictionary라고도 함)을 기본 자료구조로 가지고있다.

Key–value store는 가장 단순한 non-trivial 데이터 모델이며, **선택적인 키 범위를 효율적으로 검색할 수 있다**는 강력한 장점을 가지고 있다. 이 모델은 사전 순서로 키를 유지하는 개별적으로 정렬된 모델로 확장될 수 있다.

## Document store

Document store의 핵심개념은 Document이다. 이 유형을 문서지향 DBMS라고 부르기도 한다.

Document는 일부 표준 형식이나 인코딩으로 데이터(또는 정보)를 캡슐화하고 인코딩된다. XML, YAML, JSON와 같은 형식을 사용하기도 한다.

Document store는 내용을 기반으로 문서를 검색하는 API 또는 쿼리 언어를 사용하는 것이 또다른 특징인데, 구현에 따라 문서 구성 및/또는 그룹화 방법은 다를 수 있다.

아래와 같은 것들이 기준으로 사용될 수 있다.

- 컬렉션
- 태그
- 보이지 않는 메타데이터
- 디렉토리 계층

RDBMS의 Table과 Document store의 collection이 유사한 것으로 간주될 수 있다. 그러나 Table의 모든 레코드는 동일한 필드 시퀀스를 가지는 반면, 컬렉션의 문서는 완전히 다른 필드를 가질 수 있다.

## Graph

Graph 데이터베이스는 관계가 유한한 수의 관계로 연결된 요소로 구성된 그래프로 잘 표현된 데이터를 위해 설계되었다. 그러한 데이터의 예로는 사회 관계, 대중 교통 링크, 도로 지도, 네트워크 토폴로지 등이 있다.

## 특성 비교

각 NoSQL DB 유형과 RDBMS의 특성을 비교하면 다음 표와 같다.

|이름|성능|확장성|유연성|복잡성|
|-|-|-|-|-|
|Key–value store|높음|높음|높음|없음|
|Document-oriented store|높음|상이함(높음)|높음|낮음|
|Graph database|상이함|상이함|높음|높음|
|Relational database|상이함|상이함|낮음|보통|
