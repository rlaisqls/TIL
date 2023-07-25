# Overlay Network

![image](https://github.com/rlaisqls/TIL/assets/81006587/2aa88149-c805-4bcc-abb6-5326db36f458)

* 컨테이너를 설치하게 되면 default로 bridge 네트워크가 연결된다.
* private internal network
* 각 컨테이너는 veth (virtual) 경로로 bridge 네트워크와 연결된다
* bridge를 통해 Single-host networking 효과를 낼 수 있다
* 외부에서 접근시에는 port-mapping이 필요하다

```bash
$ docker container

Usage:  docker network COMMAND

Manage Docker networks

Options:
      --help   Print usage

Commands:
  connect     Connect a container to a network
  create      Create a network
  disconnect  Disconnect a container from a network
  inspect     Display detailed information on one or more networks
  ls          List networks
  rm          Remove one or more networks

Run 'docker network COMMAND --help' for more information on a command.
```

docker container 명령어는 컨테이너 네트워크를 규명하고 관리하는 데에 사용되는 가장 기본적인 명령어이다.

명령어 그대로 입력하면 지원하는 sub-command를 확인할 수 있는데, `create`/`inspect` 와 같이 다양한 명령어들을 확인할 수 있다.

```bash
$ docker network ls    # list networks
NETWORK ID          NAME                DRIVER              SCOPE
1befe23acd58        bridge              bridge              local
726ead8f4e6b        host                host                local
ef4896538cc7        none                null                local
```

​네트워크는 각각 유니크한 이름과 ID를 지니게 되고, 한 개의 드라이브를 소유하고 있다.

위에서 'bridge'란 이름의 네트워크를 찾아볼 수 있는데, 이는 도커를 가장 처음 설치했을 때 자동으로 설치되는 default 네트워크이다.

브릿지 네트워크는 브릿지 드라이버를 사용하는데, 위 예시는 name과 driver 명이 동일해서 헷갈릴 수 있지만, 두 개는 다른 개념이다.

위 예시에서 브릿지 네트워크는 local로 범위가 정해져있는데, 이 의미는 해당 네트워크가 도커 호스트 내에서만 존재한다는 것이다.

어떤 컨테이너를 생성하더라도, 특별히 네트워크를 지정해주지 않았다면 브릿지 네트워크에 기본적으로 연결되어 있다. 아래에 예제로 백그라운드 환경에서 `sleep infinity` 명령어를 수행하는 `ubuntu:latest` 이미지로 생성된 컨테이너를 실행해보자.

`docker run` 명령어에 별도로 네트워크를 지정해주지 않았기 때문에 bridge 네트워크로 연결되어있을 것이다.

```bash
$ docker run -dt ubuntu sleep infinity
6dd93d6cdc806df6c7812b6202f6096e43d9a013e56e5e638ee4bfb4ae8779ce

$ brctl show
bridge name     bridge id               STP enabled     interfaces
docker0         8000.0242f17f89a6       no              veth3a080f
```

linux bridge 네트워크를 리스팅하는 명령어 `brctl`을 사용하여 수행하면 위와 같이 결과를 확인할 수 있다.

인터페이스에 값이 생긴 것으로 보아 방금 생성한 컨테이너에 bridge 네트워크가 연결되었음을 확인할 수 있다.

```bash
$ docker network inspect bridge
<Snip>
        "Containers": {
            "6dd93d6cdc806df6c7812b6202f6096e43d9a013e56e5e638ee4bfb4ae8779ce": {
                "Name": "reverent_dubinsky",
                "EndpointID": "dda76da5577960b30492fdf1526c7dd7924725e5d654bed57b44e1a6e85e956c",
                "MacAddress": "02:42:ac:11:00:02",
                "IPv4Address": "172.17.0.2/16",
                "IPv6Address": ""
            }
        },
<Snip>
```

`docker network inspect`를 해보게 되면, 컨테이너 ID가 보임으로써 컨테이너에 네트워크가 올바르게 attach된 것을 확인할 수 있다.

도커 호스트의 쉘 프롬프트를 실행하여 `ping <도커 컨테이너 IP주소>`를 하게 되면 정상적으로 응답하는 것을 확인할 수 있다. 거꾸로 도커 컨테이너에 접속하여 ping을 설치한 뒤 어느 웹사이트에의 ping 명령어를 수행해도 마찬가지로 정상적인 응답을 확인할 수 있다.

```bash
$ docker ps    // 컨테이너 ID를 얻기 위해 수행
CONTAINER ID    IMAGE    COMMAND             CREATED  STATUS  NAMES
6dd93d6cdc80    ubuntu   "sleep infinity"    5 mins   Up      reverent_dubinsky

// Exec into the container
$ docker exec -it 6dd93d6cdc80 /bin/bash   // bash쉘을 실행하기 위해 -it 옵션
// -i : interactive (stdin활성화)
// -t : tty 모드 설정 여부

# Update APT package lists and install the iputils-ping package
root@6dd93d6cdc80:/# apt-get update
<Snip>

apt-get install iputils-ping  // ping설치
Reading package lists... Done
<Snip>

# Ping www.dockercon.com from within the container
root@6dd93d6cdc80:/# ping www.dockercon.com
PING www.dockercon.com (104.239.220.248) 56(84) bytes of data.
64 bytes from 104.239.220.248: icmp_seq=1 ttl=39 time=93.9 ms
64 bytes from 104.239.220.248: icmp_seq=2 ttl=39 time=93.8 ms
64 bytes from 104.239.220.248: icmp_seq=3 ttl=39 time=93.8 ms
^C
--- www.dockercon.com ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2002ms
rtt min/avg/max/mdev = 93.878/93.895/93.928/0.251 ms
```

이제는 NAT를 구성해보자. 도커 호스트의 8080포트와 컨테이너 내부의 80 포트를 연결하도록 publishing하는 nginx 이미지 서버를 띄워보자.

```bash
$ docker run --name web1 -d -p 8080:80 nginx
```

이후 docker ps를 통해 포트 매핑이 정상적으로 이루어졌음을 확인할 수 있다.

---

## Overlay Network

![image](https://github.com/rlaisqls/TIL/assets/81006587/4670516f-27d1-424e-bca9-ddd81589a177)

docker swarm을 설치해서 멀티 노드를 구성하여 실습해볼 것이다. linux-base 도커 호스트 2개를 사용하고, 각 노드를 node1, node2로 구분하였다.

Manager노드와 worker node를 구성하는 것인데, manager노드에서 worker node에게 ping을 날렸을 때 응답을 받을 수 있어야한다.

```bash
node1$ docker swarm init
Swarm initialized: current node (cw6jpk7pqfg0jkilff5hr8z42) is now a manager.
To add a worker to this swarm, run the following command:

docker swarm join \
--token SWMTKN-1-3n2iuzpj8jynx0zd8axr0ouoagvy0o75uk5aqjrn0297j4uaz7-63eslya31oza2ob78b88zg5xe \
172.31.34.123:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

node1에서 docker swarm을 init하게 되면 `swarm join`이 가능한 토큰이 발행되는데, 이를 노드 2에서 사용할 것이다.

```bash
node2$ docker swarm join \
>     --token SWMTKN-1-3n2iuzpj8jynx0zd8axr0ouoagvy0o75uk5aqjrn0297j4uaz7-63eslya31oza2ob78b88zg5xe \
>     172.31.34.123:2377

This node joined a swarm as a worker.
```

노드 1로 돌아가서 아래와 같이 수행하면 정상적으로 swarm 에 두 노드가 돌아가고 있는 것을 확인할 수 있다.

```bash
node1$ docker node ls
ID                           HOSTNAME          STATUS  AVAILABILITY  MANAGER STATUS
4nb02fhvhy8sb0ygcvwya9skr    ip-172-31-43-74   Ready   Active
cw6jpk7pqfg0jkilff5hr8z42 *  ip-172-31-34-123  Ready   Active        Leader
```

이제 `overlay` 네트워크를 만들어볼 차례인데, node1에서 overnet이라는 이름의 `overlay` 드라이브의 도커 네트워크를 생성한다.

```bash
node1$ docker network create -d overlay overnet
0cihm9yiolp0s9kcczchqorhb
```

docker network를 리스팅 해보면 아래와 같이 swarm 스코프에 생성된 네트워크 두 개가 발견이 된다.

(ingress와 docker_gwbridge 네트워크는 `overlay` 네트워크가 생성되면서 자동으로 생성되었다)

```bash
node1$ docker network ls
NETWORK ID          NAME                DRIVER      SCOPE
1befe23acd58        bridge              bridge      local
726ead8f4e6b        host                host        local
8eqnahrmp9lv        ingress             overlay     swarm
0ea6066635df        docker_gwbridge     bridge      local
ef4896538cc7        none                null        local
0cihm9yiolp0        overnet             overlay     swarm
```

node2에서도 동일한 명령어를 수행하면 `overlay` 네트워크를 찾아볼 수 없는데, 그 이유는 도커가 `overlay` 네트워크가 연결된 호스트 내에 서비스가 동작하여 수행중일 때에만 해당 네트워크를 연결해주기 때문이다.

노드1에서 위에 생성한 `overlay` 네트워크로 서비스를 하나 생성해보자. 서비스는 간단하게 sleep하는 우분투 서버이다.

```bash
node1$ docker service create --name myservice \
--network overnet \
--replicas 2 \
ubuntu sleep infinity

e9xu03wsxhub3bij2tqyjey5t
```

위에서 replica를 2개를 생성하였는데, 아래와 같이 docker service ps {서비스이름} 을 수행하게 되면, 각 서비스가 다른 노드에서 돌고 있는 것을 확인할 수 있다. 이제 node2 역시도 `overlay` 네트워크에서 서비스를 수행하고 있는 상황이라, node2 콘솔에서 위의 docker network 리스팅을 해보면 안보였던 overnet 네트워크가 확인이 될 것이다.

```bash
node1$ docker service ps myservice
ID            NAME         IMAGE   NODE   DESIRED STATE  CURRENT STATE  ERROR
5t4wh...fsvz  myservice.1  ubuntu  node1  Running        Running 2 mins
8d9b4...te27  myservice.2  ubuntu  node2  Running        Running 2 mins
```

이제 네트워크가 정상적으로 연결되어 서로 확인이 가능한지 보자.

node1에 접속하여 `docker ps`를 수행하게 되면, 위에 생성해둔 Myservice 서비스 중 node1에서 돌고 있는 서비스가 확인이 된다.

```bash
node1$ docker ps
CONTAINER ID   IMAGE           COMMAND            CREATED      STATUS         NAMES
053abaac4f93   ubuntu:latest   "sleep infinity"   19 mins ago  Up 19 mins     myservice.2.8d9b4i6vnm4hf6gdhxt40te27
```

위에서 얻은 container ID로 docker를 execute하여, ping을 설치하고 node2 IP로 ping을 보내보면 응답을 받는 것을 확인할 수 있다.

```bash
node1$ docker exec -it 053abaac4f93 /bin/bash
root@053abaac4f93:/# apt-get update && apt-get install iputils-ping
<Snip>
root@053abaac4f93:/# ping 10.0.0.4  // node2 IP 주소
PING 10.0.0.4 (10.0.0.4) 56(84) bytes of data.
64 bytes from 10.0.0.4: icmp_seq=1 ttl=64 time=0.726 ms
64 bytes from 10.0.0.4: icmp_seq=2 ttl=64 time=0.647 ms
^C
--- 10.0.0.4 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 999ms
rtt min/avg/max/mdev = 0.647/0.686/0.726/0.047 ms
```
이를 통해 node1과 node2가 정상적으로 네트워크를 공유하고 있음을 확인할 수 있다.

![image](https://github.com/rlaisqls/TIL/assets/81006587/ed6fb619-cfd3-4ed3-973a-e46a056396be)

---
참고
- https://docs.docker.com/network/network-tutorial-overlay/
- https://docs.docker.com/network/drivers/overlay/