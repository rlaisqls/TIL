# 📖 JPA(Java persistence API)

JPA는 자바의 ORM(Object-Relational Mapping) 기술의 표준으로, 객체와 테이블을 매핑해 패러다임의 불일치를 개발자 대신 해결하는 기술이다. 객체는 객체대로 생성하고, 데이터베이스는 데이터베이스에 맞게 설계할 수 있도록 해준다.

## Repository interface
JPA는 Repository라는 interface를 통해 지속성 저장소에 대한 데이터 액세스 계층을 구현하는 데 필요한 상용구 코드의 양을 크게 줄일 수 있도록 해준다. Repository를 상속받은 하위 인터페이스의 종류로는 CrudRepository, PagingAndSortingRepository, JpaRepository 등이 있고 각 인터페이스가 적절한 기본 메서드를 지정하고 있다.

```java
//ex) CrudRepository
public interface CrudRepository<T, ID> extends Repository<T, ID> {

  <S extends T> S save(S entity);      

  Optional<T> findById(ID primaryKey); 

  Iterable<T> findAll();               

  long count();                        

  void delete(T entity);               

  boolean existsById(ID primaryKey);   

  // … more functionality omitted.
}
```

이 Repository interface를 상속받은 interface에서 JPQL(`@Query ` 어노테이션)을 사용해 DAO(Data Access Object)의 메서드를 직접 선언할 수도 있고, Spring Data 리포지토리 인프라에 구축된 쿼리 빌더 메커니즘을 통해 쿼리를 생성할 수도 있다. 

JPA를 사용하여 복잡한 동적 쿼리를 생성할 떄 타입 안정성(type-safe)을 지킬 수 있도록 하는 Querydsl이라는 프레임워크도 있다.