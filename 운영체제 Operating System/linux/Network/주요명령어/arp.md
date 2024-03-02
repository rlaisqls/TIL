
```bash
/sbin/arp
```

시스템 사이의 통신에는 상대방의 MAC 주소가 필요하다. 이때 arp는 ARP를 이용하여 상대 시스템 IP에 신호를 보내 MAC 주소를 받아온다.

서브넷의 ARP 정보는 연결 효율을 높이기 위해 `/proc/net/arp`에 저장된다. 

이와 같이 저장된 ARP 캐시의 내용(연결하려는 시스템의 MAC 주소)을 자세히 보고 싶다면 다음과 같이 실행한다.

```bash
$ arp -v
Address                  HWtype  HWaddress           Flags Mask            Iface
ip-172-18-0-3.ap-northe  ether   02:42:ac:12:00:03   C                     br-58c1503932a1
ip-172-18-0-2.ap-northe  ether   02:42:ac:12:00:02   C                     br-58c1503932a1
ip-172-31-32-1.ap-north  ether   0a:7e:87:6d:6c:80   C                     ens5
ip-172-17-0-4.ap-northe  ether   02:42:ac:11:00:04   C                     docker0
ip-172-17-0-3.ap-northe  ether   02:42:ac:11:00:03   C                     docker0
ip-172-17-0-2.ap-northe  ether   02:42:ac:11:00:02   C                     docker0
Entries: 6	Skipped: 0	Found: 6
```

```bash
$ arp --help
Usage:
  arp [-vn]  [<HW>] [-i <if>] [-a] [<hostname>]             <-Display ARP cache
  arp [-v]          [-i <if>] -d  <host> [pub]               <-Delete ARP entry
  arp [-vnD] [<HW>] [-i <if>] -f  [<filename>]            <-Add entry from file
  arp [-v]   [<HW>] [-i <if>] -s  <host> <hwaddr> [temp]            <-Add entry
  arp [-v]   [<HW>] [-i <if>] -Ds <host> <if> [netmask <nm>] pub          <-''-

        -a                       display (all) hosts in alternative (BSD) style
        -e                       display (all) hosts in default (Linux) style
        -s, --set                set a new ARP entry
        -d, --delete             delete a specified entry
        -v, --verbose            be verbose
        -n, --numeric            don't resolve names
        -i, --device             specify network interface (e.g. eth0)
        -D, --use-device         read <hwaddr> from given device
        -A, -p, --protocol       specify protocol family
        -f, --file               read new entries from file or from /etc/ethers

  <HW>=Use '-H <hw>' to specify hardware address type. Default: ether
  List of possible hardware types (which support ARP):
    ash (Ash) ether (Ethernet) ax25 (AMPR AX.25) 
    netrom (AMPR NET/ROM) rose (AMPR ROSE) arcnet (ARCnet) 
    dlci (Frame Relay DLCI) fddi (Fiber Distributed Data Interface) hippi (HIPPI) 
    irda (IrLAP) x25 (generic X.25) eui64 (Generic EUI-64) 
```

## 관련 명령어

- **arping:** 대상 주소에 ARP 패킷을 보낸다.
- **arpwatch:** Ethernet/IP 주소의 진로를 추적한다.
- **arpsnmp:** Ethernet/IP 주소의 진로를 추적한다.
- **tcpdump:** 네트워크 인터페이스에서의 패킷 헤더를 출력한다.