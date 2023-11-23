# BPF(Berkeley Packet Filter)

- BPF는 1992년 패킷 분석 및 필터링을 위해 개발된 in-kernel virtual machine이다.
- BSD라는 OS에서 처음 도입했으며 리눅스에서도 이 개념을 빌려와서 서브시스템을 만들었다.
- in-kernel virtual machine이라고 함은 정말로 가상의 레지스터와 스택 등을 갖고 있으며 이를 바탕으로 코드를 실행한다는 뜻이다.

<img width="527" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/d8f58fa4-02eb-435f-bf40-0224df718f9d">

- 다양한 커널 및 애플리케이션 이벤트에서 작은 프로그램을 실행할 수 있는 방법을 제공한다.

### How BPF works

<img width="527" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/6a6f8fc9-6694-442c-90c1-06685aceb525">

- BPF 프로그램은 위의 코드처럼 커널 코드 내에 미리 정의된 훅이나 kprobe, uprobe, tracepoint를 사용해서 프로그램을 실행할 수 있다.
- 위의 그림은 간단한 예시로, execve 시스템 호출이 실행될 때마다 BPF 프로그램을 실행해서 새로운 프로세스가 어떻게 만들어지는지를 나타낸다.

### BPF 코드 컴파일 과정

<img height="272" src="https://github.com/rlaisqls/TIL/assets/81006587/a48bf8d5-181f-45b2-89b5-088650a01b1b"> <img height="272" src="https://github.com/rlaisqls/TIL/assets/81006587/7ef6deb1-bc42-4c54-b2ab-4585520034c5">

- BPF는 사용자측에서 가져온 코드를 커널에서 실행하기 때문에 안전성이 매우 중요하다. <br/> 시스템의 안정성을 해칠만한 코드인지 아닌지 검증하는 과정이 필요하다.
  - 무한 루프가 발생할 수 있기 때문에 반복문도 매우 제한적으로 지원한다.
- 모든 BPF 프로그램은 Verifier를 통과해야만 실행된다.

- 위 사진은 BPF 코드가 검증되고 컴파일되는 과정을 나타낸다.

1. C 코드에서 LLVM 중간 표현으로 번역
2. BPF 바이트코드로 다시 번역
3. 바이트코드를 Verifier로 검증
4. JIT 컴파일러로 컴파일

이 4가지 과정을 거치면 실행할 수 있는 상태가 된다.

### BPF의 장점

- BPF의 최대 장점은 커널을 새로 빌드할 필요 없이 바로 코드를 실행해볼 수 있다는 점이다.
  - 물론 애초에 커널의 기능을 바꿀 일이 있다면 소스를 고치는게 맞지만, **트레이싱을 하는 경우에는 필요할 때만 트레이싱 코드를 실행하고 작업이 끝나고 나면 다시 그 코드를 비활성화**해야 하는데 그럴때마다 매번 커널을 새로 빌드할 필요가 없어진다.

### BPF의 단점

- 자주 실행되는 함수를 트레이싱할 경우 오버헤드가 엄청나다.
- 인라인 함수를 트레이싱 하려면 매우 번거롭다.
- 사용자 공간 함수를 트레이싱 하는 경우에는 커널 공간을 들렀다가 가야 하므로 비효율적이다.
- 지원되는 구문이 제한적이다. (위에서 말한 반복문 처럼)
- 고정된 스택을 갖는다 (512바이트)

### eBPF: extended BPF

<img width="552" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/470c9829-a147-4d5e-9a52-b28a9ad4bec9">

eBPF는 확장 BPF라는 뜻이다. 기존의 BPF에서 사용하던 머신에서 더 나아가서 레지스터의 크기를 늘려주고 스택과 맵을 도입하는 등의 변화가 있었다. 

그래서 기존의 BPF를 cBPF (classic BPF)라고 부르고 새로운 BPF를 eBPF로 부르게 되었다.

### eBPF를 활용한 프로그램

- 초기 목표가 트레이싱을 효율적으로 하기 위함이기 때문에, eBPF를 사용한 다양한 트레이싱 툴이 있다. 

  <img width="327" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/d8f58fa4-02eb-435f-bf40-0224df718f9d">

- **Cilium**
  - Cilium은 eBPF 기반 네트워킹, 보안 및 observability를 제공하는 오픈 소스 프로젝트이다. 컨테이너 워크로드의 새로운 확장성, 보안 및 가시성 요구사항을 해결하기 위해 설계되었다. Service Mesh, Hubble, CNI 3가지 타입이 있다.
    
    <img height="222" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/1bffe60c-f398-4237-a61f-229c17853562">

    <img height="222" src="https://github.com/rlaisqls/TIL/assets/81006587/94da48b6-46c3-4955-885e-2d85d9392d3a">

- **Calico**
  - K8s cni로 사용할 수 있는 Pluggable eBPF 기반 네트워킹 및 보안 오픈소스이다. Calico Open Source는 컨테이너 및 Kubernetes 네트워크를 단순화, 확장 및 보안하기 위해 설계되었디.
  - Calico의 eBPF 데이터 플레인은 eBPF 프로그램의 성능, 속도 및 효율성을 활용하여 환경에 대한 네트워킹, 로드 밸런싱 및 커널 내 보안을 강화한다.

    <img height="222" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/46dcc883-63dc-4680-8477-281547a2ad60">

### man


```
     The Berkeley Packet Filter provides a raw interface to data link layers in a protocol independent
     fashion.  All packets on the network, even those destined for other hosts, are accessible through this
     mechanism.

     The packet filter appears as a character special device, /dev/bpf0, /dev/bpf1, etc.  After opening the
     device, the file descriptor must be bound to a specific network interface with the BIOCSETIF ioctl.  A
     given interface can be shared by multiple listeners, and the filter underlying each descriptor will see
     an identical packet stream.

     A separate device file is required for each minor device.  If a file is in use, the open will fail and
     errno will be set to EBUSY.

     Associated with each open instance of a bpf file is a user-settable packet filter.  Whenever a packet is
     received by an interface, all file descriptors listening on that interface apply their filter.  Each
     descriptor that accepts the packet receives its own copy.

     Reads from these files return the next group of packets that have matched the filter.  To improve
     performance, the buffer passed to read must be the same size as the buffers used internally by bpf.
     This size is returned by the BIOCGBLEN ioctl (see below), and can be set with BIOCSBLEN.  Note that an
     individual packet larger than this size is necessarily truncated.

     A packet can be sent out on the network by writing to a bpf file descriptor.  The writes are unbuffered,
     meaning only one packet can be processed per write.  Currently, only writes to Ethernets and SLIP links
     are supported.

     When the last minor device is opened, an additional minor device is created on demand.  The maximum
     number of devices that can be created is controlled by the sysctl debug.bpf_maxdevices.
```

<img width="747" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/ce7a666b-4df6-4c32-b0b7-92aa84402faa">

```bash
$ sudo strace -e bpf,ioctl,perf_event_open bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'
bpf(BPF_MAP_CREATE, {map_type=BPF_MAP_TYPE_ARRAY, key_size=4, value_size=4, max_entries=1, map_flags=0, inner_map_fd=0, map_name="", map_ifindex=0, btf_fd=0, btf_key_type_id=0, btf_value_type_id=0, btf_vmlinux_value_type_id=0, map_extra=0}, 128) = 3
Attaching 1 probe...
bpf(BPF_MAP_CREATE, {map_type=BPF_MAP_TYPE_PERCPU_HASH, key_size=16, value_size=8, max_entries=4096, map_flags=0, inner_map_fd=0, map_name="AT_", map_ifindex=0, btf_fd=0, btf_key_type_id=0, btf_value_type_id=0, btf_vmlinux_value_type_id=0, map_extra=0}, 128) = 3
bpf(BPF_MAP_CREATE, {map_type=BPF_MAP_TYPE_PERF_EVENT_ARRAY, key_size=4, value_size=4, max_entries=2, map_flags=0, inner_map_fd=0, map_name="printf", map_ifindex=0, btf_fd=0, btf_key_type_id=0, btf_value_type_id=0, btf_vmlinux_value_type_id=0, map_extra=0}, 128) = 4
perf_event_open({type=PERF_TYPE_SOFTWARE, size=0 /* PERF_ATTR_SIZE_??? */, config=PERF_COUNT_SW_BPF_OUTPUT, sample_period=1, sample_type=PERF_SAMPLE_RAW, read_format=0, precise_ip=0 /* arbitrary skid */, ...}, -1, 0, -1, PERF_FLAG_FD_CLOEXEC) = 6
ioctl(6, PERF_EVENT_IOC_ENABLE, 0)      = 0
bpf(BPF_MAP_UPDATE_ELEM, {map_fd=4, key=0x7ffc050c5360, value=0x7ffc050c5368, flags=BPF_ANY}, 128) = 0
perf_event_open({type=PERF_TYPE_SOFTWARE, size=0 /* PERF_ATTR_SIZE_??? */, config=PERF_COUNT_SW_BPF_OUTPUT, sample_period=1, sample_type=PERF_SAMPLE_RAW, read_format=0, precise_ip=0 /* arbitrary skid */, ...}, -1, 1, -1, PERF_FLAG_FD_CLOEXEC) = 7
ioctl(7, PERF_EVENT_IOC_ENABLE, 0)      = 0
bpf(BPF_MAP_UPDATE_ELEM, {map_fd=4, key=0x7ffc050c5360, value=0x7ffc050c5368, flags=BPF_ANY}, 128) = 0
bpf(BPF_PROG_LOAD, {prog_type=BPF_PROG_TYPE_TRACEPOINT, insn_cnt=27, insns=0x557142e8bbd0, license="GPL", log_level=0, log_size=0, log_buf=NULL, kern_version=KERNEL_VERSION(5, 15, 46), prog_flags=0, prog_name="sys_enter", prog_ifindex=0, expected_attach_type=BPF_CGROUP_INET_INGRESS, prog_btf_fd=0, func_info_rec_size=0, func_info=NULL, func_info_cnt=0, line_info_rec_size=0, line_info=NULL, line_info_cnt=0, attach_btf_id=0, attach_prog_fd=0, fd_array=NULL}, 128) = 9
perf_event_open({type=PERF_TYPE_TRACEPOINT, size=0 /* PERF_ATTR_SIZE_??? */, config=348, sample_period=1, sample_type=0, read_format=0, precise_ip=0 /* arbitrary skid */, ...}, -1, 0, -1, PERF_FLAG_FD_CLOEXEC) = 8
ioctl(8, PERF_EVENT_IOC_SET_BPF, 9)     = 0
ioctl(8, PERF_EVENT_IOC_ENABLE, 0)      = 0
^Cstrace: Process 813445 detached
```

```python
#!/usr/bin/python
from bcc import BPF
from time import sleep

program = """
int hello_world(void *ctx) {
  bpf_trace_printk("Hello world!\\n");
  return 0;
}
"""

b = BPF(text=program)
clone = b.get_syscall_fnname("clone")
b.attach_kprobe(event=clone, fn_name="hello_world")
b.trace_print();

while True:
  sleep(2)
  s = ""
  if len(b["clones"].items()):
    for k,v in b["clones"].items():
      s += "ID {}: {}\t".format(k.value, v.value)
    print(s)
  else:
    print("No entries yet")
```

---
참고
- https://www.tcpdump.org/papers/bpf-usenix93.pdf
- https://netflixtechblog.com/how-netflix-uses-ebpf-flow-logs-at-scale-for-network-insight-e3ea997dca96
- https://www.brendangregg.com/bpf-performance-tools-book.html
- https://www.amazon.com/gp/reader/0136554822?asin=B081ZDXNL3&revisionId=c47b7fdb&format=1&depth=1
- https://en.wikipedia.org/wiki/Berkeley_Packet_Filter
- https://www.youtube.com/watch?v=lrSExTfS-iQ