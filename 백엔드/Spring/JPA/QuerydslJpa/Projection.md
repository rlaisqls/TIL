
Projection은 엔티티를 그냥 그대로 가지고 오지 않고, 필요한 정보만 추출해오는 것을 의미한다. Querydsl 에서는 프로젝션 대상이 하나면 명확한 타입을 지정할 수 있지만 프로젝션 대상이 둘 이상이라면 Tuple 이나 DTO 로 조회해야 한다.

### 순수 JPA에서의 Projection
``` java
    @Test
    void projectionWithJpa() {
        //given
        //when
        List<MemberDto> results = em.createQuery(
                        "select new com.study.querydsl.dto.MemberDto(m.username, m.age)" +
                                "from Member m", MemberDto.class
                )
                .getResultList();
        //then
        results.forEach(dto -> System.out.println(dto.toString()));
    }
```

순수 JPA 에서 DTO 를 조회할 때는 new 키워드를 이용한 생성자를 통해서만 가능했고, package 이름을 모두 명시해야해서 불편했다.

Querydsl에서는 Projections클래스의 메서드(`bean()`, `fields()`, `constructor()`)를 사용하는 방법과, Dto를 Q-Class로 등록하여 사용하는 방법이 있다. 

### Projections

```java
    @Test
    public void projectionWithQuerydsl1() {
        //given
        //when
        //Setter 사용해 생성
        List<MemberDto> results1 = queryFactory
                .select(Projections.bean(MemberDto.class,
                        member.username,
                        member.age))
                .from(member)
                .fetch();

        //필드에 직접 접근해 생성
        List<MemberDto> results2 = queryFactory
                .select(Projections.fields(MemberDto.class,
                        member.username,
                        member.age))
                .from(member)
                .fetch();

        //생성자를 사용해 생성
        List<MemberDto> results3 = queryFactory
                .select(Projections.constructor(MemberDto.class,
                        member.username,
                        member.age))
                .from(member)
                .fetch();
        //then
    }
```

Projections클래스에서 Dto형식으로 입력받을 수 있도록 해주는 위의 세 메서드는, 출력 결과는 거의 똑같지만 내부적으로 처리하는 방법이 다르다.

`bean()`은 Dto 클래스의 기본 생성자와 Setter를 사용해 객체를 생성한다.

`fields()`은 Dto 클래스의 필드에 리플렉션으로 접근하여 객체를 필드에 주입한다.

`constructor()`는 생성자를 통해 Dto 객체를 생성한다.

상황에 따라서 적절히 사용하면 될 것 같다.

### Q-Class로 등록

생성자에 `@QueryProjection`를 붙이면 Querydsl에서 쿼리를 생성할 때 사용할 수 있는 Q-Class를 만들어준다.

```java
@NoArgsConstructor
@Getter
public class MemberDto {
    private String username;
    private int age;

    @QueryProjection
    public MemberDto(String username, int age) {
        this.username = username;
        this.age = age;
    }
}
```

```java
@Generated("com.querydsl.codegen.DefaultProjectionSerializer")
public class QMemberDto extends ConstructorExpression<MemberDto> {

    private static final long serialVersionUID = -1034590129L;

    public QMemberDto(com.querydsl.core.types.Expression<String> username, com.querydsl.core.types.Expression<Integer> age) {
        super(MemberDto.class, new Class<?>[]{String.class, int.class}, username, age);
    }

}
```

하지만 이렇게 생성된 Q-Class에는 Entity의 Q-Class와는 달리 static 인스턴스가 없기 때문에 조회를 할 때 새 인스턴스를 만들어서 사용해야한다.

```java
    @Test
    public void projectionWithQuerydsl2() {
        //given
        //when
        List<MemberDto> results = queryFactory
                .select(new QMemberDto(member.username, member.age))
                .from(member)
                .fetch();
        //then
        results.forEach(System.out::println);
    }
```

제일 깔끔한 방법이고, type-safe하다는 장점이 있지만 Dto가 Querydsl 에 대한 의존성을 가지기 떄문에 라이브러리를 바꿀 때 많은 코드를 수정해야한다는 단점이 있다.