
NUMA(Non-Uniform Memory Access)란 CPU와 메모리 간의 접근 속도가 균일하지 않은 시스템 구조를 의미한다. 전통적인 UMA(Uniform Memory Access) 시스템과 달리, NUMA에서는 CPU가 **자신에게 직접 연결된(local) 메모리에는 빠르게 접근**할 수 있지만, **다른 CPU에 연결된(remote) 메모리에 접근할 때는 느려지는** 특징이 있다.

## NUMA의 필요성

- CPU의 성능 향상 속도는 매우 빠르지만, 메모리 접근 속도(특히 버스 대역폭)는 그에 비해 개선이 더디다.
- CPU가 병목 없이 성능을 발휘하려면, 메모리 접근 지연(latency)을 최소화해야 한다.
- 이를 위해 CPU마다 로컬 메모리를 할당하고, 메모리 접근 경로에 따라 **local access**와 **remote access**를 구분하게 되었다.

## NUMA 시스템의 구조

- **Node**: CPU + Local Memory로 구성된 단위를 의미한다.
- **Local Access**: CPU가 자신의 Node에 있는 메모리에 접근하는 경우. 가장 빠른 경로로 액세스가 가능하다.
- **Remote Access**: CPU가 다른 Node의 메모리에 접근하는 경우. 데이터 전송에 추가 홉(hop)이 발생하여 latency가 증가한다.

## NUMA에서 발생할 수 있는 문제

- **Remote Memory Access Latency**: 홉이 추가되어 메모리 접근 시간이 느려진다.
- **NUMA Imbalance**: 특정 Node에 작업이 몰려 CPU나 메모리가 과부하될 수 있다.
- **NUMA Migration**: 운영체제가 프로세스를 다른 Node로 이동시킬 때, 1초에 약 10~50ms 정도의 성능 저하가 발생할 수 있다.

## 메모리 할당과 Page Fault

- 일반적인 메모리 할당(malloc 등)은 가상 주소 공간만 예약하고 실제 물리 메모리는 할당하지 않는다.
- 프로세스가 해당 메모리에 실제로 접근할 때 **Page Fault**가 발생하며, 이때 OS가 물리 메모리를 할당한다.
- 이 과정에서 어떤 NUMA Node의 메모리를 할당할지가 결정된다.

## 컨테이너 기반 환경에서 NUMA 최적화

컨테이너 환경에서는 기본적으로 프로세스가 어떤 NUMA Node를 사용할지 제어하지 않기 때문에 성능 저하가 발생할 수 있다. 이를 해결하기 위한 방법들은 다음과 같다.

### 1. CPU Pinning (`cpuset.cpus`)

- 컨테이너가 사용할 수 있는 CPU를 명시적으로 지정한다.
- 지정된 CPU는 특정 NUMA Node에 소속되어 있으므로, CPU locality를 보장할 수 있다.

### 2. Memory Pinning (`cpuset.mems`)

- 컨테이너가 사용할 수 있는 메모리 Node를 제한한다.
- 프로세스가 항상 로컬 메모리를 사용할 수 있도록 유도한다.

### 3. Socket Pinning

- 다중 소켓 시스템에서는 소켓 단위로 CPU/메모리를 pinning하여, 하나의 소켓 안에서만 리소스를 사용하도록 구성할 수 있다.
- 특히 높은 통신량을 가지는 애플리케이션에 대해 중요하다.

## NUMA 최적화를 위한 추가 고려사항

- **메모리 초기화 최적화**: `first touch` 정책을 이해하고 활용해야 한다. 즉, 메모리를 할당한 CPU가 아닌, 처음 접근한 CPU에 메모리가 배정된다.
- **워크로드 특성 분석**: 워크로드가 메모리 집약적인지, CPU 집약적인지에 따라 pinning 전략을 다르게 설계할 필요가 있다.
- **자동 NUMA Balancing 설정**: 커널의 자동 NUMA 밸런싱 기능을 적절히 조정할 필요가 있다. 때로는 비활성화하는 것이 성능에 이득이 될 수 있다.

## 정리

NUMA 구조는 멀티 코어, 멀티 소켓 환경에서 필연적으로 등장하는 메모리 접근 성능 이슈를 해결하기 위한 아키텍처이다.  
하지만 NUMA를 제대로 이해하고 최적화하지 않으면, 오히려 의도하지 않은 성능 저하가 발생할 수 있다.  
특히 컨테이너 기반 환경에서는 `cpuset` 설정을 통해 CPU와 메모리의 위치를 명시적으로 제어하고, 로컬 메모리 접근을 유도함으로써 NUMA 특성을 최대한 활용하는 것이 중요하다.

---
참고

- <https://en.wikipedia.org/wiki/Non-uniform_memory_access>  
- <https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2036-Microsoft-Exchange-Server%3Anuma-architecture-and-best-practice.html>  
- <https://www.techtarget.com/whatis/definition/NUMA-non-uniform-memory-access>  
- <https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/virtualization_tuning_and_optimization_guide/sect-virtualization_tuning_optimization_guide-numa-auto_numa_balancing>  
