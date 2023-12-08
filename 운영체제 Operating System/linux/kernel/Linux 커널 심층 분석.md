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

- 결국 프로세서 자원을 소모하므로 스핀락은 오랫동안 잡으면 안 되고 단기간만 사용해야 한다.

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
- 스핀락은 `<linux/spinlock.h>`과 `<asm/spinlock.h>`에 정의돼있다.
- 스핀락은 위와 같은 함수들을 사용해서 lock과 unlock을 하며 인터럽트 핸들러에서도 사용할 수 있다.
- 인터럽트 핸들러 버전은 데드락을 방지하기 위해 로컬 인터럽트를 비활성화하고 복원하는 과정을 포함한다.

## 9.5 동기화 수단 3: 세마포어(Semaphore)

- 이미 사용 중인 락을 얻으려고 시도할 때 busy-wait 하는 게 스핀락이라면, 세마포어는 sleep으로 진입한다.
- 무의미한 루프로 낭비하는 시간이 사라지니 프로세서 활용도가 높아지지만, 스핀락보다 부가 작업이 많다. 

Sleep 상태 전환, 대기큐 관리, wake-up 등 부가 작업을 처리하는 시간이 락 사용 시간보다 길 수 있기 때문에 오랫동안 락을 사용하는 경우에 적합하다.

Sleep 상태 전환 되므로 인터럽트 컨텍스트에선 사용할 수 없다.

세마포어를 사용할 때는 스핀락이 걸려있으면 안 된다.

세마포어는 동시에 여러 스레드가 같은 락을 얻을 수 있도록 사용 카운트를 설정할 수 있다.

0과 1로 이루어져 있다면 바이너리 세마포어 또는 뮤텍스(mutex), 그 외는 카운팅 세마포어라 부른다.

---
참고
- [Linux 커널 심층 분석 3판](https://product.kyobobook.co.kr/detail/S000000935348)
- https://jaykos96.tistory.com/27