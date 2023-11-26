# BTF(BPF Type Format)

BTF is the metadata format which encodes the debug info related to BPF program/map. The name BTF was used initially to describe data types. The BTF was later extended to include function info for defined subroutines, and line info for source/line information.

The debug info is used for map pretty print, function signature, etc. The function signature enables better bpf program/function kernel symbol. The line info helps generate source annotated translated byte code, jited code and verifier log.

The BTF specification contains two parts,

- BTF kernel API
- BTF ELF file format

The kernel API is the contract between user space and kernel. The kernel verifies the BTF info before using it. The ELF file format is a user space contract between ELF file and libbpf loader.

The type and string sections are part of the BTF kernel API, describing the debug info (mostly types related) referenced by the bpf program. These two sections are discussed in details in 2. BTF Type and String Encoding.

## BTF Type and String Encoding

The file `include/uapi/linux/btf.h` provides high-level definition of how types/strings are encoded.

The beginning of data blob must be:

```c
struct btf_header {
    __u16   magic;
    __u8    version;
    __u8    flags;
    __u32   hdr_len;

    /* All offsets are in bytes relative to the end of this header */
    __u32   type_off;       /* offset of type section       */
    __u32   type_len;       /* length of type section       */
    __u32   str_off;        /* offset of string section     */
    __u32   str_len;        /* length of string section     */
};
```

The magic is `0xeB9F`, which has different encoding for big and little endian systems, and can be used to test whether BTF is generated for big- or little-endian target. The `btf_header` is designed to be extensible with `hdr_len` equal to `sizeof(struct btf_header)` when a data blob is generated.

### String Encoding

The first string in the string section must be a null string. The rest of string table is a concatenation of other null-terminated strings.

### Type Encoding

BTF represents each type with one of a few possible type descriptors identified by kind: `BTF_KIND_INT`, `BTF_KIND_ENUM`, `BTF_KIND_STRUCT`, `BTF_KIND_UNION`, `BTF_KIND_ARRAY`, ect.

That type has a index, and the type id `0` is reserved for void type. The type section is parsed sequentially and type id is assigned to each recognized type starting from id `1`. Currently, the following types are all supported list:

```c
#define BTF_KIND_INT            1       /* Integer      */
#define BTF_KIND_PTR            2       /* Pointer      */
#define BTF_KIND_ARRAY          3       /* Array        */
#define BTF_KIND_STRUCT         4       /* Struct       */
#define BTF_KIND_UNION          5       /* Union        */
#define BTF_KIND_ENUM           6       /* Enumeration up to 32-bit values */
#define BTF_KIND_FWD            7       /* Forward      */
#define BTF_KIND_TYPEDEF        8       /* Typedef      */
#define BTF_KIND_VOLATILE       9       /* Volatile     */
#define BTF_KIND_CONST          10      /* Const        */
#define BTF_KIND_RESTRICT       11      /* Restrict     */
#define BTF_KIND_FUNC           12      /* Function     */
#define BTF_KIND_FUNC_PROTO     13      /* Function Proto       */
#define BTF_KIND_VAR            14      /* Variable     */
#define BTF_KIND_DATASEC        15      /* Section      */
#define BTF_KIND_FLOAT          16      /* Floating point       */
#define BTF_KIND_DECL_TAG       17      /* Decl Tag     */
#define BTF_KIND_TYPE_TAG       18      /* Type Tag     */
#define BTF_KIND_ENUM64         19      /* Enumeration up to 64-bit values */
```

Note that the type section encodes debug info, not just pure types. BTF_KIND_FUNC is not a type, and it represents a defined subprogram.

Each type contains the following common data:

```c
struct btf_type {
    __u32 name_off;
    /* "info" bits arrangement
     * bits  0-15: vlen (e.g. # of struct's members)
     * bits 16-23: unused
     * bits 24-28: kind (e.g. int, ptr, array...etc)
     * bits 29-30: unused
     * bit     31: kind_flag, currently used by
     *             struct, union, fwd, enum and enum64.
     */
    __u32 info;
    /* "size" is used by INT, ENUM, STRUCT, UNION and ENUM64.
     * "size" tells the size of the type it is describing.
     *
     * "type" is used by PTR, TYPEDEF, VOLATILE, CONST, RESTRICT,
     * FUNC, FUNC_PROTO, DECL_TAG and TYPE_TAG.
     * "type" is a type_id referring to another type.
     */
    union {
            __u32 size;
            __u32 type;
    };
};
```

For certain kinds, the common data are followed by kind-specific data. The name_off in struct btf_type specifies the offset in the string table. The following sections detail encoding of each kind.

## BTF type graph

<img width="906" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/df79d1d4-d16a-404b-a790-0f01c72e58be">

The diagram above should give a pretty good idea of the BTF type graph. 

It shows some C source code on the left and its corresponding BTF type graph on the right. The type with ID 0 is special, it represents void and is implicit: the first type descriptor in the .BTF section has type ID 1. In all the diagrams in this blog post, type IDs are written out in the top-left corner of each type node. Type references are marked with arrows. For structs/unions it should be obvious from the diagrams which field references which type. 

A well-known tool, [`pahole`](https://linux.die.net/man/1/pahole), was recently updated with the ability to convert DWARF into corresponding BTF type information in a straightforward, one-to-one fashion. It iterates over each DWARF type descriptor, converts it trivially into a BTF type descriptor and embeds all of them into the `.BTF` section in the ELF binary. 

### Deduplication

In BTF type graph, the same type hierarchy (e.g., struct and all the types that struct references) can be represented in DWARF/BTF to various degrees of completeness (or rather, incompleteness) due to struct/union forward declarations.

Let's take a look at an example. Suppose we have two compilation units, each using same `struct S`, but each of them having incomplete type information about struct's fields:

<img width="587" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/59349d9f-73ef-47b3-bb15-fdc19d928f1d">

This compilation unit isolation means that it's possible there is no single CU with complete type information describing `structs S`, `A`, and `B`. Also, we might get tons of duplicated and redundant type information. Unfortunately, for BPF use cases that are going to rely on BTF data, it's important to have a single and complete type information per each unique type, without any duplicates and incompleteness.

That means we need to have an algorithm, that would take this duplicated and potentially incomplete BTF information and emit nicely deduplicated type information, while also "reconstructing" complete type information by merging pieces of it from different CUs.

So, in summary, we need an algorithm that will:

- deduplicate redundant BTF information and leave single instance of each unique type;
- merge and reconstruct complete type information across multiple CUs;
- handle type cycles correctly and efficiently;
  
do all of the above fast and reliably to become a part of Linux kernel build process.

The algorithm completes its work in five separate passes, which we'll describe briefly here and in detail in subsequent sections:

- **Strings deduplication**: Deduplicate string data, re-write all string offsets in BTF type descriptors to simplify string comparisons later.
- **Non-reference types deduplication**: Establish equivalence between and deduplicate integer, enum, struct, union and forward types.
- **Reference types deduplication**: Deduplicate pointers, const/volatile/restrict modifiers, typedefs, and array.
- **Type compaction**: Compact type descriptors leaving only unique ones.
- **Type IDs fix up**: Update all referenced type IDs with new ones established during compaction.

There are also a few important ideas and data structures the algorithm relies on, which are critical to understanding it and would be useful to keep in mind as you follow along.

1. **String deduplication** as a very first step. BTF doesn't embed strings into type descriptors. Instead, all the strings are concatenated into a byte array of string data with \0 as a separator. Strings themselves are referenced from type descriptors using offsets into this array (typically through name_off fields). By performing string deduplication early, we can avoid comparing string contents later: after string deduplication it's enough to just compare corresponding string offsets to determine string equality, which both saves time and simplifies code.

2. Using a side array to store **type equivalence mapping** for duplicated and resolved BTF types, instead of modifying IDs in-place. As the algorithm performs deduplication and type info merging, it needs to transform the type graph to record type equivalence and resolve forward declarations to struct/union type descriptors. By utilizing a separate array to store this mapping (instead of updating referenced type IDs in-place inside each affected BTF type descriptor), we are performing graph transformations that would potentially need O(N) type ID rewrites (if done in-place) with just a single value update in this array. This is a crucial idea to allow simple and efficient BTF_KIND_FWD → BTF_KIND_{STRUCT|UNION} remapping. The small price to pay for this is the need to consult this array for every type ID resolution when trying to get BTF type descriptor by type ID.

3. **Canonical types**. The algorithm determines the canonical type descriptor ("one and only representative") for each unique type. This canonical type is the one that will go into the final deduplicated BTF type information. For struct/unions, it is also the type that the algorithm will merge additional type information into, as it discovers it from data in other CUs. To facilitate fast discovery of canonical types, we also maintain a canonical index, which maps the type descriptor's signature (i.e., kind, name, size, etc.) into a list of canonical types that match that signature. With sufficiently good choice of type signature function, we can limit the number of canonical types for each unique type signature to a very small number, allowing the discovery of canonical type for any duplicated type very quickly.



---
reference
- https://www.kernel.org/doc/html/next/bpf/btf.html
- https://facebookmicrosites.github.io/bpf/blog/2018/11/14/btf-enhancement.html