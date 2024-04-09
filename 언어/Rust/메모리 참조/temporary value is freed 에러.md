- In Rust, the error `temporary value is freed` occurs when a temporary value is deallocated before it is expected to be used. 
- This typically happens when the temporary value goes out of scope and its memory is deallocated. If there are still references to this value after deallocation, it leads to a runtime error.

- To avoid this error, it's crucial to ensure that the lifetimes of values match their usage and that ownership is managed correctly. This involves properly understanding Rust's ownership system and lifetime annotations to ensure that references remain valid for as long as they are needed.

- Let's see below example

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

- In the given code, the error occurs as follows:
    ```rust
    37 |         let did_config = json_config.to_string().as_str();
    |                          ^^^^^^^^^^^^^^^^^^^^^^^         - temporary value is freed at the end of this statement
    |                          |
    |                          creates a temporary which is freed while still in use
    38 |         println!("did config: {}", did_config);
    |                                    ---------- borrow later used here
    ```

- The thing is that the string literal is of type `&'static str`, which means it is a `&str` that will live for the entire duration of the program.

- Then you're doing `.to_string().as_str()`,
  - which first creates a heap allocated string (String),
  - and then gets a reference of type `&str` (`as_str`).
  - The problem is that this `&str` will only live as long as the String, so if that value is dropped (freed),
  - the reference will be invalid, and that's what the borrow checker is complaining about.

- What I would do is give the variable `did_config` the type String, instead of `&str`.

- Another way of fixing it is to store the result of the `to_string` in another variable that lives as long as the `&str` lives, but it seems a bit more complex than just storing the heap allocated string (String)

---
reference
- https://www.reddit.com/r/rust/comments/kd7s60/i_dont_understand_this_temporary_value_is_freed/
- https://stackoverflow.com/questions/54056268/temporary-value-is-freed-at-the-end-of-this-statement