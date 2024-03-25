kprobe와 kretprobe는 **커널 코드에 동적으로 중단점을 삽입하여 사용자가 정의하는 핸들러 함수가 실행되도록 하는** 강력한 도구이다.  kprobe는 함수 또는 함수에서 특정 오프셋만큼 떨어진 곳에서 핸들러 함수를 실행하게 해주는 도구이다. kretprobe는 함수가 끝난 후에 핸들러 함수를 실행하게 해주는 도구이다.

BPF에서 실행될 함수를 등록할 때도 uprobe, tracepoint, UDST 등의 툴과 함께 kprobe, kretprobe가 사용된다.

## kprobe의 동작 방식

![image](https://github.com/rlaisqls/TIL/assets/81006587/2952b12b-30c1-402c-8bf7-a86c91e18f9c)

- kprobe는 커널의 중단점을 삽입할 주소 (함수 + 오프셋)에 존재하는 명령어를 복사해둔 뒤 중단점을 삽입하는 명령어로 덮어씌운다 (i386에서는 int3 명령어로 1바이트이다.) 그럼 i386에서는 int3 명령어를 실행하는 순간 breakpoint exception이 발생해서 kprobe 핸들러로 넘어가게 된다.

- 그렇게 kprobe에 등록된, 중단점 이전에 실행되어야 하는 `pre_handler`를 먼저 실행한 후, 아까 복사한 명령어를 실행한다. 

- 복사된 명령어를 실행한 후에는 중단점 이후에 실행되어야 하는 `post_handler`를 실행한다. (이때 debug exception이 발생한다.) `post_handler`를 실행한 이후에는 probe 이후의 코드가 다시 실행되어서 본래의 함수 흐름으로 돌아간다. 따라서 kprobe를 사용하면 함수 호출마다 적어도 2번의 exception이 발생한다.

## kretprobe 동작 방식

- kretprobe는 kprobe로 구현된다. 이후에 나올 jump optimization를 사용하는 경우에는 1바이트보다 많은 메모리를 필요하므로 함수의 완전히 끝 부분에 중단점을 삽입할 수가 없다.

- 따라서 kretprobe는 함수가 끝날 때의 동작을 등록하기 위해 함수의 시작 부분 코드에 kprobe를 등록하여 함수의 리턴 주소를 트램펄린이라는 공간의 주소로 덮어씌운다. (트램펄린은 일련의 nop 명령어로 이루어져있는 코드 영역으로, 리눅스가 시작할 때 kprobe가 등록한다.)그럼 리턴 주소가 덮어씌워진 함수는 리턴할 때 트램펄린으로 리턴한다. 트램펄린으로 이동한 후에는 사용자가 등록한 핸들러 함수가 실행된다.

    > kretprobe는 리턴 주소를 kretprobe_instance에 저장하는데, kretprobe_instace의 개수는 사용자가 kretprobe를 등록할 때 maxactive라는 파라미터로 정해줄 수 있다. 보통 선점 가능한 커널이냐에 따라서 NR_CPUS나 2 * NR_CPUS를 기본값으로 정해준다. 만약 maxactive가 작아서 kretprobe_instance가 부족하다면 일부는 누락되는데, 이것은 kretprobe 구조체의 nmissed에 기록된다.

- kretprobe로 중단점을 등록할 때는 함수가 끝날 때 뿐만 아니라 시작할 때도 등록할 수 있다. kretprobe 구조체의 `entry_handler`를 지정해주면 된다.

### Jump Optimization

- kprobe는 pre_handler를 실행할 때의 breakpoint exception과 post_handler를 실행한 이후의 debug exception으로 함수가 실행될 때마다 2번의 exception을 처리해야하는 오버헤드가 존재한다. 따라서 이러한 오버헤드를 줄이고자 int3처럼 exception을 발생하는 것이 아니라 jump문으로 덮어씌워서 오버헤드를 줄이고자 한다.

### Safety Check

- 그런데 모든 상황에서 최적화가 가능한 것은 아니다. 최적화를 한 후에 커널이 크래시가 나면 안되기 때문에 kprobe는 re 안정성을 먼저 체크해야한다. 크게 두 가지의 안정성 체크를 한다. 
  1. kprobe로 코드를 덮어쓰는 범위가 함수의 크기를 넘어가지 않는지를 확인한다. jump optimization을 사용하는 경우에는 1바이트를 넘는 크기를 덮어쓰기 때문에, 함수의 마지막 몇 바이트에는 안정성 체크를 통과하지 못하므로 최적화를 할 수 없다.
  2. jump optimization을 사용했을 때는 여러 바이트를 덮어씌우는데, 덮어씌운 코드의 중간 지점으로 점프하는 코드가 없는지를 확인한다. 왜냐하면 중간 지점으로 점프할 경우 해당 주소에 있는 것이 코드가 아닐 수 있기 때문이다. 따라서 함수 내에 probe를 등록하는 지점 근처로 점프하는 명령어가 있다면 등록할 수 없다.

### Detour Buffer

- 안정성 체크가 끝나면 kprobe는 최적화에 사용할 detour buffer를 준비한다. detour buffer에는 다음의 항목이 순서대로 들어있다.

  - CPU 레지스터를 저장하는 코드
  - 트램펄린 코드로 이동하는 코드
  - CPU 레지스터를 복구하는 코드
  - 최적화 하느라 덮어쓴 영역에 원래 있었던 코드
  - 기존의 실행 경로로 돌아가는 코드

### Pre-Optimization

- detour buffer를 준비한 이후 최적화를 하기 전에 kprobe는 다음의 항목을 확인한다. 셋중 하나라도 거짓인 경우에는 최적화를 하지 않는다.

  - probe가 post_handler를 등록하지 않는다.
  - 최적화된 코드에 대한 probe가 존재하지 않는다.
  - probe가 활성화된 상태이다.

- 물론 비활성화된 probe가 다시 활성화되는 등 조건이 바뀌면 다시 최적화를 진행한다. 최적화가 가능하다는 것이 확인되면 kprobe는 "최적화 리스트"에 최적화를 해야된다는 걸 기억해두고 최적화를 진행한다.

- 만약 최적화 리스트에는 존재하지만 아직 최적화하지 않은 코드가 실행이 되면 single-step을 방지하기 위해 detour buffer에 저장해두었던 "최적화 하느라 덮어쓴 영역에 원래 있었던 코드"를 실행하도록 한다.

### Optimization

- kprobe는 무작정 코드를 덮어쓰지는 않는다. 먼저 `synchronize_rcu()`로 현재 코드에 접근하는 CPU가 접근을 모두 끝낼 때까지 기다린다. 그 다음에는 `text_poke_smp()`라는 함수로 코드 영역을 detour buffer의 시작점으로 점프하는 코드로 덮어씌운다. 이때 i386에서는 5바이트를 덮어씌운다.

### Unoptimization

- 아직 최적화되지 않았는데 최적화를 취소해야 한다면 최적화 리스트에서 사라진다. 그렇지 않은 경우에는 detour buffer로 점프하는 명령어로 덮어썼던 부분을 원래의 코드로 다시 덮어쓴다.

### Blacklist

- kprobe를 등록하면 함수의 경우에는 `include/linux/kprobe.h`의 blacklist에 함수를 추가하거나, 함수에 `NOKPROBE_SYMBOL()` 매크로를 사용해야 한다.

## Configuration

- kprobe는 컴파일시 CONFIG_KPROBES을 설정해서 커널에 추가할 수 있다. 함수의 주소를 계산하는 데 CONFIG_KALLSYMS, CONFIG_KALLSYMS_ALL도 필요할 수 있다.

### Kprobe Features and Limitations

- kprobe는 같은 주소에 여러 개의 probe를 등록할 수 있다. 그런데 post_handler를 갖는 kprobe는 최적화가 불가능하므로 같은 주소에 존재하는 여러 개의 probe중 하나라도 post_handler를 갖는다면 최적화한 것을 다시 취소해야한다. (unoptimization)

- 일반적으로 kprobe는 커널의 거의 모든 코드에 probe를 등록할 수 있다. 인터럽트 핸들러도 가능하다. 다만 kprobe 자체의 코드와, `do_page_fault`, `notifier_call_chain` 함수에는 probe를 등록할 수 없다. `NOKPROBE_SYMBOL()`을 사용하는 함수에도 등록할 수 없다.

- 만약 probe를 등록하려는 함수가 인라인 함수라면 예상하던대로 동작하지 않을 수 있으므로 미리 확인하자. kprobe는 인라인 함수의 모든 사본에 probe를 삽입하지는 않는다.

- kprobe의 핸들러 함수는 커널의 자료구조를 수정할 수 있다. 따라서 ksplice처럼 버그를 고치거나, fault injection 처럼 오류를 테스트 하는 데에도 사용될 수 있다. (대신 주의해야한다.)
- 그리고 kprobe는 핸들러 함수가 probe를 등록한 함수의 호출을 막지 않는다. 예를 들어서 printk에 probe를 등록했는데 핸들러 함수가 다시 printk를 호출하는 경우가 있을 수 있다. 이럴 땐 핸들러 함수가 호출한 printk에 대해서는 다시 핸들러 함수가 호출되지는 않는다. 대신 kprobe 구조체의 nmissed가 증가한다.

- 핸들러 함수를 호출하는 동안에는 선점이나 인터럽트가 비활성화된다. 무엇이 비활성화 되느냐는 최적화를 했냐 안했냐, 또는 아키텍처에 따라 다르다. (x86에서는 선점만 비활성화한다.) 무엇을 비활성화했던 간에 핸들러 함수는 sleep을 해서는 안된다.

- kretprobe를 등록한 함수에서 `__builtin_return_address`를 호출하면 함수의 원래 리턴 주소가 아니라 트램펄린 코드의 리턴 주소가 반환된다.

- 그리고 kprobe는 오버헤드가 어느정도 있기 때문에 성능이 매우 크리티컬한 함수에서는 디버깅용 이상으로는 사용하기 어렵다. production 환경에서 성능 측정을 위해 사용했다가는 수용하기 힘든 성능 저하를 겪을 수 있다.

## Supported Architectures
- i386 (Supports jump optimization)
- x86_64 (AMD-64, EM64T) (Supports jump optimization)
- ppc64
- ia64 (Does not support probes on instruction slot1.)
- sparc64 (Return probes not yet implemented.)
- arm
- ppc
- mips
- s390
- parisc

## 구조체 코드
### kprobe
kprobe의 구조체 코드이다.

```c
struct kprobe {
        struct hlist_node hlist;

        /* list of kprobes for multi-handler support */
        struct list_head list;

        /*count the number of times this probe was temporarily disarmed */
        unsigned long nmissed;

        /* location of the probe point */
        kprobe_opcode_t *addr;

        /* Allow user to indicate symbol name of the probe point */
        const char *symbol_name;

        /* Offset into the symbol */
        unsigned int offset;

        /* Called before addr is executed. */
        kprobe_pre_handler_t pre_handler;

        /* Called after addr is executed, unless... */
        kprobe_post_handler_t post_handler;

        /* Saved opcode (which has been replaced with breakpoint) */
        kprobe_opcode_t opcode;

        /* copy of the original instruction */
        struct arch_specific_insn ainsn;

        /*
         * Indicates various status flags.
         * Protected by kprobe_mutex after this kprobe is registered.
         */
        u32 flags;
};
```

### kretprobe

```c
struct kretprobe
struct kretprobe {
        struct kprobe kp;
        kretprobe_handler_t handler;
        kretprobe_handler_t entry_handler;
        int maxactive;
        int nmissed;
        size_t data_size;
        struct freelist_head freelist;
        struct kretprobe_holder *rph;
};
struct kretprobe_instance
```

### kretprobe_instance

kretprobe_instance는 kretprobe에서 리턴 주소를 저장할때 사용된다.

```c
struct kretprobe_instance {
        union {
                struct freelist_node freelist;
                struct rcu_head rcu;
        };
        struct llist_node llist;
        struct kretprobe_holder *rph;
        kprobe_opcode_t *ret_addr;
        void *fp;
        char data[];
};
```

---
**참고**
 - https://lwn.net/Articles/132196/
 - http://egloos.zum.com/studyfoss/v/5369031
 - http://studyfoss.egloos.com/5371124