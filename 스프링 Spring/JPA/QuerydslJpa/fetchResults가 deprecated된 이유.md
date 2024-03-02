
### <a href="http://querydsl.com/static/querydsl/5.0.0/apidocs/com/querydsl/jpa/impl/AbstractJPAQuery.html#fetchResults--">#</a> 공식 Docs 설명
```
fetchResults() : Get the projection in QueryResults form. Make sure to use fetch() instead if you do not rely on the QueryResults.getOffset() or QueryResults.getLimit(), because it will be more performant. Also, count queries cannot be properly generated for all dialects. For example: in JPA count queries can’t be generated for queries that have multiple group by expressions or a having clause. Get the projection in QueryResults form. Use fetch() instead if you do not need the total count of rows in the query result.
```

fetchCount와 fetchResult는 querydsl 작성한 select 쿼리를 기반으로 count 쿼리를 만들어낸다. 쿼리를 만들어내는 방식은 단순히 기존 쿼리의 결과를 감싸 쿼리를 생성하는 식이다.

`SELECT COUNT(*) FROM (<original query>).`

단순한 쿼리에선 위와 같은 방식으로 count 쿼리를 날려도 괜찮지만, 복잡한 쿼리(group by having 절 등을 사용하는 다중그룹 쿼리)에서는 잘 작동하지 않는다고 한다. 그렇기 때문에 Page로 결과를 반환하고 싶다면 별도의 카운트 쿼리를 날린 후 직접 생성자를 통해 생성해야한다.

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
                .select(Wildcard.count)
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