# 🤔 Querydsl

<img src="https://t1.daumcdn.net/cfile/tistory/99248E505CB2FFB018">

<br>

 Spring Data JPA가 기본적으로 제공해주는 CRUD 메서드 및 쿼리 메서드 기능을 사용하더라도 원하는 조건의 데이터를 수집하기 위해선 JPQL을 작성해야한다.JPQL로 간단한 로직을 작성하는데는 큰 문제가 없지만, 복잡한 로직의 경우 쿼리 문자열이 상당히 길어진다. 또, 정적 쿼리인 경우엔 어플리케이션 로딩 시점에 JPQL 문자열의 오타나 문법적인 오류를 발견할 수 있지만, 그 외는 런타임 시점에서 에러가 발생한다는 문제가 있다.

 이러한 문제를 해결하기 위한 프레임워크가 바로 QueryDSL-jpa이다. QueryDSL을 사용하면 문자가 아닌 코드로 쿼리를 작성할 수 있기 때문에 컴파일 시점에 문법 오류를 쉽게 확인할 수 있고, 타입 안정성(type-safe)을 지키면서 동적인 쿼리를 편리하게 작성할 수 있다.

 QueryDSL-jpa는 JPQL을 생성해주는 역할을 하고, QueryDSL 자체는 QueryDSL-SQL, QueryDSL-MongoDB 등등 여러 종류로 나뉘어있지만 여기에서 말하는 QueryDSL은 QueryDSL-jpa를 뜻하는 것으로 간주한다.

---

# Q-Class

Q-Class는 컴파일 시점에 JPAAnnotationProcessor가 `@Entity`, `@Data`같은 Annotation이 붙어있는 클래스를 분석하여 자동으로 생성되는 클래스이다.

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
