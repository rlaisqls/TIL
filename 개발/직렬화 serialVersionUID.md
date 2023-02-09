# 직렬화 serialVersionUID

가끔 자바코드에서 이런 코드를 발견할 때가 있다.

```java
    private static final long serialVersionUID = 3487495895819393L;
```

이 `serialVersionUID`라는 long 타입의 상수는 직렬화할 객체의 버전이 바뀌었는지 식별하기 위한 클래스의 고유 식별자이다.

직렬화와 역직렬화 할때 이 값이 동일하면 동일한 클래스의 데이터라는 것을 확인할 수 있고, 그렇지 않은 경우에는 다르거나 바뀐 클래스라고 생각하여 오류를 throw할 수 있다.

자바 스펙에 따르면, serialVersion을 명시적으로 선언해놓지 않았을 땐 직렬화 런타임이 기본 serialVersion을 클래스의 기본 해쉬값을 가지고 자동으로 계산해준다고 한다.

> 하지만 JVM에 의한 default serialVersionUID 계산은 클래스의 세부 사항을 매우 민감하게 반영하기 때문에 약간의 변경사항만 있어도 deserialization 과정에서 InvalidClassException이 생길 수 있다. 그렇기 때문에 클래스 호환 문제를 어느정도 직접 관리할 수 있다면 이 값을 고정된 값으로 정의해주는게 좋다.


java의 ObjectStreamClass에 가보면 이런 식으로 데이터를 저장하는 변수가 정의되어있는 것을 볼 수 있다.

```java
    private volatile Long suid;
```

```java
    private static Long getDeclaredSUID(Class<?> cl) {
        try {
            Field f = cl.getDeclaredField("serialVersionUID");
            int mask = Modifier.STATIC | Modifier.FINAL;
            if ((f.getModifiers() & mask) == mask) {
                f.setAccessible(true);
                return f.getLong(null);
            }
        } catch (Exception ex) {
        }
        return null;
    }
```

스프링 Web을 쓸때도 똑같이 역직렬화/직렬화 과정을 거치긴 하지만 웹 통신을 할때는 byte를 주거나 받기만 하고, 본인이 직렬화한 데이터를 다시 역직렬화할 일은 없기 때문에 serialVersionUID에 대한 걱정은 하지 않아도 된다.

하지만 데이터를 Kafka에 직렬화 해서 넣어놓고 받는 로직을 쓴다거나 하면 클래스 변경에 유의하거나 uid 값을 정의하는것을 고려해보는 것이 좋을 것 같다.