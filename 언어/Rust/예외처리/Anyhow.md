
- Anyhow는 일반화된 Error 타입을 이용해 **코드에서 발생하는 에러를 한 가지 타입으로 처리할 수 있게 도와주는 라이브러리**이다.
  
- Rust에서는 엄격하게 타입을 검사하기 때문에, 여러 라이브러리에서 사용하는 서로 다른 에러 타입을 처리하기 위해서는 `map_err`로 에러를 변환해 통일하거나 `Box<dyn std::error::Error>`를 이용해 타입을 일반화하거나 타입의 제약조건을 덜어내는 방법을 사용한다.

- `map_err`을 사용할 때는, 문자열로 에러를 변환하거나 새로운 에러 타입을 만들어 통일한다.
  
    ```rust
    fn stringify(x: u32) -> String { format!("error code: {}", x) }

    let x: Result<u32, u32> = Err(404);
    x.map_err(stringify); // error code: 404
    ```

- `Box<dyn std::error::Error>`는 “`std::error::Error` 트레잇(Trait)을 구현한 타입이면 아무거나 된다”라는 의미이다. 트레잇이기 때문에 dyn 키워드가 붙었고, 에러 타입의 크기를 정확히 모르기 때문에 Box로 감싸준다.

    ```rust
    #[tokio::main]
    async fn main() -> Result<(), Box<dyn std::error::Error>> {
        // ...
    }
    ```

- 마찬가지로, Anyhow도 `Box<dyn std::error::Error>`와 동일하게 사용하면 된다.

    ```rust
    fn get_cluster_info() -> anyhow::Result<ClusterMap> {
        let config = std::fs::read_to_string("cluster.json")?;
        let map: ClusterMap = serde_json::from_str(&config)?;
        Ok(map)
    }
    ```

- `anyhow::Error`는 `Box<dyn std::error::Error>`와 매우 비슷하지만, 몇 가지 차이점이 있다.

   - 가장 큰 차이는 Error가 `Send`, `Sync`, `'static`이어야한다는 것이다. 즉, 스레드간 소유권 이전(Send)과 여러 스레드에서 접근(Sync)이 가능해야한다.
   - 또한, Error가 가지고 있는 참조는 항상 `'static`이어야한다. 이를 통해서 Error의 역추적(Backtrace)이 보장된다.

### 포맷

에러를 출력할 때 사용하는 포맷(Format)도 더 자세한 정보를 제공한다.

- `{:#}`:
  
    ```rust
    Failed to read instrs from ./path/to/instrs.json: No such file or directory (os error 2)
    ```

- `{:?}`:

    ```rust
    Error: Failed to read instrs from ./path/to/instrs.json

    Caused by:
        No such file or directory (os error 2)

    Stack backtrace:
    0: <E as anyhow::context::ext::StdError>::ext_context
                at /git/anyhow/src/backtrace.rs:26
    1: core::result::Result<T,E>::map_err
                at /git/rustc/src/libcore/result.rs:596
    2: anyhow::context::<impl anyhow::Context<T,E> for core::result::Result<T,E>>::with_context
                at /git/anyhow/src/context.rs:58
    3: testing::main
                at src/main.rs:5
    4: std::rt::lang_start
                at /git/rustc/src/libstd/rt.rs:61
    5: main
    6: __libc_start_main
    7: _start
    ```

- `{:#?}`:

    ```rust
    Error {
        context: "Failed to read instrs from ./path/to/instrs.json",
        source: Os {
            code: 2,
            kind: NotFound,
            message: "No such file or directory",
        },
    }
    ````

### 매크로

- `anyhow!` 매크로는 문자열에서 에러를 만들 때 사용한다.

    ```rust
    return Err(anyhow!("Missing attribute: {}", missing)); 
    ```

- `bail!`은 에러를 조기에 반환할 때 사용한다. `return Err(anyhow!("error message"))`와 동일한 동작을 한다.

    ```rust
    if !has_permission(user, resource) {
        bail!("permission denied for accessing {}", resource);
    }
    ```

---
참고
- https://docs.rs/anyhow/latest/anyhow/
- https://antoinerr.github.io/blog-website/2023/01/28/rust-anyhow.html