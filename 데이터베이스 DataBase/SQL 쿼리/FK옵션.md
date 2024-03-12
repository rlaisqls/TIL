
## Delete(/Modify) Action

1. Cascade: Master 삭제 시 Child 같이 삭제
2. Set Null: Master 삭제 시 Child의 FK 필드 Null
3. set Default: Master 삭제 시 Child FK 필드 Default 값으로 설정
4. Restrict: Child 테이블에 PK 값이 없는 경우만 Master 삭제 허용
5. No Action: 참조 무결성을 위반하는 삭제/수정 액션을 취하지 않음(MySQL에서는 Restrict와 동일함)

## Insert Action

1. Automatic: Master 테이블에 PK가 없는 경우 Master PK를 생성 후 Child
2. Set Null: Master 테이블에 PK가 없는 경우 Child 외부키를 Null 값으로 처리
3. Set Default: Master 테이블에 PK가 없는 경우 Child 외부키를 지정된 기본값으로 입력
4. Dependant: Master 테이블에 PK가 존재할 때만 Child 입력 허용
5. No Action: 참조무결성을 위반하는 입력 액션을 취하지 않음