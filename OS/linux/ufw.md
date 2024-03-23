우분투의 기본적인 방화벽은 UFW이다. 이는 iptables를 좀 더 쉽게 설정할 수 있도록 한 것인데 간단한 방화벽 구성에는 문제가 없지만 수준 높은 방화벽 구성에는 iptables 룰을 직접 사용해야한다.

### UFW 사용법
UFW 기본 설정법에 대하여 알아보자.

- UFW 활성화/비활성화
  
  UFW는 기본 비활성화 상태이기에 활성화 해주어야 사용할 수 있다.

  ```bash
  sudo ufw enable
  ```

- UFW 비활성화

  ```bash
  sudo ufw disable
  ```

- UFW 상태 확인

  ```bash
  sudo ufw status verbose
  ```

### UFW 기본 룰

UFW에 설정되어 있는 기본 룰은 아래와 같다.

- 들어오는 패킷에 대해서는 전부 거부(deny)
- 나가는 패킷에 대해서는 전부 허가(allow)

- 기본 룰 확인

  ```bash
  sudo ufw show raw
  ```

- 기본 정책 차단

  ```bash
  sudo ufw default deny
  ```

- 기본 정책 허용

  ```bash
  sudo ufw default allow
  ```


### UFW 허용

```bash
sudo ufw allow <port>/<optional: protocal>
```

- SSH 포트 22번 허용(tcp/udp 22번 포트를 모두 허용)

  ```bash
  sudo ufw allow 22
  ```

- tcp 22번 포트만을 허용 - SSH는 tcp 22번 포트만 허용하는게 정답

  ```bash
  sudo ufw allow 22/tcp
  ```

- udp 22번 포트만을 허용

  ```bash
  sudo ufw allow 22/udp
  ```

### UFW 거부

```bash
sudo ufw deny <port>/<optional: protocol>
```

- ssh 포트 22번 거부(tcp/udp 22번 포트를 모두 거부)

  ```bash
  sudo ufw deny 22
  ```

- tcp 22번 포트만을 거부

  ```bash
  sudo ufw deny 22/tcp
  ```

- udp 22번 포트만을 거부

  ```bash
  sudo ufw deny 22/udp
  ```

- UFW 룰의 삭제 (ufw deny 22/tcp 설정이 되어있다고 가정)

  ```bash
  sudo ufw delete deny 22/tcp
  ```

#### service 명을 이용한 설정

`/etc/services`에 지정되어 있는 서비스명과 포트를 이용해 UFW를 설정할 수 있다.

```bash
# 서비스명 보기
less /etc/services
# 서비스명으로 허용
sudo ufw allow <service name>
```

### UFW 로그 기록

```bash
sudo ufw logging on
sudo ufw logging off
```

### 특정한 IP 주소 허가/거부

- 특정한 IP주소 허용
  ```bash
  sudo ufw allow from <ip address>
  ```

- 특정 IP 주소와 일치하는 포트 허용
  ```bash
  sudo ufw allow from <ip address> to <protocol> port <port number>
  ```

- 특정 IP 주소와 프로토콜, 포트 허용

  ```bash
  sudo ufw allow from <ip address> to <protocol> port <port number> proto <protocol name>
  ```

### ping (icmp) 허용/거부

UFW 기본설정은 ping 요청을 허용하도록 되어있다.

  ```bash
  sudo vi /etc/ufw/before.rules

   # ok icmp codes
  -A ufw-before-input -p icmp --icmp-type destination-unreachable -j ACCEPT
  -A ufw-before-input -p icmp --icmp-type source-quench -j ACCEPT
  -A ufw-before-input -p icmp --icmp-type time-exceeded -j ACCEPT
  -A ufw-before-input -p icmp --icmp-type parameter-problem -j ACCEPT
  -A ufw-before-input -p icmp --icmp-type echo-request -j ACCEPT
  ```

위 코드들의 ACCEPT 부분을 모두 DROP으로 변경하거나 삭제하면 ping 요청을 거부하게 된다.

### ufw numbered rules

UFW 룰들에 숫자를 붙여서 볼 수 있다. 이를 이용해 룰에 수정이나 삭제, 추가를 할 수 있다.

- ufw number 보기
  ```bash
  sudo ufw status numbered
  ```

- ufw numbered 수정
  ```bash
  sudo ufw delete 1
  sudo ufw insert 1 allow from 192.168.0.100
  ```

---
참고
- https://help.ubuntu.com/community/UFW