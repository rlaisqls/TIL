# 🐬 GROUPING SETS와 GROUPING

## GROUPING SETS

인자별 소계를 계산한다.

```sql
SELECT 종, 성별, SUM(*) AS 마릿수
FROM 반려동물
GROUP BY GROUPING SETS(종, 성별);
```

#### 결과

|종|성별|마릿수|
|-|-|-|
|강아지|(null)|10|
|고양이|(null)|12|
|앵무새|(null)|7|
|(null)|F|15|
|(null)|M|14|


## GROUPING

GROUPING은 ROLLUP이나 CUBE, GROUPING SETS 등의 그룹함수에 의해 컬럼 값이 소계나 총합과 같이 집계된 데이터일 경우 1을 리턴하고 만약 집계된 데이터가 아니면 0을 리턴하는 함수이다.

`WHEN THEN`문과 같이 사용하여 아래와 같이 응용할 수 있다.

```sql
SELECT 종,
       성별,
       SUM(*) AS 마릿수,
       WHEN GROUPING(d.DEPARTMENT_NAME) = 1  THEN '합계 TOTAL' 
FROM 반려동물
GROUP BY ROLLUP(종);
```