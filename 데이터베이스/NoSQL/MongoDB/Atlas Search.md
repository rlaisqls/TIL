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

---
참고
- https://www.mongodb.com/docs/atlas/atlas-search/atlas-search-overview
- https://www.mongodb.com/resources/products/platform/intro-to-mongodb-atlas-search-webinar-korea
- https://tech.inflab.com/202211-mongodb-atlas-search/