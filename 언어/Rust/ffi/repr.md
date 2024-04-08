## repr(Rust)

- First and foremost, all types have an alignment specified in bytes. 
- A value with alignment n must only be stored at an address that is a multiple of n. So alignment 2 means you must be stored at an even address, and 1 means that you can be stored anywhere. 
- Alignment is at least 1, and always a power of 2.

- Primitives are usually aligned to their size, although this is platform-specific behavior. For example, on x86 u64 and f64 are often aligned to 4 bytes (32 bits).

- A type's size must always be a multiple of its alignment (Zero being a valid size for any alignment). 
  - This ensures that an array of that type may always be indexed by offsetting by a multiple of its size. Note that the size and alignment of a type may not be known statically in the case of dynamically sized types.

- Rust gives you the following ways to lay out composite data:
  - structs (named product types)
  - tuples (anonymous product types)
  - arrays (homogeneous product types)
  - enums (named sum types -- tagged unions)
  - unions (untagged unions)
  
- An enum is said to be field-less if none of its variants have associated data.

- By default, composite structures have an alignment equal to the maximum of their fields' alignments. Rust will consequently insert padding where necessary to ensure that all fields are properly aligned and that the overall type's size is a multiple of its alignment. For instance:

    ```rust
    struct A {
        a: u8,
        b: u32,
        c: u16,
    }
    ```

- will be 32-bit aligned on a target that aligns these primitives to their respective sizes. The whole struct will therefore have a size that is a multiple of 32-bits. 
    - It may become:
        ```rust
        struct A {
            a: u8,
            _pad1: [u8; 3], // to align `b`
            b: u32,
            c: u16,
            _pad2: [u8; 2], // to make overall size multiple of 4
        }
        ```

    - or maybe:
        ```rust
        struct A {
            b: u32,
            c: u16,
            a: u8,
            _pad: u8,
        }
        ```

- There is no indirection for these types; all data is stored within the struct, as you would expect in C. However with the exception of arrays (which are densely packed and in-order), the layout of data is not specified by default. Given the two following struct definitions:

    ```rust
    struct A {
        a: i32,
        b: u64,
    }

    struct B {
        a: i32,
        b: u64,
    }
    ```

- Rust does guarantee that two instances of A have their data laid out in exactly the same way. However Rust does not currently guarantee that an instance of A has the same field ordering or padding as an instance of B.

- With A and B as written, this point would seem to be pedantic, but several other features of Rust make it desirable for the language to play with data layout in complex ways.

- For instance, consider this struct:

    ```rust
    struct Foo<T, U> {
        count: u16,
        data1: T,
        data2: U,
    }
    ```

- Now consider the monomorphizations of `Foo<u32, u16>` and `Foo<u16, u32>`. If Rust lays out the fields in the order specified, we expect it to pad the values in the struct to satisfy their alignment requirements. So if Rust didn't reorder fields, we would expect it to produce the following:

    ```rust
    struct Foo<u16, u32> {
        count: u16,
        data1: u16,
        data2: u32,
    }

    struct Foo<u32, u16> {
        count: u16,
        _pad1: u16,
        data1: u32,
        data2: u16,
        _pad2: u16,
    }
    ```

- The latter case quite simply wastes space. An optimal use of space requires different monomorphizations to have different field orderings.

- Enums make this consideration even more complicated.
  - Naively, an enum such as:

    ```rust
    enum Foo {
        A(u32),
        B(u64),
        C(u8),
    }
    ```

  - might be laid out as:

    ```rust
    struct FooRepr {
        data: u64, // this is either a u64, u32, or u8 based on `tag`
        tag: u8,   // 0 = A, 1 = B, 2 = C
    }
    ```

- And indeed this is approximately how it would be laid out (modulo the size and position of tag).

- However there are several cases where such a representation is inefficient. The classic case of this is Rust's "null pointer optimization": an enum consisting of a single outer unit variant (e.g. `None`) and a (potentially nested) non-nullable pointer variant (e.g. `Some(&T)`) makes the tag unnecessary. A null pointer can safely be interpreted as the unit (None) variant. The net result is that, for example, `size_of::<Option<&T>>() == size_of::<&T>()`.

- There are many types in Rust that are, or contain, non-nullable pointers such as `Box<T>`, `Vec<T>`, `String`, `&T,` and `&mut T`. Similarly, one can imagine nested enums pooling their tags into a single discriminant, as they are by definition known to have a limited range of valid values. In principle enums could use fairly elaborate algorithms to store bits throughout nested types with forbidden values. As such it is especially desirable that we leave enum layout unspecified today.

### Dynamically Sized Types (DSTs)

- Rust supports Dynamically Sized Types (DSTs): types without a statically known size or alignment. 
- On the surface, this is a bit nonsensical: Rust must know the size and alignment of something in order to correctly work with it! In this regard, DSTs are not normal types. 
- Because they lack a statically known size, these types can only exist behind a pointer. Any pointer to a DST consequently becomes a wide pointer consisting of the pointer and the information that "completes" them (more on this below).

- There are two major DSTs exposed by the language:

  - trait objects: `dyn MyTrait`
  - slices: `[T]`, `str`, and others
  
- A trait object represents some type that implements the traits it specifies. The exact original type is erased in favor of runtime reflection with a vtable containing all the information necessary to use the type. The information that completes a trait object pointer is the vtable pointer. The runtime size of the pointee can be dynamically requested from the vtable.

- A slice is simply a view into some contiguous storage -- typically an array or Vec. The information that completes a slice pointer is just the number of elements it points to. The runtime size of the pointee is just the statically known size of an element multiplied by the number of elements.

- Structs can actually store a single DST directly as their last field, but this makes them a DST as well:

    ```rust
    // Can't be stored on the stack directly
    struct MySuperSlice {
        info: u32,
        data: [u8],
    }
    ```

- Although such a type is largely useless without a way to construct it. Currently the only properly supported way to create a custom DST is by making your type generic and performing an unsizing coercion:

    ```rust
    struct MySuperSliceable<T: ?Sized> {
        info: u32,
        data: T,
    }

    fn main() {
        let sized: MySuperSliceable<[u8; 8]> = MySuperSliceable {
            info: 17,
            data: [0; 8],
        };

        let dynamic: &MySuperSliceable<[u8]> = &sized;

        // prints: "17 [0, 0, 0, 0, 0, 0, 0, 0]"
        println!("{} {:?}", dynamic.info, &dynamic.data);
    }
    ```
- (Yes, custom DSTs are a largely half-baked feature for now.)

### Zero Sized Types (ZSTs)

- Rust also allows types to be specified that occupy no space:

    ```rust
    struct Nothing; // No fields = no size

    // All fields have no size = no size
    struct LotsOfNothing {
        foo: Nothing,
        qux: (),      // empty tuple has no size
        baz: [u8; 0], // empty array has no size
    }
    ```

- On their own, Zero Sized Types (ZSTs) are, for obvious reasons, pretty useless. However as with many curious layout choices in Rust, their potential is realized in a generic context: Rust largely understands that any operation that produces or stores a ZST can be reduced to a no-op. First off, storing it doesn't even make sense -- it doesn't occupy any space. Also there's only one value of that type, so anything that loads it can just produce it from the aether -- which is also a no-op since it doesn't occupy any space.

- One of the most extreme examples of this is Sets and Maps. Given a `Map<Key, Value>`, it is common to implement a `Set<Key>` as just a thin wrapper around` Map<Key, UselessJunk>`. In many languages, this would necessitate allocating space for UselessJunk and doing work to store and load UselessJunk only to discard it. Proving this unnecessary would be a difficult analysis for the compiler.

- However in Rust, we can **just say that `Set<Key> = Map<Key, ()>`**. Now Rust statically knows that every load and store is useless, and no allocation has any size. The result is that the monomorphized code is basically a custom implementation of a HashSet with none of the overhead that HashMap would have to support values.

- Safe code need not worry about ZSTs, but unsafe code must be careful about the consequence of types with no size. In particular, pointer offsets are no-ops, and allocators typically require a non-zero size.

- Note that references to ZSTs (including empty slices), just like all other references, must be non-null and suitably aligned. Dereferencing a null or unaligned pointer to a ZST is undefined behavior, just like for any other type.

### Empty Types
- Rust also enables types to be declared that cannot even be instantiated. These types can only be talked about at the type level, and never at the value level. Empty types can be declared by specifying an enum with no variants:

    ```rust
    enum Void {} // No variants = EMPTY
    ```

- Empty types are even more marginal than ZSTs. The primary motivating example for an empty type is type-level unreachability. For instance, suppose an API needs to return a Result in general, but a specific case actually is infallible. It's actually possible to communicate this at the type level by returning a `Result<T, Void>`. Consumers of the API can confidently unwrap such a Result knowing that it's statically impossible for this value to be an Err, as this would require providing a value of type Void.

- In principle, Rust can do some interesting analyses and optimizations based on this fact. For instance, `Result<T, Void>` is represented as just T, because the Err case doesn't actually exist (strictly speaking, this is only an optimization that is not guaranteed, so for example transmuting one into the other is still Undefined Behavior).

- The following could also compile:

```rust
enum Void {}

let res: Result<u32, Void> = Ok(0);

// Err doesn't exist anymore, so Ok is actually irrefutable.
let Ok(num) = res;
```

- But this trick doesn't work yet. One final subtle detail about empty types is that raw pointers to them are actually valid to construct, but dereferencing them is Undefined Behavior because that wouldn't make sense.

- We recommend against modelling C's `void*` type with `*const Void`. A lot of people started doing that but quickly ran into trouble because Rust doesn't really have any safety guards against trying to instantiate empty types with unsafe code, and if you do it, it's Undefined Behavior. This was especially problematic because developers had a habit of converting raw pointers to references and &Void is also Undefined Behavior to construct.

- `*const ()` (or equivalent) works reasonably well for `void*`, and can be made into a reference without any safety problems. It still doesn't prevent you from trying to read or write values, but at least it compiles to a no-op instead of Undefined Behavior.

### Extern Types

- There is an accepted RFC to add proper types with an unknown size, called extern types, which would let Rust developers model things like C's void* and other "declared but never defined" types more accurately. However as of Rust 2018, the feature is stuck in limbo over how `size_of_val::<MyExternType>()` should behave.

## repr(C)

- This is the most important repr. It has fairly simple intent: do what C does.
- The order, size, and alignment of fields is exactly what you would expect from C or C++. Any type you expect to pass through an FFI boundary should have `repr(C)`, as C is the lingua-franca of the programming world. 
  - This is also necessary to soundly do more elaborate tricks with data layout such as reinterpreting values as a different type.

- We strongly recommend using rust-bindgen and/or cbindgen to manage your FFI boundaries for you. The Rust team works closely with those projects to ensure that they **work robustly and are compatible with current and future guarantees about type layouts and reprs**.

- The interaction of `repr(C)` with Rust's more exotic data layout features must be kept in mind. Due to its dual purpose as "for FFI" and "for layout control", `repr(C)` can be applied to types that will be nonsensical or problematic if passed through the FFI boundary.

  - ZSTs are still zero-sized, even though this is not a standard behavior in C, and is explicitly contrary to the behavior of an empty type in C++, which says they should still consume a byte of space.

  - DST pointers (wide pointers) and tuples are not a concept in C, and as such are never FFI-safe.

  - Enums with fields also aren't a concept in C or C++, but a valid bridging of the types is defined.

  - If `T` is an FFI-safe non-nullable pointer type, `Option<T>` is guaranteed to have the same layout and ABI as T and is therefore also FFI-safe. As of this writing, this covers `&`, `&mut`, and function pointers, all of which can never be null.

  - Tuple structs are like structs with regards to `repr(C)`, as the only difference from a struct is that the fields aren’t named.

  - `repr(C)` is equivalent to one of repr(u*) (see the next section) for fieldless enums. The chosen size is the default enum size for the target platform's C application binary interface (ABI). Note that enum representation in C is implementation defined, so this is really a "best guess". In particular, this may be incorrect when the C code of interest is compiled with certain flags.

  - Fieldless enums with `repr(C)` or `repr(u*)` still may not be set to an integer value without a corresponding variant, even though this is permitted behavior in C or C++. It is undefined behavior to (unsafely) construct an instance of an enum that does not match one of its variants. (This allows exhaustive matches to continue to be written and compiled as normal.)

## repr(transparent)

- `#[repr(transparent)]` can only be used on a struct or single-variant enum that has a single non-zero-sized field (there may be additional zero-sized fields). The effect is that the layout and ABI of the whole struct/enum is guaranteed to be the same as that one field.

> NOTE: There's a transparent_unions nightly feature to apply repr(transparent) to unions, but it hasn't been stabilized due to design concerns. 

- The goal is to make it possible to **transmute between the single field and the struct/enum**. An example of that is [`UnsafeCell`](https://doc.rust-lang.org/std/cell/struct.UnsafeCell.html), which can be transmuted into the type it wraps (`UnsafeCell` also uses the unstable no_niche, so its ABI is not actually guaranteed to be the same when nested in other types).

- Also, passing the struct/enum through FFI where the inner field type is expected on the other side is guaranteed to work. In particular, this is necessary for `struct Foo(f32)` or `enum Foo { Bar(f32) }` to always have the same ABI as f32.

- This repr is only considered part of the public ABI of a type if either the single field is pub, or if its layout is documented in prose. Otherwise, the layout should not be relied upon by other crates.

- More details are in the [RFC 1758](https://github.com/rust-lang/rfcs/blob/master/text/1758-repr-transparent.md) and the [RFC 2645](https://rust-lang.github.io/rfcs/2645-transparent-unions.html).

## repr(u*), repr(i*)

- These specify the size to make a fieldless enum. If the discriminant overflows the integer it has to fit in, it will produce a compile-time error. 

- You can manually ask Rust to allow this by setting the overflowing element to explicitly be 0. However Rust will not allow you to create an enum where two variants have the same discriminant.

- The term "fieldless enum" only means that the enum doesn't have data in any of its variants. A fieldless enum without a `repr(u*)` or `repr(C)` is still a Rust native type, and does not have a stable ABI representation. Adding a repr causes it to be treated exactly like the specified integer size for ABI purposes.

- If the enum has fields, the effect is similar to the effect of `repr(C)` in that there is a defined layout of the type. This makes it possible to pass the enum to C code, or access the type's raw representation and directly manipulate its tag and fields. See the RFC for details.

- These reprs have no effect on a struct.

- Adding an explicit `repr(u*)`, `repr(i*)`, or `repr(C)` to an enum with fields suppresses the null-pointer optimization, like:

    ```rust
    enum MyOption<T> {
        Some(T),
        None,
    }

    #[repr(u8)]
    enum MyReprOption<T> {
        Some(T),
        None,
    }

    assert_eq!(8, size_of::<MyOption<&u16>>());
    assert_eq!(16, size_of::<MyReprOption<&u16>>());
    ```

This optimization still applies to fieldless enums with an explicit `repr(u*)`, `repr(i*)`, or `repr(C)`.

## repr(packed)

- repr(packed) forces Rust to strip any padding, and only align the type to a byte. This may improve the memory footprint, but will likely have other negative side-effects.

- In particular, most architectures strongly prefer values to be aligned. This may mean the unaligned loads are penalized (x86), or even fault (some ARM chips). For simple cases like directly loading or storing a packed field, the compiler might be able to paper over alignment issues with shifts and masks. 
  - However if you take a reference to a packed field, it's unlikely that the compiler will be able to emit code to avoid an unaligned load.

- As this can cause undefined behavior, the lint has been implemented and it will become a hard error.

- repr(packed) is not to be used lightly. Unless you have extreme requirements, this should not be used.

- This repr is a modifier on `repr(C)` and repr(Rust).

## repr(align(n))

- repr(align(n)) (where n is a power of two) forces the type to have an alignment of at least n.

- This enables several tricks, like making sure neighboring elements of an array never share the same cache line with each other (which may speed up certain kinds of concurrent code).

- This is a modifier on `repr(C)` and repr(Rust). It is incompatible with repr(packed).

---
reference
- https://doc.rust-lang.org/nomicon/other-reprs.html