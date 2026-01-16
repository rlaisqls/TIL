
BPF 프로그램의 종류는 다양하다. BPF 프로그램은 이벤트를 중심으로 작성되는데, 프로그램 타입에 따라 사용할 수 있는 이벤트가 제한적이므로 작성하고자 하는 프로그램이 어떤 범주에 속하는지 잘 알고 있어야 한다.

작성한 프로그램은 해당하는 이벤트가 발생할 때 실행되고, 실행 시점에 프로그램에서 필요로 하는 정보가 컨텍스트로 제공될 것이다.

### 프로그램 타입

[커널 내 소스](https://github.com/torvalds/linux/blob/v5.8/include/uapi/linux/bpf.h#L161)에는 커널에서 지원하는 BPF 프로그램의 타입 전체가 나열되어 있다.

```c
/* Note that tracing related programs such as
 * BPF_PROG_TYPE_{KPROBE,TRACEPOINT,PERF_EVENT,RAW_TRACEPOINT}
 * are not subject to a stable API since kernel internal data
 * structures can change from release to release and may
 * therefore break existing tracing BPF programs. Tracing BPF
 * programs correspond to /a/ specific kernel which is to be
 * analyzed, and not /a/ specific kernel /and/ all future ones.
 */
enum bpf_prog_type {
	BPF_PROG_TYPE_UNSPEC,
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
	BPF_PROG_TYPE_CGROUP_SYSCTL,
	BPF_PROG_TYPE_RAW_TRACEPOINT_WRITABLE,
	BPF_PROG_TYPE_CGROUP_SOCKOPT,
	BPF_PROG_TYPE_TRACING,
	BPF_PROG_TYPE_STRUCT_OPS,
	BPF_PROG_TYPE_EXT,
	BPF_PROG_TYPE_LSM,
};
```

아래 표와 같이 이 프로그램 타입들을 범주별로 묶을 수 있다.

|범주|프로그램 타입|
|-|-|
|소켓 관련|`SOCKET_FILTER`<br>`SK_SKB`<br>`SOCK_OPS`|
|TC 관련|`BPF_PROG_SCHED_CLS`<br>`BPF_PROG_SCHED_ACT`|
|XDP 관련|`BPF_PROG_TYPE_XDP`|
|트레이싱 관련|`BPF_PROG_TYPE_KPROBE`<br>`BPF_PROG_TYPE_TRACEPOINT`<br>`BPF_PROG_TYPE_PERF_EVENT`|
|CGROUP 관련|`BPF_PROG_TYPE_CGROUP_SKB`<br>`BPF_PROG_TYPE_CGROUP_SOCK`<br>`BPF_PROG_TYPE_CGROUP_DEVICE`|
|터널링 관련|`BPF_PROG_TYPE_LWT_IN`<br>`BPF_PROG_TYPE_LWT_OUT`<br>`BPF_PROG_TYPE_LWT_XMIT`<br>`BPF_PROG_TYPE_LWT_SEGGLOCAL`|

### 타입별 특징

각 타입별로 신경써야 하는 부분은 다음 3가지이다.

1. 어떤 역할이며, 언제 프로그램이 실행되는가?
2. 어떻게 커널에 로딩하는가?
3. 어떤 컨텍스트가 제공되는가?

BPF_PROG_TYPE_KPROBE 타입의 프로그램을 예로 들어 살펴보자.

1. 어떤 역할이며, 언제 프로그램이 실행되는가?
   - `BPF_PROG_TYPE_KPROBE`는 이름 그대로 [`kprobe`](https://www.kernel.org/doc/Documentation/trace/kprobetrace.txt)를 활용하는 프로그램 타입이다.
   - `kprobe`는 커널의 함수 진입점에 바인딩되는 이벤트로서 커널 내 특정 함수 호출 정보를 제공할 수 있다.
  
2. 어떻게 커널에 로딩하는가?
   
   - `kprobe`에 관련된 인터페이스는 sysfs 밑의 tracef애 있다.
   - tracefs는 트레이싱을 위한 특별한 파일 시스템으로, 바인딩을 위한 ID를 tracefs를 통해 발급받을 수 있다. 보통은 debugfs 아래에 마운트되어 있다.
      
		```bash
		// 마운트 정보를 확인한다.
		$ mount | grep tracing
		tracefs on /sys/kernel/debug/tracing type tracefs (rw, nosuid,nodev,noexec,relatime)

		// 바인딩을 위한 ID를 발급받는다.
		$ echo 'p:myprobe tcp_retransmit_skb' > /sys/kernel/debug/tracing/kprobe_events
		$ cat /sys/kernel/debug/tracing/events/kprobes/myprobe/id
		1965
		```
    
    - 이렇게 발급받은 ID는 BPF 프로그램을 로드할 때 `sys_perf_event_open()`에 해당 id를 찾아서 전달된다.

		```c
		static int load_and_attach(const char *event, struct bpf_insn *prog, int size) {
			...
			if (is_kprobe || is_kretprobe) {
				...
				strcpy(buf, DEBUGFS);
				strcat(buf, "events/kprobes/");
				strcat(buf, event_prefix);
				strcat(buf, event);
				strcat(buf, "/id");
			}
			...
			buf[err] = 0;
			id = atoi(buf);
			attr.config = id;

			efd = sys_perf_event_open(&attr, -1/*pid*/, 0/*cpu*/, -1/*group_fd*/, 0);
			...
		}
		```
	
	- BPF 바이너리는 이벤트가 바인딩되기 전에 커널로 먼저 로딩되어야 한다. `do_load_bpf_file()` 함수에서 주어진 경로의 ELF 바이너리를 읽어서 프로그램과 맵, 그리고 그외 ELF 섹션에 기술된 라이선스 및 버전 등을 추출한다.

		```c
		static int do_load_bpf_file(const char *path, fixup_map_cb fixup_map) {
			/* scan over all elf sections to get license and map info */
			for (i = 1; i < ehdr.e_shnum; i++) {

				if (get_sec(elf, i, &ehdr, &shname, &shdr, &data))
					continue;

				if (0) /* helpful for llvm debugging */
					printf("section %d:%s data %p size %zd link %d flags %d\n",
						i, shname, data->d_buf, data->d_size,
						shdr.sh_link, (int) shdr.sh_flags);

				if (strcmp(shname, "license") == 0) {
					processed_sec[i] = true;
					memcpy(license, data->d_buf, data->d_size);
				} else if (strcmp(shname, "version") == 0) {
					processed_sec[i] = true;
					if (data->d_size != sizeof(int)) {
						printf("invalid size of version section %zd\n",
							data->d_size);
						return 1;
					}
					memcpy(&kern_version, data->d_buf, sizeof(int));
				} else if (strcmp(shname, "maps") == 0) {
					int j;

					maps_shndx = i;
					data_maps = data;
					for (j = 0; j < MAX_MAPS; j++)
						map_data[j].fd = -1;
				} else if (shdr.sh_type == SHT_SYMTAB) {
					strtabidx = shdr.sh_link;
					symbols = data;
				}
			}
			...
			/* load programs */
			for (i = 1; i < ehdr.e_shnum; i++) {

				if (processed_sec[i])
					continue;

				if (get_sec(elf, i, &ehdr, &shname, &shdr, &data))
					continue;

				if (...) {
					ret = load_and_attach(shname, data->d_buf,
								data->d_size);
					if (ret != 0)
						goto done;
				}
			}
		}
		```

	- 필요한 정보를 처리하고 나면 `load_and_attach()`가 호출되며, 다음 코드 블럭에서 프로그램을 커널로 로딩한다.
	- `bpf_load_program()`은 bpf() 시스템 콜을 추상화해주는 `libbpf` 라이브러리에서 제공하는 함수이다.  

		```c
		static int do_load_bpf_file(const char *path, fixup_map_cb fixup_map) {
			...
			fd = bpf_load_program(prog_type, prog, insns_cnt, license, kern_version,
					bpf_log_buf, BPF_LOG_BUF_SIZE);
			...
		}
		```

3. 어떤 컨텍스트가 제공되는가?

   - 전달되는 컨텍스트는 `struct pt_regs *ctx`이다.
     - 이 구조체는 레지스터를 추상화한 구조체로서 이를 통해 함수 호출 시 전달되는 매개변수, 레지스터 상태, 함수 실행 전후의 컨텍스트 등을 확인할 수 있다.
  
		```c
		struct pt_regs {
			unsigned long pc;		/*   4 */
			unsigned long ps;		/*   8 */
			unsigned long depc;		/*  12 */
			unsigned long exccause;		/*  16 */
			unsigned long excvaddr;		/*  20 */
			unsigned long debugcause;	/*  24 */
			unsigned long wmask;		/*  28 */
			unsigned long lbeg;		/*  32 */
			unsigned long lend;		/*  36 */
			unsigned long lcount;		/*  40 */
			unsigned long sar;		/*  44 */
			unsigned long windowbase;	/*  48 */
			unsigned long windowstart;	/*  52 */
			unsigned long syscall;		/*  56 */
			unsigned long icountlevel;	/*  60 */
			unsigned long scompare1;	/*  64 */
			unsigned long threadptr;	/*  68 */

			/* Additional configurable registers that are used by the compiler. */
			xtregs_opt_t xtregs_opt;

			/* Make sure the areg field is 16 bytes aligned. */
			int align[0] __attribute__ ((aligned(16)));

			/* current register frame.
			* Note: The ESF for kernel exceptions ends after 16 registers!
			*/
			unsigned long areg[XCHAL_NUM_AREGS];
		};
		```


   - (BCC를 사용하면 구조체에서 정보를 가져오는 부분도 추상화되어 작동한다.)

---
참고
- https://github.com/torvalds/linux/blob/v5.8/samples/bpf/bpf_load.c
- https://github.com/torvalds/linux/blob/v5.8/include/uapi/linux/bpf.h#L161
- https://www.kernel.org/doc/Documentation/trace/kprobetrace.txt