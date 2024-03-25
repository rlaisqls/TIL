# PMU(performance monitoring unit)

- PMU는 counter register(PMC ,performance monitoring counter)와 configuration register로 구성되어 있으며 CPU 내부에 위치한다.
- 물리적으로 PMC와 하드웨어 유닛을 wire로 연결하면 하드웨어 이벤트 카운트를 측정할 수 있다. 하지만 각각의 하드웨어 유닛에 PMC들을 연결하기엔 공간상 한계(or 자원의 한계)가 존재한다. 따라서 하나의 PMC에 두 개 이상의 유닛을 연결하고 configuration register를 이용하여 측정하고 하는 이벤트를 선택할 수 있다.

    <img width="341" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/ffac1d89-dd46-434c-ad0a-22ebeb2b6d0a">

### Perf

- [perf](./Perf.md) 명령어를 사용하여 PMU의 데이터를 모니터링할 수 있다. 다음과 같은 흐름으로 정보를 가져와 보여준다.
  
1. perf 명령어가 입력되면 내부적으로 `perf_event_open()` 시스템 콜이 호출된다. 이 시스템 콜이 호출되면 configure 모듈(커널)에서 사용자가 측정하고자 하는 값을 카운트하기 위한 셋팅이 이루어진다(configuration register 값 변경).

   1. counter register(PMC)의 counter을 0으로 초기화
   2. configure events that we want to measure
   3. counter register을 enable counting하게 셋팅

2. 세팅이 끝나면 성능분석을 하고자 하는 프로그램을 실행시켜 counter register로 하드웨어 이벤트가 수집된다.

3. 분석하고자 하는 프로그램의 실행이 완료되면 counter register를 disenable counting으로 다시 세팅한다.

4. collect 모듈(커널)에서 counter register에 저장된 값을 읽어오고 최종적으로 user에게 하드웨어 이벤트 카운트를 반환한다.

    <img width="400" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/47e72c7e-be65-404c-8ef5-a5a95740ec58">


---
참고
- https://terenceli.github.io/%E6%8A%80%E6%9C%AF/2020/08/29/perf-arch
- https://leezhenghui.github.io/linux/2019/03/05/exploring-usdt-on-linux.html