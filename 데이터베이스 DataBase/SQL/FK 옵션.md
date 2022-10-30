# 🐬 FK 옵션

## Delete(/Modify) Action

**RESTRICT**<br>
본인의 PK값이 Child 테이블에 FK로 존재하지 않는 경우에만 삭제를 허용한다.

**NO ACTION** : 참조무결성을 위반하는 삭제/수정 액션을 취하지 않는다. 표준 SQL에 등장하는 키워드로, MySQL에서는 `RESTRICT` 옵션과 동일한 기능이다.

**CASCADE**<br>
부모 테이블에서 `UPDATE` 및 `DELETE`8 연산이 발생하면 해당 인스턴스를 참조하고 있는 자식 테이블에도 자동으로 연산을 수행한다.

**SET NULL**<br>
Child 테이블이 존재하지 않는(삭제된) 키를 FK로 가지고 있는 경우 Null값으로 처리한다.

**SET DEFAULT**<br>
Child 테이블이 존재하지 않는(삭제된) 키를 FK로 가지고 있는 경우 기본값을 삽입한다.