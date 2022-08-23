# Q Type

Q Type는 컴파일 시점에 JPAAnnotationProcessor가 @Entity, @Data같은 Annotation이 붙어있는 클래스를 분석하여 자동으로 생성되는 클래스이다.

Q 클래스 인스턴스를 사용하는 방법은 총 2가지가 있다.

#### 1. 직접 인스턴스 생성(alias)

```java
QMember qMember = new QMember("m");
```
별칭(alias)을 지정하면서 새 인스턴스를 생성하여 사용하는 방법이다. 프로그램 실행시 `select m From Member m ~~`와 같이 쿼리가 나간다. 같은 테이블을 Join하거나 서브쿼리를 사용하는 것이 아니라면 잘 사용하지 않는다.

#### 2. 기본 static 인스턴스 사용

```java
QMember qMember = QMember.member;
```

Querydsl에서 생성해주는 Q클래스에 기본으로 있는 static 인스턴스를 사용하는 방법이다.

<img src="https://blogfiles.pstatic.net/MjAyMjA4MjNfMjYw/MDAxNjYxMjYxOTM5NDYz.KMnu_JW4_p0cSBZYjPkzafnKhfYYdYh7YaFnuKU5ofYg.kt03PTLKWyOAZ2qb96QHVmjBf5OVU0Ov-QA1l-9lcMgg.PNG.rlaisqls/image.png">

직접 가보면 위와 같이 선언되어있는 것을 알 수 있다.
