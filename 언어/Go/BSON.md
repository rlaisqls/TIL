
golang에서 JSON 형태를 쓰고 싶을 때는 bson을 사용하면 된다.

- bson.D: 하나의 BSON 도큐먼트. MongoDB command 처럼 순서가 중요한 경우에 사용한다.
- bson.M: 순서가 없는 map 형태. 순서를 유지하지 않는다는 점을 빼면 D와 같다.
- bson.A: 하나의 BSON array 형태.
- bson.E: D 타입 내부에서 사용하는 하나의 엘리먼트.

