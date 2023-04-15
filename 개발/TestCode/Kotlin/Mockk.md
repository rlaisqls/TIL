# 🍬 Mockk

![image](https://user-images.githubusercontent.com/81006587/210192366-7c1a653d-9af0-4e7d-aab1-7b54b58be4cd.png)

Mockk는 코틀린 스타일의 Mock 프레임워크이다.

Mockito를 사용하는 경우 코틀린 DSL 스타일을 활용할 수 없지만, Mockk를 사용하면 아래와 같이 코틀린 DSL 스타일로 Mock 테스트를 작성할 수 있다.

```kotlin
//Mockito
given(userRepository.findById(1L).willReturn(expectedUser)

//Mockk
every { userRepository.findById(1L) } answers { expectedUser }
```

Mockk의 사용을 위해서는 아래와 같은 의존성을 추가해줘야 한다.

```kotlin
dependencies {
    testImplementation("io.mockk:mockk:1.12.0")
}
```

### 예시

**Mocking**

```kotlin
val permissionRepository = mockk<PermissionRepository>()
```

**SpyK**

```kotlin
val car = spyk(Car()) // or spyk<Car>() to call default constructor
```

**Relaxed mock**

```kotlin
val car = mockk<PermissionRepository>(relaxed = true)

// relaxed를 설정하는 경우 permissionRepository.delete에 대해 Mocking을 하지 않은 상태에서 delete 메소드가 호출되더라도 예외가 발생하지 않습니다.
// every { permissionRepository.delete(id) } just Runs
```

**Answers**

```kotlin
// answers
every { permissionRepository.save(permission) } answers { permission }

// throws
every { permissionRepository.findByIdOrNull(id) } throws EntityNotFoundException()

// just Runs
every { permissionRepository.delete(id) } just Runs

// returnsMany
every { permissionRepository.save(permission) } returnsMany listOf(firstPermission, secondPermission)

// returns
every { permissionRepository.save(permission) } returns permission
every { permissionRepository.save(permission) } returns firstPermission andThen secondPermission
```

**Argument matching**

- any

```kotlin
every { permissionRepository.save(any()) } retunrs permission
```

- varargs

```kotlin
every { obj.manyMany(5, 6, *varargAll { it == 7 }) } returns 3

println(obj.manyMany(5, 6, 7)) // 3
println(obj.manyMany(5, 6, 7, 7)) // 3
println(obj.manyMany(5, 6, 7, 7, 7)) // 3

every { obj.manyMany(5, 6, *varargAny { nArgs > 5 }, 7) } returns 5

println(obj.manyMany(5, 6, 4, 5, 6, 7)) // 5
println(obj.manyMany(5, 6, 4, 5, 6, 7, 7)) // 5
```

**Verification**

- verify
  
```kotlin
verify(atLeast = 3) { car.accelerate(allAny()) }
verify(atMost  = 2) { car.accelerate(fromSpeed = 10, toSpeed = or(20, 30)) }
verify(exactly = 1) { car.accelerate(fromSpeed = 10, toSpeed = 20) }
verify(exactly = 0) { car.accelerate(fromSpeed = 30, toSpeed = 10) } // means no calls were performed
```

- verifyAll

```kotlin
verifyAll {
    obj.sum(1, 3)
    obj.sum(1, 2)
    obj.sum(2, 2)
}
```

- verifySequnece

```kotlin
verifySequence {
    obj.sum(1, 2)
    obj.sum(1, 3)
    obj.sum(2, 2)
}
```

## SpringMockk

Mockk에서는 `@MockBean`이나 `@SpyBean`의 기능을 직접 제공하지 않는다.

`@MockBean`이나 `@SpyBean`의 기능을 코틀린 DSL을 활용해 사용하고 싶다면 `Ninja-Squad/springmockk` 의존성을 추가해야 합니다.

```kotlin
testImplementation("com.ninja-squad:springmockk:3.0.1")
```

SpringMockk에서는 `@MockkBean`, `@SpykBean`이라는 어노테이션 및 기능을 제공한다.

```kotlin
    @MockkBean // @MockBean 대신 @MockkBean 사용 가능
    private lateinit var userRepository: UserRepository
```

더 많은 예시는 공식 링크에서 볼 수 있다.

https://mockk.io/#dsl-examples
