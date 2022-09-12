다대일 연관관계를 맺고 있는 Member와 Team이라는 엔티티가 있다고 하자.

```java
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "team_id")
    private Team team;

    public Member(Team team) {
        this.team = team;
    }
}
```

```java
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
public class Team {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
}
```

이때, Member 엔티티를 조회하기 위해선 Team 엔티티를 가져와서 save 해줘야한다.

(Team을 조회하는 쿼리가 하나 필요하다.)

```java
Team team = teamRepository.findById(teamId).get();
Member member = new Member(team);
memberRepository.save(member);
```

객체지향적으로는 객체들끼리 연관관계를 맺는 위와 같은 코드가 좋다.

하지만 여러 Member를 저장해야하는 상황이라면 각각의 Team을 select하는 것이 부담이 될 수 있다. save() 작업이 1,000건, 10,000 건 이상 이뤄지는 경우라면 select 쿼리도 1,000건, 10,000건 만큼 더 나가는 것이다.

하지만 Member를 생성할때 Team 엔티티의 정보를 모두 가져와 주입하는 것이 아니라, Team의 Id만 넣어서 저장한다면 이러한 문제를 해결할 수 있을 것이다. 

Member 엔티티를 다음과 같이 수정하면 된다.

```java
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
public class Member {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(targetEntity = Team.class, fetch = FetchType.LAZY)
    @JoinColumn(name = "team_id", insertable = false, updatable = false)
    private Team team;

    @Column(name = "team_id")
    private Long teamId;

    public Member(Long teamId) {
        this.teamId = teamId;
    }
}
```

Member엔티티와 연관관계가 맺어져있는 Team 필드를 주입하거나 수정할 수 없게 하고, 조인한 컬럼과 같은 이름으로 또 하나의 필드 변수를 만들어줬다. 

이렇게 하면 Long 타입의 id를 주입하는 것만으로 team과의 연관관계를 만들 수 있다.

Member에서 Team을 조회하는 경우(`Member.getTeam()`) 하이버네이트가 team_id컬럼을 통해 엔티티를 알아서 조회해주기 때문에 Member를 가져와서 사용할때는 기존과 같이 사용할 수 있다. 하지만 Team 엔티티를 Member에 직접 주입할 수 없게 되고, 데이터 무결성이 깨질 수 있기 때문에 (해당 TeamId를 가진 엔티티가 존재하지 않는 경우) 해당 부분을 조심하면서 사용해야한다.

참고: https://stackoverflow.com/questions/27930449/jpa-many-to-one-relation-need-to-save-only-id