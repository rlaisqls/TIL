# 📖 OrphanRemoval

<p><a href="./Cascade.md">cascade</a> 옵션을 사용하면 부모 엔티티에 상태 변화가 생길 때 그 엔티티와 연관되어있는 엔티티에도 상태 변화를 전이시킬 수 있다. 그러나 cascade 옵션을 사용한다고 해서 부모 엔티티에서 자식 엔티티의 생명주기를 완전히 통제할 수 있는 것은 아니다.</p>

<p>cascade의 REMOVE 옵션은, 부모 엔티티를 삭제했을때 그 엔티티를 참조하고 있는 자식 엔티티(해당 부모 엔티티를 Foreign Key로 가지고있는 엔티티)도 함께 삭제해준다. 하지만 부모 엔티티에서 자식 엔티티를 삭제했을때에는 그 참조를 끊어줄 뿐, 그 자식 엔티티를 같이 삭제해주진 않는다. (심지어 FK에 NotNull 제약조건을 걸어놨으면 아무 변화도 생기지 않는다)</p>

<p>그럴 때 사용할 수 있는 것이 OrphanRemoval이다. OrphanRemoval은 말 그대로 고아 객체를 삭제해준다는 뜻인데, 이걸 설정에 추가해주면 부모 엔티티에서 자식 엔티티를 삭제하여 참조를 끊었을때, 고아 객체가 된 자식 객체에 대한 DELETE 쿼리를 날려준다. </p>

<p>cascadeType.ALL과 orphanRemoval를 모두 적용하면 부모 엔티티에서 자식 엔티티의 생명주기를 전부 통제할 수 있게 된다. 부모 엔티티에 자식 엔티티를 추가하면 새 엔티티가 저장되고, 부모에서 자식 엔티티와의 연관관계를 끊으면 그 자식 엔티티는 삭제되니까 말이다. 부모 엔티티에서 자신을 참조하는 엔티티에 대한 강력한 통제를 할 수 있는 설정이기 때문에 양쪽 다 FK를 가지고 있는 연관관계거나 자식 엔티티가 다른 엔티티를 참조하고 있을 때에는 큰 문제가 생길 수 있다. (이건 cascade 설정도 마찬가지이다.)</p>

<p>즉, cascade와 orphanRemoval은 부모 엔티티를 완전히 개인적으로 소유하는 경우에 사용하는 것이 좋다. </p>

---

<p>나의 경우엔 유저가 소유하는 엔티티를 유저 클래스에서 관리하기 위해 orphanRemoval을 처음으로 사용하게 되었다. </p>

<p>자세히 말하자면 DB에 고정적으로 저장되어있는 카드가 있어서 그 카드를 유저가 여러개 가질 수 있는 구조였다. 그 두 테이블을 다대다로 연결하기 위해서 UserCard라는 중간 테이블을 만들었는데, 여기서 User(부모)와 UserCard(자식)에cascadeType.ALL과 orphanRemoval를 적용했다.</p>

```java
//User와 UserCard 1:N관계로 매핑하고, 그 카드를 지우는 메서드를 User 클래스 내부에 구현했다.
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Entity
public class User {
    ...
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<UserCard> userCardList;

    ...
        public void removeCard(Card card, int cardCount) {

        this.cardCount.removeCount(card.getGrade(), cardCount);

        List<UserCard> userCardListToDelete = this.userCardList
                .stream()
                .filter(o -> o.getCard() == card)
                .limit(cardCount)
                .collect(Collectors.toList());

        for (UserCard userCard : userCardListToDelete) {
            this.userCardList.remove(userCard);
        }
    }
    ...
}
```

<p>더 자세히 말하자면, 프로젝트의 요구사항에 따라서 User의 Card를 추가하거나 삭제하는 동작이 필요했는데, 그럴 때 서비스 클래스에서 UserCardRepository를 상속받아서 삭제할 UserCard를 조회하여 직접 UserCard를 삭제하는 것 보다는 User에서 userCardList 필드에 접근해서 .remove()하는 것이 유저 객체의 캡슐화를 유지하기 위해 더 나은 방법이라고 생각했기 때문에 User 클래스에 내부 메서드를 만들어 UserCard를 삭제하고, 추가할 수 있도록 하고싶었다.</p>

<p>그렇게 구현하기 위해선 cascade와 orphanRemove을 설정하여 영속성 컨텍스트에 저장되어있는 부모 엔티티에서 자식 엔티티에 접근하여 데이터를 삽입/삭제할 수 있어야 했다. UserCard는 User가 소유하고 있는 Card들의 정보를 담고있으니 UserCard의 리스트를 관리하고 조회하는 것은 유저밖에 없기 때문에 부모 엔티티에서 자식 엔티티의 생성/삭제를 모두 통제할 수 있도록 설정해도 문제가 생기지 않을 것이라 판단했고, 두 옵션을 활용해 기능을 구현하게 되었다.</p>

<p>그래서 결과적으론 User 엔티티에서 UserCard의 엔티티의 생명주기를 전부 통제할 수 있게 되었고, 원했던 구조대로 코드를 작성할 수 있었다.</p>

<p>cascade만 설정해줘도 부모 엔티티에서 자식 엔티티의 삭제까지 전부 관리할 수 있다고 생각했는데, 부모 엔티티에서 자식 엔티티를 삭제한다는 것이 자식 엔티티의 참조를 끊는 것 뿐이라는 사실을 알게되었다. 테이블간의 관계를 맺고, 데이터를 관리하는 것이 생각보다 복잡한 일인 것 같다. 이번 기회를 통해 JPA와 DB에 대해 아는 것이 얼마나 중요한지 깨닫게 되었다. </p>
<p>위에서 설명한 코드는 이 <a href="https://github.com/YouGoodBackEnd/DSM-TCG-Backend/blob/master/src/main/java/com/project/tcg/domain/user/domain/User.java">링크</a>에서 자세히 볼 수 있다.</p>


참고: <br>
 https://www.baeldung.com/jpa-cascade-remove-vs-orphanremoval<br>
https://velog.io/@banjjoknim/JPA에서-Cascade-orphanRemoval을-사용할-때-주의해야할-점