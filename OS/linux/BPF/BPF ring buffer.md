- BPF 프로그램은 수집한 데이터를 후처리하고 로깅하기 위해 User space로 전송해야하는데, 대부분의 경우 이를 위해 BPF Perf buffer(Perfbuf)를 사용한다. Perfbuf는 CPU마다 하나씩 생성되는 순환 버퍼로, Kernel space와 Use space간 데이터를 효율적으로 교환할 수 있도록 한다.

- 하지만 Perfbuf에는 두가지의 문제점이 있었다.
  1. 각 CPU에 대해 별도의 버퍼를 사용하기 때문에 데이터 스파이크에 대응하기 위해서 각각의 버퍼크기를 크게 할당해주어야 한다. 이 때문에 필요한 것 보다 더 많은 메모리 공간이 낭비될 수 있다.
  2. 연관된 이벤트가 서로 다른 CPU에서 빠르게 발생하는 경우 이벤트가 순서대로 전달되지 않을 수 있다. 이 때문에 이벤트를 옳은 순서로 재정렬하는 추가 로직이 필요하다.

- 이 문제를 해결하기 위해서 Linux 5.8부터 BPF에 새로운 데이터 구조(BPF map)인 BPF ring buffer(Ringbuf)가 만들어졌다. ringbuf는 여러 생산자와 단일 소비자를 가지는 MPSC 큐이며 여러 CPU에서 안전하게 공유할 수 있다.

- Ringbuf는 모든 CPU에서 하나의 큰 버퍼를 공용으로 사용하게 함으로써 Perfbuf의 문제점을 해결한다. 한 버퍼를 공유하기 때문에 각 버퍼의 크기를 키울 필요 없이 하나의 버퍼 크기만 조정하면 되고, 하나의 큐에서 먼저 발행된 이벤트가 먼저 소비되도록 보장하기에 재정렬을 수행할 필요가 없다.

## 코드 예제

> https://github.com/anakryiko/bpf-ringbuf-examples/tree/main

이 레포지토리의 코드를 살펴보며 활용 방법을 이해해보자.

### BPF Perfbuf 코드 예제

- [BPF 코드](https://github.com/anakryiko/bpf-ringbuf-examples/blob/main/src/perfbuf-output.bpf.c)를 먼저 살펴보자. 우선 BPF를 정의하고 활용하기 위해 `<linux/bpf.h>`와 `<bpf/bpf_helpers.h>`를 include해준다.

    ```c
    #include <linux/bpf.h>
    #include <bpf/bpf_helpers.h>
    #include "common.h"

    char LICENSE[] SEC("license") = "Dual BSD/GPL";
    ```

- BPF perfbuf를 `BPF_MAP_TYPE_PERF_EVENT_ARRAY` 맵으로 정의한다. libbpf가 CPU의 수에 따라 `max_entries` 수를 정해주기 때문에, 해당 값을 직접 정의해주지 않아도 된다. 각 CPU에 해당하는 버퍼 크기는 user space에서 각각 지정해줄 수 있다.

    ```c
    /* BPF perfbuf map */
    struct {
        __uint(type, BPF_MAP_TYPE_PERF_EVENT_ARRAY);
        __uint(key_size, sizeof(int));
        __uint(value_size, sizeof(int));
    } pb SEC(".maps");
    ```

- `common.h`에 정의되어있는 sample 구조체의 크기가 512byte 이상으로 크기 때문에 스택에 데이터를 쌓아놓기 어렵다. 그러므로 CPU당 배열을 임시 저장소로 사용한다.

    ```c
    struct {
        __uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
        __uint(max_entries, 1);
        __type(key, int);
        __type(value, struct event);
    } heap SEC(".maps");
    ```

- 그 다음, BPF 프로그램을 정의하고 `sched:sched_process_exec`에 연결되도록 지정한다. 이 프로그램은 `exec()` 시스템 콜에서 트리거되며, tracepoint 컨텍스트에서 데이터를 가져와 임시 저장소에 채워넣은 후 `bpf_perf_event_output()` 호출을 통해 데이터를 BPF perfbuf로 보낸다.

  - 아래 로직에서 샘플에 대한 임시 저장소를 가져와서 추적 포인트 컨텍스트의 데이터로 채워넣는다.
  - 완료되면 `bpf_perf_event_output()` 콜을 통해 샘플을 BPF perfbuf로 보낸다. 이 API는 현재 CPU의 perf 버퍼에 struct event에 대한 공간을 예약하고, e에서 그 예약된 공간으로 `sizeof(*e)` 바이트의 데이터를 복사한다. 그리고 복사가 완료되면 사용자 공간에 새 데이터가 사용 가능하다는 신호를 보낸다.
  - 이 시점에서 epoll 서브시스템이 사용자 공간 핸들러를 Dispatch하고, 데이터 사본에 대한 포인터를 전달하여 처리한다.
  
    ```c
    SEC("tp/sched/sched_process_exec")
    int handle_exec(struct trace_event_raw_sched_process_exec *ctx)
    {
        unsigned fname_off = ctx->__data_loc_filename & 0xFFFF;
        struct event *e;
        int zero = 0;

        e = bpf_map_lookup_elem(&heap, &zero);
        if (!e) /* can't happen */
            return 0;

        e->pid = bpf_get_current_pid_tgid() >> 32;
        bpf_get_current_comm(&e->comm, sizeof(e->comm));
        bpf_probe_read_str(&e->filename, sizeof(e->filename), (void *)ctx + fname_off);

        bpf_perf_event_output(ctx, &pb, BPF_F_CURRENT_CPU, e, sizeof(*e));
        return 0;
    }
    ```

- 이제 [User space의 코드](https://github.com/anakryiko/bpf-ringbuf-examples/blob/main/src/perfbuf-output.c)를 살펴보자. BPF Skeleton을 활용하여 초기 설정(libbpf logging handler, interupt handler 설정, BPF 시스템의 RLIMIT_MEMLOCK 제한 증가)을 마치고 로드한다. 
- 로드가 성공하면 libbpf의 `perf_buffer__new()` API를 사용하여 perf 버퍼 소비자의 인스턴스를 만든다.

    ```c
	struct perf_buffer *pb = NULL;
	struct perf_buffer_opts pb_opts = {};
	struct perfbuf_output_bpf *skel;

	...

	/* Set up ring buffer polling */
	pb_opts.sample_cb = handle_event;
	pb = perf_buffer__new(bpf_map__fd(skel->maps.pb), 8 /* 32KB per CPU */, &pb_opts);
	if (libbpf_get_error(pb)) {
		err = -1;
		fprintf(stderr, "Failed to create perf buffer\n");
		goto cleanup;
	}
    ```

- 여기서 CPU당 버퍼를 32KB로 지정해주고,(8 pages x 4096 bytes per page) libbpf로 전달된 각 샘플마다 `handle_event()` 콜백 함수를 호출하여 데이터를 `printf()`로 출력하도록 한다.

    ```c
    void handle_event(void *ctx, int cpu, void *data, unsigned int data_sz)
    {
        const struct event *e = data;
        struct tm *tm;
        char ts[32];
        time_t t;

        time(&t);
        tm = localtime(&t);
        strftime(ts, sizeof(ts), "%H:%M:%S", tm);

        printf("%-8s %-5s %-7d %-16s %s\n", ts, "EXEC", e->pid, e->comm, e->filename);
    }
    ```

- 데이터가 있는 경우 poll해오는 코드를 작성한다.

    ```c
        /* Process events */
        printf("%-8s %-5s %-7s %-16s %s\n",
            "TIME", "EVENT", "PID", "COMM", "FILENAME");
        while (!exiting) {
            err = perf_buffer__poll(pb, 100 /* timeout, ms */);
            /* Ctrl-C will cause -EINTR */
            if (err == -EINTR) {
                err = 0;
                break;
            }
            if (err < 0) {
                printf("Error polling perf buffer: %d\n", err);
                break;
            }
        }
    ```


### BPF ringbuf 코드 예제

- 위에서 작성했던 코드를 ringbuf로 변경하기 위해선, 몇몇 부분만 수정해주면 된다.
- BPF 코드에서 BPF ringbuf의 `bpf_ringbuf_output()` API는 `bpf_perf_event_output()`와 같은 역할을 수행한다. 그러므로 위의 코드에서 주석처리된 부분을 지우고 아래 부분을 수정하면 된다.
  - `bpf_perf_event_output()`는 `bpf_ringbuf_output()`으로 대체한다. ringbuf API는 BPF 프로그램의 컨텍스트에 대한 참조가 필요하지 않다.
  - BPF ringbuf 맵의 크기는 BPF 측에서 정의할 수 있다. 필요하다면 사용자 공간에서 크기를 지정하거나 재정의할 수도 있다. 크기는 바이트 단위로 지정되며, 페이지 크기보다 큰 2의 거듭제곱수여야 한다.

    ```c
    struct {
    //	__uint(type, BPF_MAP_TYPE_PERF_EVENT_ARRAY);
    //	__uint(key_size, sizeof(int));
    //	__uint(value_size, sizeof(int));
    // } pb SEC(".maps");
        __uint(type, BPF_MAP_TYPE_RINGBUF);
        __uint(max_entries, 256 * 1024 /* 256 KB */);
    } rb SEC(".maps");
    
    struct {
        __uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
        bpf_get_current_comm(&e->comm, sizeof(e->comm));
        bpf_probe_read_str(&e->filename, sizeof(e->filename), (void *)ctx + fname_off);
    
        // bpf_perf_event_output(ctx, &pb, BPF_F_CURRENT_CPU, e, sizeof(*e));
        bpf_ringbuf_output(&rb, e, sizeof(*e), 0);
        return 0;
    } 
    ```

- User space 코드에서 이벤트 핸들러 콜백을 정의할 때 CPU의 인덱스를 없애야 한다. Ringbuf에서는 여러 CPU가 버퍼를 공유하기 때문에 Lock 경합을 최소화 하기 위해 CPU 인덱싱과 샘플 콜백 기능이 제외되었다. 만약 CPU 인덱스를 알아야 하는 경우 BPF 측에서 명시적으로 샘플에 기록해야 한다.

    ```c
    // int handle_event(void *ctx, int cpu, void *data, unsigned int data_sz)
    int handle_event(void *ctx, void *data, size_t data_sz)
    {
        const struct event *e = data;
        struct tm *tm;
    ```

- `perf_buffer__new()`를 `ring_buffer__new()` 함수로 대체한다. 콜백을 지정할 때도 추가 옵션 구조체 부분을 생략할 수 있다. 
  
```c
 	/* Set up ring buffer polling */
    // pb_opts.sample_cb = handle_event;
    // pb = perf_buffer__new(bpf_map__fd(skel->maps.pb), 8 /* 32KB per CPU */, &pb_opts);
    // if (libbpf_get_error(pb)) {
 	rb = ring_buffer__new(bpf_map__fd(skel->maps.rb), handle_event, NULL, NULL);
 	if (!rb) {
 		err = -1;
        // fprintf(stderr, "Failed to create perf buffer\n");
 		fprintf(stderr, "Failed to create ring buffer\n");
 		goto cleanup;
 	}
```

- `perf_buffer__poll()`을 `ring_buffer__poll()`로 대체하여 ring 버퍼 데이터를 동일한 방식으로 소비할 수 있다.

```c
 	printf("%-8s %-5s %-7s %-16s %s\n",
 	       "TIME", "EVENT", "PID", "COMM", "FILENAME");
 	while (!exiting) {
 		// err = perf_buffer__poll(pb, 100 /* timeout, ms */);
 		err = ring_buffer__poll(rb, 100 /* timeout, ms */);
 		/* Ctrl-C will cause -EINTR */
 		if (err == -EINTR) {
 			err = 0;
 			break;
 		}
 		if (err < 0) {
            // printf("Error polling perf buffer: %d\n", err);
			printf("Error polling ring buffer: %d\n", err);
 			break;
 		}
 	}
```

### reserve/submit 예제

- `bpf_ringbuf_output()`는 BPF perfbuf에서 BPF ringbuf로의 원활한 전환이 가능하도록 구현되었다. 샘플을 구성하기 전에 버퍼로 복사하기 위해 추가 공간이 필요하다는 단점이 생겼다. 또, 이벤트가 갑작스럽게 많이 들어와 버퍼가 오버플로우되면, 샘플을 구성하는 작업이 낭비될 수도 있다.

- 그러나 데이터가 삭제될 것이라는 것을 알고 있다면 처음부터 수집을 건너 뛰어 consumer 측의 리소스를 아낄 수 있다. BPF ringbuf에서는 `bpf_ringbuf_reserve()`와 `bpf_ringbuf_submit()`를 통해 그러한 문제를 해결한다. 이 함수들을 사용하면 사용할 공간을 일찍 예약하고, 샘플을 수집할 공간이 충분하지 않은 경우엔 데이터 수집을 미리 건너뛸 수 있다. 
  - 예약이 성공하면 데이터 수집이 완료된 후 사용자 공간에 발행하는 것이 실패하지 않을 것임을 보장한다. 즉, `bpf_ringbuf_reserve()`가 NULL 포인터를 반환하지 않으면 이후의 `bpf_ringbuf_submit()`은 항상 성공할 것이다.

- Ringbuf 자체의 예약된 공간은 submit될 때까지 사용자 공간에서 보이지 않으므로, 복잡한 구조의 코드에서도 샘플을 구성할 때 쉽게 활용할 수 있다. 또한 reserve를 활용하면 추가 메모리 복사 및 임시 저장 공간의 필요성이 없어진다. 
- 단, reserve의 크기가 BPF 검증기에서 검증 시간에 알려져야 한다는 제약사항이 있다. 따라서 동적 크기의 샘플의 경우 `bpf_ringbuf_output()`을 사용하여 처리해야 하며 추가 복사의 비용을 감당해야한다.

- 따라서 대부분의 경우에는 reserve/submit를 사용하는 것이 좋다. 코드를 아래와 같이 수정하여 적용할 수 있다.
- per-CPU 배열을 없애는 대신 `bpf_ringbuf_reserve()`의 결과를 사용하여 샘플을 데이터로 채우도록 한다.
  
    ```c
    // struct {
    // 	    __uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
    // 	    __uint(max_entries, 1);
    // 	    __type(key, int);
    //      __type(value, struct event);
    // } heap SEC(".maps");
    SEC("tp/sched/sched_process_exec")
    int handle_exec(struct trace_event_raw_sched_process_exec *ctx)
    {
        unsigned fname_off = ctx->__data_loc_filename & 0xFFFF;
        struct event *e;
        // int zero = 0;
        
        // e = bpf_map_lookup_elem(&heap, &zero);
        // if (!e) /* can't happen */
        e = bpf_ringbuf_reserve(&rb, sizeof(*e), 0);
        if (!e)
            return 0;
    
        e->pid = bpf_get_current_pid_tgid() >> 32;
        bpf_get_current_comm(&e->comm, sizeof(e->comm));
        bpf_probe_read_str(&e->filename, sizeof(e->filename), (void *)ctx + fname_off);
    
        // bpf_ringbuf_output(&rb, e, sizeof(*e), 0);
        bpf_ringbuf_submit(e, 0);
        return 0;
    }
    ```

### BPF ringbuf: 데이터 알림

- 처리량이 많은 경우 샘플이 submit될 때 커널의 폴링/epoll 시스템을 통해 user space handler가 대기 중인 새 데이터를 받아 wake up하는 동작에서 가장 큰 오버헤드가 발생한다. (이는 perfbuf 및 ringbuf 모두에 동일하다.)

- Perfbuf는 샘플된 알림을 설정할 수 있는 기능으로 이를 개선한다. 모든 샘플에 대해 즉시 처리하지 않고, n번째 샘플만 알림을 보내어 처리하도록 하는 것이다. 사용자 공간에서 BPF perfbuf 맵을 생성할 때 이를 설정할 수 있다.

- BPF ringbuf의 `bpf_ringbuf_output()`와 `bpf_ringbuf_submit()`는 이를 조금 다른 방식으로 해결한다.
  
- 해당 함수들의 추가 플래그 인자로 `BPF_RB_NO_WAKEUP`을 지정하면 커널에서 데이터 가용성 알림을 보내지 않도록 한다. 반면에 `BPF_RB_FORCE_WAKEUP`은 알림을 강제로 보낸다. 이렇게 하면 필요한 경우 정확한 수동 제어가 가능해진다. ([Benchmark 참고](https://github.com/torvalds/linux/blob/master/tools/testing/selftests/bpf/progs/ringbuf_bench.c#L22-L31))

- 플래그가 지정되지 않은 경우 BPF ringbuf 코드는 기본적으로 user space consumer의 처리 지연 여부에 따라 적응적인 알림을 수행한다. 플래그가 없는 것이 대부분의 경우에는 안전한 기본값이지만 필요한 경우에는 사용자 정의 기준(예: 버퍼에 인큐된 데이터 양)에 따라 데이터 알림을 수동으로 제어하는 것이 성능을 크게 향상시킬 수 있다.

---
참고
- https://nakryiko.com/posts/bpf-ringbuf/
- https://www.kernel.org/doc/html/next/bpf/ringbuf.html
- https://elixir.bootlin.com/linux/latest/source/kernel/bpf/ringbuf.c