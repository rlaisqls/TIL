
## ROLLUP

전체 학생 테이블에서

```sql
SELECT COUNT(*)
FROM student
GROUP BY (grade)
```

와 같이 데이터를 조회하면 1학년, 2학년, 3학년 각 학생의 인원 수가 조회되는데, 여기서 GROUP BY를 `GROUP BY ROLLUP (grade)`로 변경하면 각 학년별 인원수와 전체 인원수까지 모두 집계해준다.

```sql
SELECT student.grade AS 학년,
       COUNT(*) AS 인원수
FROM student
GROUP BY ROLLUP(grade)
```

#### 결과

|학년|인원수|
|-|-|
|1학년|72|
|2학년|80|
|3학년|80|
|(null)|232|

ROLLUP에 여러 인자를 넣는 경우에는, 인자를 넣는 순서에 따라 결과가 바뀔 수 있다.

## CUBE

CUBE 함수는 그룹핑 컬럼이 가질 수 있는 모든 경우의 수에 대하여 소계(SUBTOTAL)과 총계(GRAND TOTAL)을 생성한다. 컬럼간 카타시안 곱으로 통계를 낸다고 생각하면 된다. ROLLUP 함수와는 다르게 CUBE함수는 인자의 순서가 달라도 결과는 같다.

```sql
SELECT student.grade AS 학년,
       student.sex AS 성별,
       COUNT(*) AS 인원수
FROM student
GROUP BY CUBE(grade, sex)
```

#### 결과

|학년|성별|인원수|
|-|-|-|
|1학년|남자|62|
|1학년|여자|10|
|2학년|남자|71|
|2학년|여자|9|
|3학년|남자|67|
|3학년|여자|13|
|(null)|(null)|232|
