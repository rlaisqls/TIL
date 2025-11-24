
eBPF는 커널에서 샌드박스된 특별한 프로그램을 실행할 수 있게 해주는 프로그래밍 시스템이다. Netfilter나 iptables처럼 **커널과 유저 공간을 오가지 않고** 커널 내에서 직접 동작한다.

eBPF 이전에는 BPF(Berkeley Packet Filter)가 있었다. BPF는 커널에서 네트워크 트래픽을 분석하는 데 사용되는 기술이다. BPF는 패킷 필터링을 지원하는데, 유저 공간 프로세스가 어떤 패킷을 검사할지 지정하는 필터를 제공할 수 있다. BPF의 대표적인 사용 사례가 `tcpdump`다. tcpdump는 필터를 BPF 프로그램으로 컴파일해서 BPF에 전달한다. BPF의 기법은 이후 다른 프로세스와 커널 작업으로 확장되었다.

**tcpdump 예제**

```bash
$ sudo tcpdump -n -i any
tcpdump: data link type LINUX_SLL2
tcpdump: verbose output suppressed, use -v[v]... for full protocol decode
listening on any, link-type LINUX_SLL2 (Linux cooked v2), snapshot length 262144 bytes
21:45:33.093065 ens5  Out IP 172.31.43.75.2222 > 14.50.190.128.63209: Flags [P.], seq 2457618334:2457618410, ack 3398066884, win 463, options [nop,nop,TS val 1101586736 ecr 1365458938], length 76
21:45:33.094530 ens5  Out IP 172.31.43.75.2222 > 14.50.190.128.63209: Flags [P.], seq 76:280, ack 1, win 463, options [nop,nop,TS val 1101586738 ecr 1365458938], length 204
21:45:33.103287 ens5  In  IP 14.50.190.128.63209 > 172.31.43.75.2222: Flags [.], ack 76, win 2046, options [nop,nop,TS val 1365458993 ecr 1101586736], length 0
21:45:33.104358 ens5  In  IP 14.50.190.128.63209 > 172.31.43.75.2222: Flags [.], ack 280, win 2044, options [nop,nop,TS val 1365458994 ecr 1101586738], length 0
...
```

eBPF 프로그램은 **syscall에 직접 접근**할 수 있다. eBPF 프로그램은 syscall을 직접 감시하고 차단할 수 있는데, 유저 공간 프로그램에 커널 훅을 추가하는 기존 방식과는 다르다. 이런 <u>성능 특성 덕분에 네트워킹 소프트웨어를 작성하는 데 아주 적합하다.</u>

---

소켓 필터링 외에도, 커널에서 지원하는 다른 attach point들은 다음과 같다:

- **Kprobes**
  - 커널 내부 컴포넌트의 동적 커널 트레이싱

- **Uprobes**
  - 유저 공간 트레이싱

- **Tracepoints**
  - 커널 정적 트레이싱. 개발자가 커널에 직접 프로그래밍해놓은 것으로, 커널 버전이 바뀌어도 변할 수 있는 kprobes보다 안정적이다.

- **perf_events**
  - 데이터와 이벤트의 타임 샘플링

- **XDP**
  - 커널 공간보다 더 낮은 드라이버 공간까지 접근해서 패킷에 직접 작동할 수 있는 특수한 eBPF 프로그램

tcpdump를 다시 예로 들어보자. 아래 그림은 tcpdump와 eBPF의 상호작용을 단순화해서 보여준다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/92391699-09cc-49da-83e5-55a85465b6ff" height="300px" />

`tcpdump -i any`를 실행한다고 가정해보자.

이 문자열은 `pcap_compile`에 의해 BPF 프로그램으로 컴파일된다. 그러면 커널은 이 BPF 프로그램을 사용해서 지정한 모든 네트워크 디바이스(우리 경우엔 `-i`로 지정한 any)를 통과하는 모든 패킷을 필터링한다.

필터링된 데이터는 map을 통해 `tcpdump`에서 사용할 수 있게 된다. Map은 키-값 쌍으로 구성된 데이터 구조로, BPF 프로그램이 데이터를 교환하는 데 사용한다.

## K8s에서 eBPF를 사용하는 이유

Kubernetes에서 eBPF를 사용하는 이유는 여러 가지가 있다:

### 성능 (해시 테이블 vs `iptables` 리스트)

Kubernetes에 서비스가 추가될 때마다 순회해야 하는 `iptables` 규칙 리스트가 기하급수적으로 늘어난다. 증분 업데이트가 없기 때문에, 새 규칙을 추가할 때마다 전체 규칙 리스트를 교체해야 한다. 20,000개의 Kubernetes 서비스를 나타내는 160,000개의 iptables 규칙을 설치하는 데 총 5시간이 걸렸다는 사례도 있다.

### 트레이싱

BPF를 사용하면 Pod과 컨테이너 레벨의 네트워크 통계를 수집할 수 있다. BPF 소켓 필터 자체는 새로운 게 아니지만, cgroup별 BPF 소켓 필터는 새롭다. Linux 4.10에 도입된 `cgroup-bpf`는 eBPF 프로그램을 cgroup에 attach할 수 있게 해준다. attach되면, 해당 cgroup의 모든 프로세스에 들어오거나 나가는 모든 패킷에 대해 프로그램이 실행된다.

### `kubectl exec` 감사

eBPF를 사용하면 `kubectl exec` 세션에서 실행되는 모든 명령을 기록하는 프로그램을 attach할 수 있다. 그 명령들을 유저 공간 프로그램으로 전달해서 이벤트를 로깅할 수 있다.

### 보안

**Seccomp**

- 어떤 syscall을 허용할지 제한하는 보안 컴퓨팅이다. Seccomp 필터는 eBPF로 작성할 수 있다.

**Falco**

- eBPF를 사용하는 오픈소스 컨테이너 네이티브 런타임 보안 도구다.

## Cilium

Kubernetes에서 eBPF의 가장 흔한 사용 사례는 **Cilium CNI와 서비스 구현**이다. Cilium은 `kube-proxy`를 대체하는데, kube-proxy는 서비스의 IP 주소를 해당 Pod들에 매핑하기 위해 `iptables` 규칙을 작성한다.

eBPF를 통해 Cilium은 모든 패킷을 커널에서 직접 가로채고 라우팅할 수 있다. 이는 더 빠를 뿐만 아니라 애플리케이션 레벨(레이어 7) 로드 밸런싱도 가능하게 한다.

---
참고

- <http://ebpf.io/>
- <https://cilium.io/blog/2020/11/10/ebpf-future-of-networking/>

