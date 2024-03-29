
프로세스에 전달한 데이터를 저장한 파일을 직접 프로세스의 가상 주소 공간으로 매핑하는 것

> Memory mapping is primarily concerned with associating portions of a process's virtual address space with external storage (e.g., files or devices), enabling efficient data access. It's often used for I/O operations and doesn't directly deal with the translation of logical to physical addresses.

**관련 개념**

- **주소 바인딩**: CPU가 프로세스의 작업을 실행하기 위해서는 논리적 주소만으로는 실제 메모리의 주소를 알 수 없기 때문에, 논리 주소와 위에서 물리적 주소를 매핑해주는 "과정"
    - CPU가 주소를 참조할 때마다 해당 데이터가 물리적 메모리의 어느 위치에 존재하는지 확인하기위해
    주소 매핑 테이블을 이용해 주소 바인딩을 점검함
    - Address binding deals with the translation of logical addresses generated by a program into physical addresses in memory. It's essential for program execution and involves techniques like compile time, load time, or run time binding.
    - 컴파일 시간 바인딩 (컴파일시)
    - 적재시간 바인딩 (링커 -> 로더)
    - 실행시간 바인딩 (적재 후 실행시)

- **Dynamic Loading**
  - 모든 루틴(function)을 교체 가능한 형태로 디스크에 저장
  - 함수 호출시에만 가져오고 호출 전에는 적재 X
  - 사용되지 않는 루틴들은 메모리를 점유하지 않게 되니 메모리 효율이 좋아짐

- **Overlay**
  - 실행하려는 프로그램이 메모리보다 클 때 필요없는 영역에 중첩하여 사용 (그때 쓰는 것만 가져와서 씀)
  - 운영체제에 의해 이뤄지는게 아니라 프로그래머가 구현했던 방식
  - VMM(Virtual memory management)가 나온 뒤로 사용되지 않음

- **Swapping(프로세스 교체)**
  - 중기 스케줄러(suspend)에서 스케줄링을 위해 메모리에 올라온 프로세스의 수를 조정하는 방법
  - 자원 안쓰는 프로세스 메모리에서 내리기
  - **Swap In:** secondary memory (**Hard Drive**)에서 main memory (**RAM**)로 옮기기
  - **Swap Out:** main memory(**RAM**)에서 secondary memory(**hard drive**)로 옮기기
  - https://binaryterms.com/swapping-in-operating-system.html
  
## Contiguous Allocation

- 연속적인 메모리 공간을 프로세스에 할당하는 방식이다. 주소 변환으로 인한 CPU 오버헤드를 줄임으로써 프로세스 수행을 빠르게 만든다.
- 가장 쉬운 방법으로는 고정된 크기로 메모리를 나눠 프로세스에게 할당해주는 방식이 있고, 효율적인 메모리 분배를 위해 파티션을 프로세스 크기에 따라 나누는 방법이 있다.
- 내부 단편화(Internal Fragmentation)가 발생할 수 있다.

### Partition

- Contiguous Allocation에서 파티션으로 메모리를 관리하는 방식에는 두가지가 있다.

- **Fixed partition Multiprogramming**
    - 고정된 크기로 할당 (미리 분할되어 있다.)
    - 똑같은 크기 X, 하지만 한번 정해진 간격이 바뀌진 않음
    - 각 프로세스가 도착한다면 적당한 공간에 넣어주면 된다.
    - 각 프로세스는 하나의 분할(Partiotion)에 적재한다
    - 오버헤드 낮지만 Internal, External Fragmentation 둘 다 생김
    - 각 Partition 별로 Boundary register 있음 (서로 관여 X)

- **Variable partition Multiprogramming**
  - 요청시 동적으로 분할하여 할당
  - 종료되어도 파티션 유지
  - External Fragmentation만 있음
  - First fit (최초 적합), Best fit (최적 적합), Worst fit (최악 적합), Next fit (순차 최초 적합) 등의 최적화 방법이 있다

## Non-Contiguous Allocation

- 프로그램을 블록으로 나눠서 할당한다. (프로그램에 연속적인 메모리 공간을 할당하지 않고, 블록 단위로 쪼개서 할당)
- 필요한 블록만 가져와서 사용
- 나머지는 swap device에 존재

- **BMT**
    - 블록위치 정보를 저장하는 매핑 테이블
    - Residence bit: 블록 적재 여부
    - Real address: 블록의 실제 주소
- **BMT를 사용해 특정 메모리 주소 구하기**
    1. BMT의 block b 칸 찾기
    2. redidence bit 검사
        - 0인 경우: swap device에서 블록 가져와 테이블 갱신 후 real addr 확인
        - 1인 경우: real addr 확인
    3. 실제 주소 r(a+d) 계산 및 접근

크게 Non-Contiguous Allocation은 block의 크기를 정적(page)으로 정하냐, 동적으로 정하냐(segmentation)에 따라 나눈 두가지의 방법이 있고, 거기에 두 방법을 합친 Hybrid 방법이 있다.

### **Paging System**
  - page(p): 프로세스의 block
  - page frame(p’): 메모리의 분할 영역, 페이지와 크기 같음
    - ex) 프로그램 756, 페이지 150 → 페이지 총 6개
  - There is no external fragmentation in paging but internal fragmentation exists
  - simple and efficient
  - PMT을 사용해 page mapping 정보를 저장함
  - **Direct Mapping**
    - `b + p * entrysize`
    - **진행순서**
      1. PMT가 저장된 주소 b에 접근
      2. page p에 대한 entry 찾기
      3. 찾은 entry의 존재비트 검사, p’ 번호 확인
      4. p’와 변위 d를 사용해 주소 r 확인
    - **문제점**
      - 접근 횟수 2배, 성능 저하
      - PMT를 위한 공간 필요
      - 해결
          - TLB를 이용한 Associate Mapping
  - **Associate Mapping**
    - PMT를 위한 전용 기억장치 사용 → 캐시 = AMT, P’를 찾을 때, AMT 부터 접근
    - page number를 병렬 탐색하여 p’를 빠르게 찾음
    - 하드웨어 비싼 대신 오버헤드 낮고 속도 빠름
    - **진행순서**
      1. AMT에 있는 경우 → residence bit로 p’확인
      2. AMT에 없는 경우 → PMT 확인 후 AMT에 entry 적재
      3. PMT에서 사용되는 entry 지역성을 따져 AMT에 적재

### **Segmentation**
  - 서로 다른 크기를 갖는 논리적인 단위
  - 서브루틴이나 함수, 행렬, 스택 등 단위로 이름 붙여 적재
  - 미리 분할 X
  - 공유 및 보호 용이
  - 주소 매핑 및 메모리 관리 오버헤드가 큼
  - Segment Map Table을 가짐
  - SMT를 통해 물리주소를 찾는 순서
    1. SMT에 접근
    2. segment에 대한 entry 찾기
    3. 존재비트 검사
        - 없으면 적재
        - 변위 d가 segment 크기보다 크면 overflow 에러
        - protection bit 상 접근 불가능한 상태면 Protection Exception
    4. 가상 주소와 변위로 실주소 확인

### **Hybrid**
  - 프로그램을 segment로 나누고 그걸 page로 나눔, 적재는 page 단위로.
  - segmentation 방식에서 외부 단편화 없애기 위해 paging 방식과 섞음
      - 외부보다 내부 단편화가 좀 더 안정적이기 때문
  - SMT PMT 모두 사용
  - 메모리 소모 많고, 매핑 복잡해 접근시간 김
  - 외부단편화 X 내부단편화 O
