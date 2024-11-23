
### ip_forward

IP forward는 일반적인 라우터 동작처럼 하나의 인터페이스로 들어온 패킷을 읽어서 일치하는 서브넷을 가지는 다른 네트워크 인터페이스로 패킷을 포워딩하는 것을 말한다.

라우터는 이 방식으로 패킷을 라우팅하지만 대부분의 호스트는 이 작업을 수행할 필요가 없다.

따라서 기본적으로 비활성화 되어있는 기능인데, 필요에 따라 옵션을 활성화할 수 있다.

```
sysctl -w  net.ipv4.conf.default.rp_filter=integer
sysctl -w net.ipv4.conf.all.rp_filter=integer
```

interger에 활성화 여부를 나타내는 숫자를 넣는다.

- `0` - 비활성화 (기본값)
- `not 0` - 활성화

인터페이스별로 지정해줄 수도 있다.

```
sysctl -w net.ipv4.conf.interface.ip_forward=integer
```

설정값을 영구적으로 수정하기 위해선 `/etc/sysctl.conf` 파일을 수정해야 한다.

```
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p /etc/sysctl.conf
```

### rp_filter

`rp_filter`는 Reverse Path Filter(역방향 경로 전달)의 줄임말이다.

`ip_forward`는 포워딩을 활성화하는 옵션이고, 역방향 경로 전달은 포워딩 중 하나의 인터페이스를 통해 들어오는 패킷이 다른 인터페이스를 통해 나가는 것을 방지하는데 사용된다.

이 검증을 활성화하면 사용자가 로컬 서브넷에서 IP 주소를 스푸핑하여 DDoS 공격을 날리는 것을 방지할 수 있다.

ip_forward와 마찬가지로 sysctl를 사용해 변경한다.

```
sysctl -w  net.ipv4.conf.default.rp_filter=integer
sysctl -w net.ipv4.conf.all.rp_filter=integer
```

여기서 integer 는 다음 중 하나이다.

- `0`: 소스 검증 없음 (기본값)

- `1`: 엄격한 모드
  - 각 수신 패킷은 FIB(Forwarding Information Base)와 대조 검사되며, 해당 인터페이스가 최적의 역경로가 아닌 경우 패킷 검사가 실패한다.

- `2`: 느슨한 모드
  - 각 수신 패킷과 출발지 주소 둘 다 FIB와 대조 검사하여, 출발지 주소가 어떤 인터페이스를 통해서도 도달할 수 없는 경우 패킷 검사가 실패한다.

RFC3704의 권장 옵션은 DDoS 공격으로부터의 IP 스푸핑을 방지하기 위해 엄격한 모드를 사용하는 것이다. 비대칭 라우팅이나 기타 복잡한 라우팅을 사용하는 경우에는 느슨한 모드가 권장된다.
`ip_forward`와 같이 네트워크 인터페이스별로 재정의할 수 있다. 인터페이스별로 재정의한 경우 기본값과 재정의 값 중 최대값을 사용한다.

---
참고

- <https://www.kernel.org/doc/Documentation/networking/ip-sysctl.txt>
- <https://unix.stackexchange.com/questions/673573/what-exactly-happens-when-i-enable-net-ipv4-ip-forward-1>
- <https://access.redhat.com/solutions/53031>
- <https://docs.redhat.com/ko/documentation/red_hat_enterprise_linux/7/html/security_guide/sec-disabling_source_routing#sect-Security_Guide-Server_Security-Reverse_Path_Forwarding>
