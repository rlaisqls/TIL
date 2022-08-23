# 🐬 DDL(Data Definition Lanquage)
<p>
DDL은 데이터 정의어를 뜻한다. DB를 구성하는 물리적 객체(사용자, 테이블, 인덱스, 뷰, 트리거, 프로시저, 사용자 정의 함수 등)을 정의/변경/제거하는 데 사용한다.
</p>
<p>
테이블의 무결성 보장을 위해 <a href="./제약조건.md">제약조건</a>을 설정할 수도 있다. 
</p>

|구분|설명|
|-|-|
|CREATE|객체를 생성할때 사용한다.|
|ALTER|객체를 수정할때 사용한다.|
|DROP|객체를 삭제할때 사용한다.|

## DDL 쿼리 예제
---
### 테이블 생성
CREATE문을 통해 테이블을 생성하는 쿼리이다. 
```sql
CREATE TABLE 테이블명1(
    컬럼명1 DATATYPE,
    컬럼명2 DATATYPE,
    CONSTRAINT 제약조건명1 PRIMARY KEY(컬럼명1)
);
```
SELECT문으로 테이블을 생성하는 방법도 있다. (테이블 구조와 일부 데이터는 똑같이 복사되지만 제약조건은 복사되지 않는다.)
```sql
CREATE TABLE 테이블명2
AS SELECT * FROM 테이블명1;
```
### 외래키 생성
생성된 테이블에 외래키(FK)를 생성하는 쿼리이다. 
```sql
ALTER TABLE 테이블명1
ADD CONSTRAINT 제약조건명2 
FOREIGN KEY (컬럼명1)
REFERENCES 테이블명2 (컬럼명3);
```
---
### 칼럼 추가
```sql
ALTER TABLE 테이블명1 ADD (컬럼명 VARCHAR(5) NULL);  
```
### 칼럼 삭제
```sql
ALTER TABLE 테이블명1 DROP 컬럼명;  
```
### 데이터형 및 제약조건 변경
``` sql
ALTER TABLE 테이블명1 MODIFY(컬럼명 NUMBER(1)
                            DEFALT 0 NOT NULL
                            NOVALIDATE);  
```
### 제약조건 삭제
```sql
ALTER TABLE 테이블명1 DROP CONSTRAINT 제약조건명1;  
```
### 칼럼명 변경
```sql
ALTER TABLE 테이블명1
RENAME COLUMN 컬럼명 TO 새컬럼명;  
```
---
### 테이블명 변경
```sql
RENAME 테이블명1 TO 새테이블명1;
```
```sql
ALTER TABLE 테이블명1
RENAME 테이블명1 TO 새테이블명2;  
```
### 테이블 내 데이터 제거
```sql
TRUNCATE TABLE 테이블명1;
```
### 테이블 제거
```sql
DROP TABLE 테이블명1;
```
RESTRICT 명령어를 붙이면 삭제할 테이블이 참조 중인 경우에 테이블을 삭제하지 않는다.
```sql
DROP TABLE 새테이블명1 RESTRICT;
```
CASCADE 명령어를 붙이면 삭제할 테이블을 참조 중인 모든 요소를 전부 삭제한다.
```sql
DROP TABLE 새테이블명1 CASCADE;
```