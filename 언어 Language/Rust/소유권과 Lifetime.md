# 소유권

- 기본적으로 모든 변수 바인딩은 유효한 “범위(스코프)“를 가지며, 범위 밖에서 변수 사용하면 에러가 발생한다.
- 스코프가 종료되면 변수는 “삭제(drop)“되었다고 하며 그 변수의 데이터는 메모리에서 해제된다.
- Rust에서는 스코프가 종료될 때 다른 리소스를 해제하기 위해 소멸자가 호출되도록 하는 것을 변수가 **값을 소유한다**고 정의한다.
- 러스트의 각각의 값은 해당값의 오너(owner)라고 불리우는 변수를 갖고 있으며 한번에 딱 하나의 오너만 존재할 수 있다.

```rust
fn main() {
    let s1: String = String::from("Rust");
    let s2: String = s1;
}
```

- 위 코드는 `"Rust"`라는 String 값에 대한 소유권을 `s1`에서 `s2`로 이전한다.
- `s2`에 `s1`을 대입하면
  - String 데이터(스택에 있는 포인터, 길이값, 용량값)이 복사된다. 포인터가 가리키고 있는 힙 메모리 상의 데이터는 복사되지 않는다.
  - 그리고 `s1`는 더이상 유효하지 않은 상태가 된다. 두 변수가 같은 메모리를 가리킬 때 생기는 double free를 방지하기 위함이다. 따라서 참조시 에러가 발생한다.

        ```rust
        error[E0382]: use of moved value: `s1`
        --> src/main.rs:4:27
        |
        3 |     let s2 = s1;
        |         -- value moved here
        4 |     println!("{}, world!", s1);
        |                            ^^ value used here after move
        |
        = note: move occurs because `s1` has type `std::string::String`,
        which does not implement the `Copy` trait
        ```

- **이동 전 메모리**

  <img height="179" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/6f528fbe-8d9b-4456-8bdd-309d44c5da64">

- **이동 후 메모리**

  <img height="219" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/f26cdfea-182d-4327-8c1b-9825d30f2530">

- 단, 정수형과 같이 컴파일 타임에 결정되어 있는 크기의 타입은 스택에 모두 저장되기 때문에, 실제 값의 복사본이 빠르게 만들어질 수 있다. 
- 이 경우에는 변수 y가 생성된 후에 x가 더 이상 유효하지 않도록 해야할 이유가 없어서, 아래와 같은 단순 타입은 소유권 이전이 이뤄지지 않고 항상 값이 복사된다.

  - u32와 같은 모든 정수형 타입들
  - true와 false값을 갖는 부울린 타입 bool
  - f64와 같은 모든 부동 소수점 타입들
  - Copy가 가능한 타입만으로 구성된 튜플들

## 함수 호출에서의 이동(Move)

```rust
fn say_hello(name: String) {
    println!("Hello {name}")
}

fn main() {
    let name = String::from("Alice");
    say_hello(name);
    // say_hello(name);
}
```
- 러스트는 함수 호출시 이동을 기본으로 하고, 복제하고 싶은 경우 명시적으로 선언하도록 한다.
- name에 할당되있는 힙 메모리는 `say_hello` 함수의 끝에서 해제된다.
- main 함수에서 name을 참조로 전달하고(&name), `say_hello`에서 매개변수를 참조형으로 수정한다면 main 함수는 name의 소유권을 유지할 수 있다. 
- `say_hello` 함수를 호출할 때 main함수는 자신이 가진 name에 대한 소유권을 포기하므로, 이후 main함수에서는 name을 사용할 수 없다.
- 가변 참조자를 사용하면 참조하는 값에 대한 수정이 가능하다.
  - 그러나, 특정한 스코프 내에 특정한 데이터 조각에 대한 가변 참조자는 딱 하나만 만들 수 있다.
  - 불변 참조자를 가지고 있을 동안에도 역시 가변 참조자를 만들 수 없다.
  - 필요한 경우 새로운 스코프를 정의하는 방법을 사용할 수 있다.
  
- 이러한 제한은 Rust가 컴파일 타임에 아래와 같은 동작으로 데이터 레이스(data race)가 발생하지 않도록 해준다.
  1. 두 개 이상의 포인터가 동시에 같은 데이터에 접근한다.
  2. 그 중 적어도 하나의 포인터가 데이터를 쓴다.
  3. 데이터에 접근하는데 동기화를 하는 어떠한 메커니즘도 없다.

## 댕글링 참조자(Dangling References)

- 댕글링 포인터란 어떤 메모리를 가리키는 포인터를 보존하는 동안, 그 메모리를 해제함으로써 다른 개체에게 사용하도록 줘버렸을 지도 모를 메모리를 참조하고 있는 포인터를 말한다.

- 러스트에서 컴파일러는 모든 참조자들이 댕글링 참조자가 되지 않도록 보장해준다. 만일 우리가 어떤 데이터의 참조자를 만들었다면, 컴파일러는 그 참조자가 스코프 밖으로 벗어나기 전에는 데이터가 스코프 밖으로 벗어나지 않을 것임을 확인해 줄 것이다.

- 댕글링 참조자를 만드는 예시를 보자.
  
```rust
fn main() {
    let reference_to_nothing = dangle();
}

fn dangle() -> &String {
    let s = String::from("hello");

    &s
}
```

- 위 코드의 오류 메세지이다.
  
```rust
error[E0106]: missing lifetime specifier
 --> dangle.rs:5:16
  |
5 | fn dangle() -> &String {
  |                ^^^^^^^
  |
  = help: this function's return type contains a borrowed value, but there is no
    value for it to be borrowed from
  = help: consider giving it a 'static lifetime

error: aborting due to previous error
```

- 빌려온 값이 실제로 존재하지 않는다며 에러가 발생하는 것을 볼 수 있다
- 참조자가 아니라 String 값을 직접 반환하면 문제를 해결할 수 있다.

## Lifetime(수명)

- 러스트에서 모든 참조자는 코드가 유효한 스코프인 라이프타임(lifetime) 을 갖는다.
- 대부분의 경우 라이프타임 또한 암묵적이며, 추론된다.


```rust
#[derive(Debug)]
struct Point(i32, i32);

fn left_most<'a>(p1: &'a Point, p2: &'a Point) -> &'a Point {
    if p1.0 < p2.0 { p1 } else { p2 }
}

fn main() {
    let p1: Point = Point(10, 10);
    let p2: Point = Point(20, 20);
    let p3: &Point = left_most(&p1, &p2);
    println!("left-most point: {:?}", p3);
}
```
- `'a`는 제네릭 매개변수로 컴파일러에 의해 추론된다.
- 수명의 이름은 ` 로 시작하며 보통 `'a`를 많이 사용한다.
- `&'a Point`는 `Point`의 수명이 최소한 `'a`라는 수명보다는 같거나 더 길다는 것을 의미한다.
- 매개변수들이 서로 다른 스코프에 있을 경우 “최소한“이라는 조건이 중요하다.

- 아래 코드에서는 p3의 수명이 p2 보다 길기 때문에 컴파일되지 않는다.

```rust
struct Point(i32, i32);

fn left_most<'a>(p1: &'a Point, p2: &'a Point) -> &'a Point {
    if p1.0 < p2.0 { p1 } else { p2 }
}

fn main() {
    let p1: Point = Point(10, 10);
    let p3: &Point;
    {
        let p2: Point = Point(20, 20);
        p3 = left_most(&p1, &p2);
    }
    println!("left-most point: {:?}", p3);
}
```

### 빌림 검사기(Borrow Checker)

- Borrow Checker 라고 불리는 컴파일러의 컴포넌트가 스코프를 비교하여 모든 빌림이 유효한지를 결정한다.

```rust
{
    let r;         // -------+-- 'a
                   //        |
    {              //        |
        let x = 5; // -+-----+-- 'b
        r = &x;    //  |     |
    }              // -+     |
                   //        |
    println!("r: {}", r); // |
                   //        |
                   // -------+
}
```

- 위 코드는 각 변수의 라이프타임을 명시적으로 주석으로 표현한 것이다.
- `'b` 라이프타임이 `'a` 라이프타임에 비해 작기 때문에 오류가 발생한다.

### 구조체에서의 수명

- 어떤 타입이 빌려온 데이터를 저장하고 있다면, 반드시 수명을 표시해야 한다.

```rust
#[derive(Debug)]
struct Highlight<'doc>(&'doc str);

fn erase(text: String) {
    println!("Bye {text}!");
}

fn main() {
    let text = String::from("The quick brown fox jumps over the lazy dog.");
    let fox = Highlight(&text[4..19]);
    let dog = Highlight(&text[35..43]);
    // erase(text);
    println!("{fox:?}");
    println!("{dog:?}");
}
```
- 위의 예제에서 Highlight의 어노테이션(`<'doc>`)은 적어도 `Highlight` 인스턴스가 살아있는 동안에는 그 내부의 `&str`가 가리키는 데이터 역시 살아있어야 한다는 것을 의미한다.
- 만약 text가 fox (혹은 dog)의 수명이 다하기 전에 `erase` 함수 호출 등으로 사라지게 된다면 빌림 검사기가 에러를 발생한다.

---
참고
- https://doc.rust-lang.org/nomicon/ownership.html
- https://doc.rust-lang.org/nomicon/lifetimes.html
- https://google.github.io/comprehensive-rust/ko/ownership.html
- https://rinthel.github.io/rust-lang-book-ko/ch10-03-lifetime-syntax.html