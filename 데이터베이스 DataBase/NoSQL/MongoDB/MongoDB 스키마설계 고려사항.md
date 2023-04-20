# 🌿 MongoDB 스키마설계 고려사항

> The best approach to design is to represent the data **the way your application sees it**<br>"당신의 어플리케이션이 바라보는 관점에서 설계하는 것이 가장 좋은 접근(설계) 방법이다."<br>- Kristina Chodorow, (2019) MongoDB: the Definitive Guide: O'Reily

RDB에서의 스키마 설계는 (application이나 query와는 무관하게) entity를 정의하고 정규화를 통해 중복을 없애는 정형화된 프로세스를 따른다. 이에 비해, MongoDB는 application 관점에서 수행되는 query의 성능을 고려하여 유연한 설계를 필요로 한다. 

mongoDB 설계에서 고려해야 할 사항들을 살펴보자.

## Access Pattern

Application이 데이터에 접근하는 패턴을 파악하여 collection을 정의한다. 아래와 같은 것들을 고려할 수 있다.
 
- Application이 어떤 query들을 수행하는가?
- 어떤 query를 가장 빈번하게 수행하는가?
- Application은 주로 DB에서 데이터를 읽는가? 아니면 쓰는가?
 
함께 조회되는 경우가 빈번한 데이터들은 **같은 collection에 담아 query의 횟수를 줄이고**, 주로 읽기만 하는 데이터와 자주 업데이트하는 데이터는 **별개의 collection에 담아 최적화** 할 수 있다.

## Relation

Access Pattern을 분석하여 collection들이 정의된 후에는, collection 간의 관계를 파악한다.

만약에, `Product`와 `Category`라는 두 collection이 DB에 존재한다고 해보자. 정형적인 RDB 설계에서는 Product Table에 category_id라는 칼럼을 두어 Category Table과 Join 하여 카테고리 정보를 가져오도록 설계될 것이다.

![image](https://user-images.githubusercontent.com/81006587/206883612-1cd727cf-ea9c-42c1-9ab5-6e4dcc8d5035.png)

이런 entity간의 relation을 MongoDB에서는 collection 간에 **reference**할지, **embed**할지 선택하여 나타낼 수 있다. 여기서, reference란 collection 간 참조할 수 있도록 id를 저장하는 것이고, embed는 관계된 document를 통째로 저장하는 것이다.

<img height=200px src="https://user-images.githubusercontent.com/81006587/206883641-b5cc9eb1-f583-4b01-bdb2-b84afd6c083c.png">

<img height=400px src="https://user-images.githubusercontent.com/81006587/206883645-9125a139-f895-4cd5-9324-dbbc95420952.png">

위 그림들은 순서대로 reference 방식, embed 방식을 나타낸다.

두 방식을 선택하는 기준은, 해당 collection이 application에서 어떻게 사용되느냐에 따라 다르다. 예를 들어, 상품 페이지에 카테고리 정보가 함께 보인다면 두 정보는 대부분 함께 조회된다고 봐야 할 것이다. 따라서 query 한 번에 모두 가져올 수 있도록 embed 하는 것이 바람직한 선택이다. 

반면에, 카테고리 정보가 끊임없이 변경되는 상황이라면 어떨까? embed 방식의 경우, 해당 카테고리의 모든 상품 document를 찾아서 embed된 카테고리 정보를 하나하나 수정해야 한다. 하지만 reference 방식의 경우 별도로 관리되는 카테고리 collection에서 하나의 document만 찾아 수정하면 된다. 이렇게 잦은 수정이 예상되는 경우, reference 방식이 더 바람직하다고 볼 수 있다.

Reference는 데이터를 정규화하여 쓰기를 빠르게 하고, embed는 데이터를 비정규화하여 읽기를 빠르게 한다. 일반적으로 최대한 정규화하여 중복을 제거하는 것이 바람직하다고 여겨지는 RDB와 달리, MongoDB는 적절한 수준의 비정규화가 필요한 경우가 많다. NoSQL의 경우 RDB처럼 복잡한 Join 연산이 불가능하기 때문에, 정규화를 수행하여 collection을 많이 쪼개놓은 경우에 필요한 복잡한 데이터로 재구성하는 것이 어려울 수도 있다.

embed와 reference가 사용되기 좋은 상황을 정리하여 나타내자면 아래 표와 같다.

|embed 권장|reference|
|-|-|
|변경이 (거의)없는 정적인 데이터|변경이 잦은 데이터|
|함께 조회되는 경우가 빈번한 데이터|조회되는 경우가 많지 않은 데이터| 
|빠른 읽기가 필요한 경우|빠른 쓰기가 필요한 경우|
|결과적인 일관성이 허용될 때|즉각적으로 일관성이 충족되어야 할 때|

##  Cardinality

서로 관계된 collection 간에 공유 필드가 여러 document에 걸쳐 반복적으로 존재할 수 있다.

온라인 북스토어를 운영한다고 가정해면 책마다 제목은 하나씩이니 One-to-One 관계이고, 책은 여러 리뷰를 가질 수 있으니 책과 리뷰는 One-to-Many관계이다. 그리고 하나의 책은 여러 태그를 가질 수 있고, 하나의 태그는 여러 책을 포함하므로 책과 태그는 Many-to-Many 관계이다. Cardinality는 이렇듯 One-to-One, One-to-Many, Many-to-Many가 존재한다.

mongoDB 설계를 할때는 단순히 many에서 끝나지 않고, how many를 고려하는 것도 필요하다. 책 한 권이 갖는 태그는 기껏해야 10개 미만이지만, 태그 하나에 포함되는 도서는 수백~수천 권이 될 것이니. 책과 태그는 Many-to-Few 관계라고 볼 수 있다.

책과 리뷰, 책과 주문기록의 관계는 둘 다 One-to-Many이지만, 리뷰보다는 주문기록의 훨씬 많을 것으로 예상할 수 있는데, 일반적으로 적은 many는 embed, 많은 many는 개별 collection을 두어 reference 하는 것이 바람직하다.

