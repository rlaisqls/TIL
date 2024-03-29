## 💾 DBMS(Database Management System)
<p>
넓은 의미에서의 데이터베이스는 일상적인 정보들을 모아 놓은 것 자체를 의미한다. 일반적으로 DB라고 말할 떄는 특정 기업이나 조직 또는 개인이 필요한 데이터를 일정한 형태로 저장해 놓은 것을 의미한다.
</p>
<p>
사용자들은 보다 효율적인 데이터 관리뿐만 아니라 예기치 못한 사건으로 인한 데이터의 손상을 피하고, 필요할 때 데이터를 복구하기 위한 강력한 기능의 소프트웨어를 필요로 한다. 이러한 요구사항을 만족시켜주는 시스템을 데이터베이스 관리 시스템(DBMS)이라고 한다.
</p>

## 💾 RDBMS(Relational Database Management System)
<p>
관계형 데이터베이스는 정규화 이론에 근거한 합리적인 데이터 모델링을 통해 데이터 이상(Anomaly) 현상 및 불필요한 데이터 중복 현상을 피할 수 있다. 이러한 RDB를 관리하는 시스템 소프트웨어를 관계현 데이터베이스 관리 시스템(RDBMS)이라고 한다.
</p>

### RDBMS의 주요 기능
- 동시성 관리 및 병행 제어를 통해 많은 사용자들이 동시에 데이터를 공유 및 조작할 수 있는 기능을 제공한다.
- 메타 데이터를 총괄 관리할 수 있기 때문에 데이터의 성격, 속성 또는 표현 방법 등을 체계화 할 수 있고, 데이터 표준화를 통한 데이터 품질을 확보할 수 있는 장점이 있다.
- 인증된 사용자만이 참조할 수 있도록 보안 기능을 제공하고, 테이블 생성 시에 사용할 수 있는 다양한 제약조건을 이용하여 사용자 실수로 인한 잘못된 데이터 입력 및 관계성이 있는 중요 데이터의 삭제를 방지하여 데이터 무결성을 보장한다.
- 시스템의 갑작스러운 장애로부터 사용자가 입력/수정/삭제하는 데이터가 데이터베이스에 제대로 반영될 수 있도록 보장해주는 기능과, 시스템 ShutDown, 재해등의 상황에서도 데이터를 화복/복구할 수 있는 기능을 제공한다.
