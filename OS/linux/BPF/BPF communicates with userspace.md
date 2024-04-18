once a program is attached and running, how do we gather information from it? There are three ways to do do this; using BPF maps, perf events and bpf_trace_printk.

## 1. BPF maps

### When should I use maps?

BPF maps are useful for gathering information during BPF programs to share with other running BPF programs, or with userspace programs which can also see the map data.

### How can I use it

The set of map types is described in [`include/linux/uapi/bpf.h`](https://github.com/torvalds/linux/blob/master/include/uapi/linux/bpf.h). The enumerated `bpf_map_type` looks like this:

```c
// include/linux/uapi/bpf.h
enum bpf_map_type {
        BPF_MAP_TYPE_UNSPEC,
        BPF_MAP_TYPE_HASH,
        BPF_MAP_TYPE_ARRAY,
        BPF_MAP_TYPE_PROG_ARRAY,
        BPF_MAP_TYPE_PERCPU_HASH,
        BPF_MAP_TYPE_PERCPU_ARRAY,
        BPF_MAP_TYPE_STACK_TRACE,
        BPF_MAP_TYPE_CGROUP_ARRAY,
        BPF_MAP_TYPE_LRU_HASH,
        BPF_MAP_TYPE_LRU_PERCPU_HASH,
        BPF_MAP_TYPE_LPM_TRIE,
        BPF_MAP_TYPE_ARRAY_OF_MAPS,
        BPF_MAP_TYPE_HASH_OF_MAPS,
        BPF_MAP_TYPE_DEVMAP,
        BPF_MAP_TYPE_SOCKMAP,
};
enum bpf_map_type {
        BPF_MAP_TYPE_UNSPEC,
        BPF_MAP_TYPE_HASH,
        BPF_MAP_TYPE_ARRAY,
        BPF_MAP_TYPE_PROG_ARRAY,
        BPF_MAP_TYPE_PERCPU_HASH,
        BPF_MAP_TYPE_PERCPU_ARRAY,
        BPF_MAP_TYPE_STACK_TRACE,
        BPF_MAP_TYPE_CGROUP_ARRAY,
        BPF_MAP_TYPE_LRU_HASH,
        BPF_MAP_TYPE_LRU_PERCPU_HASH,
        BPF_MAP_TYPE_LPM_TRIE,
        BPF_MAP_TYPE_ARRAY_OF_MAPS,
        BPF_MAP_TYPE_HASH_OF_MAPS,
        BPF_MAP_TYPE_DEVMAP,
        BPF_MAP_TYPE_SOCKMAP,
};
```

### Map actions

We can create/update, delete and lookup map information, both in BPF programs and in user-space. User-space map interactions are done via the BPF syscall. Their function signatures are slightly different to those of their in-kernel BPF program equivalents. In `tools/lib/bpf/bpf.c` wrappers for these actions are present:

```c
int bpf_create_map(enum bpf_map_type map_type, int key_size, int value_size, int max_entries, __u32 map_flags);

Description
    Create BPF map of specified type, with key/value size, of max_entries size with map flags specified.
Returns
     File descriptor for map on success, negative error on failure.



int bpf_create_map_node(enum bpf_map_type map_type, int key_size, int value_size, int max_entries, __u32 map_flags, int node);

Description
    NUMA node-specific creation of BPF map.
Returns
    File descriptor for map on success, negative error on failure.



int bpf_create_map_in_map(enum bpf_map_type map_type, int key_size, int inner_map_fd, int max_entries, __u32 map_flags);

Description
    Create map of specified type, passing in fd of inner map as representative
Returns
    File descriptor for map on success, negative error on failure.



int bpf_create_map_in_map_node(enum bpf_map_type map_type, int key_size, int inner_map_fd, int max_entries, __u32 map_flags, int node);

Description
    NUMA node-specific creation of BPF map-in-map.
Returns
    File descriptor for map on success, negative error on failure.



int bpf_map_update_elem(int fd, const void *key, const void *value, __u64 flags);

Description
       Update element with specified key with new value. A few flag values are supported.

       BPF_NOEXIST

       The entry for key must not exist in the map.

       BPF_EXIST

       The entry for key must already exist in the map.

       BPF_ANY

       No condition on the existence of the entry for key

       Flag value BPF_NOEXIST cannot be used for maps of types _ARRAY (all elements always exist), the helper would return an error.
Returns
    0 on success, negative errno on failure.



int bpf_map_lookup_elem(int fd, const void *key, void *value);

Description
    Look up value associated with specific key. If successful value will point to retrieved value. The value will be copied if necessary.
Returns
    0 on success, negative errno on failure.



int bpf_map_delete_elem(int fd, const void *key);

Description
    Delete element with specified key. Delete is not supported for array values.

Returns
    0 on success, negative errno on failure.



int bpf_map_get_next_key(int fd, const void *key, void *next_key);

Description
    On success, next_key will point at next key after specified *key.
Returns
     0 on success, negative error on failure or when no more keys are available.



int bpf_map_get_next_id(__u32 start_id, __u32 *next_id);

Description
     Get id of next map given start id.
Returns
     0 on success, negative error on failure or when no more ids are available.



int bpf_create_map(enum bpf_map_type map_type, int key_size, int value_size, int max_entries, __u32 map_flags);

Description
    Create BPF map of specified type, with key/value size, of max_entries size with map flags specified.
Returns
     File descriptor for map on success, negative error on failure.



int bpf_create_map_node(enum bpf_map_type map_type, int key_size, int value_size, int max_entries, __u32 map_flags, int node);

Description
    NUMA node-specific creation of BPF map.
Returns
    File descriptor for map on success, negative error on failure.



int bpf_create_map_in_map(enum bpf_map_type map_type, int key_size, int inner_map_fd, int max_entries, __u32 map_flags);

Description
    Create map of specified type, passing in fd of inner map as representative
Returns
    File descriptor for map on success, negative error on failure.



int bpf_create_map_in_map_node(enum bpf_map_type map_type, int key_size, int inner_map_fd, int max_entries, __u32 map_flags, int node);

Description
    NUMA node-specific creation of BPF map-in-map.
Returns
    File descriptor for map on success, negative error on failure.


int bpf_map_update_elem(int fd, const void *key, const void *value, __u64 flags);

Description

       Update element with specified key with new value. A few flag values are supported.

       BPF_NOEXIST

       The entry for key must not exist in the map.

       BPF_EXIST

       The entry for key must already exist in the map.

       BPF_ANY

       No condition on the existence of the entry for key

       Flag value BPF_NOEXIST cannot be used for maps of types _ARRAY (all elements always exist), the helper would return an error.
Returns
    0 on success, negative errno on failure.



int bpf_map_lookup_elem(int fd, const void *key, void *value);

Description
    Look up value associated with specific key. If successful value will point to retrieved value. The value will be copied if necessary.
Returns
    0 on success, negative errno on failure.



int bpf_map_delete_elem(int fd, const void *key);

Description
    Delete element with specified key. Delete is not supported for array values.
Returns
    0 on success, negative errno on failure.



int bpf_map_get_next_key(int fd, const void *key, void *next_key);

Description
    On success, next_key will point at next key after specified *key.
Returns
     0 on success, negative error on failure or when no more keys are available.



int bpf_map_get_next_id(__u32 start_id, __u32 *next_id);

Description
     Get id of next map given start id.
Returns
     0 on success, negative error on failure or when no more ids are available.
```

### Defining a map in a BPF program

Under `samples/bpf`, maps are defined in a kernel BPF program in a dedicated section as a type `"struct bpf_map_def"` which bpf_load.h defines as:

```c
struct bpf_map_def {
        unsigned int type;
        unsigned int key_size;
        unsigned int value_size;
        unsigned int max_entries;
        unsigned int map_flags;
        unsigned int inner_map_idx;
        unsigned int numa_node;
};
struct bpf_map_def {
        unsigned int type;
        unsigned int key_size;
        unsigned int value_size;
        unsigned int max_entries;
        unsigned int map_flags;
        unsigned int inner_map_idx;
        unsigned int numa_node;
};
```

An example of a definition using this structure is in `samples/bpf/lathist_kern.c` :

```c
struct bpf_map_def SEC("maps") my_map = {
        .type = BPF_MAP_TYPE_ARRAY,
        .key_size = sizeof(int),
        .value_size = sizeof(u64),
        .max_entries = MAX_CPU,
};
struct bpf_map_def SEC("maps") my_map = {
        .type = BPF_MAP_TYPE_ARRAY,
        .key_size = sizeof(int),
        .value_size = sizeof(u64),
        .max_entries = MAX_CPU,
};
```

Once `bpf_load.c` has scanned the ELF headers, it calls `bpf_create_map_node()` or `bpf_create_map_in_map_node()` which are implemented in `tools/lib/bpf/bpf.c` as wrappers to the `BPF_MAP_CREATE` command for the `SYS_BPF` syscall.

Unless you are writing tc or lightweight tunnel BPF programs - which, since they implement BPF program loading themselves have their own map loading mechanisms - I'd recommend re-using this code rather than re-inventing the wheel. We can see it's generally a case of defining a map type, key/value sizes and a maximum number of entries.

Programs which use `"tc"/"ip route"` for loading can utilize a data structure like this (from `tc_l2_redirect_kern.c`):


```c
#define PIN_GLOBAL_NS           2

struct bpf_elf_map {
        __u32 type;
        __u32 size_key;
        __u32 size_value;
        __u32 max_elem;
        __u32 flags;
        __u32 id;
        __u32 pinning;
};    

struct bpf_elf_map SEC("maps") tun_iface = {
        .type = BPF_MAP_TYPE_ARRAY,
        .size_key = sizeof(int),
        .size_value = sizeof(int),
        .pinning = PIN_GLOBAL_NS,
        .max_elem = 1,

};
#define PIN_GLOBAL_NS           2

struct bpf_elf_map {
        __u32 type;
        __u32 size_key;
        __u32 size_value;
        __u32 max_elem;
        __u32 flags;
        __u32 id;
        __u32 pinning;
};    

struct bpf_elf_map SEC("maps") tun_iface = {
        .type = BPF_MAP_TYPE_ARRAY,
        .size_key = sizeof(int),
        .size_value = sizeof(int),
        .pinning = PIN_GLOBAL_NS,
        .max_elem = 1,

};
```

The bpf_elf_map data structure mirrors that defined in https://git.kernel.org/pub/scm/network/iproute2/iproute2.git/tree/include/bpf_elf.h?h=v4.14.1.

### Map pinning

In that file, we can see that there are a few options for pinning a map:

```c
/* Object pinning settings */

#define PIN_NONE        0
#define PIN_OBJECT_NS        1
#define PIN_GLOBAL_NS        2
/* Object pinning settings */

#define PIN_NONE        0
#define PIN_OBJECT_NS        1
#define PIN_GLOBAL_NS        2
```

Pinning options determine how the map's file descriptor is exported via the filesystem. Outside of tc etc, we can pin a map fd to a file via libbpf's `bpf_obj_pin(fd, path)`. Then other programs etc can retrieve the fd via `bpf_obj_get()`. The `PIN_*` options for iproute determine that path - for example maps which specify `PIN_GLOBAL_NS` are found in `/sys/fs/bpf/tc/globals/` , so to retrieve the map fd one simply runs

```c
mapfd = bpf_obj_get(pinned_file);
mapfd = bpf_obj_get(pinned_file);
```

...where "pinned_file" is the filename. From looking at the iproute code it appears a custom pinning path can also be used (by specifying a value > PIN_GLOBAL_NS).

### Map operation definitions

Examining `include/linux/bpf_types.h`, we see that the various map types have associated sets of operations; for example:

```c
BPF_MAP_TYPE(BPF_MAP_TYPE_ARRAY, array_map_ops)
BPF_MAP_TYPE(BPF_MAP_TYPE_PERCPU_ARRAY, percpu_array_map_ops)
BPF_MAP_TYPE(BPF_MAP_TYPE_ARRAY, array_map_ops)
BPF_MAP_TYPE(BPF_MAP_TYPE_PERCPU_ARRAY, percpu_array_map_ops)
```
etc. The functions in the various ops variables define how the map allocates, frees, looks up data and much more. For example, as you might imagine the key for the lookup function for a `BPF_MAP_TYPE_ARRAY` is simply an index into the array. We see in `kernel/bpf/arraymap.c`:

```c
/* Called from syscall or from eBPF program */
static void *array_map_lookup_elem(struct bpf_map *map, void *key)
{
    struct bpf_array *array = container_of(map, struct bpf_array, map);
    u32 index = *(u32 *)key;

    if (unlikely(index >= array->map.max_entries))
        return NULL;

    return array->value + array->elem_size * (index & array->index_mask);
}

/* Called from syscall or from eBPF program */
static void *array_map_lookup_elem(struct bpf_map *map, void *key)
{
    struct bpf_array *array = container_of(map, struct bpf_array, map);
    u32 index = *(u32 *)key;

    if (unlikely(index >= array->map.max_entries))
        return NULL;

    return array->value + array->elem_size * (index & array->index_mask);
}
```

### Array Maps

Array maps are implemented in `kernel/bpf/arraymap.c`. All arrays restrict key size to 4 bytes (64 bits), and delete of values is not supported.

- `BPF_MAP_TYPE_ARRAY`: Simple array. Key is the array index, and elements cannot be deleted.
- `BPF_MAP_TYPE_PERCPU_ARRAY`: As above, but kernel programs implicitly write to a per-CPU allocated array which minimizes lock contention in BPF program context. When bpf_map_lookup_elem() is called, it retrieves NR_CPUS values. For example, if we are summing a stat across CPUs, we would do something like this:

    ```c
    long values[nr_cpus];
                                            ...

                            ret = bpf_map_lookup_elem(map_fd, &next_key, values);
                            if (ret) {
                                    perror("Error looking up stat");
                                    continue;
                            }

                            for (i = 0; i < nr_cpus; i++) {
                                    sum += values[i];
                            }
    long values[nr_cpus];
                                                    ...

                            ret = bpf_map_lookup_elem(map_fd, &next_key, values);
                            if (ret) {
                                    perror("Error looking up stat");
                                    continue;
                            }

                            for (i = 0; i < nr_cpus; i++) {
                                    sum += values[i];
                            }
    ```

Use of a per-cpu data structure is to be preferred in codepaths which are frequently executed, since we will likely be aggregating the results across CPUs in user-space much less frequently than writing updates.

- `BPF_MAP_TYPE_PROG_ARRAY`: An array of BPF programs used as a jump table by `bpf_tail_call()`. See [`samples/bpf/sockex3_kern.c`](https://github.com/torvalds/linux/blob/8cd26fd90c1ad7acdcfb9f69ca99d13aa7b24561/samples/bpf/sockex3_kern.c#L4) for an example.

- `BPF_MAP_TYPE_PERF_EVENT_ARRAY`: Array map which is used by the kernel in `bpf_perf_event_output()` to associate tracing output with a specific key. User-space programs associate fds with each key, and can `poll()` those fds to receive notification that data has been traced. See "Perf Events" section below for more details.

- `BPF_MAP_TYPE_CGROUP_ARRAY`: Array map used to store cgroup fds in user-space for later use in BPF programs which call `bpf_skb_under_cgroup()` to check if skb is associated with the cgroup in the cgroup array at the specified index.

- `BPF_MAP_TYPE_ARRAY_OF_MAPS`: Allows map-in-map definition where the values are the fds for the inner maps. Only two levels of map are supported, i.e. a map containing maps, not a map containing maps containing maps. `BPF_MAP_TYPE_PROG_ARRAY` does not support map-in-map functionality as it would make tail call verification harder. See https://www.mail-archive.com/netdev@vger.kernel.org/msg159387.html. for more.

### Hash Maps

Hash maps are implemented in `kernel/bpf/hashmap.c`. Hash keys do not appear to be limited in size but must `be > 0` for obvious reasons. Hash lookup matches the key to the appropriate value via a hashing function rather than an indexed lookup. Unlike the array case, values can be deleted from a hashmap. Hash maps are ideal when using a value such as an IP address for storage/retrieval.

- `BPF_MAP_TYPE_HASH`: simple hash map. Continually adding new elements can fail with E2BIG - if this is likely to be an issue, an LRU (least recently used) hash is recommended as it will recycle old entries out of buckets.
- `BPF_MAP_TYPE_PERCPU_HASH`: same as above, but kernel programs implicitly write to the CPU-specific hash. Retrieval works as described above.
- `BPF_MAP_TYPE_LRU_HASH`: Each hash maintains an LRU (least recently used) list for each bucket to inform delete when the hash bucket fills up.
- `BPF_MAP_TYPE_HASH_OF_MAPS`: Similar to ARRAY_OF_MAPS for for hash. See https://www.mail-archive.com/netdev@vger.kernel.org/msg159383.html for more.
 
### Other

- `BPF_MAP_TYPE_STACK_TRACE`: defined in `kernel/bpf/stackmap.c`. Kernel programs can store stacks via the `bpf_get_stackid()` helper. The idea is we store stacks based on an identifier which appears to correspond to a 32-bit hash of the instruction pointer addresses that comprise the stack for the current context. The common use case is to get stack id in kernel, and use it as key to update another map. So for example we could profile specific stack traces by counting their occurence, or associate a specific stack trace with the current pid as key. See samples/bpf/offwaketime_kern.c for an example of the latter. In user-space we can look up the symbols associated with the stackmap to unwind the stack (see [`samples/bpf/offwaketime_user.c`](https://github.com/torvalds/linux/blob/8cd26fd90c1ad7acdcfb9f69ca99d13aa7b24561/samples/bpf/offwaketime_user.c#L4)).
- `BPF_MAP_TYPE_LPM_TRIE`: Map supporting efficient longest-prefix matching. Useful for storage/retrieval of IP routes for example.
- `BPF_MAP_TYPE_SOCKMAP`: sockmaps are used primarily for socket redirection, where sockets added to a socket map and referenced by a key which dictates redirection when `bpf_sockmap_redirect()` is called.
- `BPF_MAP_TYPE_DEVMAP`: does a similar job to sockmap, with netdevices for XDP and `bpf_redirect()`.

## 2. Perf Events

As well as using maps, perf events can be used to gather information from BPF in user-space. Perf events allow BPF programs to store data in `mmap()`ed shared memory accessible by user-space programs.

- When should I use perf events? If you are gathering kernel data that is not amenable to map storage (such as variable-length chunks of memory) and does not need to be shared with other BPF programs.
- How can I use it? To see an example of how to set this up on the user-space side, see samples/bpf/trace_output_user.c and samples/bpf/trace_output_kern.c.

### User-space
- First we may need to up the rlimit (resource limit) of how much memory we can lock in RAM (`RLIMIT_MEMLOCK`) - we need to lock memory for maps. See [setrlimit(2)/getrlimit(2)](https://linux.die.net/man/2/setrlimit)
- Create a map of type `BPF_MAP_TYPE_PERF_EVENT_ARRAY`. It can be keyed by CPU, and in that case the associated value for each key will be the fd associated with the perf event opened for that CPU.
- For each CPU, `run perf_event_open()` with a perf event with attributes of type `PERF_TYPE_SOFTWARE`, config `PERF_COUNT_SW_BPF_OUTPUT`, sample_type `PERF_SAMPLE_RAW`
- Update the `BPF_MAP_TYPE_PERF_EVENT_ARRAY` for the current CPU with the fd retrieved from the `perf_event_open()`. See `test_bpf_perf_event()`
- Run `PERF_EVENT_IOC_ENABLE` `ioctl()` for perf event fd
- `mmap()` read/write shared memory for the perf event fd. See `perf_event_mmap()`. This will store struct `perf_event_mmap_page *` containing the data.
- Add the perf event fd to the set of fds used in `poll()` so we can poll on events from the set of fds for each CPU to catch events.
- Now we are ready to run `poll()`, and handle events enqueued (see perf_event_read())

### Kernel
- The program needs to define `BPF_MAP_TYPE_PERF_EVENT_ARRAY` to share with userspace.
- Program should run `bpf_perf_event_output(ctx, &map, index, &data, sizeof(data))`. The index is the key of the `BPF_MAP_TYPE_PERF_EVENT_ARRAY` map, so if we're keying per-cpu it should be a CPU id.

As we saw previously, bpf_perf_event_output() is supported for tc, XDP, lightweight tunnel, and kprobe, tracepoint and perf events program types. The context passed in is the relevant context for each of those program types.

## 3. bpf_trace_printk

### When should I use it?
This option is more for debugging and should not be used in production BPF code. All BPF program types support `bpf_trace_printk()` and it is useful for debugging.

### How can I use it?
Simply add a `bpf_trace_printk()` to your program. Messages can be retrieved via

```c
# cat /sys/kernel/debug/tracing/trace_pipe
```

One gotcha here; you need to pre-define the format string otherwise the BPF verifier will complain. I usually use the following approach: define a general error message format, and have it add specifics with a particular string. For example:

```c
char errmsg[] = "egress: got unexpected error (%s) %x\n";
    char store_fail[] = "could not store ipv6 hdr";

    bpf_trace_printk(errmsg, sizeof(errmsg), store_fail, ret);
char errmsg[] = "egress: got unexpected error (%s) %x\n";
    char store_fail[] = "could not store ipv6 hdr";

    bpf_trace_printk(errmsg, sizeof(errmsg), store_fail, ret);
```

One approach to consider is to have a config option BPF map shared between your program and user-space and if the config debug option is set, emit `bpf_trace_printk()`s.

---
reference
- https://man7.org/linux/man-pages/man7/bpf-helpers.7.html
- http://blogs.oracle.com/linux/notes-on-bpf-2
- https://nakryiko.com/posts/bpf-tips-printk/