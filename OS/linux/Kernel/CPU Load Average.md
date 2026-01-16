리눅스 커널에서는 CPU Load을 평균으로 산출하여 스케쥴링 알고리즘과 CPU 로드 밸런싱등에 사용한다.  여기서 산출하는 CPU Load 평균은 해당 CPU 실행큐에 대해서 전역적(global)으로 걸리는 부하 평균이다.  

<img src="https://github.com/rlaisqls/TIL/assets/81006587/8f64d4be-274d-4598-ac18-64b8fbda038f" style="height: 200px"/>


### 이동평균(Moving Average)

리눅스 커널에서는 CPU 부하 평균(Load Average)을 “이동평균” 방식으로 산출한다. 이동평균(Moving Average)은 선택한 범위(날짜 혹은 시간)안에서 발생한 수치들의 평균이다. 예를들어 정리하면 다음과 같다.

- 1일 이동평균은 1일동안 발생한 수치들의 평균.
- 5일 이동평균은 5일동안 발생한 수치들의 평균.
- 15일 이동평균은 15일동안 발생한 수치들의 평균.
- 1분 이동평균은 1분동안 발생한 수치들의 평균.
- 5분 이동평균은 5분동안 발생한 수치들의 평균.
- 15분 이동평균은 15분동안 발생한 수치들의 평균.

이러한 이동평균을 계산하는 가장 대표적인 방법은 단순이동평균(SMA: Simple Moving Average)과 지수이동평균(EMA: Exponential Moving Average)이 있다. 

- **단순이동평균**(SMA):
  - 일반적으로 평균을 산출하는 방법과 유사하다. 
  - 단순이동평균(SMA)은 범위안의 과거 데이터들을 모두 가지고 있어야 힌다. (합계)

- 5일 단순이동평균은 다음과 같이 계산한다.
  - 5일동안 발생한 수치들의 합계(S): `10 + 20 + 10 + 20 + 50` = `150`
  - 단순이동평균(SMA): `합계(S) / 일수` = `110 / 5` = `22`

- **지수이동평균**(EMA):
  - 가감변수(함수)를 사용하여 최근 수치의 영향력은 높이고 과거 수치의 영향력은 낮추는 방식이다. 이것은 최근에 발생한 수치의 변화를 더 비중있게 반영하는 효과가 있다.
  - 가감변수에는 수학적으로 여러가지 함수를 적용하여 다양하게 파생된 지수이동평균(EMA)을 산출할 수 있다.
  - 지수이동평균(EMA)은 직전 데이터와 현재 데이터만 알아도 된다. (누적)

- 5일 지수이동평균은 다음과 같이 계산힌다.
  - 전일 발생 수치(T1): `20`
  - 금일 발생 수치(T2): `50`
  - 가감변수 계산(E): `2 / (1 + n) = 2 / (1 + 5)` = `0.33`
  - 지수이동평균(EMA): `(T1 x E) + T2 x (1 - E) = 20 x 0.33 + 50 x (1 - 0.33)` = `40.1`

### 커널 CPU Load Average 산출식

리눅스 커널은 CPU Load Average 산출을 위해서 데이터들의 메모리 사용 부담을 줄이고 최근 데이터를 좀더 비중있게 평균에 반영하기 위해 지수이동평균(EMA)을 사용한다. 리눅스 커널에서 CPU Load Average 산출하는 수식은 다음과 같다.
 
```
L2 = L1 x exp_n + A x (1 - exp_n)
```

- `L1`: 지난(과거) Load
- `L2`: 현재 Load
- `A`: 현재 Active Task 개수
- `exp_n`: 지수(Exponetial) 함수
- `_n`: 리포팅 시간(계산 주기: 1분, 5분, 15분)
 
### 커널 CPU Load Average 값 확인

리눅스 터미널에서 아래 명령을 실행하면 현재 계산된 Load Average 값을 확인할 수 있다.

```bash
$ cat /proc/loadavg

0.41 0.38 0.44 1/949 8443
```

> `uptime`, `top` 명령어를 사용해도 1, 5, 15분의 평균값을 확인할 수 있다.

- 첫번째 위치에 출력된 0.41은 CPU Load Average을 1분동안 산출한 1분 지수이동평균값에 해당한다.
- 두번째 수치 0.38은 5분 지수이동평균이다.
- 세번째 수치 0.44는 15분 지수이동평균값에 해당한다.
- 네번째 수치 1/949는 현재 실행되고 있는 태스크수는 1개 이고 전체 태스크수는 949개 임을 나타낸다.
- 마지막 다섯번째 수치 8443은 가장 최근에 실행한 프로세스 번호이다.

이 파일에서 확인할 수 있는 CPU Load Average 수치는 전체 CPU들에 대한 전역적인(Global) Load Average 수치이다. CPU Load Average가 1.0이면 CPU들이 100% 부하로 일하고 있다는 것이고, 0.41 이면 41%는 일하고 59%는 IDLE 상태라는 것을 의미한다. 

```bash
$ cat /proc/loadavg

1.21 0.56 0.50 1/950 8606
```
 
최근 1분동안에 121% CPU 부하가 걸렸고, 5분동안에는 56%, 15분 동안에는 50% 부하가 걸렸다는 의미이다. 121% 부하에서 100%는 CPU가 모두 일하고 있다는 것이고 나머지 21%는 CPU 대기열에서 태스크들이 기다리고 있는 의미가 된다.

위의 결과를 출력하는 리눅스 커널 소스는 `fs/proc/loadavg.c`에 다음과 같이 `loadavg_proc_show()` 함수로 코딩되어 있다.

### `loadavg_proc_show()` 함수

    ```c
    // https://github.com/torvalds/linux/blob/2df0193/fs/proc/loadavg.c#L14
    static int loadavg_proc_show(struct seq_file *m, void *v)
    {
        unsigned long avnrun[3];

        get_avenrun(avnrun, FIXED_1/200, 0);

        seq_printf(m, "%lu.%02lu %lu.%02lu %lu.%02lu %u/%d %d\n",
            LOAD_INT(avnrun[0]), LOAD_FRAC(avnrun[0]),
            LOAD_INT(avnrun[1]), LOAD_FRAC(avnrun[1]),
            LOAD_INT(avnrun[2]), LOAD_FRAC(avnrun[2]),
            nr_running(), nr_threads,
            idr_get_cursor(&task_active_pid_ns(current)->idr) - 1);
        return 0;
    }
    ```
 

위에서 `avenrun[0]`에는 1분 CPU Load Average 값이 저장되어 있고, a`venrun[1]`에는 5분 CPU Load Average 값, `avenrun[2]`에는 15분 CPU Load Average 값이 저장되어 있다. `LOAD_INT()`는 이것의 정수 부분을 가지고 오는 매크로이고, `LOAD_FRAC()`는 소수 부분을 가져오는 매크로이다.

`avenrun[]` 배열에 CPU Load Average 을 계산하는 함수들은 `kernel/sched/loadavg.c` 소스 파일에 코딩되어 있다.

### `calc_global_load_tick()` 함수

이 함수는 `scheduler_tick()` 함수에서 HZ 주기 마다 실행된다. `calc_global_load_tick()` 함수는 `kernel/sched/loadavg.c` 소스 파일에 다음과 같이 코딩 되어있다.

```c
// https://github.com/torvalds/linux/blob/2df0193/kernel/sched/loadavg.c#L385
/*
 * Called from sched_tick() to periodically update this CPU's
 * active count.
 */
void calc_global_load_tick(struct rq *this_rq)
{
	long delta;

	if (time_before(jiffies, this_rq->calc_load_update))
		return;

	delta  = calc_load_fold_active(this_rq, 0);
	if (delta)
		atomic_long_add(delta, &calc_load_tasks);

	this_rq->calc_load_update += LOAD_FREQ;
}
```

이 함수는 현재 실행되고 있는 `this_rq`에 대해서 작업한다. 이 함수가 HZ 주기마다 실행 되지만, `if (time_before(jiffies, this_rq->calc_load_update))` 조건에 의해서 jiffies가 `this_rq->calc_load_update`보다 작으면 바로 리턴된다. `this_rq->calc_load_update` 값은 `LOAD_FREQ` 만큼씩 증가한다. `LOAD_FREQ`는 `(5*HZ+1)`로 정의 되어 있으므로 5초 주기가 된다. 따라서 `calc_global_load_tick()` 함수는 5초마다 실행 되면서 전역변수인 `calc_load_tasks` 값을 계산한다.

calc_load_tasks 값은 `calc_load_fold_active()` 함수에서 계산한 delta을 덧셈한 값이다. `calc_load_fold_active()` 함수는 다음과 같이 코딩되어 있다.

 
```c
// https://github.com/torvalds/linux/blob/2df0193/kernel/sched/loadavg.c#L78
long calc_load_fold_active(struct rq *this_rq, long adjust)
{
	long nr_active, delta = 0;

	nr_active = this_rq->nr_running - adjust;
	nr_active += (int)this_rq->nr_uninterruptible;

	if (nr_active != this_rq->calc_load_active) {
		delta = nr_active - this_rq->calc_load_active;
		this_rq->calc_load_active = nr_active;
	}

	return delta;
}
```
 
이 함수는 현재 실행되고 있는 `this_rq` 에 대해서 작업한다. `nr_active`은 `this_rq->nr_running`과 `this_rq->nr_uninterruptible`을 덧셈한 값이다. `nr_active`와 `this_rq->calc_load_active`가 다르다면 둘사이의 차이값을 delta에 저장하고 `nr_active`는 `this_rq->calc_load_active`에 저장 한다.

### `calc_global_load()` 함수

`calc_global_load()` 함수는 `calc_global_load_tick()` 함수에서 계산하여 전역변수로 가지고 있는 calc_load_tasks에서 active 태스크 개수를 계산한후 CPU Load Average을 산출하여 `avenrun[]` 배열에 저장한다. 실행 주기는 `LOAD_FREQ`이다.

```c
// https://github.com/torvalds/linux/blob/2df0193/kernel/sched/loadavg.c#L349
/*
 * calc_load - update the avenrun load estimates 10 ticks after the
 * CPUs have updated calc_load_tasks.
 *
 * Called from the global timer code.
 */
void calc_global_load(void)
{
	unsigned long sample_window;
	long active, delta;

	sample_window = READ_ONCE(calc_load_update);
	if (time_before(jiffies, sample_window + 10))
		return;

	/*
	 * Fold the 'old' NO_HZ-delta to include all NO_HZ CPUs.
	 */
	delta = calc_load_nohz_read();
	if (delta)
		atomic_long_add(delta, &calc_load_tasks);

	active = atomic_long_read(&calc_load_tasks);
	active = active > 0 ? active * FIXED_1 : 0;

	avenrun[0] = calc_load(avenrun[0], EXP_1, active);
	avenrun[1] = calc_load(avenrun[1], EXP_5, active);
	avenrun[2] = calc_load(avenrun[2], EXP_15, active);

	WRITE_ONCE(calc_load_update, sample_window + LOAD_FREQ);

	/*
	 * In case we went to NO_HZ for multiple LOAD_FREQ intervals
	 * catch up in bulk.
	 */
	calc_global_nohz();
}
```

위의 소스에서 `calc_load()` 함수가 지수이동평균을 사용하여 CPU Load Average을 산출하는 함수이다. 실행중인 태스크 개수(active)는 앞에서 계산한 `calc_load_tasks` 값에서 가지고 온다. `EXP_1`은 1분 지수이동평균, EXP_5는 5분 지수이동평균, EXP_15는 15분 지수이동평균을 계산하기 위한 지수값이다. 이 값들을 `calc_load()` 함수에 전달하여 CPU Load Average을 계산한다.


### `calc_load()` 함수

`calc_load()` 함수는 `include/linux/sched/loadavg.h `헤더 파일에 다음과 같이 코딩되어 있다.

```c
// https://github.com/torvalds/linux/blob/2df0193/include/linux/sched/loadavg.h#L29
#define FSHIFT		11		/* nr of bits of precision */
#define FIXED_1		(1<<FSHIFT)	/* 1.0 as fixed-point */
#define LOAD_FREQ	(5*HZ+1)	/* 5 sec intervals */
#define EXP_1		1884		/* 1/exp(5sec/1min) as fixed-point */
#define EXP_5		2014		/* 1/exp(5sec/5min) */
#define EXP_15		2037		/* 1/exp(5sec/15min) */

/*
 * a1 = a0 * e + a * (1 - e)
 */
static inline unsigned long
calc_load(unsigned long load, unsigned long exp, unsigned long active)
{
	unsigned long newload;

	newload = load * exp + active * (FIXED_1 - exp);
	if (active >= load)
		newload += FIXED_1-1;

	return newload / FIXED_1;
}
```
 

앞에서 지수이동평균 산출식에 대해서 기술한 수식이 `calc_load()` 함수에 적용된다. 이 함수의 주석에서 산출식을 다음과 같이 표현하고 있다. 변수 명칭만 다를뿐, 지수이동평균 산출식과 동일하다.

```c
a1 = a0 * e + a * (1 - e)
```

a0는 이전에 산출한 CPU Load이고 a는 active 태스크 수, e는 지수 함수값이다. a0는 `calc_load()` 함수에 load라는 파라미터 변수에 전달되고, a는 `active`에, e는 `exp` 파라미터 변수에 전달된다.  `calc_load()` 함수는 이들을 전달 받아서 a1 즉 newload을 다음과 같이 산출한다.

 
```c
newload = load * exp + active * (FIXED_1 - exp)
```
 
위의 수식에서 `FIXED_1`은 2^11승에 해당하는 값인 2048이다. 이 값은 실수 1.0에 해당한다. 리눅스 커널은 실수 연산을 고정 소숫점 연산으로 대체하기 위해서 10비트는 정수, 11비트는 실수 위치로 비트단위로 시프트하여 계산한다. 이것을 이진화정수 연산이라 하는데, 이렇게 하면 실수연산에서 발생하는 속도저하를 회피할 수 있다.

위에서 EXP_1으로 정의한 1884도 이진화정수 값이다. 이것이 어떻게 계산된 값인지 역산해보자.

```
EXP_1 = 1/exp(5sec/1min) = 1/exp(5/60) = 1/1.087 = 0.92
실수 0.92에 1.0에 해당하는 이진화정수값 2048을 곱하면,
0.92 x 2048 = 1884
```

이진화정수에서 정수 부분과 소수 부분을 가지고 오는 방법은 `include/linux/sched/loadavg.h`에 정의 되어 있는 `LOAD_INT()`와 `LOAD_FRAC()` 매크로를 사용한다. 이 매크로는 앞에서 잠깐 언급한 `loadavg_proc_show()` 함수에서 사용되었다.

```c
#define FSHIFT 11
#define LOAD_INT(x) ((x) >> FSHIFT)
#define LOAD_FRAC(x) LOAD_INT(((x) & (FIXED_1-1)) * 100)
```

---
참고
- https://kernel.bz/boardPost/118683/9?boardPage=3
- https://www.brendangregg.com/blog/2017-08-08/linux-load-averages.html
- https://unix.stackexchange.com/questions/730922/difference-between-the-cpu-usage-and-load-average-and-when-should-it-be-a-conc