
Pyroscope는 애플리케이션을 지속적으로 프로파일링하는 오픈소스 플랫폼이다. Go의 `pprof`, python의 `py-spy`, eBPF 등 다양한 백엔드를 지원한다. 애플리케이션이 사용한 CPU, Memory 등의 메트릭을 Flamegraph로 확인할 수 있도록 하는 기능을 제공한다.

Flamegraph는 샘플링 시간에 캡처된 모든 함수를 보여준다. 그래프의 각 층은 호출되는 함수의 계층을 나타내고, 각 상자의 너비는 해당 함수가 덤프에 나타나는 빈도(즉, 프로그램이 해당 함수에서 사용되는 시간)를 의미한다.

- target을 찾아서 어떤 pid에서 실행된 명령어에 어떤 태그를 달아서 수집할지 지정해놓는다.


- pid_event를 반환하는 ebpf들을 만든다.
  - `OP_REQUEST_EXEC_PROCESS_INFO`
    - kprobe/sys_execveat
    - kprobe/sys_execve
  - `OP_PID_DEAD`
    - kprobe/disassociate_ctty
  - `bpf_perf_event_output(ctx, &events, BPF_F_CURRENT_CPU, &event, sizeof(event));`로 반환
- `PERF_COUNT_SW_BPF_OUTPUT`에 대한 event를 받는 fd를 만든다.
- poller를 통해 해당 fd에 대한 event를 구독한다.
- pid_event 구조체를 가져온다. (op(정보 수집 타입), pid(프로세스 id))
  - 가져와서 pid_config map에 데이터를 저장해놓는다.

- `PERF_COUNT_SW_CPU_CLOCK`를 받는 fd를 만든다.
- ioctl로 ebpf program에 attach한다.
  - `libc::ioctl(fd, PERF_EVENT_IOC_SET_BPF as c_ulong, prog.as_fd().as_raw_fd())`
  - `libc::ioctl(fd, PERF_EVENT_IOC_ENABLE as c_ulong, 0)`
- 그러면 해당 perf event 발생시 ebpf 코드가 실행된다.
  - ebpf 코드에선 pid_config를 가져와서 `bpf_get_stackid`로 stack을 조회하고
  - 수집한 정보를 count라는 map에 저장++한다.

- 주기적으로 count map에 있는 정보를 조회한다.
  - 8씩 잘라서 128번 돌면서 각 pointer에 대한 이름 가져오기
  - 