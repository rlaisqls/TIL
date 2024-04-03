- FFI(Foreign Function Interface)는 한 프로그래밍 언어에서 다른 프로그래밍 언어의 코드를 호출하기 위한 인터페이스를 말한다. Rust에서는 toml에 lib 형태로 저장한 crate방식으로 사용할 수 있다.

## Rust에서 C 코드 호출하기

- [snappy](https://github.com/google/snappy/blob/main/snappy-c.h)라는 C 라이브러리를 참조하는 코드 예시를 살펴보자.
    ```rust
    use libc::size_t;

    #[link(name = "snappy")]
    extern {
        fn snappy_max_compressed_length(source_length: size_t) -> size_t;
        fn snappy_compress(input: *const u8,
                        input_length: size_t,
                        compressed: *mut u8,
                        compressed_length: *mut size_t) -> c_int;
        fn snappy_uncompress(compressed: *const u8,
                            compressed_length: size_t,
                            uncompressed: *mut u8,
                            uncompressed_length: *mut size_t) -> c_int;
        fn snappy_max_compressed_length(source_length: size_t) -> size_t;
        fn snappy_uncompressed_length(compressed: *const u8,
                                    compressed_length: size_t,
                                    result: *mut size_t) -> c_int;
        fn snappy_validate_compressed_buffer(compressed: *const u8,
                                            compressed_length: size_t) -> c_int;
    }

    fn main() {
        let x = unsafe { snappy_max_compressed_length(100) };
        println!("max compressed length of a 100 byte buffer: {}", x);
    }
    ```

- extern 블록 내부에 있는 함수는 외부 라이브러리의 함수 시그니처를 명시한 것이다. `#[link(...)]` 속성은 링커에게 snappy라는 이름의 C 라이브러리를 링크하도록 지시하여 해당 기호들이 해결되도록 한다.

- 외부 함수는 안전하지 않다고 가정되므로 해당 함수를 호출할 때 안전하지 않음을 나타내는 `unsafe {}`로 감싸주어야 한다. 

- 외부 함수에 인수 유형을 선언할 때 Rust 컴파일러는 선언이 올바른지 확인할 수 없으므로 정확하게 확인해줘야 한다.

### 안전한 인터페이스

- 메모리에 안전한 방식으로 벡터와 같은 고수준 개념을 사용하려면 raw C API를 래핑해야 한다. 안전한 상위 수준 인터페이스만 노출하고 안전하지 않은 세부 정보는 숨기는 방식으로 코드를 작성할 수 있다.

- 버퍼를 기대하는 함수를 래핑하는 것은 `slice::raw` 모듈을 사용하여 Rust 벡터를 메모리에 대한 포인터로 조작하는 것을 포함한다. Rust의 벡터는 연속적인 메모리 블록이 보장된다. 길이는 현재 포함된 요소의 수이고, 용량은 할당된 메모리 요소의 전체 크기이다.

    ```rust
    pub fn validate_compressed_buffer(src: &[u8]) -> bool {
        unsafe {
            snappy_validate_compressed_buffer(src.as_ptr(), src.len() as size_t) == 0
        }
    }
    ```

- 위의 `validate_compressed_buffer` 래퍼는 함수 시그니처에서 `unsafe`를 생략하고 `unsafe` 블록을 사용함으로써 호출이 모든 입력에 대해 안전하다는 것을 보장한다.

- `snappy_compress` 및 `snappy_uncompress` 함수는 출력을 보유하기 위해 버퍼를 할당해야 하므로 더 복잡하다.

- `snappy_max_compressed_length` 함수를 사용하여 값을 저장하기 위한 최대 용량을 갖는 벡터를 할당하고, `snappy_compress` 함수에 출력 매개변수로 전달하는 코드이다.

    ```rust
    pub fn compress(src: &[u8]) -> Vec<u8> {
        unsafe {
            let srclen = src.len() as size_t;
            let psrc = src.as_ptr();

            let mut dstlen = snappy_max_compressed_length(srclen);
            let mut dst = Vec::with_capacity(dstlen as usize);
            let pdst = dst.as_mut_ptr();

            snappy_compress(psrc, srclen, pdst, &mut dstlen);
            dst.set_len(dstlen as usize);
            dst
        }
    }
    ```

## C에서 Rust 코드 호출하기

- C에서 호출할 수 있는 방식으로 Rust 코드를 컴파일하고 싶은 경우 아래와 같이 할 수 있다.

- `rust_from_c`라는 이름의 crate가 있다고 가정하고, `lib.rs` 코드를 아래처럼 작성한다.

    ```rust
    #[no_mangle]
    pub extern "C" fn hello_from_rust() {
        println!("Hello from Rust!");
    }
    ```
- `extern "C"`는 이 함수가 C 호출 규칙을 따르도록 한다. `no_mangle` 옵션으로 Rust의 mangle이 작동하지 않도록 하여 C와의 컴파일 호환을 맞춘다.

- 이후 Rust 코드를 C에서 호출할 수 있는 공유 라이브러리로 컴파일하려면 `Cargo.toml`에 아래와 같은 부분을 추가해야한다.

    ```rust
    [lib]
    crate-type = ["cdylib"]
    ```

- 이렇게 설정하면 C에서는 아래처럼 호출할 수 있다.

    ```c
    extern void hello_from_rust();

    int main(void) {
        hello_from_rust();
        return 0;
    }
    ```

- 파일 이름을 `call_rust.c`로 지정하고 crate root로 옮기고, 아래 명령어로 컴파일을 수행한다. Rust 라이브러리를 찾기 위해 `-l`과 `-L` 옵션을 지정해주어야 한다.

    ```bash
    $ gcc call_rust.c -o call_rust -lrust_from_c -L./target/debug
    $ LD_LIBRARY_PATH=./target/debug ./call_rust
    Hello from Rust!
    ```
- [cbindgen](https://github.com/mozilla/cbindgen)에서 다른 예제를 확인할 수 있다.

## Callback

- 일부 라이브러리에서는 현재 상태 또는 중간 데이터를 호출자에게 다시 보고하기 위해 콜백을 사용해야 한다. 이 경우 Rust에 정의된 함수를 외부 라이브러리에 전달하는 것도 가능하다.

- 콜백 함수를 Rust에서 C 라이브러리로 전달하여 사용할 수 있다. 콜백 예제를 살펴보자.

    ```rust
    extern fn callback(a: i32) {
        println!("I'm called from C with value {0}", a);
    }

    #[link(name = "extlib")]
    extern {
    fn register_callback(cb: extern fn(i32)) -> i32;
    fn trigger_callback();
    }

    fn main() {
        unsafe {
            register_callback(callback);
            trigger_callback(); // Triggers the callback.
        }
    }
    ```

- C 코드는 아래처럼 작성한다.

    ```rust
    typedef void (*rust_callback)(int32_t);
    rust_callback cb;

    int32_t register_callback(rust_callback callback) {
        cb = callback;
        return 1;
    }

    void trigger_callback() {
        cb(7); // Will call callback(7) in Rust.
    }
    ```

- 이 예에서 Rust의 `main`은 `trigger_callback()`를 호출하고, C는 다시 `callback()`을 호출한다.

### Rust 객체에 대한 콜백 타겟팅

- 콜백이 특정 Rust 객체를 대상으로 하도록 할 수도 있다. 객체에 대한 원시 포인터를 C 라이브러리로 전달함으로써 이를 구현할 수 있다. 그러면 C 라이브러리는 알림에 Rust 객체에 대한 포인터를 포함할 수 있다. 
- 이 방식에서 콜백이 참조된 Rust 객체에 대해 액세스하는 것은 안전하지 않을 수 있다.

- 러스트 코드:

    ```rust
    struct RustObject {
        a: i32,
        // Other members...
    }

    extern "C" fn callback(target: *mut RustObject, a: i32) {
        println!("I'm called from C with value {0}", a);
        unsafe {
            // Update the value in RustObject with the value received from the callback:
            (*target).a = a;
        }
    }

    #[link(name = "extlib")]
    extern {
    fn register_callback(target: *mut RustObject,
                            cb: extern fn(*mut RustObject, i32)) -> i32;
    fn trigger_callback();
    }

    fn main() {
        // Create the object that will be referenced in the callback:
        let mut rust_object = Box::new(RustObject { a: 5 });

        unsafe {
            register_callback(&mut *rust_object, callback);
            trigger_callback();
        }
    }
    ```

- C 코드:

    ```c
    typedef void (*rust_callback)(void*, int32_t);
    void* cb_target;
    rust_callback cb;

    int32_t register_callback(void* callback_target, rust_callback callback) {
        cb_target = callback_target;
        cb = callback;
        return 1;
    }

    void trigger_callback() {
    cb(cb_target, 7); // Will call callback(&rustObject, 7) in Rust.
    }
    ```

### 비동기 콜백

- 이전 예제의 콜백들은 외부 C 라이브러리에 대한 함수 호출에 대한 직접적인 반응으로 호출됩니다. 현재 스레드에 대한 제어는 콜백 실행을 위해 Rust에서 C, Rust로 전환되지만, 결국 콜백은 콜백을 트리거한 함수를 호출한 동일한 스레드에서 실행된다.

- 외부 라이브러리가 자체 스레드를 생성하고 거기에서 콜백을 호출하면 상황이 더 복잡해진다. 이러한 경우 콜백 내부의 Rust 데이터 구조에 대한 액세스는 특히 안전하지 않기 때문에 뮤텍스 등의 적절한 동기화 메커니즘을 사용해야 한다. 또는 Rust의 채널(`std::sync::mpsc`)을 사용하여 콜백을 호출한 C 스레드의 데이터를 Rust 스레드로 전달하는 방식을 사용할 수 있다.

- 비동기 콜백이 Rust 주소 공간의 특수 개체를 대상으로 하는 경우 해당 Rust 개체가 삭제된 후 C 라이브러리에서 더 이상 콜백을 수행하도록 막는 로직 또한 필요하다. 이는 객체의 소멸자에서 콜백을 등록 취소하고 취소 후 콜백이 수행되지 않도록 보장하는 방식으로 라이브러리를 설계함으로써 달성할 수 있다.

## Linking

- `link` 블록의 속성은 Rustc extern에게 네이티브 라이브러리에 연결하는 방법을 지시하기 위한 기본 빌딩 블록을 제공한다. 링크 속성에는 두 가지 형식이 허용된다.

- foo는 연결할 네이티브 라이브러리의 이름이고, bar는 컴파일러가 연결하는 네이티브 라이브러리의 유형이다. 
    ```rust
    #[link(name = "foo")]
    #[link(name = "foo", kind = "bar")]
    ```

- 네이티브 라이브러리에는 세 가지 유형이 있다.

  - 동적: `#[link(name = "readline")]`
  - 정적: `#[link(name = "my_build_dependency", kind = "static")]`

- kind 값은 네이티브 라이브러리가 연결에 참여하는 방식을 다르게 하기 위한 것이다.
  
  - **static 유형을 사용하는 경우**
    - Rust 코드를 작성할 때 C/C++로 작성된 코드가 필요하지만 C/C++ 코드를 라이브러리 형식으로 배포하는 것은 부담스러울 수 있다. 이 경우, 코드는 `libfoo.a`로 아카이브되고, Rust crate는 `#[link(name = "foo", kind = "static")]`를 통해 의존성을 선언할 수 있다. 라이브러리가 Rust output에 한께 포함되므로 네이티브 정적 라이브러리를 따로 컴파일할 필요가 없다.

  - **동적 유형을 사용하는 경우**
    - 일반 시스템 라이브러리(예: readline)는 많은 시스템에서 사용할 수 있으며 이러한 라이브러리의 정적 사본은 찾을 수 없는 경우가 많다. 이 의존성이 Rust 크레이트에 포함되면 부분 타겟(예: rlib)은 라이브러리를 링크하지 않지만 rlib이 최종 타겟(예: binary)에 포함될 때 네이티브 라이브러리가 링크된다.

- link 관점에서 Rust 컴파일러는 partial(rlib/staticlib)과 final(dylib/binary)이라는 두 가지 종류의 아티팩트를 생성한다. 동적 라이브러리 및 프레임워크 종속성은 최종 아티팩트 경계로 전파되고, 정적 라이브러리 종속성은 후속 아티팩트에 직접 통합되므로 종속성을 전파하지 않는다.
  
### 안전하지 않은 블록

- 원시 포인터 역참조나 unsafe로 표시된 함수 호출과 같은 일부 작업은 안전하지 않은 블록 내에서만 허용된다. 안전하지 않은 블록은 unsafe한 코드를 격리하며 unsafe한 코드가 블록 외부로 누출되지 않는다는 것을 컴파일러에 약속한다.

- 하지만 unsafe 함수는 해당 함수를 사용하는 코드도 unsafe할 수 있다는 것을 알린다.

    ```rust
    unsafe fn kaboom(ptr: *const i32) -> i32 { *ptr }
    ```

---
참고
- https://doc.rust-lang.org/nomicon/ffi.html
- https://doc.rust-lang.org/std/ffi/index.html
- https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/book/first-edition/ffi.html