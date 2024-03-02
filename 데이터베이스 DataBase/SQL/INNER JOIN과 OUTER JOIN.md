
JOIN은 두 테이블의 데이터를 합치는 것을 의미한다. INNER JOIN과 OUTER JOIN은 그 방식에 차이가 있다. 중복 컬럼을 가지고 있지 않은 A와 B 테이블을 JOIN한다고 가정할때, <br> 일반적으로 INNER JOIN은 A와 B의 교집합, 즉 벤다이어그램으로 그렸을 떄 교차되는 부분이 결과로 추출되고, <br> OUTER JOIN은 A와 B의 합집합, 즉 벤타이어그램으로 그렸을 때 두 부분의 전체가 결과로 추출된다. (단, Left Outer Join과 Right Outer Join은 완전히 합집합은 아니다. 밑에서 예제로 더 알아보자)

<img src="https://www.codeproject.com/KB/database/Visual_SQL_Joins/Visual_SQL_JOINS_V2.png">

---

두개의 테이블이 있다고 가정해보자

```
A    B
-    -
1    3
2    4
3    5
4    6
```

### Inner Join

Inner join을 하면 두 집합에서 공통되는 열만 남는다.

```sql
SELECT *
FROM a
INNER JOIN b
ON a.a = b.b
```

```
a | b
--+--
3 | 3
4 | 4
```

### Left Outer Join

Left outer join을 하면 왼쪽에 있는 테이블(A) 전체와, B 테이블에서 공통되는 부분이 남는다. 공통되지 않는 부분은 null이 된다.

```sql
select * from a LEFT OUTER JOIN b on a.a = b.b;
```

```
a |  b
--+-----
1 | null
2 | null
3 |    3
4 |    4
```

### Right Outer Join

Right outer join을 하면 오른쪽에 있는 테이블(B) 전체와, A 테이블에서 공통되는 부분이 남는다. 공통되지 않는 부분은 null이 된다.

```sql
SELECT *
FROM a
RIGHT OUTER JOIN b
ON a.a = b.b
```

```
a    |  b
-----+----
3    |  3
4    |  4
null |  5
null |  6
```

### Full outer join

Full outer join을 하면 A와 B의 합집합을 얻게 됩니다. B에는 있는데 A에 없는 부분은 A에서는 해당 부분이 null 이 되고, A에는 있는데 B에 없는 부분에서는 B에서는 해당 부분이 null 이 된다.

```sql
SELECT *
FROM a
FULL OUTER JOIN b
ON a.a = b.b
```

```
 a   |  b
-----+-----
   1 | null
   2 | null
   3 |    3
   4 |    4
null |    6
null |    5
```

용어가 조금 헷갈리지만, 제대로 숙지해야한다.