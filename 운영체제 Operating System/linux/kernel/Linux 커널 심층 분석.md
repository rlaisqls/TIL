# Linux 커널 심층 분석

> https://product.kyobobook.co.kr/detail/S000000935348

<img width="274" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/68bc09a0-0951-4fcb-aa06-9df4cd85ecbf">

리눅스 커널 심층 분석 책을 읽고 내용을 정리하는 문서입니다.

# Chapter 1,2 리눅스 커널 소개

## 1.2 OS와 커널

- 커널은 시스템의 기본적인 서비스를 제공하고, HW를 관리하며, 리소스를 분배하는 핵심 SW를 의미한다.

- 커널의 주 구성요소 
  - 인터럽트 핸들러 (ISR, Interrupt Service handler Routain)
  - 프로세스 스케줄러 (Scheduler)
  - 메모리 관리 시스템 (MM, Memory Management)
  - 네트워크 및 IPC 서비스

- 일반적으로 사용자는 시스템의 ‘유저 공간’에서 사용자 애플리케이션을 수행하며, 커널 기능이 필요할 때 시스템콜 또는 인터럽트를 호출해 ‘커널 공간’에 있는 커널 애플리케이션을 요청한다.

## 1.3 UNIX vs LINUX

- 커널 모듈 동적 로드 기능 제공한다. (Monolothic kernel이지만 동시에 micro kernel 성격도 가짐)
- SMP(symmetric multiprocessing)를 지원한다. (최신 상용 UNIX도 지원한다)
- 커널도 선점형 스케줄러로 동작한다.
- 프로세스와 스레드를 구분하지 않는다.
- 디바이스 파일시스템(sysfs) 등을 지원해 객체지향적 장치 모델을 지원한다.

## 2.2 커널 소스 트리

커널 소스 트리는 여러 개의 디렉토리로 구성되는데, 최상단의 주요 디렉토리에 대한 설명은 다음과 같다.

- `arch`: 특정 아키텍처(i.e. ARM, PowerPC, x86 등)에 대한 소스코드
- `block`: 블록 I/O 관련 기능에 대한 소스코드
- `crypto`: 암호화 관련 기능에 대한 소스코드
- `Documentation`: 커널 소스와 관련된 문서 모음
- `drivers`: 장치 드라이버 관련 소스코드
- `firmwares`: 특정 장치 드라이버를 사용할 때 필요한 펌웨어의 모음
- `fs`: 파일시스템 관련 소스코드
- `include`: 커널의 헤더 파일 모음
- `init`: 커널 초기화 관련 소스코드
- `ipc`: 프로세스 간 통신(IPC) 관련 소스코드
- `kernel`: 스케줄러와 같은 핵심 커널 시스템 관련 소스코드
- `lib`: 유틸리티 모음
- `mm`: 메모리 관리 시스템 및 가상 메모리 관련 소스코드
- `net`: 네트워크 관련 소스코드
- `samples`: 예제 및 데모 코드 모음
- `scripts`: 커널 빌드를 위한 스크립트 모음
- `security`: 보안 기능 관련 소스코드
- `sound`: 사운드 시스템 기능 관련 소스코드
- `usr`: 초기 사용자 공간 소스코드
- `tools`: 리눅스 커널 개발에 유용한 도구 모음
- `virt`: 가상과 기반 구조 관련 소스코드

## 2.3. 커널의 특징

- 커널은 속도 및 크기를 이유로 표준 C 라이브러리(libc) 대신 GNU C(glibc)를 이용한다.
- 커널 공간에는 유저 공간과 같은 메모리 보호 기능이 없다.
- 커널은 부동소수점 연산을 쉽게 수행할 수 없다.
- 커널은 프로세스당 고정된 작은 크기의 스택을 사용한다.
- 커널은 비동기식 선점형 인터럽트를 지원하며, SMP를 지원하므로 동기화 및 동시성(concurrency) 문제가 매우 중요하다.

# Chapter 3. 프로세스 관리

## 3.1 프로세스와 구조체

- 프로세스는 프로그램 코드를 실행하면서 생기는 모든 결과물이다.
  - 일반적인 의미: 실행 중인 프로그램
  - 포괄적인 의미: 사용 중인 파일, 대기 중인 시그널, 커널 내부 데이터, 프로세서 상태, 메모리 주소 공간, 실행 중인 하나 이상의 스레드 정보 등
- 프로세스는 `fork()` 호출 시 생성되고, 기능을 수행한 뒤, `exit()`를 호출해 종료된다. 부모 프로세스는 `wait()` 호출로 자식 프로세스 종료 상태를 확인할 수 있다.
- 스레드는 프로세스 내부에서 동작하는 객체이고, 개별적인 PC, Stack, Register(context)를 가지고 있다.
- 리눅스 커널은 프로세스와 스레드를 구분하지 않는다.
- 리눅스 커널에 대한 접근은 오직 시스템 콜과 ISR로만 가능하다.
  
- 커널은 프로세스를 ‘task list’라는 **circular bidirctional linked list **자료구조로 저장한다.
- ‘Task list’는 `<linux/sched.h>` 내 `task_struct` 구조체로 정의되어있다.
  - `task_struct`는 프로세스를 관리하는 데 필요한 모든 정보를 가지고 있어서 정의만 약 300줄 가량이며 32-bit 시스템 기준 약 1.7KB에 달하는 상당히 큰 구조체다.
  - `task_struct`는 ‘slab allocator’(객체 재사용 및 캐시 기능 지원)를 이용해 동적할당 한다.
    - 커널 2.6 버전 이전에는 각 프로세스 커널의 최하단(또는 최상단)에 task_struct를 뒀다. 그래야 x86처럼 레지스터 개수가 적은 아키텍처에서 레지스터에 따로 task_struct의 주솟값을 저장하지 않고 바로 접근할 수 있었기 때문이다.
  
    ```c
    struct task_struct {
        volatile long state;
        void *stack;
        atomic_t usage;
        unsigned int flags;
        unsigned int ptrace;

        int lock_depth;
    #ifdef CONFIG_SMP
    #ifdef __ARCH_WANT_UNLOCKED_CTXSW
    ...
    }
    ```

## 3.2 프로세스 상태

- 프로세스는 다음과 같은 5가지 상태를 가진다. 

  - `TASK_RUNNING`: Ready queue에서 대기중이거나, 현재 동작 중인 프로세스다.
  - `TASK_INTERRUPTIBLE`/`TASK_UNINTERRUPTIBLE`: 특정 조건이 발생하기를 기다리며 중단된 상태에 있는 프로세스다. 조건 발생 시 `TASK_RUNNING`으로 바뀐다. Signal 수신 여부로 두 상태를 구분한다.
  - `TASK_TRACED`: 디버거 같은 장비를 사용하는 외부 프로세스가 ptrace를 사용해 해당 프로세스를 추적하고 있는 상태다.
  - `TASK_STOPPED`: 프로세스가 SIGSTOP 같은 signal을 받아 실행이 정지된 상태다.

- 프로세스의 상태는 `<linux/sched.h>`의 `set_task_state()` 함수로 설정 가능하다.

## 3.3 프로세스 계층 트리

- 모든 프로세스는 PID 1인 init 프로세스의 자식 프로세스다.
- `task_struct`는 부모-형제-자식 프로세스의 관계를 표현하고 있다.
- 또한, `task_struct`는 (Bidirectional circular linked list의 요소를 가리키는) `*next`, `*prev` 포인터를 갖고 있다.
  

## 3.4 프로세스 생성

- UNIX에서는 `fork()`로 프로세스를 생성할 때 부모 프로세스의 모든 리소스를 그대로 자식 프로세스에 복사하는 식으로 구현했다. 일반적으로 자식 프로세스는 생성된 후 `exec()`을 이용해 다른 프로그램을 실행하는 경우가 많으므로 이러한 방법은 굉장히 비효율적이었다.

- 리눅스는 ‘Copy-and-write’를 이용해서 이 문제를 해결했다. 
  - 자식 프로세스가 공유자원에 write을 시도할 때 부모 프로세스 → 자식 프로세스 리소스 복사한다.
  - 자식 프로세스가 공유자원에 write을 하지 않는 경우 (대부분 생성 후 바로 `exec()`하는 경우), 큰 최적화 효과를 얻을 수 있다.

- 프로세스가 생성되는 세부적인 과정은 다음과 같다. 

1. 리눅스의 glibc 속 `fork()`는 `clone()` 이라는 시스템콜을 다양한 플래그를 적용해 부모-자식 프로세스간 공유자원을 지정한 뒤 호출한다.
     - linux - Which file in kernel specifies `fork()`, `vfork()`... to use `sys_clone()` system call - Unix & Linux Stack Exchange

2. `clone()`은 `do_fork()`함수를 호출하고 `do_fork()`는 `copy_process()`를 호출해 내부적으로 아래 과정을 수행한다.

     1. `dup_task_struct()` 함수 호출 
         - 새로운 프로세스 스택 공간 할당, 새로운 thread_info, task_struct 구조체를 생성한다.
         - 생성할 때 부모의 process descriptor를 그대로 가져와서 생성한다.
     2. 프로세스 개수 제한을 넘었는지 검사한다.
     3. 자식 프로세스 구조체의 일부 멤버변수를 초기화. (상태= `TASK_UNINTERRUPTED`)
     4. `copy_flag()` 함수 호출 
         - `task_struct`의 `flags` 내용을 정리한다.
         - `PF_SUPERPRIV` 플래그 초기화: 현재 수행하는 작업이 관리자 권한임을 의미.
         - `PF_FORKNOEXEC` 플래그 초기화: 프로세스가 exec() 함수를 호출하지 않았음을 의미.
     5. `alloc_pid()` 함수 호출 
         - 자식 프로세스에게 새로운 PID값을 할당한다.
     6. `clone()`의 매개변수로 전달된 플래그에 따라 파일시스템 정보, signal handler, 주소공간, namespace 등을 share하거나 copy한다. (보통 스레드는 share를, 프로세스는 copy 한다.)
3. 생성한 자식 프로세스의 포인터를 반환한다.

- `vfork()` 시스템콜은 부모 프로세스의 page table을 copy하지 않는다는 점을 제외하면 `fork()`와 동일. 그러나 copy-and-write을 사용하는 리눅스 특성상 `fork()` 대비 이득이 적어서 거의 사용하지 않는다.

## 3.5 스레드 구현 및 취급

- 대표적인 modern-programming 기법인 스레드는 공유 메모리를 가진 여러 프로그램을 ‘동시에’(concurrent) 수행해 multi-processor 환경에서는 진정한 병렬처리를 구현할 수 있다.
- 스레드는 개별 `task_struct`를 갖고 메모리를 부모 프로세스와 공유하고 있는 정상 프로세스다. (리눅스는 프로세스와 스레드를 구분하지 않는다.)
- 따라서 스레드도 내부적으로는 프로세스 생성 때와 똑같이 `clone()` 시스템콜을 이용한다. 여러 플래그를 parameter로 넘겨서 스레드의 특성을 부여할 뿐이다. (i.e. `clone(CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND, 0)`;)
- `<linux/sched.h>`의 최상단에 스레드 생성 관련 clone flags가 정의되어있다.

### 커널 스레드
  - 커널도 일부 동작은 백그라운드에서 실행하는 것이 좋은데, 이때 커널 공간에서만 존재하는 특별한 스레드인 ‘커널 스레드’를 이용한다.
  - 가장 큰 차이점은 주소 공간이 없다는 점이다. (프로세스의 주소 공간을 가리키는 mm 포인터가 NULL이다.)
  - 커널 스레드는 `<linux/kthread.h>`에 정의돼있고, `kthreadd`라는 최상위 부모 스레드가 모든 하위 커널 스레드를 만드는 방식으로 동작한다.

  - 커널 스레드는 `kthread_run` 매크로로 `kthread_create()`를 호출해 `clone()` 시스템콜을 호출해 만든다.

## 3.6 프로세스 종료

- 프로세스는 `main()`이 끝날 때 묵시적으로 또는 명시적으로 `exit()`를 호출하여 종료된다.
- `exit()` 함수는 내부적으로 `<kernel/exit.c>`에 정의된 `do_exit()` 함수를 호출한다.
- 프로세스 종료 과정은 아래와 같다.

```c
void __noreturn do_exit(long code)
{
	struct task_struct *tsk = current;
	int group_dead;

	...
	exit_signals(tsk);  /* 1 - sets PF_EXITING */

	acct_update_integrals(tsk); /* 2 */
	group_dead = atomic_dec_and_test(&tsk->signal->live);
	if (group_dead) {
		/*
		 * If the last thread of global init has exited, panic
		 * immediately to get a useable coredump.
		 */
		if (unlikely(is_global_init(tsk)))
			panic("Attempted to kill init! exitcode=0x%08x\n",
				tsk->signal->group_exit_code ?: (int)code);

    ...
	tsk->exit_code = code; /* 3 */
	taskstats_exit(tsk, group_dead);

	exit_mm(); /* 4 */

	if (group_dead)
		acct_process();
	trace_sched_process_exit(tsk);

	exit_sem(tsk); /* 5 */
	exit_shm(tsk);
	exit_files(tsk); /* 6 */
	exit_fs(tsk);

	...
	exit_notify(tsk, group_dead); /* 7 */
	proc_exit_connector(tsk);
	mpol_put_task_policy(tsk);

    ...
	lockdep_free_task(tsk);
	do_task_dead(); /* 8 */
}
```

1. current의 flags의 `PF_EXITING` 플래그를 설정한다.
2. `acct_update_integrals()` 함수를 호출해 종료될 프로세스 정보를 기록한다.
3. current의 exit_code에 `exit()` 함수에서 지정한 값에 따른 종료코드가 저장된다.
4. `exit_mm()` 함수를 호출해 프로세스의 mm_struct를 반환해 자원 해제한다.
5. `exit_sem()` 함수를 호출해 프로세스의 세마포어를 반환해 대기 상태를 해제한다.
6. `exit_files()`, `exit_fs()` 함수를 호출해 file descriptor 및 file system의 참조 횟수를 하나 감소한다. 참조 횟수가 0이면 해당 객체를 사용하는 프로세스가 없다는 의미이므로 자원 해제한다.
7. `exit_notify()` 함수를 호출해 부모 프로세스에 signal을 보낸다. 이때 해당 프로세스가 자식 프로세스를 가지고 있었다면, 자신의 부모 프로세스 or 자신이 속한 스레드 group의 다른 스레드 or init 프로세스 중 하나를 부모로 설정한다.
8. current의 state을 `TASK_DEAD`로 설정해 좀비 프로세스로 만든다.

- 부모 프로세스의 동작은 다음과 같다.
1. `release_task()` 함수를 호출해 더는 자식 좀비 프로세스가 필요없다고 커널에게 signal을 보낸다. `release_task()` -> `__exit_signal()` -> `__unhashed_process()` -> `detach_pid()`
2. `__exit_signal()`에서 좀비 프로세스의 남은 정보도 완전히 메모리 반환한다.
3.  `release_task()`는 `put_task_struct()` 함수를 호출해 좀비 프로세스의 `stack`, `thread_info` 구조체, `task_struct` 구조체가 들어있던 페이지 및 slab cache를 반환한다. 이제 프로세스와 연관된 모든 자원이 해제돼 완전히 종료됐다.

- 부모 프로세스가 좀비가 된 자식 프로세스를 책임지고 종료하지 못할 때 리눅스의 유명한 문제인 ‘좀비 프로세스 문제’가 발생한다.
  - 시스템 메모리를 낭비하는 문제가 발생하는 것이다.
  - 따라서, 위 과정 중 8번에서 다뤘듯, 부모 프로세스가 없을 때 다른 부모 프로세스 후보들 중 하나를 선택해 부모로 설정해주는 과정이 반드시 필요하다.

    1. `do_exit()` 함수에서 `exit_notify()` 함수를 호출한다.
    2. `exit_notify()` 함수에서 `forget_original_parent()` 함수를 호출한다.
    3. `forget_original_parent()` 함수는 종료할 프로세스의 부모 프로세스를 반환하는 함수다. 
       - 이때, 부모 프로세스가 먼저 종료된 ‘문제 좀비 프로세스’인 경우, 적당한 부모 프로세스를 선택해주는 역할도 함께 한다.종료 프로세스가 속한 스레드 group 내에서 다른 스레드를 찾는다. 찾았다면, 해당 스레드를 부모로 만들고 반환한다.
       - 만일 다른 스레드가 없다면, init 프로세스를 찾고 init 프로세스를 부모로 만들어서 반환한다.

    4. 부모 프로세스를 찾았으니 종료할 프로세스의 모든 자식 프로세스의 부모로 설정한다.

- 이로써, 좀비 프로세스를 적절히 종료하지 못해 발생하는 문제를 미연에 방지할 수 있다.

# Chapter 4. 프로세스 스케줄러

## 4.1 정의 및 역사

- 스케줄러는 어떤 프로세스를 어떤 순서로 얼마나 오랫동안 실행할 것인지 정책에 따라 결정한다.
- 스케줄러는 시스템의 최대 사용률을 끌어내 사용자에게 여러 프로세스가 동시에 실행되고 있는 듯한 느낌을 제공해야 한다.
- 스케줄러는 비선점형 스케줄러와 선점형 스케줄러로 나뉜다.
  - 선점형 스케줄러는 일정한 timeslice 동안 전적으로 프로세서 자원을 사용할 수 있고, 시간이 지나면 다음으로 우선순위가 높은 프로세스에 선점된다.
- 1991년 리눅스 첫 버전부터 2.4 버전까지는 단순한 스케줄러를 제공했다.
  - 2.5 버전부터 대대적인 스케줄러 개선작업을 통해 O(1) 스케줄러라는 이름의 새로운 스케줄러를 구현했다. Timeslice 동적 계산이 O(1)에 수행되며 프로세서마다 별도의 wait queue를 구현해 성능향상을 이뤄냈다.
  - 그러나 O(1) 스케줄러는 서버 시스템에는 이상적이었지만, 대화형 서비스를 제공하는 데스크톱 시스템에서는 성능이 안 좋았다.
    그래서 2.6.23 버전부터 **CFS**(Completely Fair Scheduler)라는 새로운 스케줄러를 도입했다.

## 4.2 스케줄러 구성요소

### I/O 중심 프로세스 vs 프로세서 중심 프로세스
  - I/O 중심 프로세스: I/O 요청 후 기다리는 데 대부분의 시간을 사용하는 프로세스 (i.e. 대부분의 GUI 애플리케이션은 사용자의 키보드, 마우스 입력을 기다림)
  - 프로세서 중심 프로세스: 선점될 때까지 대부분의 시간을 코드를 실행하는 데 사용하는 프로세스. 더 긴 시간동안 덜 자주 실행하도록 스케줄링 해야 한다. (i.e. ssh-keygen 등)
  
### 스케줄링 정책
- 정책(Policy)은 스케줄러가 무엇을, 언제 실행할 것인지를 정하는 동작을 의미한다.
- 정책은 두 가지 목적을 갖고 있다. 
  - 프로세스 응답시간(latency)을 빠르게 하기
  - 시스템 사용률(Throughput)을 최대화 하기
- 정책은 낮은 우선순위 프로세스는 최대한 공정하게, 높은 우선순위 프로세스는 최대한 빠르게 선택해서 실행할 책임이 있다.

### 우선순위
- 일반적으로 선점형 우선순위 스케줄링은 
  - 우선순위가 높은 프로세스가 낮은 프로세스를 선점해 먼저 실행하고
  - 우선순위가 같은 프로세스 끼리는 round-robin으로 돌아가며 실행한다.
- 리눅스 커널 프로세스 스케줄링은 두 가지 별개의 우선순위 단위를 갖고 있다. 
  - **Nice**
    - 20~+19 사이의 값을 가지며 값이 클수록 우선순위가 낮다.
    - Timeslice의 비율을 조절할 때도 사용된다.
  - **실시간 우선순위**
    - 0~99 사이의 값을 가지며 값이 클수록 우선순위가 크다.
    - 모든 real-time(실시간) 프로세스는 일반 프로세스보다 우선순위가 높다.

### Timeslice
- Timeslice는 선점 당하기 전까지 프로세스가 작업을 얼마나 오랫동안 실행할 수 있는지를 의미한다. 
  - 너무 길면 대화형 프로세스의 성능이 떨어진다.
  - 너무 짧으면 빈번한 context-switching으로 인해 전체 시스템의 성능이 떨어진다.
- CFS는 프로세스별로 timeslice를 설정하지 않고 프로세스별로 프로세서 할당 ‘비율’을 지정한다. 
  - 그래서 프로세스에 할당되는 CPU time은 시스템의 부하와 nice값에 대한 함수로 O(1)로 결정된다.
- CFS는 모든 프로세스가 공정하게 골고루 실행됨을 보장하기 위해 새 프로세스가 현재 실행 중인 프로세스보다 낮은 비율의 CPU time을 사용했다면, 현재 프로세스를 선점하고 즉시 실행한다.

### 예시

간단한 예시를 통해 일반적인 스케줄러 정책의 동작과 CFS의 동작을 알아보자.

문서 편집기(A, I/O 중심)와 동영상 인코더(B, 프로세서 중심) 두 가지 프로세스가 있다.

- 일반적으로 A가 더 우선순위가 높고 더 많은 CPU time을 할당한다. 
  - 작업량이 많아서가 아니라, 필요한 순간에 항상 CPU time을 얻기 위해서
  - 사용자가 키보드를 눌러 A가 깨어날 때 B를 선점해야 더 좋은 대화형 성능을 보장할 수 있다.
  - B가 실행시간 제약이 없기 때문이다. (지금 실행되든 0.5초 뒤에 실행되는 critical 하지 않음)

- 리눅스의 CFS는 위와 조금 다르게 동작한다. 
  - A는 일정 비율(B와 같은 nice 값을 가진다면 50%)의 CPU time을 보장받는다.
  - A는 사용자 입력을 기다리느라 할당받은 50%의 CPU time을 대부분 사용하지 못한다. 하지만, B는 할당받은 50%의 CPU time을 전부 활용한다.
  - 사용자가 키보드를 눌러 A가 깨어날 때, CFS는 A가 아주 적은 CPU time만 사용했다고 알아차린다.
  - A가 B보다 CPU time 비율이 적으므로 B를 선점하도록 한 뒤 사용자 입력을 빠르게 처리하고 다시 대기모드로 들어간다. 나머지 시간은 B가 온전히 사용할 수 있다.
​
## 4.3 리눅스 스케줄링 알고리즘

### 스케줄러 클래스
  - 리눅스 스케줄러는 모듈화 돼있어 각 프로세스를 각기 다른 알고리즘으로 스케줄링 할 수 있다.
  - 이러한 형태를 ‘스케줄러 클래스’라고 말하며 각 클래스에는 우선순위가 있다.
  - `<kernel/sched.c>`에는 기본 스케줄러가 구현되어있다.
  - CFS는 리눅스의 일반 프로세스용 스케줄러 클래스이며 `<kernel/sched_fair.c>`에서 구현되어있다.

### UNIX의 프로세스 스케줄링
  - CFS에 대해 배우기전에 먼저 전통적인 유닉스의 프로세스 스케줄링 방법에 대해서 배워보자.
  - 앞서 말했듯, 유닉스는 nice 값을 기반으로 우선순위를 결정하고 정해진 timeslice 동안 프로세스를 실행한다. 높은 우선순위 프로세스스는 더 자주 실행되니 더 긴 timeslice를 할당받을 것이다.
  - 하지만, 이 방법에는 몇 가지 문제가 있다. 

1. Context-switching 최적화가 어렵다.
   - Nice에 timeslice를 대응하기 위해 각 nice 값에 할당할 timeslice의 절대값을 정해야 한다. (i.e. nice값 0 = timeslice 100ms, +19 = timeslice 5ms)
   - 어떤 두 프로세스가 있다. 
     - Nice 0인 프로세스 + Nice 19인 프로세스: 전자가 100ms 수행된 뒤 후자가 선점해 5ms를 수행하므로 105ms에 context swtiching이 2회 발생한다.
     - Nice 19인 프로세스 2개: 10ms에 context switching이 2회 발생한다.
     - Nice 0인 프로세스 2개: 200ms에 context switching이 2회 발생한다.
   - 잦은 context switching이 발생하고 우선순위가 낮은 프로세스는 잘 실행되지 않는다.

2. 상대적인 nice값 차이로 문제가 발생한다.
   - Nice 0인 프로세스는 100ms, Nice 1인 프로세스는 95ms를 할당받는다고 가정하자.
   - 두 프로세스의 timeslice 차이는 겨우 5%로, 큰 차이가 없다.
   - Nice 18인 프로세스는 10ms, Nice 19인 프로세스는 5ms를 할당받는다고 가정하자.
   - 두 프로세스의 timeslice 차이는 무려 50%로 굉장한 차이가 발생한다.
   - 즉, ‘nice 값을 1 증가하거나 낮추는 행위’는 기존 nice값에 따라 의미가 달라지게 된다!

3. 아키텍처에 의존적이다.
   - Nice값에 따라 timeslice의 절대값을 할당하기 위해 시스템 클럭의 일정 배수로 timeslice를 설정해야 한다.
   - 시스템의 프로세서 아키텍처에 따라 1-tick은 가변적이므로 timeslice 또한 영향을 받는다.
   - 즉, nice값 1 차이가 1ms 차이일 수도, 10ms 차이일 수도 있다는 문제가 있다.

4. 여러 복잡한 문제를 해결할 수 없다.
   - 대화형 프로세스의 반응성을 개선하기 위해서는 사용자의 키 입력에 대한 인터럽트 발생 시 바로바로 반응할 수 있도록 우선순위를 높여 sleep-wake 과정 속도를 증가해야 한다.
   - 하지만, 한 프로세스만 불공정하게 CPU time을 할당할 수 밖에 없는 방법론적인 허점이 존재한다.
   - 이러한 문제는 UNIX의 스케줄링 방법이 선형적이고 단순하기 때문에 발생한다.
​
### 공정(Fair) 스케줄링 (CFS)

- CFS는 wait 중인 n개의 프로세스 각각에 1/n 비율의 CPU time을 할당해 모두 동일한 시간 동안 실행된다.
  - CFS는 실행 가능한 전체 프로세스 n개와 nice값에 대한 함수를 이용해 개별 프로세스가 얼마 동안 실행할 수 있는지 동적으로 계산한다. 이때, nice값은 CPU time 비율의 가중치로 사용된다.
  - Nice값이 높을수록(우선순위가 낮을수록) 프로세스는 낮은 가중치를 받아 낮은 비율을 할당받는다.

- **목표 응답시간(Targeted Latency)**: CFS가 설정한 응답시간의 목표치이며, 실행이 완료된 프로세스가 다음 번에 자신의 순서가 돌아오기까지 기다려야 하는 최대 시간을 의미한다. 
    - 낮을수록 반응성이 좋아져 완전 멀티태스킹에 가까워진다.
    - 낮을수록 context switching 비용은 높아져 전체 시스템 성능은 낮아진다.
    - 목표 응답시간 20ms인 시스템에 
        - 우선순위 동일 프로세스 2개 있다면? 각각 20 ÷ 2 = 10ms씩 실행된다.
        - 우선순위 동일 프로세스 5개 있다면? 각각 20 ÷ 5 = 4ms씩 실행된다.
        - 우선순위 동일 프로세스 20개 있다면? 각각 20 ÷ 20 = 1ms씩 실행된다.

- **최소 세밀도(Minimum Granularity)**: 각 프로세스에 할당되는 CPU time의 최소값을 의미한다. 
    - 프로세스 개수가 늘어나면, 각 프로세스에 할당되는 CPU time은 점점 0에 수렴한다.
    - Context switching이 전체 수행시간에서 큰 비율을 차지하게 되므로 최소치를 정해놓아야 한다
    - 기본값은 1ms다.

- CFS에선, 오로지 nice값의 상대적인 차이만이 각 프로세스의 timeslice에 영향을 준다. 
    - 앞서 UNIX 스케줄링의 문제점 1번에서 언급했지만, nice값과 timeslice가 선형관계일 때, context switching이 언제(10ms? 105ms? 200ms?) 발생할지 예측할 수 없다는 문제가 있었다.
    - 목표 응답시간 20ms인 시스템에 두 프로세서 A, B가 있을 때, 
        - A(nice: 0), B(nice: 5) 이라면, A는 15ms, B는 5ms를 할당받는다.
        - A(nice: 10), B(nice: 15) 이라면, 똑같이 A는 15ms, B는 5ms를 할당받는다
        - Nice값의 절대값이 CFS의 결정에 영향을 미치지 않는것에 집중하자.

- CFS는 프로세스 개수가 많이 늘어나서 최소 세밀도 이하로 내려갈 경우에는 공정성을 보장하지 못한다. 
  - 완전히 공정하진 않지만, 각 프로세스에 공정한 CPU time 비율을 나눠준다는 점에서 ‘Fair’하다.
  - 최소한 목표 응답시간 n에 대해 n개 프로세스 까지는 공정성을 보장할 수 있다.

## 4.4 CFS 구현

### 시간 기록 (Time Accounting)

  - 모든 프로세스 스케줄러는 각 프로세스의 실행시간(the time that a process runs)을 기록해야 한다.
  - 시스템 클럭 1-tick이 지날 때마다 이 값은 1씩 감소하며, 0이 될 때 다른 프로세스에 의해 선점된다.
  - 각 프로세스(task)의 스케줄러 관련 정보는 `task_struct` 내에 `sched_entity` 구조체 타입 se 멤버변수에 저장된다. `sched_entity` 구조체 내부는 아래와 같이 구성되어있다.

    ```c
    struct sched_entity {
	/* For load-balancing: */
	struct load_weight		load;
	struct rb_node			run_node;
	u64				deadline;
	u64				min_deadline;

	struct list_head		group_node;
	unsigned int			on_rq;

	u64				exec_start;
	u64				sum_exec_runtime;
	u64				prev_sum_exec_runtime;
    // 가상실행시간, 프로세스가 실행한 시간을 정규화한 값이며 CFS는 실행 대기 프로세스 중 가상실행시간이 가장 낮은 프로세스를 다음 실행 프로세스로 선택한다.
	u64				vruntime; 
    ...
    }
    ```

- 프로세스의 실행시간은 `vruntime` 멤버변수에 저장된다.
- 이 변수의 갱신은 `kernel/sched_fair.c` 소스코드 내 `uptate_curr()` 함수에서 담당한다.
  - 이 함수는 시스템 타이머에 의해 주기적으로 호출된다.
  - now - `curr->exec_start`로 이전에 기록된 시간으로부터 현재 얼마나 지났는지 차이를 계산해 delta_exec에 저장한다.
  - vruntime을 갱신하기 위해 `__update_curr()` 함수를 호출한다.
- `__update_curr()` 함수에서는 `calc_delta_fair()` 함수를 호출해 현재 실행 중인 프로세스 개수를 고려해 가중치를 계산한 뒤 vruntime을 갱신한다.
- 위와 같은 방식으로 vruntime 값은 특정 프로세스의 실행시간을 정확하게 반영한다.

    ```c
    static void update_curr(struct cfs_rq *cfs_rq) { // 현재 함수의 실행시간을 계산에 delta_exec에 저장 
         struct sched_entity *curr = cfs_rq->curr;
         u64 now = rq_of(cfs_rq)->clock;
         unsigned long delta_exec;
 
         if (unlikely(!curr))
                 return;
 
         /*
          * Get the amount of time the current task was running
          * since the last time we changed load (this cannot
          * overflow on 32 bits):
          * 지난번 갱신 시점 이후 현재 작업이 실행된 시간을 구한다. (32bit를 넘을 수 없음)
          *
          */
         delta_exec = (unsigned long)(now - curr->exec_start);
         if (!delta_exec)
                 return;
 
 		/*
        * 계산된 실행값을 __update_curr함수에 전달한다,
        * __update_curr함수는 전체 실행중인 프로세스 갯수를 고려해 가중치를 계산한다.
        * 이 가중치 값을 추가하여 현재 프로세스의 vruntime에 저장한다.
        */
         __update_curr(cfs_rq, curr, delta_exec);  
         curr->exec_start = now;
 
         if (entity_is_task(curr)) {
                 struct task_struct *curtask = task_of(curr);
 
                 trace_sched_stat_runtime(curtask, delta_exec, curr->vruntime);
                 cpuacct_charge(curtask, delta_exec);
                 account_group_exec_runtime(curtask, delta_exec);
         }
    }
    ```
 
    ```c
    /* 현재 작업의 실행시간 통계를 갱신한다. 해당 스케줄링 클래스에 속하지 않는 작업은 무시한다. 
    * 시스템 타이머를 통해 주기적으로 실행되며, 프로세스가 실행 가능 상태로 바뀌거나 대기상태가 되어 실행이 중단되어도
    * 호출된다.
    */
    static inline void __update_curr(struct cfs_rq *cfs_rq, struct sched_entity *curr,
                   unsigned long delta_exec)
     {
             unsigned long delta_exec_weighted;
     
             schedstat_set(curr->exec_max, max((u64)delta_exec, curr->exec_max));
     
             curr->sum_exec_runtime += delta_exec;
             schedstat_add(cfs_rq, exec_clock, delta_exec);
             delta_exec_weighted = calc_delta_fair(delta_exec, curr);
     
             curr->vruntime += delta_exec_weighted;
             update_min_vruntime(cfs_rq);
     }
    ```

### 프로세스 선택

- CFS는 다음번에 실행될 프로세스를 결정할 때 ‘가장 낮은 비율로 CPU time을 실행한’ 프로세스로 결정한다, 즉 가장 낮은 vruntime을 가진 프로세스를 선택한다.
- CFS의 핵심은 매 context switching 시 실행 가능한 프로세스 중 가장 낮은 vruntime을 가진 프로세스를 찾아 선택하는 것이다.
- 빠른 탐색을 위해 self-balancing BST로 유명한 ​‘Red-Black Tree’ 자료구조를 사용​한다.

<img width="609" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/99225061-cf75-4c04-bb3a-455b42e27c41">

- 따라서 다음 작업을 선택할 때는 가장 왼쪽에 있는 node를 선택하면 된다.
```c
/**
*  CFS가 다음에 실행해야 할 프로세스를 반환하는 함수
*/
static struct sched_entity *__pick_next_entity(struct cfs_rq *cfs_rq)
 {
         struct rb_node *left = cfs_rq->rb_leftmost; 
         # rb_leftmost 캐시된 가장 왼쪽 노드 포인터
 
         if (!left)
                 return NULL;
 
         return rb_entry(left, struct sched_entity, run_node);
 }
```

### 스케줄러 진입 위치 (Scheduler Entry Point)

- 스케줄러의 main 함수는 `kernel/sched.c` 에 정의된 void `__sched schedule(void)` 함수다.
- 가장 우선순위가 높은 스케줄러 클래스의 가장 우선순위가 높은 프로세스를 찾아 다음 프로세스로 선택한다. 
- `schedule()` 함수 내부에서 `pick_next_task()` 함수를 호출한다.

```c
// https://github.com/torvalds/linux/blob/bee0e7762ad2c6025b9f5245c040fcc36ef2bde8/kernel/sched/core.c#L5983
/*
 * Pick up the highest-prio task:
 */
static inline struct task_struct *
__pick_next_task(struct rq *rq, struct task_struct *prev, struct rq_flags *rf)
{
	const struct sched_class *class;
	struct task_struct *p;

	/*
	 * Optimization: we know that if all tasks are in the fair class we can
	 * call that function directly, but only if the @prev task wasn't of a
	 * higher scheduling class, because otherwise those lose the
	 * opportunity to pull in more work from other CPUs.
	 */
	if (likely(!sched_class_above(prev->sched_class, &fair_sched_class) &&
		   rq->nr_running == rq->cfs.h_nr_running)) {

		p = pick_next_task_fair(rq, prev, rf);
		if (unlikely(p == RETRY_TASK))
			goto restart;

		/* Assume the next prioritized class is idle_sched_class */
		if (!p) {
			put_prev_task(rq, prev);
			p = pick_next_task_idle(rq);
		}

		return p;
	}

restart:
	put_prev_task_balance(rq, prev, rf);

	for_each_class(class) {
		p = class->pick_next_task(rq);
		if (p)
			return p;
	}

	BUG(); /* The idle class should always have a runnable task. */
}
```

- if 문은 최적화를 위한 구문이다.
  - 일반적으로 프로세스는 CFS를 스케줄러 클래스로 사용하는 경우가 많다.
  - 즉, 현재 실행 중인 프로세스 개수와 CFS 스케줄러 클래스 사용 프로세스 개수가 동일할 가능성이 높다.
  - 이런 경우에는 CFS 스케줄러 클래스 내부에 정의된 `pick_next_task()` 함수를 실행하도록 한다.
  - 이 함수는 `kernel/sched_fair.c`에 `pick_next_task_fair()`에 정의되어있다.
  - CFS의 `pick_next_task()`는 `pick_next_entity()`를 호출하고 이어서 `__pick_next_entity()`를 호출한다. 
  - for 문은 가장 우선순위가 높은 스케줄러 클래스의 가장 우선순위가 높은 프로세스를 찾는다.
  - 가장 높은 우선순위부터 돌아가며 스케줄러 클래스 내 `pick_next_task()` 함수를 호출한다.

### Sleeping and Waking Up

- 프로세스가 sleep 또는 block 상태로 들어간 데에는 여러 가지 이유가 있지만, 커널 동작은 같다. 
  1. 프로세스는 자신의 state가 ‘대기 상태’(`TASK_(UN)INTERRUPTIBLE`)임을 표시한다.
  2. CFS 스케줄러 클래스의 RBTree에서 자기 자신을 제거한다.
  3. `schedule()` 함수를 호출해 새 프로세스를 선택해 실행한다.

- 이러한 프로세스들은 ‘Wait Queue(대기열)’에 들어가서 특정 조건이 발생하기를 기다린다.

```c
// https://github.com/torvalds/linux/blob/bee0e7762ad2c6025b9f5245c040fcc36ef2bde8/include/linux/wait.h#L40
struct wait_queue_head {
	spinlock_t		lock;
	struct list_head	head;
};
typedef struct wait_queue_head wait_queue_head_t;
```

- 대기열은 `<linux/wait.h>` 헤더파일에 `wait_queue_head_t` 구조체로 표현한다.
  - 대기열은 `DECLARE_WAITQUEUE()` 매크로를 이용해 정적으로 만들 수 있다.

```c
// https://github.com/torvalds/linux/blob/bee0e7762ad2c6025b9f5245c040fcc36ef2bde8/include/linux/wait.h#L48
#define __WAITQUEUE_INITIALIZER(name, tsk) {					\
	.private	= tsk,							\
	.func		= default_wake_function,				\
	.entry		= { NULL, NULL } }

#define DECLARE_WAITQUEUE(name, tsk)						\
	struct wait_queue_entry name = __WAITQUEUE_INITIALIZER(name, tsk)

```

- 대기열은 `init_waitqueue_head()` 함수를 이용해 동적으로 만들 수도 있다.

```c
// https://github.com/torvalds/linux/blob/bee0e7762ad2c6025b9f5245c040fcc36ef2bde8/kernel/sched/wait.c#L8
#define init_waitqueue_head(wq_head)						\
	do {									\
		static struct lock_class_key __key;				\
										\
		__init_waitqueue_head((wq_head), #wq_head, &__key);		\
	} while (0)
```

- [주의] Sleep과 wake는 동일 프로세스에 대한 일종의 경쟁상태(race condition)를 유발할 위험이 있다.
  - 특정 단발성 wake 조건을 기다리는 프로세스가 sleep에 들어가기 전에 해당 조건이 발생했다면? 해당 sleep 프로세스는 영원히 wake 할 일이 없을 것이다.
  - 따라서 아래와 같은 과정으로 sleep-wake을 처리할 것을 권장한다.

        ```c
        add_wait_queue(q, &wait); 
        while (!condition) {
            prepare_to_wait(&q, &wait, TASK_INTERRUPTIBLE); 
            if (signal_pending(current)) {
                    /* handle signal */ 
            }
            schedule();
        }
        finish_wait(&q, &wait);
        ```

        1. `add_wait_queue()` 를 이용해 프로세스를 대기열에 추가한다.

        2. `prepare_to_wait()` 함수는 프로세스의 state를 `TASK_INTERRUPTIBLE`로 변경한다.

        3. `schedule()` 함수는 다른 프로세스가 먼저 실행되도록 해준다.

        4. 원하는 wake-up 조건이 발생했다면, while-loop를 빠져나와 state를 `TASK_RUNNING`으로 변경하고 `fininsh_wait()` 함수를 호출해 대기열에서 프로세스를 제거한다.

  - 위와 같은 구조에서는 sleep 전 wake-up condition이 먼저 발생하더라도 기능에만 문제가 생기게 되고, 해당 프로세스가 영원히 sleep 상태에 빠질 위험은 예방할 수 있다.

### 4.5 Context switching

- `schedule()` 함수는 다음에 실행될 프로세스를 결정한 뒤 `<kernel/sched.c>`에 정의된 `context_switch()` 함수를 호출한다.
  - `context_switch()` 함수는 `<asm/mmu_context.h>`에 정의된 `switch_mm_irqs_off()` 함수를 호출한다. 이 함수는 CPU의 메모리 관련 레지스터를 masking 해서 가상메모리 매핑을 새로운 프로세스로 변경한다.
  - `context_switch()` 함수는 `<asm/system.h>`에 정의된 `switch_to()` 함수를 호출한다. 이 함수는 인라인 어셈블리를 이용해서 현재 프로세스의 TCB(Task Control Block)를 저장하고, 다음 프로세스의 TCB를 복원한다.

```c
// https://github.com/torvalds/linux/blob/bee0e7762ad2c6025b9f5245c040fcc36ef2bde8/kernel/sched/core.c#L5320
/*
 * context_switch - switch to the new MM and the new thread's register state.
 */
static __always_inline struct rq *
context_switch(struct rq *rq, struct task_struct *prev,
	       struct task_struct *next, struct rq_flags *rf) {
	prepare_task_switch(rq, prev, next);

	/*
	 * For paravirt, this is coupled with an exit in switch_to to
	 * combine the page table reload and the switch backend into
	 * one hypercall.
	 */
	arch_start_context_switch(prev);

	/*
	 * kernel -> kernel   lazy + transfer active
	 *   user -> kernel   lazy + mmgrab_lazy_tlb() active
	 *
	 * kernel ->   user   switch + mmdrop_lazy_tlb() active
	 *   user ->   user   switch
	 *
	 * switch_mm_cid() needs to be updated if the barriers provided
	 * by context_switch() are modified.
	 */
	if (!next->mm) {                                // to kernel
		enter_lazy_tlb(prev->active_mm, next);

		next->active_mm = prev->active_mm;
		if (prev->mm)                           // from user
			mmgrab_lazy_tlb(prev->active_mm);
		else
			prev->active_mm = NULL;
	} else {                                        // to user
		membarrier_switch_mm(rq, prev->active_mm, next->mm);
		/*
		 * sys_membarrier() requires an smp_mb() between setting
		 * rq->curr / membarrier_switch_mm() and returning to userspace.
		 *
		 * The below provides this either through switch_mm(), or in
		 * case 'prev->active_mm == next->mm' through
		 * finish_task_switch()'s mmdrop().
		 */
		switch_mm_irqs_off(prev->active_mm, next->mm, next);
		lru_gen_use_mm(next->mm);

		if (!prev->mm) {                        // from kernel
			/* will mmdrop_lazy_tlb() in finish_task_switch(). */
			rq->prev_mm = prev->active_mm;
			prev->active_mm = NULL;
		}
	}

	/* switch_mm_cid() requires the memory barriers above. */
	switch_mm_cid(rq, prev, next);

	prepare_lock_switch(rq, next, rf);

	/* Here we just switch the register state and the stack. */
	switch_to(prev, next, prev);
	barrier();

	return finish_task_switch(prev);
}
```

- 커널은 `need_resched` 플래그를 이용해서 언제 스케줄링이 필요한지 판단한다.
- 사용자 공간으로 돌아가거나, 인터럽트 처리를 마칠 때마다 커널은 `need_resched` 플래그를 확인한다. 설정되어있다면 `schedule()` 함수를 호출해 최대한 빨리 새 프로세스로 전환한다.
- `need_resched` 플래그는 각 프로세스의 task_struct 속 thread_info 속 flags 멤버변수에 포함되며 `TIF_NEED_RESCHED` 라는 이름으로 선언되어있다.

```c
// https://github.com/torvalds/linux/blob/bee0e7762ad2c6025b9f5245c040fcc36ef2bde8/include/linux/sched.h#L2261
static __always_inline bool need_resched(void) {
	return unlikely(tif_need_resched());
}
```

- need_resched 플래그는 각 프로세스의 task_struct 속 thread_info 속 flags 멤버변수에 포함되며 `TIF_NEED_RESCHED` 라는 이름으로 선언되어있다.

### ​4.6 선점

- 리눅스 커널은 2.6 버전 이상부터 사용자 공간 뿐만 아니라, 커널도 선점될 수 있는 ‘완전 선점형’이다.
- 실행 중인 작업이 lock 돼있지 않다면 커널은 언제나 선점될 수 있다.
- `thread_info` 구조체에는 `preemp_count` 라는 멤버변수가 있다. 이 변수는 프로세스가 lock을 설정 할 때마다 1 증가하고 lock을 해제할 때마다 1 감소한다.
- 즉, 해당 프로세스의 `preemp_count`가 0이면, 해당 프로세스는 선점 가능한 상태라고 판단한다.
- 정리하자면, 커널은 need_resched 플래그 활성화 + 현재 프로세스의 preemp_count == 0일 경우 더 우선순위가 높은 프로세스를 찾은 뒤 선점을 허용하고 `schedule() -> context_switch()` 함수를 호출한다.

​### 4.7 실시간 스케줄링 정책

- 리눅스 커널은 FIFO와 Round-robin 두 가지 실시간 스캐줄링 정책으로 soft 실시간성을 제공한다.
- 실시간 프로세스는 일반 프로세스보다 우선순위가 높아 항상 먼저 실행​된다.
- 그러므로, 더 높은 우선순위 실시간 프로세스가 없다면, 양보 없이 무한히 계속 실행될 수도 있다.
- 반면, Round-robin 정책(SCHED_RR)은 정해진 `timeslice` 만큼만 실행된 뒤, 우선순위가 같은 다른 실시간 프로세스를 돌아가며 실행한다.
- 리눅스의 실시간 우선순위는 `task_struct`의 `rt_priority` 멤버변수에 저장하며, `0 ~ MAX_RT_PRIO-1` 사이의 값을 가지며, 기본값은 0 ~ 99다.

# 5. System Calls

- 커널은 시스템콜의 일관성, 유연성, 이식성​ 3가지를 확보하는 것을 최우선 사항으로 생각하고 있다.

- 따라서 커널은 POSIX 표준에 따라 표준 C 라이브러리 형태로 시스템콜을 제공한다.

- 리눅스 커널에서 시스템콜은 네 가지 역할을 수행한다.
  1. 사용자 공간에 HW 인터페이스를 추상화된 형태로 제공한다.
  2. 시스템에 보안성 및 안정성을 제공한다.
  3. 인터럽트(및 트랩)와 함께 커널에 접근할 수 있는 유일한 수단이다.
  4. 사용자 공간과 기타 공간을 분리해 프로세스별 가상환경(가상메모리, 멀티태스킹 등)을 제공한다.

- 리눅스의 시스템콜은 다른 OS보다 상대적으로 갯수가 적고 수행속도가 빠르다.
  - 리눅스는 시스템콜 핸들러 호출 흐름이 간단하기 때문이다.
  - 리눅스는 context switching 속도가 빠르기 때문이다.

- 리눅스의 시스템콜은 아래 파일에 정의되어있다.

  - `include/linux/syscalls.h`: 시스템콜 선언부

  - `kernel/sys.c`: 시스템콜 구현부

- 간단한 시스템콜 예시인 `getpid()`의 구현을 통해 조금 더 내용을 알아보자.

    ```c
    #define SYSCALL_DEFINE0(name)	   asmlinkage long sys_##name(void)
    SYSCALL_DEFINE0(getpid)    // asmlinkage long sys_getpid(void);
    {
        return task_tgid_vnr(current); // return current->tgid
    }
    ```

    - `getpid()` 함수는 인자를 갖지 않기 때문에 맨 끝 숫자로 0이 붙은 SYSCALL_DEFINE매크로를 사용한다.

    - asmlinkage 지시자는 함수의 인자를 프로세스 스택 메모리에서 찾을 것을 컴파일러에게 명령한다.

    - 반환형이 long인 이유는 32-bit와 64-bit 시스템 사이의 호환성을 유지하기 위함이다.

    - 모든 리눅스 시스템콜은 sys_ 라는 접두사를 명명규칙으로 따른다.

- 커널은 시스템콜을 ‘시스템콜 번호’라는 고유번호로 식별한다. 
  - 시스템콜 번호는 한 번 할당 시 변경할 수 없다.
  - 한 번 할당된 시스템콜 번호는 대응하는 시스템콜이 제거된 후라도 재사용하지 않는다.
  - 모든 시스템콜 번호와 그 핸들러는 sys_call_table 이라는 상수 함수포인터 배열에 아키텍처별로 정의되어있다. (i.e. `x86은 arch/x86/kernel/syscall64.c`)

- 커널이 시스템콜을 처리할 때는 ‘프로세스 컨텍스트’라는 특수한 컨텍스트에 진입한다.

  - 프로세스 컨텍스트에서 커널과 특정 프로세스는 같은 컨텍스트로 묶여 있는 상황이다. 
  - 실행은 커널이 하고 있지만, current 매크로는 여전히 특정 프로세스를 가리키고 있다.
  - 실행은 커널이 하고 있지만, 여전히 sleep 가능하고 선점도 가능한 상태​다.

- 사용자 애플리케이션이 시스템콜을 호출 했을 때,
  1. 대응하는 시스템콜을 호출 + 특정 레지스터에 시스템콜 번호 기록 → SW 인터럽트를 발생시킴.
  2. 커널이 시스템을 커널 모드로 전환함.
  3. `system_call()` 함수 호출 → 레지스터값이 유효한 시스템콜 번호인지 확인함.
  4. sys_call_table의 시스템콜 번호 인덱스의 함수를 호출해 적절한 핸들러를 호출함.

- 이때 시스템콜의 매개변수는 레지스터를 통해 전달한다. (i.e. ARM의 R0~R3, x86의 ebx~edx, esi, edi)
- 사용자는 직접 시스템콜을 구현할 수도 있다. (하지만, 절대 권장하지 않는다.)

- **시스템콜을 설계할 때 반드시 고려해야 하는 점**
  - 해당 시스템콜이 수행할 정확한 하나의 목적을 정의할 것
  - 해당 시스템콜의 인자, 반환값, 오류코드를 정의할 것
  - 해당 시스템콜이 추후 새로운 기능을 추가할 여지가 있는지 생각할 것 (유연성)
  - 해당 시스템콜이 하위 호환성을 깨지 않고 버그를 쉽게 수정할 수 있는지 생각할 것 (호환성)
  - 해당 시스템콜이 특정 아키텍처의 워드나 엔디안을 가정하고 만들지는 않았는지 점검할 것 (이식성)
- **시스템콜을 구현할 때 반드시 고려해야 하는 점**
  - 인자로 전달되는 포인터의 유효성을 확인할 것 
    - 포인터는 사용자 공간의 메모리 영역을 가리켜야 한다.
    - 포인터는 프로세스 주소 공간의 메모리 영역을 가리켜야 한다.
    - 해당 메모리 영역의 권한에 맞는 접근을 해야 한다.

  - 수행결과를 반드시 알맞는 방법으로 제공할 것 
    - 커널 영역의 수행 결과, 특히 포인터는 절대 사용자 공간으로 내보내선 안 된다.
    - `copy_to_user()` 또는 `copy_from_user()` 두 함수를 이용해서 안전하게 정보를 전달 및 제공받아야 한다.

- 사용자 시스템콜의 설계 및 구현이 완료됐다면 정식 시스템콜로 등록한다. 
  - entry.S 파일의 시스템콜 테이블 마지막에 새로운 시스템콜을 추가한다.
  - `asm/unistd.h` 헤더파일에 새로운 시스템콜 번호를 추가한다.
  - 새로운 시스템콜의 핸들러를 구현한다.
  - 커널을 재컴파일 한다.

# 7. 인터럽트

## 7.1 인터럽트 개요

- OS는 인터럽트를 구별하고 인터럽트가 발생한 HW를 식별 뒤 적절한 핸들러를 이용해 인터럽트를 처리한다. 
- 요점은 장치별로 특정 인터럽트가 지정되어있으며, 커널이 이 정보를 가지고 있다는 것이다.
- 인터럽트 처리를 위해 커널이 호출하는 함수를 인터럽트 핸들러 또는 인터럽트 서비스 루틴(ISR)라고 부른다.
- 인터럽트는 ‘인터럽트 컨텍스트’에서 실행되며 중간에 실행을 중단할 수 없다.
- 인터럽트는 언제라도 발생할 수 있고 그동안 원래 실행흐름은 중단되므로 최대한 빨리 인터럽트 핸들러를 처리하고 복귀하는 것이 중요하다. 따라서 인터럽트 핸들러 실행시간은 가능한 짧은 것이 중요하다. 
  - 하지만, 때로는 인터럽트 핸들러에서 처리해야 하는 작업이 많거나 복잡할 수 있다.
  - 이를 해결하기 위한 전략이 전반부 처리(top-half) + 후반부 처리(bottom-half)다.
    - 당장 실시간으로 빠르게 처리해야 하는 부분은 인터럽트 핸들러 내에서 처리를 하고,
    - 나중에 처리해도 되는 부분은 다른 프로세스로 따로 만들어 처리한다.

## 7.2 인터럽트 핸들러 등록

```c
// linux/interrupt.h
typedef irq_handler_t (*irq_handler_t)(int, void *);
int request_irq(unsigned int irq,
				irq_handler_t handler,
				unsigned long flags,
				const char* name,
				void* dev)
```

- 인터럽트 핸들러는 `<linux/interrupt.h>`의 `request_irq()` 함수를 통해 등록할 수 있다. 
    1. **irq** : IRQ 번호를 의미하며 보통 기본 페리페럴은 이 값이 하드코딩 되어있다. 다른 디바이스들은 탐색을 통해 동적으로 정해진다.
    2. **handler** : 인터럽트를 처리할 인터럽트 핸들러의 함수 포인터다.
    3. **flags** : 
       - `IRQF_DISABLED` : 인터럽트 핸들러를 실행하는 동안 모든 인터럽트를 비활성화한다.
       - `IRQF_SAMPLE_RANDOM` : 커널 내에 난수 발생기의 엔트로피에 이번 인터럽트 이벤트를 포함시킬지 여부를 결정한다. 포함한다면 조금 더 무작위인 난수가 생성될 것이다.
       - `IRQF_TIMER` : 이 핸들러가 시스템 타이머를 위한 인터럽트를 처리하는 핸들러임을 명시한다.
       - `IRQF_SHARED` : 이 핸들러가 여러 인터럽트가 공유하는 핸들러임을 명시한다.

    4. **name** : 개발자가 식별하기 위한 인터럽트 핸들러의 이름이다.
    5. **dev** : 같은 인터럽트를 사용하는 여러 핸들러 사이에서 특정 핸들러를 구별하기 위해 고유 쿠키값을 정의한다. 핸들러가 하나 뿐이라면 NULL을 사용해도 괜찮다.

- 등록에 성공하면 `request_irq()` 함수는 0을 반환한다.
- (참고) `requeset_irq()` 함수는 sleep 상태를 허용하는 함수다. 따라서 인터럽트 컨텍스트를 포함한 코드 실행이 중단돼서는 안 되는 상황에서는 호출할 수 없다. 내부적으로 `proc_mkdir()` → `proc_create()` → `kmalloc()` 함수를 호출하는데, 이 함수가 sleep이 가능하기 때문이다.
​
## 7.3 인터럽트 핸들러 구현 및 동작순서

<img width="570" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/892c596d-5b08-4a96-9de4-3aa5e4f4d869">

1. 디바이스는 bus를 통해 인터럽트 컨트롤러로 전기신호를 전송한다.
2. 인터럽트 컨트롤러는 프로세서의 특정 핀에 인터럽트를 건다.
3. 프로세서는 하던 동작을 중단하고 작업 내용(및 context)을 스택에 저장한다.
4. 미리 정해진 메모리 주소의 코드로 branch한다.
5. 현재 발동된 인터럽트 라인을 비활성화 중복 인터럽트 발생을 예방하고, 유효한 핸들러가 등록돼있는지, 사용가능한지, 현재 미실행 상태인지 확인한다.
6. `<kernel/irq/handler.c>`의 `handle_IRQ_event()`를 호출해 해당 인터럽트의 핸들러를 실행한다.
7. 핸들러 실행 후 복귀했다면 정리작업을 수행하고 `ret_from_intr()`로 이동한다. 이 함수는 3, 4번처럼 아키텍처 특화 어셈블리로 작성되어있으며, 대기 중인 스케줄링 작업 존재 여부 확인 후 `schedule()` 함수를 호출해 원래 실행흐름으로 복귀한다.

## 7.4 인터럽트 활성화/ 비활성화

- 인터럽트 제어 기능은 아키텍처 의존적이며 동기화를 위해 인터럽트를 비활성화해 선점을 막기 위해 사용한다.
- 보통 아래와 같은 구조를 가진다.

```c
local_irq_disable();
/* 인터럽트가 비활성화 된 상태! 
여기서 할일을 한다 ~~~ */
local_irq_enable();
```

- 또는 `void disable_irq(unsigned int irq)`, `void enable_irq(unsigned int irq)`로 특정 인터럽트를 마스킹하는 방법도 제공한다.

- 하지만, 이것만으로 완전한 동기화를 보장하지는 못한다. 리눅스는 SMP 환경을 지원하므로 여기에 몇 가지 잠금 장치를 더 추가해주어야 한다. 

## 7.5 인터럽트 후반부 처리 (Bottom-half)

- 어떤 일을 후반부로 지연시킬지 명확한 기준은 없지만, 실행시간에 민감하거나, 절대 선점되서는 안 되는 작업이 아니라면 후반부 처리로 넘길 것을 권장한다.

- 후반부 처리의 가장 큰 요점은 모든 인터럽트가 활성화 된 상태에서, 시스템이 덜 바쁜 미래의 어떤 시점에 인터럽트의 나머지 부분을 처리해 시스템의 throughput을 극대화할 수 있다는 점이다.

- 아랫부분에서 BH(Bottom-half), Softirq, Tasklet, WorkQueue 4가지 후반부 처리 기법에 대해서 알아볼 것이다. 결론부터 말하자면, 현재 2020년대에서는 주로 Threaded IRQ 또는 WorkQueue 2가지만 사용하고 나머지는 거의 사용하지 않는다. 리눅스 커널의 인터럽트 후반부 처리의 역사가 어떻게 발전했는지에 대해 알아보는 느낌으로 가볍게 살펴보도록 하자.

- **① BH**
  - 가장 먼저 만들어진 후반부 처리 기법으로, 정적으로 정의된 32개의 후반부 처리기가 존재했다.
  - 인터럽트 핸들러에서 32-bit 전역 변수의 bit를 조작해 나중에 실행할 후반부 처리기를 지정했다.
  - 서로 다른 프로세서가 두 개의 BH를 동시에 실행할 수 없었고, 유연성이 떨어졌고, 병목현상이 발생했다.
  - 성능이슈, 확장성 이슈, 이식성 이슈로 인해 더 이상 BH를 사용하기 어려워져 2.5버전 이후로 사라졌다.

- **② Softirq**
  - 모든 프로세서에서 동시에 사용할 수 있는 정적으로 정의된 후반부 처리기의 모음집이다.
  - 실행시간에 매우 민감하고 중요한 후반부 처리(i.e. 네트워크, Block I/O)를 해야 할 때 사용한다.
  - 같은 유형의 softirq가 다른 프로세서에서 동시에 실행될 수 있으므로 ​각별한 주의가 필요하다. 
    - softirq 핸들러에서 만일 공유변수를 사용한다면, 적절한 락이 필요하다는 뜻이다.
    - 하지만, 동시 실행을 막는다면, softirq를 사용하는 의미가 상당 부분 사라지기 때문에 tasklet을 사용하는 것이 낫다.
    - 꼭 softirq를 써야만 하는 이유가 반드시 있는 것이 아니라면, 거의 모든 경우 tasklet을 사용하는 것을 권장한다.

        ```c
        // https://github.com/torvalds/linux/blob/bee0e7762ad2c6025b9f5245c040fcc36ef2bde8/include/linux/interrupt.h#L588
        struct softirq_action
        {
            void	(*action)(struct softirq_action *);
        };
        ...
        // https://github.com/torvalds/linux/blob/bee0e7762ad2c6025b9f5245c040fcc36ef2bde8/kernel/softirq.c#L59static struct softirq_action softirq_vec[NR_SOFTIRQS] __cacheline_aligned_in_smp;
        DEFINE_PER_CPU(struct task_struct *, ksoftirqd);

        const char * const softirq_to_name[NR_SOFTIRQS] = {
            "HI", "TIMER", "NET_TX", "NET_RX", "BLOCK", "IRQ_POLL",
            "TASKLET", "SCHED", "HRTIMER", "RCU"
        };
        ```

  - Softirq는 `<linux/intrerrupt.h>`의 sortirq_action 구조체로 표현하며 관련 함수는 <kernel/softirq.c> 에 구현되어있다.
  - Softirq는 `<linux/interrupt.h>`에 열거형으로 우선순위 순으로 커널에 정적으로 등록되어있다.
  - Softirq의 핸들러는 `open_softirq()` 함수를 이용해서 런타임에 동적으로 등록할 수 있다. (`open_softirq(softirq 이름, my_softirq)`)
  - 등록한 핸들러는 `my_softirq->action(my_softirq)`와 같이 실행할 수 있는데, `softirq_action` 구조체에 데이터를 추가하더라도 softirq 핸들러 원형을 바꿀 필요가 없기 때문에 확장성이 좋아진다는 장점이 있다.
  - 등록된 softirq는 인터럽트 핸들러가 종료 전에 raise 해줘야 실행 가능하다. `raise_softirq`(softirq 이름) 함수를 사용해서 raise 할 수 있다.
  - 커널은 다음 번 softirq를 처리할 때 raise 되어있는 softirq를 먼저 확인하고, 대응하는 softirq 핸들러를 실행한다

  - Softirq를 도입할 때 한 가지 딜레마가 있었다.
    - 만일 softirq의 발생 빈도가 높아질 경우 유저 공간 애플리케이션이 프로세서 시간을 얻지 못하는 starvation 문제가 발생할 가능성이 있다.
    - 커널 개발자들은 softirq를 도입하기 위해서는 적절한 ‘타협’이 필요함을 깨달았다.
    - 각 프로세서마다 nice 값 +19 (가장 낮은 우선순위)를 갖는 특수한 커널 스레드 `ksoftirqd`를 하나씩 만들어둔다.
    - ksoftirqd 커널 스레드는 계속 루프를 돌면서 pending 중인 softirq가 발생할 때마다, 프로세서가 여유롭다면 바로바로 `do_softirq()` 함수를 호출해서 softirq를 처리한다. (그리고 사용자 애플리케이션을 방해하지도 않으며 꽤 괜찮은 성능도 보여줬다.)
    - ksoftirqd 커널 스레드는 루프 한 바퀴를 돌 때마다 `schedule()` 함수를 호출해서 더 중요한 프로세스를 먼저 실행한다.
    - ksoftirqd 커널 스레드가 실행할 softirq가 없다면 자신을 TASK_INTERRUPTIBLE 상태로 전환해 softirq가 발생할 때 깨어난다.
​
- **③ Tasklet**
  - Softirq 기반으로 만들어진 동적 후반부 처리 방식이다. (Task와는 아무런 관련 없다) 
  - 네트워크처럼 성능이 아주 중요한 경우에만 softirq를 사용하고 대부분의 후반부 처리는 tasklet을 사용하면 충분하다.
  - 같은 유형의 tasklet은 서로 다른 프로세서에서 동시 실행 불가능하다.
  - Softirq 보다 사용법이 간단하고 lock 사용 제한이 유연하다.

    ```c
    // https://github.com/torvalds/linux/blob/bee0e7762ad2c6025b9f5245c040fcc36ef2bde8/include/linux/wait.h#L40
    struct tasklet_struct {
        struct tasklet_struct *next; // 다음 tasklet
        unsigned long state; // 현재 tasklet의 상태
        atomic_t count; // 참조 횟수
        bool use_callback; // 콜백 사용 여부
        union {
            void (*func)(unsigned long data); // 핸들러 함수
            void (*callback)(struct tasklet_struct *t); // 핸들러 함수 콜백
        };
        unsigned long data; // 핸들러 함수의 인자
    };
    ```

  - `<linux/interrupt.h>` 헤더파일의 `tasklet_struct` 구조체로 표현한다.
    - state는 0, `TASKLET_STATE_SCHED`(실행 대기 중), `TASKLET_STATE_RUN`(실행 중) 세 가지 중 한 가지를 가진다.
    - count는 현재 태스크릿의 참조 횟수를 뜻하며, 0이 아니면 태스크릿은 비활성화, 0이면 태스크릿은 활성화 상태다.
  - Softirq와 마찬가지로, 활성화 되기 위해서는 raising 돼야 하는데, 이를 ‘태스크릿 스케줄링’ 이라고 표현한다.

    ```c
    static void __tasklet_schedule_common(struct tasklet_struct *t,
                        struct tasklet_head __percpu *headp,
                        unsigned int softirq_nr)
    {
        struct tasklet_head *head;
        unsigned long flags;

        local_irq_save(flags);
        head = this_cpu_ptr(headp);
        t->next = NULL;
        *head->tail = t;
        head->tail = &(t->next);
        raise_softirq_irqoff(softirq_nr);
        local_irq_restore(flags);
    }
    ```

  - 태스크릿 스케줄링은 <kernel/softrq.c> 파일에 구현되어있고 `tasklet_schedule()` 함수에서 처리한다.
    - 태스크릿의 상태가 `TASKLET_STATE_SCHED` 라면, `__tasklet_schedule()` 함수는 호출한다.
    - 현재 IRQ(인터럽트) 상태를 저장하고, 태스크릿을 현재 프로세서의 `tasklet_vec` 또는 `tasklet_hi_vec` 배열의 가장 뒤에 추가한다.
    - `raise_softirq_irqoff()` 함수로 softirq를 raise해서 `do_softirq()` 함수가 태스크릿을 처리하도록 만든다. (바로 이 부분에서 태스크릿이 softirq 기반으로 만들어졌음을 알 수 있다.)
  - 태스크릿이 스케줄링(활성화) 됐으니 이제 태스크릿이 핸들러 함수를 호출하고 처리되는 과정을 알아보자.

    ```c
    static __latent_entropy void tasklet_action(struct softirq_action *a)
    {
        tasklet_action_common(a, this_cpu_ptr(&tasklet_vec), TASKLET_SOFTIRQ);
    }
    ```

    ```c
    static void tasklet_action_common(struct softirq_action *a,
                    struct tasklet_head *tl_head,
                    unsigned int softirq_nr)
    {
        struct tasklet_struct *list;

        local_irq_disable();
        list = tl_head->head;
        tl_head->head = NULL;
        tl_head->tail = &tl_head->head;
        local_irq_enable();

        while (list) {
            struct tasklet_struct *t = list;

            list = list->next;

            if (tasklet_trylock(t)) {
                if (!atomic_read(&t->count)) {
                    if (tasklet_clear_sched(t)) {
                        if (t->use_callback) {
                            trace_tasklet_entry(t, t->callback);
                            t->callback(t);
                            trace_tasklet_exit(t, t->callback);
                        } else {
                            trace_tasklet_entry(t, t->func);
                            t->func(t->data);
                            trace_tasklet_exit(t, t->func);
                        }
                    }
                    tasklet_unlock(t);
                    continue;
                }
                tasklet_unlock(t);
            }

            local_irq_disable();
            t->next = NULL;
            *tl_head->tail = t;
            tl_head->tail = &t->next;
            __raise_softirq_irqoff(softirq_nr);
            local_irq_enable();
        }
    }
    ```

  - 태스크릿 핸들러 함수는 `<kernel/softirq.c>` 파일의 `tasklet_action()` 함수에서 처리한다.

  - 인터럽트 비활성화 후, 현재 프로세서의 `tasklet_vec` 또는 `tasklet_hi_vec` 배열을 copy 해온 뒤 NULL로 초기화하고, 인터럽트를 활성화 한다.

  - 다시 한 번 태스크릿의 상태가 `TASKLET_STATE_SCHED` 임을 확인한 뒤 핸들러를 호출해 실행한다.

  - 배열에 더 이상 대기 중인 태스크릿이 없을 때까지 반복문을 돌면서 핸들러를 호출한다.

- **④ WorkQueue**

  - 워크큐는 softirq, 태스크릿과 달리, 후반부 처리를 커널 스레드 형태로 프로세스 컨텍스트 내에서 처리한다.
  - 워크큐는 스케줄링이 가능하고, 인터럽트가 활성화 된 상태이고, 선점될 수 있고, sleep 상태로 전환될 수 있다.
  - 워크큐는 엄연히 커널 스레드이므로 사용자 공간 프로세스 메모리 영역을 접근할 수 없다.
  - 따라서 워크큐는 대용량 메모리 할당/ 세마포어 관련 작업/ 블록 I/O에 적합하다.
  - 사용 편의성 측면에서 워크큐가 가장 좋다.
  - 워크큐의 전체적인 구조는 아래와 같다. (`<kernel/workqueue.c>` 파일, `<linux/workqueue.h>` 파일 참고)

    <img width="454" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/4bd0869d-ebd5-4dda-ac07-6688aab3732a">

    - 리눅스 커널은 프로세서별로 ‘작업 스레드’라는 events/n 이란 이름의 특별한 커널 스레드를 하나씩 가지고 있다.
    - 작업 스레드는 여러 작업 유형으로 나뉘며, 각 작업 유형마다 하나의 `workqueue_struct` 구조체로 표현한다.
    - 사용자가 원한다면 특정 작업 유형에 작업 스레드를 추가할 수 있으며, 작업 스레드는 `cpu_workqueue_struct` 구조체로 표현한다.
    - 후반부 처리 할 작업은 `work_struct` 구조체로 표현한다.
  - 모든 작업 스레드는 `worker_thread()` 라는 함수를 실행한다.

    ```c
    // https://github.com/torvalds/linux/blob/9ace34a8e446c1a566f3b0a3e0c4c483987e39a6/kernel/workqueue.c#L2726
    /**
    * worker_thread - the worker thread function
    * @__worker: self
    *
    * The worker thread function.  All workers belong to a worker_pool -
    * either a per-cpu one or dynamic unbound one.  These workers process all
    * work items regardless of their specific target workqueue.  The only
    * exception is work items which belong to workqueues with a rescuer which
    * will be explained in rescuer_thread().
    *
    * Return: 0
    */
    static int worker_thread(void *__worker)
    {
      struct worker *worker = __worker;
      struct worker_pool *pool = worker->pool;

      /* tell the scheduler that this is a workqueue worker */
      set_pf_worker(true);
    woke_up:
      raw_spin_lock_irq(&pool->lock);

      /* am I supposed to die? */
      if (unlikely(worker->flags & WORKER_DIE)) {
        raw_spin_unlock_irq(&pool->lock);
        set_pf_worker(false);

        set_task_comm(worker->task, "kworker/dying");
        ida_free(&pool->worker_ida, worker->id);
        worker_detach_from_pool(worker);
        WARN_ON_ONCE(!list_empty(&worker->entry));
        kfree(worker);
        return 0;
      }

      worker_leave_idle(worker);
    recheck:
      /* no more worker necessary? */
      if (!need_more_worker(pool))
        goto sleep;

      /* do we need to manage? */
      if (unlikely(!may_start_working(pool)) && manage_workers(worker))
        goto recheck;

      /*
      * ->scheduled list can only be filled while a worker is
      * preparing to process a work or actually processing it.
      * Make sure nobody diddled with it while I was sleeping.
      */
      WARN_ON_ONCE(!list_empty(&worker->scheduled));

      /*
      * Finish PREP stage.  We're guaranteed to have at least one idle
      * worker or that someone else has already assumed the manager
      * role.  This is where @worker starts participating in concurrency
      * management if applicable and concurrency management is restored
      * after being rebound.  See rebind_workers() for details.
      */
      worker_clr_flags(worker, WORKER_PREP | WORKER_REBOUND);

      do {
        // pool에서 worker를 찾아서, 실행할 work가 있는 동안 동작을 계속한다.
        struct work_struct *work =
          list_first_entry(&pool->worklist,
              struct work_struct, entry);

        if (assign_work(work, worker, NULL)) 
          process_scheduled_works(worker);
      } while (keep_working(pool));

      worker_set_flags(worker, WORKER_PREP);
    sleep:
      /*
      * pool->lock is held and there's no work to process and no need to
      * manage, sleep.  Workers are woken up only while holding
      * pool->lock or from local cpu, so setting the current state
      * before releasing pool->lock is enough to prevent losing any
      * event.
      */
      worker_enter_idle(worker);
      __set_current_state(TASK_IDLE);
      raw_spin_unlock_irq(&pool->lock);
      schedule(); // 작업이 없는 worker는 스케줄러에 의해 다시 깨어나 작업을 기다리게 된다.
      goto woke_up;
    }
    ```
  - `worker_thread()`에서는 `raw_spin_lock_irq()`와 `raw_spin_unlock_irq()` 함수를 사용하여 동기화를 유지하고, 여러 worker가 동시에 작업 목록에 접근하지 못하도록 한다.

- **워크큐 사용하기**
  - 새로운 작업 유형 작업 스레드 생성: `struct workqueue_struct *create_workqueue(const char* name)` 함수를 이용한다.
  - 정적 작업 생성: `DECLARE_WORK(name, void (*func)(void *), void *data);` 매크로를 사용한다.
  - 동적 작업 생성: 포인터를 이용해서 `work_struct` 구조체를 동적 생성한 뒤 `INIT_WORK(struct work_struct *work, void (*func) (void *), void *data);` 매크로를 사용해서 초기화한다.
  - 스케줄링: `schedule_work(&work);` 함수를 이용해서 작업 스레드를 깨우고 워크큐 핸들러를 실행한다. 
  - 만일 당장 실행하고 싶지 않다면, `schedule_delayed_word(&work, delay);` 함수로 원하는 시간 이후에 활성화 할 수도 있다.

# 9. 커널 동기화

## 9.1 Critical section과 Race condition

- 공유 메모리를 사용하는 애플리케이션을 개발할 때는 서로 다른 두 객체가 공유 자원에 동시에 접근하는 race condition을 반드시 막아야 한다.
- Critical section에 동시에 접근하는 것을 막기 위해서는 커널에서 제공하는 다양한 수단(원자적 연산, 스핀락, 세마포어) 원자적인(atomically) 접근을 보장해 race condition을 해소하는 동기화(synchronization)가 필요하다.
- 동기화의 기본적인 동작과정은 다음과 같다. 

1. 스레드 A와 B가 critical section에 접근하기 위해 락을 요청한다.
2. 스레드 A가 락을 휙득한다. 스레드 B는 무한루프(busy-waiting) 돌거나 sleep에 들어간다.
3. 스레드 A가 critical section을 처리한다.
4. 스레드 A가 락을 반환한다.
5. 스레드 B가 락을 휙득한다. 스레드 B가 critical section을 처리한다.

- 커널 동기화에는 두 가지를 반드시 염두해야 한다. 
  - 커널 동시성 문제가 발생하는 것을 막는 것보다 막아야 한다는 사실을 깨닫는 것이 훨씬 더 어려우므로 코드의 시작 단계부터 락을 설계해야 한다.
  - 락을 설정하는 대상은 ‘코드 블록’이 아니라 ‘데이터’다.

## 9.2 데드락 (Deadlock)

- 데드락은 실행 중인 2개 이상의 스레드와 2개 이상의 자원에 대해 발생하는 심각한 동기화 오류로, 각 스레드가 서로가 갖고 있는 자원을 기다리고 있지만, 모든 자원이 이미 점유된 상태라 옴싹달싹 못하는 상태를 말한다.
- 데드락을 예방하기 위해서는 3가지 규칙을 준수하자. 
  - 락이 중첩되는 경우 항상 같은 순서로 락을 얻고, 반대 순서로 락을 해제한다.
  - 같은 락을 두 번 얻지 않는다.
  - 락의 갯수나 복잡도 면에서 단순하게 설계한다.

## 9.3 동기화 수단 1: 원자적 연산

- 리눅스 커널은 지원하는 모든 아키텍처에 대해 원자적 정수 연산과 비트 연산을 제공한다.
- 원자적 연산은 이름 그대로 연산을 하는 동안 다른 프로세서, 프로세스, 스레드가 접근하지 못함을 보장한다.
- 원자적 연산은 int 대신 특별한 자료구조인 atomic_t를 사용한다. (`<linux/types.h>`에 정의) 
 1. 다른 자료형에 원자적 연산을 잘못 사용하는 것을 막을 수 있기 때문이다.
 2. 컴파일러가 개발자의 의도와 다르게 최적화하는 것을 막을 수 있기 때문이다.

- 대표적인 몇 가지 원자적 정수 연산 함수는 다음과 같다. (`<asm/atomic.h>`에 정의) 
  - `atomic_set(&var, num)`: atomic_t형 변수 var을 num으로 초기화한다.
  - `atomic_add(num, &var)`: var을 num을 더한다.
  - `atomic_inc(&var)`: var을 1 증가한다.
- 대표적인 몇 가지 원자적 비트 연산 함수는 다음과 같다. (<asm/bitops.h>에 정의) 
  - `test_and_set(int n, void *addr)`: 원자적으로 addr에서부터 n번째 bit를 set하고 이전 값을 반환한다.
  - `test_and_clear(int n, void *addr)`: 원자적으로 addr에서부터 n번째 bit를 clear하고 이전 값을 반환한다.
- 가능하면 복잡한 락 대신 간단한 원자적 연산을 사용하는 것이 성능 면에서 훨씬 좋다.

## 9.4 동기화 수단 2: 스핀락(Spin-lock)

- 간단한 원자적 연산만으로는 복잡한 상황에서는 충분한 보호를 제공할 수 없기 때문에 더 일반적인 동기화 방법인 ‘락’이 필요하다.
- ‘스핀락’이라는 이름대로 이미 사용 중인 락을 얻으려고 할 때 루프를 돌면서 (busy-wait) 기다린다.
- 스핀락은 프로세서 자원을 꽤 소모하므로 단기간만 사용해야 한다.

  ```c
  DEFINE_SPINLOCK(lock);

  // 1. process context 
  spin_lock(&lock);
  /***** critical section *****/
  spin_unlock(&lock);

  // 2. interrupt handler
  unsigned long flags;
  spin_lock_irqsave(&lock, flags);
  /***** critical section *****/
  spin_unlock_irqrestore(&lock, flags);
  ```
- 스핀락은 `<linux/spinlock.h>`과 `<asm/spinlock.h>`에 정의되어있다.
- 스핀락은 위와 같은 함수들을 사용해서 lock과 unlock을 하며 인터럽트 핸들러에서도 사용할 수 있다.
- 인터럽트 핸들러 버전은 데드락을 방지하기 위해 로컬 인터럽트를 비활성화하고 복원하는 과정을 포함한다.

## 9.5 동기화 수단 3: 세마포어(Semaphore)

- 이미 사용 중인 락을 얻으려고 시도할 때 busy-wait 하는 게 스핀락이라면, 세마포어는 sleep으로 진입한다.
- 무의미한 루프로 낭비하는 시간이 사라지니 프로세서 활용도가 높아지지만, 스핀락보다 부가 작업이 많다. 
  - Sleep 상태 전환, 대기큐 관리, wake-up 등 부가 작업을 처리하는 시간이 락 사용 시간보다 길 수 있기 때문에 오랫동안 락을 사용하는 경우에 적합하다.
  - Sleep 상태로 전환 되므로 인터럽트 컨텍스트에선 사용할 수 없다.
  - 세마포어를 사용할 때는 스핀락이 걸려있으면 안 된다.
  
- 세마포어는 동시에 여러 스레드가 같은 락을 얻을 수 있도록 사용 카운트를 설정할 수 있다.
- 0과 1로 이루어져 있다면 바이너리 세마포어 또는 뮤텍스(mutex), 그 외는 카운팅 세마포어라 부른다.


  ```c
  struct semaphore sema;
  sema_init(&sema, count);    // 동적으로 세마포어 생성
  init_MUTEX(&sema);          // 동적으로 뮤텍스 생성

  // 세마포어(뮤텍스) 휙득 시도
  if (down_interruptible(&sema)) {
      ...
  }
  /***** Critical Section *****/
  up(&sema);    // 세마포어(뮤텍스) 반환
  ```
- 주로 사용하는 세마포어 관련 함수는 위와 같다.
- 특히 `down()` 함수 보다는 `down_interruptible()` 함수를 많이 사용하는 것에 주목하자.
- 세마포어(뮤텍스)를 얻을 수 없을 때 sleep에 진입할 때 프로세스 상태는 `TASK_INTERRUPTIBLE` 또는 `TASK_UNINTERRUPTIBLE`로 들어갈탠데, 당연히 나중에 세마포어를 휙득할 수 있을 때 깨어나야 하므로 후자를 더 많이 사용한다.

## 9.6 동기화 수단 4: 뮤텍스(Mutex)

- 2.6 커널부터 ‘뮤텍스’는 상호 배제성을 가진 특정 락으로 구현됐다.

  ```c
  DEFINE_MUTEX(mu);
  mutex_init(&mu);
  mutex_lock(&mu);
  /* Critical section */
  mutex_unlock(&mu);
  ```
- 이 뮤텍스는 바이너리 세마포어와 유사하게 동작하지만, 인터페이스가 더 간단하고, 성능도 더 좋다.
- 뮤텍스를 사용할 수 없는 어쩔 수 없는 경우가 아니라면, 세마포어보다는 새로운 뮤텍스를 사용하는 것이 좋다.


## 9.7 동기화 수단 비교

|요구사항|권장사항|
|-|-|
|락 사용시간이 짧은 경우|스핀락 추천|
|락 사용시간이 긴 경우|뮤텍스 추천|
|인터럽트 컨텍스트에서 락을 사용하는 경우|반드시 스핀락 사용|
|락을 얻은 상태에서 sleep 할 필요가 있는 경우|반드시 뮤텍스 사용|

## 9.8 선점 비활성화 & 배리어

- 리눅스 커널은 선점형 커널이므로 프로세스는 언제라도 선점될 수 있고 동시성 문제의 원인이 되기도 한다.
- 또한, SMP 환경에서는 프로세서별 변수가 아닌 이상 다른 프로세서가 동시적으로 접근할 수 있다.
- 따라서, 커널은 `preempt_disable()`, `preempt_enable()` 함수로 선점 카운터를 제어한다.
- 더 깔끔하고 자주 사용하는 방법으로 `get_cpu()` 함수를 사용하기도 한다. 프로세서 번호를 반환하면서 커널 선점을 비활성화 한다. 대응하는 함수는 `put_cpu()` 함수를 사용하면 커널 선점이 활성화된다.
- 동시성 문제는 굉장히 예민한 문제이므로 반드시 개발자의 의도대로 동작하게끔 컴파일러에게 알려야 한다. **성능을 위해 임의로 순서를 바꾸지 말고 코드 순서대로 메모리 I/O가 진행하게끔 컴파일러에게 알리는 명령을 ‘배리어(Barrier)’**라고 한다.
- 커널은 `rmb()`(메모리 읽기 배리어), `wmb()`(메모리 쓰기 배리어), `barrier()`(읽기 쓰기 배리어)를 제공한다.
- 배리어 명령, 특히 마지막 `barrier()` 명령은 다른 메모리 배리어에 비해 거의 코스트가 없고 상당히 가볍다.

# 11. 타이머 & 시간 관리

## 11.1 기본 개념

- 커널은 `<asm/param.h>` 헤더파일에 시스템 타이머의 진동수를 HZ라는 값에 저장한다.
- 일반적으로 HZ 값은 100 또는 1000으로 설정돼있고, 커널 2.5 버전부터 ​기본값이 1000으로 상향됐다. 
  - 장점: 타이머 인터럽트의 해상도와 정확도가 향상돼 더 정확한 프로세스 선점이 가능해졌다.
  - 단점: 타이머 인터럽트 처리에 더 많은 시간을 소모하고, 전력 소모가 늘어난다.
  - 실험결과 시스템 타이머를 1,000Hz로 변경해도 성능을 크게 해치지 않는다는 결론이 났다.
- `<linux/jiffies.h>`에 jiffies 라는 전역변수에는 시스템 시작 이후 발생한 틱 횟수가 저장된다. 
- 타이머 인터럽트가 초당 HZ회 발생하므로 jiffies는 1초에 HZ만큼 증가한다.
- 따라서 시스템 가동 시간은 **jiffies / HZ** 로 계산할 수 있다.
- 32-bit 시스템에선 unsigned long 형인 jiffies는 HZ 100에선 497일, 1,000에선 50일이면 오버플로우가 발생한다.
- 반면에, 64-bit 시스템에선 평생 발생하지 않는다. 
  - 이 문제를 해결하기 위해 32-bit 시스템에서는 `extern u64 jiffies_64` 라는 변수를 만들고
  - 주 커널 이미지 링커 스크립트에 jiffies = jiffies_64라고 써서 두 변수를 겹쳐버린다.
  - 이러면 jiffies 변수는 32-bit 시스템에서도 오버플로우가 발생하지 않는다.
- jiffies는 오버플로우일 때 다시 0으로 돌아간다.
- 서로 다른 두 jiffies값을 올바르게 비교할 수 있도록 매크로 함수를 제공하고 있다. 
  - `#define time_after(a, b) ((long)(b) - (long)(a) < 0)`
  - `#define time_before(a, b) ((long)(a) - (long)(b) < 0)`
  - 보통 a는 현재 jiffies값이, b는 비교하려는 값이 들어간다.

## ​11.2 타이머 인터럽트

- 타이머 인터럽트는 최소한 다음 과정을 처리한다. 

1. xtime_lock 락을 얻어 xtime, jiffies 변수에 안전하게 접근한다.
2. 아키텍처 종속적인 `tick_periodic()` 함수를 호출한다.
3. jiffies 값을 1 증가, xtime에 현재 시간을 갱신한다.
4. 설정 시간이 만료된 동적 타이머의 핸들러를 실행한다.

```c
// https://github.com/torvalds/linux/blob/f2e8a57ee9036c7d5443382b6c3c09b51a92ec7e/kernel/time/tick-common.c#L82C1-L102C2
/*
 * Periodic tick
 */
static void tick_periodic(int cpu)
{
	if (tick_do_timer_cpu == cpu) {
		raw_spin_lock(&jiffies_lock);
		write_seqcount_begin(&jiffies_seq);

		/* Keep track of the next tick event */
		tick_next_period = ktime_add_ns(tick_next_period, TICK_NSEC);

		do_timer(1);
		write_seqcount_end(&jiffies_seq);
		raw_spin_unlock(&jiffies_lock);
		update_wall_time();
	}

	update_process_times(user_mode(get_irq_regs()));
	profile_tick(CPU_PROFILING);
}

// https://github.com/torvalds/linux/blob/f2e8a57ee9036c7d5443382b6c3c09b51a92ec7e/kernel/time/timekeeping.c#L2289
void do_timer(unsigned long ticks)
{
	jiffies_64 += ticks;
	calc_global_load();
}

// https://github.com/torvalds/linux/blob/f2e8a57ee9036c7d5443382b6c3c09b51a92ec7e/kernel/time/timer.c#L2064
/*
 * Called from the timer interrupt handler to charge one tick to the current
 * process.  user_tick is 1 if the tick is user time, 0 for system.
 */
void update_process_times(int user_tick)
{
	struct task_struct *p = current;

	/* Note: this timer irq context must be accounted for as well. */
	account_process_tick(p, user_tick);
	run_local_timers();
	rcu_sched_clock_irq(user_tick);
#ifdef CONFIG_IRQ_WORK
	if (in_irq())
		irq_work_tick();
#endif
	scheduler_tick();
	if (IS_ENABLED(CONFIG_POSIX_TIMERS))
		run_posix_cpu_timers();
}
```

- 1/HZ 초마다 한 번씩 타이머 인터럽트가 발생해 `tick_periodic()` 핸들러가 호출된다.
- `do_timer()` 에서는 jiffies를 증가하고 시스템 내 여러 통계 변수를 갱신한다.
- `update_process_time()` 에서는 
  - `account_process_tick()` 함수에서 프로세서의 시간을 갱신한다.
  - `run_local_timers()` 함수에서 제한시간이 만료된 타이머들의 핸들러를 실행한다.
  - `schedule_tick()` 함수는 현재 프로세스의 타임슬라이스 값을 줄이고, 필요한 경우 need_sched 플래그를 설정해 스케줄링 여부를 결정한다.

## ​11.3 타이머

```c
// <linux/timer.h>
struct timer_list {
	struct list_head entry;
	unsigned long expires;
	void (*function)(unsigned long);
	unsigned long data;
	struct tvec_base *base;
};

struct timer_list my_timer;
// 1. 타이머를 생성하고 초기화한다.
init_timer(&my_timer);
my_timer.expires = jiffies + delay;
my_timer.data = 0;
my_timer.function = my_function;

// 2. 타이머를 활성화한다.
add_timer(&my_timer);
// 3. 타이머의 만료 시간을 갱신한다.
mod_timer(&my_timer, jiffies + new_delay);
// 4. 타이머를 제거한다.
del_timer(&my_timer);
```

- 커널 타이머는 초기화 작업 → 핸들러 설정 → 타이머 활성화로 사용하고 만료된 이후 자동으로 소멸된다.
- 타이머는 비동기적으로 실행되므로 race condition이 발생할 잠재적인 위험이 있다. 따라서 `del_timer()` 함수 보다는 조금 더 안전한 버전인 `del_timer_sync()` 함수를 사용하자.

## 11.4 작은 지연

- 간혹 커널 코드에서는 아주 짧지만 정확한 지연 시간이 필요한 경우가 있다.
- 커널의 `<linux/delay.h>`에는 jiffies 값을 사용하지 않고도 지연처리를 하는 `mdelay()`, `udelay()`, `ndelay()` 3가지 함수를 제공한다. 
  - 물론, 지연 하는 동안 시스템이 동작을 정지하므로 꼭 필요한 경우가 아니면 절대 쓰면 안 된다.
- 더 적당한 해결책은 `schedule_timeout()` 함수를 사용하는 것이다. 
  - 최소한 인자로 넘긴 지정한 시간만큼 해당 작업이 휴면 상태로 전환됨을 보장한다.
  - 당연하지만, 이 함수는 프로세스 컨텍스트에서만 사용할 수 있다.

# 12. 메모리 관리

## 12.1 페이지 (Page) & 구역 (Zone)

- 프로세서가 메모리에 접근할 때 가장 작은 단위는 byte 또는 word지만, MMU와 커널은 메모리 관리를 페이지 단위로 처리한다.
- 페이지 크기는 아키텍처 별로 다르며 보통 32-bit 시스템에선 4KB, 64-bit 시스템에선 8KB다.
- 커널은 하나의 페이지를 여러 구역(zone)으로 나눠 관리한다. (`<linux/mmzone.h>`에 정의) 
  - **ZONE_DMA**: DMA를 수행할 수 있는 메모리 구역
  - **ZONE_DMA32**: 32-bit 장치들만 DMA를 수행할 수 있는 메모리 구역
  - **ZONE_NORMAL**: 통상적인 페이지가 할당되는 메모리 구역
  - **ZONE_HIGHMEM**: 커널 주소 공간에 포함되지 않는 ‘상위 메모리’ 구역
- 메모리 구역의 실제 사용 방식과 배치는 아키텍처에 따라 다르며 없는 구역도 있다.

## 12.2. 페이지 할당 & 반환

- 커널은 메모리 할당을 위한 저수준 방법 1개 + 할당받은 메모리에 접근하는 몇 가지 인터페이스를 제공한다.
- 모두 `<linux/gfp.h>` 파일에 정의돼있으며 기본 단위는 ‘페이지’다.

  ```c
  // 방법 1 - alloc_pages
  struct page* alloc_pages(gfp_t gfp_mask, unsigned int order);
  // 방법 2 - __get_free_pages
  unsigned long __get_free_pages(gfp_t gfp_mask, unsigned int order);
  // 방법 3 - get_zeroed_page
  unsigned long get_zeroed_page(unsigned int gfp_mask, unsigned int order);
  ```

- 위 세 방법 중 하나를 선택해서 원하는 크기(2 * order 페이지)만큼 메모리를 할당받을 수 있다.
- 차이점은 반환값이다. 첫 번째 함수는 page 구조체를 얻을 수 있고, 두 번째 함수는 할당받은 첫 번째 페이지의 논리적 주소를 반환하며 마지막 함수는 0으로 초기화된 페이지를 얻을 수 있다.
- 특히, 커널 영역에서 메모리를 할당하는 것은 실패할 가능성이 있으며 반드시 오류를 검사하는 과정이 필요하다. 또한, 오류가 발생했다면 원위치 시켜야 하는 과정도 필요하다.
- 할당받은 페이지는 반드시 반환해야 하며, 할당받은 페이지만 반환해야 한다.
- 페이지 반환에는 `void __free_pages (struct page *page, unsigned int order);`를 사용한다.
- C의 `malloc()`과 `free()` 함수의 관계와 주의점을 생각하면 된다.
​
## 12.3 메모리 할당 (`kmalloc()`, `vmalloc()`)

- `kmalloc()`은 `gfp_mask` 플래그라는 추가 인자가 있다는 점을 제외하면 C의 `malloc()`과 비슷하게 동작한다.
- 즉, 바이트 단위로 메모리를 할당할 때 사용하며 커널에서도 메모리를 할당할 때 대부분 이 함수를 사용한다.
- `gfp_mask` 플래그는 동작 지정자, 구역 지정자로 나뉘며 둘을 조합한 형식 플래그도 제공된다. 
- 커널에서 자주 사용되는 대표적인 플래그는 아래와 같다.
  - **GFP_KERNEL**: 중단 가능한 프로세스 컨텍스트에서 사용하는 일반적인 메모리 할당 플래그다.
  - **GFP_ATOMIC**: 중단 불가능한 softirq, 태스크릿, 인터럽트 컨텍스트에서 사용하는 메모리 할당 플래그다.
  - **GFP_DMA**: ZONE_DMA 구역에서 할당 작업을 처리해야 할 경우 사용한다.
- 메모리를 해제할 때는 `<linux/slab.h>`에 정의된 `kfree()` 함수를 사용한다.
- `vmalloc()` 함수는 할당된 메모리가 물리적으로 연속됨을 보장하지 않는다는 것을 제외하면 `kmalloc()`과 동일하게 동작한다. 
  - 물리적으로 연속되지 않은 메모리를 연속된 가상 주소 공간으로 만들기 위해 상당량의 페이지 테이블을 조정하는 부가 작업이 필요하므로 `kmalloc()`의 성능이 훨씬 좋다.
  - 큰 영역의 메모리를 할당하는 경우에만 `vmalloc()`을 사용하자.
  - 메모리를 해제할 때는 `vfree()`를 사용한다.

## 12.4 슬랩 계층 (Slab layer)

- 사용이 빈번한 자료구조는 사용할 때마다 메모리를 할당하고 초기화하고 사용한 뒤 메모리를 반환하는 것보다 풀(pool) 방식을 사용하는 것이 성능면에서 효율적이다.
- 슬랩 계층은 자료구조를 위한 캐시 계층이며 사용 종료 시 메모리를 반환하지 않고 해제 리스트에 넣어두고 다음 번에 재활용한다.
- 슬랩의 크기는 페이지 1개 크기와 같고, 1개 슬랩에는 캐시할 자료구조 객체가 여러개 들어간다.
- 빈번하게 할당 및 해제되는 자료구조일수록 슬랩을 이용해서 관리하는 것이 합리적이다.

## 12.5 스택 할당

- 사용자 공간은 동적으로 확장되는 커다란 스택 공간을 사용할 수 있지만, 커널은 고정된 작은 크기의 스택을 사용한다.
- 커널 스택은 컴파일 시점의 옵션에 따라 하나 또는 두 개의 페이지(4KB ~ 16KB)로 구성된다.
- 인터럽트 핸들러는 커널 스택을 사용하지 않고 프로세서별로 존재하는 1-page 짜리 스택을 사용한다.
- 특정 함수의 지역변수 크기는 1KB 이하로 유지하는 것이 좋다. 스택 오버플로우는 조용히 발생하며 확실하게 문제를 일으키며 가장 먼저 thread_info 구조체가 먹혀버린 뒤 모든 종류의 커널 데이터가 오염될 여지가 있다.
- 따라서 대량의 메모리를 사용할 때는 앞서 살펴본 동적 할당을 사용해야 한다.

## 12.6. 상위 메모리 연결

- 12.1 항목에서 설명했듯, 상위 메모리에 있는 페이지는 커널 주소 공간에 포함되지 않을 수도 있다. (대부분의 64-bit 시스템은 포함된다.)
- `alloc_pages()` 함수를 호출해서 얻은 페이지에 가상주소가 없을 수 있으므로, 페이지를 할당한 다음에 커널 주소 공간에 수동으로 연결하는 작업이 필요하다.
- 이를 위해 `<linux/highmem.h>` 파일에 `kmap(struct page* page);` 함수를 사용한다. 
  - 페이지가 하위 메모리에 속해 있다면, 그냥 페이지의 가상주소를 반환한다.
  - 페이지가 상위 메모리에 속해 있다면, 메모리를 맵핑한 뒤 그 주소를 반환한다.
- 프로세스 컨텍스트에서만 동작한다.

## 12.7 CPU별 할당 - percpu 인터페이스
- SMP를 지원하는 2.6 커널에는 특정 프로세서 고유 데이터인 CPU별 데이터를 생성하고 관리하는 percpu라는 새로운 인터페이스를 도입했다.
- `<linux/percpu.h>` 헤더파일과 `<mm/slab.c>`, `<asm/percpu.c>` 파일에 정의돼있다.

    ```c
    // 컴파일 타임의 CPU별 데이터
    DEFINE_PER_CPU(var, name);	// type형 변수 var 생성
    get_cpu_var(var)++;			// 현재 프로세서의 var 증감
    // 여기부터 선점이 비활성화 된다.
    put_cpu_var(var);			// 다시 선점 활성화

    // 런타임의 CPU별 데이터
    void *alloc_percpu(size_t size, size_t align);
    void free_percpu(const void *);
    ```

- CPU별 데이터를 사용하면 세 가지 장점이 있다. 
  - 락(스핀락, 세마포어)을 사용할 필요가 줄어든다.
  - 캐시 무효화(invalidation) 위험을 줄여준다.
  - 선점 자동 비활성화-활성화로 인터럽트 컨텍스트 & 프로세스 컨텍스트에서 안전하게 사용할 수 있다.

# 13. 파일 시스템

- VFS(Virtual FileSystem)는 시스템콜이 파일시스템이나 물리적 매체 종류에 상관없이 공통적으로 동작할 수 있도록 해주는 인터페이스다.
- 파일시스템 추상화 계층은 모든 파일시스템이 지원하는 기본 인터페이스와 자료구조를 선언한 것이다.
- VFS는 슈퍼블록(superblock), 아이노드(inode), 덴트리(dentry), 파일(file) 4가지 객체로 구성돼있다. 
  - **슈퍼블록**: 파일시스템을 기술하는 정보(+ file_system_type, vfsmount 구조체)를 저장한다.
  - **아이노드**: 파일이나 디렉토리를 관리하는 데 필요한 모든 정보를 저장한다.
  - **덴트리**: 디렉토리 경로명 속 각 항목의 유효성 정보 등을 저장한다.
  - **파일**: 메모리 상에 로드 된 열려있는 파일에 대한 정보를 저장한다. 한 파일은 여러 프로세스에서 동시에 열고 사용할 수 있기 때문에, 같은 파일에 대해 여러 개의 파일 객체가 있을 수 있다.
- 각 객체들에는 여러 함수들이 들어있는 동작(operation) 객체가 멤버변수로 들어있다. 
  - **super_operation** 객체에는 `write_inode()`, `sync_fs()` 같이 특정 파일시스템에 대한 함수가 들어있다.
  - **inode_operation** 객체에는 `create()`, `link()` 같이 특정 파일에 대한 함수가 들어있다.
  - **dentry_operation** 객체에는 `d_compare()`, `d_delete()` 같이 디렉토리에 대한 함수가 들어있다.
  - **file_operation** 객체에는 `read()`, `write()` 같이 열린 파일(프로세스)에 대한 함수가 들어있다. 표준 유닉스 시스템콜의 기초가 되는 익숙한 함수들이 들어있다.
- 프로세스 관련 자료구조 
  - 우리는 이미 커널이 프로세스를 `task_struct` 구조체로 관리하고 있음을 알고 있다.
  - `task_struct`는 `files_struct` 구조체를 멤버변수로 가지고 있는데, 여기에 열려 있는 파일(프로세스)에 대한 세부 정보가 저장된다.
  - `files_struct`는 `<linux/fdtable.h>`에 정의돼있다.

# 14. Block I/O

## 14.1. 버퍼 헤드

- 블록 장치는 고정된 크기의 데이터에 임의 접근하는 플래시 메모리 같은 HW 장치를 의미한다.
- 블록 장치가 물리적으로 접근하는 최소 단위는 섹터(sector, 약 512-byte)고, 논리적으로 접근하는 최소 단위는 블록(Block)이며 섹터 크기의 배수다.
- 디스크 상의 ‘블록’이 메모리 상에 나타나려면 객체 역할을 하는 ‘버퍼’가 필요하다.
- 커널은 버퍼가 어느 블록 장치의 어떤 블록에 해당하는지 등의 관련 제어 정보를 ‘버퍼 헤드’(buffer_head) 구조체를 사용해서 저장하고 표현하며 `<linux/buffer_head.h>`에 정의돼있다. 

  ```c
  // https://github.com/torvalds/linux/blob/f2e8a57ee9036c7d5443382b6c3c09b51a92ec7e/include/linux/buffer_head.h#L59
  /*
  * Historically, a buffer_head was used to map a single block
  * within a page, and of course as the unit of I/O through the
  * filesystem and block layers.  Nowadays the basic I/O unit
  * is the bio, and buffer_heads are used for extracting block
  * mappings (via a get_block_t call), for tracking state within
  * a page (via a page_mapping) and for wrapping bio submission
  * for backward compatibility reasons (e.g. submit_bh).
  */
  struct buffer_head {
    unsigned long b_state;		/* 해당 버퍼의 현재 상태를 의미하며 여러 플래그 중 하나의 값을 가진다. (see above) */
    struct buffer_head *b_this_page;/* circular list of page's buffers */
    union {
      struct page *b_page;	/* the page this bh is mapped to */
      struct folio *b_folio;	/* the folio this bh is mapped to */
    };

    sector_t b_blocknr;		/* start block number */
    size_t b_size;			/* 블록의 길이(크기) */
    char *b_data;			/* 버퍼가 가리키는 블록 */

    struct block_device *b_bdev;
    bh_end_io_t *b_end_io;		/* I/O completion */
    void *b_private;		/* reserved for b_end_io */
    struct list_head b_assoc_buffers; /* associated with another mapping */
    struct address_space *b_assoc_map;	/* mapping this buffer is
                associated with */
    atomic_t b_count;		/* 버퍼의 사용 횟수를 의미한다. get_bh(), put_bh() 함수로 증감한다. */
    spinlock_t b_uptodate_lock;	/* Used by the first bh in a page, to
            * serialise IO completion of other
            * buffers in the page */
  };
  ```

- 커널 2.6 버전 이전의 버퍼 헤드는 훨씬 크고 모든 블록 I/O 동작까지 책임지는 더 중요한 역할을 맡았다. 하지만, 버퍼 헤드로 블록 I/O를 하는 것은 크고 어려운 작업이었고, 페이지 관점에서 I/O를 하는 것이 보다 간단하고 더 좋은 성능을 보여줬으며, 페이지보다 작은 버퍼를 기술하기 위해 커다란 버퍼 헤드 자료구조를 사용하는 것은 비효율적이었다.
- 따라서 커널 2.6 버전 이후로 버퍼 헤드는 크게 간소화 됐으며, 상당수 커널 작업이 버퍼 대신 페이지와 주소 공간을 직접 다루는 방식으로 바뀌었다.
- 지금의 버퍼 헤드는 디스크 블록과 메모리의 페이지를 연결시켜주는 서술자 역할을 한다.

## 14.2 bio 구조체

- 거대한 버퍼 헤드의 기능이 간소화되며 블록 I/O 동작은 `<linux/bio.h>`의 bio 구조체가 담당하게 됐다.

```c
// https://litux.nl/mirror/kerneldevelopment/0672327201/ch13lev1sec3.html
struct bio {
        sector_t             bi_sector;         /* associated sector on disk */
        struct bio           *bi_next;          /* list of requests */
        struct block_device  *bi_bdev;          /* associated block device */
        unsigned long        bi_flags;          /* status and command flags */
        unsigned long        bi_rw;             /* read or write? */
        unsigned short       bi_vcnt;           /* number of bio_vecs off */
        unsigned short       bi_idx;            /* current index in bi_io_vec */
        unsigned short       bi_phys_segments;  /* number of segments after coalescing */
        unsigned short       bi_hw_segments;    /* number of segments after remapping */
        unsigned int         bi_size;           /* I/O count */
        unsigned int         bi_hw_front_size;  /* size of the first mergeable segment */
        unsigned int         bi_hw_back_size;   /* size of the last mergeable segment */
        unsigned int         bi_max_vecs;       /* maximum bio_vecs possible */
        struct bio_vec       *bi_io_vec;        /* bio_vec list */
        bio_end_io_t         *bi_end_io;        /* I/O completion method */
        atomic_t             bi_cnt;            /* usage counter */
        void                 *bi_private;       /* owner-private method */
        bio_destructor_t     *bi_destructor;    /* destructor method */
};
```

- bio 구조체는 scatter-gather I/O 방식을 사용하므로 개별 버퍼가 메모리 상에 연속되지 않더라도 bio_io_vec 이라는 세그먼트 리스트로 연결해서 표현한다.
  
  <img width="414" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/1be0a936-894d-4a70-85a2-027972ec1001">
  
## 14.3 요청 큐 (Request Queue)

- 블록 장치는 대기 중인 블록 I/O 요청을 요청 큐에 저장한다.
- 요청 큐는 `<linux/blkdev.h>`의 request_queue 구조체를 사용해 표현한다.

```c
// https://github.com/torvalds/linux/blob/f2e8a57ee9036c7d5443382b6c3c09b51a92ec7e/include/linux/blkdev.h#L378
struct request_queue {
	struct request		*last_merge;
	struct elevator_queue	*elevator;

	struct percpu_ref	q_usage_counter;

	struct blk_queue_stats	*stats;
	struct rq_qos		*rq_qos;
	struct mutex		rq_qos_mutex;

	const struct blk_mq_ops	*mq_ops;

	/* sw queues */
	struct blk_mq_ctx __percpu	*queue_ctx;

	unsigned int		queue_depth;

	/* hw dispatch queues */
	struct xarray		hctx_table;
	unsigned int		nr_hw_queues;

	/*
	 * The queue owner gets to use this for whatever they like.
	 * ll_rw_blk doesn't touch it.
	 */
	void			*queuedata;

	/*
	 * various queue flags, see QUEUE_* below
	 */
	unsigned long		queue_flags;
	/*
	 * Number of contexts that have called blk_set_pm_only(). If this
	 * counter is above zero then only RQF_PM requests are processed.
	 */
	atomic_t		pm_only;

	/*
	 * ida allocated id for this queue.  Used to index queues from
	 * ioctx.
	 */
	int			id;

	spinlock_t		queue_lock;

	struct gendisk		*disk;

	refcount_t		refs;

	/*
	 * mq queue kobject
	 */
	struct kobject *mq_kobj;

#ifdef  CONFIG_BLK_DEV_INTEGRITY
	struct blk_integrity integrity;
#endif	/* CONFIG_BLK_DEV_INTEGRITY */

#ifdef CONFIG_PM
	struct device		*dev;
	enum rpm_status		rpm_status;
#endif

	/*
	 * queue settings
	 */
	unsigned long		nr_requests;	/* Max # of requests */

	unsigned int		dma_pad_mask;

#ifdef CONFIG_BLK_INLINE_ENCRYPTION
	struct blk_crypto_profile *crypto_profile;
	struct kobject *crypto_kobject;
#endif

	unsigned int		rq_timeout;

	struct timer_list	timeout;
	struct work_struct	timeout_work;

	atomic_t		nr_active_requests_shared_tags;

	struct blk_mq_tags	*sched_shared_tags;

	struct list_head	icq_list;
#ifdef CONFIG_BLK_CGROUP
	DECLARE_BITMAP		(blkcg_pols, BLKCG_MAX_POLS);
	struct blkcg_gq		*root_blkg;
	struct list_head	blkg_list;
	struct mutex		blkcg_mutex;
#endif

	struct queue_limits	limits;

	unsigned int		required_elevator_features;

	int			node;
#ifdef CONFIG_BLK_DEV_IO_TRACE
	struct blk_trace __rcu	*blk_trace;
#endif
	/*
	 * for flush operations
	 */
	struct blk_flush_queue	*fq;
	struct list_head	flush_list;

	struct list_head	requeue_list;
	spinlock_t		requeue_lock;
	struct delayed_work	requeue_work;

	struct mutex		sysfs_lock;
	struct mutex		sysfs_dir_lock;

	/*
	 * for reusing dead hctx instance in case of updating
	 * nr_hw_queues
	 */
	struct list_head	unused_hctx_list;
	spinlock_t		unused_hctx_lock;

	int			mq_freeze_depth;

#ifdef CONFIG_BLK_DEV_THROTTLING
	/* Throttle data */
	struct throtl_data *td;
#endif
	struct rcu_head		rcu_head;
	wait_queue_head_t	mq_freeze_wq;
	/*
	 * Protect concurrent access to q_usage_counter by
	 * percpu_ref_kill() and percpu_ref_reinit().
	 */
	struct mutex		mq_freeze_lock;

	int			quiesce_depth;

	struct blk_mq_tag_set	*tag_set;
	struct list_head	tag_set_list;

	struct dentry		*debugfs_dir;
	struct dentry		*sched_debugfs_dir;
	struct dentry		*rqos_debugfs_dir;
	/*
	 * Serializes all debugfs metadata operations using the above dentries.
	 */
	struct mutex		debugfs_mutex;

	bool			mq_sysfs_init_done;
};
```

- request_queue와 request 그리고 bio와 bio_vec 사이의 복잡한 구조를 도식화한 그림이다. 

  <img width="568" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/09cd5753-643d-4bc4-b902-1e659233e21e">

  - 요청 큐 request_queue 구조체에는 여러 블록 I/O 요청인 request 구조체가 들어있고,
  - 각 request는 (블록 I/O의 동작을 의미하는) 하나 이상의 bio 구조체를 멤버로 가지고 있고,
  - 각 bio 구조체는 bio_vec 배열을 가리키며 이 배열에는 여러 세그먼트가 들어 있을 수 있다.

## 14.4 입출력 스케줄러

- 커널은 블록 I/O 요청을 받자마자 바로 요청 큐로 보내지 않고, ​입출력 스케줄러로 대기 중인 블록 I/O 요청들 중 병합할 수 있는 건 합치고 정렬해서 디스크 탐색시간을 최소화 해 시스템 성능을 크게 개선한다. 
- 요쳥 A가 접근하려는 섹터와 요청 B가 접근하려는 섹터가 인접하다면, 합쳐서 하나의 I/O 요청으로 만드는 것이 효율적이다. 한 번의 명령으로 추가 탐색 없이 여러 개의 요청을 처리할 수 있다.
- 병합할 수 있는 요청이 없을 때, 요청 큐 맨 끝에 넣는 것보다, 물리적으로 가까운 섹터에 접근하는 다른 요청 근처에 정렬해 추가한다면 효율적이다.
- 입출력 스케줄러 알고리즘은 우리의 일상생활 속의 ‘엘리베이터 알고리즘’과 상당히 흡사해 실제로 커널 2.4 버전까지 ‘리누스 엘리베이터’라는 이름으로 불렸다.
- 리눅스 커널 2.6 버전은 4가지 입출력 스케줄러 알고리즘​을 제공한다. 

- **데드라인 (Deadline)**
  - 대부분의 사용자는 쓰기보다 읽기 성능에 민감하다. 어떤 읽기 요청 하나가 미처리 상태에 머물면 정체 시스템 지연 시간이 어마어마하게 커질 것이다.
  - 이름 그대로 각 요청에 ‘만료 시간’을 설정한다. 읽기 요청은 0.5초, 쓰기 요청은 5초다.
  - 데드라인 방식은 요청 큐로 FIFO 큐를 사용하는데, 쓰기 FIFO 큐나 읽기 FIFO 큐의 맨 앞 요청이 만료되면 해당 요청을 가장 우선으로 처리한다.
- **예측 (Anticipatory)**
  - 데드라인 방식은 우수한 읽기 성능을 보장하지만 이는 전체 성능 저하의 대가를 감수한 것이다.
  - 예측 방식은 데드라인을 기반으로 휴리스틱하게 동작한다.
  - 읽기 요청이 발생하면 스케줄러는 요청을 처리한 뒤 바로 다른 요청을 처리하러 가지만, 예측 방식에선 수 ms 동안 아무 일도 하지 않는다.
  - 이 시간 동안 사용자로부터 다른 읽기 요청이 계속해서 들어오고, 병합되고, 정렬된다.
  - 대기 시간이 지난 뒤에 스케줄러는 다시 돌아가서 이전 요청 처리를 계속한다.
  - 한 번에 많은 읽기 요청을 처리하기 위해 요청이 추가로 더 들어올 것을 예측하면서 수 ms를 아무것도 안 하고 가만히 있는 이 전략은 의외로 성능을 크게 증가시켰다.
  - 특히, 스케줄러는 여러 입출력 양상 통계값과 휴리스틱을 이용해 애플리케이션과 파일시스템의 동작을 예측해 읽기 요청을 처리하기 때문에 필요한 탐색 시간을 허비하는 일을 크게 줄일 수 있었다.
  - 이 스케줄러는 서버에 이상적인 스케줄러다.
- **완전 공정 큐 (Completely Fair Queueing)**
  - 현재 리눅스의 기본 입출력 스케줄러로, 여러 부하 조건에서 가장 좋은 성능을 보여준다.
  - 입출력 요청을 각 프로세스 별로 할당한 큐에 저장하고, 병합하고, 정렬한다.
  - 각 요청 큐들 사이에서는 round-robin 방식으로 순서대로 미리 설정된 개수(기본값 4개)의 요청을 꺼내 처리한다.
- **무동작 (Noop)**
  - 플래시 메모리와 같이 완벽하게 random-access가 가능한 블록 장치를 위한 스케줄러다.
  - 병합만 하고 정렬이나 기타 탐색 시간 절약을 위한 어떤 동작도 수행하지 않는다.

# 15. 프로세스 주소 공간

- 커널은 사용자 공간 프로세스의 메모리도 관리해야 하며 이를 ‘프로세스 주소 공간’이라고 부른다.
- 프로세스는 유효한 메모리 영역에만 접근해야 하며, 이를 어길시 segment fault를 만날 것이다.

## 15.1 메모리 서술자 구조체 mm_struct

```c
struct mm_struct {
	struct {
		atomic_t mm_users;
		/*
		 * Fields which are often written to are placed in a separate
		 * cache line.
		 */
		struct {
			/**
			 * @mm_count: The number of references to &struct
			 * mm_struct (@mm_users count as 1).
			 *
			 * Use mmgrab()/mmdrop() to modify. When this drops to
			 * 0, the &struct mm_struct is freed.
			 */
			atomic_t mm_count;
		} ____cacheline_aligned_in_smp;

		struct maple_tree mm_mt;
    ...
  }
};
```

- `<linux/mm_types.h>`에는 `mm_struct` 라는 메모리 서술자 구조체가 정의돼있다. 
  - `mm_users`: 이 주소 공간을 사용하는 프로세스의 개수를 의미한다.
  - `mm_count`: 이 구조체의 주 참조 횟수다. 
    - 9개 스레드가 주소 공간을 공유한다면? `mm_users == 9, mm_count == 1`
    - `mm_users == 0` -> mm_count를 하나 감소시킨다.
    - `mm_count == 0` -> 이 주소 공간을 참조하는 놈이 하나도 없으니 메모리를 해제한다.
  - mmap, mm_rb: 동일한 메모리 영역을 전자는 연결리스트로, 후자는 레드-블랙 트리로 나타낸 것이다. 
    - 왜 같은 대상을 중복 표현해서 메모리를 낭비하는 걸까?
    - 메모리 낭비는 있겠지만, 얻을 수 있는 이점이 있기 때문이다.
    - 전후 관계를 파악하거나 모든 항목을 탐색할 때는 연결리스트가 효율적이다.
    - 특정 항목을 탐색할 때는 레드-블랙 트리가 효율적이다.
    - 이런 방식으로 같은 데이터를 두 가지 다른 접근 방식으로 사용하는 것을 ‘스레드 트리’라고 부른다.

- 이미 3장에서 `task_struct`를 배울 때 mm 멤버변수로 이 구조체를 봤었다.
  - 복습하자면, `current->mm`은 현재 프로세스의 메모리 서술자를 뜻하며,
  - `fork()` → `copy_mm()` 함수가 부모 프로세스의 메모리 서술자를 자식 프로세스로 복사하며,
  - 복사할 때 12.4절에서 배운 ‘슬랩 캐시’를 이용해 `mm_cachep`에서 `mm_struct` 구조체를 할당한다.
  - 만일 만드는게 스레드라면, 생성된 스레드의 메모리 서술자는 부모의 mm을 가리킬 것이다.
  - 그리고 커널 스레드라면, 당연히 프로세스 주소 공간이 없으므로 mm == NULL이다. 
    - (+ 추가내용: 커널 스레드가 종종 프로세스 주소 공간의 페이지 테이블 일부 데이터가 필요한 경우가 있다. 메모리 서술자의 mm == NULL일 때, active_mm 항목은 이전 프로세스의 메모리 서술자가 가리키던 곳으로 갱신된다. 따라서 커널 스레드는 이전 프로세스의 페이지 테이블을 필요할 때 사용할 수 있다.)

## 15.2 가상 메모리 영역 구조체 vm_area_struct

- 리눅스 커널에서 ‘가상 메모리 영역’은 VMA라고 줄여 부르며 `<linux/mm_type.h>`의 `vm_area_struct` 구조체로 메모리 영역을 표현한다.

```c
// https://github.com/torvalds/linux/blob/f2e8a57ee9036c7d5443382b6c3c09b51a92ec7e/include/linux/mm_types.h#L616
struct vm_area_struct {
	/* The first cache line has the info for VMA tree walking. */

	union {
		struct {
			/* VMA covers [vm_start; vm_end) addresses within mm */
			unsigned long vm_start;
			unsigned long vm_end;
		};
#ifdef CONFIG_PER_VMA_LOCK
		struct rcu_head vm_rcu;	/* Used for deferred freeing. */
#endif
	};

	struct mm_struct *vm_mm;	/* The address space we belong to. */
	pgprot_t vm_page_prot;          /* Access permissions of this VMA. */

	/*
	 * Flags, see mm.h.
	 * To modify use vm_flags_{init|reset|set|clear|mod} functions.
	 */
	union {
		const vm_flags_t vm_flags;
		vm_flags_t __private __vm_flags;
	};

	const struct vm_operations_struct *vm_ops;
  ...
} __randomize_layout;
```

- 주요 멤버 변수를 살펴보면 아래와 같다. 
  - `vm_start`, `vm_end`: 가상 메모리 영역의 시작주소와 마지막 주소를 의미하므로 이 둘의 차이가 메모리 영역의 바이트 길이가 된다. 다른 메모리 영역끼리는 중첩될 수 없다.
  - `vm_mm`: VMA 별로 고유한 mm_struct를 보유한다. 동일 파일을 별도의 프로세스들이 각자의 주소 공간에 할당할 경우 각자의 vm_area_struct를 통해 메모리 공간을 식별하게 된다.
  - `vm_flags`: 메모리 영역 내 페이지에 대한 정보(읽기, 쓰기, 실행 권한 정보 등)를 제공한다.
  - `vm_ops`: 메모리 영역을 조작하기 위해 커널이 호출할 수 있는 동작 구조체 vm_operations_struct를 가리킨다. (13절 VFS를 설명할 때 언급했던 ‘동작 객체’ 구조체와 비슷한 개념이다.)

## 15.3. 실제 메모리 영역 살펴보기
- 간단한 프로그램을 만들고, ‘/proc’ 파일시스템과 pmap 유틸리티를 통해 특정 프로세스의 주소 공간과 메모리 영역을 살펴보자.

```bash
[ec2-user@ip-x-x-x-x ~]$ echo -e "int main(int argc, char *argv[]) { while(1); }" > test.c
[ec2-user@ip-x-x-x-x ~]$ gcc -o test test.c && ./test &
[1] 1024914
[ec2-user@ip-x-x-x-x ~]$ cat /proc/1024914/maps
55ef85f2b000-55ef85f5a000 r--p 00000000 103:01 2253                      /usr/bin/bash
55ef86c8c000-55ef86dad000 rw-p 00000000 00:00 0                          [heap]
7ffb87000000-7ffb94530000 r--p 00000000 103:01 8524092                   /usr/lib/locale/locale-archive
7ffb94600000-7ffb94ed4000 r--s 00000000 103:01 9692403                   /var/lib/sss/mc/passwd
7ffb94fab000-7ffb95000000 r--p 00000000 103:01 443                       /usr/lib/locale/C.utf8/LC_CTYPE
7ffb95000000-7ffb95028000 r--p 00000000 103:01 8524744                   /usr/lib64/libc.so.6
7ffb95230000-7ffb95231000 r--p 00000000 103:01 1600                      /usr/lib/locale/C.utf8/LC_NUMERIC
7ffb95231000-7ffb95232000 r--p 00000000 103:01 1603                      /usr/lib/locale/C.utf8/LC_TIME
7ffb95232000-7ffb95233000 r--p 00000000 103:01 442                       /usr/lib/locale/C.utf8/LC_COLLATE
7ffb95233000-7ffb95234000 r--p 00000000 103:01 446                       /usr/lib/locale/C.utf8/LC_MONETARY
7ffb95234000-7ffb95235000 r--p 00000000 103:01 8524051                   /usr/lib/locale/C.utf8/LC_MESSAGES/SYS_LC_MESSAGES
7ffb95235000-7ffb95236000 r--p 00000000 103:01 1601                      /usr/lib/locale/C.utf8/LC_PAPER
7ffb95236000-7ffb95237000 r--p 00000000 103:01 447                       /usr/lib/locale/C.utf8/LC_NAME
7ffb95237000-7ffb9523e000 r--s 00000000 103:01 2799                      /usr/lib64/gconv/gconv-modules.cache
7ffb9523e000-7ffb95240000 r--p 00000000 103:01 9455124                   /usr/lib64/libnss_sss.so.2
7ffb9524e000-7ffb9525c000 r--p 00000000 103:01 8522848                   /usr/lib64/libtinfo.so.6.2
7ffb95283000-7ffb95285000 r--p 00000000 103:01 8524740                   /usr/lib64/ld-linux-x86-64.so.2
7ffed54c8000-7ffed54e9000 rw-p 00000000 00:00 0                          [stack]
7ffed55e0000-7ffed55e4000 r--p 00000000 00:00 0                          [vvar]
7ffed55e4000-7ffed55e6000 r-xp 00000000 00:00 0                          [vdso]
ffffffffff600000-ffffffffff601000 --xp 00000000 00:00 0                  [vsyscall]
```
- `/proc/<pid>/maps` 파일은 프로세스 주소 공간의 메모리 영역을 출력해준다.
- pmap 유틸리티를 사용하면 위 정보를 조금 더 가독성 있게 표현해준다.
- 지금까지 다룬 구조체의 구조를 깔끔하게 도식화한 그림이다.

  <img width="546" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/7a83e81b-9239-4de7-8f78-34822689ba9f">

- `task_struct`의 mm은 각 프로세스의 메모리 서술자인 `mm_struct`이다.
- `mm_struct`의 mmap은 가상 메모리 영역 `vm_area_struct`을 표현하는 연결리스트다.
- `vm_area_struct`는 프로세스의 실제 메모리 영역(.txt, .data 등)을 나타낸다.

<img width="563" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/ff72c51b-ddd1-4e1d-914a-21f77b01930a">

- 알다시피, 커널과 애플리케이션은 가상 주소를 사용하지만, 프로세서는 물리 주소를 사용한다.
  - 따라서 프로세서와 애플리케이션이 서로 상호작용하기 위해서는 페이지 테이블을 통해 변환작업이 필요하다.
- 리눅스 커널은 PGD(Global), PMD(Middle), PTE 세 단계의 페이지 테이블을 사용한다.
- 페이지 테이블 구조는 아키텍처에 따라 상당히 다르며 `<asm/page.h>`에 정의돼있다.

# 16. Page Cache & Page Writeback

## 16.1 캐시 정의와 사용 방식

- 리눅스는 캐시를 ‘페이지 캐시(Page cache)’라고 부르며 디스크 접근 횟수를 최소화 하기 위해 사용한다. 
  - 프로세스가 `read()` 시스템콜 등으로 읽기 요청을 할 때, 커널은 가장 먼저 페이지 캐시를 확인한다.
  - 만약 있다면, 메모리 또는 디스크 접근을 하지 않고 캐시에서 데이터를 바로 읽는다.
  - 만약 없다면, 메모리 또는 디스크에 접근해 읽은 뒤 데이터를 캐시에 채워 넣는다.
  
- 리눅스는 write policy로 지연 기록(write-back)을 채택하고 있다. 
  - 프로세스의 쓰기 동작은 캐시에 바로 적용된다. (메모리 or 디스크에 적용 X)
  - 해당 캐시 라인에 dirty 표시를 한다.
  - 적당한 때에 주기적으로 캐시의 dirty 표시된 내용이 메모리 or 디스크에 갱신되고 지워진다.
  - 통합해서 한꺼번에 처리하므로 성능이 우수하지만 복잡도가 높다.
  
- 캐시의 갱신된 페이지 내용을 메모리 or 디스크로 반영하는 작업을 ‘플러시(Flush)’라고 한다. 
  - 리눅스는 이 작업을 ‘플러시 스레드(Flush thread)’라는 커널 스레드가 담당한다.
  - 페이지 캐시 가용 메모리가 특정 임계치 이하로 내려갈 때 dirty 캐시 라인을 플러시 한다.
  - 페이지 케시 dirty 상태가 특정 한계 시간을 지나면 플러시 한다.
  - 사용자가 `sync()`, `fsync()` 시스템콜을 호출하면 즉시 플러시 한다.
  
- 리눅스는 replacement policy로 ‘이중 리스트 전략’(Two-list) 라는 개량 LRU(Least Recently Used) 알고리즘을 사용한다. 
  - 페이지 캐시가 가득찼을 때 어떤 데이터를 제거할 것인지 선택하는 과정이다.
  - 언제 각 페이지에 접근했는지 타임스탬프를 기록해둔 뒤 가장 오래된 페이지를 교체하는 방법이다.
  - 이중 리스트 전략은 ‘활성 리스트’와 ‘비활성 리스트’ 두 가지 리스트를 활용한다. 
    - 최근에 접근한 캐시 라인은 활성 리스트에 들어가서 교체 대상에서 제외한다.
    - 두 리스트는 큐처럼 앞부분에서 제거하고 끝부분에 추가한다.
    - 두 리스트는 균형 상태를 유지한다. 활성 리스트가 커지면 앞쪽 항목들을 비활성 리스트로 넘긴다.

## 16.2 리눅스 페이지 캐시 구조체 - address_space

- 다양한 형태의 파일과 객체를 올바르게 캐시하는 것을 목표로 `<linux/fs.h>`에 `address_space` 객체가 만들어졌다.
- 하나의 `address_space` 객체는 하나의 파일(inode)을 나타내고 1개 이상의 `vm_area_struct`가 포함된다. 단일 파일이 메모리상에서 여러 개의 가상 주소를 가질 수 있다는 걸 생각하면 된다.
- 특히, 페이지 캐시는 원하는 페이지를 빨리 찾을 수 있어야 하기 때문에 `address_space`에는 `page_tree`라는 이름의 기수 트리(radix tree)가 들어 있다.

# 17. Devices & Modules

## 17.1 정의
- 모듈: 커널 관련 하위 함수, 데이터, 바이너리 이미지를 포함해 동적으로 불러 올 수 있는 커널 객체를 의미한다.
- 장치: 리눅스 커널은 장치를 **블록 장치, 캐릭터 장치, 네트워크 장치** 3가지로 분류한다. 모든 장치 드라이버가 물리장치를 표현하는 것은 아니며 커널 난수 생성기, 메모리 장치처럼 가상 장치도 표현한다.
 
## 17.2 모듈 사용하기

### 모듈 만들기

- 모듈 개발은 새로운 프로그램을 짜는 것과 비슷하다.
- 각 모듈은 소스파일 내에 자신의 시작위치(`module_init()`)와 종료위치(`module_exit()`)가 있다.
- 가장 간단한 ‘hello, world’ 출력 모듈을 작성하면 아래와 같다.

  ```c
  #include <linux/init.h>
  #include <linux/module.h>
  #include <linux/kernel.h>

  static int hello_init(void)
  {
    printk(KERN_ALERT, "hello\n");
    return 0;
  }

  static void hello_exit(void)
  {
    printk(KERN_ALERT, "world\n");
  }

  module_init(hello_init);					// 모듈 진입점
  module_exit(hello_exit);					// 모듈 종료점

  MODULE_LICENSE("GPL");						// 저작권 정보
  MODULE_AUTHOR("Embeddedjune");				    // 모듈 제작자 정보
  MODULE_DESCRIPTION("Test Hello,world");		// 모듈에 대한 정보
  ```

### 모듈 설치 준비하기

- 모듈 작성을 완료했다면, 모듈 소스를 패치의 형태나 커널 소스 트리에 병합한다.
- 모듈은 `/drivers`의 적당한 장치 하위 디렉토리에 디렉토리를 만들고 넣는다.
- `/drivers`의 Makefile과 방금 만든 하위 디렉토리 안의 Makefile을 수정한다.
- make 명령어로 모듈을 컴파일한다.

### 모듈 설치하기
- `make modules_install` 명령을 이용해서 모듈을 설치한다.

### 모듈 의존성 생성하기
- `depmod` 명령어를 이용해서 의존성 정보를 반드시 생성한다.

### 메모리에 모듈 로드하기
- `insmod`로 모듈을 메모리에 추가하고 rmmod로 모듈을 제거한다.
- `modprobe` 도구는 의존성 해소, 오류 검사 및 보고 등의 고급 기능들을 제공하므로 사용을 적극 권장한다.

## 17.3 장치 모델

- 리눅스 커널 2.6버전의 중요한 새 기능으로 ‘장치 모델(Device model)’이 추가됐다. 
- 장치 모델이 추가된 이유는 ‘전원 관리(Power management) 기능 운용’을 위한 정확한 장치 트리(Device tree, 시스템의 장치 구조를 표현하는 트리)를 제공하기 위해서다.
- 플래시 드라이브가 어느 컨트롤러에 연결됐는지, 어느 장치가 어느 버스에 연결됐는지 정보를 알려주고, 커널이 전원을 차단할 때 트리의 하위 노드 장치부터 전원을 차단할 수 있도록 도와준다.
- 이러한 일련의 서비스를 정확하고 효율적으로 제공하기 위해 장치 트리 및 장치 모델이 필요하다.
- 장치 모델은 `kobjects`, `ksets`, `ktypes` 세 가지 구조체로 표현한다. (모든 구조체는 `<linux/kobject.h>`에 정의되어있다.)

```c
// https://github.com/torvalds/linux/blob/f2e8a57ee9036c7d5443382b6c3c09b51a92ec7e/include/linux/kobject.h#L64
// 커널 자료구조의 기본적인 객체 속성 제공, sysfs 상의 디렉토리와 같음
struct kobject {
	const char		*name;
	struct list_head	entry;
	struct kobject		*parent;
	struct kset		*kset;
	const struct kobj_type	*ktype;
	struct kernfs_node	*sd; /* sysfs directory entry */
	struct kref		kref;

	unsigned int state_initialized:1;
	unsigned int state_in_sysfs:1;
	unsigned int state_add_uevent_sent:1;
	unsigned int state_remove_uevent_sent:1;
	unsigned int uevent_suppress:1;

#ifdef CONFIG_DEBUG_KOBJECT_RELEASE
	struct delayed_work	release;
#endif
};

...

// https://github.com/torvalds/linux/blob/f2e8a57ee9036c7d5443382b6c3c09b51a92ec7e/include/linux/kobject.h#L168C1-L173C22
// 기능상 관련된 kobject의 집합(연결리스트)
struct kset {
	struct list_head list;
	spinlock_t list_lock;
	struct kobject kobj;
	const struct kset_uevent_ops *uevent_ops;
} __randomize_layout;

...

// https://github.com/torvalds/linux/blob/f2e8a57ee9036c7d5443382b6c3c09b51a92ec7e/include/linux/kobject.h#L116C1-L123C3
// 공동 동작을 공유하는 kobject의 집합(연결리스트)
struct kobj_type {
	void (*release)(struct kobject *kobj); // `kobjects`의 참조횟수가 0이 될 때 호출되서 C++의 소멸자 역할을 한다.
	const struct sysfs_ops *sysfs_ops;
	const struct attribute_group **default_groups;
	const struct kobj_ns_type_operations *(*child_ns_type)(const struct kobject *kobj);
	const void *(*namespace)(const struct kobject *kobj);
	void (*get_ownership)(const struct kobject *kobj, kuid_t *uid, kgid_t *gid);
};
...
```
- `kobjects` 구조체는 부모 객체를 멤버 포인터 객체로 가지므로 계층 구조를 가지고 있다.
- `kobjects`를 사용하기 위해서는 `kobject_create()` 함수를 사용한다.

## 17.4. sysfs

### sysfs 정의

- sysfs은 kobject 계층 구조를 보여주는 가상 파일시스템​이다.
- sysfs는 ​가상 파일을 통해 다양한 커널 하위 시스템의 장치 드라이버에 대한 정보를 제공한다.
- 리눅스 2.6 커널 이상을 이용하는 모든 시스템은 sysfs를 포함하며 /sys 디렉토리에 마운트돼있다.
- sysfs에는 block, bus, class, dev, devices, firmware, fs, kernel, module, power 등 최소 10개 디렉토리가 포함돼있다.
- 이 디렉토리들 중 가장 중요한 두 디렉토리는 class와 devices 디렉토리다. 
  - class는 시스템 장치의 상위 개념을 정리된 형태로 보여주고,
  - devices는 시스템 장치의 하위 물리적 장치 연결 정보 관계를 보여준다.
  - 나머지 디렉토리는 devices의 데이터를 단순히 재구성한 것에 불과하다.

### sysfs에 kobject에 추가하고 제거하기

```c
struct kobject *kobject_create_and_add(const char *name, struct kobject *parent);
void kobject_del(struct kobject *kobj);
```
- `kobject_create_and_add()`는 `kobject_create()` 함수와 `kobject_add()` 함수를 하나로 합친 함수다.
- kobject 객체를 생성하고 sysfs에 추가한다.
- kobject 객체를 제거할 때는 `kobject_del()` 함수를 사용한다.

### sysfs에 파일 추가하기

- kobject를 sysfs 계층구조에 추가해도 kobject가 가리키는 ‘파일’이 없다면 아무 의미가 없다.
- kobjects 구조체 속 ktypes 구조체는 아무런 인자가 없어도 기본적인 파일 속성을 제공한다.
  - `default_attrs` : 이 변수를 설정해서 파일의 이름, 소유자, 속성(쓰기, 읽기, 실행)을 부여한다.
  - `sysfs_ops` : 파일의 기본적인 동작(읽기(show), 쓰기(store))을 정의한다.
- 속성을 제거하기 위해서는 `sysfs_remove_file()` 함수를 이용한다.

# 18. Debugging

## 18.1. 시작하기

- 커널 디버깅에는 세 가지 요소가 필요하다. 
  - 버그가 처음 등장한 커널 버전을 파악할 수 있는가?
  - 버그를 재현할 수 있는가?
  - 커널 코드에 관한 지식을 갖추고 있는가?
- 버그를 명확하게 정의하고 안정적으로 재현할 수 있다면 성공적인 디버깅에 절반 이상 달성한 것이다.
​
## 18.2. 출력을 이용한 디버깅

### `printk()`와 웁스(oops)

- 커널 출력 함수인 `printk()`는 C 라이브러리의 printf() 함수와 거의 동일하다. 
  - 주요 차이점은 로그수준(Loglevel)을 지정할 수 있다는 점이다.
  - 가장 낮은 수준인 `KERN_DEBUG` 부터 가장 높은 수준인 `KERN_EMERG` 까지 7단계로 설정할 수 있다.
  
- `printk()`의 장점은 커널의 어느 곳에서도 언제든지 호출할 수 있다는 점이다. 
  - 인터럽트 컨텍스트, 프로세스 컨텍스트 모두 호출 가능하다.
  - 락을 소유하든 소유하지 않든 호출 가능하다.
  - 어느 프로세서에서도 사용할 수 있다.
  
- `printk()`의 단점은 커널 부팅 과정에서 콘솔이 초기화되기 전에는 사용할 수 없다는 점이다. 
  - 이식성을 포기하고 `printk()` 함수 변종인 `early_printk()` 함수를 사용하는 해결책이 있다.
  
- `printk()`를 사용할 때 주의할 점은, 너무 빈번하게 호출되는 커널 함수에 사용하면 시스템이 뻗어버린다는 것이다. 
  - 출력 폭주를 막기 위해 두 가지 방법을 사용할 수 있다.
  - 첫 번째 방법: jiffies를 이용해서 수초마다 한 번씩만 출력한다.
  - 두 번째 방법: `printk_ratelimit()` 함수를 이용해서 n초에 한 번씩만 출력한다.
  
- 커널 메시지는 크기가 `LOG_BUF_LEN`인 원형 큐(버퍼)에 저장된다. 
  - 크기는 `CONFIG_LOG_BUF_SHIFT` 옵션을 통해 설정할 수 있으며 기본값은 16KB다.
  - 원형 큐이므로 가득찼을 때 가장 오래된 메시지를 덮어쓴다.
  - 표준 리눅스 시스템은 사용자 공간의 ‘klogd’ 데몬이 로그 버퍼에서 커널 메시지를 꺼내고 ‘syslogd’ 데몬을 거쳐서 시스템 로그 파일(기본: `/var/log/messages`)에 기록한다.
  
- 웁스(oops)는 커널이 사용자에게 무언가 나쁜 일이 일어났다는 것을 알려주는 방법이다. 
  - 커널은 심각한 오류가 났을 때 사용자 프로세스처럼 책임감 없이 프로세스를 종료할 수 없다. 
    - 커널은 웁스가 발생했을 때 최대한 실행을 계속 하려고 시도한다.
    - 더 이상 커널 실행이 불가능하다고 판단할 경우 ‘패닉 상태’가 된다.
  - 커널은 콘솔 오류 메시지 + 레지스터 내용물 + 콜스택 역추적 정보 등을 출력한다.

### 버그 확인과 정보 추출

- `BUG()`, `BUG_ON()`: 웁스를 발생한다. 
  - 의도적으로 웁스를 발생시키는 시스템콜이다.
  - 이 함수는 발생해서는 안 되는 상황에 대한 조건문을 확인할 때 사용한다.
  - `if (...) BUG()` 랑 `BUG_ON(...)` 는 동일한 구문이다. 그래서 대부분 커널 개발자는 `BUG_ON()`을 사용하는 것을 더 좋아하며 조건문에 `unlikely()`를 함께 사용(`BUG_ON(unlikely());`)한다.
- `panic()` : 패닉을 발생한다. 
  - 좀 더 치명적인 오류의 경우에는 웁스가 아닌 패닉을 발생시킨다.
  - 이 함수를 호출하면 오류 메시지를 출력하고 커널을 중지시킨다.
- `dump_stack()` : 디버깅을 위한 스택 역추적 정보를 출력한다.

# 19. Portability(이식성)

- 이식성이란, 특정 시스템 아키텍처의 코드가 (가능하다면) 얼마나 쉽게 다른 아키텍처로 이동할 수 있는지를 의미한다.
- 이 장에서는 핵심 커널 코드나 디바이스 드라이버를 개발할 때 이식성 있는 코드를 작성하는 방법에 대해서 알아본다.
- 리눅스는 인터페이스와 핵심 코드는 아키텍처 독립적인 C로 작성됐고, 성능이 중요한 커널 기능은 각 아키텍처에 특화된 어셈블리로 작성해 최적화시켰다. 
  - 좋은 예로 스케줄러가 있다. 스케줄러 기능의 대부분은 `<kernel/sched.c>` 파일에 아키텍처 독립적으로 구현돼있다.
  - 하지만, 스케줄링의 세부 과정인 context switching과 memory management를 책임지는 `switch_to()`, `switch_mm()` 함수는 아키텍처별로 따로따로 구현돼있다.​
  
## 19.1 불확실한 자료형 크기

- 1-WORD는 시스템이 한 번에 처리할 수 있는 데이터의 길이를 의미하며 보통 범용 레지스터의 크기와 같다. 
- 리눅스 커널은 long 데이터의 크기가 1-WORD 크기와 같다.
- 리눅스 커널은 아키텍처마다 `<asm/types.h>` 의 `BITS_PER_LONG` 에 long 데이터형 크기로 1-WORD 크기를 지정해 놓았다.
- 옛날에는 같은 아키텍처도 32-bit 버전과 64-bit 버전이 따로 구현돼있었지만, 2.6버전 이후로 통합됐다.
- 아키텍처에 따라 C 자료형의 크기가 불명확한 것에 따라 장단점이 있다. 
  - 장점: long 크기가 1-WORD임이 보장된다, 아키텍처별로 명시적으로 자료형의 크기를 지정하지 않아도 된다 등
  - 단점: 코드 상에서 자료형의 크기를 알 수가 없다.
- 따라서 자료형의 크기를 함부로 추정하지 않는 것이 좋다.
- 자료형이 실제 필요로 하는 공간과 형태가 바뀌어도 상관 없도록 코드를 작성해야 이식성 높은 코드를 작성할 수 있다.
​
## 19.2 더욱 구체적인 자료형

- 때로는 개발자가 코드에서 자료형을 더욱 구체적으로 명시화 해줄 필요가 있다. 
- 예를 들어, 레지스터나 패킷 같이 HW, NW 관련 코드를 작성해야 하는 경우
- 음수를 저장해야 하는 경우: 명시적으로 signed 키워드를 써주는 것을 권장한다.
- 커널은 `<asm/types.h>` 파일에 명시적으로 크기가 정해진 자료형(i.e. u8, u16, u32, u64 등)을 typedef로 정의해놨다. 
- 이 자료형은 namespace 문제 때문에 커널 내부 코드에서만 사용해야 한다.
- 만일, 사용자 공간에 노출해야 한다면, 언더스코어 2개를 덧붙여서 `__u8`, `__u16` 처럼 사용하면 된다. 의미는 같다.

## 19.3. 기타 권장사항

- **바이트 순서**: 절대로 바이트 순서를 예측하지 마라. 범용 코드는 빅엔디안, 리틀엔디안 모두에서 동작해야 한다.
- **시간**: 절대로 jiffies 값을 양수값과 비교해서는 안 된다. Hz값으로 곱하거나 나눠야 한다.
- **페이지 크기**: 페이지 크기는 아키텍처마다 다르다. 당연히 4KB라고 생각해선 안 된다.
- **처리 순서**: 아키텍처마다 다양한 방식으로 프로세서 처리 순서를 따르므로 적절한 배리어를 사용해야 한다.

---
**참고**
- [Linux 커널 심층 분석 3판](https://product.kyobobook.co.kr/detail/S000000935348)
- https://github.com/torvalds/linux
- https://litux.nl/mirror/kerneldevelopment/0672327201/ch13lev1sec3.html
- https://jaykos96.tistory.com/27
- https://www.kernel.org/doc/html//v6.3/block/request.html
- https://www.kernel.org/doc/Documentation/this_cpu_ops.txt
- https://showx123.tistory.com/92
