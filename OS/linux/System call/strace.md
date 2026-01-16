strace는 프로세스가 호출하는 시스템 콜과 시그널을 추적하는 리눅스 디버깅 도구다.

```bash
strace [options] command [args]
strace [options] -p pid
```

**기본 옵션**

| 옵션 | 설명 |
|------|------|
| `-p pid` | 실행 중인 프로세스에 attach |
| `-o file` | 출력을 파일로 저장 |
| `-e trace=syscalls` | 특정 syscall만 추적 |
| `-c` | 통계 요약 출력 |

**멀티쓰레드/프로세스 옵션**

| 옵션 | 설명 |
|------|------|
| `-f` | fork된 자식 프로세스도 추적 |
| `-ff` | 각 프로세스/쓰레드별 별도 파일 생성 (`-o` 필요) |

**출력 형식 옵션**

| 옵션 | 설명 |
|------|------|
| `-tt` | 마이크로초 단위 타임스탬프 |
| `-T` | 각 syscall 소요 시간 |
| `-y` | 파일 디스크립터에 경로 표시 |
| `-yy` | 소켓 정보도 표시 |

## 예시

**특정 syscall만 추적**

```bash
# 파일 관련
strace -e trace=open,openat,close,read,write ./program

# 네트워크 관련
strace -e trace=network ./program

# 프로세스 관련
strace -e trace=process ./program

# 메모리 관련
strace -e trace=memory ./program
```

**멀티쓰레드 프로그램 분석**

```bash
# 쓰레드별 별도 파일로 저장
strace -ff -tt -o /tmp/trace ./program

# 결과: /tmp/trace.1234, /tmp/trace.1235, ... (각 쓰레드 PID)
```

**파일 경로 확인**

```bash
strace -y -e trace=openat ./program
# 출력: openat(AT_FDCWD, "/etc/passwd", O_RDONLY) = 3</etc/passwd>
```

**실행 시간 측정**

```bash
strace -T -e trace=write ./program
# 출력: write(1, "hello", 5) = 5 <0.000042>
```

**파일 열기 실패 원인 찾기**

```bash
strace -e trace=openat ./program 2>&1 | grep -i error
```

**락 경합 분석**

```bash
strace -ff -tt -e trace=futex -o /tmp/futex ./program

# 분석
grep EAGAIN /tmp/futex.*
grep FUTEX_WAIT /tmp/futex.*
```

**I/O 병목 찾기**

```bash
strace -c ./program
# 출력:
# % time     seconds  usecs/call     calls    errors syscall
# ------ ----------- ----------- --------- --------- ----------------
#  85.00    1.234567         123     10000           write
#  10.00    0.145678          14     10000           read
```

## 출력

**기본 형식**

```
syscall(args) = return_value
```

**에러 반환**

```
openat(AT_FDCWD, "/nonexistent", O_RDONLY) = -1 ENOENT (No such file or directory)
futex(0x7f..., FUTEX_WAIT, 0, NULL) = -1 EAGAIN (Resource temporarily unavailable)
```

**시그널**

```
--- SIGCHLD {si_signo=SIGCHLD, si_code=CLD_EXITED, ...} ---
```

**프로세스 종료**

```
+++ exited with 0 +++
+++ killed by SIGKILL +++
```

## 컨테이너에서 사용

Kubernetes나 Docker에서 strace를 사용하려면 `SYS_PTRACE` 권한이 필요하다.

```yaml
# Kubernetes Pod 설정
securityContext:
  capabilities:
    add:
      - SYS_PTRACE
```

```bash
# Docker
docker run --cap-add=SYS_PTRACE ...
```

## 주의사항

- strace는 성능에 상당한 오버헤드를 준다 (10~100배 느려질 수 있음)
- 프로덕션 환경에서는 주의해서 사용
- `-e trace=`로 필요한 syscall만 추적하면 오버헤드 감소

## 관련 도구

| 도구 | 설명 |
|------|------|
| `ltrace` | 라이브러리 함수 호출 추적 |
| `perf trace` | 더 낮은 오버헤드의 syscall 추적 |
| `bpftrace` | eBPF 기반 고급 추적 |

## 참고

- [strace(1) - Linux man page](https://man7.org/linux/man-pages/man1/strace.1.html)

