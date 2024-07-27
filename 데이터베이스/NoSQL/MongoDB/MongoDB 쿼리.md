- insert와 upsert
  - insert: 무조건 insert
  - upsert: 있으면 update 없으면 insert

- 아틀라스에서 예전 데이터를 S3로 옮겨주는 기능을 지원함.
    - 데이터가 S3에 있어도 조인등 쿼리가 문제없이 됨. 실무에선 이력 데이터를 남겨야 하는 경우가 많아서 유용하게 사용

- mongoDB에선 mutex를 지원하지 않기 때문에 writeConflict 예외처리(재시도 로직)이 필요함

- projection

    ```bash
    # db.<콜렉션 이름>.find({},{"<표시할 field>":1, "<표시하지 않을 field>":0})
    # {}는 첫번째 인자인 검색 쿼리
    # "_id"는 입력하지 않을 경우, default로 나옴.
    # 나머지는 입력하지 않을 경우, default로 나오지 않음.

    > db.test.find({},{_id:0,name:1})
    { "name" : "abc" }
    { "name" : "def" }
    ```

---
참고
- https://www.inflearn.com/course/%EC%8B%A4%EB%AC%B4%EC%9E%90%EB%8F%84-%EB%AA%A8%EB%A5%B4%EB%8A%94-mongo-%ED%99%9C%EC%9A%A9%EB%B2%95