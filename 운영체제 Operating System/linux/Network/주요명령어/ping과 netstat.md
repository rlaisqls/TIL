# ping과 netstat

## ping

ping은 네트워크 연결 상태를 점검하는 명령이다. 목적지에 ICMP(Internet Control Message Protocol) 패킷을 보내고 되돌아오는지 확인하여 연결 상태를 진단한다.

`ping [옵션] 목적지주소` 형식으로 입력하며 목적지 주소에는 연결 상태를 확인하려는 대상의 주소를 입력한다. IP 주소와 도메인 모두 사용할 수 있다. 

도메인 주소로 ping 명령을 실행하면 DNS 서버에 질의해 대상 컴퓨터의 IP주소를 알아내고 ping을 실시한다. 

```bash
$ ping google.com
PING google.com (172.217.25.174): 56 data bytes
64 bytes from 172.217.25.174: icmp_seq=0 ttl=109 time=102.128 ms
64 bytes from 172.217.25.174: icmp_seq=1 ttl=109 time=34.757 ms
64 bytes from 172.217.25.174: icmp_seq=2 ttl=109 time=34.030 ms
64 bytes from 172.217.25.174: icmp_seq=3 ttl=109 time=34.423 ms
^C
--- google.com ping statistics ---
4 packets transmitted, 4 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 34.030/51.334/102.128/29.327 ms
```

명령어를 치면 일정한 시간 간격으로 응답을 받고 있다는 메시지가 출력된다. 목적지로부터 받는 응답 패킷의 크기는 64byte이며 TTL 값은 109로 나온다. 

결과를 보니 요청 패킷을 4개 보내 응답 패킷을 받았으며 패킷 손실이 없었다는 것을 알 수 있다. 

`-i` 옵션은 요청 패킷을 전송하는 대기 시간을 설정한다. 다음 명령은 5초 간격으로 패킷을 전송할 것이다.

```bash
$ ping -i 5 google.com
```

`-t`로 ttl 값을 0에서 255까지 변경할 수 있다. ICMP 패킷의 ttl을 너무 작게 설정하면 패킷이 목적지에 닿기 전에 자동으로 소멸한다.

```bash
$ ping -m 1 google.com
PING google.com (172.217.25.174): 56 data bytes
92 bytes from 192.168.1.1: Time to live exceeded
Vr HL TOS  Len   ID Flg  off TTL Pro  cks      Src      Dst
 4  5  00 5400 d7ae   0 0000  01  01 5907 192.168.1.196  172.217.25.174 
```

`-R` 옵션은 요청 패킷이 목적지까지 도달하는 데 거치는 호스트의 IP 주소를 차례로 보여준다. 목적지까지 경로에 문제가 있는지 확인할 때 유용한 옵션이다.

```bash
$ ping -R google.com
PING google.com (172.217.161.78) 56(124) bytes of data.
 192.168.1.1
 10.156.144.2
 172.20.0.229
 172.16.1.137
 ...
```

사용하는 서버의 연결상태를 진단할 때, ifconfig 결과 인터페이스가 정산적으로 올라와있고 route 결과 기본 게이트웨이로 가기 위한 라우팅 테이블도 설정되어 있다면 ping으로 연결 상태를 진단해야 한다. pin을 전략적으로 사용하면 문제의 원인을 알아낼 수 있다.

아래는 문제를 파악하기 위해 시도해볼 수 있는 명령어들이다.
```bash
$ ping [기본 게이트웨이] # 우선 기본적인 게이트웨이와의 연결을 확인한다.
$ ping [내부 호스트] # 내부 호스트와의 네트워크 연결 상태를 확인할 수 있다.
$ ping 8.8.8.8 # DNS 서버의 IP 주소로 ping하여서 외부와의 연결 상태를 확인한다.
```

## netstat

netstat은 리눅스 네트워크 상태를 종합적으로 보여주는 명령이다. 아무 옵션 없는 `netstat`은 현재 리눅스 서버의 열려있는 모든 소켓에 대한 데이터를 확인할 수 있다.

```bash
$ netstat
Active Internet connections (w/o servers)
Proto Recv-Q Send-Q Local Address           Foreign Address         State      
...
Active UNIX domain sockets (w/o servers)
Proto RefCnt Flags       Type       State         I-Node   Path
unix  2      [ ]         DGRAM                    18318    /run/systemd/journal/syslog
unix  11     [ ]         DGRAM      CONNECTED     18327    /run/systemd/journal/dev-log
...
```

`-i` 옵션을 사용하면 네트워크 인터페이스를 통해 주고 받은 패킷에 대한 정보를 확인할 수 있다.

```bash
$ netstat -i
Kernel Interface table
Iface      MTU    RX-OK RX-ERR RX-DRP RX-OVR    TX-OK TX-ERR TX-DRP TX-OVR Flg
docker0   1500  4516881      0      0 0       4453333      0      0      0 BMRU
docker_g  1500 31766422      0      0 0      30192881      0      0      0 BMRU
eno1      1500 212252892      0     65 0      59361573      0      0      0 BMRU
eno2      1500        0      0      0 0             0      0      0      0 BMU
eno3      1500        0      0      0 0             0      0      0      0 BMU
```

`-nr` 옵션을 사용하면 라우팅 테이블 정보를 확인할 수 있다.

```bash
$ netstat -nr
Kernel IP routing table
Destination     Gateway         Genmask         Flags   MSS Window  irtt Iface
0.0.0.0         114.108.176.65  0.0.0.0         UG        0 0          0 eno1
114.108.176.64  0.0.0.0         255.255.255.224 U         0 0          0 eno1
```

프로토콜에 따른 패킷 통계를 확인하기 위해서는 `-s` 옵션을 사용한다. 어떤 프로토콜이 제대로 동작하지 않는지, 쓸모없는 프로토콜이 동작하고 있는건 아닌지 확인할 수 있다. 

```bash
$ netstat -s
Ip:
    Forwarding: 1
    137414135 total packets received
    35886764 forwarded
    385 with unknown protocol
    0 incoming packets discarded
    100479457 incoming packets delivered
    122011477 requests sent out
    20 outgoing packets dropped
    52 reassemblies required
    26 packets reassembled ok
Icmp:
    3646098 ICMP messages received
    107 input ICMP message failed
    ICMP input histogram:
        destination unreachable: 5301
        timeout in transit: 264
...
```

`-atp`를 사용하면 열려있는 포트와 데몬, 그리고 그 포트를 사용하는 프로그램에 대한 정ㅇ보를 상세히 확인할 수 있다.
```bash
$ netstat -atp
(Not all processes could be identified, non-owned process info
 will not be shown, you would have to be root to see it all.)
Active Internet connections (servers and established)
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name    
tcp        0      0 0.0.0.0:2001            0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:cisco-sccp      0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:2003            0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:2002            0.0.0.0:*               LISTEN      -                   
tcp        0      0 0.0.0.0:5000            0.0.0.0:*               LISTEN      -         
...
```