

## 기출유형 1회

<img style="height: 300px" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/0ce55d7c-8a8b-4099-bf5d-e54079978a95"/>

|네트워크(구간)|호스트(장치명)|IP 주소|
|-|-|-|
|204.200.7.0/24<br>(R1~ISP 구간)|R1 [se0/0/0]|204.200.7.1|
||ISP [se0/0/0]|204.200.7.2|
|204.200.10.0/24<br>(VLAN 10: skill)|R1 [Fa0/0.10]|해당 서브넷에서 호스트에 할당 가능한 임의의 IP 주소|
||PC0|204.200.10.2|
|204.200.20.0/24<br>(VLAN 20: comm)|R1 [Fa0/0.20]|해당 서브넷에서 호스트에 할당 가능한 임의의 IP 주소|
||PC1|204.200.20.2|
|204.200.30.0/24<br>(VLAN 30: office)|R1 [Fa0/0.30]|해당 서브넷에서 호스트에 할당 가능한 임의의 IP 주소|
||PC2|204.200.30.2|
|100.30.0.0/24|Server0|100.30.0.2|

|VLAM 이름 (ID)|Port|
|-|-|
|skill (VLAN10)|Fa0/1|
|comm (VLAN 20)|Fa0/2|
|office (VLAN 30)|Fa0/3|

### 설정

#### 스위치 설정

```bash
en
conf t

## vlan 생성
vlan 10
name skill
vlan 20
name comm
vlan 30
name office

## 결과 확인
do show vlan

## 인터페이스 정의
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

#### 라우터 설정

```bash
en
conf t

## Console 접속 암호 설정
line con 0
pass 'admin##'

## Telnet 접속 암호 설정
line vty 0 4
pass 'admin##'
exit

int fa0/0
no sh

## 인터페이스 IP 설정
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
no sh
```

#### ISP 설정

```bash
en
conf t

## Privilege Mode 접속 암호 설정
enable pass 'admin##'

## 인터페이스 IP 설정
in se0/0/0
ip add 204.200.7.2 255.255.255.0
cl ra 64000
no sh

int fa0/0
ip add 100.30.0.1 255.255.255.0
no sh
```

#### RIP 설정

**라우터**

```bash
router rip
v 2
ne 204.200.7.0
ne 204.200.10.0
ne 204.200.20.0
ne 204.200.30.0

## 확인
do show ip bri
```

**ISP**

```bash
router rip
v 2
ne 204.200.7.0
ne 100.30.0.0
no au
```

---

## 기출유형 2회

<img src="https://github.com/rlaisqls/TIL/assets/81006587/30eb3c3e-99ba-4e4d-a785-079a294b1d8a" style="height: 300px"/>

|네트워크(구간)|호스트(장치명)|IP 주소|
|-|-|-|
|100.100.100.0/24<br>(R1~ISP 구간)|R1 [se0/0/0]|100.100.100.2|
|182.16.0.0/16<br>(VLAN 10: sales)|R1 [Fa0/0.10]|해당 서브넷에서 호스트에 할당 가능한 임의의 IP 주소|
||sales_PC|182.16.0.1|
|182.30.0.0/16<br>(VLAN 20: manage)|R1 [Fa0/0.20]|해당 서브넷에서 호스트에 할당 가능한 임의의 IP 주소|
||manage_PC|182.30.0.1|
||S1|182.30.0.2|
|192.168.1.0/24|IDC_Server|192.168.1.10|

|VLAM 이름 (ID)|Port|
|-|-|
|sales (VLAN10)|Fa0/1|
|manage (VLAN 20)|Fa0/2|

### 설정

#### 스위치 설정

```bash
vl 10
na Sales
vl 20
na Manage

int f0/1
sw m a
no sh
sw a vl 10

int f0/2
sw m a
no sh
sw a vl 20

int f0/24
sw m t

int vl 20
ip add 182.30.0.2 255.255.0.0
no sh
ip de 182.30.255.254
```

#### 라우터 설정

```bash
int f0/0
no sh

int f0/0.10
no sh
en d 10
ip add 182.16.255.254 255.255.0.0

int f0/0.20
no sh
en d 20
ip add 182.30.255.254 255.255.0.0

int s0/0/0
ip add 100.100.100.2
cl ra 64000
no sh

cdp run
do sh cdp ne de
ip route 0.0.0.0 0.0.0.0 100.100.100.50 # cdp 결과
```

---

## 기출유형 3회

<img src="https://github.com/rlaisqls/TIL/assets/81006587/73ae4efd-bf84-4cf3-aa19-6d47f7973905" style="height: 300px"/>

|네트워크(구간)|호스트(장치명)|IP 주소|
|-|-|-|
|172.30.0.8/30<br>(R1~ISP 구간)|R1 [se0/0/0]|172.30.0.9|
|100.0.0.0/10<br>(VLAN 10: sales)|R1 [Fa0/0.10]|해당 서브넷에서 호스트에 할당 가능한 임의의 IP 주소|
||PC0|100.0.0.1|
||Switch|100.0.0.2|
|100.128.0.0/10<br>(VLAN 20: manage)|R1 [Fa0/0.20]|해당 서브넷에서 호스트에 할당 가능한 임의의 IP 주소|
||PC1|100.129.0.1|
|192.168.1.0/24|IDC_Server|192.168.1.10|

|VLAM 이름 (ID)|Port|
|-|-|
|sales (VLAN10)|Fa0/1|
|manage (VLAN 20)|Fa0/2|

### 설정

#### 스위치 설정

```bash
vl 10
na sales
vl 20
na manage

int f0/1
sw mo a
int vl 10

int f0/2
sw mo a
int vl 20

int f0/24
sw mo t
no sh

int vl 10
ip add 100.0.0.2 255.192.0.0
ip de 100.63.255.254
```

#### 라우터 설정

```bash
int fa0/0.10
no sh
en d 10
ip add 100.63.255.254 255.192.0.0

int fa0/0.20
no sh
en d 20
ip add 100.192.266.265 255.192.0.0

int s0/0/0
no sh
ip add 172.30.0.9 255.255.255.252
cl ra 64000

ip route 192.168.1.0 255.255.255.0 172.30.0.10 # 서버 네트워크 구간 -> ISP 시리얼 주소
```

> 라우터 사이 네트워크가 `172.30.0.8/30`이므로 할당 가능한 주소는 `172.30.0.9`와 `172.30.0.10` 두 개이다. 문제에서 `172.30.0.9`를 R1 시리얼 주소로 설정하였기 때문에 ISP 시리얼 주소는 `172.30.0.10`가 된다.

## 기출유형 4회

<img src="https://github.com/rlaisqls/TIL/assets/81006587/4c69a51a-a89e-4ee8-9bd4-8c3a4627d2c1" style="height: 300px"/>


|네트워크(구간)|호스트(장치명)|IP 주소|
|-|-|-|
|150.204.163.0/24<br/>(VLAN 50: admin)|R1 [Fa0/0.50]|해당 서브넷에서 호스트에 할당 가능한 첫 번쨰 IP 주소|
||PC0|150.203.163.2|
||S1|150.203.163.3|
|160.203.163.0/24<br/>(VLAN 60: sales)|R1 [Fa0/0.60]|해당 서브넷에서 호스트에 할당 가능한 첫 번쨰 IP 주소|
||PC1|160.203.163.2|
|170.203.163.0/24<br/>(VLAN 70: marketing)|R1 [Fa0/0.70]|해당 서브넷에서 호스트에 할당 가능한 첫 번쨰 IP 주소|
||PC2|170.203.163.2|
||S2|170.203.163.3|
|180.203.163.0/24<br/>(VLAN 80: business)|R1 [Fa0/0.80]|해당 서브넷에서 호스트에 할당 가능한 첫 번쨰 IP 주소|
||PC3|180.203.163.2|

|장치 이름|VLAN 이름 (ID)|Port|
|-|-|-|
|S1|admin (VLAN 50)|Fa0/1|
||sales (VLAN 60)|Fa0/2|
|S2|marketing (VLAN 70)|Fa0/1|
||business (VLAN 80)|Fa0/2|

### 설정

#### S1 설정

```bash
vl 50
na admin
vl 60
na sales

int fa0/1
sw mo a
sw a vl 50
no sh

int fa0/2
sw mo a
sw a vl 60
no sh

int vl 50
ip add 150.203.163.3 255.255.255.0
ip de 150.203.163.1
```

#### S2 설정

```bash
vl 70
na marketing
vl 80
na business

inf f0/1
sw m a
sw a vl 70
no sh

int f0/2
sw m a
sw a vl 80
no sh

int vl 70
ip add 170.203.163.3 255.255.255.0
ip de 170.203.163.1

inf f0/24
no sh
```

#### 라우터 설정

```bash
int f0/0
no sh

int f0/0.50
en d 50
ip add 150.203.163.1 255.255.255.0
no sh

int f0/0.60
en d 60
ip add 160.203.163.1 255.255.255.0
no sh

int f0/0.70
en d 70
ip add 170.203.163.1 255.255.255.0
no sh

int f0/0.80
en d 80
ip add 180.203.163.1 255.255.255.0
no sh
```

---

## 기출유형 5회

<img src="https://github.com/rlaisqls/TIL/assets/81006587/619d6fa0-9e03-4a8d-accd-e074f1cd19c8" style="height: 300px"/>


|네트워크(구간)|호스트(장치명)|IP 주소|
|-|-|-|
|R1<br/>192.168.0.0/24|R1 [Fa0/0]|해당 서브넷에서 호스트에 할당 가능한 첫 번쨰 IP 주소|
||SW0 [vlan 1]|192.168.0.253|
||PC0|192.168.0.1|
||PC1|192.168.0.2|
|10.0.0.4/30<br/>(라우터들의 시리얼 구간)|R1 [Se0/0/0]|10.0.0.6|
||R2 [Se0/0/0]|해당 서브넷에서 사용하지 않은 나머지 주소|
|172.30.0.0/24<br/>(VLAN 10: admin)|R2 [Fa0/0.10]|해당 호스트에 할당 가능한 마지막 IP 주소|
||PC2|172.30.0.1|
|172.31.0.0/24<br/>(VLAN 20: sales)|R2 [Fa0/0.20]|해당 호스트에 할당 가능한 마지막 IP 주소|
||PC3|172.31.0.1|

|VLAM 이름 (ID)|Port|
|-|-|
|admin (VLAN 10)|Fa0/1|
|sales (VLAN 20)|Fa0/2|

### 설정

#### S0 설정

```bash
int vl 1
ip add 192.168.0.253 255.255.255.0
no sh
ip de 192.168.0.254
```

#### S1 설정

```bash
vl 10
na admin

int f0/1
sw mo a
sw a vl 10

int f0/23
sw mo t
int f0/24
sw mo t
```

#### S2 설정

```bash
vl 20
na sales

int f0/3
sw mo a
sw a vl 20

int f0/24
sw mo t
```

#### R1 설정

```bash
int f0/0
ip add 192.168.0.254 255.255.255.0
no sh

int s0/0/0
ip add 10.0.0.6 255.255.255.252
no sh

route rip 
v 2
ne 192.168.0.0
ne 10.0.0.4
no au
pass f0/0
```

#### R2 설정

```bash
int f0/0
no sh

int f0/0.10
en d 10
ip add 172.30.0.254 255.255.255.0
no sh

inf f0/0.20
en d 20
ip add 192.31.0.254 255.255.255.0
no sh

int s0/0/0
ip add 10.0.0.5 255.255.255.252
cl ra 64000
no sh

route rip v 2
ne 172.30.0.0
ne 172.31.0.0
ne 10.0.0.4
no au
pass f0/0 # 라우팅 업데이트 정보가 전송되지 않도록
```

---

## 기출유형 6회

<img src="https://github.com/rlaisqls/TIL/assets/81006587/e6087ae8-5491-4412-85f4-db7b4cee3385" style="height: 300px"/>


|네트워크(구간)|호스트(장치명)|IP 주소|
|-|-|-|
|120.0.0.0/14<br/>server_net (vlan 10)<br/>서버 네트워크|R1 [Fa0/0.10]|해당 서브넷에서 호스트에 할당 가능한 마지막 IP 주소|
||Server|120.0.0.1(이미 할당되어 있음)|
|120.32.0.0/14<br/>manage_net (vlan 20)<br/>관리용 네트워크|R1 [Fa0/0.20]|해당 서브넷에서 호스트에 할당 가능한 마지막 IP 주소|
||PC0|DHCP 할당 (할당 못할 경우 해당 서브넷의 임의 값으로 설정)|
||S1|120.32.0.1|
|120.64.0.0/14<br/>student_net (vlan 10)<br/>학생용 네트워크|R1 [Fa0/0.10]|해당 서브넷에서 호스트에 할당 가능한 마지막 IP 주소|
||PC1|DHCP 할당 (할당 못할 경우 해당 서브넷의 임의 값으로 설정)|
||S2|120.64.0.1|
|120.192.0.0/14<br/>teacher_net (vlan 20)<br/>교사용 네트워크|R1 [Fa0/0.20]|해당 서브넷에서 호스트에 할당 가능한 마지막 IP 주소|
||PC2|DHCP 할당 (할당 못할 경우 해당 서브넷의 임의 값으로 설정)|


|장치 이름|VLAM 이름 (ID)|Port|
|-|-|-|
|S1|server_net (VLAN 10)|Fa0/1-0/10|
||manage_net (VLAN 20)|Fa0/11|
|S2|student_net (VLAN 10)|Fa0/1-0/10|
||teacher_net (VLAN 20)|Fa0/11-0/20|

### 설정

#### S1 설정

```bash
spanning-tree portfast default

vl 10
na Server_net
vl 20
na Manage_net

int ra f0/1-10
sw mo a
sw a vl 10

int f0/11
sw mo a
sw a vl 20

int f0/24
sw m t

int vl 20
ip add 120.32.0.1 255.252.0.0
no sh
ip de 120.35.255.254
```

#### S2 설정

```bash
vl 10
na Student_net
vl 20
na Teacher_net

int ra f0/1-10
sw m a
sw a vl 10

int ra f0/11-20
sw m a
sw a vl 20

int f0/24
sw m t

int vl 10
ip add 120.64.0.1 255.252.0.0
no sh
ip de 120.67.255.254
```

#### R1 설정

```bash
enable pass pass!!

ip host s1 120.32.0.1
ip host s2 120.64.0.1
ip host server 120.0.0.1

int f0/0
no sh

int f0/0.10
en d 10
ip add 120.3.255.254 255.252.0.0
no sh

int f0/0.20
en d 20
ip add 120.35.255.254 255.252.0.0
no sh
ip help 120.0.0.1
no sh

int f1/0
no sh

int f1/0.10
en d 10
ip add 120.67.255.254 255.252.0.0
no sh

int f1/0.20
en d 20
ip add 120.195.255.254 255.252.0.0
no sh
ip help 120.0.0.1
no sh
```

---

## 기출유형 7회


<img src="https://github.com/rlaisqls/TIL/assets/81006587/84433685-4823-46e4-bc92-229fb234821e" style="height: 300px"/>


|네트워크(구간)|호스트(장치명)|IP 주소|
|-|-|-|
|100.100.0.4/30<br/>(R1-ISP 구간)|R1 [Se0/0/0]|100.100.0.6|
||ISP[Se0/0/0]|해당 구간에서 사용하지 않은 나머지 주소|
|100.16.0.0/16<br/>Sales (vlan 20)|R1 [Fa0/0.20]|해당 서브넷에서 호스트에 할당 가능한 마지막 IP 주소|
||Sales PC|DHCP 할당 |
|100.30.0.0/14<br/>Manage (vlan 60)|R1 [Fa0/0.10]|해당 서브넷에서 호스트에 할당 가능한 마지막 IP 주소|
||Manage PC|DHCP 할당|
||S1|120.64.0.1|
|192.168.1.0/24|IDC_server|192.168.1.10 (이미 구성되어 있음)|

|VLAN 이름 (ID)|Port|
|-|-|
|Sales (VLAN 20)|Fa0/1|
|Manage (VLAN 60)|Fa0/2|

### 설정

#### S1 설정

```bash
vl 20
na Sales
vl 60
na Manage

int f0/1
sw mo a
sw a vl 20

int f0/2
sw mo a
sw a vl 60

int f0/24
sw mo tr
sw tr all vl 20,60

int vl 60
ip add dhcp
no sh
```

#### R1 설정

```bash
int f0/0
no sh
login local
enable pass router##

int f0/0.20
en d 20
ip add 100.16.255.254 255.255.0.0
ip help 192.168.1.10
no sh

int f0/0.60
en d 60
ip add 100.30.255.254 255.255.0.0
ip help 192.168.1.10
no sh

int s0/0/0
ip add 100.100.0.6 255.255.255.252
cl ra 64000
no sh

ip route 192.168.1.0 255.255.255.0 100.100.0.5
```

---

## 기출유형 8회


|네트워크(구간)|호스트(장치명)|IP 주소|
|-|-|-|
|120.0.0.0/14<br/>Server_net (VLAN 10)<br/>서버네트워크|Router [Fa0/0.10]|해당 서브넷에서 할당 가능한 마지막 IP 주소|
||Server|120.0.0.1 (이미 설정되어 있음)|
|120.32.0.0/14<br/>Manage_net(VLAN 20)<br/>관리용네트워크|Router [Fa0/0.20]|해당 서브넷에서 호스트에 할당 가능한 마지막 IP 주소|
||PC0|DHCP 할당|
||S1|120.32.0.1|
|120.64.0.0/14<br/>Student_net(VLAN 30)<br/>학생용네트워크|Router [Fa0/0.30]|해당 서브넷에서 호스트에 할당 가능한 마지막 IP 주소|
||PC1|DHCP 할당|
||S2|120.64.0.1|
|120.192.0.0/14<br/>Teacher_net(VLAN 30)<br/>교사용네트워크|Router [Fa0/0.40]|해당 서브넷에서 호스트에 할당 가능한 마지막 IP 주소|
||PC2|DHCP 할당|



|장치 이름|VLAN 이름 (ID)|Port|
|-|-|-|
|S1|Server_net (VLAN 10)|Fa0/1-10|
||Manage_net (VLAN 20)|Fa0/11-20|
|S2|Student_net (VLAN 30)|Fa0/1-10|
||Teacher_net (VLAN 40)|Fa0/11|

### 설정

#### S1 설정

```bash
# vlan, 인터페이스 설정
```

#### S2 설정

```bash
# vlan, 인터페이스 설정
```

#### R1 설정

```bash
enable pass admin##
li vty 0 4
pass admin##
login

# inter vlan 설정

ip dhcp ex # 게이트웨이, 브로드캐스트 IP 제외

ip dhcp pool Manage_net
ne 120.32.0.0 255.252.0.0
de 120.35.255.254
dns 120.0.0.1

ip dhcp pool Student_net
ne 120.64.0.0 255.252.0.0
de 120.64.255.254
dns 120.0.0.1

ip dhcp pool Teacher_net
ne 120.192.0.0 255.252.0.0
de 120.195.255.254
dns 120.0.0.1
```

---

#### Privilage 모드 암호 설정

```bash
enable pass [admin##]
```

#### 콘솔 접속 이름, 암호 설정

```bash
li con 0 # 콘솔 라인모드 지정
user [master] pass [pass!!]
login local # 콘솔 로컬 인증
```

#### 텔넷 비밀번호

```bash
li vty 0 4
pass [pass!!]
login
```

#### 콘솔 접속시 메세지

```bash
ban motd @[^$~R1~$^]@
```

#### Port Security

스위치에서 int 설정
```bash
sw port
sw port max 1 # 최대 1대
sw port vio sh # 1대 이상이면 연결 끊어짐
```

#### 장비이름 바꾸기

```bash
host R1        
```

#### ping 테스트에서 host 이름 지정

```bash
ip host R1        
```

#### 비밀번호 암호화

```bash
ser pass
```