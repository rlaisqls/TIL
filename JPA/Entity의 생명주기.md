# Entity의 생명주기
<img src="./image/Entity의 생명주기.png" height = 300px>

### 비영속(new/transient)
영속성 컨텍스트와 관련없는 순수한 객체 상태
### 영속(managed)
EntityManager를 통해 엔티티가 영속성 컨텍스트에 저장되어 영속성 컨텍스트가 관리중인 상태
### 준영속(detached)
영속성 컨텍스트에 저장되었다가 분리된(detached) 상태
### 삭제(removed)
엔티티를 영속성 컨텍스트와 데이터베이스에서 삭제된 상태