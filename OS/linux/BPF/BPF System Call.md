
```c
#include <linux/bpf.h>

int bpf(int cmd, union bpf_attr *attr, unsigned int size);
```

- `bpf()` 시스템 콜은 eBPF와 관련된 다양한 동작을 수행한다. 이 시스템 콜을 사용해 커널 내 eBPF 헬퍼 함수들을 호출할 수 있으며 eBPF Map 같은 공유 자료 구조에 접근할 수 있다.

- 각 eBPF 프로그램은 완료 때까지 안전하게 실행할 수 있는 명령어들의 집합이다. 커널 내 검증기가 eBPF 프로그램이 안전한지 여부를 정적으로 판단한다. 검증하는 동안 커널에서 그 eBPF 프로그램이 쓰는 맵 각각에 참조 카운터를 올려서 프로그램이 내려갈 때까지 관련 맵들이 제거되지 않도록 한다.

### cmd

- `bpf()` 시스템 호출이 수행할 동작을 cmd 인자로 결정할 수 있다. 각 동작은 bpf_attr 타입 공용체(아래 참고) 포인터인 attr을 통해 추가 인자를 받는다. size 인자는 attr이 가리키는 공용체의 크기다.

- cmd로 주는 값은 다음 중 하나이다.
  - `BPF_MAP_CREATE`: 맵을 생성하고 그 맵을 가리키는 파일 디스크립터를 반환한다. 새 파일 디스크립터에는 close-on-exec 플래그가 자동으로 켜진다.
  - `BPF_MAP_LOOKUP_ELEM`: 지정한 맵에서 키로 항목을 찾아서 그 값을 반환한다.
  - `BPF_MAP_UPDATE_ELEM`: 지정한 맵에서 항목(키/값 쌍)을 생성하거나 갱신한다.
  - `BPF_MAP_DELETE_ELEM`: 지정한 맵에서 키로 항목을 찾아서 삭제한다.
  - `BPF_MAP_GET_NEXT_KEY`: 지정한 맵에서 키로 항목을 찾아서 다음 항목의 키를 반환한다.
  - `BPF_PROG_LOAD`: eBPF 프로그램을 검증 및 적재하고 프로그램과 연계된 새 파일 디스크립터를 반환한다. 새 파일 디스크립터에는 close-on-exec 플래그가 자동으로 켜진다.
  
### attr

- attr는 명령어 실행 옵션을 넣기 위한 파라미터이다. `bpf_attr` union은 여러 `bpf()` 명령에서 쓰는 다양한 익명 구조체들로 이뤄져 있다.

    ```c
    union bpf_attr {
        struct {    /* BPF_MAP_CREATE에 사용 */
            __u32         map_type;
            __u32         key_size;    /* 키 크기, 바이트 단위 */
            __u32         value_size;  /* 값 크기, 바이트 단위 */
            __u32         max_entries; /* 맵 내의 항목 최대 개수 */
        };

        struct {    /* BPF_MAP_*_ELEM 및 BPF_MAP_GET_NEXT_KEY
                    명령에 사용 */
            __u32         map_fd;
            __aligned_u64 key;
            union {
                __aligned_u64 value;
                __aligned_u64 next_key;
            };
            __u64         flags;
        };

        struct {    /* BPF_PROG_LOAD에 사용 */
            __u32         prog_type;
            __u32         insn_cnt;
            __aligned_u64 insns;      /* 'const struct bpf_insn *' */
            __aligned_u64 license;    /* 'const char *' */
            __u32         log_level;  /* 검증기의 출력 상세도 */
            __u32         log_size;   /* 사용자 버퍼 크기 */
            __aligned_u64 log_buf;    /* 사용자가 제공하는 'char *'
                                        버퍼 */
            __u32         kern_version;
                                    /* prog_type=kprobe일 때 검사
                                        (리눅스 4.1부터) */
        };
    } __attribute__((aligned(8)));
    ```

### size

- size 파라미터에는 attr가 가리키는 union의 size 값을 넣으면 된다.

# map 관련 시스템 콜

## `BPF_MAP_CREATE`

- BPF_MAP_CREATE 명령은 새로운 맵을 만들고 그 맵을 가리키는 새 파일 디스크립터를 반환한다.

    ```c
    int
    bpf_create_map(enum bpf_map_type map_type,
                unsigned int key_size,
                unsigned int value_size,
                unsigned int max_entries)
    {
        union bpf_attr attr = {
            .map_type    = map_type,
            .key_size    = key_size,
            .value_size  = value_size,
            .max_entries = max_entries
        };

        return bpf(BPF_MAP_CREATE, &attr, sizeof(attr));
    }
    ```

- `map_type`으로 맵의 종류를 지정할 수 있다. `map_type`으로 지원되는 값은 다음과 같은 것들이 있다.

    ```c
    // /usr/include/linux/bpf.h
    enum bpf_map_type {
        BPF_MAP_TYPE_UNSPEC,  /* 0은 유효하지 않은 맵 종류로 예약 */
        BPF_MAP_TYPE_HASH,
        BPF_MAP_TYPE_ARRAY,
        BPF_MAP_TYPE_PROG_ARRAY,
        BPF_MAP_TYPE_PERF_EVENT_ARRAY,
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
        BPF_MAP_TYPE_CPUMAP,
        BPF_MAP_TYPE_XSKMAP,
        BPF_MAP_TYPE_SOCKHASH,
        BPF_MAP_TYPE_CGROUP_STORAGE,
        BPF_MAP_TYPE_REUSEPORT_SOCKARRAY,
        BPF_MAP_TYPE_PERCPU_CGROUP_STORAGE,
        BPF_MAP_TYPE_QUEUE,
        BPF_MAP_TYPE_STACK,
        // /usr/include/linux/bpf.h
    };
    ```

  - `BPF_MAP_TYPE_PROG_ARRAY`

    - eBPF 맵중에는 program array라는 특수한 맵이 있다. 이 맵은 다른 eBPF 프로그램을 가리키는 파일 디스크립터들을 저장한다. 
      - 이 맵에서 lookup을 수행하면 프로그램 흐름이 그대로 다른 eBPF 프로그램의 시작점으로 옮겨진다. 

    - 호출된 프로그램은 같은 스택을 재사용하게 된다. 새 프로그램으로 점프를 수행하고 나면 이전 프로그램으로는 더이상 돌아오지 않는다.
       
    - 중첩 깊이 제한은 32단계이다. 맵에 저장된 프로그램 파일 디스크립터는 런타임에 변경할 수 있다.

    - 프로그램 배열 맵에서 참조하는 모든 프로그램은 `bpf()`를 통해 커널로 미리 적재해 둬야 한다. 맵 탐색이 실패하면 현재 프로그램이 실행을 계속한다. 

    - `key_size`와 `value_size` 모두 정확히 4바이트여야 한다.
    - 이 맵은 `bpf_tail_call()` 헬퍼와 함께 사용한다.

        ```c
        void bpf_tail_call(void *context, void *prog_map,
                        unsigned int index);
        ```

    - 프로그램 배열의 주어진 색인에서 eBPF 프로그램을 찾을 수 없으면 현재 eBPF 프로그램 실행을 계속한다. 

## `BPF_MAP_LOOKUP_ELEM`

- `BPF_MAP_LOOKUP_ELEM` 명령은 파일 디스크립터 fd가 가리키는 맵에서 주어진 key로 항목을 찾는다.

    ```c
    int
    bpf_lookup_elem(int fd, const void *key, void *value)
    {
        union bpf_attr attr = {
            .map_fd = fd,
            .key    = ptr_to_u64(key),
            .value  = ptr_to_u64(value),
        };

        return bpf(BPF_MAP_LOOKUP_ELEM, &attr, sizeof(attr));
    }
    ```

- 항목을 찾으면 동작이 0을 반환하며 항목의 값을 value에 저장한다. value는 `value_size` 바이트 크기의 버퍼를 가리켜야 한다.

## `BPF_MAP_UPDATE_ELEM`

- `BPF_MAP_UPDATE_ELEM` 명령은 파일 디스크립터 fd가 가리키는 맵에서 주어진 key/value로 항목을 생성하거나 갱신한다.

    ```c
    int
    bpf_update_elem(int fd, const void *key, const void *value,
                    uint64_t flags)
    {
        union bpf_attr attr = {
            .map_fd = fd,
            .key    = ptr_to_u64(key),
            .value  = ptr_to_u64(value),
            .flags  = flags,
        };

        return bpf(BPF_MAP_UPDATE_ELEM, &attr, sizeof(attr));
    }
    ```

- flags 인자는 다음 중 하나로 지정해야 한다.
  - `BPF_ANY`: 새 항목을 생성하거나 기존 항목을 갱신한다.
  - `BPF_NOEXIST`: 존재하지 않을 때 새 항목을 생성하기만 한다.
  - `BPF_EXIST`: 기존 항목을 갱신한다.

## `BPF_MAP_DELETE_ELEM`

- `BPF_MAP_DELETE_ELEM` 명령은 파일 디스크립터 fd가 가리키는 맵에서 키가 key인 항목을 삭제한다.

    ```c
    int
    bpf_delete_elem(int fd, const void *key)
    {
        union bpf_attr attr = {
            .map_fd = fd,
            .key    = ptr_to_u64(key),
        };

        return bpf(BPF_MAP_DELETE_ELEM, &attr, sizeof(attr));
    }
    ```

- 성공 시 0을 반환한다. 항목을 찾지 못하면 -1을 반환하며 errno를 ENOENT로 설정한다.

## `BPF_MAP_GET_NEXT_KEY`

- `BPF_MAP_GET_NEXT_KEY` 명령은 파일 디스크립터 fd가 가리키는 맵에서 key로 항목을 찾아서 그 다음 항목의 키를 `next_key` 포인터가 가리키게 설정한다.
- 이 시스템 콜을 사용해서 맵의 항목 전체를 순회할 수 있다.

    ```c
    int
    bpf_get_next_key(int fd, const void *key, void *next_key)
    {
        union bpf_attr attr = {
            .map_fd   = fd,
            .key      = ptr_to_u64(key),
            .next_key = ptr_to_u64(next_key),
        };

        return bpf(BPF_MAP_GET_NEXT_KEY, &attr, sizeof(attr));
    }
    ```
- key를 찾으면 0을 반환하며 다음 항목의 키를 `next_key` 포인터가 가리키게 설정한다. 
- key를 찾지 못하면 동작이 0을 반환하고 첫 번째 항목의 키를 `next_key` 포인터가 가리키게 설정한다. 
- key가 마지막 항목이면 -1을 반환하며 errno를 `ENOENT`로 설정한다. 

## `close(map_fd)`

- 파일 디스크립터 fd가 가리키는 맵을 삭제한다. 
- 맵을 생성한 사용자 공간 프로그램이 종료할 때 모든 맵들이 자동으로 삭제된다. (하지만 NOTES를 보라.)

# eBPF 프로그램 관련 시스템 콜

## `BPF_PROG_LOAD`

- `BPF_PROG_LOAD` 명령을 사용해 eBPF 프로그램을 커널로 적재할 수 있다. 이 명령의 반환 값은 eBPF 프로그램에 연결된 새 파일 디스크립터이다.

- `BPF_PROG_LOAD`가 반환한 파일 디스크립터로 `close()`를 호출하면 eBPF 프로그램을 제거할 수 있다.

    ```c
    char bpf_log_buf[LOG_BUF_SIZE];

    int
    bpf_prog_load(enum bpf_prog_type type,
                const struct bpf_insn *insns, int insn_cnt,
                const char *license)
    {
        union bpf_attr attr = {
            .prog_type = type,
            .insns     = ptr_to_u64(insns),
            .insn_cnt  = insn_cnt,
            .license   = ptr_to_u64(license),
            .log_buf   = ptr_to_u64(bpf_log_buf),
            .log_size  = LOG_BUF_SIZE,
            .log_level = 1,
        };

        return bpf(BPF_PROG_LOAD, &attr, sizeof(attr));
    }
    ```

- bpf_attr의 각 필드는 아래와 같은 의미이다.
  - `insns`는 struct bpf_insn 인스트럭션의 배열이다.
  - `insn_cnt`는 insns가 가리키는 프로그램 인스트럭션의 갯수이다.
  - `license`는 라이선스 문자열이며, gpl_only로 표시된 헬퍼 함수들을 호출하려면 GPL 호환이어야 한다. (라이선스 규칙이 커널 모듈과 같으므로 "Dual BSD/GPL" 같은 이중 라이선스를 쓸 수도 있다.)
  - `log_buf`는 호출자가 할당한 버퍼에 대한 포인터이며 커널 내 검증기가 여기에 검증 로그를 저장할 수 있다. 그 로그는 여러 행의 문자열이며 프로그램 작성자가 이를 확인하여 검증기가 어떻게 그 eBPF 프로그램이 안전하지 않다는 결론에 도달했는지 알 수 있다. 검증기가 발전함에 따라 출력 형식이 언제든 바뀔 수 있다.
  - `log_size`는 `log_buf`가 가리키는 버퍼의 크기다. 버퍼 크기가 검증기 메시지를 모두 담기에 충분하지 않으면 -1을 반환하고 errno를 ENOSPC로 설정한다.
  - `log_level`은 로그 단계를 뜻한다. 0 값은 검증기가 로그를 제공하지 않는다는 뜻이다. 이 경우 `log_buf`가 NULL 포인터인 동시에 `log_size`가 0이어야 한다.

- prog_type은 사용 가능한 프로그램 종류들 중 하나이다.

    ```c
    // /usr/include/linux/bpf.h
    enum bpf_prog_type {
        BPF_PROG_TYPE_UNSPEC,        /* 0은 유효하지 않은
                                        프로그램 종류로 예약 */
        BPF_PROG_TYPE_SOCKET_FILTER,
        BPF_PROG_TYPE_KPROBE,
        BPF_PROG_TYPE_SCHED_CLS,
        BPF_PROG_TYPE_SCHED_ACT,
        BPF_PROG_TYPE_TRACEPOINT,
        BPF_PROG_TYPE_XDP,
        BPF_PROG_TYPE_PERF_EVENT,
        BPF_PROG_TYPE_CGROUP_SKB,
        BPF_PROG_TYPE_CGROUP_SOCK,
        BPF_PROG_TYPE_LWT_IN,
        BPF_PROG_TYPE_LWT_OUT,
        BPF_PROG_TYPE_LWT_XMIT,
        BPF_PROG_TYPE_SOCK_OPS,
        BPF_PROG_TYPE_SK_SKB,
        BPF_PROG_TYPE_CGROUP_DEVICE,
        BPF_PROG_TYPE_SK_MSG,
        BPF_PROG_TYPE_RAW_TRACEPOINT,
        BPF_PROG_TYPE_CGROUP_SOCK_ADDR,
        BPF_PROG_TYPE_LWT_SEG6LOCAL,
        BPF_PROG_TYPE_LIRC_MODE2,
        BPF_PROG_TYPE_SK_REUSEPORT,
        BPF_PROG_TYPE_FLOW_DISSECTOR,
    };
    ```

---
참고
- https://man7.org/linux/man-pages/man2/bpf.2.html
- https://docs.kernel.org/userspace-api/ebpf/syscall.html