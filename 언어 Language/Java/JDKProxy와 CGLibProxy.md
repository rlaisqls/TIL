# ☕ JDK Proxy와 CGLib Proxy

Proxy를 구현한 것 중 가장 많이 쓰이는 종류로는 **JDK Proxy와 CGLib Proxy**가 있다.

두 방식의 가장 큰 차이점은 Target의 어떤 부분을 상속 받아서 프록시를 구현하느냐에 있다.

![image](https://user-images.githubusercontent.com/81006587/200806976-6528c443-8c57-4920-85e4-fc2131efcfbe.png)

JDK Proxy는 Target의 상위 인터페이스를 상속 받아 프록시를 만든다. 

따라서 **인터페이스를 구현한 클래스가 아니면 의존할 수 없다**. Target에서 다른 구체 클래스에 의존하고 있다면, JDK 방식에서는 그 클래스(빈)를 찾을 수 없어 런타임 에러가 발생한다.

우리가 의무적으로 서비스 계층에서 인터페이스 -> XXXXImpl 클래스를 작성하던 관례도 다 이러한 JDK Proxy의 특성 때문이기도 하다.

또한 내부적으로 Reflection을 사용해서 추가적인 비용이 발생한다.

```java
public class ExamDynamicHandler implements InvocationHandler {
    private ExamInterface target; // 타깃 객체에 대한 클래스를 직접 참조하는것이 아닌 Interface를 이용

    public ExamDynamicHandler(ExamInterface target) {
        this.target = target;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args)
            throws Throwable {
        // TODO Auto-generated method stub
        // 메소드에 대한 명세, 파라미터등을 가져오는 과정에서 Reflection 사용
        String ret = (String) method.invoke(target, args); //타입 Safe하지 않다는 단점이 있다.
        return ret.toUpperCase(); //메소드 기능에 대한 확장
    }
}
```

CGLib Proxy는 Target 클래스를 상속 받아 프록시를 만든다.

JDK Proxy와는 달리 리플렉션을 사용하지 않고 바이트코드 조작을 통해 프록시 객체 생성을 하고 있다.

게다가 인터페이스를 구현하지않고도 해당 구현체를 상속받는 것으로 문제를 해결하기 때문에 성능상 이점을 가지고, 런타임 에러가 발생할 확률도 상대적으로 적다.

CGLib는 Enhancer라는 클래스를 바탕으로 Proxy를 생성한다.

```java
// 1. Enhancer 객체를 생성
Enhancer enhancer = new Enhancer();

// 2. setSuperclass() 메소드에 프록시할 클래스 지정
enhancer.setSuperclass(BoardServiceImpl.class);
enhancer.setCallback(NoOp.INSTANCE);

// 3. enhancer.create()로 프록시 생성
Object obj = enhancer.create();

// 4. 프록시를 통해서 간접 접근
BoardServiceImpl boardService = (BoardServiceImpl)obj;
boardService.writePost(postDTO);
```

이처럼 상속을 통해 프록시 객체가 생성되는 모습을 볼 수 있다.

BoardServiceProxy.writePost(postDTO) -> BoardServiceImpl.writePost(postDTO)
`enhancer.setCallback(NoOp.INSTANCE);`라는 코드는 `Enhancer` 프록시 객체가 직접 원본 객체에 접근하기 위한 옵션이다.

기본적으로 프록시 객체들은 직접 원본 객체를 호출하기 보다는, 별도의 작업을 수행하는데 CGLib의 경우 Callback을 사용한다.

CGLib에서 가장 많이 사용하는 콜백은 net.sf.cglib.proxy.MethodInterceptor인데, 프록시와 원본 객체 사이에 인터셉터를 두어 메소드 호출을 조작하는 것을 도와줄 수 있게 된다.

```
BoardServiceProxy -> BoardServiceInterceptor -> BoardServiceImpl
```

자바 리플렉션 방식보다 CGLib의 MethodProxy이 더 빠르고 예외를 발생시키지 않는다고 하여 Springboot에서는 CGLib를 기본 프록시 객체 생성 라이브러리로 채택하게 되었다.