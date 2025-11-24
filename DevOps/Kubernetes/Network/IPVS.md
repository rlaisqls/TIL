IP Virtual Server (IPVS)는 Linux의 connection(L4) 레벨 로드 밸런서이다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/baab90be-20db-4b95-91cb-e2859c2b1b45" height=400px>

iptables는 개별 DNAT 규칙의 가중치로 형성된 무작위성을 통해 연결을 무작위로 라우팅함으로써 간단한 L4 로드 밸런싱을 수행할 수 있다. **하지만 IPVS는 iptables와 달리 여러 로드 밸런싱 모드를 지원한다.** 이를 통해 IPVS는 구성과 트래픽 패턴에 따라 iptables보다 더 효과적으로 부하를 분산할 수 있다.

## 로드 밸런싱 모드

IPVS는 다음과 같은 로드 밸런싱 모드를 제공한다.

|이름|코드|설명|
|-|-|-|
|Round-robin|rr|순환 방식으로 다음 호스트로 연속적인 연결을 전송한다. iptables의 무작위 라우팅과 비교하여 특정 호스트로 전송되는 연속 연결 사이의 시간을 증가시킨다.|
|Least connection|lc|현재 열린 연결이 가장 적은 호스트로 연결을 전송한다.|
|Destination hashing|dh|연결의 목적지 주소를 기반으로 특정 호스트로 결정론적으로 연결을 전송한다.|
|Source hashing|sh|연결의 소스 주소를 기반으로 특정 호스트로 결정론적으로 연결을 전송한다.|
|Shortest expected delay|sed|연결 대 가중치 비율이 가장 낮은 호스트로 연결을 전송한다.|
|Never queue|nq|기존 연결이 없는 호스트로 연결을 전송하고, 그렇지 않으면 "shortest expected delay" 전략을 사용한다.|

## 패킷 포워딩 모드

IPVS는 다음과 같은 패킷 포워딩 모드를 지원한다.

- NAT: 소스와 목적지 주소를 재작성한다.
- DR: IP 데이터그램을 IP 데이터그램 내에 캡슐화한다.
- IP 터널링: 데이터 프레임의 MAC 주소를 선택된 백엔드 서버의 MAC 주소로 재작성하여 백엔드 서버로 패킷을 직접 라우팅한다.

## 한계

로드 밸런서로서 iptables의 문제점을 살펴보면 세 가지 측면이 있다:

**클러스터의 노드 수**

- Kubernetes가 v1.6 릴리스에서 이미 5,000개의 노드를 지원하지만, iptables를 사용하는 kube-proxy는 클러스터를 5,000개 노드로 확장하는 데 병목 현상이 된다. 예를 들어, 5,000개 노드 클러스터에서 NodePort 서비스를 사용할 때, 2,000개의 서비스가 있고 각 서비스가 10개의 pod을 가지면, 각 워커 노드에 최소 20,000개의 iptables 레코드가 생성되어 커널이 매우 바쁘게 만든다.

**시간**

- 5,000개의 서비스(40,000개의 규칙)가 있을 때 하나의 규칙을 추가하는 데 걸리는 시간은 11분이다. 20,000개의 서비스(160,000개의 규칙)의 경우 5시간이 걸린다.

**지연 시간**

- 서비스에 접근하는 데 지연 시간(라우팅 지연 시간)이 있다. 각 패킷은 일치하는 항목을 찾을 때까지 iptables 목록을 순회해야 한다. 규칙을 추가/제거하는 데도 지연 시간이 있으며, 대규모 목록에서 삽입하고 제거하는 것은 집약적인 작업이다.

## Session affinity

IPVS는 세션 어피니티(session affinity)도 지원한다.

서비스에서 옵션으로 설정할 수 있다.(`Service.spec.sessionAffinity`와 `Service.spec.sessionAffinityConfig`). 이 옵션을 설정하면 세션 어피니티 time window 내의 반복된 연결은 동일한 호스트로 라우팅된다.

캐시 미스를 최소화하는 등의 시나리오에 유용할 수 있다. 또, 동일한 주소에서 오는 연결을 무기한으로 동일한 호스트로 라우팅함으로써 모든 모드에서 라우팅을 효과적으로 상태 저장(stateful)하게 만들 수 있다. 하지만 개별 pod이 생성되고 사라지는 Kubernetes에서는 라우팅 고정성이 절대적이진 않다.

## IPVS 사용하기

동일한 가중치를 가진 두 개의 대상이 있는 기본 로드 밸런서를 생성하려면 `ipvsadm -A -t <address> -s <mode>`를 실행한다. `-A`, `-E`, `-D`는 각각 가상 서비스를 추가, 편집, 삭제하는 데 사용된다. 소문자 `-a`, `-e`, `-d`는 각각 호스트 백엔드를 추가, 편집, 삭제하는 데 사용된다:

```bash
ipvsadm -A -t 1.1.1.1:80 -s lc
ipvsadm -a -t 1.1.1.1:80 -r 2.2.2.2 -m -w 100
ipvsadm -a -t 1.1.1.1:80 -r 3.3.3.3 -m -w 100
```

`-L`로 IPVS 호스트 목록을 조회할 수 있다. 각 가상 서버(고유한 IP 주소와 포트 조합)가 백엔드와 함께 표시된다:

```bash
$ ipvsadm -L
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  1.1.1.1.80:http lc
  -> 2.2.2.2:http             Masq    100    0          0
  -> 3.3.3.3:http             Masq    100    0          0
```

`-L`은 추가 연결 통계를 표시하는 `--stats`와 같은 여러 옵션을 지원한다.

---
reference

- <https://medium.com/google-cloud/load-balancing-with-ipvs-1c0a48476c4d>
- <https://en.wikipedia.org/wiki/IP_Virtual_Server>
- <http://www.linuxvirtualserver.org/software/ipvs.html>
- <https://kubernetes.io/blog/2018/07/09/ipvs-based-in-cluster-load-balancing-deep-dive/>
