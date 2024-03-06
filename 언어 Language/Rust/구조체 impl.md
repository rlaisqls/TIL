Rust에서 데이타를 표현하는 구조체(혹은 enum, trait 객체)의 맥락에서 그 구조체와 연관된 함수들을 정의할 수 있는데, 이렇게 연관되어진 함수들을 메서드라 한다. 메서드는 맥락이 되는 구조체 인스턴스로부터 호출되어 사용된다. Rust에서 구조체(struct)에 메서드들을 구현하는 구현 블럭(implementation block)은 "impl" 키워드를 사용하여 정의된다.

### impl 구현블럭

impl 키워드는 구현 블럭(implementation block)을 정의할 때 사용하는데, impl 뒤에 타입명을 적고 impl 블럭 안에 메서드(method) 혹은 연관 함수(associated function)를 넣게 된다. impl 안에 정의된 함수는 그 타입과 연관된 함수라는 의미에서 Associated Function 이라고 불리운다.

메서드는 항상 첫번째 파라미터로 `self` 를 갖지만, Associated Function은 `self`를 갖지 않는다. 이는 다시 말하면, 메서드는 항상 타입 인스턴스를 갖지만, Associated Function는 이 인스턴스를 갖지 않는다는 것을 의미한다. 또한, 연관함수는 `타입명::함수명()`과 같이 사용하지만, 메서드는 `타입명.함수명()`과 같이 `.` 을 사용하여 호출한다.

아래 예제는 Person 이라는 구조체를 정의하고, 이 구조체와 연관되어 사용되는 함수(new 함수)를 impl 블럭에서 정의한 예이다. impl 키위드 뒤에는 구조체 Person과 동일한 이름을 적고, impl 블럭 안에 메서드 혹은 함수를 정의한다. 여기서 new() 연관 함수는 Person 구조체의 인스턴스를 생성하여 리턴하는 일을 한다.

```rust
struct Person {
    id: i32,
    name: String,
    active: bool
}
 
impl Person {
    // 연관함수
    fn new(id: i32, name: String) -> Person {
        Person{ id: id, name: name, active: true }
    }
 
    // 메서드 ...
}
 
fn main() {
    // 연관함수 호출 Person::new()
    let p = Person::new(101, String::from("Tom"));
 
    println!("{}: {}", p.id, p.name);
}
```

연관함수는 `타입명::함수명()`과 같이 `::` 을 사용하는데, 위의 예에서는 `Person::new()` 와 같이 `::` 앞에 Person 구조체명을 붙여 이 타입과 연관된 `new()` 함수라는 것을 표시한다.

impl 블럭은 하나이상 정의할 수 있는데, 일반적으로 여러 개의 impl 블럭을 정의하기 보다는 하나의 impl 블럭을 정의하여 사용한다.

### 메서드 구현

메서드(method)는 impl 블럭 안에 정의된다. 메서드(method)는 함수(function)와 마찬가지로 fn 키워드를 사용하여 정의하며 파라미터와 리턴값을 갖는다. 메서드는 함수와 달리, 구조체와 연관지어 사용되고, 첫번째 파라미터로 항상 "self"를 갖는다. 이때의 self는 해당 메서드와 연관되어 있는 구조체의 인스턴스를 가리킨다.

아래 예제에서 `display()` 메서드는 첫번째 파라미터로 "self"를 가지며, self 인스턴스로부터 (self.active와 같이) 구조체의 필드들을 엑세스하게 된다. 구조체와 연관된 impl 블럭 안에 필요한 메서드들을 체계적으로 정의해 두면 중복된 코드나 에러를 줄일 수 있다. 위에서 언급하였듯이, 연관함수는 `타입명::함수명()`과 같이 사용하지만, 메서드는 `타입명.함수명()`과 같이 `.` 을 사용하여 호출한다. 예를 들어, 아래 예제에서 `p.display()`와 같이 `display()` 메서드를 호출하는 것을 볼 수 있다.

```rust
struct Person {
    id: i32,
    name: String,
    active: bool
}
 
impl Person {
    fn new(id: i32, name: String) -> Person {
        Person{ id: id, name: name, active: true }
    }
 
    // 메서드
    fn display(&self) {
        if self.active {
            println!("{}: {}", self.id, self.name);
        }
        else {
            println!("{}: inactive", self.id);
        }
    }
}
 
fn main() {
    let p = Person::new(101, String::from("Tom"));
    p.display();
}
```

메서드 `fn display(&self)` 에서 `&self` 파라미터는 실제로 `self: &Self` 의 축약형이다. `Self`는 impl 이 정의하는 구조체 즉 위의 경우에는 Person을 가리킨다. 따라서, `&Self`는` &Person` 레퍼런스를 가리키며, Person 인스턴스를 borrow 하여 메서드 내에서 사용하는 것이 된다. 

`&self` 는 구조체 인스턴스를 변경하지 않는 읽기 전용에서 사용되는데, 만약 구조체 인스턴스로부터 필드값을 변경하려면 아래 예제와 같이 `&mut self` 를 사용한다.

```rust
impl Person {
    // &mut self 
    fn set_active(&mut self, is_active: bool) {
        self.active = is_active;
    }
}
 
fn main() {
    let mut p = Person::new(101, String::from("Tom"));
    p.set_active(false);
    p.display();
}
```

---
참고
- http://rust-lang.xyz/rust/article/14-%EA%B5%AC%EC%A1%B0%EC%B2%B4-impl-%EB%B8%94%EB%9F%AD
- https://doc.rust-lang.org/std/keyword.impl.html
- https://stackoverflow.com/questions/65977255/what-does-impl-for-mean