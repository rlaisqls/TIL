
Pyroscope는 애플리케이션을 지속적으로 프로파일링하는 오픈소스 플랫폼이다. Go의 `pprof`, python의 `py-spy`, eBPF 등 다양한 백엔드를 지원한다. 애플리케이션이 사용한 CPU, Memory 등의 메트릭을 Flamegraph로 확인할 수 있도록 하는 기능을 제공한다.

Flamegraph는 샘플링 시간에 캡처된 모든 함수를 보여준다. 그래프의 각 층은 호출되는 함수의 계층을 나타내고, 각 상자의 너비는 해당 함수가 덤프에 나타나는 빈도(즉, 프로그램이 해당 함수에서 사용되는 시간)를 의미한다.

<image height="300px" src="https://github.com/rlaisqls/TIL/assets/81006587/58380823-0b4a-4b93-a8ed-829dc8e8e7c0">

## eBPF Backend

Pyroscope의 ebpf 백엔드는 Flamegraph 정보를 가져오기 위해 eBPF helper인 `bpf_get_stackid`를 사용한다. `bpf_get_stackid`를 사용하면 특정 애플리케이션의 사용자 또는 커널 스택을 검사할 수 있다.

> Walk a user or a kernel stack and return its id. To achieve this, the helper needs ctx, which is a pointer to the context on which the tracing program is executed, and a pointer to a map of type BPF_MAP_TYPE_STACK_TRACE.

따라서 helper는 두 가지 작업을 수행한다.

- 커널(또는 사용자) 스택을 탐색하고 `BPF_MAP_TYPE_STACK_TRACE` 타입의 eBPF Map 요소를 채운다.
- 맵에 액세스하기 위해 해당 스택에 해당하는 키를 생성하고 반환한다.
  
eBPF 프로그램은 Agent에 의해 주기적으로 호출되면서 스택 실행 정보를 수집하고 발생 횟수를 계산한다. eBPF에서 실제로 실행하는 코드의 흐름은 아래와 같다:

1. 설정을 가져온다 (e.g. 스레드 ID에 대한 필터링을 수행해야 하는지 여부)
2. 현재 명령어 포인터를 가져온다.
3. 설정에 따라 커널 스택 또는 사용자 스택을 가져온다.
4. 명령, 스택 ID 및 스레드 ID를 기반으로 키를 생성하고, 해당 스택이 발생한 횟수를 계산한다.

```c
SEC("perf_event")
int do_perf_event(struct bpf_perf_event_data *ctx)
{
    u64 id = bpf_get_current_pid_tgid();
    u32 tgid = id >> 32;
    u32 pid = id;
    struct sample_key key = { .pid = tgid};
    key.kern_stack = -1;
    key.user_stack = -1;
    u32 *val, one = 1, zero = 0;
    struct bss_arg *arg = bpf_map_lookup_elem(&args, &zero); // 1
    if (!arg) {
        return 0;
    }
    if (pid == 0) {
        return 0;
    }
    if (arg->tgid_filter != 0 && tgid != arg->tgid_filter) {
        return 0;
    }

    bpf_get_current_comm(&key.comm, sizeof(key.comm)); // 2

    if (arg->collect_kernel) {
        key.kern_stack = bpf_get_stackid(ctx, &stacks, KERN_STACKID_FLAGS); // 3
    }
    if (arg->collect_user)  {
        key.user_stack = bpf_get_stackid(ctx, &stacks, USER_STACKID_FLAGS); // 3 
    }

    val = bpf_map_lookup_elem(&counts, &key); // 4
    if (val)
        (*val)++;
    else
        bpf_map_update_elem(&counts, &key, &one, BPF_NOEXIST); // 4
    return 0;
}
```

### StackTrace 구하기

helper에서 명령어의 포인터를 기준으로 정보를 수집한 후에는, 이를 사람이 읽을 수 있는 이름으로 바꾸는 과정이 필요하다. 변환하는 흐름은 아래와 같다.

1. 각 CPU에 대해 perf 이벤트를 생성한다.

    ```go
    func newPerfEvent(cpu int, sampleRate int) (*perfEvent, error) {
        var (
        fd  int
        err error
        )
        attr := unix.PerfEventAttr{
        Type:   unix.PERF_TYPE_SOFTWARE,
        Config: unix.PERF_COUNT_SW_CPU_CLOCK,
        Bits:   unix.PerfBitFreq,
        Sample: uint64(sampleRate),
        }
        fd, err = unix.PerfEventOpen(&attr, -1, cpu, -1, unix.PERF_FLAG_FD_CLOEXEC)
        if err != nil {
        return nil, fmt.Errorf("open perf event: %w", err)
        }
        return &perfEvent{fd: fd}, nil
    }
    ```

2. 그리고 eBPF 프로그램을 여기에 연결한다.

    ```go
    err = pe.attachPerfEvent(s.bpf.profilePrograms.DoPerfEvent)
    ```

3. Flame 그래프 정보를 가져오기 위해 스택의 모든 키를 수집하고 카운터 맵을 읽는다.

    ```go
    keys, values, batch, err := s.getCountsMapValues()
    if err != nil {
        return fmt.Errorf("get counts map: %w", err)
    }
    ```

4. 각 키의 스택 맵에 액세스하고 pid, 스택, 카운터를 사용하여 레코드를 작성한다.

    ```go
    for i := range keys {
        /*...*/
        if s.options.CollectUser {
            uStack = s.getStack(ck.UserStack)
        }
        if s.options.CollectKernel {
            kStack = s.getStack(ck.KernStack)
        }
        sfs = append(sfs, sf{
            pid:    ck.Pid,
            uStack: uStack,
            kStack: kStack,
            count:  value,
            comm:   getComm(ck),
            labels: labels,
        })
    }
    ```

5. 이러한 getStack 호출은 명령 포인터 형식(정수)으로 스택을 반환한다. 각 요소에 대해 해당 PID의 스택을 탐색하고 이를 기호 이름과 함께 읽을 수 있는 형식으로 변환한 다음 콜백을 통해 반환한다.

    ```go
    for _, it := range sfs {
        stats := stackResolveStats{}
        sb.rest()
        sb.append(it.comm)
        if s.options.CollectUser {
            s.walkStack(&sb, it.uStack, it.pid, &stats)
        }
        if s.options.CollectKernel {
            s.walkStack(&sb, it.kStack, 0, &stats)
        }
        if len(sb.stack) == 1 {
            continue // only comm
        }
        lo.Reverse(sb.stack)
        cb(it.labels, sb.stack, uint64(it.count), it.pid)
        s.debugDump(it, stats, sb)
    }
    ```

6. 해석을 수행할 수 있도록 `symCache` object를 채운다.

    ```go
    func (s *session) walkStack(sb *stackBuilder, stack []byte, pid uint32, stats *stackResolveStats) {
        if len(stack) == 0 {
            return
        }
        var stackFrames []string
        for i := 0; i < 127; i++ {
            instructionPointerBytes := stack[i*8 : i*8+8]
            instructionPointer := binary.LittleEndian.Uint64(instructionPointerBytes)
            if instructionPointer == 0 {
                break
            }
            sym := s.symCache.Resolve(pid, instructionPointer)
            var name string
            if sym.Name != "" {
                name = sym.Name
                stats.known++
            } else {
                if sym.Module != "" {
                    // name = fmt.Sprintf("%s+%x", sym.Module, sym.Start) // todo expose an option to enable this
                    name = sym.Module
                    stats.unknownSymbols++
                } else {
                    name = "[unknown]"
                    stats.unknownModules++
                }
            }
            stackFrames = append(stackFrames, name)
        }
    }
    ```

7. `/proc/$pid/maps` 공간을 읽어서 각 주소의 데이터 구조를 읽는다.

    ```go
        ProcMap {
        StartAddr: saddr,
        EndAddr:   eaddr,
        Perms:     perms,
        Offset:    offset,
        Dev:       device,
        Inode:     inode,
        Pathname:  pathname,
        }
    ```

8. 특정 지역에 해당하는 파일이 주어지면 `elf.NewFile()`이 구문을 분석한다. 구문 분석은 아래와 같은 과정으로 이뤄진다.

   - 명령 포인터가 어디에 속해 있는지 찾기 위해 모든 범위를 탐색한다. [(코드)](https://github.com/grafana/pyroscope/blob/07c51d833e73450c77800545ca0a3003d49fd049/ebpf/symtab/proc.go#L133)
   - 주어진 범위에 해당하는 파일을 사용하여 elf 테이블을 작성한다. [(코드)](https://github.com/grafana/pyroscope/blob/07c51d833e73450c77800545ca0a3003d49fd049/ebpf/symtab/proc.go#L121)
   - elf 파일에서 buildID를 가져온다. [(코드)](https://github.com/grafana/pyroscope/blob/5acd4f8255ef154370e19bc8523aacf6531ad759/ebpf/symtab/elf.go#L98)
   - symbol에 사용할 debug 파일을 찾는다. [(코드)](https://github.com/grafana/pyroscope/blob/5acd4f8255ef154370e19bc8523aacf6531ad759/ebpf/symtab/elf.go#L124)
   - elf 테이블에서 symbol을 가져온다. [(코드)](https://github.com/grafana/pyroscope/blob/5acd4f8255ef154370e19bc8523aacf6531ad759/ebpf/symtab/elf.go#L156)
  
이 과정을 통해 flameGraph를 표현하기 위한 각 StackTrace 정보를 얻을 수 있다!

---
참고
- https://fedepaol.github.io/blog/2023/09/24/ebpf-journey-by-examples-perf-events-with-pyroscope
- https://github.com/grafana/pyroscope/tree/main
- https://grafana.com/docs/pyroscope/latest/configure-client/grafana-agent/ebpf/