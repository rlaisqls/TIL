

### `libbpf_register_prog_handler()`

```rust
LIBBPF_API int libbpf_register_prog_handler(const char *sec,
					    enum bpf_prog_type prog_type,
					    enum bpf_attach_type exp_attach_type,
					    const struct libbpf_prog_handler_opts *opts);
```

`libbpf_register_prog_handler()`는 커스텀 BPF 프로그램을 `SEC()` handler로 등록해준다.

모든 커스텀 handler(sec 파라미터가 NULL인 것은 제외)는 libbpf에서 정의하는 `SEC()` handler보다 전에 등록된다.

- 파라미터
  - `sec`: section의 prefix
    - "sec"과 같이 입력하면 `SEC("sec")`만 매치되고, "sec/"과 같이 입력하면 `SEC("abc/something")`처럼 하위 경로가 있는 핸들러와도 매치될 수 있다.
    - 이 값이 NULL이면 등록된 `SEC()` 핸들러와 일치하지 않는 모든 BPF 프로그램에 대해 등록된다.
  - `prog_type`: section에 속할 BPF 프로그램의 타입
  - `exp_attach_type`: 예상하는 bpf attach 타입
  - `opts`: 쿠키, 콜백 등 기타 옵션
- 반환값: handler의 ID, 이후 ID를 사용해 `libbpf_unregister_prog_handler()`로 등록 해제시킬 수 있다.

### `bpf_map_lookup_elem()`

`bpf_map_lookup_elem` 함수는 map에서 key에 연관된 항목을 찾는다.

```c
int bpf_map_lookup_elem(int fd, const void *key, void *value) {
	const size_t attr_sz = offsetofend(union bpf_attr, flags);
	union bpf_attr attr;
	int ret;

	memset(&attr, 0, attr_sz);
	attr.map_fd = fd;
	attr.key = ptr_to_u64(key);
	attr.value = ptr_to_u64(value);

	ret = sys_bpf(BPF_MAP_LOOKUP_ELEM, &attr, attr_sz);
	return libbpf_err_errno(ret);
}
```

### `bpf_map_update_elem()`


`bpf_map_update_elem` 함수는 map에서 key에 연관된 항목의 값을 추가하거나 업데이트한다.

정보를 찾았다면 key에 연관된 맵 값을 반환하고, 만약 찾지 못했다면 NULL을 반환한다.

가능한 flag는 아래와 같은 것들이 있다.

- `BPF_NOEXIST`: map에 key에 대한 항목이 존재해서는 안된다.
- `BPF_EXIST`: map에 이미 key에 대한 항목이 있어야 한다.
- `BPF_ANY`: key에 대한 항목의 존재 여부에 대한 조건이 없다.

`BPF_NOEXIST` 플래그 값은 `BPF_MAP_TYPE_ARRAY` 또는 `BPF_MAP_TYPE_PERCPU_ARRAY` 유형의 맵에 대해선 사용할 수 없다. 해당 타입의 맵은 요소가 항상 존재하기 때문에 오류를 반환할 것이다.

반환값은 성공 시 0이며, 실패할 경우 음수 오류 코드를 반환한다.

```c
int bpf_map_update_elem(int fd, const void *key, const void *value, __u64 flags) {
	const size_t attr_sz = offsetofend(union bpf_attr, flags);
	union bpf_attr attr;
	int ret;

	memset(&attr, 0, attr_sz);
	attr.map_fd = fd;
	attr.key = ptr_to_u64(key);
	attr.value = ptr_to_u64(value);
	attr.flags = flags;

	ret = sys_bpf(BPF_MAP_UPDATE_ELEM, &attr, attr_sz);
	return libbpf_err_errno(ret);
}
```

### `bpf_probe_read_kernel()`

- `unsafe_ptr`에서 `size` 바이트를 커널 공간 주소에서 안전하게 읽어서 데이터를 `dst`에 저장하려고 시도한다.
- 성공시 0을, 실패시 음수를 반환한다.

```c
long bpf_probe_read_kernel(void *dst, u32 size, const void *unsafe_ptr)
```

### `bpf_probe_read_user()`

- 유저 공간의 `unsafe_ptr`주소에서 `size` 바이트를 안전하게 읽어서 데이터를 `dst`에 저장한다.
- 성공시 0을, 실패시 음수를 반환한다.

```c
int bpf_probe_read_user(void *dst, int size, const void *src)
```

### `bpf_tail_call()`

- "테일 콜(tail call)"을 trigger하거나 다른 eBPF 프로그램으로 점프하기 위해 사용한다. 호출된 프로그램에서도 동일한 스택 프레임이 사용된다. (하지만 호출자의 스택 및 레지스터에 있는 값은 호출된 프로그램에서 접근할 수 없다). 

- 이를 활용해 프로그램 체이닝이 가능해지며, 이는 사용 가능한 eBPF 명령어의 최대 수를 늘리거나 조건부 블록에서 지정된 프로그램을 실행하기 위해 사용될 수 있다. 

- 보안상의 이유로 연속적인 Tail call 수에는 상한선이 있다. Tail call의 최대 갯수는 커널 내에서 **MAX_TAIL_CALL_CNT** 매크로로 정의된다. (user space에서 접근할 수 없음) 기본값은 33이다.

- helder를 호출하면 프로그램은 `prog_array_map`에서 **BPF_MAP_TYPE_PROG_ARRAY** 유형의 특별한 맵에 있는 index에 참조된 프로그램으로 점프를 시도하고 ctx를 전달한다.
- 성공시 0을, 실패시 음수를 반환한다.
  - 호출이 성공하면 커널은 즉시 새 프로그램의 첫 번째 명령어를 실행한다. 이는 함수 호출이 아니기에 이전 프로그램으로 돌아가지 않는다. 
  - 점프 대상 프로그램이 존재하지 않거나 (즉, `index`가 `prog_array_map`에 있는 항목 수를 초과할 때) 또는 이 체인의 프로그램에 대한 최대 Tail call 수에 도달하여 호출이 실패하는 경우 호출자의 이후 명령어를 계속 실행한다.

  
```c
long bpf_tail_call(void *ctx, struct bpf_map *prog_array_map, u32 index)
```

### `bpf_perf_event_output()`

```c
long bpf_perf_event_output(void *ctx, struct bpf_map *map, u64 flags, void *data, u64 size)
```

- `BPF_MAP_TYPE_PERF_EVENT_ARRAY` 유형의 맵에 raw data blob을 BPF 성능 이벤트로서 write한다. 이 성능 이벤트는 다음과 같은 특성을 가져야 한다:
  - sample_type: `PERF_SAMPLE_RAW`
  - type: `PERF_TYPE_SOFTWARE`
  - config: `PERF_COUNT_SW_BPF_OUTPUT`

- flag는 값을 넣을 맵 내의 인덱스를 나타내는 데 사용되며 `BPF_F_INDEX_MASK`와 마스크된다.   현재 CPU 코어의 인덱스를 사용해야 함을 나타내는 `BPF_F_CURRENT_CPU`로 설정하기도 한다.

- 이 함수로 작성한 값을 읽으려는 프로그램은 `perf_event_open()`을 호출하고 파일 디스크립터를 맵에 저장해야 한다. 이 작업은 eBPF 프로그램이 데이터를 전송하기 전에 수행되어야 한다. 

- Linux 커널 소스 트리의 [samples/bpf/trace_output_user.c](https://github.com/torvalds/linux/blob/928a87efa42302a23bb9554be081a28058495f22/samples/bpf/trace_output_user.c#L4) 파일에서 예시를 확인할 수 있다.

---
참고
- https://github.com/iovisor/bcc/blob/master/docs/reference_guide.md#10-bpf_probe_read_user
- https://github.com/libbpf/libbpf/blob/main/include/uapi/linux/bpf.h