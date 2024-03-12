
BPF는 c언어로 작성할 수 있고, LLVM의 clang과 같은 컴파일러를 활용해 C언어로 된 BPF 프로그램 코드를 eBPF 바이트코드로 컴파일할 수 있다. 

[linux man 페이지](https://man7.org/linux/man-pages/man8/BPF.8.html)에서 BPF 프로그램 예제를 볼 수 있다.

```c
#include <linux/bpf.h>

#ifndef __section
# define __section(x)  __attribute__((section(x), used))
#endif

__section("classifier") int cls_main(struct __sk_buff *skb) {
    return -1;
}

char __license[] __section("license") = "GPL";
```

이 코드는 아무 동작도 하지 않는 빈 껍데기 프로그램이다. clang을 사용해 다음과 같은 식으로 직접 코드를 빌드할 수 있다.

```bash
$ clan -02 -emit-llvm -c bpf.c -0 - | llc -march=bpf -filetype=obj -o bpf.o
$ file bpf.o
bpf.o: ELF 64-bit LSB relocatable, eBPF, version 1 (SYSV), not stripped
```

빌드된 BPF 바이너리는 사용자 영역에서 `bpf()` 시스템 콜을 통해 로드해서 사용할 수도 있고, `tc`나 `ip` 같은 도구를 통해 `IC`나 `XDP` 등의 시스템에 사용되기도 한다. 사용자 영역에서 BPF로 통신하거나, 결과를 처리하기 위해선 별도의 복잡한 로직이 필요하다.

이러한 것들을 고려하지 않고 **eBPF를 더 쉽게 사용할 수 있도록** 하기 위해 BCC(BPF COmpiler Collection)가 만들어졌다.

### 활용

DCC는 C++, Python, lua 로 작성된 사용자 공간의 프로그램과 C로 작성도니 커널 공간의 BPF 프로그램을 작성할 수 있게 도와준다. BCC를 활용하면 BPF 프로그램을 빌드, 로드, 실행하는 데 많은 편의를 얻을 수 있다.

[BCC tools](https://github.com/iovisor/bcc/tree/master/tools)에는 BPF를 응용한 80여개 이상의 넘는 도구가 포함되어있다. 아래는 BCC tools에 포함된 대표적인 도구와 각 도구가 바라보는 타깃 영역을 나타낸 것이다.

<img width="327" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/d8f58fa4-02eb-435f-bf40-0224df718f9d">

### Example

**1. 시스템 콜을 사용한 유저의 id 출력**

아래 코드는 BCC를 활용하여 eBPF 상에서 시스템 콜이 일어났을 때 `hello_world`라는 함수에서 콜 호출자의 user id를 출력하도록 하는 예제이다. 

program에 해당하는 부분은 c언어 코드이고, 나머지는 python 코드로 되어있다.

[bcc를 먼저 설치](https://github.com/iovisor/bcc/blob/master/INSTALL.md#amazon-linux-1---binary)한 후에 `ebpf.py`라는 이름의 파일을 만들어 실행했다.

```python
#!/usr/bin/python3
from bcc import BPF
from time import sleep

program = """
int hello_world(void *ctx) {
  u64 uid;
  uid = bpf_get_current_uid_gid() & 0xFFFFFFFF;
  bpf_trace_printk("id %d\\n", uid);
  return 0;
}
"""

b = BPF(text=program)
clone = b.get_syscall_fnname("clone")
b.attach_kprobe(event=clone, fn_name="hello_world")
b.trace_print();
```

결과는 아래와 같다. root 유저인 0과 첫번째 유저인 1000이 시스템 콜을 사용했음을 알 수 있다.

쉘을 하나 더 열고 명령어를 사용하면 로그가 계속해서 찍힌다.

```bash
$ sudo ./ebpf.py
b'   systemd-udevd-1205    [001] d..31    89.861992: bpf_trace_printk: id 0'
b''
b'   systemd-udevd-1205    [001] d..31    89.863882: bpf_trace_printk: id 0'
b''
b'   (udev-worker)-3191    [001] d..31    89.972630: bpf_trace_printk: id 0'
b''
b'           <...>-3190    [000] d..31    89.972772: bpf_trace_printk: id 0'
b''
b'           <...>-4623    [001] d..31   215.181875: bpf_trace_printk: id 1000'
```

**2. 시스템 콜을 사용한 유저의 id 출력**

발생하는 sync 시스템 콜 호출 간의 시간 간격을 측정하고, 이 간격이 1초 미만인 경우 해당 간격을 출력한다.

> sync 시스템 콜은 주로 시스템이 자동으로 수행하는데, `sync` 명령어를 사용하여 수동으로 호출할 수도 있다. sync는 파일 시스템의 버퍼를 디스크에 즉시 쓰고 변경된 내용을 디스크에 동기화한다. 주로 시스템 관리 목적으로 사용되며, 변경 내용을 안정하게 디스크에 저장하고 파일 시스템의 무결성을 보장하는 데 도움된다.

```python
#!/usr/bin/python3
from __future__ import print_function
from bcc import BPF
from bcc.utils import printb

# load BPF program
b = BPF(text="""
#include <uapi/linux/ptrace.h>

BPF_HASH(last);

// "last"라는 hash (associative array) 유형의 BPF map object를 생성한다. 타입을 지정하지 않았기에 키 값 모두 기본적으로 u64 타입이 된다. 
// 이 코드에선 hash에서 key가 0인 공간만을 사용할 것이다. 

int do_trace(struct pt_regs *ctx) {
    u64 ts, *tsp, delta, key = 0;

    // 저장된 timestamp를 가져온다.
    // lookup 함수는 hash에서 key를 찾고 값 존재 여부에 따라 값의 포인터 또는 NULL을 반환한다.
    tsp = last.lookup(&key); 
    if (tsp != NULL) {
        delta = bpf_ktime_get_ns() - *tsp;
        if (delta < 1000000000) {
            // output if time is less than 1 second
            bpf_trace_printk("%d\\n", delta / 1000000);
        }
        last.delete(&key);
    }

    // 저장된 timestamp를 갱신한다.
    ts = bpf_ktime_get_ns();
    last.update(&key, &ts);
    return 0;
}
""")

b.attach_kprobe(event=b.get_syscall_fnname("sync"), fn_name="do_trace")
print("Tracing for quick sync's... Ctrl-C to end")

# format output
start = 0
while 1:
    try:
        (task, pid, cpu, flags, ts, ms) = b.trace_fields()
        if start == 0:
            start = ts
        ts = ts - start
        printb(b"At time %.2f s: multiple syncs detected, last %s ms ago" % (ts, ms))
    except KeyboardInterrupt:
        exit()
```

간단하게 설명하면 bpf hash에 이전 sync 호출 시간을 저장해놓고, sync 호출 시 이전 sync 시간과 비교하여 출력하는 코드이다. 

출력 예시는 다음과 같다.

```bash
$ sudo ./ebpf.py
Tracing for quick sync's... Ctrl-C to end
At time 0.00 s: multiple syncs detected, last 616 ms ago
At time 4.92 s: multiple syncs detected, last 795 ms ago
At time 7.06 s: multiple syncs detected, last 530 ms ago
At time 7.61 s: multiple syncs detected, last 544 ms ago
At time 8.18 s: multiple syncs detected, last 575 ms ago
At time 8.88 s: multiple syncs detected, last 693 ms ago
At time 36.94 s: multiple syncs detected, last 767 ms ago
At time 121.95 s: multiple syncs detected, last 615 ms ago
```

---
참고
- https://product.kyobobook.co.kr/detail/S000001766462