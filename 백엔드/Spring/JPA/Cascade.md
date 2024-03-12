
cascade 옵션은 jpa를 사용할때 @OneToMany나 @ManyToOne에 옵션으로 줄 수 있는 값이다. cacade 옵션을 사용하면 부모 엔티티에 상태 변화가 생길 때 그 엔티티와 연관되어있는 엔티티에도 상태 변화를 전이시킬 수 있다. 즉, 자식 엔티티의 생명주기를 관리할 수 있다.

## cascade 타입의 종류

### PERSIST

- 부모 엔티티를 저장하면 자식 엔티티까지 함께 저장한다.

- 다시말해, 명시적으로 부모엔티티와 연관관계를 가진 자식 엔티티 영속화시킬때 따로 명시할 필요 없이 `부모.자식 = 자식 인스턴스` 과 같이 적으면 자식 엔티티도 데이터베이스에 자동으로 저장된다. 

### MERGE

- 데이터베이스에서 가져온 부모 객체를 통해 자식 엔티티의 정보를 수정하여 병합했을때 변경 결과가 자식 엔티티에 반영된다.

### REMOVE

- 부모 엔티티를 삭제하면 그 엔티티를 참조하고 있는 자식 엔티티(해당 부모 엔티티를 Foreign Key로 가지고있는 엔티티)도 함께 삭제된다. 

### REFRESH

- 부모 엔티티를 `refresh()` (DB에 저장되어있는 상태로 다시 가져옴) 할때 자식 엔티티도 함께 가져온다.

### DETACH

- 부모 엔티티가 `detach()`를 수행하게 되면, 연관된 엔티티도 `detach()` 상태가 되어 변경사항이 반영되지 않는다.

### ALL

- 위에 있는 상태 전이가 모두 적용된다.

---

다음과 같이 연관관계 매핑 어노테이션에 속성으로 지정해주면 된다.

```java
public class Card {
    ...
    @OneToMany(mappedBy = "card", cascade = CascadeType.REMOVE)
    private List<UserCard> userCards;
    ...
}
```

<div id="reference">연관 개념:</div>
엔티티의 생명주기 <a href="https://gmlwjd9405.github.io/2019/08/08/jpa-entity-lifecycle.html">https://gmlwjd9405.github.io/2019/08/08/jpa-entity-lifecycle.html</a>