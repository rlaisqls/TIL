- `extern` 키워드를 사용하면 외부 코드를 링크하거나 import할 수 있다.

- `extern` 키워드는 Rust에서 두 가지 용도로 사용된다. 하나는 `crate` 키워드와 함께 사용하여 프로젝트 내의 다른 Rust crate를 인식시키는 것이다 (예: `extern crate lazy_static;`). 다른 하나는 외부 함수 인터페이스(FFI, Foreign Function Interface)에서 사용하는 것이다.

- FFI에서 `extern`은 두 가지 맥락에서 사용된다. 첫 번째는 외부 블록(external block) 형태로, Rust 코드가 외부 코드를 호출할 수 있도록 함수 인터페이스를 선언하는 것이다.

    ```rust
    #[link(name = "my_c_library")]
    extern "C" {
        fn my_c_function(x: i32) -> bool;
    }
    ```

- 이 코드는 런타임에 Unix 계열 시스템에서는 `libmy_c_library.so`를, Windows에서는 `my_c_library.dll`을 링크하려고 시도하며, 링크할 대상을 찾지 못하면 패닉이 발생한다.

- 이후 Rust 코드는 `my_c_function`을 다른 unsafe Rust 함수처럼 사용할 수 있다. Rust가 아닌 다른 언어와 FFI로 작업하는 것은 본질적으로 안전하지 않기 때문에, 보통 C API를 감싸는 래퍼를 만들어 사용한다.

- FFI의 반대 방향 사용도 `extern` 키워드로 구현할 수 있다:

    ```rust
    #[no_mangle]
    pub extern "C" fn callable_from_c(x: i32) -> bool {
        x % 3 == 0
    }
    ```

- 이 코드를 dylib로 컴파일하면 생성된 `.so` 파일을 C 라이브러리에서 링크할 수 있고, 해당 함수를 다른 라이브러리의 함수처럼 사용할 수 있다.

---
참고

- <https://doc.rust-lang.org/std/keyword.extern.html>
- <https://www.reddit.com/r/rust/comments/17f78mb/what_is_extern_system/>

