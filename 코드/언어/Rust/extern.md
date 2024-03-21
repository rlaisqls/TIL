
- Using extern keyword, you can link to or import external code.

- The extern keyword is used in two places in Rust. One is in conjunction with the crate keyword to make your Rust code aware of other Rust crates in your project, i.e., extern crate lazy_static;. The other use is in foreign function interfaces (FFI).

- `extern` is used in two different contexts within FFI. The first is in the form of external blocks, for declaring function interfaces that Rust code can call foreign code by.

    ```rust
    #[link(name = "my_c_library")]
    extern "C" {
        fn my_c_function(x: i32) -> bool;
    }
    ```

- This code would attempt to link with `libmy_c_library.so` on unix-like systems and my_c_library.dll on Windows at runtime, and panic if it can’t find something to link to.

- Rust code could then use `my_c_function` as if it were any other unsafe Rust function. Working with non-Rust languages and FFI is inherently unsafe, so wrappers are usually built around C APIs.

- The mirror use case of FFI is also done via the extern keyword:

    ```rust
    #[no_mangle]
    pub extern "C" fn callable_from_c(x: i32) -> bool {
        x % 3 == 0
    }
    ```

- If compiled as a dylib, the resulting .so could then be linked to from a C library, and the function could be used as if it was from any other library.

---
reference
- https://doc.rust-lang.org/std/keyword.extern.html
- https://www.reddit.com/r/rust/comments/17f78mb/what_is_extern_system/