
컨테이너는 [namespace](namespace와 cgroup.md)를 사용하여 같은 host 안에서 자원을 격리한다. 

network namespace는 도커와 같은 컨테이너에서 네트워크 격리를 구현하기 위해 쓰인다. 기본적으로 호스트는 외부 네트워크와 연결하기 위한 인터페이스와 Routing Table, ARP Table을 가지고 있는데, 컨테이너를 만들면 그 컨테이너에 대한 network namespace가 생성되어서 호스트의 네트워크 인터페이스와 완전히 분리된다.

대신에, 추가적으로 **컨테이너 각각에 가상의 인터페이스와 Routing Table, ARP Table을 설정**하면 설정대로 통신을 할 수 있게 된다. 호스트에서는 각 네트워크 인터페이스의 네트워크 요소를 확인할 수 없으며, 각 네임스페이스도 호스트가 외부와 통신하기 위해 쓰는 네트워크 요소를 확인할 수 없다.

## 명령어

네임 스페이스 목록 보기
```js
ip netns
```

인터페이스 목록 보기
```
ip link
```

네임스페이스 내부의 인터페이스 목록 보기
```js
ip netns exec {namespace name} ip link
ip -n {namespace name} link
```

```js
arp
route
```

## 두 network namespace를 직접 연결하기

`red`와 `blue`라는 네트워크 인터페이스를 만들어놓았다고 해보자

두 인터페이스를 [veth](veth.md)로 연결되도록 한다. (아직 이 인터페이스가 네임스페이스와 등록되진 않았다.)
```js
ip link add veth-red type veth peer name veth-blue
```

각 인터페이스를 네임스페이스에 등록한다.
```js
ip link set veth-red netns red
ip link set veth-blue netns blue
```

네임스페이스(인터페이스)에 가상 ip를 지정한다.
```js
ip -n red addr add 192.168.15.1 veth-red
ip -n blue addr add 192.168.15.1 veth-blue
```

인터페이스가 실제로 작동할 수 있도록 활성화한다.
```js
ip -n red link set veth-red up
ip -n blue link set veth-blue up
```

red에서 blue의 ip로 ping을 보내면 arp 테이블에서 해당 호스트를 등록해놓은 것을 볼 수 있다.
```js
ip netns exec red ping 192.168.15.2
ip netns exec
```

output
```js
Address        HWtype  HWaddress          Flags Mak  Iface
192.168.15.2   ether   ba:b0:6d:68:09:e9  C          veth-red
```

## 가상 switch 만들기

위와같이 인터페이스를 직접 연결하지 않고, [네트워크 스위치](https://ko.wikipedia.org/wiki/%EB%84%A4%ED%8A%B8%EC%9B%8C%ED%81%AC_%EC%8A%A4%EC%9C%84%EC%B9%98)를 가상으로 구현하여 연결하는 방법도 있다. 

linux bridge를 통해 가상 switch를 구현하는 방법을 알아보자.

우선은 호스트에 브릿지 타입의 네트워크 인터페이스를 하나 정의해준다.
```js
ip link add v-net-0 type bridge
ip link set deb v-net-0 up
```

이 인터페이스는 브릿지 타입이기 떄문에, 각 네트워크 네임스페이스에서도 보고 접근할 수 있다. 

인터페이스를 통해 스위치와 네임스페이스를 이어주자.

```js
ip link add veth-red type veth peer name veth-red-br
ip link set veth-red netns red
ip link set veth-red-br master v-net-0

ip link add veth-blue type veth peer name veth-blue-br
```

그리고 네임스페이스(인터페이스)에 가상 ip를 지정하고 활성화한다.
```js
ip -n red addr add 192.168.15.1 veth-red
ip -n blue addr add 192.168.15.1 veth-blue
ip -n red link set veth-red up
ip -n blue link set veth-blue up
```

이렇게 여러 네임스페이스를 연결해주면, 서로 통신할 수 있는 상태가 된다. 하지만 여기까지는 각 네임스페이스끼리만 연결되어있는 상태기 때문에, 외부에서는 이 네임스페이스에 접근할 방법이 아직 없다.

외부에서 네트워크 네임스페이스에 접근할 수 있도록 하기 위해선, 호스트를 거쳐야한다. 이를 설정해줄 수 있도록 하는 것이 바로 iptable이다.

호스트로 들어온 트래픽을 어떤 네트워크로 보낼지 구분하기 위해서 들어온 포트에 따라 매핑하는 방식을 사용하는 것이 대표적이다. 여기서 dport와 destination port를 다르게 설정하면, 포트포워딩이 된다.

```js
iptables -t nat -A PRESOUTING --dport 80 --to-destination 192.168.15.2:80 -j DNAT
```

최종적으로 아래와 같은 모양이 된다.

<img src="https://user-images.githubusercontent.com/81006587/216491394-fa7e84e9-d1a8-437c-b5a6-2fd460f9532f.png" height=300px>