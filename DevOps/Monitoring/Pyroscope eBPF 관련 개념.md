# eBPF로 서버 성능 Profiling하는 법: Pyroscope의 구현 살펴보기

Pyroscope는 애플리케이션을 지속적으로 프로파일링하는 오픈소스 플랫폼이다. 

> **프로파일링(profiling)이란?**
>
> 프로그램을 실행하면서 성능을 측정하고, 분석하는 행위를 프로파일링이라고 한다. <br/>
> - 함수 혹은 메소드가 CPU를 얼마나 오랫동안 사용하는가, 얼마나 많이 호출되는가
> - 메모리를 얼마나 자주 할당 및 해제하는가, 얼마나 많이 할당하느냐
> 
> 와 같은 정보를 측정한다.

애플리케이션이 사용한 CPU, Memory 등의 프로파일링 정보을 Flame Graph로 확인하는 기능을 제공한다. 

Flame Graph에서 각 사각형은 Stack frame(함수)를 나타내고, 사각형의 가로 너비는 현재 프로파일에 얼마나 존재하는지(실행되는지)를 나타낸다. CPU 사용 정보를 예시로 들면, CPU를 오랫동안 사용하는 함수의 너비가 넓게 표시되는 것이다. 

이를 통해서 어떤 함수가 리소스를 많이 사용하는 병목 지점인지 찾아낼 수 있다.

<img style="width:597px;" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/e1e3ba7a-cced-418b-8428-875069021be8"/>

Pyroscope에서 Profiling 정보를 수집하는데는 두 가지 방식이 있다.

1. 각 언어 SDK에서 Pyroscope에 정보를 전송하는 방식 ([문서](https://grafana.com/docs/pyroscope/latest/configure-client/language-sdks/))
2. Grafana Agent(Alloy)에서 Pyroscope에 정보를 전송하는 방식

이 중 Grafana Agent(Alloy) 방식을 쓰면 [eBPF로 CPU Profile 정보를 수집하는 기능](https://grafana.com/docs/pyroscope/latest/configure-client/grafana-agent/ebpf/)을 사용할 수 있다. 

> **eBPF란?**
>
> 커널 레벨에서 코드를 실행시키기 위한 공간을 제공해주는 기술이다. (in-kernel virtual machine) <br/>
> 커널 코드 내에 미리 정의된 훅이나 kprobe, uprobe, tracepoint를 사용해서 프로그램을 실행할 수 있다. 즉, 특정 이벤트가 발생했을 때 커널 레벨에서 코드를 실행시키도록 할 수 있다. <br/>
> 커널 수준에서 일어나는 특정 이벤트에 대해 추적하거나 모니터링하기 위해 활용하는 경우가 많다.

eBPF를 사용한 방식은 아래와 같은 장점을 가진다:
- 성능 오버헤드가 가장 낮고, low level의 함수 호출 정보(System Call 등)까지 세밀하게 수집할 수 있다. (System Call이나 )
- 애플리케이션 코드를 수정하지 않고 데이터를 수집할 수 있다.

하지만 한계 또한 있다:
- 실행된 명령어의 포인터로 함수명을 찾기 때문에, 일부 언어에서만 지원된다. (Go, Rust, C/C++, Python에 대해서만 사용 가능하고, Java와 node.js에 대한 기능은 [이슈](https://github.com/grafana/pyroscope/issues/2766)만 등록된 상태이다.)
- 메모리 및 Thread Lock 등의 프로파일링 유형을 지원하지 않는다.
- eBPF는 호스트 시스템에 대한 root 액세스 권한이 필요하므로 일부 환경에서는 문제가 될 수 있다.

### 1. Target 찾기

Target을 찾아서 어떤 pid에서 실행된 명령어에 어떤 태그를 달아서 수집할지 지정해놓는다.

### 1. PID 

- `pid_event`를 반환하는 ebpf들을 만든다.
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
  - 가져오는 방법은 elf table

---
참고
- https://www.brendangregg.com/flamegraphs.html
- https://www.emaallstars.com/categories-of-ebpf-tools.html