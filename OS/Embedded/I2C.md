- Inter-Integrated Circuit(I2C) 프로토콜은 IC 사이에 통신 링크를 제공하는 양방향 2 와이어 직렬 버스이다.
- IIC 혹은 TWI(The Two-Wire Serial Interface)라고도 불린다.
- Philips Semiconductors 에 의해 1980 년대 초기에 개발
- 초기에는 텔레비전에서 CPU를 주변 칩에 연결할 방법을 제공하기 위해 만들어졌다. 오늘날에는 오디오와 비디오 장비뿐만 아니라 많은 다른 응용 분야에서 사용하며, 사실상의 표준으로서 산업계에서 보편적으로 수용되고 있다.

- 하나의 마스터와, 다른 하나의 슬레이브로 구성 된다. 그리고 슬레이브는 127개까지 구성이 가능하다. 즉, 메인 ECU가 있으면, 그 외 여러가지 디바이스들이 묶여 통신이 가능하다.

- 주로 제어(control)용으로 쓰인다. 2라인만 사용하여 병렬로 많은 수의 칩을 컨트롤 할 수 있다.
  - 클럭 라인(SCL): 동기용 클럭 신호를 전송한다.
  - 데이터 라인(SDA): Address, Data, Acknowledge, Start & Stop 등 주 데이터를 전송한다.   
    
    <img src="https://github.com/rlaisqls/TIL/assets/81006587/9de0d096-6af3-410c-b05a-c3e61c963bd0" style="height: 400px"/>

- I2C 사용 시에 주의 해야 할 점은 '풀업 저항'이다. 이 저항을 다는 이유는 I2C 통신을 위해 SDA선과 SCL 선이 모두 기본으로 High 상태가 되어야 하기 때문이다. 풀업 저항은 이를 High 상태로 만들어 준다.

- 전송속도
  - Standard Mode : 100kbps
  - Fast Mode : 200kbps, 400kbps 가능
- 디바이스는 고유의 어드레스(7비트)를 가지며, 필요에 따라 Receiver와 Transmitter로 동작한다.

### I2C 하드웨어 구성

- SDA와 SCL은 각각 한 라인에 연결 되는데, 다음과 같은 부과회로가 필요하다.
  - Rs: 내부보호회로 (보통 100 Ω) 
  - Rp: Pull-Up저항 (보통 4.7 kΩ) 

    <img src="https://github.com/rlaisqls/TIL/assets/81006587/8f75b129-26ba-4978-8c93-94115ce40890" style="height: 200px"/>

### I2C 데이터 구성

- 8비트의 데이터와 이를 확인하는 Acknowledge가 조합된 블럭이 반복되는 구조이다.
- 시작과 끝을 알리는 START와 STOP가 존재한다.

    <img src="https://github.com/rlaisqls/TIL/assets/81006587/13d55bf7-21af-4ce8-b940-323519aa3013" style="height: 300px"/>

- 8-비트 데이터를 전송할 경우
  - 첫번째 데이터블럭은 칩내부의 Slave-ADDRESS로 사용
  - 두번째 데이터블럭은 Sub-ADDRESS의 데이터로 사용
  - 이를 이용하녀 칩내의 많은 수의 레지스터를 조정할 수 있다.

- 8-비트 데이터를 연속적으로 전송할 경우
  - 단순히 데이터를 연속해서 n번 사용
  - 첫번째 데이타는 (Sub-Address의 번지)의 데이터
  - 두번째 데이타는 (Sub-Address의 번지+1)의 데이터
  - 많은 양의 데이터를 빠른 시간에 전송할 수 있음

### I2C 비트의 구성

- START
  - I2C 라인을 사용하고자 할 때 사용된다.
  - 1-비트로 구성되어있고, 신호의 구성은 다음과 같다.
  - START = SCL가 HIGH일경우, SDA가 HIGH->LOW
- STOP
  - I2C 라인 사용이 끝났을 때 사용된다.
  - 1-비트로 구성되어있고, 신호의 구성은 다음과 같다.
  - STOP = SCL가 HIGH일경우, SDA가 LOW->HIGH

    <img src="https://github.com/rlaisqls/TIL/assets/81006587/09218b48-daa6-4f5a-a5c2-8980a4a8b514" style="height: 150px"/>

- First Byte : 7비트-어드레스+R/W
  - Slave Address
    - START BIT후 처음으로 나가는 신호는 칩을 호출하기 위한 데이터
    - 이 데이터는 칩 메이커들이 고유로 만듦
- R/W신호	
  - 칩에서 데이타를 읽을때는 "1", 쓸때는 "0"

- Acknowledge
  - 이 비트는 데이터를 받는 Slave칩이 데이터를 잘 받았는지 체크
  - DATA를 잘 받았으면 "0", 받지 못했으면 "1"
  - 이 데이터는 Slave칩쪽에서 동작을 취해줘야 함(응답) 
  
> 참고<br>
> - 휴지상태 
>   - I2C라인이 사용되지 않는 상태이며, 이때는 SCL,SDA 라인모드 High상태임.
> - 데이터의 변경
>   - 아래 그림과 같이 SCL이 LOW상태일 때 변화되어야 한다.

### 리눅스 어플리케이션에서 I2C 제어

아래 명령어로 현재 시스템에서 I2C 제어를 위한 device를 확인할 수 있다. 해당 I2C 디바이스를 프로그램에서 Open하여 I2C를 제어할 수 있다.

```bash
$ ls /dev/i2c*
    /dev/i2c-0  /dev/i2c-1  /dev/i2c-2
```

이 디바이스 파일을 열기 위한 함수는 저수준 파일 함수인 open 함수를 이용한다. 보통 Blocking I/O 형태로 열기 때문에 다음과 같은 형식으로 열고 닫는다.


```c
#define I2C_DEV_FILENAME “/dev/i2c-0”
int fd;
fd = open( I2C_DEV_FILENAME, O_RDWR );
if (fd >= 0) {
    // ...
    close(fd);
}
```

해당 디바이스 드라이버가 read/write 이외에 여러가지 파라미터를 세팅하는 경우에 Ioctl을 사용할 수도 있다. i2c read/write 제어는 `read()`/`write()` 함수를 사용하지 않고 ioctl을 이용한다.

- struct i2c_rdwr_ioctl_data 구조체는 전송할 데이터를 묶는 역할을 한다.
- struct i2c_msg는 실제로 전달해야 하는 데이터의 각 블록을 표현한다.

```c
struct i2c_rdwr_ioctl_data {
    struct i2c_msg  __user  *msgs; /* pointers to   i2c_msgs */
    __u32 nmsgs;   /* number of i2c_msgs */
};

```

```c
struct i2c_msg {
    __u16 addr; /* slave address   */
    __u16 flags;
    __u16 len;  /* msg length  */
    __u8 *buf;  /* pointer to msg data  */
};
```

Flags 값
- `I2C_M_TEN`: 주소가 10비트이다.
- `I2C_M_RD`: 이 값이 지정되면 읽기 명령을 I2C 버스상에서 수행한다. 
- `I2C_M_NOSTART`: START가 발생하면 안되는 패킷임을 표시한다. 가장 첫 번째 msg 블럭에는 사용할 수 없다. 
- `I2C_M_REV_DIR_ADDR`: R/W가 반전된 처리를 해야 한다. 
- `I2C_M_IGNORE_NAK`: NAK 응답 즉 ACK가 없더라도 에러 처리하지 않는다. 
- `I2C_M_NO_RD_ACK`: 읽기에 따른 ACK가 없더라도 에러 처리하지 않는다

---
참고
- https://mickael-k.tistory.com/184
- https://en.wikipedia.org/wiki/I%C2%B2C
- https://www.seminet.co.kr/channel_micro.html