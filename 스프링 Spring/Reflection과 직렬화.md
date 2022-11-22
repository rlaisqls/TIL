# 🍃 Reflection

`Reflection`은 런타임에 동적으로 클래스들의 정보를 알아내고, 실행할 수 있는 것을 말한다.

`Reflection`은 프로그래머가 데이터를 보여주고, 다른 포맷의 데이터를 처리하고, 통신을 위해 serialization(직렬화)을 수행하고, bundling을 하기 위해 일반 소프트웨어 라이브러리를 만들도록 도와준다.

java와 같은 객체지향 프로그래밍언어에서 Reflection을 사용하면 컴파일 타임에 인터페이스, 필드, 메소드의 이름을 알지 못해도 실행중에 접글할 수 있다. 또, 멤버 접근 가능성 규칙을 무시하여 private 필드의 값을 변경할 수 있다.

## 직렬화

jackson은 java.lang reflection 라이브러리를 사용한다.

기본생성자가 있는 경우에는 _constructor.newInstance()를 사용하여, 객체를 생성한다.

```java
@Override
public final Object call() throws Exception {
    return _constructor.newInstance();
}
```

기본 생성자가 없는 경우에는 _constructor.newInstance(Object[] args) 또는 _constructor.newInstance(Object arg) 등을 사용하여 생성한다.

```java
@Override
public final Object call(Object[] args) throws Exception {
    return _constructor.newInstance(args);
}

@Override
public final Object call1(Object arg) throws Exception {
    return _constructor.newInstance(arg);
}
```
