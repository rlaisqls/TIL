[Gorilla Compression](https://dl.acm.org/doi/10.14778/2824032.2824078)은 Facebook이 2015년 발표한 시계열 데이터 전용 압축 알고리즘이다. IoT, 모니터링 시스템, 로그 수집 등에서 대규모 시계열 데이터를 효율적으로 저장하고 전송하기 위해 고안되었으며, 시계열 데이터베이스(TSDB: Time Series Database)에서 널리 활용된다.

아래 프로그램에도 Gorilla Compression과 비슷한 압축 로직이 사용되고 있다.

- Prometheus: time series chunk compression에서 유사한 기법 채택
- InfluxDB: TSM(Time Structured Merge tree) 엔진에 유사한 delta/XOR 기법 적용
- VictoriaMetrics: 자체 압축 방식에 Gorilla의 timestamp/value 인코딩 알고리즘 적용
- TimescaleDB: 기본 PostgreSQL 엔진 위에 압축 layer를 두어 적용 가능

Gorilla Compression은 시계열 데이터를 압축하기 위해 시간(timestamp)과 값(value)을 분리하여 각각 다른 방식으로 압축한다.

## Timestamp 압축

시계열 데이터는 일반적으로 **고정된 간격(interval)**으로 수집되는 경우가 많으므로, 이 패턴을 활용하여 타임스탬프를 효율적으로 저장한다.

1. 첫 번째 타임스탬프는 그대로 저장한다.
2. 이후 타임스탬프는 **이전 타임스탬프와의 차이(delta)**를 저장한다.
3. 두 번째부터는 **이전 delta와의 차이(delta of delta)**를 저장한다.
4. delta of delta 값은 가변 길이 비트 인코딩(variable-length encoding)을 사용해 적은 비트 수로 표현한다. (대부분의 delta-of-delta는 0에 가깝고, 0은 1비트에 저장할 수 있으므로 효율적이다.)

## Value 압축 (XOR 기반)

시계열 값은 대체로 **천천히 변화**하거나 **비슷한 값이 반복**되므로, 이런 특성을 활용한 XOR 기반 압축을 수행한다.

- 첫 번째 값은 그대로 저장한다.
- 이후 값은 이전 값과 XOR 연산을 수행한 결과를 저장한다.
- XOR 결과가 0이면 값이 동일하다는 뜻이므로 단일 비트 `0`로 표현된다.
- XOR 결과가 0이 아니면:
  - XOR 값에서 유효한 비트 구간의 시작 위치와 길이를 인코딩한 후, 해당 비트만 저장한다.
  - 이전과 동일한 시작 위치 및 길이라면 해당 정보를 생략하고 유효 비트만 저장한다.

- 예시

    ```text
    이전 값: 01010101010101010101010101010101  
    현재 값: 01010101010101010111010101010101  
    XOR 결과: 00000000000000000010000000000000
    ```

- 앞뒤에 0이 많고, 중앙의 일부 비트만 다르기 때문에, 소량의 비트로 변경된 부분만 저장하면 충분하다.
- 값 변화가 작을수록 압축률이 높아지며, 중복 값, 혹은 noise만 있는 경우에도 효율적이다.

## 장단점

장점

- 인코딩/디코딩 성능이 빠르다.
- 메모리 사용량이 적고, 디스크 저장 효율이 높다.
- 압축된 블록을 앞에서부터 읽으며 순차적으로 복원 가능하기 때문에 I/O 효율이 좋다. (streaming-friendly)

단점

- 압축률이 데이터 패턴에 크게 의존해서, 비정형 간격 데이터, 변동성이 큰 데이터에서는 비효율적일 수 있다.

---
참고

- <https://dl.acm.org/doi/10.14778/2824032.2824078>
- <https://jessicagreben.medium.com/four-minute-paper-facebooks-time-series-database-gorilla-800697717d72>
- <https://engineering.fb.com/2017/02/03/core-infra/beringei-a-high-performance-time-series-storage-engine/>
