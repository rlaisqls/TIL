MongoDB의 Aggregation은 각 스테이지가 순차적으로 처리되며, 그 결과를 다음 스테이지로 전달하면서 사용자의 요청을 처리한다.

그래서 각 스테이지들의 배열 순서는 처리 성능에 많은 영향을 미친다. 예를 들어, 필요한 도큐먼트만 필터링 하는 스테이지는 데이터를 그룹핑하는 스테이지보다 앞쪽에 위치해야 그룹핑해야 할 도큐먼트의 건수를 줄일 수 있고, Aggregation의 성능을 높일 수 있다.

aggregation 파이프라인의 각 단계에서는 다음과 같은 연산자들을 제공한다.

- `$project`: 출력 도큐먼트상에 배치할 필드를 지정한다.
- `$match`: 처리될 도큐먼트를 선택하는 것. find()와 비슷한 역할을 수행한다.
- `$limit`: 다음 단계에 전달될 도큐먼트의 수를 제한한다.
- `$skip`: 지정된 수의 도큐먼트를 건너뛴다.
- `$unwind`: 배열을 확장하여 각 배열 항목에 대해 하나의 출력 도큐먼트를 생성한다.
- `$group`: 지정된 키로 도큐먼트를 그룹화한다.
- `$sort`: 도큐먼트를 정렬한다.
- `$geoNear`: 지리 공간위치 근처의 도큐먼트를 선택한다.
- `$out`: 파이프라인의 결과(출력)를 컬렉션에 쓴다.
- `$redact`: 특정 데이터에 대한 접근을 제어한다.

## 예시

```bash
mongo> db.users.aggregate(
  [
    { $match : { type : "idle" } },
    { $sort : { last_login_dt : 1 } },
    { $project : { last_login_dt : 1, seconds : 1, _id : 0 } },
    { $group : { _id : "$last_login_dt", avgUsingTime : { $avg : "seconds" } } }
  ]
);
```

### `$elemMatch`

```bash
> db.inventory.aggregate( [ { 
    field: { "$elemMatch" : {field: value} }
} ]
```

첫 번째 인자에서 쓰일 경우, 배열 필드의 서브 Document 필드가 쿼리와 일치하는 문서를 찾는다. 

두 번째 인자에서 쓰일 경우, 지정된 기준과 일치하는 요소가 하나 이상있는 배열 요소만 프로젝션 한다.

### `$unwind`

```bash
{ "_id" : 1, "item" : "ABC1", sizes: [ "S", "M", "L"] }

> db.inventory.aggregate( [ { $unwind : "$sizes" } ] )
{ "_id" : 1, "item" : "ABC1", "sizes" : "S" }
{ "_id" : 1, "item" : "ABC1", "sizes" : "M" }
{ "_id" : 1, "item" : "ABC1", "sizes" : "L" }
```

id가 1인 도큐먼트가 하나 있을 때 위처럼 unwind 쿼리를 사용하면, sizes 배열의 요소 갯수만큼 document로 분리하여 출력해준다.

## 팁

- 조회시 collation numericOrdering 옵션을 사용하면 String을 int처럼 정렬할 수 있다.
- 쿼리에서 메모리를 너무 많이 사용하여 리드 리밋이 자주 넘는다면, allow disk use 옵션을 킬 수 있다. 하지만 이 옵션을 키면 속도가 느려지므로 프로젝션을 통한 최적화를 먼저 시도해보자.

---
참고
- https://docs.mongodb.com/manual/core/aggregation-pipeline/
- https://docs.mongodb.com/manual/reference/operator/aggregation-pipeline
- https://www.inflearn.com/course/%EC%8B%A4%EB%AC%B4%EC%9E%90%EB%8F%84-%EB%AA%A8%EB%A5%B4%EB%8A%94-mongo-%ED%99%9C%EC%9A%A9%EB%B2%95