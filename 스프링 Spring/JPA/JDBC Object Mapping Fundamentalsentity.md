
스프링 데이터가 객체를 매핑할 떄 담당하는 핵심 역할은 도메인 객체 인스턴스를 생성하고, 여기에 저장소 네이티브 데이터 구조를 매핑하는 일이다. 여기에는 두 가지의 핵심적인 단계가 있다.

1. 노출된 생성자중 하나로 인스턴스 생성하기.
2. 나머지 프로퍼티 채우기.
   
## 엔티티(Entity) 생성

Spring Data JDBC에서 엔티티 객체를 생성하는 알고리즘은 3가지이다.

1. 기본 생성자가 있는 경우 기본생성자를 사용한다.
2. 다른 생성자가 존재해도 무시하고 우선적으로 기본생성자를 사용한다.
3. 매개변수가 존재하는 생성자가 하나만 존재한다면 해당 생성자를 사용한다.

매개변수가 존재하는 생성자가 여러개 있으면 `@PersistenceConstructor` 어노테이션이 적용된 생성자를 사용한다. 만약 `@PersistenceConstructor`가 존재하지 않고, 기본 생성자가 없다면 `org.springframework.data.mapping.model.MappingInstantiationException`을 발생시킨다.

여기서 기본 생성자를 private으로 선언해도 정상적으로 잘 작동한다.

## 엔티티 내부 값 주입 과정

Spring Data JDBC는 생성자로 인해 채워지지 않은 필드들에 대해 자동으로 생성된 프로퍼티 접근자(Property Accessor)가 다음과 같은 순서로 멤버변수의 값을 채워넣는다.

1. 엔티티의 식별자를 주입한다.
2. 엔티티의 식별자를 이용해 참조중인 객체에 대한 값을 주입한다.
3. transient 로 선언된 필드가 아닌 멤버변수에 대한 값을 주입한다.
   
엔티티 맴버변수는 다음과 같은 방식으로 주입된다.

### 1. 멤버변수에 final 예약어가 있다면(immutable) wither 메서드를 이용하여 값을 주입한다.

```java
    // wither method
    public Sample withId(Long id) {
       // 내부적으로 기존 생성자를 이용하며 imuttable한 값을 매개변수로 가진다.
       return new Sample(id, this.sampleName);
   }
```

해당 wither메서드가 존재하지 않다면 `java.lang.UnsupportedOperationException: Cannot set immutable property ...` 를 발생시킨다.

### 2. 해당 멤버변수의 @AccessType이 PROPERTY라면 setter를 사용하여 주입한다.

setter가 존재하지 않으면 java.lang.IllegalArgumentException: No setter available for persistent property이 발생한다.

나머지 경우에는 기본적으로는 직접 멤버변수에 주입한다. (Field 주입)

## witherMethod

withMethod를 정의하는 경우는 final예약어가 있는 immutable한 멤버변수가 존재 할 때이다. 이때 주의해야할 점이 있다.

만약 immutable한 멤버변수가 n개라면 witherMethod또한 n개 작성해 주어야 합니다. 단순히 witherMethod 한개의 매개변수에 여러개의 immutable 필드를 주입한다면 `java.lang.UnsupportedOperationException: Cannot set immutable property`를 보게 된다.

또한 witherMethod의 이름을 잘못 작성해서는 안된다. 멤버변수의 이름이 createdAt 이라면 witherMethod의 이름은 멤버변수의 이름을 뒤에 붙힌 withCreatedAt으로 작성해야 한다. 테이블 컬럼 이름이 아닌 멤버 변수명을 따라서 작성해야한다.

---

참고

- https://docs.spring.io/spring-data/jdbc/docs/current/reference/html/#mapping.fundamentals