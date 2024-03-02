
ApplicationEventPublisher는 Spring의 ApplicationContext가 상속하는 인터페이스 중 하나이다.

옵저버 패턴의 구현체로 이벤트 프로그래밍에 필요한 기능을 제공해준다. 이벤트 기반의 방법을 사용하면, 서비스간 강결합 문제를 해결힐 수 있다.

## 1. ApplicationEvent를 상속하는 이벤트 클래스 만들기

```java
import org.springframework.context.ApplicationEvent;
 
public class MyEvent extends ApplicationEvent {
 
    private int data;
 
    public MyEvent(Object source) {
        super(source);
    }
 
    public MyEvent(Object source, int data) {
        super(source);
        this.data = data;
    }
 
    public int getData() {
        return data;
    }
}
```

## 2. ApplicationConext로 이벤트 발생시키기

```java
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;
 
@Component
public class AppRunner implements ApplicationRunner {
 
    @Autowired
    ApplicationEventPublisher eventPublisher;
 
    @Override
    public void run(ApplicationArguments args) throws Exception {
        eventPublisher.publishEvent(new MyEvent(this, 100));    // 이벤트 발생시키기
    }
}
```

ApplicationContext(ApplicationEventPublisher)의 publishEvent() 메소드를 호출해서 이벤트를 발생시킬 수 있다.

ApplicationContext 타입으로 주입받아도 되지만 이벤트 발생 기능을 사용할 것이므로 ApplicationEventPublisher 타입으로 선언하였다.

## 3. 이벤트 핸들링(처리) 하기

```java
import org.springframework.context.ApplicationListener;
import org.springframework.stereotype.Component;
 
@Component
public class MyEventHandler implements ApplicationListener<MyEvent> {
    
    @Override
    public void onApplicationEvent(MyEvent event) {
        System.out.println("First event handling, data: " + event.getData());
    }
}
```

ApplicationEventPublisher가 발생시킨 이벤트를 처리할 핸들러 MyEventHandler 클래스를 생성하고 위와 같이 작성한다.

이벤트 핸들러는 spring이 발생한 이벤트를 누구에게 전달해야하는지 알아야 하기 때문에 빈으로 등록해야 한다.

onApplicationEvent() 안에 이벤트에 대해 필요한 작업을 처리하는 코드를 작성하면 된다.