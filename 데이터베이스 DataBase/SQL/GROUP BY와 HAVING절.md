# 🐬 GROUP BY절
GROUP BY절은 GROUP BY절에 기재한 컬럼을 기춘으로 결과 집합을 그룹화한다. 이 GROUP BY절을 사용하면 소그룹별 기준 칼럼을 정한 후, 집계 함수를 사용하여 그룹별 통계를 계산할 수 있다. 

### GROUP BY절 쿼리 예제
코드
```sql
SELECT A.species, 
       SUM(A.count) AS "마릿수"
FROM animal A
WHERE A.birth_day = '2022%'
GROUP BY A.species;
```
결과
```
species | 마릿수
--------|--------
강아지  | 45
고양이  | 40
앵무새  | 15
```

# 🐬 HAVING절
<p>
HAVING절은 그룹을 나타내는 결과집합의 행에 조건이 적용된다. HAVING절에는 GROUP BY절의 기준 항목이나 소그룹의 집계함수가 조건으로 사용되고, 만들어진 소그룹 중 HAVING절 조건에 만족되는 내용만 출력한다.
</p>
<p>
WHERE절과 유사한 기능을 하지만, 테이블에서 추출할 행을 제한하는 WHERE절과 다르게 HAVING절은 그룹핑한 경과집합에 대한 조건을 주어 추출할 집계 데이터를 필터링한다는 차이점이 있다.
</p>

### HAVING절 쿼리 예제
코드
```sql
SELECT A.species, 
       SUM(A.count) AS "마릿수"
FROM animal A
WHERE A.birth_day = '2022%'
GROUP BY A.species;
HAVING SUM(A.count) > 20;
```
결과
```
species | 마릿수
--------|--------
강아지  | 45
고양이  | 40
```