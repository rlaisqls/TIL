
- kernel을 컴파일 하면 KERNEL_ROOT 디렉토리에 vmlinux 파일이 생성된다.

- 해당 바이너리는 [ELF](ELF.md)(Excutable Linking Format) 형식이며, 디버깅과 관련된 정보 등과 같이 부가적인 정보들을 포함하고 있다. 

- vmlinux에서 objcopy 명령을 통해 Instruction set만 추출한 것이 바로 Image file이며 해당 파일은 크기가 크기 때문에 gzip을 통해서 압축을 진행한다. zlib, bzip2 등으로 압축한 vmlinux 파일을 vmlinuz, zImage, bzImage라고 부른다.

### 커널 이미지 생성 상세 과정

<img width="390" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/9e348350-a731-4d35-88cb-e25362a39cf0">

- 해당 vmlinux 파일에서 (1) 의 과정을 통해 `.comment`, `symbol table`, `relocation` 정보 등을 제거한 파일이 `arch/arm/boot/Image` 파일이다. 이 파일은 ELF 형식이 아니고 그냥 Data Binary File 이다. 쉽게 얘기하면 순수한 Kernel의 코드와 데이터만을 포함한 이미지이다.

- Image 파일을 (2)의 과정을 통해 gzip 으로 압축한 것이 `piggy.gzip` 파일이다.
따라서, `piggy.gzip` 파일은 단순히 Data Binary File 을 압축만 한 파일이라고 할 수 있다.

- 이러한 압축 파일을 통째로 `piggy.gzip.S` 에 포함하여 Assembling 하면 `piggy.gzip.o` 파일이 만들어진다.
이렇게 하는 이유는 본격적인 Kernel 의 시작(start_kernel)을 하기 전에 초기화 작업을 하고 압축을 해제하는 코드인 `head.o` 와 `misc.o` 를 묶어서 다시 Linking 하기 위한 것이다.

- `piggy.gzip.o`, `head.o`, `misc.o` 파일 3개를 Link 하여 새로이 만들어낸 파일이 a`rch/arm/boot/compressed/vmlinx` 파일이며 이 파일은 새로이 Linking 하여 만들어낸 파일이므로 역시 ELF 파일이 된다. 

- 마지막으로, Linking 과정에서 `.comment`, `symbol`, `relocation` 정보들이 또 들어가 있을 것이므로 `objcopy`를 통해 이를 다시 제거하면 최종 `zImage` 파일이 만들어진다. 이 파일을 통해 커널을 실행할 수 있다.

- Computer를 Booting 하면 Boot Loader는 필요한 하드웨어 초기화 작업을 수행한 후, 이 `zImage`를 특정한 메모리 영역에 로드하고 PC(Program Counter)를 해당 zImage 의 첫번째 명령어(Instruction)로 셋팅해 줌으로서 `zImage`가 시작되도록 한다.

- 그 첫 시작 지점은 위에서 실질적인 Kernel 이미지와 함께 Linking 되었던 `head.o `파일의 코드가 된다. `head.o`  에서는 Kernel 시작 전 적절한 초기화 작업을 수행한 후, `misc.o` 의 코드들을 호출하여 `piggy.gzip.o`, 즉 압축된 원래의 Kernel Image 의 압축을 해제하여 또 다른 특정 메모리 영역에 복제한 후, 최종적으로 PC 를 그 Kernel Image 의 첫 부분(start_kernel 함수)으로 분기하도록 해준다.

### vmlinux 파일 추출

- 추출을 도와주는 바이너리는 아래 경로에서 찾을 수 있다.
  
    ```bash
    /usr/src/linux-headers-$(uname -r)/scripts/extract-vmlinux
    ```

- 만약 존재하지 않는다면 설치가 필요하다.
  
    ```bash
    sudo apt-get install linux-headers-$(uname -r)
    ```

- 이를 이용하여 아래와 같이 vmlinux를 추출할 수 있다.

    ```bash
    /usr/src/linux-headers-$(uname -r)/scripts/extract-vmlinux /boot/vmlinuz-$(uname -r) > vmlinux
    ```

---
reference
- https://www.baeldung.com/linux/kernel-images
- http://cloudrain21.com/kernel-image-build-process
