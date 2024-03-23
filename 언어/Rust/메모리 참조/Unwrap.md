unwrap을 호출한 객체는 기본적으로 복사를 수행한다. 복사와 소유권 이동 둘다 가능한 시점에서 복사가 발생한다.

```rust
fn main() {
    let s = Some(12);
    
    let a = s.unwrap();
    println!("{}", a);

    let b = s.unwrap();
    println!("{}", b);    
}
```

복사를 수행하기 위해서는 해당 타입이 Copy 트레잇을 구현해야 한다. 복사가 안된다면 메모리 소유권 이동이 발생한다.

```rust
struct MyStruct{
    x:i32,
    y:i32,
}

fn main() {
    let s = Some(MyStruct {
        x: 123,
        y: 1,
    });

    let a = s.unwrap();//소유권 이동 발생, s에는 메모리 소유권 없음
    println!("{}", a.x);
    
    let b = s.unwrap();//error
    println!("{}", b.x);
}


13  |     let s = Some(MyStruct {
    |         - move occurs because `s` has type `Option<MyStruct>`, which does not implement the `Copy` trait
...
18  |     let a = s.unwrap();
    |             - -------- `s` moved due to this method call
    |             |
    |             help: consider calling `.as_ref()` or `.as_mut()` to borrow the type's contents
...
21  |     let b = s.unwrap();
    |             ^ value used here after move
```

Copy 트레잇을 구현 해주면 복사가 발생하기에 소유권 에러는 발생하지 않는다.

```rust
#[derive(Copy, Clone)]
struct MyStruct{
    x:i32,
    y:i32,
}

fn main() {
    let s = Some(MyStruct {
        x: 123,
        y: 1,
    });

    let a = s.unwrap();
    println!("{}", a.x);//123
    
    let mut b = s.unwrap();
    b.x = 321;
    println!("{}", a.x);//123
    println!("{}", b.x);//321
}
```

힙 메모리를 담는 타입들은 Copy는 구현되어 있지 않지만 소유권 이동은 가능하다.

```rust
fn main() {
    let s = Some(Box::new(1));

    let a = s.unwrap();// 소유권 이동 발생, s의 메모리 소유권은 사라짐
    println!("{}", *a);
    
    let b = s.unwrap();// error, s는 유효한 메모리를 가지고 있지 않다.
    println!("{}", *b);
}
```

복사가 가능한 타입이라면 unwrap 호출시 복사가 발생한다.

```rust
fn main() {
    let s = Some(1);

    let a = s.unwrap();//메모리 복사
    println!("{}", a);
    
    let b = s.unwrap();//Ok
    println!("{}", b);
}
```

만약 참조로 인자를 받았다면 unwrap으로 인해 소유권이 없어지는 코드가 작성 되는지 주의해야한다.

```rust
fn Func(a: Option<Box<i32>>) {
    let c = a.unwrap();//소유권 이동, a는 더이상 메모리 소유권 없음
    println!("{}", c);
    // let d = a.unwrap();
    // println!("{}", d);
}

fn main() {
    let a = Some(Box::new(123));
    Func(a);
    // println!("{}", a.unwrap());//소유권 이동, a는 더이상 메모리 소유권 없음
}
```

참조로 전달하면 소유권 이동을 막을 수 있지만 unwrap 호출시 as_ref를 이용하여 참조로서 가져오도록 해야한다.

```rust
fn Func(a: &Option<Box<i32>>) {
    let c = a.as_ref().unwrap();
    // let c = a.unwrap();//error, 참조이기에 소유권 이동 안됨
    println!("{}", c);
    let d = a.as_ref().unwrap();
    println!("{}", d);    
}

fn main() {
    let a = Some(Box::new(123));
    Func(&a);
    println!("{}", a.unwrap());
}
```

---
참고
- https://doc.rust-lang.org/rust-by-example/error/option_unwrap.html