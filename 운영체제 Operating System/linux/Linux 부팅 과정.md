# 리눅스 부팅 과정

## 1단계: 하드웨어 단계

### Power On

- 부팅 직후 CPU는 리셋 벡터를 통해 펌웨어(BIOS, EFI)로 접근하고, 이곳에서 펌웨어 코드(BIOS Code)를 실행한다.

- BIOS 프로그램은 전원공급과 함께 메모리의 특정번지(예:FFFF0H)에 자동 로드된다.

- CPU는 전원공급과 함께 특정번지(예:FFFF0H)의 BIOS프로그램(명령들)을 자동실행 한다.

- 초기부팅 직후 CPU가 처음으로 하게 될 일은 EIP(Extend Instruction Pointer-CPU가 할 일들, 즉 메모리에 등록되어 있는 Code의 주소를 가리키는 포인터)에 숨겨진 0xFFFFFFF0 주소로 점프하는 것이다. 이 주소는 펌웨어(BIOS, EFI)의 엔트리 포인트로 매핑되는 영역으로 리셋 벡터(Reset Vector)라고 한다. 이 영역은 전원을 켰을 때 항상 같은 자리에 있지만 real mode(초기 부팅 때 전체 메모리의 1MB 영역까지만 접근 가능하지 못함)에서는 접근할 수 없도록 숨겨져 있다. 

- 펌웨어는 시스템의 하드웨어 구성을 저장한다.

### POST, BOOT SECTOR(MBR/VBR/EBR)

- Power-on-self-test (POST): CPU, RAM, 제어장치, BIOS 코드 자체, 주변장치 등에 대한 검사 진행

- OS외 기존 가상화 확장, 보안 등에 대한 구성 확인

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/9fc938e1-f801-410a-9995-dd076d3afcd9)

- MBR(Master Boot Record)
    POST 과정이 완료되면, BIOS는 부팅 디바이스(하드디스크 등)를 검색하고, 해당 디바이스의 파티션 테이블을 검색한다. 파티션 되지 않은 장치의 시동 섹터는 VBR이 된다. 파티션 테이블을 찾은 경우, 해당 파티션의 첫 번째 블록(섹터 0) 512 bytes의 MBR(Master Boot Record-시동섹터)에서 부트로더 코드(Boot Loader Code=OS Loader)를 검색한다. 부트로더 코드를  찾으면 메모리에 로드시킨다.  

    - 파티션 테이블(Partition Table): 4개 Primary partition 정보(시작~끝 블록, 크기 등) (64bytes)
    - 부트 시그니처(Boot Signature): 부트로더 코드의 고유값(0x55AA) (2 bytes)

- VBR(Volume Boot Record)
  - 각 Primary partition의 첫 번째 블록(부트로더 코드와 부트시그니처를 포함할 수 있다)
  - 파티션되지 않은 장치의 시동 섹터는 VBR이다.

- EBR(Extended Boot Record)
  - 각 Logical partition(하나의 파티션을 sub-divide 한 파티션 단위)의 첫 번째 블록(파티션 테이블, VBR 부트시그니처 포함)
  - EBR의 파티션 테이블에는 모든 Logical partition이 링크되어 있다.

## 2단계: 부트로더 단계

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/9dc79b1d-bf10-4832-a60b-276461f55e13)

BIOS가 디스크의 MBR에서 부트 로더를 찾고, 이 부트 로더가 GRUB 설정 파일을 찾으면, 부트로더는 약 3~5초 동안의 시간을 카운트다운한다. 이 시간 동안(기본 운영체제가 시작하기 전까지) 사용자는 아무 키나 눌러 부트 로더에 개입할 수 있게 된다.

일반적으로 유저가 부트 메뉴에서 부트 로더에 개입해야 하는 이유는 다음과 같다.

- 다른 런레벨로 시작해야 할 때(런레벨 오버라이드)
- 다른 커널을 선택해야 할 때
    (ex. RHEL의 새 커널이 yum을 통해 설치되면 이전 커널이 하나씩 유지된다. 새 커널이 시작하지 않을 때를 대비하는 것이다)
- 다른 운영체제를 선택해야 할 때
    (ex. 페도라와 RHEL가 함께 설치된 컴퓨터에서 RHEL이 올바로 동작하지 않을 때 페도라로 시동한 뒤 RHEL 파일 시스템을 마운트하여 문제 해결을 시도할 수 있다)
- 부트 옵션을 변경해야 할 때
    (ex. 커널 옵션 추가, 특정 구성 요소 하드웨어 지원 비활성화-일시적으로 USB 포트 비활성화 등-)

### GRUB(GRand Unified Bootloader): Linux Loader

- GRUB은 커널(kernel)이미지를 불러들이고 시스템 제어권을 커널에게 넘겨준다.

- GRUB은 GRUB Stage1 > 1.5 > 2 의 세 단계를 거치는 부트로더로 현재는 GRUB2가 가장 보편적으로 사용된다. 
    - **GRUB Stage 1**
        MBR 또는 VBR에 저장되어 있는 부트 이미지가 메모리에 로드되고 실행됨(core.img의 첫 번쩨 섹터 로드)
    - **GRUB Stage 1.5**
        MBR과 첫번째 파티션 사이에 있는 블록(a.k.a MBR gap)에 저장된 core.img가 메모리에 로드되고 실행됨. core.img의 configuration 파일과 파일시스템을 위한 드라이버를 로드한다.
    - **GRUB Stage 2**
        `/boot/grub` 파일 시스템에 직접 접근하여 커널(vmlinuz)의 압축을 풀어 메모리에 로드하고, 커널이 필요로 하는 모든 드라이버와 모듈, 파일시스템(ext2, ext3, ext4...)등이 담긴 RAM 디스크 파일(initrd.img)를  메모리에 로드한다.

`*` 커널은 로드되기 이전 `/boot` 아래 압축된 파일 형태인 `vmlinux` 로 존재 > GRUB Stage 2에서 압축 풀고 로드

`*` 커널 컴파일(Kernel Compile)을 통해 GRUB을 통해 로드할 커널 버전을 고를 수 있음

`*` `grub>` 이라는 고유의 작은 셸을 사용할 수 있음(이 셸의 프롬프트를 통해 부팅 파라미터 및 부팅OS 등을 정의할 수 있음)

## 3단계: 커널 단계(Loading the Kernel)

부팅 2단계까지 지나며 현재 부트로더는 커널파일과 RAM디스크 파일을 메모리에 로드해놓은 상태이다.

커널은 컴퓨터의 각종 하드웨어를 사용하는 데 필요한 드라이버와 모듈을 로드한다. 이 시점에서는 주로 하드웨어 실패를 찾아야 한다. 관련된 기능이 올바로 동작하지 않는 문제를 차단해야 하기 때문이다.

**로드된 커널파일 실행**
- 로드된 커널파일 실행, 콘솔에 관련 정보 띄워줌
- PCI bus 점검 및 감지된 주변장치(Peripheral) 확인 후 `/var/log/dmesg` 파일에 기록
- 커널은 swapper 프로세스(PID 0)를 호출, swapper(PID 0)는 커널이 사용할 각 장치드라이브들을 초기화
- Root file system (`"/"`)을 읽기 전용으로 마운트, 이 과정에서 마운트 실패시 "커널 패닉" 메시지 출력
- 문제없이 커널이 실행되고 나면 언마운트 후 Root File System을 읽기+쓰기 모드로 리마운트
- 이후 Init 프로세스(PID 1)를 호출

커널이 시작하면서 생성한 메시지들이 복사되는 곳은 커널 링 버퍼(Kernel Ring Buffer)라고 한다. 이곳에 커널 메시지가 저장되며, 버퍼가 모두 채워지면 오래된 순서부터 메시지가 삭제된다. 부팅 후 시스템 로그인하여 커널 메시지를 파일로 캡처하는 커맨드를 통해 커널 메시지 기록을 파일 형태로 남길 수 있다.

커널 메시지는 구성 요소 즉, CPU나 메모리, 네트워크 카드, 하드 드라이브 등이 감지될 때 나타난다.

```bash
dmesg > /tmp/kernel_msg.txt
less /tmp/kernel_msg.txt

# systemd는 systemd 저널에 저장된다
# 따라서 journalctl을 실행해야 부트 시부터 지금까지 쌓인 메시지 확인 가능
```

## 4단계: INIT

init 시스템은 SysV 및 Systemd로 구분된다
 
### sysV

#### SysVinit 1. Configuration. the file /etc/inittab
- `/etc/inittab`의 초기 시스템 구성 파일을 읽어옴(Operation mode, 런레벨, 콘솔 등)

#### SysVinit 2. Initialization. the file /etc/init.d/rc
- `/etc/init.d/rc.S`(debian) 명령 실행
- (시스템 초기화-스왑영역 로드, 필요없는 파일 제거, 파일시스템 점검 및 마운트, 네트워크 활성화 등)

#### SysVinit  3. Services. /etc/init.d 및 /etc/rcN.d 디렉토리들
- 지정된 런레벨에 해당하는 스크립트 및 서비스 실행
- `/etc/init.d` 의 실행 가능한 서비스들 모두 실행(cron, ssh, lpd 등등)
- 각 런레벨별로 실행할 서비스들은 `/etc/rcN.d` 에서 정의할 수 있음 (S01: 런레벨 1에서 활성화, K01:런레벨 1에서 비활성화)

### systemd: BSD init

- systemd는 대표적인 Ubuntu Linux의 Init System이다.
- Sysvinit에 비해 시작속도가 빠르고, 리눅스 시스템을 보조하는 풀타임 프로세스로 상주한다
- Target 유닛을 사용하여 부팅, 서비스관리, 동기화 프로세스를 진행한다
- System Unit : Any resource that system can operate/manage (ex. .service, .target, .device, .mount, .swap...)

**Systemd Boot process**

- systemd용 GRUB2 구성(GRUB_CMDLINE_LINUX="init=/lib/systemd/systemd" (이후 update-grub 실행)
- 첫 번째 `.target` 유닛 실행 (보통 `graphical.target`의 심볼릭 링크임)

```bash
#첫 번째 .target 유닛
[Unit]

Description=yon boot target
Requires=multi-user.target
Wants=yonbar.service
After=multi-user.target rescue.service rescue.target
Requires = hard dependencies
Wants = soft dependencies (시작이 필요하지 않은)
After = 여기서 정의된 서비스들 실행 이후에 부팅할 것
```
- Requires = hard dependencies
- Wants = soft dependencies (시작이 필요하지 않은)
- After = 여기서 정의된 서비스들 실행 이후에 부팅할 것

## 정리

리눅스 시스템이 올바로 시동하려면 일련의 과정이 올바르게 수행되어야 한다.

PC 아키텍처에 직접 설치된 리눅스 시스템은 다음 과정을 거쳐 시동한다.

- 전원을 켬
- 하드웨어를 시작함(BIOS 또는 UEFI 펌웨어에서)
- 부트 로더 위치 찾기 + 시작하기
- 부트 로더에서 운영체제 고르기
- 선택된 운영체제에 맞는 커널과 초기 RAM 디스크(initrd) 시작하기
- 초기화 프로세스(init 또는 systemd) 시작
- 선택된 런레벨 또는 타깃에 따라 서비스 시작

--- 
참고
- https://itragdoll.tistory.com/3
- https://ocw.unican.es/
- https://manybutfinite.com/post/how-computers-boot-up/ 

