`macro_rules!`는 Rust의 선언적 매크로(declarative macro)를 정의하는 구문이다. 컴파일 타임에 패턴 매칭으로 코드를 생성한다.

```rust
macro_rules! 매크로이름 {
    (패턴) => { 확장 코드 };
}
```

`(패턴) => { 확장 코드 }` 한 쌍을 arm이라고 한다. `match` 문과 비슷하게, 여러 arm을 정의하면 위에서부터 순서대로 매칭을 시도한다.

```rust
macro_rules! say {
    () => {
        println!("nothing")
    };
    ($x:expr) => {
        println!("{}", $x)
    };
}

say!(); // println!("nothing")
say!("hello"); // println!("{}", "hello")
```

## Fragment Specifier

패턴에서 `$name:specifier` 형태로 캡처 변수를 선언한다. specifier는 캡처할 구문 요소의 종류를 지정한다.

- **`ident`**: 식별자. 변수명, 함수명, 타입명 등. `foo`, `_add`, `MyStruct`
- **`expr`**: 표현식. `1 + 2`, `foo()`, `if x { 1 } else { 2 }`
- **`ty`**: 타입. `i32`, `Vec<String>`, `&str`
- **`pat`**: 패턴. `Some(x)`, `_`, `1..=5`
- **`stmt`**: 문장. `let x = 1`
- **`block`**: 블록. `{ ... }`
- **`item`**: 아이템. `fn`, `struct`, `impl` 등 최상위 정의
- **`literal`**: 리터럴. `42`, `"hello"`, `true`
- **`path`**: 경로. `std::collections::HashMap`
- **`tt`**: token tree. 어떤 토큰이든 매칭. 가장 유연하지만 타입 안전성이 낮다

```rust
macro_rules! make_fn {
    ($name:ident, $body:expr) => {
        fn $name() -> i32 {
            $body
        }
    };
}

make_fn!(answer, 42);
assert_eq!(answer(), 42);
```

`$name:ident`는 식별자를 캡처하고, 확장 코드에서 `$name`으로 참조한다. 위 예시에서 `answer`라는 ident가 캡처되어 함수 이름으로 들어간다.

## 복수 arm 매크로

arm을 여러 개 정의하면 인자 수나 형태에 따라 다른 코드를 생성할 수 있다.

```rust
macro_rules! proxy_slot {
    // arm 1: 인자 1개
    ($slot:ident) => {
        Some(|a, b, vm| {
            let a_ref = unwrap(a);
            let b_ref = unwrap(b);
            if let Some(f) = a_ref.class().slots.$slot.load() {
                f(a_ref, b_ref, vm)
            } else {
                Ok(vm.ctx.not_implemented())
            }
        })
    };
    // arm 2: 인자 2개
    ($slot:ident, $right_slot:ident) => {
        Some(|a, b, vm| {
            let a_ref = unwrap(a);
            let b_ref = unwrap(b);
            if let Some(f) = a_ref.class().slots.$slot.load() {
                f(a_ref, b_ref, vm)
            } else if let Some(f) = b_ref.class().slots.$right_slot.load() {
                f(a_ref, b_ref, vm)
            } else {
                Ok(vm.ctx.not_implemented())
            }
        })
    };
}

// arm 1 매칭
proxy_slot!(add)
// arm 2 매칭
proxy_slot!(add, radd)
```

`proxy_slot!(add)`는 arm 1에 매칭되고, `proxy_slot!(add, radd)`는 arm 2에 매칭된다. 각각 다른 코드로 확장된다.

## 반복

`$(...)*`이나 `$(...)+` 구문으로 반복 패턴을 처리한다.

```rust
macro_rules! vec_of {
    // $( )* : 0번 이상 반복, 구분자는 쉼표
    ($($x:expr),*) => {
        {
            let mut v = Vec::new();
            $( v.push($x); )*
            v
        }
    };
}

let v = vec_of![1, 2, 3];
// 확장 결과:
// {
//     let mut v = Vec::new();
//     v.push(1);
//     v.push(2);
//     v.push(3);
//     v
// }
```

- `$($x:expr),*` — 쉼표로 구분된 expr을 0개 이상 캡처
- `$($x:expr),+` — 1개 이상 캡처 (비어있으면 컴파일 에러)
- `$($x:expr);*` — 세미콜론 구분

반복 캡처된 변수는 확장 코드에서도 `$( ... )*` 안에서 써야 한다.

## 클로저를 인자로 넘기는 패턴

매크로에서 생성한 코드가 [클로저](./클로저.md)를 헬퍼 함수에 넘기는 패턴은 매크로 크기를 줄이는 데 유용하다.

```rust
fn apply_binary(a: i32, b: i32, op: fn(i32, i32) -> i32) -> i32 {
    // 공통 전처리 로직
    let a = a.abs();
    let b = b.abs();
    op(a, b)
}

macro_rules! binary_op {
    ($op:ident) => {
        |a, b| apply_binary(a, b, |a, b| a.$op(b))
    };
}

// 확장 결과:
// |a, b| apply_binary(a, b, |a, b| a.wrapping_add(b))
let add = binary_op!(wrapping_add);
```

매크로는 메서드 이름만 바인딩하고, 공통 로직은 `apply_binary`에 한 번만 존재한다. 매크로가 확장되어도 코드 크기가 작고, 디버깅 시 `apply_binary`라는 함수명이 스택 트레이스에 나타난다.

반면 헬퍼 없이 매크로 안에 로직을 전부 넣으면, 매크로를 N번 호출할 때마다 동일한 코드가 N번 복사된다. 익명 클로저만 생성되므로 스택 트레이스에 `{{closure}}`만 표시되어 어떤 연산에서 에러가 발생했는지 구분하기 어렵다.

## 스코프와 위생성

위생성(hygiene)이란, 매크로가 확장될 때 매크로 내부의 변수명과 호출 지점의 변수명이 서로 오염되지 않도록 컴파일러가 보장하는 성질이다.

C의 `#define`은 단순 텍스트 치환이라 이름이 겹치면 그대로 충돌한다(비위생적, unhygienic).

```c
// C 매크로 — 비위생적
#define DOUBLE(x) ({ int tmp = (x); tmp + tmp; })

int tmp = 5;
int result = DOUBLE(tmp);
// 확장: ({ int tmp = (tmp); tmp + tmp; })
// 매크로 내부의 tmp와 외부의 tmp가 충돌 → 의도치 않은 결과
```

Rust의 `macro_rules!`는 컴파일러가 매크로 내부에서 선언된 식별자에 별도의 구문 컨텍스트(syntax context)를 부여한다. 같은 이름이어도 서로 다른 바인딩으로 취급된다.

```rust
macro_rules! double {
    ($x:expr) => {{
        let tmp = $x; // 매크로 컨텍스트의 tmp
        tmp + tmp
    }};
}

let tmp = 5;
let result = double!(tmp); // 호출자 컨텍스트의 tmp
// 두 tmp는 이름만 같고 별개의 바인딩 → 정상 동작, result = 10
```

"부분적으로" 위생적이라고 하는 이유는, `$name:ident`로 캡처한 식별자는 호출 지점의 컨텍스트를 그대로 가져오기 때문이다. 매크로가 새로 만든 이름은 격리되지만, 호출자가 넘긴 이름은 격리되지 않는다.

```rust
macro_rules! using_x {
    ($e:expr) => {{
        let x = 42; // 매크로 내부의 x
        $e           // 호출자가 넘긴 표현식
    }};
}

let x = 0;
let result = using_x!(x + 1); // 호출자의 x(0)를 사용, result = 1
```

`$e`에 들어온 `x + 1`의 `x`는 호출자의 `x = 0`을 참조한다. 매크로 내부의 `let x = 42`와는 별개의 바인딩이다. 완전한 위생성(full hygiene)을 제공하는 절차적 매크로의 `Span` API와는 이 점에서 차이가 있다.

## `macro_rules!` vs 절차적 매크로

`macro_rules!`는 패턴 매칭 기반이라 단순 코드 생성에 적합하지만, AST를 직접 조작하거나 복잡한 로직이 필요하면 절차적 매크로(procedural macro)를 써야 한다.

- **`macro_rules!`**: 패턴 → 코드 치환. 별도 크레이트 불필요. derive 불가.
- **derive 매크로**: `#[derive(MyTrait)]` 형태. `proc-macro` 크레이트 필요.
- **attribute 매크로**: `#[my_attr]` 형태. 아이템 전체를 변환.
- **function-like 매크로**: `my_macro!(...)` 형태지만 내부에서 `TokenStream`을 직접 조작.

절차적 매크로는 `TokenStream`을 입력으로 받고 `TokenStream`을 반환하는 함수다. `TokenStream`은 Rust 소스 코드를 토큰 단위로 표현한 시퀀스로, 컴파일러가 렉싱 단계에서 생성한다.

개별 토큰은 `TokenTree` enum으로 표현된다.

- **`Ident`**: 식별자. `foo`, `struct`, `i32`
- **`Punct`**: 구두점. `+`, `::`, `#`
- **`Literal`**: 리터럴. `42`, `"hello"`
- **`Group`**: 괄호로 묶인 그룹. `(...)`, `{...}`, `[...]` — 내부에 또 `TokenStream`을 가진다

```rust
use proc_macro::TokenStream;

#[proc_macro_derive(MyTrait)]
pub fn my_trait_derive(input: TokenStream) -> TokenStream {
    // input: #[derive(MyTrait)]가 붙은 struct/enum의 토큰들
    // 예: `struct Foo { x: i32 }` 전체가 TokenStream으로 들어옴

    // 반환: 생성할 코드의 토큰들
    // 예: `impl MyTrait for Foo { ... }`를 TokenStream으로 만들어 반환
}
```

`TokenStream`을 직접 조작하는 건 번거롭기 때문에 실제로는 `syn` 크레이트로 AST로 파싱하고, `quote` 크레이트로 다시 `TokenStream`을 생성하는 게 일반적이다.

```rust
use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, DeriveInput};

#[proc_macro_derive(MyTrait)]
pub fn my_trait_derive(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput); // TokenStream → AST
    let name = &input.ident;

    let expanded = quote! {          // AST → TokenStream
        impl MyTrait for #name {
            fn hello() {
                println!("Hello from {}", stringify!(#name));
            }
        }
    };

    expanded.into()
}
```

대부분의 코드 생성은 `macro_rules!`로 충분하다. AST를 분석하거나 외부 데이터를 읽어야 할 때만 절차적 매크로가 필요하다.

---
참고

- <https://doc.rust-lang.org/reference/macros-by-example.html>
- <https://doc.rust-lang.org/rust-by-example/macros.html>
- <https://veykril.github.io/tlborm/>
- <https://doc.rust-lang.org/reference/procedural-macros.html>
