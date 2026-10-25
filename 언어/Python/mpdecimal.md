mpdecimal(libmpdec)은 임의 정밀도 십진 부동소수점 연산을 하는 C 라이브러리다. IBM Mike Cowlishaw의 [General Decimal Arithmetic Specification](https://speleotrove.com/decimal/decarith.html)(IEEE 754-2008 십진 연산의 바탕)을 구현한 것이고, CPython `decimal` 모듈의 C 구현(`_decimal`)이 이 위에서 실행된다.

```python
>>> 0.1 + 0.2
0.30000000000000004
>>> Decimal('0.1') + Decimal('0.2')
Decimal('0.3')
>>> Decimal('1.30') + Decimal('1.20')
Decimal('2.50')
```

- 이진 float는 `0.1`을 정확히 담지 못한다. Decimal은 값을 "십진 정수 계수 × 10^지수"로 들고 있어서 사람이 쓴 십진수를 그대로 표현한다.
- `2.50`처럼 끝의 0도 보존한다. 같은 값이어도 `2.5`와 `2.50`은 지수가 다른 별개의 표현이고, 스펙은 이 차이(유효 자릿수)를 의미 있는 정보로 취급한다.
- 정밀도는 고정이 아니라 **context**가 정한다. Python 기본값은 28자리이고, 64비트 빌드에서는 최대 `MPD_MAX_PREC = 999999999999999999`자리까지 올릴 수 있다.

| file | role |
|---|---|
| `mpdecimal.c` | 스펙의 모든 연산 quiet 버전 |
| `mpsignal.c` | quiet 함수를 감싸 status를 context에 반영하는 signaling 버전 |
| `context.c` | context 초기화(`mpd_defaultcontext`, `mpd_ieee_context` 등), trap 처리 |
| `basearith.c` | 10^19(32비트는 10^9) 진법 워드 배열에 대한 덧셈·곱셈·나눗셈 |
| `io.c` | 문자열 ↔ `mpd_t` 변환, 포맷팅 |
| `mpalloc.c` | 할당, static ↔ dynamic 전환 |
| `typearith.h` | 더블워드 곱셈·나눗셈 같은 저수준 primitive |
| `numbertheory.c`, `fnt.c`, `sixstep.c`, `fourstep.c`, `convolute.c`, `crt.c`, `transpose.c`, `umodarith.h`, `difradix2.c` | 큰 수 곱셈용 Number Theoretic Transform |

`literature/` 디렉터리에는 FNT 설명(`bignum.txt`), 알고리즘 증명(`matrix-transform.txt`, `mulmod-64.txt`), `umodarith.h`의 ACL2 증명(`umodarith.lisp`)까지 들어 있다.

## `mpd_t`

```c
typedef struct mpd_t {
    uint8_t flags;
    mpd_ssize_t exp;
    mpd_ssize_t digits;
    mpd_ssize_t len;
    mpd_ssize_t alloc;
    mpd_uint_t *data;
} mpd_t;
```

(`mpdecimal.h.in#L314-L321`)

값은 `(-1)^sign × coefficient × 10^exp`다.

| 필드 | 뜻 |
|---|---|
| `flags` | 부호와 특수값(`MPD_NEG`, `MPD_INF`, `MPD_NAN`, `MPD_SNAN`), 메모리 소유권(`MPD_STATIC`, `MPD_STATIC_DATA`, `MPD_SHARED_DATA`, `MPD_CONST_DATA`) |
| `exp` | 10의 지수 |
| `digits` | 계수의 십진 자릿수 |
| `len` | 계수가 실제로 쓰는 워드 수 |
| `alloc` | `data`에 할당된 워드 수 |
| `data` | 계수. 워드 하나가 0 ~ 10^19-1을 담는 little-endian 배열 |

계수는 이진 bignum이 아니라 **10^19 진법**이다(`MPD_RADIX 10000000000000000000ULL`, `MPD_RDIGITS 19`, `mpdecimal.h.in#L102-L103`). 10^19는 2^64(약 1.8 × 10^19)보다 작은 가장 큰 10의 거듭제곱이라 64비트 워드에 꽉 차게 들어간다. 32비트 빌드는 같은 이유로 10^9를 쓴다.

```
Decimal('12345678901234567890123')
  digits = 23, len = 2, exp = 0
  data[0] = 5678901234567890123   ← 아래 19자리
  data[1] = 1234

Decimal('-1.50')
  flags = MPD_NEG, exp = -2, digits = 3, len = 1
  data[0] = 150
```

**왜 10^19 진법인가**

이진 bignum(GMP 같은)으로 계수를 들면 곱셈은 빠르지만, 십진 연산에서 매번 필요한 작업이 비싸진다.

- 반올림은 "십진 자릿수 몇 개를 잘라낸다"는 연산이다. 10^19 진법이면 워드 단위로 자르고, 워드 안에서는 10^k로 나누면 된다. 이진이면 큰 수 나눗셈이 필요하다.
- `digits`(자릿수)를 알아야 정밀도 초과 여부를 판단할 수 있다. 10^19 진법이면 `(len-1)*19 + 맨 위 워드의 자릿수`로 바로 나온다(`mpd_setdigits`, `mpdecimal.c#L616`).
- 문자열 변환이 워드마다 19자리씩 독립적이라 선형 시간이다.

대신 캐리 처리에 `< MPD_RADIX` 비교가 들어가고, 곱셈 결과를 2^64가 아니라 10^19로 나눠야 하는 비용이 있다. `typearith.h`의 더블워드 나눗셈이 이 부분을 맡는다.

**메모리: static과 dynamic**

`MPD_NEW_STATIC` 매크로로 스택에 `mpd_t`와 작은 `data` 버퍼(`MPD_MINALLOC_MAX = 64`워드)를 같이 잡을 수 있다. 결과가 버퍼보다 커지면 `mpd_switch_to_dyn`(`mpalloc.c#L209`)이 heap으로 옮기고 `MPD_STATIC_DATA` 플래그를 내린다. 함수 안에서 쓰는 임시값 대부분이 이 방식이라 작은 수 연산에서는 malloc이 거의 일어나지 않는다.

CPython은 이 구조를 객체에 그대로 박아 둔다([_decimal.c#L203-L208](https://github.com/python/cpython/blob/f81c03a673ae1c71ad18845b0407f26e6cf64159/Modules/_decimal/_decimal.c#L203-L208)).

```c
typedef struct {
    PyObject_HEAD
    Py_hash_t hash;
    mpd_t dec;
    mpd_uint_t data[_Py_DEC_MINALLOC];  /* 4워드 = 76자리 */
} PyDecObject;
```

모듈 초기화 때 `mpd_setminalloc(4)`를 부르고 할당 함수를 `PyMem_Malloc` 계열로 바꾼다([_decimal.c#L7765-L7773](https://github.com/python/cpython/blob/f81c03a673ae1c71ad18845b0407f26e6cf64159/Modules/_decimal/_decimal.c#L7765-L7773)). 76자리 이하의 Decimal은 객체 할당 한 번으로 끝난다.

## Context

모든 연산은 context를 받는다. 결과를 몇 자리로, 어떻게 반올림할지, 어떤 상황을 에러로 볼지가 여기 들어 있다.

```c
typedef struct mpd_context_t {
    mpd_ssize_t prec;   /* precision */
    mpd_ssize_t emax;   /* max positive exp */
    mpd_ssize_t emin;   /* min negative exp */
    uint32_t traps;     /* status events that should be trapped */
    uint32_t status;    /* status flags */
    uint32_t newtrap;   /* set by mpd_addstatus_raise() */
    int      round;     /* rounding mode */
    int      clamp;     /* clamp mode */
    int      allcr;     /* all functions correctly rounded */
} mpd_context_t;
```

(`mpdecimal.h.in#L203-L213`)

미리 정의된 context는 다음과 같다(`context.c#L86-L148`).

| 함수 | prec | round | traps | 비고 |
|---|---|---|---|---|
| `mpd_maxcontext` | `MPD_MAX_PREC` | HALF_EVEN | 기본 | |
| `mpd_defaultcontext` | 38 (`2*MPD_RDIGITS`) | HALF_UP | 기본 | |
| `mpd_basiccontext` | 9 | HALF_UP | 기본 + Clamped | 스펙의 basic context |
| `mpd_ieee_context(ctx, bits)` | `9*(bits/32)-2` | HALF_EVEN | 없음 | decimal32/64/128 → 7/16/34자리, `clamp=1` |

Python의 기본 context(`prec=28, HALF_EVEN, Emax=999999`)는 libmpdec 쪽이 아니라 `_decimal.c`가 따로 만든다. 현재 context는 `contextvars`에 저장돼서 스레드와 asyncio task마다 독립적이다([_decimal.c#L1987](https://github.com/python/cpython/blob/f81c03a673ae1c71ad18845b0407f26e6cf64159/Modules/_decimal/_decimal.c#L1987)).

**반올림 모드**

| 모드 | 동작 | 2.5 → | -2.5 → |
|---|---|---|---|
| `MPD_ROUND_UP` | 0에서 멀어지는 쪽 | 3 | -3 |
| `MPD_ROUND_DOWN` | 0 쪽(버림) | 2 | -2 |
| `MPD_ROUND_CEILING` | +∞ 쪽 | 3 | -2 |
| `MPD_ROUND_FLOOR` | -∞ 쪽 | 2 | -3 |
| `MPD_ROUND_HALF_UP` | 반은 올림(학교식 반올림) | 3 | -3 |
| `MPD_ROUND_HALF_DOWN` | 반은 내림 | 2 | -2 |
| `MPD_ROUND_HALF_EVEN` | 반은 짝수 쪽(banker's rounding) | 2 | -2 |
| `MPD_ROUND_05UP` | 버린 뒤 마지막 자리가 0이나 5면 0에서 멀어지게 | 2 | -2 |
| `MPD_ROUND_TRUNC` | 버림이지만 overflow 때 Infinity를 낸다 | | |

`MPD_ROUND_TRUNC`는 스펙에 없는 libmpdec 전용 모드다. HALF_EVEN이 기본인 이유는 반올림 오차가 위아래로 고르게 퍼져 합계를 낼 때 치우침이 쌓이지 않기 때문이다.

## Status와 trap

연산 중에 생긴 일은 비트 플래그로 기록된다(`mpdecimal.h.in#L217-L232`).

| 플래그 | 언제 |
|---|---|
| `MPD_Inexact` | 반올림으로 0이 아닌 자리가 버려졌다 |
| `MPD_Rounded` | 자리가 버려졌다(0이었어도) |
| `MPD_Clamped` | 지수가 범위에 맞게 조정됐다 |
| `MPD_Overflow` / `MPD_Underflow` / `MPD_Subnormal` | 지수 범위를 넘거나 모자랐다 |
| `MPD_Division_by_zero` | 0이 아닌 수 / 0 |
| `MPD_Invalid_operation` | `0/0`, `Inf - Inf`, sNaN 피연산자 등 |
| `MPD_Conversion_syntax` | 문자열 파싱 실패 |
| `MPD_Division_impossible` / `MPD_Division_undefined` | 정수 나눗셈 결과가 정밀도를 넘음 / `0 // 0` |
| `MPD_Malloc_error` | 메모리 부족 |

API는 두 벌이다.

- **quiet** (`mpd_qadd` 등, 이름에 `q`): `uint32_t *status`에 플래그를 OR만 하고 끝난다. `mpdecimal.c`의 함수가 전부 이쪽이다.
- **signaling** (`mpd_add` 등): quiet 버전을 부른 뒤 `mpd_addstatus_raise`로 context의 `status`에 더하고, `traps`에 걸리는 플래그가 있으면 `mpd_traphandler`를 부른다(`mpsignal.c#L495-L500`, `context.c#L278-L285`). 기본 핸들러는 `raise(SIGFPE)`다(`context.c#L36-L40`).

CPython은 quiet 버전만 쓴다. 매 연산 뒤 `dec_addstatus`가 status를 context에 더하고, trap된 플래그가 있으면 그에 맞는 Python 예외를 세운다([_decimal.c#L611-L639](https://github.com/python/cpython/blob/f81c03a673ae1c71ad18845b0407f26e6cf64159/Modules/_decimal/_decimal.c#L611-L639)). 플래그와 예외 클래스의 대응표는 [`signal_map_template`](https://github.com/python/cpython/blob/f81c03a673ae1c71ad18845b0407f26e6cf64159/Modules/_decimal/_decimal.c#L290-L301)에 있다. 여러 libmpdec 플래그(`Conversion_syntax`, `Division_impossible`, `Division_undefined`, `Invalid_context`, `Malloc_error`, ...)를 묶은 `MPD_IEEE_Invalid_operation`이 `decimal.InvalidOperation` 하나로 나간다. libmpdec의 trap handler 자리에는 아무것도 안 하는 `dec_traphandler`를 꽂아 둔다.

```python
>>> getcontext()
Context(prec=28, rounding=ROUND_HALF_EVEN, Emin=-999999, Emax=999999, capitals=1, clamp=0, flags=[Inexact, Rounded], traps=[InvalidOperation, DivisionByZero, Overflow])
>>> Decimal(1) / 0
decimal.DivisionByZero: [<class 'decimal.DivisionByZero'>]
>>> getcontext().traps[DivisionByZero] = False
>>> Decimal(1) / 0
Decimal('Infinity')
```

## 연산의 공통 흐름

연산은 대체로 "정확한 결과를 구한다 → `mpd_qfinalize`로 context에 맞춘다"의 두 단계다.

```
mpd_qadd(result, a, b, ctx, &status)
  ├─ 특수값(NaN, Inf) 처리
  ├─ 지수를 맞추고 계수를 더한다    ← 이 시점까지는 정확한 값
  └─ mpd_qfinalize(result, ctx, status)
       ├─ _mpd_check_exp: emax/emin 검사 → Overflow, Underflow, Subnormal, Clamped
       └─ _mpd_check_round: digits > prec이면 잘라내고 반올림 → Rounded, Inexact
```

(`mpd_qfinalize`, `mpdecimal.c#L1965-L1976`)

- 덧셈·곱셈은 정확한 결과가 유한하니 이렇게 하면 끝이다. 곱셈 결과의 지수는 두 지수의 합, 계수는 두 계수의 곱이다(`result->exp = big->exp + small->exp`, `mpdecimal.c#L6040` `_mpd_qmul`의 끝부분).
- 나눗셈은 몫이 무한소수일 수 있다. `prec`보다 몇 자리 더 구하고 나머지가 0인지로 Inexact를 판정한다.
- `exp`, `ln`, `log10`, `pow`, `sqrt`처럼 결과가 대부분 무리수인 함수는 따로 다룬다. 아래 [올바른 반올림](#올바른-반올림-correctly-rounded) 참고.

## 곱셈

`_mpd_qmul`(`mpdecimal.c#L6040`)은 두 피연산자 중 작은 쪽의 워드 수(`small->len`)와 결과 워드 수(`rsize`)로 알고리즘을 고른다.

| 조건 | 알고리즘 | 복잡도 |
|---|---|---|
| 큰 쪽이 1워드 | `_mpd_singlemul` | O(1) |
| `rsize <= 64` 또는 `small->len <= 256` | `_mpd_basemul`(학교식), 한쪽이 1워드면 `_mpd_shortmul` | O(n·m) |
| `rsize <= 1024` | `_mpd_kmul`(Karatsuba, 16워드 이하는 학교식으로) | O(n^1.585) |
| `rsize <= 3 × 2^32` | `_mpd_fntmul`(Number Theoretic Transform) | O(n log n) |
| 그보다 큼 | `_mpd_kmul_fnt`(Karatsuba로 쪼갠 뒤 조각마다 FNT) | |

`rsize <= 64`일 때는 스택 버퍼(`rbuf[MPD_MINALLOC_MAX]`)에 곱해서 결과로 복사하므로 heap 할당이 없다.

**Number Theoretic Transform**

FFT로 곱셈을 하면 계수 배열의 convolution을 O(n log n)에 구할 수 있다. 문제는 복소수 FFT가 부동소수점이라 오차가 생긴다는 점이다. 10^19 진법 워드의 곱은 10^38 근처까지 커지고 길이 n짜리 convolution의 항은 n × 10^38까지 가는데, double의 53비트로는 정확히 담을 수 없다.

NTT는 같은 변환을 복소수 대신 **유한체 Z/pZ**에서 한다. 1의 거듭제곱근 자리에 모듈로 p에서의 원시근을 쓰면 FFT와 같은 구조가 정수 연산만으로 돌아가고, 결과가 정확하다([Pollard 1971](https://www.ams.org/journals/mcom/1971-25-114/S0025-5718-1971-0301966-0/home.html)).

```
_mpd_fntmul(u, v):
    c1 = fnt_convolute(u, v, P1)   # mod P1에서 convolution
    c2 = fnt_convolute(u, v, P2)   # mod P2
    c3 = fnt_convolute(u, v, P3)   # mod P3
    result = crt3(c1, c2, c3)      # 중국인의 나머지 정리로 복원
```

(`literature/bignum.txt`)

- 소수 하나(64비트)로는 convolution 항의 진짜 값을 담기에 범위가 모자란다. 그래서 세 소수로 각각 계산하고 CRT로 P1·P2·P3(약 2^192)까지의 값을 복원한다(`crt3`, `crt.c#L133`).
- 64비트 소수는 `18446744069414584321`(= 2^64 - 2^32 + 1), `18446744056529682433`, `18446742974197923841`이고, 원시근은 각각 7, 10, 19다(`constants.c#L35-L38`). 모두 `k × 2^n + 1` 꼴이라 길이 2^n짜리 변환에 필요한 거듭제곱근이 존재한다.
- 변환 길이에 따라 구현이 셋이다. 4096워드 이하의 2^n 길이는 `std_fnt`(decimation in frequency), 그보다 큰 2^n 길이는 캐시 친화적인 `six_step_fnt`, 3 × 2^n 길이는 `four_step_fnt`다(`SIX_STEP_THRESHOLD`, `convolute.c#L62-L75`). 3 × 2^n을 지원하는 이유는 길이를 2^n으로만 맞추면 최악의 경우 패딩이 거의 두 배가 되기 때문이다.
- mod p 곱셈(`umodarith.h`)은 128비트 곱을 p로 나누는 대신, 소수가 `2^64 - 2^n + 1` 꼴인 점을 이용해 `hi × 2^n - hi + lo`로 축약한다. 이 루틴의 정당성은 `literature/mulmod-64.txt`와 ACL2 증명으로 따로 검증돼 있다.

## 나눗셈과 Newton 반복

`_mpd_qdiv`(`mpdecimal.c#L3755`)도 제수의 워드 수로 나뉜다.

| 제수 길이 | 알고리즘 |
|---|---|
| 1워드 | `_mpd_shortdiv`(`basearith.c#L269`) |
| 1024워드 이하 (`MPD_NEWTONDIV_CUTOFF`) | `_mpd_basedivmod`, Knuth Algorithm D(`basearith.c#L300`) |
| 그보다 김 | `_mpd_base_ndivmod`, Newton 반복으로 역수를 구해 곱한다(`mpdecimal.c#L7690`) |

Newton 방식은 `x ← x(2 - v·x)`로 1/v를 구한다. 한 번 돌 때마다 맞는 자릿수가 두 배가 되므로 정밀도를 처음부터 끝까지 다 쓰지 않고 단계별로 두 배씩 올린다(`_mpd_qreciprocal`, `mpdecimal.c#L7603`). 각 단계가 곱셈 몇 번이라 나눗셈 비용이 곱셈 비용의 상수 배가 된다. 큰 수에서 곱셈이 FNT로 O(n log n)이니 나눗셈도 같이 빨라진다. 같은 구조로 `mpd_qinvroot`(1/√x)와 `mpd_qsqrt`가 구현돼 있다.

## 반올림

`exp(x)`의 결과를 28자리로 내려면, 진짜 값을 28자리로 반올림한 것과 같아야 한다. 그런데 진짜 값은 무한소수라 직접 구할 수 없다. 30자리쯤 근삿값을 구해 반올림하면 대부분 맞지만, 진짜 값이 `...4999999999|7`처럼 반올림 경계에 아주 가까우면 근삿값의 오차 때문에 반대쪽으로 반올림될 수 있다(Table Maker's Dilemma).

libmpdec은 `ctx->allcr = 1`(기본값)이면 **Ziv의 전략**으로 이를 해결한다(`mpd_qexp`, `mpdecimal.c#L4519-L4618`).

```
prec = ctx->prec + 3
loop:
    r = exp(x) 를 prec 자리로 계산      # 오차 < 1 ulp가 보장됨
    hi = round(r + ulp),  lo = round(r - ulp)    # ctx->prec 자리로
    if hi == lo: return round(r)        # 진짜 값이 [r-ulp, r+ulp] 안에 있으니 반올림 결과가 확정
    prec += 19                          # 경계에 걸쳤으면 정밀도를 올려 다시
                                        # (subnormal 판정이 갈리면 prec *= 2)
```

- 진짜 값은 `r - ulp`와 `r + ulp` 사이 어딘가에 있다. 그 구간의 양 끝을 반올림한 결과가 같으면 구간 안의 어떤 값을 반올림해도 같다. 그래서 진짜 값을 몰라도 결과가 확정된다.
- 경계에 가까울수록 반복이 늘지만, 대부분은 첫 번째 시도에서 끝난다.
- `ln`, `log10`도 같은 루프를 돈다(`mpdecimal.c#L5121`, `#L5318`). 정수가 아닌 지수의 `pow`는 `exp(y·ln(x))`로 계산하면서 같은 전략을 쓴다(`_mpd_qpow_real`, `mpdecimal.c#L6799`).
- `allcr = 0`이면 루프 없이 한 번 계산하고 끝난다. 이때는 오차가 1 ulp 미만이라는 것만 보장된다. Python은 항상 `allcr = 1`이다.

## 테스트

스펙 작성자가 관리하는 **decTest** 파일이 표준 테스트 스위트다. 한 줄이 한 케이스다.

```
precision:   9
rounding:    half_up
maxExponent: 384
minexponent: -383

addx003 add '5.75'  '3.3'   ->  9.05
divx007 divide  1     3    ->  0.333333333 Inexact Rounded
```

context 지시문 아래로 `id 연산 피연산자... -> 기대 결과 기대 플래그`가 이어진다.

libmpdec의 `tests/runtest`가 `official.decTest`(공식 파일 목록)와 `additional.decTest`(자체 추가 케이스)를 돌린다. CPython의 `test_decimal`도 같은 decTest 파일을 쓰고, C 구현(`_decimal`)과 순수 Python 구현(`_pydecimal`)의 결과를 무작위 입력으로 대조하는 `Modules/_decimal/tests/deccheck.py`도 있다.

## CPython과의 관계

- Python 3.3에서 `decimal`의 기본 구현이 순수 Python(`_pydecimal.py`)에서 `_decimal` + libmpdec으로 바뀌었다. what's new에 따르면 데이터베이스류 작업에서 10배, 연산이 많은 작업에서 100배까지 빨라졌다.
- `decimal.__libmpdec_version__`으로 링크된 버전을 볼 수 있다. Homebrew Python 3.14는 `4.0.1`이다.
- CPython 소스에는 libmpdec 사본이 들어 있었다. 3.13에서 `--with-system-libmpdec`가 기본이 되고 번들 사본이 deprecated됐다([3.13 what's new](https://github.com/python/cpython/blob/f81c03a673ae1c71ad18845b0407f26e6cf64159/Doc/whatsnew/3.13.rst#L2602-L2604)). 3.15에서는 시스템 libmpdec이 없을 때 번들 사본으로 조용히 넘어가는 동작도 없어졌다([3.15 what's new](https://github.com/python/cpython/blob/f81c03a673ae1c71ad18845b0407f26e6cf64159/Doc/whatsnew/3.15.rst#L2724-L2726)).
- `_decimal.c`는 libmpdec의 Python 바인딩일 뿐이고 숫자 연산은 전부 libmpdec이 한다. 그래서 libmpdec의 ABI만 맞추면 구현을 통째로 바꿔 끼울 수 있다.

---
참고

- <https://www.bytereef.org/mpdecimal/>
- [General Decimal Arithmetic Specification](https://speleotrove.com/decimal/decarith.html)
- [decTest 테스트 케이스](https://speleotrove.com/decimal/dectest.html)
- [J. M. Pollard, The fast Fourier transform in a finite field (1971)](https://www.ams.org/journals/mcom/1971-25-114/S0025-5718-1971-0301966-0/home.html)
- [Python `decimal` 문서](https://docs.python.org/3/library/decimal.html)
