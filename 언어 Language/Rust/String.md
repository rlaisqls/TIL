# String

### String과 str

```rust
fn main() {
    let s1: &str = "World";
    println!("s1: {s1}");

    let mut s2: String = String::from("Hello ");
    println!("s2: {s2}");
    s2.push_str(s1);
    println!("s2: {s2}");
    
    let s3: &str = &s2[6..];
    println!("s3: {s3}");
}
```

- Rust에서 `&str`은 문자열 슬라이스에 대한 (불변) 참조이다. (C++의 `const char*`와 유사하지만 항상 유효한 문자열을 가리킨다)
- `String`은 문자열을 담을 수 있는 버퍼이다. (문자열을 이루는 바이트에 대한 백터(Vec<u8>)이며, 가리키고 있는 문자열은 String의 소유이다.)

### String 생성

- new 함수를 이용하여 스트링을 생성할 수 있다.

```rust
let mut s = String::new();
```

- `to_string` 메소드 또는 `String::from()`을 사용하여 스트링 리터럴로부터 String을 생성할 수 있다.

```rust
let data = "initial contents";
let s = data.to_string();
let s = "initial contents".to_string();

let s = String::from("initial contents");
```

- `+` 연산자나 `format!` 매크로를 사용하여 편리하게 String 값들을 서로 접합(concatenation)할 수 있다.

### 포맷팅

- 아래와 같이 변수를 포맷팅하여 출력하는 여러가지 방법이 있다.
- `format()` 매크로를 사용하여 포맷팅 결과를 String으로 반환받을 수 도 있다.

```rust
fn main() {
    let mut a: [i8; 10] = [42; 10];
    a[5] = 0;
    // a라는 배열을 출력하는 여러가지 방법

    println!("a: {a}"); // 일반 출력
    // println!("a: {}", a);과 동일
    /*
    배열은 일반 출력이 불가능하다.
    `[i8; 10]` cannot be formatted with the default formatter
    */

    println!("a: {a:?}"); // 디버깅 출력
    // println!("a: {:?}", a);과 동일
    /*
    a: [42, 42, 42, 42, 42, 0, 42, 42, 42, 42]
    */

    println!("a: {a:#?}"); // 예쁜 디버깅 출력
    // println!("a: {:#?}", a);과 동일
    /*
    a: [
        42,
        42,
        42,
        42,
        42,
        0,
        42,
        42,
        42,
        42,
    ]
    */
}
```

### escape

- `r`을 붙이면 특수문자를 escape하기 위한 백슬래시(`\`)를 적지 않아도 된다. (`r"\n" == "\\n"`)
- string 양쪽에 `#`를 붙이면 붙인 갯수만큼 쌍따옴표를 문자열에 포함할 수 있다.
  
### String 내부 인덱싱

- Rust String은 인덱싱을 지원하지 않는다. (`[0]`과 같이 참조할 수 없다.)
- String은 `Vec<u8>`을 감싼 것인데, 유니코드 스칼라 값이 저장소의 2바이트를 차지하거나 유효하지 않은 문자가 껴있는 경우에 대한 처리가 힘들기 때문에 단순 인덱싱을 불가능하게 만들었다.
- 원한다면 슬라이스를 사용하거나, `.chars()` 혹은 `.bytes()`로 interate 할 수 있다.

---
참고
- https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/std/index.html
- https://rinthel.github.io/rust-lang-book-ko/ch08-02-strings.html