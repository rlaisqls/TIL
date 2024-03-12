
- top 명령어를 사용하면 시스템의 상태를 전반적으로 가장 빠르게 파악할 수 있다. (CPU, Memory, Process)
- 옵션 없이 입력하면 interval 간격(기본 3초)으로 화면을 갱신하며 정보를 보여준다.

```bash
$ top -help
  procps-ng 3.3.17
Usage:
  top -hv | -bcEeHiOSs1 -d secs -n max -u|U user -p pid(s) -o field -w [cols]
```

```bash
top - 21:22:27 up 232 days,  2:22,  3 users,  load average: 0.00, 0.04, 0.05
Tasks: 134 total,   1 running, 133 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.8 us,  0.5 sy,  0.0 ni, 98.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem:   3712.0 total,    181.8 free,   2010.1 used,   1520.0 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.   1419.4 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND                                                 
      1 root      20   0  174752  12136   8484 S   0.3   0.3 516:12.38 systemd                                                 
   2402 root      20   0 1498416  25636   7104 S   0.3   0.7 741:07.27 containerd                                              
 705636 ubuntu    20   0   10892   3840   3144 R   0.3   0.1   0:00.01 top                                                     
1677876 root      20   0  712200   6344   3292 S   0.3   0.2  26:35.67 containerd-shim                                         
      2 root      20   0       0      0      0 S   0.0   0.0   0:00.83 kthreadd                                                
      3 root       0 -20       0      0      0 I   0.0   0.0   0:00.00 rcu_gp                                                  
...        
```

- load average: 현재 시스템이 얼마나 일을 하는지를 나타냄. 3개의 숫자는 1분, 5분, 15분 간의 평균 실행/대기 중인 프로세스의 수. CPU 코어수 보다 적으면 문제 없음
- Tasks: 프로세스 개수
- KiB Mem, Swap: 각 메모리의 사용량
- PR: 실행 우선순위
- VIRT, RES, SHR: 메모리 사용량 => 누수 check 가능
- S: 프로세스 상태(작업중, I/O 대기, 유휴 상태 등)

- VIRT
    - 프로세스가 사용하고 있는 virtual memory의 전체 용량
    - 프로세스에 할당된 가상 메모리 전체
    - SWAP + RES
- RES
    - 현재 프로세스가 사용하고 있는 물리 메모리의 양
    - 실제로 메모리에 올려서 사용하고 있는 물리 메모리
    - 실제로 메모리를 쓰고 있는 RES가 핵심!
- SHR
    - 다른 프로세스와 공유하고 있는 shared memory의 양
    - 예시로 라이브러리를 들 수 있음. 대부분의 리눅스 프로세스는 glibc라는 라이브러리를 참고하기에 이런 라이브러리를 공유 메모리에 올려서 사용

**top 실행 후 명령어**

- `shift + p`: CPU 사용률 내림차순
- `shit + m`: 메모리 사용률 내림차순
- `shift + t`: 프로세스가 돌아가고 있는 시간 순
- `k`: kill. k 입력 후 PID 번호 작성. signal은 9
- `f`: sort field 선택 화면 -> q 누르면 RES순으로 정렬
- `a`: 메모리 사용량에 따라 정렬
- `b`: Batch 모드로 작동
- `1`: CPU Core별로 사용량 보여줌
  
- ps와 top의 차이점
    - ps는 ps한 시점에 proc에서 검색한 cpu 사용량을 출력한다.
    - top은 proc에서 일정 주기로 합산해 실시간 cpu 사용량을 출력한다. 

## Memory Commit

- 프로세스가 커널에게 필요한 메모리를 요청하면 커널은 프로세스에 메모리 영역을 주고 실제로 할당은 하지 않지만 해당 영역을 프로세스에게 주었다는 것을 저장해둔다.
- 이런 과정을 Memory commit이라 부른다.

- 왜 커널은 프로세스의 메모리 요청에 따라 즉시 할당하지 않고 Memory Commit과 같은 기술을 사용해 요청을 지연시킬까?
    - `fork()`와 같은 새로운 프로세스를 만들기 위한 콜을 처리해야 하기 때문이다.
    - `fork()` 시스템 콜을 사용하면 커널은 실행중인 프로세스와 똑같은 프로세스를 하나 더 만들고, `exec()` 시스템 콜을 통해 다른 프로세스로 변한다.
    - 이 때 확보한 메모리가 쓸모 없어질 수 있으므로, `COW(Copy-On-Write)` 기법을 통해 복사된 메모리 영역에 실제 쓰기 작업이 발생한 후 실질적인 메모리 할당을 진행