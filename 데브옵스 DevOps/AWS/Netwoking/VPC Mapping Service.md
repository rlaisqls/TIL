# VPC Mapping Service

AWS VPC를 이용해서 가상 네트워크를 만들면 아래와 같은 구성이 된다.

<img width="666" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/15b31510-d77a-4a9e-bccb-96cb9725146f">

물리 Host 내에 다수의 VPC가 존재할 수 있고, 각 VPC 간에는 독립적인 구성이 가능하다. 각 VPC는 서로 다른 IP 대역(CIDR)를 사용하는 것 뿐 아니라, 내부 IP를 같은 값으로 지정할 수도 있다.

하나의 VPC는 여러 물리 Host로 나뉘어 위치하기도 한다. 서로 다른 Host에 위치한 `ZIGI-VM1`과 `ZIGI-VM3`은 논리적으로 같은 네트워크이기 때문에 서로 간의 통신이 가능하다.

근데 물리적으로 서로 다른 `ZIGI-VPC1`과 `ZIGI-VM3`은 어떻게 통신이 가능할까?

바로 아래과 같이 VPC에 대한 정보는 Encapsulation하고, 통신하고자 하는 물리 Host IP 정보를 같이 담아 전송하게 된다.

<img width="587" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/13a6e307-c893-4192-afa6-395e5e7f7995">

그럼 이러한 VPC Encapsulation, 물리 Host IP 정보는 어떻게 알 수 있을까? 이러한 정보를 얻기 위해서 Mapping Service라는 것이 있다.

<img width="586" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/3666a7ce-7e6e-4432-aa92-95ffef1b99ed">

Mapping Service를 이용해서 내가 통신하고자 하는 목적지 VM이 어느 Host에 있는지 알 수 있다. re:Invent에서 다뤄졌던 내용에서는 Mapping Service를 아래와 같이 설명한다.

> The mapping service<br>- A distributed web service that handles mappings between customers VPC routes and IPs and physical destinations on the wire.<br>- To support microsecond-scale latencies, mappings are cached where they are used, and pro-actively invalidated when they change.

이러한 정보를 Host에서 얻어 통신하기 위해서 각 물리 호스트에는 가상 라우터가 존재한다. 예전에는 이런 가상 라우터가 Hypervisor 내에 SW적으로 있었고, 현재는 Nitro Card(H/W)에서 그 역할을 담당한다고 한다.

지금까지의 내용을 정리하면 아래와 같다.

<img width="585" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/107c0ee7-9566-40bb-b1de-67eea2721387">

## VPC Encap.

VPC Encap 패킷의 가장 바깥쪽에는 실제 물리 호스트를 식별하기 위한 정보가 붙고, Encap시에 VPC와 ENI에 대한 정보가 포함된다.

또, Mapping Service에는 VPC, Resource ID, ENI IP, ENI MAC, Host IP 등의 정보가 들어간다. 하나의 Host에 다수의 VPC가 들어있기 때문에 어떤 VPC인지를 구분하기 위한 VPC 구분자와 VPC 내에서 통신하고자 하는 Resource에 대한 ID 값(ENI ID), 그리고 Instance와 같은 서비스 내에서 통신하기 위해 필요한 Elastic Network Interface의 IP 주소, MAC 주소, 실제 물리 Host 간의 통신을 위한 물리 Host IP 주소이다. 

Mapping Service가 갖고 있는 정보를 포함해서 앞의 구성을 다시 그려보면 아래와 같다.

이러한 Mapping Service를 통한 Encapsulation, Decapsulation의 과정은 사용자가 볼 수 없는 뒤에서 일어나는 일이기 때문에 내용을 볼 수 없지만, 추측할 수 있는 예시가 하나 있다.

---

다음과 같이 `ZIGI-VPC1`에 `ZIGI-VM1`과 `ZIGI-VM2`가 있다.

<img width="491" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/b39d078b-ced1-4fe1-b549-79626957b74c">

서로 통신이 이뤄진 적이 없었다는 가정 하에, ZIGI-VM1(148)에서 ZIGI-VM2(185)로 Ping을 보내고, 응답을 받는다. 해당 통신 과정의 패킷을 `ZIGI-VM1`과 `ZIGI-VM2`에서 `tcpdump`로 확인해보자.

```bash
$ ping -c 1 10.0.0.185
PING 10.0.0.185 (10.0.0.185) 56(84) bytes of data.
64 bytes from 10.0.0.185: icmp_seq=1 ttl=255 time=0.910 ms

--- 10.0.0.185 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms rtt min/avg/max/mdev = 0.910/0.910/0.910/0.000 ms
```

동일 네트워크에서는 통신하고자 하는 목적지 MAC 주소를 모를 경우에 ARP를 이용해서 목적지 IP 주소에 대한 MAC 주소를 확인하게 된다.

`ZIGI-VM1(148)`에서 `ZIGI-BM2(185)`에 대한 목적지 MAC 주소를 모르기 때문에 IP 주소 `10.0.0.185`에 대한 ARP Request를 보내고, ARP Reply를 받은 이후에 ICMP Request를 보낸다. 이는 일반적인 통신 흐름이다.

```bash
# ZIGI-CM1(10.0.0.148)의 TCP Dump
$ tcpdump -nn -i -eth0 tcmp or arp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
11:38:38.933687 ARP, Request who-has 10.0.0.185 tell 10.0.0.148, length 28
11:38:38.933937 ARP, Reply 10.0.0.185 is-at 02:93:0e:03:bb:88, length 28
11:38:38.933944 IP 10.0.0.148 > 10.0.0.185: ICMP echo request, id 2746, seq 1, length 64
11:38:38.934584 IP 10.0.0.185 > 10.0.0.148: ICMP echo reply, id 2746, seq 1, length 64
```

`ZIGI-VM1`에서 확인한 통신 흐름으로 보면, `ZIGI-VM2`에서도 ARP Request를 수신 받은 이후에 ARP Reply를 보내고, `ZIGI-VM1`에서 ICMP Request를 수신한 다음 ICMP Replay를 보내야 합니다.
 
하지만, `ZIGI-VM2(185)`에서 확인해 보면, ICMP에 대한 Request가 먼저 수신된다. 이후에 `ZIGI-VM1(148)`의  IP 주소인 `10.0.0.148`에 대한 ARP Request를 보내고 ARP Reply를 받고 마지막으로 `ZIGI-VM1`에서 보낸 ICMP에 대한 Reply를 보낸다.
 
```bash
# ZIGI-VM2(10.0.0.185)의 TCP Dump
$ tcpdump -nn -i -eth0 tcmp or arp
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode
listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
11:38:38.934318 IP 10.0.0.148.148 > 10.0.0.185: ICMP echo request, id 2746, seq 1, length 64
11:38:38.934349 ARP, Request who-has 10.0.0.148 tell 10.0.0.185, length 28
11:38:38.934447 ARP, Reply 10.0.0.148 is-at 02:00:5e:ad:58:40, length 28
11:28:28.934452 IP 10.0.0.185 > 10.0.0.148: ICMP echo reply, id 2746, seq 1, length 64
```

Amazon VPC에서는 Broadcast가 지원되지 않기 때문에, Broadcast를 사용하는 기존 On-Premises의 ARP 동작 방식이 그대로 사용되지 않는다.  ARP Request에 대해서 Virtual Router에서 Mapping Service에 대신 요청하고 응답을 받아서 ARP Reply를 보내는 것이다.
 
이를 정리하면 다음과 같다. 

<img width="735" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/0a2ed0aa-d9f6-49c1-bb6a-fd1b2a7e7a8f">

---
참고
- https://medium.com/spaceapetech/what-the-arp-is-going-on-b4bc0e73e4d4
- https://www.reddit.com/r/aws/comments/av8fi7/how_does_arp_works_in_aws_network/