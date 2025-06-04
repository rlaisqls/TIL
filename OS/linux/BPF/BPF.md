
> For connected systems evolving these days, the amount of data transfer is huge, and the support infrastructure for the network analysis needed a way to filter out things pretty fast.

- BPF는 1992년 패킷 분석 및 필터링을 위해 개발된 in-kernel virtual machine이다.
- BSD라는 OS에서 처음 도입했으며 리눅스에서도 이 개념을 빌려와서 서브시스템을 만들었다.
- in-kernel virtual machine이라고 함은 정말로 가상의 레지스터와 스택 등을 갖고 있으며 이를 바탕으로 코드를 실행한다는 뜻이다.
- 커널 레벨의 프로그램을 개발하기 위한 일종의 프레임워크 같은 형태라고 볼 수 있다. 다양한 커널 및 애플리케이션 이벤트에서 작은 프로그램을 실행할 수 있는 방법을 제공한다.
- 일반적으로 eBPF 프로그램은 사용자 프로그램에 의해 적재되며 그 프로세스가 끝날 때 자동으로 내려간다.
  
  > `tc-bpf` 같은 일부 경우에서는 프로그램을 적재한 프로세스가 끝난 후에도 프로그램이 커널 내에 계속 살아 있다. 이 경우에는 사용자 공간 프로그램이 파일 디스크립터를 닫은 후에 `tc`라는 이름의 서브시스템이 프로그램에 대한 참조를 잡고 있는다.
  
> 자바스크립트는 브라우저 내에 존재하는 가상 머신에서 안정하게 실행되면서 이벤트에 따라 정적인 HTML 웹페이지를 동적으로 바꾸고, eBPF는 커널에서 여러 이벤트에 따라 동작하는 작은 프로그램을 가상머신위에서 안전하게 동작시킨다.<br>
> -Brendan Gregg-

### 구조

<img width="327" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/6a6f8fc9-6694-442c-90c1-06685aceb525">

- BPF 프로그램은 위의 코드처럼 커널 코드 내에 미리 정의된 훅이나 kprobe, uprobe, tracepoint를 사용해서 프로그램을 실행할 수 있다.
- 위의 그림은 간단한 예시로, execve 시스템 호출이 실행될 때마다 BPF 프로그램을 실행해서 새로운 프로세스가 어떻게 만들어지는지를 나타낸다.

### BPF 코드 컴파일 과정

<img height="252" src="https://github.com/rlaisqls/TIL/assets/81006587/a48bf8d5-181f-45b2-89b5-088650a01b1b"> <img height="252" src="https://github.com/rlaisqls/TIL/assets/81006587/7ef6deb1-bc42-4c54-b2ab-4585520034c5">

- 자바나 파이썬 등의 VM 언어처럼 eBPF 또한 JIT(Just In Time) 컴파일을 지원한다. 컴파일 시점에서 물리 장비의 기계어로 즉시 변환 후 실행되어 성능을 더욱 개선할 수 있다.
- BPF는 사용자측에서 가져온 코드를 커널에서 실행하기 때문에 안전성이 매우 중요하다. <br/> 시스템의 안정성을 해칠만한 코드인지 아닌지 검증하는 과정이 필요하다.
  - 무한 루프가 발생할 수 있기 때문에 반복문도 매우 제한적으로 지원한다.
- 모든 BPF 프로그램은 Verifier를 통과해야만 실행된다.

- 위 사진은 BPF 코드가 검증되고 컴파일되는 과정을 나타낸다.

1. C 코드에서 LLVM 중간 표현으로 번역
2. BPF 바이트코드로 다시 번역
3. 바이트코드를 Verifier로 검증
4. JIT 컴파일러로 컴파일

이 4가지 과정을 거치면 실행할 수 있는 상태가 된다.

### BPF의 장점

- 커널을 새로 빌드할 필요 없이 바로 코드를 실행해볼 수 있다.
  - 물론 애초에 커널의 기능을 바꿀 일이 있다면 소스를 고치는게 맞지만, **트레이싱을 하는 경우에는 필요할 때만 트레이싱 코드를 실행하고 작업이 끝나고 나면 다시 그 코드를 비활성화**해야 하는데 그럴때마다 매번 커널을 새로 빌드할 필요가 없어진다.

### BPF의 단점

- 자주 실행되는 함수를 트레이싱할 경우 오버헤드가 크다.
- 인라인 함수를 트레이싱 하려면 매우 번거롭다.
- 사용자 공간 함수를 트레이싱 하는 경우에는 커널 공간을 들렀다가 가야 하므로 비효율적이다.
- 지원되는 구문이 제한적이다. (위에서 말한 반복문처럼)
- 고정된 스택을 갖는다 (512바이트)

### eBPF: extended BPF

- eBPF는 확장 BPF라는 뜻이다. 기존의 BPF에서 사용하던 머신에서 더 나아가서 레지스터의 크기를 늘려주고 스택과 맵을 도입하는 등의 변화가 있었다.
- 그래서 기존의 BPF를 cBPF (classic BPF)라고 부르고 새로운 BPF를 eBPF로 부르게 되었다.
- 현재의 리눅스 커널은 둘을 모두 지원하고, eBPF를 처리하는 가상머신에서 기존의 cBPF도 같이 처리하는 형태로 작동한다.
- cBPF와 eBPF 스펙의 상세 차이는 다음과 같다.

|항목|cBPF|eBPF|
|-|-|-|
|레지스터|32bit, 2개의 레지스터와 스택|64bit, 11개의 레지스터|
|저장소|16 메모리 블록|크기 제한이 없는 맵, 512바이트의 스택|
|시스템 콜|N/A|bpf()|
|이벤트|네트워크 패킷<br>시스템 콜|네트워크 패킷<br>시스템 콜<br>kprobe<br>uprobe<br>트레이스포인트<br>USDT<br>소프트웨어 이벤트<br>하드웨어 이벤트|

<img width="502" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/470c9829-a147-4d5e-9a52-b28a9ad4bec9">

### eBPF를 활용한 프로그램

- **Cilium**
  - Cilium은 eBPF 기반 네트워킹, 보안 및 observability를 제공하는 오픈 소스 프로젝트이다. 컨테이너 워크로드의 새로운 확장성, 보안 및 가시성 요구사항을 해결하기 위해 설계되었다. Service Mesh, Hubble, CNI 3가지 타입이 있다.

    <img height="222" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/1bffe60c-f398-4237-a61f-229c17853562">

    <img height="222" src="https://github.com/rlaisqls/TIL/assets/81006587/94da48b6-46c3-4955-885e-2d85d9392d3a">

- **Calico**
  - K8s cni로 사용할 수 있는 Pluggable eBPF 기반 네트워킹 및 보안 오픈소스이다. Calico Open Source는 컨테이너 및 Kubernetes 네트워크를 단순화, 확장 및 보안하기 위해 설계되었디.
  - Calico의 eBPF 데이터 플레인은 eBPF 프로그램의 성능, 속도 및 효율성을 활용하여 환경에 대한 네트워킹, 로드 밸런싱 및 커널 내 보안을 강화한다.

    <img height="222" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/46dcc883-63dc-4680-8477-281547a2ad60">

---
참고

- <https://www.tcpdump.org/papers/bpf-usenix93.pdf>
- <https://netflixtechblog.com/how-netflix-uses-ebpf-flow-logs-at-scale-for-network-insight-e3ea997dca96>
- <https://www.brendangregg.com/bpf-performance-tools-book.html>
- <https://www.amazon.com/gp/reader/0136554822?asin=B081ZDXNL3&revisionId=c47b7fdb&format=1&depth=1>
- <https://en.wikipedia.org/wiki/Berkeley_Packet_Filter>
- <https://www.youtube.com/watch?v=lrSExTfS-iQ>

