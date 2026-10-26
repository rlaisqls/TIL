Work log for [RustPython/mpdecimal](https://github.com/RustPython/mpdecimal), a c2rust translation of libmpdec 4.0.1. Each entry records a problem I hit and how I solved it.

Background:

- The goal is to follow [xz-rs](https://github.com/simnalamburt/xz-rs) and split the translation into two crates:
  - `core`, the implementation, which exports no symbols;
  - `sys`, the `#[no_mangle] extern "C"` wrappers matching `mpdecimal.h`, built as a `staticlib`.
- The direction is under discussion in [issue #2](https://github.com/RustPython/mpdecimal/issues/2).

## 2026-10-26: ABI checks and the core/sys split

### ctest does not check signatures

- **Problem:** a wrapper with one wrong argument type still links and only breaks at runtime. I wanted the split to be checked at compile time, but ctest 0.5.1 only checks that a function exists (its address) and does not compare signatures.
- **Solution:** bindgen translates `mpdecimal.h` into Rust declarations, and generated code assigns each item of the crate to its C type. Any mismatch fails `cargo check`.

  ```rust
  const _: unsafe extern "C" fn(*mut mpd_t, *const mpd_t, *const mpd_t, *mut mpd_context_t)
      = mpdecimal_sys::mpd_add;
  const _: *const Option<unsafe extern "C" fn(size_t) -> *mut c_void> = &raw const mpd_mallocfunc;
  const _: fn(&mpd_t) -> &u8 = |s| &s.flags;
  const _: () = {
      assert!(size_of::<rs::mpd_t>() == size_of::<c::mpd_t>());
      assert!(offset_of!(rs::mpd_t, digits) == offset_of!(c::mpd_t, digits));
  };
  ```

- **Verified:** with mutation tests. Each of these mistakes fails to compile:
  - flipping the mut/const of a function pointer;
  - swapping two struct fields;
  - changing a constant's value;
  - changing the signature of a hand-written wrapper.

### `const mpd_add = mpd_add` is a cycle

- **Problem:** a named constant that refers to the item of the same name refers to itself.
- **Solution:** use anonymous `const _` items.

### bindgen infers the wrong types for macro constants

- **Problem:** bindgen emits declarations such as `MPD_UINT_MAX: i32 = -1`, so comparing the values directly fails.
- **Solution:** compare bit patterns at the width of the crate's type (`same_bits(a as u64, b as u64, size_of_val(&a))`).

### Generating i686 bindings on macOS

- **Problem:** CONFIG_32 also has to be checked. The host's libc headers make the bindgen output depend on the host.
- **Solution:** pass `--target=i686-unknown-linux-gnu -I neutral-libc` and use the neutral libc headers of the pipeline. libclang is found with `LIBCLANG_PATH=/Library/Developer/CommandLineTools/usr/lib`.

### c2rust and bindgen rename the field `type` differently

- **Problem:** c2rust renames the C field `type` to `type_0`, while bindgen renames it to `type_`.
- **Solution:** the generator maps a trailing `_` to `_0`.

### Writing 338 wrappers by hand

- **Problem:** the public ABI is 338 functions and 8 globals, so the wrappers are too many to write and maintain by hand.
- **Solution:** generate `sys/src/capi.rs` from the same bindgen output.
  - The 4 functions that only CONFIG_64 declares are under `#[cfg(target_pointer_width = "64")]`.
  - When a core signature diverges later, only that wrapper is written by hand in `sys/src/manual.rs`, and the generator skips every function defined there.
  - If a core signature changes and its wrapper is not updated, the sys build fails at the call inside the wrapper.

### Globals that C writes to cannot be wrapped

- **Problem:** C users assign `mpd_mallocfunc`, `mpd_callocfunc`, `mpd_reallocfunc`, `mpd_free`, `mpd_traphandler` and `MPD_MINALLOC` directly, as in `mpd_mallocfunc = my_malloc;`, and core reads those values. If sys kept its own copies under the same names, the values C wrote would never reach core.
- **Solution:** core exports only the header globals, behind the feature `capi`, and sys enables it.

  ```rust
  #[cfg_attr(feature = "capi", no_mangle)]
  pub static mut mpd_mallocfunc: Option<unsafe extern "C" fn(size_t) -> *mut c_void> = ...;
  ```

  ```toml
  mpdecimal-core = { path = "../core", features = ["capi"] }
  ```

- **Precedent:** `xz-sys` enables the `custom_allocator` feature of `xz-core`. If core later takes the allocator and trap handler as arguments, this exception goes away.

### The long tests link internal symbols

- **Problem:** mpdecimal-testit links internal symbols such as `_mpd_kmul` and `mpd_moduli`.
- **Solution:** `install.py` rewrites `#[no_mangle]` by rule when it installs the translation into `core/`, so rerunning c2rust gives the same result.

  | Item | In core | Exported by |
  |---|---|---|
  | header function | `#[no_mangle]` removed | the wrapper in sys |
  | header global | `#[cfg_attr(feature = "capi", no_mangle)]` | core (sys enables it) |
  | anything else | `#[cfg_attr(feature = "test-hooks", no_mangle)]` | core (enabled by `sys/test-hooks`) |

- **Verified:**
  - Building core alone exports 0 symbols.
  - sys exports 346 symbols, exactly the header's set.
  - sys with test-hooks exports the same set as before the split.
  - The short tests pass 296 of 296, as before the split.

### The per-target crates became workspace members

- **Problem:** the pipeline creates a crate per target in `c2rust/out/<target>/mpdec`. Once the root became a workspace, Cargo picked these up as members.
- **Solution:** `exclude = ["c2rust"]` in the root `Cargo.toml`.

### Glob imports became ambiguous

- **Problem:** the `use ...::*` in the `include!`d generated code and `pub use manual::*` brought in the same names.
- **Solution:** wrap the generated code in a module (`mod capi; pub use capi::*;`).

### `git checkout` reverted core to the untransformed version

- **Problem:** `git checkout -- core/src/crt.rs` restored the index version, which did not have the export transformation yet.
- **Solution:** reapply `exports()`, confirm that `check_root()` passes against `installed.sha256`, and then stage.

### Still open

- The other 8 targets have not been run since the split. So far only macOS aarch64 has been run.
- The long tests:
  - `karatsuba_fnt` and `karatsuba_fnt2` hit the 900 s timeout;
  - `fntcov` exits with 137 both before and after the split, and the cause is unknown.
- `install.py` has not been run through the real pipeline, since c2rust is not installed here.

## 2026-10-26: clippy soundness lints and the first core cleanup

Done on the branch `core-cleanup`, ahead of the answer to issue #2. From here on `core/` is edited by hand, so `install.py` refuses to overwrite it (`installed.sha256`). What soundness means and what the two lints catch: [[Soundness]].

### c2rust translates `p + i` into `offset(i as isize)`

- **Problem:** `ptr_offset_with_cast` reported 289 sites on 64-bit and 304 on 32-bit, because some code exists only for one width. On 32-bit, an index of 2^31 or more becomes a negative offset. That is the same class of bug that xz-rs fixed in 9a7ed11.
- **Solution:** `p.add(i)`, which means the same as C's `p + i`.
  - The fix was applied with `cargo clippy --fix -- -A clippy::all -W clippy::ptr_offset_with_cast` in all four configurations (aarch64 / i686, with and without `test-hooks`).
  - Both lints are denied in `core/src/lib.rs`.
- **Checked before switching to `add`:** an index that is a wrapped negative value would turn `add` into UB.
  - Only the Knuth division in basearith does wrapping arithmetic inside the offset argument (`n-1`, `n-2`), and C guarantees `n > 1` there.
- **Not caught by the lint:** 5 sites index with `q: mpd_uint_t` rather than `usize`. They have the same problem and were fixed by hand with `add(... as usize)`.
  - The `.offset` calls that remain take signed indices (`mpd_ssize_t`, `c_int`), so they are correct.
- **No reproducible bug:** mpdecimal bounds the length of a coefficient, so the current tests do not reach the overflow.
- `not_unsafe_ptr_arg_deref` reported 0 sites, because every public function is an `unsafe fn`.

### clippy's other machine-applicable fixes

- **Problem:** clippy reported about 1,400 warnings.
- **Solution:** `cargo clippy --fix` in the four configurations, repeated until nothing changed.
  - Removed unneeded casts, `return`s and `unsafe` blocks.
  - Rewrote `if let`, `+=`, `ptr::eq` and `ptr::swap`, and added parentheses for precedence.
  - The `unsafe { ... }` around 12 static initializers was removed with a script, using the spans of the `unused_unsafe` warnings.
  - `missing_safety_doc` (392) is allowed, because these are the libmpdec functions documented in its manual.
- **Pitfalls:**
  - `clippy --fix` also applies rustc's fixes, such as renaming unused parameters `_ctx`.
  - In zsh, `$t` does not split into words, so `cargo clippy $t` with `t="--features test-hooks"` fails. Use `${=t}` or an array.
- **Checked:** the 4 precedence warnings were not bugs; c2rust had kept the C semantics.

### Running the Linux targets without Apple `container`

- **Problem:** `c2rust/in-container.sh` uses Apple's `container` CLI, which is not installed here, and building the full image also builds LLVM and c2rust.
- **Solution:** a test-only image for Docker (orbstack): Ubuntu 24.04, the cross gccs, `qemu-user` and rustup 1.99.0 with the targets. The repository is mounted at the same path, and the image runs `c2rust/test-short.sh` with the same environment as `test-all.sh`.

### Verified

- clippy: 0 warnings in all four configurations.
- systest: all four configurations pass.
- Exports: 346 symbols, and 391 with `test-hooks`, the same set as before.
- `systest/gen.py`: produces the same output.
- Short tests, 296 PASS each, with and without `test-hooks`:
  - macOS aarch64;
  - Linux aarch64, i686, s390x and armv7.
- Not run: wasm32, Windows and macOS x86_64.

---
References

- https://github.com/RustPython/mpdecimal/issues/2
- https://github.com/simnalamburt/xz-rs
- https://rust-lang.github.io/rust-bindgen/
- https://github.com/rust-lang/libc/tree/main/ctest
