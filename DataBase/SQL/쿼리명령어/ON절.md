# 🐬 ON절

On절은 조인문을 사용할때 조인할 조건을 설정하기 위한 명령어이다. 조회 결과를 필터링한다는 점에서 Where절과 비슷하지만, 실행 시기와 용도에 차이가 있다.

---

<img src="https://img1.daumcdn.net/thumb/R1280x0/?scode=mtistory2&fname=https%3A%2F%2Fblog.kakaocdn.net%2Fdn%2FcWaZO7%2FbtqGpypivYJ%2FSkIvFbYdzPzsOIsivCwcQ0%2Fimg.png">

<br>

On절은 Where절과 다르게 테이블 조인 이전에 실행된다. 그렇기 때문에 Join할 테이블의 일부 컬럼을 가져오고 싶을 때 ON절을 사용한다.

그러나 Inner join을 사용하는 경우엔 조건의 위치와 테이블의 순서에 무관하게 사용할 수 있다. 왜냐하면 조인하는 두 테이블의 위치관계나, 쿼리 순서에 상관없이 결과가 똑같이 교집합으로 나오기 때문이다.

On절은, Outer join을 사용할 떄 의미를 가진다.

두개의 테이블이 있다고 가정해보자.

```
A    B
-    -
1    3
2    4
3    5
4    6
```

아래의 쿼리로 Left Outer Join을 실행했다.

```sql
select *
from a
LEFT OUTER JOIN b;
```

```
a |  b
--+-----
1 | null
2 | null
3 |    3
4 |    4
```

On절이나 Where절이 없기 떄문에 전체가 출력된다. 

여기서 나는 B 테이블의 값이 3인 경우에만 조인하여 값을 나타내고 싶다. 원하는 결과값은 다음과 같다.

```
a |  b
--+-----
1 | null
2 | null
3 |    3
4 | null
```

---

근데 여기서, Where절로 B 테이블의 값이 3인 경우를 출력하도록 하면 어떤 결과값이 나올까?

```sql
SELECT *
FROM a
LEFT OUTER JOIN b
ON a.a = b.b
WHERE b.b = 3;
```

```
a |  b
--+-----
3 |    3
```

이런 결과값이 나왔다. B 테이블의 값이 3인 경우에 조인한 것이 아니라 모두 조인한 후 B 테이블의 값이 3인 컬럼만 출력되었다. 

내가 원하는 결과를 내기 위해선, Join을 실행하기 전에 미리 B 테이블의 컬럼을 필터링 한 후 A 테이블과 출력해야 한다. 

그렇게 하기 위해서 On절에 조건을 추가했다.

```sql
select *
from a
LEFT OUTER JOIN b
on a.a = b.b AND b.b = 3;
```

```
a |  b
--+-----
1 | null
2 | null
3 |    3
4 | null
```

원하는 결과를 출력할 수 있었다.

그리고 사실은 Join 문에 거의 기본적으로 들어있는 `ON a.a = b.b`(pk값)은 키값이 동일한 경우에 조인하겠다는 의미를 가진 것이었던 것 같다. 

Join문에서 ON절은 필수적으로 필요하며, Where과는 다른 명령어라는 것을 알 수 있었다.
