
ssh 명령어로 항상 같은 서버에 접속할 때, 매번 pem, host를 지정하는 것이 귀찮다면 설정에 등록해서 사용해보자

```bash
sudo vi /etc/ssh/ssh_config
```

이런식으로 밑에 추가해주면 된다.

```bash
# dev
Host dev
    HostName x.x.x.x
    User ec2-user 
    IdentityFile /user/rlaisqls/...
 
# ops
Host ops
    HostName x.x.x.x
    User ec2-user
    IdentityFile /user/rlaisqls/...
```

- Host: 이름
- HostName: 연결될 서버 호스트 명  (미 설정시 Host값이 HostName으로 사용됨)
- User: 네트워크 커넥션에 사용되는 계정 명
- IdentityFile: 키 파일 위치

이런식으로 바로 접속해줄 수 있다.

```bash
$ ssh dev
```