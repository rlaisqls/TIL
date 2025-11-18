
SSH는 원격 서버에 안전하게 접속하기 위한 암호화 프로토콜이다.

## 공개키 인증의 원리

SSH는 비밀번호 대신 공개키 비대칭 암호화 방식을 사용한다. 따라서 두 개의 키를 사용한다.

- **개인키(Private Key)**: 절대 공유하지 않는 비밀 키
- **공개키(Public Key)**: 누구에게나 공개해도 되는 키

공개키로 암호화한 데이터는 개인키로만 복호화할 수 있다. 반대로 개인키로 서명한 데이터는 공개키로 검증할 수 있다.

SSH 공개키 인증은 이렇게 작동한다.

1. 클라이언트가 서버에 접속을 시도한다
2. 서버는 등록된 공개키 목록(`~/.ssh/authorized_keys`)을 확인한다
3. 서버가 무작위 챌린지 데이터를 생성해 클라이언트에게 보낸다
4. 클라이언트는 개인키로 챌린지에 서명해 돌려보낸다
5. 서버는 공개키로 서명을 검증한다

이 과정에서 개인키 자체는 절대 전송되지 않는다. 개인키를 가진 사람만이 올바른 서명을 만들 수 있으므로, 서버는 클라이언트가 진짜 사용자임을 확신할 수 있다.

## SSH 키 관리

### SSH key 생성

아래 명령어로 SSH 키를 만들 수 있다. 현대적인 Ed25519 알고리즘을 사용하는 것이 권장된다.

```bash
ssh-keygen -t ed25519 -C "user@example.com"
```

RSA를 사용해야 한다면 최소 4096비트를 사용한다.

```bash
ssh-keygen -t rsa -b 4096 -C "user@example.com"
```

키를 생성하면 패스프레이즈를 입력하라고 나온다. 패스프레이즈는 개인키 자체를 암호화하는 비밀번호이다.

누군가 개인키 파일을 훔쳐가더라도 패스프레이즈 없이는 사용할 수 없다. 보안을 위해 강력한 패스프레이즈를 설정하는 것을 권장한다.

### 파일 경로

ssh에 관련된 파일은 `~/.ssh/` 디렉터리에 저장된다.

```bash
ls -la ~/.ssh/
```

각 파일의 역할은 이렇다.

- `id_ed25519`: 개인키. 절대 공유하지 않는다. 권한은 600이어야 한다.
- `id_ed25519.pub`: 공개키. 서버에 등록할 키이다. 누구에게나 공개해도 안전하다.
- `known_hosts`: 접속했던 서버의 호스트 키 지문을 저장한다. 중간자 공격을 방지한다.
- `authorized_keys`: (서버 측) 이 사용자로 접속할 수 있는 공개키 목록이다.
- `config`: SSH 접속 설정을 저장한다.

### 공개키 등록

공개키를 서버의 `~/.ssh/authorized_keys` 파일에 추가하면 된다. 가장 간단한 방법은 `ssh-copy-id`를 사용하는 것이다.

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@remote-host
```

이 명령은 공개키를 서버에 복사하고, 올바른 권한까지 설정해준다.

`ssh-copy-id`가 없다면 수동으로 할 수도 있다.

```bash
cat ~/.ssh/id_ed25519.pub | ssh user@remote-host "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

이제 비밀번호 없이 서버에 접속할 수 있다.

## Config 파일

매번 `ssh -i ~/.ssh/work_key -p 2222 user@192.168.1.100`처럼 긴 명령을 입력하는 건 번거롭다. `~/.ssh/config` 파일을 사용하면 이런 설정을 저장해두고 간단한 별칭으로 접속할 수 있다.

예를 들어 이런 config 파일을 만들면:

```
Host myserver
    HostName 192.168.1.100
    User myuser
    Port 2222
    IdentityFile ~/.ssh/work_key
```

주로 사용하는 옵션 목록

- `HostName`: 실제 호스트명 또는 IP 주소
- `User`: 로그인할 사용자명
- `Port`: SSH 포트 번호 (기본 22)
- `IdentityFile`: 사용할 개인키 경로
- `ProxyJump`: 점프 서버 경유
- `ForwardAgent`: SSH 에이전트 포워딩 활성화
- `ServerAliveInterval`: 주기적으로 연결 확인 메시지 전송 (초 단위)
- `ServerAliveCountMax`: 응답 없을 때 재시도 횟수
- `StrictHostKeyChecking`: 호스트 키 검증 정책 (yes/no/ask)

Config 파일은 개인키처럼 민감한 정보는 아니지만, 올바른 권한을 설정해두는 것이 좋다.

```bash
chmod 600 ~/.ssh/config
```

### 점프 서버 (Bastion Host)

내부 서버에 직접 접속할 수 없고, 중간의 점프 서버를 거쳐야 하는 경우가 있다. `ProxyJump`를 사용하면 이를 간단하게 처리할 수 있다.

```
Host bastion
    HostName bastion.company.com
    User admin

Host internal-server
    HostName 10.0.1.50
    User developer
    ProxyJump bastion
```

이제 `ssh internal-server`만 입력하면 bastion을 거쳐 자동으로 내부 서버에 접속된다.

## 포트 포워딩

SSH는 단순히 원격 접속만 하는 게 아니다. 네트워크 트래픽을 안전하게 터널링하는 데도 사용할 수 있다. 이를 포트 포워딩 또는 SSH 터널링이라고 부른다.

### 로컬 포트 포워딩

회사 내부 데이터베이스 서버가 있는데, 보안상 외부에서 직접 접속할 수 없다고 해보자. 하지만 SSH 서버에는 접속할 수 있다. 이럴 때 로컬 포트 포워딩을 사용한다.

```bash
ssh -L 3306:db.internal:3306 user@bastion-server
```

이 명령은 이런 의미다.

- 내 로컬의 3306 포트를 열어둔다
- 누군가 로컬 3306에 접속하면
- SSH 서버(bastion-server)를 통해 db.internal:3306으로 전달한다

이제 로컬에서 `localhost:3306`에 접속하면, 실제로는 내부 데이터베이스에 연결된다. 모든 트래픽은 SSH로 암호화되어 안전하다.

```bash
mysql -h 127.0.0.1 -P 3306 -u dbuser -p
```

다른 예시로, 내부 웹 서비스에 접속하고 싶다면:

```bash
ssh -L 8080:internal-web:80 user@jump-server
```

이제 브라우저에서 `http://localhost:8080`을 열면 내부 웹 서비스가 보인다.

### 원격 포트 포워딩

로컬 포트 포워딩과 반대 방향이다. 로컬에서 실행 중인 서비스를 원격 서버를 통해 외부에 노출하고 싶을 때 사용한다.

예를 들어 로컬에서 웹 애플리케이션을 개발 중인데(localhost:3000), 이를 팀원에게 보여주고 싶다고 해보자.

```bash
ssh -R 8080:localhost:3000 user@public-server
```

이제 팀원이 `public-server:8080`에 접속하면 당신의 로컬 3000 포트로 연결된다.

주의할 점은 서버의 `sshd_config`에서 `GatewayPorts yes` 설정이 필요할 수 있다는 것이다. 그렇지 않으면 원격 서버의 localhost에서만 접속 가능하다.

### 동적 포트 포워딩 (SOCKS 프록시)

매번 특정 포트를 지정하는 게 아니라, 모든 트래픽을 SSH를 통해 터널링하고 싶다면 동적 포트 포워딩을 사용한다.

```bash
ssh -D 1080 user@remote-server
```

이제 로컬에 SOCKS 프록시가 생성된다. 브라우저나 애플리케이션의 프록시 설정을 `localhost:1080` (SOCKS5)로 설정하면, 모든 네트워크 트래픽이 SSH 터널을 통해 원격 서버에서 나가게 된다.

이렇게 하면:

- 공개 WiFi에서도 안전하게 인터넷을 사용할 수 있다
- 지역 제한이 있는 서비스에 접속할 수 있다
- 방화벽을 우회할 수 있다

백그라운드로 실행하고 싶다면:

```bash
ssh -fN -D 1080 user@remote-server
```

- `-f`: 백그라운드로 실행
- `-N`: 원격 명령을 실행하지 않고 포워딩만 수행
- `-D`: SOCKS 프록시 포트 지정

## SSH 에이전트

개인키에 패스프레이즈를 설정하면 보안은 강화되지만, 서버에 접속할 때마다 패스프레이즈를 입력해야 하는 불편함이 있다. SSH 에이전트는 이 문제를 해결한다.

SSH 에이전트는 개인키를 메모리에 저장해두고, 필요할 때 자동으로 제공한다. 한 번만 패스프레이즈를 입력하면, 세션이 유지되는 동안 계속 사용할 수 있다.

에이전트를 시작한다.

```bash
eval "$(ssh-agent -s)"
```

개인키를 에이전트에 추가한다. 이때 패스프레이즈를 한 번 입력한다.

```bash
ssh-add ~/.ssh/id_ed25519
```

이제 서버에 접속할 때 패스프레이즈를 다시 입력할 필요가 없다.

등록된 키를 확인하려면:

```bash
ssh-add -l
```

모든 키를 에이전트에서 제거하려면:

```bash
ssh-add -D
```

### 에이전트 포워딩

점프 서버를 거쳐 최종 서버에 접속할 때, 점프 서버에는 개인키를 두고 싶지 않다. 이럴 때 에이전트 포워딩을 사용한다.

```bash
ssh -A user@jump-host
```

`-A` 옵션을 사용하면 로컬의 SSH 에이전트를 점프 서버에서도 사용할 수 있다. 점프 서버에서 다른 서버로 SSH 접속할 때, 로컬의 개인키로 인증한다. 개인키 자체는 전송되지 않고, 인증 요청만 로컬 에이전트로 포워딩된다.

Config 파일에 설정할 수도 있다.

```
Host jump-host
    ForwardAgent yes
```

하지만 주의할 점이 있다. 점프 서버가 해킹당하면 공격자가 에이전트를 악용할 수 있다. 신뢰할 수 있는 서버에만 에이전트 포워딩을 사용하자.

## 보안 강화

### 서버 측 보안

SSH 서버를 운영한다면 보안 설정을 강화해야 한다. 서버의 `/etc/ssh/sshd_config` 파일을 편집해 설정을 변경할 수 있다.

- 공개키 인증이 훨씬 안전하다. 비밀번호는 추측당하거나 무차별 대입 공격에 취약하다.

  ```
  PasswordAuthentication no
  ```

- 루트 계정으로 직접 접속하는 것은 위험하다. 일반 사용자로 접속한 후 필요할 때만 `sudo`를 사용하는 것이 안전하다.

  ```
  PermitRootLogin no
  ```

- 기본 포트 22번은 자동화된 공격의 주요 타겟이다. 포트를 변경하면 단순한 스캔 공격을 피할 수 있다.

  ```
  Port 2222
  ```
  
- 특정 사용자만 SSH 접속을 허용한다. 또는 특정 그룹만 허용할 수도 있다.

  ```
  AllowUsers alice bob
  AllowGroups ssh-users
  ```

- 기타 유용한 설정

  공개키 인증 활성화 (보통 기본값):

  ```
  PubkeyAuthentication yes
  ```

  빈 비밀번호 금지:

  ```
  PermitEmptyPasswords no
  ```

  X11 포워딩 비활성화 (필요없다면):

  ```
  X11Forwarding no
  ```

설정을 변경했다면 SSH 서비스를 재시작해야 적용된다.

```bash
sudo systemctl restart sshd
```

### 클라이언트 측 보안

서버만이 아니라 클라이언트 측도 신경써야 한다.

개인키 파일의 권한이 너무 느슨하면 SSH가 사용을 거부한다. 올바른 권한으로 설정하자.

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

개인키에 패스프레이즈를 추가하거나 변경하려면:

```bash
ssh-keygen -p -f ~/.ssh/id_ed25519
```

개인키가 유출되더라도 패스프레이즈가 있으면 즉시 사용할 수 없다. 그 사이에 키를 교체할 시간을 벌 수 있다.

## 파일 전송

SSH는 원격 접속만이 아니라 파일 전송에도 사용된다.

### SCP로 파일 복사하기

SCP(Secure Copy)는 SSH를 기반으로 한 파일 복사 도구다.

로컬 파일을 원격으로 전송:

```bash
scp local_file.txt user@remote:/path/to/destination/
```

디렉터리 전체를 복사하려면 `-r` 옵션:

```bash
scp -r local_directory user@remote:/path/to/destination/
```

원격에서 로컬로 다운로드:

```bash
scp user@remote:/path/to/file.txt ~/Downloads/
```

여러 파일을 한 번에:

```bash
scp file1.txt file2.txt user@remote:/destination/
```

### rsync로 동기화하기

SCP는 간단하지만, 큰 파일이나 디렉터리를 전송할 때는 비효율적이다. rsync는 변경된 부분만 전송해서 훨씬 빠르다.

```bash
rsync -avz -e ssh /local/path/ user@remote:/remote/path/
```

옵션의 의미:

- `-a`: 아카이브 모드. 권한, 타임스탬프, 심볼릭 링크 등을 보존한다
- `-v`: 진행 상황을 상세히 출력한다
- `-z`: 전송 중 압축한다
- `-e ssh`: SSH를 사용해 전송한다

rsync는 증분 백업에 아주 유용하다. 처음엔 모든 파일을 전송하지만, 다음부터는 변경된 파일만 전송한다.

삭제된 파일도 동기화하려면 `--delete`:

```bash
rsync -avz --delete -e ssh /local/path/ user@remote:/remote/path/
```

드라이런(실제로 실행하지 않고 무엇이 바뀔지 미리 확인):

```bash
rsync -avz --dry-run -e ssh /local/path/ user@remote:/remote/path/
```

### 원격 명령 실행하기

SSH로 접속하지 않고도 원격 명령을 실행할 수 있다.

```bash
ssh user@remote-host 'ls -la /var/log'
```

여러 명령을 실행하려면:

```bash
ssh user@remote-host 'cd /var/www && git pull && pm2 restart app'
```

로컬 스크립트를 원격에서 실행:

```bash
ssh user@remote-host 'bash -s' < local_script.sh
```

이런 식으로 배포 자동화 스크립트를 만들 수 있다.

### SSH Multiplexing으로 성능 개선하기

같은 서버에 여러 번 접속할 때, 매번 새 연결을 맺는 건 비효율적이다. SSH Multiplexing은 하나의 TCP 연결을 재사용해 여러 SSH 세션을 처리한다.

`~/.ssh/config`에 추가:

```
Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h-%p
    ControlPersist 600
```

소켓 디렉터리를 만든다:

```bash
mkdir -p ~/.ssh/sockets
```

이제 첫 번째 SSH 접속이 연결을 열고, 이후 접속들은 그 연결을 재사용한다. `ControlPersist 600`은 마지막 세션이 종료된 후에도 10분간 연결을 유지한다.

git push나 scp를 반복할 때 눈에 띄게 빨라지는 걸 느낄 수 있다.

## 관련 도구

SSH와 함께 사용하면 좋은 도구들을 소개한다.

### autossh

SSH 연결이 끊어지면 자동으로 재연결한다. 포트 포워딩을 계속 유지해야 할 때 유용하다.

```bash
autossh -M 0 -f -N -L 3306:db.internal:3306 user@bastion
```

### mosh (Mobile Shell)

WiFi와 모바일 네트워크를 오가거나 네트워크가 불안정한 환경에서도 끊김 없는 연결을 제공한다. UDP를 사용하고, 로컬에서 즉시 에코하기 때문에 반응이 빠르다.

```bash
mosh user@hostname
```

### tmux / screen

SSH 세션 안에서 터미널 멀티플렉서를 사용하면, 연결이 끊어져도 작업이 계속 실행된다. 다시 접속하면 세션에 다시 붙을 수 있다.

```bash
tmux
# 작업...
# Ctrl+B D로 detach

# 나중에 다시 접속
tmux attach
```

### sshfs

원격 디렉터리를 로컬에 마운트한다. 원격 파일을 로컬 파일처럼 편집할 수 있다.

```bash
sshfs user@remote:/remote/path ~/local/mount/point
```

---
참고

- <https://www.openssh.com>
- <https://www.ssh.com/academy/ssh>
- <https://www.digitalocean.com/community/tutorials/ssh-essentials-working-with-ssh-servers-clients-and-keys>
- <https://infosec.mozilla.org/guidelines/openssh>
- <https://en.wikipedia.org/wiki/Secure_Shell>
