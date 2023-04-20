# field 상속

JAVA에는 field 상속이라는 개념이 없다. 하지만 kotlin에서는 `override val`과 같이 쓰면 필드를 상속받은 것 처럼 사용할 수 있다.

```kotlin
data class Teacher(
    val id: UUID = UUID.randomUUID(),
    val accountId: String,
    val password: String
) : Domain
```

이렇게 `Teacher`라는 클래스를 만들고, 그걸 상속받은 `TeacherEntity`라는 클래스를 만들면, `TeacherEntity` 안에 private 필드가 따로 만들어지는 것을 볼 수 있다.

<img width="932" alt="image" src="https://user-images.githubusercontent.com/81006587/232469145-10c155cb-cb5c-49b9-9fd3-2181f75a737f.png">

private이기 때문에 외부에선 함부로 참조할 수 없고, 마치 그냥 `override` 받은 것 같이 편하게 사용할 수 있다.

그래서 이 특성을 사용해서 POJO인 `Domain class`를 `Entity class`가 상속 받게 구현하고, 라이브러리 의존성을 분리하는 Hexagonal Architecture를 구현하려고 했다.

하지만 여기서 문제가 생겼다...

## Reflection

Spring framework data에서는 class 정보를 가져와서 private인지 여부에 상관 없이 필드를 가져오는데, 경우에 따라 필드 이름이 중복이라서 등록이 안되는 경우가 있었다.

여기서 등록이 되는지 안되는지 여부는 DB 구현에 따라 조금 다른 것 같다.
- mongo data에서는 등록 자체가 불가능했고
- R2DBC에서는 필드를 override로 정의하는 것 까진 가능했지만, data class거나 필드가 전부 var이어야 했다. (data class는 상속받을 수 없기 때문에, 선택지가 하나라고 봐도 무방하다.)

코틀린 상으로는 `override`라고 쓰긴 했지만 내부적으로는 private 필드를 각각 가지고 있는 것이기 때문에 스캔 방식에 따라 등록되는 조건이 조금씩 다른 것 같다. 


---

참고

- https://stackoverflow.com/questions/47757454/kotlin-override-abstract-val-behavior-object-vs-class