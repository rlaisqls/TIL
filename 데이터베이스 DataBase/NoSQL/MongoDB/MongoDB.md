# 🌿 MongoDB

mongoDB는 C++로 짜여진 오픈소스 데이터베이스이다. **문서지향(Document-Oriented)적이며 뛰어난 확장성과 성능을 자랑**한다.

일반 RDBMS에서의 Tuple/Row 대신, Document라는 용어를 사용한다. 각 Document는 키과 값으로 이뤄져있으며 Join이라는 개념을 Embedded Documents로 대체한다.

## 특징

MongoDB의 특성으로는 다음과 같은 것들이 있다.

- NoSQL
- 스키마 프리(Schema-Free)
- 비 관계형 데이터베이스



|특징|설명|
|-|-|
|**Document-oriented storage**|MongoDB는 database > collections > documents 구조로 document는 key-value형태의 BSON(Binary JSON)으로 되어있다.|
|**Full Index Support**|다양한 인덱싱을 제공한다.<br>&nbsp;&nbsp;- Single Field Indexes : 기본적인 인덱스 타입<br>&nbsp;&nbsp;- Compound Indexes : RDBMS의 복합인덱스 같은 거<br>&nbsp;&nbsp;- Multikey Indexes : Array에 매칭되는 값이 하나라도 있으면 인덱스에 추가하는 멀티키 인덱스<br>&nbsp;&nbsp;- Geospatial Indexes and Queries : 위치기반 인덱스와 쿼리<br>&nbsp;&nbsp;- Text Indexes : String에도 인덱싱이 가능<br>&nbsp;&nbsp;- Hashed Index : Btree 인덱스가 아닌 Hash 타입의 인덱스도 사용 가능|
|**Replication& High Availability**|간단한 설정만으로도 데이터 복제를 지원. 가용성 향상.|
|**Auto-Sharding**|MongoDB는 처음부터 자동으로 데이터를 분산하여 저장하며, 하나의 컬렉션처럼 사용할 수 있게 해준다. 수평적 확장 가능|
|**Querying(documented-based query)**|다양한 종류의 쿼리문 지원. (필터링, 수집, 정렬, 정규표현식 등)|
|**Fast In-Pace Updates**|고성능의 atomic operation을 지원|
|**Map/Reduce**|맵리듀스를 지원.(map과 reduce 함수의 조합을 통해 분산/병렬 시스템 운용 지원, 하지만 하둡같은 MR전용시스템에 비해서는 성능이 떨어진다)|
|**GridFS**|분산파일 저장을 MongoDB가 자동으로 해준다. 실제 파일이 어디에 저장되어 있는지 신경 쓸 필요가 없고 복구도 자동이다.|
|**Commercial Support**|10gen에서 관리하는 오픈소스|

## 장점

|장점|설명|
|-|-|
|Flexibility|Schema-less라서 어떤 형태의 데이터라도 저장할 수 있다.|
|Performance|Read & Write 성능이 뛰어나다. 캐싱이나 많은 트래픽을 감당할 때 써도 좋다.|
|Scalability|스케일 아웃 구조를 채택해서 쉽게 운용 가능하고, Auto Sharding이 지원된다.|
|Deep Query ability|문서지향적 Query Language를 사용하여 SQL만큼 강력한 Query 성능을 제공한다.|
|Conversion/Mapping|JSON과 비슷한 형태로 저장이 가능해서 직관적이고 개발이 편리하다.|

## 단점

- join이 필요없도록 설계해야한다.
- memory mapped file을 사용한다. 따라서 메모리에 의존적이고, 메모리 크기가 성능을 좌우한다.
- SQL을 완전히 이전할 수 없다.
- B트리 인덱스를 사용하기 때문에 크기가 커질수록 새로운 데이터를 입력하거나 삭제할 때 성능이 저하된다. 이런 B트리의 특성 때문에 데이터를 넣어두면 잘 변하지않는 정보를 조회하는 데에 적합하다.

## MongoDB의 Physical 데이터 저장구조

MongoDB를 구성할 때, 가장 많이 이슈되는 부분 중 하나는 메모리량과 디스크 성능이다.
 
MongoDB는 기본적으로 **memory mapped file**(OS에서 제공되는 mmap을 사용)을 사용한다. 데이터를 쓰기할때, 디스크에 바로 쓰기작업을 하는 것이 아니라 논리적으로 memory 공간에 쓰기를 하고, 그 block들을 주기적으로 디스크에 쓰기를 하며, 이 디스크 쓰기 작업은 OS에 의해서 이루어 진다.
 
만약 메모리가 부족하다면 가상 메모리를 사용하게 된다. 가상 메모리는 페이지(Page)라는 블럭 단위로 나뉘어지고, 이 블럭들은 디스크 블럭에 매핑되고, 이 블럭들의 집합이 하나의 데이터 파일이 된다.
 
![image](https://user-images.githubusercontent.com/81006587/206588762-f4103a3d-a146-4d41-a26d-60cd14cdddb5.png)

메모리는 실제 데이터 블록과, 인덱스가 저장된다. MongoDB에서는 인덱스가 메모리에 상주하고 있어야 제대로 된 성능을 낼 수 있다.

물리 메모리에 해당 데이터 블록이 없다면, 페이지 폴트가 발생하게 되고, 디스크에서 그 데이터 블록을 로드하게 된다. 물론 그 데이터 블록을 로드하기 위해서는 다른 데이터 블록을 디스크에 써야한다.
 
즉, 페이지 폴트가 발생하면, 페이지를 메모리와 디스카 사이에 스위칭하는 현상이 일어나기 때문에 디스크IO가 발생하고 성능 저하를 유발하게 된다. 하지만 메모리 용량이 크다면 페이지 폴트를 예방할 수 있다.