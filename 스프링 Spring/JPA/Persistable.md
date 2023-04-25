# 📖 Save or Update

`CrudRepository`의 기본 구현인 `SimpleJpaRepositoryy`의 save 메서드는 이렇게 구현되어있다.

```java
// SimpleJpaRepository의 save method
	@Transactional
	@Override
	public <S extends T> S save(S entity) {

		Assert.notNull(entity, "Entity must not be null.");

		if (entityInformation.isNew(entity)) {
			em.persist(entity);
			return entity;
		} else {
			return em.merge(entity);
		}
	}
```

new인 경우에는 insert 쿼리를 날리고, 그렇지 않은 경우에는 update 쿼리를 날린다. R2DBC도 똑같다.

```java
// SimpleR2dbcRepository의 save method
	@Override
	@Transactional
	public <S extends T> Mono<S> save(S objectToSave) {

		Assert.notNull(objectToSave, "Object to save must not be null!");

		if (this.entity.isNew(objectToSave)) {
			return this.entityOperations.insert(objectToSave);
		}

		return this.entityOperations.update(objectToSave);
	}
```

`AbstractEntityInformation`의 isNew에서는

- 타입이 null이거나
- Number이면서 값이 0
인 경우 true를 반환하고,

- primitive 타입이 아니면서 값이 존재하면 
false를 반환하며, primitive 타입 필드면 에러를 던지는 것이 기본 전략이다.

```java
	@Override
	public boolean isNew(Object entity) {

		Object value = valueLookup.apply(entity);

		if (value == null) {
			return true;
		}

		if (valueType != null && !valueType.isPrimitive()) {
			return false;
		}

		if (value instanceof Number) {
			return ((Number) value).longValue() == 0;
		}

		throw new IllegalArgumentException(
				String.format("Could not determine whether %s is new; Unsupported identifier or version property", entity));
	}
```

여기서, ID를 직접 지정하기 위해 자동 생성 전략을 선택하지 않았을 경우엔 insert이전에 select 쿼리가 한번 나가는 것을 확인할 수 있다. `ID` 필드에 값을 세팅해주면 `isNew()`에서 (ID 필드가 null이 아니라) `false`를 반환하고, 그 결과 `merge()`가 호출되기 때문이다.

변경을 위해선 변경 감지(dirty-checking)를, 저장을 위해선 `persist()`만이 호출되도록 유도해야 실무에서 성능 이슈 등을 경험하지 않을 수 있다. 위와 같이 `merge`가 호출되지 않도록 하려면 enitty에서 `Persistable` 인터페이스를 상속받게 하고, overriding해주는 방법이 있다.

```java
public interface Persistable<ID> {

	/**
	 * Returns the id of the entity.
	 *
	 * @return the id. Can be {@literal null}.
	 */
	@Nullable
	ID getId();

	/**
	 * Returns if the {@code Persistable} is new or was persisted already.
	 *
	 * @return if {@literal true} the object is new.
	 */
	boolean isNew();
}
```