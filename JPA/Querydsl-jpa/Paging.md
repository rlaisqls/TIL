# 🤔 Paging

Querydsl에서 페이징하는 방법을 알아보자.

Page는 인터페이스이기 떄문에, Page를 반환하기 위해선 Page를 구현한 구체클래스를 생성해야한다. 그렇기 때문에 아래 코드에선 스프링 데이터에 있는 PageImpl 클래스를 사용하여 return 하도록 한다.

fetchResults()를 사용하여 total count쿼리와 결과 리스트를 한 코드로 조회하도록 할 수도 있지만, fetchResults()와 fetchCount()가 특정 상황에서 제대로 동작하지 않는 이슈때문에 depercated 되었으므로 따로 count를 조회하여 반환하는 방식을 택했다.  

원하는 컬럼을 Dto로 만들어서 조건에 따라 조회한 후 반환하는 예제 코드이다.

```java
    public Page<MemberTeamDto> searchPage(MemberSearchCondition condition, Pageable pageable) {
        List<MemberTeamDto> results = queryFactory
                .select(new QMemberTeamDto(
                        member.id.as("memberId"),
                        member.username,
                        member.age,
                        team.id.as("teamId"),
                        team.name.as("teamName")
                ))
                .from(member)
                .leftJoin(member.team, team)
                .where(
                        usernameEq(condition.getUsername()),
                        teamNameEq(condition.getTeamName()),
                        ageGoe(condition.getAgeGoe()),
                        ageLoe(condition.getAgeLoe())
                )
                .offset(pageable.getOffset())
                .limit(pageable.getPageSize())
                .fetch();

        Long count = queryFactory
                .select(member.count())
                .from(member)
                .leftJoin(member.team, team)
                .where(
                        usernameEq(condition.getUsername()),
                        teamNameEq(condition.getTeamName()),
                        ageGoe(condition.getAgeGoe()),
                        ageLoe(condition.getAgeLoe())
                )
                .fetchOne();

        return new PageImpl<>(results, pageable, count);
    }
```

## 최적화

PageImpl 대신에 스프링 데이터의 PageableExecutionUtils의 getPage() 메서드를 사용하면 Count 쿼리를 생략해도 되는 경우에 최적화를 해줄 수 있다. 최적화 할 수 있는 경우는 두가지가 있다.

1. 첫번째 페이지이면서 컨텐츠 사이즈가 페이지 사이즈보다 작을 때
    ex) 하나의 페이지에 100개의 컨텐츠를 보여주는데, 총 데이터가 100개가 안되는 경우

2. 마지막 페이지일 때 (offset + 컨텐츠 사이즈를 더해서 전체 사이즈를 구할 수 있기 때문)

극적인 성능 개선 효과를 누릴 순 없지만, 일부 상황에서 조금이라도 쿼리를 아끼고 싶은 경우 사용할 수 있는 방법이다. count 조회 쿼리를 즉시 실행하지 않고, JPAQuery 상태로 파라미터에 넣으면 된다.

```java
    public Page<MemberTeamDto> searchPage(MemberSearchCondition condition, Pageable pageable) {
        List<MemberTeamDto> results = queryFactory
                .select(new QMemberTeamDto(
                        member.id.as("memberId"),
                        member.username,
                        member.age,
                        team.id.as("teamId"),
                        team.name.as("teamName")
                ))
                .from(member)
                .leftJoin(member.team, team)
                .where(
                        usernameEq(condition.getUsername()),
                        teamNameEq(condition.getTeamName()),
                        ageGoe(condition.getAgeGoe()),
                        ageLoe(condition.getAgeLoe())
                )
                .offset(pageable.getOffset())
                .limit(pageable.getPageSize())
                .fetch();

        JPAQuery<Long> countQuery = queryFactory
                .select(member.count())
                .from(member)
                .leftJoin(member.team, team)
                .where(
                        usernameEq(condition.getUsername()),
                        teamNameEq(condition.getTeamName()),
                        ageGoe(condition.getAgeGoe()),
                        ageLoe(condition.getAgeLoe())
                );

        return PageableExecutionUtils.getPage(results, pageable, countQuery::fetchOne);
    }
```