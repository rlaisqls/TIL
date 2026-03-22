Rust에서 `temporary value is freed` 에러는 임시 값이 사용되기 전에 해제될 때 발생한다. 임시 값이 스코프를 벗어나 메모리가 해제되었는데, 해제된 값에 대한 참조가 여전히 남아있으면 이 에러가 발생한다.

이 에러를 방지하려면 값의 라이프타임이 실제 사용 범위와 일치하도록 소유권을 올바르게 관리해야 한다.

## 예시

```rust
let mut did_config =  "{}";
let seed_input = options.value_of("seed").unwrap_or("tbd");
if (seed_input != "tbd") {
    let json_config = json!({
    "seed": seed_input
    });

    did_config = json_config.to_string().as_str();
    println!("did config: {}", did_config);
}
```

위 코드에서는 다음과 같은 에러가 발생한다.

```rust
37 |         let did_config = json_config.to_string().as_str();
|                          ^^^^^^^^^^^^^^^^^^^^^^^         - temporary value is freed at the end of this statement
|                          |
|                          creates a temporary which is freed while still in use
38 |         println!("did config: {}", did_config);
|                                    ---------- borrow later used here
```

문자열 리터럴 `"{}"`는 `&'static str` 타입으로, 프로그램이 실행되는 동안 계속 살아있다. 그런데 `.to_string().as_str()`를 호출하면 먼저 힙에 할당된 `String`이 생성되고, 거기서 `&str` 참조를 얻는다. 이 `&str`은 원본 `String`이 살아있는 동안에만 유효한데, `String`이 해당 구문이 끝나면서 drop되기 때문에 참조가 무효화된다. borrow checker가 잡아내는 것이 바로 이 문제다.

## 해결

가장 간단한 방법은 `did_config`의 타입을 `&str` 대신 `String`으로 바꾸는 것이다. `to_string()` 결과를 별도 변수에 저장해서 `&str`과 같은 라이프타임을 갖게 하는 방법도 있지만, 그냥 `String`을 쓰는 편이 더 깔끔하다.

---
참고

- <https://www.reddit.com/r/rust/comments/kd7s60/i_dont_understand_this_temporary_value_is_freed/>
- <https://stackoverflow.com/questions/54056268/temporary-value-is-freed-at-the-end-of-this-statement>
