- ELF는 Executable and Linking Format의 약어로, UNIX / LINUX 기반에서 사용되는 실행 및 링킹 파일 포맷이다. 
- 사용하는 운영체제는 유닉스, BSD, 솔라리스, 리눅스가 있다. (같은 바이너리 포멧이어도 각 운영체제간에는 호환이 되지 않는다.)
- ELF 파일은 아래와 같은 구조를 가지고 있다.

    |구조|
    |-|
    |ELF Header|
    |Program header table|
    |.text|
    |.rodata|
    |.data|
    |Section header table|


### ELF header

- ELF 헤더는 파일의 시작 부분에 있고, 파일에 대한 메타데이터를 가지고 있다.
- ELF 헤더에는 프로세서 아키텍처에 대한 정보가 포함되어있어 (32bit or 64bit, little-endian or big-endian 등) 다양한 프로세서 아키텍처가 ELF 파일을 해석할 수 있도록 도와준다.

- `/usr/include/elf.h`의 `Elf64_Ehdr` 정의
  
    ```c
    typedef struct {
      unsigned char	e_ident[EI_NIDENT];  /* Magic number and other info */
      Elf64_Half	e_type;         /* Object file type */
      Elf64_Half	e_machine;      /* Architecture */
      Elf64_Word	e_version;      /* Object file version */
      Elf64_Addr	e_entry;        /* Entry point virtual address */
      Elf64_Off	  e_phoff;        /* Program header table file offset */
      Elf64_Off	  e_shoff;        /* Section header table file offset */
      Elf64_Word	e_flags;        /* Processor-specific flags */
      Elf64_Half	e_ehsize;       /* ELF header size in bytes */
      Elf64_Half	e_phentsize;    /* Program header table entry size */
      Elf64_Half	e_phnum;        /* Program header table entry count */
      Elf64_Half	e_shentsize;    /* Section header table entry size */
      Elf64_Half	e_shnum;        /* Section header table entry count */
      Elf64_Half	e_shstrndx;     /* Section header string table index */
    } Elf64_Ehdr;
    ```

- `readelf` 명령어를 사용해 특정 프로그램의 ELF 헤더를 확인할 수 있다.

```bash
$ readelf -h /bin/ls 
ELF Header:
  Magic:   7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00 
  Class:                             ELF64
  Data:                              2's complement, little endian
  Version:                           1 (current)
  OS/ABI:                            UNIX - System V
  ABI Version:                       0
  Type:                              DYN (Position-Independent Executable file)
  Machine:                           Advanced Micro Devices X86-64
  Version:                           0x1
  Entry point address:               0x6180
  Start of program headers:          64 (bytes into file)
  Start of section headers:          145256 (bytes into file)
  Flags:                             0x0
  Size of this header:               64 (bytes)
  Size of program headers:           56 (bytes)
  Number of program headers:         11
  Size of section headers:           64 (bytes)
  Number of section headers:         30
  Section header string table index: 29
```

### Section Headers

- ELF 바이너리의 코드와 데이터는 섹션(section)으로 나누어져 있다.
- 섹션의 구조는 각 섹션의 내용이 구성된 방식에 따라 다른데, 각 섹션 헤더(section header)에서 그 속성을 찾을 수 있다. 바이너리 내부의 모든 섹션에 대한 헤더 정보는 섹션 헤더 테이블(section header table)에서 찾을 수 있다.
- 섹션은 링커가 바이너리를 해석할 때 편리한 단위로 나눈 것이다.
- 링킹이 수행되지 않은 경우에는 섹션 헤더 테이블이 필요하지 않다. 만약 섹션 헤더 테이블 정보가 없다면 `e_shoff` 필드는 0이다.
- 바이너리를 실행할 때 바이너리 내부의 코드와 데이터를 세그먼트(segment)라는 논리적인 영역으로 구분한다.
- 세그먼트는 링크 시 사용되는 섹션과는 달리 실행 시점에 사용된다.

- `/usr/include/elf.h`의 `Elf64_Shdr` 구조체 정의

    ```c
    typedef struct {
      Elf64_Word	sh_name;        /* Section name (string tbl index) */
      Elf64_Word	sh_type;        /* Section type */
      Elf64_Xword	sh_flags;       /* Section flags */
      Elf64_Addr	sh_addr;        /* Section virtual addr at execution */
      Elf64_Off	sh_offset;        /* Section file offset */
      Elf64_Xword	sh_size;        /* Section size in bytes */
      Elf64_Word	sh_link;        /* Link to another section */
      Elf64_Word	sh_info;        /* Additional section information */
      Elf64_Xword	sh_addralign;   /* Section alignment */
      Elf64_Xword	sh_entsize;     /* Entry size if section holds table */
    } Elf64_Shdr;
    ```

- `sh_name`: 이름이 저장되어 있는 문자열 테이블상의 인덱스를 의미한다. 인덱스는 ELF 헤더의 e_shstrndx 필드에 대응되는 문자열 테이블을 따른다. 섹션의 이름이 없으면 0이다.
- `sh_type`: 섹션을 구분하는 enum 
  - `SHT_PROGBITS`: <br/>
  기계어 명령이나 상수값 등의 데이터를 포함하고 있다. 이런 섹션은 링커가 분석해야 할 별도의 구조를 가지고 있지 않다.
  - `SHT_SYMTAB`, `SHT_DYNSYM`, `SHT_STRTAB`: <br/>
    심볼 테이블을 위한 섹션 타입(정적 심볼 테이블을 위한 `SHT_SYMTAB`, 동적 링킹 시에 필요한 심볼 테이블을 위한 `SHT_DYNSYM`)도 있고, 문자열 테이블(`SHT_STRTAB`)도 있다. <br/>
    심볼 테이블에는 파일 오프셋 또는 주소에 위치한 심볼의 명칭과 타입 정보를 명시해 둔 잘 정의된 형식의 심볼 정보가 포함된다. (struct Elf64_Sym 참고)
  - `SHT_REL`, `SHT_RELA`:  <br/>
    이 타입의 섹션은 링커가 다른 섹션들 간의 필수적인 재배치 관계를 파악할 수 있도록 하고자 잘 정의된 형식(struct Elf64_Rel과 struct Elf64_Sym 참고)에 맞춰 재배치 엔트리 정보를 제공한다. <br/>
    각각의 재배치 엔트리 정보는 재배치가 필요한 부분의 주소와, 재배치 시 해결해야 하는 심볼 정보를 포함한다. 이 두 타입의 섹션은 정적 링킹을 위한 목적으로 사용된다.
  - `SHT_DYNAMIC`:  <br/>이 타입의 섹션은 동적 링킹에 필요한 정보를 담고 있다. (struct Elf64_Dyn 참고)

- `sh_flags`: 섹션과 관련된 추가 정보를 제공한다.
  - `SHF_WRITE`: <br/>실행 시점에 해당 섹션이 쓰기 가능한 상태임을 나타낸다. 이 정보를 통해 정적 데이터(상수값 등)에 해당하는 섹션과 변수 값을 저장하는 섹션을 구분할 수 있다.
  - `SHF_ALLOC`: <br/>바이너리가 실행될 때 해당 섹션의 정보가 가상 메모리에 적재된다는 의미다. (실제로는 섹션이 아닌 세그먼트 단위로 처리)
  - `SHF_EXECINSTR`:  <br/>실행 가능한 명령어들을 담고 있는 섹션임을 의미한다.

- `sh_addr`, `sh_offset`, `sh_size`: `sh_addr`는 가상 메모리의 주소, `sh_offset`은 파일 오프셋, `sh_size`는 섹션의 크기를 나타낸다.
- `sh_link`: 관련된 섹션 헤더 테이블상 섹션들의 인덱스 정보들을 표기한다.
- `sh_info`: 섹션의 추가적인 정보를 제공한다.
- `sh_addralign`: 배치 관련 규칙들이 명시된다.
- `sh_entsize`: 심볼 테이블이나 재배치 테이블과 같은 일부 섹션들은 잘 설계된 자료 구조(Elf64_Sym 또는 Elf64_Rela) 형태로 테이블을 갖는다. 이런 섹션들에는 해당 테이블의 각 엔트리의 크기가 몇 바이트인지를 명시하는 `sh_entsize` 필드가 존재한다. 사용하지 않는다면 0이다.

### Sections

GNU/Linux 시스템의 ELF 파일들은 대부분 표준적인 섹션 구성으로 이루어져 있다.

```bash
$ readelf --sections --wide a.out

There are 29 section headers, starting at offset 0x1168:

Section Headers:
  [Nr] Name           Type      Address          Off    Size   ES Flg Lk Inf Al
  [ 0]                NULL      0000000000000000 000000 000000 00      0   0  0
  [ 1] .interp        PROGBITS  0000000000400238 000238 00001c 00   A  0   0  1
  [ 2] .note.ABI-tag  NOTE      0000000000400254 000254 000020 00   A  0   0  4
  [ 3] .note.gnu.build-id NOTE     0000000000400274 000274 000024 00   A  0   0  4
  [ 4] .gnu.hash      GNU_HASH  0000000000400298 000298 00001c 00   A  5   0  8
  [ 5] .dynsym        DYNSYM    00000000004002b8 0002b8 000060 18   A  6   1  8
  [ 6] .dynstr        STRTAB    0000000000400318 000318 00003d 00   A  0   0  1
  [ 7] .gnu.version   VERSYM    0000000000400356 000356 000008 02   A  5   0  2
  [ 8] .gnu.version_r VERNEED   0000000000400360 000360 000020 00   A  6   1  8
  [ 9] .rela.dyn      RELA      0000000000400380 000380 000018 18   A  5   0  8
  [10] .rela.plt      RELA      0000000000400398 000398 000030 18  AI  5  24  8
  [11] .init          PROGBITS  00000000004003c8 0003c8 00001a 00  AX  0   0  4
  [12] .plt           PROGBITS  00000000004003f0 0003f0 000030 10  AX  0   0 16
  [13] .plt.got       PROGBITS  0000000000400420 000420 000008 00  AX  0   0  8
  [14] .text          PROGBITS  0000000000400430 000430 000192 00  AX  0   0 16
  [15] .fini          PROGBITS  00000000004005c4 0005c4 000009 00  AX  0   0  4
  [16] .rodata        PROGBITS  00000000004005d0 0005d0 000012 00   A  0   0  4
  [17] .eh_frame_hdr  PROGBITS  00000000004005e4 0005e4 000034 00   A  0   0  4
  [18] .eh_frame      PROGBITS  0000000000400618 000618 0000f4 00   A  0   0  8
  [19] .init_array    INIT_ARRAY0000000000600e10 000e10 000008 00  WA  0   0  8
  [20] .fini_array    FINI_ARRAY0000000000600e18 000e18 000008 00  WA  0   0  8
  [21] .jcr           PROGBITS  0000000000600e20 000e20 000008 00  WA  0   0  8
  [22] .dynamic       DYNAMIC   0000000000600e28 000e28 0001d0 10  WA  6   0  8
  [23] .got           PROGBITS  0000000000600ff8 000ff8 000008 08  WA  0   0  8
  [24] .got.plt       PROGBITS  0000000000601000 001000 000028 08  WA  0   0  8
  [25] .data          PROGBITS  0000000000601028 001028 000010 00  WA  0   0  8
  [26] .bss           NOBITS    0000000000601038 001038 000008 00  WA  0   0  1
  [27] .comment       PROGBITS  0000000000000000 001038 000034 01  MS  0   0  1
  [28] .shstrtab      STRTAB    0000000000000000 00106c 0000fc 00      0   0  1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), l (large)
  I (info), L (link order), G (group), T (TLS), E (exclude), x (unknown)
  O (extra OS processing required) o (OS specific), p (processor specific)
```

- `.init` 섹션에는 초기화에 필요한 실행 코드가 포함된다. 운영체제의 제어권이 바이너리의 메인 엔트리로 넘어가면 이 섹션의 코드부터 실행된다.
- `.fini` 섹션은 메인 프로그램이 완료된 후에 실행된다. `.init`과 반대로 소멸자 역할을 한다.
- `.init_array` 섹션은 일종의 생성자로 사용할 함수에 대한 포인터 배열이 포함된다. 각 함수는 메인 함수가 호출되기 전에 초기화되며 차례로 호출된다. `.init_array`는 데이터 섹션으로 사용자 정의 생성자에 대한 포인터를 포함해 원하는 만큼 함수 포인터를 포함할 수 있다.
- `.fini_array` 섹션은 소멸자에 대한 포인터 배열이 포함된다. `.init_array`와 유사하다. 이전 버전의 gcc로 생성한 바이너리는 .ctors와 .dtors라고 부른다.
- `.text` 섹션에는 메인 함수 코드가 존재한다. 사용자 정의 코드를 포함하기 때문에 `SHT_PROGBITS`라는 타입으로 설정되어 있다. 또한 실행 가능하지만 쓰기는 불가능해 섹션 플래그는 AX다. `_start`, `register_tm_clones`, `frame_dummy`와 같은 여러 표준 함수가 포함된다.
- `.rodata` 섹션에는 상숫값과 같은 읽기 전용 데이터가 저장된다.
- `.data` 섹션은 초기화된 변수의 기본값이 저장된다. 이 값은 변경되어야 하므로 쓰기 가능한 영역이다.
- `.bss` 섹션은 초기화되지 않은 변수들을 위해 예약된 공간이다. BSS는 심벌에 의해 시작되는 블록 영역(Block Strarted by Symbol)이라는 의미로, (심벌) 변수들이 저장될 메모리 블록으로 사용한다.
- `.rel.*`와 `.rela.*` 형식의 섹션들은 재배치 과정에서 링커가 활용할 정보를 담고 있다. 모두 SHT_RELA 타입이며 재배치 항목들을 기재한 테이블이다. 테이블의 각 항목은 재배치가 적용돼야 하는 주소와 해당 주소에 연결해야 하는 정보를 저장한다. 동적 링킹 단계에서 수행할 동적 재배치만 남아 있다. 다음은 동적 링킹의 가장 일반적인 두 타입이다.
  - **GLOB_DAT**(global data): 이 재배치는 재배치는 데이터 심벌의 주소를 계산하고 .got의 오프셋에 연결하는 데 사용된다. 오프셋이 .got 섹션의 시작 주소를 나타낸다.
  - **JUMP_SLO**(jump slots): .got.plt 섹션에 오프셋이 있으며 라이브러리 함수의 주소가 연결될 수있는 슬롯을 나타냅니다. 엔트리는 점프 슬롯(jump slot)이라고 부른다. 이 엔트리의 오프셋은 해당 함수에서 간접 점프하는 점프 슬롯의 주소다. (rip로부터의 상대 주소로 계산)

- `.dynamic` 섹션은 바이너리가 로드될 때 운영체제와 동적 링커에게 일종의 road map을 제시하는 역할을 한다. 일명 태그(tag)라고 하는 Elf64_dyn 구조의 테이블을 포함한다. 태그는 번호로 구분한다.
  - `DT_NEEDED` 태그는 바이너리와 의존성 관계를 가진 정보를 동적 링커에게 알려준다.
  - `DT_VERNEED`와 `DT_VERNEEDNUM` 태그는 버전 의존성 테이블(version dependency table)의 시작 주소와 엔트리 수를 지정한다.
  - 동적 링커의 수행에 필요한 중요한 정보들을 가리키는 역할을 하기도 한다. 예를 들어 동적 문자열 테이블(`DT_STRTAB`), 동적 심벌 테이블(`DT_SYMTAB`), `.got.plt` 섹션(`DT_PLTGOT`), 동적 재배치 섹션(`DT_RELA`) 등.

- `.shstrtab` 섹션은 섹션의 이름을 포함하는 문자열 배열이다. 각 이름들을 숫자로 인덱스가 매겨져 있다.
- `.symtab` 섹션에는 Elf64_Sym 구조체의 테이블인 심벌 테이블이 포함되어 있다. 각 심벌 테이블은 심벌명을 함수나 변수와 같이 코드나 데이터와 연관시킨다.
- `.strtab` 섹션에는 심벌 이름을 포함한 실제 문자열들이 위치한다. 이 문자열들은 Elf64_Sym 테이블과 연결된다. 스트립 된 바이너리에는 `.symtab`과 `.strtab` 테이블은 전부 삭제된다.
- `.dynsym` 섹션과 `.dynstr` 섹션은 동적 링킹에 필요한 심벌과 문자열 정보를 담고 있다는 점을 제외하면 `.symtab`이나 `.strtab`와 유사하다.
정적 심벌 테이블은 섹션 타입이 `SHT_SYMTAB`이고 동적 심벌 테이블은 `SHT_DYNSYM` 타입이다.

---
참고
- https://en.wikipedia.org/wiki/Executable_and_Linkable_Format
- http://man7.org/linux/man-pages/man5/elf.5.html
- http://egloos.zum.com/recipes/v/5010841
- http://www.yolinux.com/TUTORIALS/LibraryArchives-StaticAndDynamic.html
- https://www.baeldung.com/linux/executable-and-linkable-format-file#:~:text=ELF%20is%20short%20for%20Executable,executed%20on%20various%20processor%20types.
- https://rond-o.tistory.com/303