
XDP(eXpress Data Path)는 운영체제 네트워킹 스택의 대부분을 우회하여 높은 속도로 네트워크 패킷을 송수신할 수 있는 eBPF 기반 고성능 데이터 경로이다.

## Data path

<img width="883" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/c322a547-9858-44ff-880a-acd5859cddaf">

위 그림은 Linux 커널의 패킷 흐름 경로를 나타낸다. XDP는 네트워킹 스택과 패킷 메타데이터를 위한 메모리 할당을 우회한다.

XDP의 핵심 아이디어는 **커널 RX 경로 초입에 hook을 걸어**, **사용자가 제공한 eBPF 프로그램이 패킷 처리 방향을 결정**하게 하는 것이다.

이 hook은 NIC 드라이버의 인터럽트 처리 직후, 네트워크 스택의 메모리 할당 전에 위치한다. 메모리 할당 비용이 크기 때문이다. 이 덕분에 **일반 하드웨어에서도 코어당 초당 2,600만 패킷을 드롭**할 수 있다.

eBPF 프로그램은 로드 전에 검증기(preverifier) 테스트를 통과해야 한다. 커널 공간에서 악성 코드가 실행되지 않도록 범위 초과 접근, 루프, 전역 변수 등을 검사한다.

프로그램은 패킷 데이터를 수정할 수 있으며, eBPF 프로그램이 반환된 후 액션 코드에 따라 패킷 처리 방향이 결정된다.

- `XDP_PASS`: 패킷을 네트워크 스택으로 계속 전달한다
- `XDP_DROP`: 패킷을 조용히 드롭한다
- `XDP_ABORTED`: 트레이스포인트 예외와 함께 패킷을 드롭한다
- `XDP_TX`: 패킷을 도착한 동일한 NIC로 반송한다
- `XDP_REDIRECT`: AF_XDP 주소 패밀리를 통해 다른 NIC 또는 사용자 공간 소켓으로 패킷을 리다이렉트한다

XDP는 NIC 드라이버의 지원이 필요하지만, 모든 드라이버가 지원하는 것은 아니므로 네트워크 스택에서 eBPF 처리를 수행하는 제네릭 구현으로 폴백할 수 있다. 다만 성능은 더 느리다.

XDP는 eBPF 프로그램을 NIC에 오프로드하여 CPU 부하를 줄이는 기능도 갖추고 있다. 2023년 기준 Netronome 카드만 지원한다.

Microsoft는 다른 회사들과 협력하여 QUIC 프로토콜의 MsQuic 구현에 XDP 지원을 추가하고 있다.

## AF_XDP

XDP와 함께 Linux 커널 4.18부터 새로운 주소 패밀리가 도입되었다.

AF_XDP(이전 이름 AF_PACKETv4, 메인라인 커널에 포함된 적 없음)는 고성능 패킷 처리에 최적화된 raw 소켓으로, 커널↔애플리케이션 간 제로 카피를 지원한다.

수신·송신 모두 쓸 수 있어 순수 사용자 공간에서 고성능 네트워크 애플리케이션을 만들 수 있다.

---
참고

- <https://prototype-kernel.readthedocs.io/en/latest/networking/XDP/>
- <https://www.netronome.com/blog/bpf-ebpf-xdp-and-bpfilter-what-are-these-things-and-what-do-they-mean-enterprise/>
- <https://ebpf.io/>
