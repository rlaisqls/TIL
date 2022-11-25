# ☕ Inner static class

클래스를 사용하면서 외부 인스턴스에 대한 참조가 필요없는 클래스를 선언 시 `Inner class may be static`이라는 경고가 뜬다. Inner class가 static으로 정의되어야 한다는 뜻인데, 그래야하는 이유가 무엇일까?

'static'키워드가 붙은 내부 클래스는 메모리에 하나만 올라가는 인스턴스가 아니다.

```java
MyClass.InnerClass mic1 = new MyClass().new InnerClass();
MyClass.InnerClass mic2 = new MyClass().new InnerClass();

if (mic1 == mic2) {
    System.out.println("내부 클래스는 새로만들어도 같은 참조지");
} else {
    System.out.println("내부 클래스도 클래스니까 다른 참조지");
}
```

InnerClass의 새로운 인스턴스를 만들게 될 때는 위와 같이 new 연산자를 두번 사용해야한다. 외부 클래스에 대한 인스턴스를 이용해서 내부 클래스의 인스턴스를 생성한다. static 키워드를 붙이지 않았을 때는 그냥 일반 클래스와 비슷하게 취급되기 떄문에 내부 클래스로 셍성한 두개의 객체는 서로 다른 인스턴스이다.
