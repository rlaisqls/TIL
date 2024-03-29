<p>
DML은 데이터 조작어를 뜻한다. 테이블의 데이터를 입력/수정/삭제/조회하는 데 사용한다.
</p>
<p>
호스트 프로그램속에 삽입되어 사용되는 DML 명령어는 데이터 부속어(DSL, Data SubLanguage)라고 부르기도 한다.
</p>

|구분|설명|
|-|-|
|INSERT|테이블에 데이터를 신규로 입력할 때 사용한다.|
|UPDATE|테이블 내 행의 칼럼값을 수정할 때 사용한다.|
|DELETE|테이블 내의 행을 삭제할 때 사용한다.|
|SELECT|테이블에서 데이터를 조회할 때 사용한다.|

## DML 쿼리 예제
---
### 신규 데이터 입력
```sql
INSERT INTO 테이블명1
(컬럼명1, 컬럼명2)
VALUES
('데이터1','데이터2');
```
### 데이터 조회
```sql
SELECT 테이블명1.컬럼명1,
        테이블명1.컬럼명2 
FROM 테이블명1
WHERE 컬럼명1 = '데이터1';
```
DISTINCT라는 조건을 지정해서 중복 행 없이 출력할 수도 있다.
```sql
SELECT DIStiNCT 테이블명1.컬럼명1,
        테이블명1.컬럼명2 
FROM 테이블명1
WHERE 컬럼명1 = '데이터1';
```
앨리어스(Alias)를 지정해 칼럼에 접근하는 테이블명, 출력하는 칼럼명을 임시로 바꿀 수도 있다.
```sql
SELECT A.컬럼명1 AS COLUMNNAME1
     , A.컬럼명2 AS COLUMNNAME2
FROM 테이블명1 A
WHERE 컬럼명1 = '데이터1';
```
### 데이터 수정
```sql
UPDATE 테이블명1
SET 컬럼명1 = '새데이터1'
WHERE 컬럼명1 = '데이터1';
```
### 데이터 삭제
```sql
DELETE
FROM 테이블명1
WHERE 컬럼명1 = '새데이터1';
```
