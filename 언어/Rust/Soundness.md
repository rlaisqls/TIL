- Rust에서 코드가 sound하다는 것은 safe 코드만으로는 정의되지 않은 동작(UB)을 일으킬 수 없다는 뜻이다.
  - UB의 예: 메모리 범위 밖 접근, dangling 포인터 역참조, 데이터 경쟁, 잘못된 값(예: `bool`에 2)을 만드는 것
  - 이 보장이 깨질 수 있는 코드를 unsound하다고 한다.
- safe 함수는 어떤 인자로 호출되어도 UB를 일으키면 안 된다. 그럴 수 있다면 함수 내부가 `unsafe` 블록으로 감싸져 있어도 그 함수는 unsound하다.
  - 호출자가 지켜야 할 조건이 있으면 함수를 `unsafe fn`으로 표시하고, 그 조건을 `# Safety` 문서에 적는다. 이렇게 하면 조건을 지킬 책임이 호출자에게 넘어간다.
- 공식 용어다. Rustonomicon과 Unsafe Code Guidelines 용어집에서 정의하고, rust-lang/rust 이슈 트래커에서는 `I-unsound` 라벨로 soundness 버그를 분류한다.

### 예시

```rust
// unsound: safe 함수인데 아무 주소나 받아 역참조한다
pub fn read(p: *const u8) -> u8 {
    unsafe { *p }
}

// sound: 호출자가 p의 유효성을 보장해야 한다고 시그니처에 드러난다
/// # Safety
/// `p`는 읽을 수 있는 유효한 `u8`을 가리켜야 한다.
pub unsafe fn read(p: *const u8) -> u8 {
    *p
}

// sound: 참조는 항상 유효하므로 unsafe가 필요 없다
pub fn read(p: &u8) -> u8 {
    *p
}
```

---
참고

- <https://doc.rust-lang.org/nomicon/safe-unsafe-meaning.html>
- <https://rust-lang.github.io/unsafe-code-guidelines/glossary.html#soundness-of-code--of-a-library>
- <https://rust-lang.github.io/rust-clippy/master/index.html#not_unsafe_ptr_arg_deref>
- <https://rust-lang.github.io/rust-clippy/master/index.html#ptr_offset_with_cast>
- <https://github.com/simnalamburt/xz-rs>
