# BPF 프로그램 타입

BPF 프로그램의 종류는 다양하다. BPF 프로그램은 이벤트를 중심으로 작성되는 데, 프로그램 타입에 따라 사용할 수 있는 이벤트가 제한적이므로 작성하고자 하는 프로그램이 어떤 범주에 속하는지 잘 알고 있어야 한다.

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
|트레이싱 관련|`BPF_PROG_TYPE_KPROBE`<br>`BPF_PROG_TYPE_TRACEPOINT`<br>`BPF_PROG_TYPE_RERF_EVENT`|
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
      // 바인딩을 위한 ID를 발급받는다.
      $ echo 'p:myprobe tcp_retransmit_skb' > /sys/kernel/debug/tracing/kprobe_events
      $ cat /sys/kernel/debug/tracing/events/kprobes/myprobe/id
      1965

      // 마운트 정보를 확인한다.
      $ mount | grep tracing
      tracefs on /sys/kernel/debug/tracing type tracefs (rw, nosuid,nodev,noexec,relatime)
      ```
    
    - 이렇게 발급받은 ID는 BPF 프로그램을 로드할 때 사용된다.

    

3. 어떤 컨텍스트가 제공되는가?