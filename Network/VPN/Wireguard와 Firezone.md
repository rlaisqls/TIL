## WireGuard

[WireGuard](https://www.wireguard.com/)는 두 지점(Peer) 사이의 통신을 암호화하는 프로토콜에 대한 구현체이다.

WireGuard는 Diffie-Hellman(DH) key 교환 방식을 기초로 하는 Noise protocol을 기반으로 만들어졌다. 

**특징**
- 우수한 성능: UDP만을 사용하며, 불안정한 연결 환경에서도 잘 작동하도록 설계되었다. 또한 Linux에 내장되어 있는 암호화 기법들을 사용하면서 잘 최적화되어 있어 암호화 성능도 좋고, 모바일이나 임베디드 환경에서도 사용하기 좋다.

- 첨단 암호화 기법 사용: 안전하고 빠른 암호화 기법을 사용한다. WireGuard에서 내부적으로 사용하는 Noise protocol framework는 Zero round trip, forward secrecy 등을 지원하여 매우 빠른 연결 속도와 더 나은 통신의 보안을 지원한다. 또한, WireGuard에서 패킷 암호화에 사용하는 Curve25519, ChaCha20 Poly1305 등의 암호화 기법들은 다른 암호화 기법들과 비교하여 훨씬 안전하고 빠른 암호화를 지원한다.

- 쉬운 Peer 배포: WireGuard에서 Peer끼리 정보를 주고 받을 때 공개키 암호화를 사용한다. 이는 바꿔말하면, 공개키로 자신의 신원을 증명할 수 있다는 말이다. 따라서 WireGuard 통신을 세팅할 때에는 공개키만 서로 알고 있다면 가능하기 때문에, 우리가 자주 쓰는 SSH Key의 deploy 만큼이나 Peer 배포가 간단하다.

- 안정적인 연결: WireGuard는 UDP만을 사용하고, 공개키를 기반으로 연결이 정의되면서 내부적으로 상태를 가지지 않는(Stateless) 특성 덕분에 통신을 끊김없이 관리할 수 있다. 데몬 등으로 연결을 관리해주어야할 필요가 없어지기 때문에 연결 관리 코스트에서도 자유롭다.

- 리눅스 내장: WireGuard는 리눅스 커널 5.6 버전부터 기본으로 포함되어 있어 그 버전 이상의 커널을 사용하면 따로 설치가 필요 없는데다가, 유저 공간의 어플리케이션이 아닌 커널 모듈로서 작동하기 때문에, 서버 어플리케이션이 비정상 종료 되어도 운영체제가 돌아가고 있는 한 WireGuard의 기능들은 모두 정상적으로 동작하여 안정적이기까지 하다.

## Firezone:

Firezone은 WireGuard 프로토콜을 기반으로 한 오픈소스 VPN 서버 및 방화벽 관리 도구이다. enterprise level으로 사용하기 위한 접근관리 기능을 함께 제공한다. 

**특징**
- 웹 기반 관리 인터페이스 제공
- 사용자 및 디바이스 관리 기능
- SAML, OIDC 등을 통한 SSO(Single Sign-On) 지원
- 상세한 로깅 및 모니터링 기능

---
참고 
- https://tech.devsisters.com/posts/wireguard-vpn-1/
- https://slowbootkernelhacks.blogspot.com/2020/09/wireguard-vpn.html
