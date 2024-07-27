MongoDB의 Atlas Search는 Atlas 클러스터에서 데이터의 세밀한 텍스트 인덱싱과 쿼리를 가능하게 한다. Atlas Search는 데이터베이스에 별도의 검색 시스템을 추가하지 않고도 고급 검색 기능을 사용할 수 있도록 한다.

Atlas Search는 여러 종류의 텍스트 분석기 옵션, `$search`와 `$searchMeta` 같은 Atlas Search 집계 파이프라인 단계를 다른 MongoDB 집계 파이프라인 단계와 함께 사용하는 풍부한 쿼리 언어, 그리고 점수 기반 결과 순위 지정을 제공한다.

## 개념
### 인덱싱

검색에서 인덱스는 쉽게 검색할 수 있는 형식으로 데이터를 분류하는 데이터 구조다. 검색 인덱스는 전체 컬렉션을 스캔하지 않고도 주어진 용어를 포함하는 문서를 더 빠르게 검색할 수 있게 한다. 

일반적인 DB의 인덱스와 달리 검색 인덱스는 책 뒤의 색인처럼 용어와 그 용어를 포함하는 문서 간의 매핑이다. 검색 인덱스는 또한 문서 내 용어의 위치와 같은 다른 관련 메타데이터도 포함한다.

자세한 내용은 [문서](https://www.mongodb.com/docs/atlas/atlas-search/atlas-search-overview/#std-label-fts-about-indexing)를 참고할 수 있다.
  
### 토큰화

검색 인덱스를 만들 때, 데이터는 먼저 일련의 토큰 또는 용어로 변환되어야 한다. 분석기는 다음과 같은 단계를 통해 이 과정을 용이하게 한다:

- 토큰화: 문자열의 단어를 인덱싱 가능한 토큰으로 나누는 것. (e.g. 문장을 공백과 문장부호로 나누는 것)
- 정규화: 데이터를 일관되게 표현하고 분석하기 쉽게 정리하는 것. (e.g. 텍스트를 소문자로 변환하거나 불용어라고 불리는 불필요한 단어를 제거하는 것)
- 어간 추출: 단어를 어근 형태로 축소하는 것. (e.g. 접미사, 접두사, 복수형을 무시하는 것)

토큰화의 세부 방법은 언어에 따라 다르며 추가적인 설정이 필요할 수 있다. 자세한 내용은 [문서](https://www.mongodb.com/docs/atlas/atlas-search/analyzers/#std-label-analyzers-ref)에 있다.

### 쿼리

검색 쿼리는 인덱스를 참조하여 결과 집합을 반환한다. 데이터베이스 쿼리가 엄격한 구문을 따라야 하는데 비해, 검색 쿼리는 단순한 텍스트 매칭을 포함해 유사한 구문, 숫자나 날짜 범위를 찾는 것일 수 있다.

자세한 내용은 [문서](https://www.mongodb.com/docs/atlas/atlas-search/atlas-search-overview/#std-label-fts-about-queries)에 있다.

### 점수 매기기

각 문서는 관련성 점수를 받아 쿼리 결과를 가장 높은 관련성에서 가장 낮은 관련성 순으로 반환할 수 있게 한다. 가장 단순한 형태의 점수 매기기에서는 쿼리 용어가 문서에 자주 나타날수록 점수가 높아지고, 쿼리 용어가 컬렉션의 많은 문서에 나타날수록 점수가 낮아진다. 

용도에 따라 기본 점수를 부스팅, 감소와 같은 방식으로 커스텀하여 정의할 수 있다. 

자세한 내용은 [문서](https://www.mongodb.com/docs/atlas/atlas-search/scoring/#std-label-scoring-ref)에서 볼 수 있다.

## 아키텍처

일반적인 mongoDB 쿼리는 `mongod` 프로세스로 처리되는데 비해, Atlas Search는 `mongod`와 함께 `mongot`라는 프로세스에서 쿼리를 처리한다. `mongot`는 [Apache Lucene](https://lucene.apache.org/)을 사용하며 Atlas 클러스터의 각 노드에서 mongod와 함께 실행된다. `mongot` 프로세스는 다음과 같은 작업을 수행한다:

- 컬렉션에 대한 인덱스 정의의 규칙에 따라 Atlas Search 인덱스를 생성한다.
- Atlas Search 인덱스를 정의한 컬렉션의 문서 현재 상태와 인덱스 변경사항을 모니터링하기 위해 변경 스트림을 감시한다.
- Atlas Search 쿼리를 처리하고 일치하는 문서를 반환한다.

<img src="https://github.com/user-attachments/assets/470af67a-17f0-48f1-a012-b77f56469777" style="height: 400px"/>

### Stored Source

`mongot` 서치에서 반환되는 도큐먼트들은 오브젝트이기 때문에, `mongot` 서치를 돌린 후에는 이후에 매치나 솔팅으로 `mongod`에 쿼리하는 과정이 필요하다.

이로 인한 성능 저하를 개선하기 위해 StoredSource 기능을 사용할 수 있다. Atlas Search 인덱스에서 StoredSource 필드를 정의하면, `mongot` 프로세스는 지정된 필드를 저장한다. 그리고 쿼리에서 returnStoredSource 옵션을 지정한하면 데이터베이스에서 전체 문서를 조회하지 않고 `mongot`에서 직접 저장했던 (캐싱했던) 필드를 반환한다.

<img src="https://github.com/user-attachments/assets/b040ef79-0e97-435c-9e8a-75a0e210c22b" style="height: 400px"/>

### 검색 노드 아키텍처

워크로드 격리를 위해 `mongot` 프로세스만 실행하는 별도의 검색 노드를 배포할 수 있다. Atlas는 각 클러스터 또는 클러스터의 각 샤드에 검색 노드를 배포한다. 예를 들어, 3개의 샤드가 있는 클러스터에 2개의 검색 노드를 배포하면 Atlas는 샤드당 2개씩 총 6개의 검색 노드를 배포한다.

별도의 검색 노드를 배포하면 다음과 같은 이점이 있다:

- MongoDB 클러스터와 독립적으로 스토리지를 확장할 수 있다.
- MongoDB와 독립적으로 쿼리 부하를 확장할 수 있다.

별도의 검색 노드를 배포하면 mongot 프로세스는 독립적으로 구성할 수 있는 별도의 검색 노드에서 실행된다.

<img src="https://github.com/user-attachments/assets/9f39a0ba-a115-4834-b65d-68eb66a0aa7c" style="height: 400px"/>

Atlas 클러스터에서 mongod 프로세스를 실행하는 데이터베이스 노드와 별도로 `mongot` 프로세스를 실행하도록 검색 노드를 구성할 수 있다. 또한 검색 노드의 수와 각 검색 노드에 할당되는 리소스의 양을 구성할 수 있다.

## 인덱스 설정 방법

---
참고
- https://www.mongodb.com/docs/atlas/atlas-search/atlas-search-overview
- https://www.mongodb.com/resources/products/platform/intro-to-mongodb-atlas-search-webinar-korea
- https://tech.inflab.com/202211-mongodb-atlas-search/