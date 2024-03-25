
<img width="397" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/0ce55d7c-8a8b-4099-bf5d-e54079978a95">

|네트워크(구간)|호스트(장치명)|IP 주소|
|-|-|-|
|204.200.7.0/24<br>(R1~ISP 구간)|R1 [se0/0/0]|204.200.7.1|
||ISP [se0/0/0]|204.200.7.2|
|204.200.10.0/24<br>(VLAN 10: skill)|R1 [Fa0/0.10]|해당 서브넷에서 호스트에 할당 가능한 임의의 IP 주소|
||PC0|204.200.20.2|
|204.200.20.0/24<br>(VLAN 20: comm)|R1 [Fa0/0.20]|해당 서브넷에서 호스트에 할당 가능한 임의의 IP 주소|
||PC1|204.200.20.2|
|204.200.30.0/24<br>(VLAN 30: office)|R1 [Fa0/0.30]|해당 서브넷에서 호스트에 할당 가능한 임의의 IP 주소|
||PC2|204.200.30.2|
|100.30.0.0/24|Server0|100.30.0.2|

|VLAM 이름(ID)|Port|
|-|-|
|skill(VLAN10)|Fa0/1|
|comm(VLAN 20)|Fa0/2|
|office(VLAN 30)|Fa0/3|

## 설정

### 스위치 설정

```bash
en
conf t

# vlan 생성
vlan 10
name skill
vlan 20
name comm
vlan 30
name office

# 결과 확인
do show vlan

# 인터페이스 정의
int fa0/1
sw m a # access
sw a vlan 10

int fa0/2
sw m a
sw a vlan 20

int fa0/3
sw m a
sw a valn 30

int fa0/24
sw m t # truncate
```

### 라우터 설정

```bash
en
conf t

# Console 접속 암호 설정
line con 0
pass 'admin##'

# Telnet 접속 암호 설정
line vty 0 4
pass 'admin##'
exit

int fa0/0
no sh

# 인터페이스 IP 설정
int fa0/0.10
en d 10
ip add 204.200.10.1 255.255.255.0

int fa0/0.20
en d 20
ip add 204.200.20.1 255.255.255.0

int fa0/0.30
en d 30
ip add 204.200.30.1 255.255.255.0

int se0/0/0
ip add 204.200.7.1 255.255.255.0
clock rate 56000
no shutdown
```

### ISP 설정

```bash
en
conf t

# Privilege Mode 접속 암호 설정
enable pass 'admin##'

# 인터페이스 IP 설정
in se0/0/0
ip add 204.200.7.2 255.255.255.0
clock rate 64000
no shutdown

int fa0/0
ip add 100.30.0.1 255.255.255.0
no shutdown
```

## RIP 설정

### 라우터 

```bash
router rip
v 2
network 204.200.7.0
network 204.200.10.0
network 204.200.20.0
network 204.200.30.0

# 확인
do show ip bri
```

### ISP

```bash
router rip
v 2
network 204.200.7.0
net 100.30.0.0
```



