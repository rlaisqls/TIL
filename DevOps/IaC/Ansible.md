## Ansible

## 구성 요소

- 제어 노드 - control node
  - Ansible을 실행하는 node
  - Ansible 제공 프로그램을 이용하여 매니지드 노드 관리
  - Ansible이 설치된 computer가 제어 노드가 된다
  - 제어 노드와 매니지드 노드 사이는 SSH를 통해 통신한다.

- 매니지드 노드 - managed node
  - Ansible로 관리하는 서버를 매니지드 노드 또는 호스트(host), 타겟(target) 이라 한다.
  - 매니지드 노드에는 Ansible이 설치되지 않는다.

- 인벤토리 - Inventory
  - 매니지드 노드 목록
  - 인벤토리 파일은 호스트 파일 이라고도 한다.
  - 인벤토리 파일은 각 매니지드 노드에 대한 IP Address, 호스트 정보, 변수 와 같은 정보를 저장

- 모듈 - module
  - Ansible이 실행하는 코드 단위
  - 미리 만들어진 동작 관련 코드 집합
  - 각 모듈은 데이터베이스 처리, 사용자 관리, 네트워크 장치 관리 등 다양한 용도로 사용
  - 단위 모듈을 호출하거나 playbook에서 여러 모듈을 호출 할 수 있다.

- 태스크 - Task
  - Ansible 작업 단위
  - Ad-hoc 명령을 사용하여 단일 작업을 한 번 실행할 수 있다.

- 플레이북 - Playbook
  - 순서가 지정된 태스크 목록
  - 지정된 작업을 해당 순서로 반복적으로 실행할 수 있다.
  - 플레이 북에는 변수와 작업이 포함 될 수 있다.
  - YAML로 작성

## Ansible 동작 과정

- Ansible은 인벤토리 파일 내용을 참조하여, 관리에 대한 매니지드 노드 파악
- Ansible을 통한 매니지드 노드 관리 방법
    - 모듈을 통한 매니지드 노드 관리
    - Ad-hoc 명령을 통한 매니지드 노드 관리
    - 태스크 단위로 매니지드 노드 관리
    - 플레이 북을 이용한 매니지드 노드 관리

### Ansible 환경 구축

- 실습 환경 구성
![image](https://github.com/rlaisqls/TIL/assets/81006587/8dc35032-a77b-4a0d-a364-fda18a7e42d0)

### Ansible 제어노드 구축
  - Ansible 제어 노드와 Managed node 연결
    - 제어 노드는 Managed Node와 연결 시 SSH를 통해서 연결한다.
    - 따라서 제어 노드의 SSH key를 Managed node에 전송해야 한다.
    - 하지만 AWS EC2 instance 환경에서는 keypair를 이용하여 연결하므로, Control node에는 Managed node의 keypair를 모두 가지고 있어야 한다.

  - Control Node 구성
    - Ansible 환경은 Control Node에 구성하고, Managed node에는 특별한 환경 구성이 없다.
    - Ansible 설치
      - Ansible은 Linux 환경에 설치 가능
      - `sudo amazon-linux-extras install ansible2`

  - Ansible 설치 확인
    - `ansible --version` - ansible 버전 확인

### Ansible 환경 설정 파일
  - `/etc/ansible/ansible.cfg` - Ansible 환경 설정 파일
    - Ansible이 동작할 때 마다 참조하는 파일
    - Ansible 호스트 키 검사 속성을 비활성화 설정
    - 처음 설치시에는 `ansible.cfg` 파일에 주석 처리 되어 있다.
      - host_key_checking = False
      - Control node에서 Managed node에 접속 시, 별도의 key 확인 과정 없이 명령 수행을 위하여 비활성화 속성을 정의함.
    - `/etc/ansible/hosts` - 인벤토리 파일

### Ansible 환경 설정 적용 순서
1. ANSIBLE_CONFIG 환경 변수에 지정된 파일
2. 현재 디렉토리에 있는 `ansible.cfg` 파일
3. 사용자 홈 디렉토리에 있는 `ansible.cfg` 파일
    - 지역설정(현재 사용자 - 리눅스 일반 사용자)
4. `/etc/ansible/ansible.cfg` 파일(글로벌 전역 파일)
    - 전역 설정(모든 사용자 - 리눅스 관리자/일반 사용자)

### Managed Node와 연결 확인
  - Control Node에서 Managed node와 연결을 하려면 Managed Node에 대한 정보를 알고 있어야 한다.
  - `/etc/ansible/hosts` 파일은 인벤토리 라고 하며, 이 파일에 Managed Node에 대한 정보를 기술한다.
  - `/etc/ansible/hosts` 파일은 전역으로 사용하는 인벤토리이며, 현재 사용자에 대한 인벤토리를 구성하려면 현재 사용자의 작업 디렉토리에 별도의 인벤토리를 작성하여 사용할 수 있다.

hosts 파일 변경 정보

```
[managed]
host1 ansible_host=10.0.1.5
ansible_connection=ssh
ansible_port=22
ansible_user=ec2-user
ansible_ssh_private_key_file=/home/ec2-user/work-ansible/Goorm-aicore0940-20220906.pem
```

### Ad-hoc 명령
- Ansible은 일반적으로 playbook을 사용하도록 설계되어있다. 하지만 한 번만 수행하거나, 간단한 명령을 통한 상태 확인 등은 별도의 playbook을 사용하지 않고 간단한 명령 구문으로 수행할 수 있는데, 이 방식을 Ad-hoc 명령이라고 한다.
 
- 형식
    - ansible <호스트명 패턴( Managed node )> [옵션]
        - `all` : 호스트명 패턴으로 사용하면 모든 managed node 대상으로 Ad-hoc 명령 실행
        - `-m` : 모듈명
        - `-a <인수목록>` : 모듈 인수
        - `-i <인벤토리 파일명>` : 인벤토리 (별도의 인벤토리를 지정하지 않으면 /etc/ansible/hosts 파일을 사용한다.)
        - `--become` : 관리자 권한으로 실행
        - `-k` : ansible 실행 시 암호 확인
        - `-K` : ansible 실행 시 root 권한으로 실행
- 예시
    - `ansible all -m ping -i ./hosts` -> 호스트 패턴 all 은 인벤토리의 모든 호스트에 대하여 Ad-hoc 명령 적용 시 사용하는 호스트 패턴
    - `ansible managed -m ping -i ./hosts` -> managed 호스트 패턴에 대하여 ping 모듈 적용, 인벤토리는 현재 디렉토리의 hosts 사용
      - ping 모듈 - Ansible Control Node와 Managed node 사이의 통신 연결 상태 확인

## Inventory 이해

- Control Node에서 Managed node에 연결하기 위한 정보를 가지고 있는 파일
- 기본 위치
    - `/etc/ansible/hosts`
- 기본 위치의 파일은 default로 적용되는 인벤토리이고, 관리자 권한으로만 수정 가능
- 사용자가 원하는 디렉토리에 복사한 후 편집하여 사용
    - `sudo cp /etc/ansible/hosts .`
    - `sudo chown <사용자ID>:<사용자그룹> <인벤토리 파일>`

- Ansible 설치 후 기본 인벤토리의 내용은 사용법에 대한 주석으로 구성되어 있다.

```bash
# This is the default ansible 'hosts' file.
#
# It should live in /etc/ansible/hosts
#
#   - Comments begin with the '#' character
#   - Blank lines are ignored
#   - Groups of hosts are delimited by [header] elements
#   - You can enter hostnames or ip addresses
#   - A hostname/ip can be a member of multiple groups
 
# Ex 1: Ungrouped hosts, specify before any group headers.
 
## green.example.com
## blue.example.com
## 192.168.100.1
## 192.168.100.10
 
# Ex 2: A collection of hosts belonging to the 'webservers' group
## [webservers]
## alpha.example.org
## beta.example.org
## 192.168.1.100
## 192.168.1.110
 
# If you have multiple hosts following a pattern you can specify
# them like this:
 
## www[001:006].example.com
 
# Ex 3: A collection of database servers in the 'dbservers' group
 
## [dbservers]
##
## db01.intranet.mydomain.net
## db02.intranet.mydomain.net
## 10.25.1.56
## 10.25.1.57
 
# Here's another example of host ranges, this time there are no
# leading 0s:
 
## db-[99:101]-node.example.com
```
- 인벤토리 내용
    - 그룹을 지정하지 않는 방식
        - <hostname( managed node )> [속성]
        - 10.0.1.97 ansible_connection=ssh ansible_port=22 ansible_user=ec2-user ansible_ssh_private_key_file=/home/ec2-user/work-ansible/gurum-aicore0942-20220906.pem
    - 그룹을 지정하는 방식
        - [그룹명]
        - <hostname( managed node )> [속성]
  
```bash
[managed]
host1 ansible_host=10.0.1.5 ansible_connection=ssh ansible_port=22 ansible_user=ec2-user ansible_ssh_private_key_file=/home/ec2-user/work-ansible/Goorm-aicore0940-20220906.pem
```

- 공통 정보를 변수에 저장하여 공유하는 방식
    - [그룹명:vars]

```bash
<hostname( managed node )> [속성]
[managed:vars]
ansible_connection=ssh     -> 연결 방법
ansible_port=22            -> 연결 port number
ansible_user=ec2-user      -> host( managed node ) user id
ansible_ssh_private_key_file=/home/ec2-user/work-ansible/gurum-aicore0942-20220906.pem               -> 개인키 파일 위치
ansible_python_interpreter=/usr/bin/python3                       -> host( managed node ) python 경고 메시지를 출력하지 않도록 파이썬 인터프리터 위치 지정
```

- 여러 그룹을 하나의 그룹으로 묶어서 변수를 공유하는 방법
  - ```bash
    [그룹명:children]
    <그룹명1>
    <그룹명2>
    ...
    [그룹명:vars]
    <hostname( managed node )> [속성]
  ```