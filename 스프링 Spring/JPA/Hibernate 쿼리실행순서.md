# Hibernate 쿼리 실행 순서

1. OrphanRemovalAction
2. AbstractEntityInsertAction
3. EntityUpdateAction
4. QueuedOperationCollectionAction
5. CollectionRemoveAction
6. CollectionUpdateAction
7. CollectionRecreateAction
8. EntityDeleteAction
   
## performExecutions

```java
protected void performExecutions(EventSource session)
```

Execute all SQL (and second-level cache updates) in a special order so that foreign-key constraints cannot be violated:
1. Inserts, in the order they were performed
2. Updates
3. Deletion of collection elements
4. Insertion of collection elements
5. Deletes, in the order they were performed

> delete 가 늦게 실행되는 이유(entity 일 때)
foreign key 제약 조건에 영향을 받을 우려가 있기때문에 이 상황을 고려하여 늦게 실행된다.

> insert 가 일찍 실행되는 이유
auto increment 일 수 있기때문에 이 상황을 고려하여 가장 먼저 실행된다.

https://docs.jboss.org/hibernate/orm/4.2/javadocs/org/hibernate/event/internal/AbstractFlushingEventListener.html
