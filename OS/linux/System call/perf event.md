```c
    #include <linux/perf_event.h>    /* Definition of PERF_* constants */
    #include <linux/hw_breakpoint.h> /* Definition of HW_* constants */
    #include <sys/syscall.h>         /* Definition of SYS_* constants */
    #include <unistd.h>

    int syscall(SYS_perf_event_open, struct perf_event_attr *attr,
     pid_t pid, int cpu, int group_fd, unsigned long flags);
```

- `perf_event_open`은 성능 모니터링을 설정하기 위한 시스템 콜이다.

- `perf_event_open()`는 성능 정보를 측정할 수 있는 파일 디스크립터(FD)를 반환한다. 각 FD는 측정되는 하나의 이벤트를 의미한다. 

- 각 이벤트는 `ioctl(2)`와 `prctl(2)`를 통해 활성화, 비활성화될 수 있다. 이벤트가 비활성화되면 측정을 멈추지만 카운트 값은 그대로 유지한다.

- 이벤트는 카운팅(counting) 타입과 샘플링(sampled) 타입 두 형태로 제공된다.
  - **카운팅 이벤트**는 발생하는 이벤트의 총 수를 세기 위해 사용된다. 카운팅 이벤트 결과는 일반적으로 `read(2)` 호출로 수집된다.
  - 샘플링 이벤트는 측정값을 주기적으로 버퍼에 기록하고, `mmap(2)`를 통해 버퍼에 액세스할 수 있다.

## Arguments

### pid와 cpu

- pid 인자로 측정할 프로세스를 지정할 수 있다.
    - `pid == 0`: 현재 프로세스를 측정
    - `pid > 0`: 해당 pid의 프로세스를 측정
    - `pid == -1`: 모든 프로세스 측정<br>
        `CAP_PERFMON`, `CAP_SYS_ADMIN` 권한을 가지고 있거나 `/proc/sys/kernel/perf_event_paranoid` 값이 1 이하인 경우에만 실행할 수 있다.
- cpu 인자로 측정할 CPU를 지정할 수 있다.
    - `cpu >= 0`: 지정된 CPU를 측정
    - `cpu == -1`: 모든 CPU에서 이벤트 측정
- pid와 cpu 인자 두 개가 모두 -1인 경우 에러가 발생한다.

### group_fd

- 이벤트 그룹을 생성할 수 있도록 하는 인자이다.
- 이벤트 그룹에서는 하나의 이벤트가 그룹의 리더가 된다. roup_fd를 -1로 지정해서 리더를 먼저 생성할 수 있고, 나머지 그룹 구성원을 생성할 때는 그룹 리더의 fd를 `group_fd`로 지정한다. (단일 이벤트는 멤버가 1명뿐인 그룹으로 간주된다.) 
- 이벤트 그룹은 CPU에 하나의 단위로 스케줄링된다. 멤버 이벤트의 값이 동일한 명령어에 대한 이벤트를 계산했기 때문에 서로 의미 있게 비교, 추가, 계산할 수 있다는 것을 의미한다.

### flags 

- flag 인자는 다음 중 하나의 값을 가진다.

- `PERF_FLAG_FD_CLOEXEC`<br>
    이 flag는 생성된 이벤트 FD가 [execve(2)](https://man7.org/linux/man-pages/man2/execve.2.html)를 통해 닫히도록 한다. (이걸 close-on-exec라고 부른다.) [fcntl(2)](https://man7.org/linux/man-pages/man2/fcntl.2.html)로도 설정할 수 있지만, 다른 스레드가 `fork(2)`와 ` execve(2)`를 호출해서 생길 수 있는 경합 가능성을 피하기 위해 유용하다.

- `PERF_FLAG_FD_NO_GROUP`<br>
    이 flag는 `group_fd` 인자를 무시하도록 한다. 

- `PERF_FLAG_FD_OUTPUT` (Linux 2.6.35부터 에러 발생)<br>
    이벤트 수집 결과가 `group_fd`에 지정된 이벤트의 mmap 버퍼에 같이 저장되도록 한다.

- `PERF_FLAG_PID_CGROUP` (Linux 2.6.39부터 사용 가능)<br>
  컨테이너별 시스템 전역 모니터링을 활성화한다. 이 모드에서 이벤트는 스레드가 지정된 컨테이너(cgroup)에 속할 경우에만 측정된다. <br>
    cgroup은 cgroupfs 파일 시스템의 디렉터리에서 열린 FD를 통해 식별된다. 예를 들어 모니터링할 컨트롤 그룹이 test이고, cgroupfs가 `/dev/cgroup`에 마운트되어 있다면 `/dev/cgroup/test`에서 열린 FD를 pid 매개변수로 전달해야 한다.<br>
    cgroup 모니터링은 시스템 전체 이벤트에만 사용할 수 있으며 추가 권한이 필요할 수 있다.

### `perf_event_attr`

`perf_event_attr` 구조체로 되어있는 인자는 생성될 이벤트에 대한 구체적인 정보를 전달하기 위해 사용한다.

```c
struct perf_event_attr {
    __u32 type;                 /* Type of event */
    __u32 size;                 /* Size of attribute structure */
    __u64 config;               /* Type-specific configuration */

    union {
        __u64 sample_period;    /* Period of sampling */
        __u64 sample_freq;      /* Frequency of sampling */
    };

    __u64 sample_type;  /* Specifies values included in sample */
    __u64 read_format;  /* Specifies values returned in read */

    __u64 disabled       : 1,   /* off by default */
          inherit        : 1,   /* children inherit it */
          pinned         : 1,   /* must always be on PMU */
          exclusive      : 1,   /* only group on PMU */
          exclude_user   : 1,   /* don't count user */
          exclude_kernel : 1,   /* don't count kernel */
          exclude_hv     : 1,   /* don't count hypervisor */
          exclude_idle   : 1,   /* don't count when idle */
          mmap           : 1,   /* include mmap data */
          comm           : 1,   /* include comm data */
          freq           : 1,   /* use freq, not period */
          inherit_stat   : 1,   /* per task counts */
          enable_on_exec : 1,   /* next exec enables */
          task           : 1,   /* trace fork/exit */
          watermark      : 1,   /* wakeup_watermark */
          precise_ip     : 2,   /* skid constraint */
          mmap_data      : 1,   /* non-exec mmap data */
          sample_id_all  : 1,   /* sample_type all events */
          exclude_host   : 1,   /* don't count in host */
          exclude_guest  : 1,   /* don't count in guest */
          exclude_callchain_kernel : 1, /* exclude kernel callchains */
          exclude_callchain_user   : 1, /* exclude user callchains */
          mmap2          :  1,  /* include mmap with inode data */
          comm_exec      :  1,  /* flag comm events that are due to exec */
          use_clockid    :  1,  /* use clockid for time fields */
          context_switch :  1,  /* context switch data */
          write_backward :  1,  /* Write ring buffer from end to beginning */
          namespaces     :  1,  /* include namespaces data */
          ksymbol        :  1,  /* include ksymbol events */
          bpf_event      :  1,  /* include bpf events */
          aux_output     :  1,  /* generate AUX records instead of events */
          cgroup         :  1,  /* include cgroup events */
          text_poke      :  1,  /* include text poke events */
          build_id       :  1,  /* use build id in mmap2 events */
          inherit_thread :  1,  /* children only inherit */
                                /* if cloned with CLONE_THREAD */
          remove_on_exec :  1,  /* event is removed from task on exec */
          sigtrap        :  1,  /* send synchronous SIGTRAP on event */

          __reserved_1   : 26;

    union {
        __u32 wakeup_events;    /* wakeup every n events */
        __u32 wakeup_watermark; /* bytes before wakeup */
    };

    __u32     bp_type;          /* breakpoint type */

    union {
        __u64 bp_addr;          /* breakpoint address */
        __u64 kprobe_func;      /* for perf_kprobe */
        __u64 uprobe_path;      /* for perf_uprobe */
        __u64 config1;          /* extension of config */
    };

    union {
        __u64 bp_len;           /* breakpoint length */
        __u64 kprobe_addr;      /* with kprobe_func == NULL */
        __u64 probe_offset;     /* for perf_[k,u]probe */
        __u64 config2;          /* extension of config1 */
    };
    __u64 branch_sample_type;   /* enum perf_branch_sample_type */
    __u64 sample_regs_user;     /* user regs to dump on samples */
    __u32 sample_stack_user;    /* size of stack to dump on
                                   samples */
    __s32 clockid;              /* clock to use for time fields */
    __u64 sample_regs_intr;     /* regs to dump on samples */
    __u32 aux_watermark;        /* aux bytes before wakeup */
    __u16 sample_max_stack;     /* max frames in callchain */
    __u16 __reserved_2;         /* align to u64 */
    __u32 aux_sample_size;      /* max aux sample size */
    __u32 __reserved_3;         /* align to u64 */
    __u64 sig_data;             /* user data for sigtrap */

};
```

각 필드에 대한 자세한 설명은 다음과 같다.

- `type`: 추적할 이벤트의 타입을 나타낸다. 상세한 이벤트는 `config` 인자의 값으로 결정된다. 타입은 아래 값 중 하나이다.
  - `PERF_TYPE_HARDWARE`: 커널에서 제공하는 제네럴한 하드웨어 이벤트 중 하나를 나타낸다.
  - `PERF_TYPE_SOFTWARE`: kernel의 software로 정의된 이벤트를 나타낸다.
  - `PERF_TYPE_TRACEPOINT`: kernel의 tracepoint 인프라에서 제공되는 tracepoint를 나타낸다.
  - `PERF_TYPE_HW_CACHE`: 하드웨어 캐시 이벤트를 나타낸다. config 필드 정의에서 설명되는 특수 인코딩을 가지고 있다.
  - `PERF_TYPE_RAW`: config 필드에서 명시되는 raw 구현을 나타낸다.
  - `PERF_TYPE_BREAKPOINT`: CPU로부터 제공되는 hardware breakpoint를 나타낸다. breakpoint의 주소로부터 읽기/쓰기 뿐만 아니라 명령어 주소 실행 또한 가능하다.
   - `kprobe`과 `uprobe`: 이 두가지의 동적 PMU는 `perf_event_open`로 생성된 FD에 대해서 kprobe/uprobe를 생성하고 등록한다.

- `size`: perf_event_attr 구조체의 크기 값을 넣어주면 된다. `sizeof(struct perf_event_attr)`를 사용하여 구할 수 있다.

- `config`: 타입 필드와 함께 원하는 이벤트를 지정한다. config1, config2 필드는 이벤트를 지정하기 위해 64비트만으로는 충분하지 않은 경우 사용된다. 이 필드들의 인코딩은 이벤트에 따라 다르다. 

- `kprobe_func`, `uprobe_path`, `kprobe_addr`, `probe_offset`: kprobe/uprobe 타입을 쓰는 경우 그에 대한 

- `sample_period`, `sample_freq`: 샘플링 주기를 지정하기 위해 사용한다. 샘플링 기간 또는 주기를 지정할 수 있다.

- `sample_type`: 샘플링 할 데이터의 타입을 지정한다.<br>
    PERF_SAMPLE_IP, PERF_SAMPLE_TID, PERF_SAMPLE_TIME, PERF_SAMPLE_ADDR, PERF_SAMPLE_READ, PERF_SAMPLE_CALLCHAIN, PERF_SAMPLE_ID, PERF_SAMPLE_CPU, PERF_SAMPLE_STACK_USER, PERF_SAMPLE_PHYS_ADDR 등이 있다.

- `inherit`: 해당 작업의 하위 작업의 이벤트도 함께 카운트할지 여부를 지정한다. 기존 하위 작업에는 적용되지 않고 새로운 하위 작업에만 적용된다.

- `pinned`: 카운터를 한 CPU에서 실행되도록 할지 여부를 지정한다. 하드웨어 카운터, 그룹 리더에만 적용된다. 카운터가 고정된 CPU에 놓일 수 없는 경우(예: 하드웨어 카운터가 충분하지 않거나 다른 이벤트와의 충돌이 있는 경우), 카운터는 '에러' 상태가 되어 파일의 끝(즉, read(2)가 0을 반환)을 반환하며, 나중에 카운터가 활성화되거나 비활성화될 때까지 이 상태가 유지된다.
  
- `exclusive`: 이 카운터 그룹이 CPU에 있을 때 CPU의 카운터를 사용하는 유일한 그룹이도록 강제할지 여부를 지정한다. 이 기능을 사용하면 다른 하드웨어 카운터를 방해하지 않도록 도와주는 PMU 기능을 사용하도록 할 수 있다.

---
참고
- https://man7.org/linux/man-pages/man2/perf_event_open.2.html#top_of_page
- https://github.com/torvalds/linux/blob/master/include/linux/syscalls.h#L845