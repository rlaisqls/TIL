
- `SEC()`은 [ELF](./ELF.md) Section을 정의하는 매크로이다.

- `/`로 접두사를 구분하기도 한다. (e.g. `kprobe/slub_flush`)

### eBPF Section

- `license`
  
    ```c
    SEC("license") = "Dual MIT/GPL";
    ```

    프로그램에서 특정 BPF helper를 특정하여 사용하려면 GPL 호환 라이선스 하에 라이선스를 선언해야한다. BPF 프로그램의 라이선스는 커널 모듈 라이선스와 동일한 규칙을 따른다. ([라이선스 목록 참고](https://docs.kernel.org/process/license-rules.html#id1))


- `.map`

    `.maps` 섹션을 정의하면 libbpf가 해당 섹션을 토대로 BTF 타입을 정의한다.
  
    ```c
    struct {
    ...
    } map_keys SEC(".maps");
    ```

### Program Sections

그 외 다양한 프로그램들에서 섹션 정보를 활용한다.

| Section (Prefix)     | [ProgramType](https://github.com/torvalds/linux/blob/70293240c5ce675a67bfc48f419b093023b862b3/include/uapi/linux/perf_event.h#L838)    | AttachType                         | AttachFlags          |
|----------------------|----------------|------------------------------------|----------------------|
| socket               | SocketFilter   |                                    |                      |
| sk_reuseport/migrate| SkReuseport    | AttachSkReuseportSelectOrMigrate   |                      |
| sk_reuseport        | SkReuseport    | AttachSkReuseportSelect            |                      |
| kprobe/              | Kprobe         |                                    |                      |
| uprobe/              | Kprobe         |                                    |                      |
| kretprobe/           | Kprobe         |                                    |                      |
| uretprobe/           | Kprobe         |                                    |                      |
| tc                   | SchedCLS       |                                    |                      |
| classifier           | SchedCLS       |                                    |                      |
| action               | SchedACT       |                                    |                      |
| tracepoint/          | TracePoint     |                                    |                      |
| tp/                  | TracePoint     |                                    |                      |
| raw_tracepoint/      | RawTracepoint  |                                    |                      |
| raw_tp/              | RawTracepoint  |                                    |                      |
| raw_tracepoint.w/    | RawTracepointWritable|                                |                      |
| raw_tp.w/            | RawTracepointWritable|                                |                      |
| tp_btf/              | Tracing        | AttachTraceRawTp                  |                      |
| fentry/              | Tracing        | AttachTraceFEntry                 |                      |
| fmod_ret/            | Tracing        | AttachModifyReturn                | BPF_F_SLEEPABLE      |
| fexit/               | Tracing        | AttachTraceFExit                  |                      |
| fentry.s/            | Tracing        | AttachTraceFEntry                 | BPF_F_SLEEPABLE      |
| fmod_ret.s/          | Tracing        | AttachModifyReturn                | BPF_F_SLEEPABLE      |
| fexit.s/             | Tracing        | AttachTraceFExit                  | BPF_F_SLEEPABLE      |
| freplace/            | Extension      |                                    |                      |
| lsm/                 | LSM            | AttachLSMMac                      |                      |
| lsm.s/               | LSM            | AttachLSMMac                      | BPF_F_SLEEPABLE      |
| iter/                | Tracing        | AttachTraceIter                   |                      |
| iter.s/              | Tracing        | AttachTraceIter                   | BPF_F_SLEEPABLE      |
| syscall              | Syscall        |                                    |                      |
| xdp.frags_devmap/    | XDP            | AttachXDPDevMap                   | BPF_F_XDP_HAS_FRAGS  |
| xdp_devmap/          | XDP            | AttachXDPDevMap                   |                      |
| xdp.frags_cpumap/    | XDP            | AttachXDPCPUMap                   | BPF_F_XDP_HAS_FRAGS  |
| xdp_cpumap/          | XDP            | AttachXDPCPUMap                   |                      |
| xdp.frags            | XDP            |                                    | BPF_F_XDP_HAS_FRAGS  |
| xdp                  | XDP            |                                    |                      |
| perf_event           | PerfEvent      |                                    |                      |
| lwt_in               | LWTIn          |                                    |                      |
| lwt_out              | LWTOut         |                                    |                      |
| lwt_xmit             | LWTXmit        |                                    |                      |
| lwt_seg6local        | LWTSeg6Local   |                                    |                      |
| cgroup_skb/ingress  | CGroupSKB      | AttachCGroupInetIngress           |                      |
| cgroup_skb/egress   | CGroupSKB      | AttachCGroupInetEgress            |                      |
| cgroup/skb           | CGroupSKB      |                                    |                      |
| cgroup/sock_create   | CGroupSock     | AttachCGroupInetSockCreate        |                      |
| cgroup/sock_release  | CGroupSock     | AttachCgroupInetSockRelease       |                      |
| cgroup/sock          | CGroupSock     | AttachCGroupInetSockCreate        |                      |
| cgroup/post_bind4    | CGroupSock     | AttachCGroupInet4PostBind         |                      |
| cgroup/post_bind6    | CGroupSock     | AttachCGroupInet6PostBind         |                      |
| cgroup/dev           | CGroupDevice   | AttachCGroupDevice                |                      |
| sockops              | SockOps        | AttachCGroupSockOps               |                      |
| sk_skb/stream_parser| SkSKB          | AttachSkSKBStreamParser           |                      |
| sk_skb/stream_verdict| SkSKB          | AttachSkSKBStreamVerdict          |                      |
| sk_skb               | SkSKB          |                                    |                      |
| sk_msg               | SkMsg          | AttachSkMsgVerdict                |                      |
| lirc_mode2           | LircMode2      | AttachLircMode2                   |                      |
| flow_dissector       | FlowDissector  | AttachFlowDissector               |                      |
| cgroup/bind4         | CGroupSockAddr| AttachCGroupInet4Bind             |                      |
| cgroup/bind6         | CGroupSockAddr| AttachCGroupInet6Bind             |                      |
| cgroup/connect4      | CGroupSockAddr| AttachCGroupInet4Connect          |                      |
| cgroup/connect6      | CGroupSockAddr| AttachCGroupInet6Connect          |                      |
| cgroup/sendmsg4      | CGroupSockAddr| AttachCGroupUDP4Sendmsg           |                      |
| cgroup/sendmsg6      | CGroupSockAddr| AttachCGroupUDP6Sendmsg           |                      |
| cgroup/recvmsg4      | CGroupSockAddr| AttachCGroupUDP4Recvmsg           |                      |
| cgroup/recvmsg6      | CGroupSockAddr| AttachCGroupUDP6Recvmsg           |                      |
| cgroup/getpeername4  | CGroupSockAddr| AttachCgroupInet4GetPeername      |                      |
| cgroup/getpeername6  | CGroupSockAddr| AttachCgroupInet6GetPeername      |                      |
| cgroup/getsockname4  | CGroupSockAddr| AttachCgroupInet4GetSockname      |                      |
| cgroup/getsockname6  | CGroupSockAddr| AttachCgroupInet6GetSockname      |                      |
| cgroup/sysctl        | CGroupSysctl  | AttachCGroupSysctl                |                      |
| cgroup/getsockopt    | CGroupSockopt | AttachCGroupGetsockopt            |                      |
| cgroup/setsockopt    | CGroupSockopt | AttachCGroupSetsockopt            |                      |
| struct_ops+          | StructOps      |                                    |                      |
| sk_lookup/           | SkLookup       | AttachSkLookup                    |                      |
| seccomp              | SocketFilter   |                                    |                      |
| kprobe.multi         | Kprobe         | AttachTraceKprobeMulti            |                      |
| kretprobe.multi      | Kprobe        

---
참고
- https://stackoverflow.com/questions/67553794/what-is-variable-attribute-sec-means
- https://ebpf-go.dev/concepts/section-naming/#program-sections