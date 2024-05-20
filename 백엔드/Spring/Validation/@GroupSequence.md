
보통 WebRequest를 받을때, null이거나 비어있는 등의 유효하지 않은 값을 미리 걸러내기 위해 Sprign validation을 사용한다. 설정해둔 `@NotNull`, `@Size`, `@Pattern` 등 조건에 부합하지 못하면 MethodArgumentNotValidException이 발생하고, 이 에러를 적절히 처리하여 반환하는 방식이 많이 사용된다.

하지만 한 필드에 여러 검증을 넣게 되면, 그 검증에 순서가 부여되지 않아 무작위로 먼저 걸리는 조건의 에러가 반환된다. 그렇다면 이 에러 처리의 순서를 정해줘야 한다면 어떻게 해야할까? 즉, Null 체크를 먼저하고, 그다음 Size를 체크하고, 그다음 Pattern을 체크하는 방식으로 흐름을 지정하려면 어떻게 해야할까?

그런 경우 `@GroupSequence`를 사용해주면 된다. `@GroupSequence`는 검증 어노테이션을 그룹으로 묶어서 각 그룹의 순서를 지정해줄 수 있도록 한다.

사용을 위해선 우선 그룹을 지정해야한다.

```java
public class ValidationGroups {
    interface NotBlankGroup {};
    interface NotEmptyGroup {};
    interface NotNullGroup {};
    interface SizeCheckGroup {};
    interface PatternCheckGroup {};
}
```

검증 종류로만 그룹을 나누고 싶다면 이런식으로 그룹을 나눌 수 있다. 다른 방식으로 그룹을 묶어주고 싶다면 코드를 바꾸면 된다.

그리고 `@GroupSequence`를 사용하여 원하는 순서대로 정리해준다.

`@GroupSequence`를 사용하여 원하는 순서대로 정리해준다.
왼쪽(위쪽)부터 유효성 검사를 체크해서 없으면 다음 유효성 검사를 실시하게 된다.

```java
@GroupSequence(
    Default.class,
    ValidationGroups.NotBlankGroup.class,
    ValidationGroups.NotEmptyGroup.class,
    ValidationGroups.NotNullGroup.class,
    ValidationGroups.SizeCheckGroup.class,
    ValidationGroups.PatternCheckGroup.class
)
public interface ValidationSequence {
}
```

dto에 선언되어있는 어노테이션에서 각각 groups = "인터페이스명"을 추가한다.

```java
@Size(min = 4, max = 30, message = "아이디는 4글자에서 30글자 사이로 입력해주세요.", groups = ValidationGroups.SizeCheckGroup.class)
@NotBlank(message = "아이디를 입력해주세요.", groups = ValidationGroups.NotNullGroup.class)
@Pattern(regexp = "^([a-z가-힣0-9]){4,30}$", message = "대문자, 특수문자는 입력할 수 없다.", groups = ValidationGroups.PatternCheckGroup.class)
    private String userId;
```

Controller에서 `@Valid`가 있었던 부분을 `@Validated`로 바꾸어준다.

`@Validated`는 `@Valid`의 동작을 대체하면서, 순서 정의 기능을 추가해주기 때문에 `@Valid`를 완전히 지워줘도 괜찮다.

```java
    @PostMapping
    public ResponseEntity createUser(@Validated(ValidationSequence.class) @RequestBody User signUpInfo) {
        accountManager.createUser(signUpInfo);
        return new ResponseEntity<>(HttpStatus.OK);
    }
```
