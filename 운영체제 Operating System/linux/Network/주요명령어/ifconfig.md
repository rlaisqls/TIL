
ifconfig는 시스템에 설치된 네트워크 인터페이스 정보를 확인하거나 수정하는 명령어이다.

`ifconfig [인터페이스][옵션]` 형식으로 입력하며, 아무 옵션 없이 `ifconfig`를 입력하면 현재 설정된 네트워크 인터페이스 상태를 보여준다. `lo`는 루프백 인터페이스로 자기 자신과 통신하는 데 사용하는 가상 장치이며, 흔히 랜카드라고 불리는 유선 네트워크 인터페이스는 `eth0`, 무선 네트워크 인터페이스는 `wlan0`라고 명명한다.

IP 주소는 호스트에 하나씩 부여되는 것이 아니라 네트워크 인터페이스에 할당되기 때문에 각 네트워크 인터페이스마다 다른 IP 주소를 할당할 수 있다.

내가 테스트해본 서버에서는 embedded NIC인 `eno1`와 가상 이더넷 인터페이스인 `veth`, 그리고 `lo` 등의 여러 네트워크 인터페이스를 확인해볼 수 있었다. eth는 선으로 연결된 onboard Ethernet, eno는 기기에 장착된 NIC라는 점이 차이이다.

```bash
$ ifconfig
eno1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 114.108.176.85  netmask 255.255.255.224  broadcast 114.108.176.95
        inet6 fe80::1602:ecff:fe3d:cf14  prefixlen 64  scopeid 0x20<link>
        ether 14:02:ec:3d:cf:14  txqueuelen 1000  (Ethernet)
        RX packets 212179261  bytes 63191358374 (63.1 GB)
        RX errors 0  dropped 65  overruns 0  frame 0
        TX packets 59341323  bytes 21948854635 (21.9 GB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
        device interrupt 16  

veth107fd5b: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet6 fe80::38ae:d4ff:fe91:238a  prefixlen 64  scopeid 0x20<link>
        ether 3a:ae:d4:91:23:8a  txqueuelen 0  (Ethernet)
        RX packets 6388  bytes 522059 (522.0 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 46505  bytes 4299681 (4.2 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 35482223  bytes 91469141584 (91.4 GB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 35482223  bytes 91469141584 (91.4 GB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
...
```

각 네트워크 인터페이스의 필드는 다음을 의미한다.

- **HWaddr:** 네트워크 인터페이스의 하드웨어 주소(MAC address)
- **inet addr:** 네트워크 인터페이스에 할당된 IP 주소
- **Bcast:** 브로드캐스트 주소
- **Mask:** 넷마스트
- **MTU:** 네트워크 최대 전송 단위(Maximum Transfer Unit)
- **RX packets:** 받은 패킷 정보
- **TX packets:** 보낸 패킷 정보
- **collisions:** 충돌된 패킷 수
- **Interrupt:** 네트워크 인터페이스가 사용하는 인터럽트 번호

필요하다면 `ifconfig` 명령으로 네트워크 인터페이스를 작동시키거나 중지시킬 수 있다. 하위 명령 up, down을 추가하여 네트워크 인터페이스를 중지할 수 있다. root 권한이 필요하기 때문에 sudo를 사용해야한다. 예를 들어 eth0를 중지하려면 다음과 같이 입력한다.

```bash
$ sudo ifconfig eth0 down
```

다시 네트워크 인터페이스 eth0를 작동시키려면 하위 명령 up을 사용하는데, 옵션으로 IP 주소를 직접 입력해서 IP주소를 변경할 수 있다.

```bash
$ sudo ifconfig eth0 192.168.0.254 up
```

이렇게 변경된 내용은 다시 ifconfig로 설정을 수정하거나 시스템이 다시 부팅될 때까지 임시로 유지된다. ifconfig나 [route](route.md)와 같은 명령어는 관리 목적으로 네트워크 주소 정보를 잠시 변경할 때 사용하고, 네트워크 설정을 변경하려면 네트워크 인터페이스 설정 파일을 수정해야한다.

---
참고
- https://superuser.com/questions/1053003/what-is-the-difference-between-eth1-and-eno1
- 책, 리눅스 서버를 다루는 기술, 길벗, 신재훈