# Trait

- 여러 타입(type)의 공통된 행위/특성을 표시한 것을 Trait이라고 한다. Rust에서의 Trait는 (약간의 차이는 있지만) 다른 프로그래밍 언어에서의 인터페이스(interface)와 비슷한 개념이다.
- Trait는 trait 라는 키워드를 사용하여 선언하며, trait 블럭 안에 공통 메서드의 원형(method signature)을 갖는다

    ```rust
    trait Draw {
        fn draw(&self, x: i32, y: i32);
    }
    ```

- `Rectangle` 이라는 구조체에 `Draw` 라는 trait를 구현하기 위해서는 `impl 트레이트명 for 타입명`과 같이 정의하고 trait 안의 메서드들을 구현하면 된다. 

    ```rust
    struct Rectangle {
        width: i32,
        height: i32
    }
    
    impl Draw for Rectangle {
        fn draw(&self, x: i32, y: i32) { 
            let x2 = x + self.width;
            let y2 = y + self.height;
            println!("Rect({},{}~{},{})", x, y, x2, y2);
        }
    }
    
    struct Circle {
        radius: i32
    }
    
    impl Draw for Circle {
        fn draw(&self, x: i32, y: i32) { 
            println!("Circle({},{},{})", x, y, self.radius);
        }
    }
    ```

- `Draw`의 구현체는 `impl Draw`와 같이 함수의 인자 혹은 반환 타입으로 명시하여 사용할 수 있다.

    ```rust
    fn draw_it(item: impl Draw, x: i32, y: i32) {
        item.draw(x, y);
    }
    
    fn main() {
        let rect = Rectangle { width: 20, height: 20 };
        let circle = Circle { radius: 5 };
    
        draw_it(rect, 1, 1);
        draw_it(circle, 2, 2);
    }
    ```

## Trait Bound

- 제네릭에 **Trait Bound**를 추가해서 사용할 수도 있다.
  - 복수 개의 Trait을 갖는다면 `+`를 사용하여 여러 Trait을 지정할 수 있다.

```rust
fn draw_it(item: impl Draw, x: i32, y: i32) {
    item.draw(x, y);
}
 
fn draw_it<T: Draw>(item: T, x: i32, y: i32) {
    item.draw(x, y);
}

trait Print {}
 
fn draw_it(item: (impl Draw + Print), x: i32, y: i32) {
    item.draw(x, y);
}
 
fn draw_it<T: Draw + Print>(item: T, x: i32, y: i32) {
    item.draw(x, y);
}

// 이렇게 쓰는 것도 가능
fn draw_it<T>(item: T, x: i32, y: i32) 
   where T: Draw + Print 
{
    item.draw(x, y);
}
```

## dyn

- Trait Bound, impl Trait을 사용하는 것은 결과적으로 정적 디스패치를 구현하는 것이다. 즉, 컴파일러가 컴파일 타임에 타입들을 검사하고 내부적으로 명시된 타입들에 대한 코드를 구현하는 것이다.
- Rust에서 **동적 디스패치**를 구현하기 위해서는 `dyn` 키워드를 사용해야한다.
- 이는 컴파일 비용을 줄이는 대신 런타임 비용을 증가시킨다.
- `dyn Trait`의 참조자는 인스턴스 객체를 위한 포인터와 `vtable`을 가리키는 포인터 총 두 개의 포인터를 갖는다. 그리고 런타임에 이 함수가 필요해지면 `vtable`을 참조해 포인터를 얻게 된다.

```rust
fn get_car(is_sedan: bool) -> Box<dyn Car>{
    if is_sedan {
        Box::new(Sedan)
    } else {
        Box::new(Suv)
    }
}
```

## 디폴트 구현

- Trait은 일반적으로 공통 행위(메서드)에 대해 어떠한 구현도 하지 않는다. 
- 하지만, 필요한 경우 Trait의 메서드에 디폴트로 실행되는 구현을 추가할 수 있다.

## 뉴타입 패턴 (newtype pattern)

- 튜플 구조체 내에 새로운 타입을 만드는 **뉴타입 패턴**을 사용하면 외부 타입에 대해 외부 트레잇을 구현할 수 있다.

- `Vec`에 대하여 `Display`을 구현하고 싶다고 가정해보자.
  - `Display` 트레잇과 `Vec` 타입은 라이브러리에 정의되어 있기 때문에 바로 구현하는 것은 불가능하다.
  - 이때 뉴타입 패턴을 적용하여 `Vec`의 인스턴스를 가지고 있는 `Wrapper` 구조체를 만들 수 있다. 그리고 `Wrapper` 상에 `Display`를 구현하고 `Vec` 값을 이용할 수 있여 구현할 수 있다.

```rust
use std::fmt;

struct Wrapper(Vec<String>);

impl fmt::Display for Wrapper {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "[{}]", self.0.join(", "))
    }
}

fn main() {
    let w = Wrapper(vec![String::from("hello"), String::from("world")]);
    println!("w = {}", w);
}
```


## Derive

- Rust는 derive 키워드를 사용해서 구조체가 특정 기본 trait 구현 기능을 사용하도록 할 것인지를 정의할 수 있도록 한다.
- 구조체 위에 `#[derive()]`와 같이 적고, 괄호 안에 구현할 항목을 `,`로 구분하여 적으면 된다.
  - 가능한 항목은 아래와 같은 것들이 있다.
    - `Eq`, `PartialEq`, `Ord`, `PartialOrd`: 동등, 순서 비교
    - `Clone`: `&T`로부터 `T`를 복사하는 메서드를 사용하는지 여부
    - `Copy`: 소유권 이전(move) 대신 copy가 동작하도록 할 것인지 여부
    - `Hash`: `&T`로부터 hash를 계산할 것인지 여부
    - `Default`: data type 대신 빈 instance를 사용할 수 있게 할 것인지 여부
    - `Debug`: `{:?}` 포매터에 대한 출력을 사용하는지 여부

    ```rust
    // `Centimeters`, a tuple struct that can be compared
    #[derive(PartialEq, PartialOrd)]
    struct Centimeters(f64);

    // `Inches`, a tuple struct that can be printed
    #[derive(Debug)]
    struct Inches(i32);

    impl Inches {
        fn to_centimeters(&self) -> Centimeters {
            let &Inches(inches) = self;
            Centimeters(inches as f64 * 2.54)
        }
    }

    // `Seconds`, a tuple struct with no additional attributes
    struct Seconds(i32);

    fn main() {
        let _one_second = Seconds(1);

        // Error: `Seconds` can't be printed; it doesn't implement the `Debug` trait
        //println!("One second looks like: {:?}", _one_second);
        // TODO ^ Try uncommenting this line

        // Error: `Seconds` can't be compared; it doesn't implement the `PartialEq` trait
        //let _this_is_true = (_one_second == _one_second);
        // TODO ^ Try uncommenting this line

        let foot = Inches(12);

        println!("One foot equals {:?}", foot);

        let meter = Centimeters(100.0);

        let cmp =
            if foot.to_centimeters() < meter {
                "smaller"
            } else {
                "bigger"
            };

        println!("One foot is {} than one meter.", cmp);
    }
    ```

## 연산자 오버로딩

- Rust는 Trait으로 연산자 오버로딩을 지원한다.

```rust
use std::ops;

struct Foo;
struct Bar;

#[derive(Debug)]
struct FooBar;

#[derive(Debug)]
struct BarFoo;

// The `std::ops::Add` trait is used to specify the functionality of `+`.
// Here, we make `Add<Bar>` - the trait for addition with a RHS of type `Bar`.
// The following block implements the operation: Foo + Bar = FooBar
impl ops::Add<Bar> for Foo {
    type Output = FooBar;

    fn add(self, _rhs: Bar) -> FooBar {
        println!("> Foo.add(Bar) was called");

        FooBar
    }
}

// By reversing the types, we end up implementing non-commutative addition.
// Here, we make `Add<Foo>` - the trait for addition with a RHS of type `Foo`.
// This block implements the operation: Bar + Foo = BarFoo
impl ops::Add<Foo> for Bar {
    type Output = BarFoo;

    fn add(self, _rhs: Foo) -> BarFoo {
        println!("> Bar.add(Foo) was called");

        BarFoo
    }
}

fn main() {
    println!("Foo + Bar = {:?}", Foo + Bar);
    println!("Bar + Foo = {:?}", Bar + Foo);
}
```

---
참고
- http://rust-lang.xyz/rust/article/22-Trait
- https://doc.rust-lang.org/rust-by-example/trait.html