# LVM

LVM이란 Logical Volume을 효율적이고 유연하게 관리하기 위한 커널의 한 부분이자 프로그램이다. 기존방식이 파일시스템을 블록 장치에 직접 접근해서 R/W를 했다면, LVM은 파일시스템이 LVM이 만든 가상의 블록 장치에 R/W를 하게 된다.

이처럼 LVM은 물리적 스토리지 이상의 추상적 레이어를 생성해서 논리적 스토리지(가상의 블록 장치)를 생성할 수 있게 한다. 직접 물리 스토리지를 사용하는 것보다 다양한 측면에서 뮤연성을 제공하기 위해, 유연한 용량 조절, 크기 조정이 가능한 스토리지 풀(Pool), 편의에 따른 장치 이름 지정, 디스크 스트라이핑, 미러 볼륨 등 기능을 가지고 있다.

LVM의 주요 용어를 알아보자.

## PV(Physical Volume)

LVM에서 블록 장치(블록 단위로 접근하는 스토리지. 하드 디스크 등)를 사용하려면 우선 PV로 초기화를 해야한다. 즉, 블록 장치 전체 또는 그 블록 장치를 이루고 있는 파티션들을 **LVM에서 사용할 수 있게 변환**하는 것이다.

예를 들어, `/dev/sda1`, `/dev/sda2` 등의 블록 스토리지를 LVM으로 쓰기위해서 PV로 초기화하게 된다. PV는 일정한 크기의 PE(Physical Extent)들로 구성된다.

## PE(Physical Extent)

PV를 구성하는 일정한 크기의 블록으로, LVM2에서의 기본크기는 `4MB`이다. LVM은 LVM1과 LVM2이 있는데, 여러 차이가 있지만 간단히 보면 LVM2가 기능이 개선된 버전이라고 이해할 수 있다.

PE는 LV(Logical Volume)의 LE(Logical Extent)들과 1:1로 대응된다. 그렇기에 항상 PE와 LE의 크기는 동일하다.

아래의 사진은 블록 장치(물리적 디스크)의 파티션들을 PV들로 초기화 시킨 모습이다. 각각의 PV들은 동일한 크기의 PE들로 구성된다.

<img width="650" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/139d36e1-4f74-4dec-a776-0665253d648e">

## VG(Volume Group)

PV들의 집합으로 LV를 할당할 수 있는 공간이다. 즉, PV들로 초기화된 장치들은 VG로 통합되게 된다.

사용자는 VG안에서 원하는대로 공간을 쪼개서 LV로 만들 수 있다. 아래 사진은 위에서 만든 PV들을 하나의 VG1로 그룹지은 모습이다.

## LV(Logical Volume)

사용자가 최종적으로 다루게 되는 논리적인 스토리지이다. 생성된 LV는 파일 시스템 및 애플리케이션(Database 등)으로 사용된다. 위에서도 언급했듯이, LV를 구성하는 LE들은 PV의 PE들과 mapping된다.

LE와 PE가 mapping되면서 총 3가지 유형의 LV가 생성된다.

- **Linear LV**
    하나의 LV로 PV를 모으는 방법이다. 예를 들어 2개의 60GB 디스크(PV)를 가지고 120GB의 LV를 만드는 방식이다. LV만을 사용하는 사용자 입장에서는 120GB의 단일 장치만 있는 것 처럼 사용하게 된다.
    <img width="624" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/25f14186-50ef-453c-9440-8c3b8b11de47">

- **Striped LV**
    LV에 데이터를 기록하게 되면 파일 시스템은 PE와 LE의 매핑대로 PV에 데이터를 기록하게 되는데, 스트라이프된 LV를 생성해서 데이터가 PV에 기록되는 방식을 바꿀 수 있다. 대량의 순차적 R/W 작업에서 효율을 올릴 수 있는 방법이다.
    Striped LV는 Round-Robin 방식으로 미리 지정된 PV에 데이터를 분산기록하여 성능을 높이고, R/W를 병렬로 실행할 수 있도록 한다. 번갈아가는 기준은 데이터의 크기인데 이를 **스트라이프 크기**라고 하며 Extent의 크기(PE/LE 크기)를 초과할 수 없다.
    ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/58b4a62c-7204-4ecb-a040-4f27f50225bb)

- Mirrored LV
    이름 그대로 블록 장치에 저장된 데이터의 복사본을 다른 블록 장치에 저장하는 방식이다. 데이터가 하나의 PV에 저장될때, 이를 미러하고있는 PV에 동일한 데이터가 저장된다.
    Mirrored LV를 사용하면 장치에 장애가 발생했을 때 데이터를 보호할 수 있다. 하나의 장치에 장애가 발생하게 되면, 선형(Linear)으로 저장되어있기에 다른 장치에서 쉽게 접근이 가능해지고, 어떤 부분이 미러를 써서 동기화되었는지에 대한 로그를 디스크에 저장한다.
    ![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/90dd07aa-43d5-4849-8168-21434b121085)

## LE(Logical Extent)

LV를 구성하는 일정한 크기의 블록으로 기본크기는 PE와 마찬가지로 4MB이다. 아래 그림은 위에서 만든 VG1에서 사용자가 원하는 크기대로 분할해서 LV1과 LV2를 만든 모습이다. 꼭 VG의 모든 공간을 다 써야하는 것은 아니다. 각각의 LV들은 동일한 크기의 LE로 구성되며 PE와 1:1로 매핑된다. 

<img width="667" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/85ca9a8a-c020-4e29-8e6e-614cb05f506f">

## 동작

Logical volume management는 디스크나 대용량 스토리지 장치를 유연하고 확장이 가능하게 다룰 수 있는 기술이며, 이를 커널에 구현한 기능을 바로 LVM(Logical Volume Manager) 라고 부른다. 

전통적으로 저장 장치를 사용했던 방식은 물리 디스크를 파티션이라는 단위로 나누어서 이를 OS에 마운트하여 사용했는데, 마운트를 하려면 파티션을 특정 디렉토리와 일치시켜 줘야 한다.

만약 특정 파티션(/home 이라 가정하자)에 마운트된 파티션이 용량이 일정 수준 이상 찼을 경우 다음과 같이 번거로운 작업을 수행해야 했다.
- 추가 디스크 장착
- 추가된 디스크에 파티션 생성 및 포맷
- 새로운 마운트 포인트(/home2) 를 만들고 추가한 파티션을 마운트
- 기존 home data를 home2 에 복사 또는 이동
- 기존 home 파티션을 언마운트(umount)
- home2 를 home 으로 마운트
  
LVM 은 이름처럼 파티션대신 볼륨이라는 단위로 저장 장치를 다룰 수 있으며, 물리 디스크를 볼륨 그룹으로 묶고 이것을 논리 볼륨으로 분할하여 관리한다. 스토리지의 확장이나 변경시 서비스의 변경을 할 수 있으며 특정 영역의 사용량이 많아져서 저장 공간이 부족할 경우에 유연하게 대응할 수 있다. 아래는 LVM의 구성 예시이다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/963abfbb-ae4c-4796-8385-13ebda7eebe6)

이제 /home 영역이 거의 찼을 경우 LVM이 적용되어 있으면 다음과 같이 처리할 수 있다.

- 추가 디스크 장착
- 추가된 디스크에 파티션을 만들어서 물리 볼륨(PV) 생성
- 물리 볼륨을 볼륨 그룹(VG)에 추가. (여기서는 vg_data 볼륨 그룹으로 추가한다.)
- /home 이 사용하는 논리 볼륨인 lv_home의 볼륨 사이즈를 증가
  
위와 같이 변경 작업을 기존 데이터의 삭제나 이동 없이 서비스가 구동중인 상태에서 유연하게 볼륨을 늘리고 줄일 수 있다.

---
참고
- https://en.wikipedia.org/wiki/Logical_Volume_Manager_(Linux)
- https://tech.cloud.nongshim.co.kr/2018/11/23/lvmlogical-volume-manager-1-%EA%B0%9C%EB%85%90/
