## 계정 관리
사용자 계정은 MongoDB 내부에 생성 된 Database마다 별도로 관리된다.
Database의 계정 정보는 db.system.users 컬렉션에 저장된다.
 
계정의 전체 목록을 확인하고 싶다면 mongosh 명령어를 사용하거나 getUsers 메소드를 사용할 수 있다.

```bash
# mongosh 명령어
> show users

# MongoDB 메소드
> db.getUsers()
```

getUsers 메소드는 db.system.users 컬렉션을 쿼리해서 반환한다.
show users 명령어는 getUsers가 반환한 결과를 가공하여 출력한다.
하단에 ok: 1의 유무로 구분할 수 있다.

![image](https://user-images.githubusercontent.com/81006587/226539680-c71e2ab0-c26c-4bc9-b50d-5151ccb91bdb.png)

따라서 계정 정보를 관리하기 위해서는 사용할 Database로 전환해야 한다.
Database를 전환하는 방법은 다음과 같다.

```bash
# Database 전환
> use Database이름

# 유저를 볼 수 있는 database
> use admin

```

관리자 계정을 생성해보자.

```
db.createUser( {
    user: "",
    pwd: passwordPrompt(), // 원하는 텍스트를 입력해도 된다.
    roles: [
        { role: "userAdminAnyDatabase", db: "admin" },
        { role: "readWriteAnyDatabase", db: "admin" }
    ]
} )
```

관리자가 아닌 일반 계정을 생성해보자.

```
db.createUser( {
    user: "",
    pwd: "",
    roles: [{ role:"readWrite", db: "DB명"}]
} )
```

이렇게 로그인 했을때 OK가 뜨면 성공이다.
````js
db.auth('계정명','패스워드')
```

### 계정 정보 수정

계정의 정보가 변경 된 경우 수정해야 한다. 계정 자체의 권한이나 정보, 비밀번호 등을 수정할 수 있다.

```json
db.updateUser("수정할계정", update: { 수정할정보 } )
```

### 계정 삭제

특정 데이터베이스에서 지정한 계정을 삭제한다.

삭제 명령을 실행하면 경고나 확인 메시지 없이 삭제하기 때문에 주의해야 한다.
 
```json
> db.dropUser("삭제할계정")
{ ok: 1 }
```
