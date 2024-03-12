
[DependencyHandler](https://docs.gradle.org/current/javadoc/org/gradle/api/artifacts/dsl/DependencyHandler.html)는 Gradle의 종속성(Dependencies)을 생성해주는 인터페이스이다.

```kotlin
public interface DependencyHandler extends ExtensionAware {

    @Nullable
    Dependency add(String configurationName, Object dependencyNotation);

    Dependency add(String configurationName, Object dependencyNotation, Closure configureClosure);

    <T, U extends ExternalModuleDependency> void addProvider(String configurationName, Provider<T> dependencyNotation, Action<? super U> configuration);

    <T> void addProvider(String configurationName, Provider<T> dependencyNotation);

    <T, U extends ExternalModuleDependency> void addProviderConvertible(String configurationName, ProviderConvertible<T> dependencyNotation, Action<? super U> configuration);
    ...
}
```

그중 Dependencies를 생성할때 일반적으로 쓰이는 것은 맨 위에 있는 `add` 메서드이다. dependencies 부분에 implement를 추가하면 저 메서드로 자동으로 연결되어서 실행된다.

(kotlinDSL을 사용하면 아래와 같은 코드로 명시적으로 이어주는 것 같다.)

```kotlin
fun DependencyHandler.`implementation`(dependencyNotation: Any): Dependency? =
    add("implementation", dependencyNotation)
```

dependencies에서 그냥 add 메서드를 바로 실행해줘도 종속성이 정상적으로 등록된다.

```kotlin
dependencies {
    add("implementation", "org.jetbrains.kotlin:kotlin-reflect")
}
```

---

그리고 신기하게도

```kotlin
fun DependencyHandler.implementationDependencies(libraries: List<Pair<String, ImplementationType>>) {
    libraries.forEach { (dependency, type) ->
        add(type.originalName, dependency)
    }
}
```

이렇게 코드를 작성하면

```kotlin
dependencies {
    implementationDependencies(
        listOf(
            "org.jetbrains.kotlin:kotlin-reflect" to IMPLEMENTATION,
            "org.jetbrains.kotlin:kotlin-stdlib-jdk8" to IMPLEMENTATION
        )
    )
}
```

이런식으로 호출할 수가 있는데, 이를 이용하여 아래 링크의 코드와 같이 buildSrc를 정의할 수도 있다.

https://github.com/rlaisqls/HelloWorld/tree/master/buildSrc