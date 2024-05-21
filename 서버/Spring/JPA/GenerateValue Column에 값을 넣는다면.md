
Hexagonal architecture를 사용해서 구현하다 문제가 생겼다.

해당 [프로젝트](https://github.com/team-aliens)에선 기본 PK로 UUID를 사용했고, 새로 생성한 도메인 모델은 id 값을 `UUID(0, 0)`으로 설정해서 사용했다. (여기서 중요하진 않지만 생성 전략은 `IdentifierGenerator`로 TimeBasedUUID를 생성할 수 있도록 직접 정의된 상태였다.)

`UUID(0, 0)`으로 설정해주다 보니 기존에는 새 insert문을 날려야하는 경우 `isNew`가 Persistable 기본 전략에 따라 false로 들어갔고, `merge`가 호출되었다. [여기](./Persistable.md)에서 알아봤던 것 처럼 영속성 컨텍스트에 등록되지 않은 객체에 대해 `merge`를 호출하면, 어떤 `update`문(혹은 insert문)을 날려야하는지를 알아야 하기 때문에 `select` 쿼리를 한번 날리게 되는데, 이것을 막아주기 위해 BaseEntity에 `Persistable`을 상속받고 변수를 정의해서 새로운 객체인지 여부를 표시하도록 했다. 

즉, 새 객체 생성시 merge가 아닌 persist를 호출하려고 했다.

```kotlin
@MappedSuperclass
abstract class BaseUUIDEntity(

    @get:JvmName("getIdValue")
    @Id
    @GeneratedValue(generator = "timeBasedUUID")
    @GenericGenerator(name = "timeBasedUUID", strategy = "team.aliens.dms.persistence.TimeBasedUUIDGenerator")
    @Column(columnDefinition = "BINARY(16)", nullable = false)
    val id: UUID?

): Persistable<UUID> {

    @Transient
    private var isNew = true

    override fun getId() = id
    override fun isNew() = isNew

    @PrePersist
    @PostLoad
    fun markNotNew() {
        isNew = false
    }
}
```

그랬는데 jpa crudRepository를 호출하는 경우 아래와 같은 에러가 발생했다.

```
org.hibernate.PersistentObjectException: detached entity passed to persist: team.aliens.dms.persistence.studyroom.entity.StudyRoomJpaEntity
```

detach 상태인데 persist를 호출했기 때문에 에러가 난다고 한다. 실제로 `org.hibernate.event.internal.DefaultPersistEventListener`의 `onPersist` 메서드에는 이러한 내용이 있었다.

```java
// DefaultPersistEventListener.java
	public void onPersist(PersistEvent event, Map createCache) throws HibernateException {
		final SessionImplementor source = event.getSession();
		final Object object = event.getObject();

        ...

		final EntityEntry entityEntry = source.getPersistenceContextInternal().getEntry( entity );
		EntityState entityState = EntityState.getEntityState( entity, entityName, entityEntry, source, true );
		if ( entityState == EntityState.DETACHED ) {
			// JPA 2, in its version of a "foreign generated", allows the id attribute value
			// to be manually set by the user, even though this manual value is irrelevant.
			// The issue is that this causes problems with the Hibernate unsaved-value strategy
			// which comes into play here in determining detached/transient state.
			//
			// Detect if we have this situation and if so null out the id value and calculate the
			// entity state again.

			// NOTE: entityEntry must be null to get here, so we cannot use any of its values
			EntityPersister persister = source.getFactory().getEntityPersister( entityName );
			if ( ForeignGenerator.class.isInstance( persister.getIdentifierGenerator() ) ) {
				if ( LOG.isDebugEnabled() && persister.getIdentifier( entity, source ) != null ) {
					LOG.debug( "Resetting entity id attribute to null for foreign generator" );
				}
				persister.setIdentifier( entity, null, source );
				entityState = EntityState.getEntityState( entity, entityName, entityEntry, source, true );
			}
		}
        ...
    }
```

해석해보자면, id 속성값이 유저로부터 임의로 설정되는 경우 detached, transient 상태를 결정하는 Hibernate unsaved-value 전략에 문제가 발생하기 때문에 id 값을 무효화하고 엔티티 상태를 다시 계산한다는 것이다.

그리고 여기서 계산한 state가 `detech`인 경우에는 예외를 던진다.

```java
        ...
		switch ( entityState ) {
			case DETACHED: {
				throw new PersistentObjectException(
						"detached entity passed to persist: " +
								EventUtil.getLoggableName( event.getEntityName(), entity )
				);
			}
            ...
        }
```


---
참고 
- https://stackoverflow.com/questions/73136683/detached-entity-passed-to-persist-when-setting-id-explicitly-and-usage-of-gen
- https://www.inflearn.com/questions/121326