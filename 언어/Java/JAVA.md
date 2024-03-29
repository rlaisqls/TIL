## 객체 지향 프로그래밍(OOP, Object-Oriented Programming)
> #### 모든 데이터를 객체(object)로 취급하여 객체의 상태와 행동을 구체화 하는 형태의 프로그래밍
### 클래스 (class)
#### 객체를 정의하는 틀 또는 설계도
 - 필드 = 클래스에 포함된 변수
 - 메소드 = (class에 종속된) 함수


### static
 - 클래스 변수 혹은 클래스 메소드 앞에 붙는거
 - 인스턴스 변수와 다르게 인스턴스하지 않아도 그냥 사용가능 (클래스가 메모리에 올라갈 때 메소드 영역에 바로 저장 되기 때문)
 - A라는 클래스 안에 num이라는 static 변수가 있으면 그냥 A.num하고 쓰면 됨
 - 함수도 그냥 메소드 이름.하고 파라미터만 넣어서 씀 
 - 반면, 인스턴스 변수는 new 해서 인스턴스로 만든담에 힙 영역에 저장돼야 사용 가능
 - 인스턴스 함수만 이 인스턴스 변수의 내용을 바꿀 수 있음 
 
---
## 자바의 특징

### 상속
 - extend (부모)
 - 클래스는 딱 하나의 클래스만 상속받을 수 있음
 - super
   - this는 내 안에서 나를 부르는거지만, super는 내 안에서 부모를 부르는거임
   - super.변수이름 하면 부모 클래스의 멤버를, super()하면 부모의 생성자를 뜻함.
   - 자식 객체를 생성하면 부모의 기본 생성자가 자동으로 만들어짐

 - method overriding
   - 상속받은 메소드를 자식에서 재정의해서 쓰는거

### 다형성(polymorphism)

 - 다형성은 하나의 객체가 여러 가지 타입을 가질 수 있다는 뜻
 - 그래서 자바에서는 부모 클래스 타입의 참조 변수로 자식 클래스 타입의 인스턴스를 참조할 수 있도록 함
 - 단, 참조 변수가 사용할 수 있는 멤버의 개수가 실제 인스턴스의 멤버 개수보다 같거나 적을때만 됨
 - 부모변수 = 자식변수,  자식변수 = (자식클래스)부모변수

### 추상화 
 - 부모클래스에선 있다고 치고 이름만 만들어놈
 - 그리고 자식에서 쓸때 오버라이딩 해서 알아서 구현해서 씀
 - 이러한 추상 클래스는 객체 지향 프로그래밍에서 중요한 특징인 다형성을 가지는 메소드의 집합을 정의할 수 있게 해줌

### 인터페이스(interface)
 - implements (부모),(부모),(부모)...
 - 오로지 추상 메소드와 상수만을 포함할 수 있지만, 여러 클래스를 상속받을 수 있음
 - 다른 클래스를 작성할 때 기본이 되는 틀을 제공하면서, 다른 클래스 사이의 중간 매개 역할까지 담당하는 일종의 추상 클래스임
 - 모든 필드가 public static final이어야 하며, 모든 메소드는 public abstract이어야 함
