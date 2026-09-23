- <https://github.com/apache/parquet-format>
- Thrift 정의: `src/main/thrift/parquet.thrift`

## Layout

```
4-byte magic "PAR1"
[Column 1 Chunk 1][Column 2 Chunk 1]...[Column N Chunk 1]   ← Row Group 1
[Column 1 Chunk 2][Column 2 Chunk 2]...[Column N Chunk 2]   ← Row Group 2
...
File Metadata (Thrift TCompactProtocol)
4-byte metadata 길이 (little endian)
4-byte magic "PAR1"
```

- **Row Group**: 행을 가로로 자른 논리적 덩어리. 물리적 구조가 보장되지는 않음. 컬럼마다 정확히 하나의 Column Chunk를 가짐
- **Column Chunk**: 한 Row Group 안 한 컬럼의 데이터. **파일 안에서 연속임이 보장됨** → 원격 read 한 번의 단위로 딱 맞음
- **Page**: Column Chunk를 다시 자른 조각. **압축·인코딩의 분할 불가능한 단위.** 한 청크 안에 여러 종류 페이지가 섞일 수 있음
- **footer**: 스키마, 각 Column Chunk의 위치·크기·인코딩·통계, 인덱스 위치. **데이터를 다 쓴 뒤에 쓰므로 single-pass 쓰기가 가능함**

병렬화 단위가 층마다 다르게 설계돼 있음

| 층 | 병렬화 단위 |
| --- | --- |
| MapReduce / 태스크 분할 | File, Row Group |
| I/O | Column Chunk |
| 인코딩 / 압축 | Page |

### 크기 권장값

| 항목 | 스펙 권장 | parquet-java 기본값 |
| --- | --- | --- |
| Row Group | 512MB ~ 1GB (HDFS 블록 하나에 딱 맞추라는 의도) | 128MB (`DEFAULT_BLOCK_SIZE`) |
| Page | 8KB (단일 행 조회를 세밀하게 하려고) | 1MB (`DEFAULT_PAGE_SIZE`) |
| Dictionary Page | — | 1MB, 기본 활성 |
| Page 행 수 상한 | — | 20,000행 |
| Writer 버전 | — | `PARQUET_1_0` → **Data Page V1이 아직도 기본값** |

- 스펙 권장값은 HDFS 시대 기준이라 오브젝트 스토리지 환경에서는 그대로 쓰지 않음
- 페이지 8KB 권장은 "페이지 인덱스로 단일 행 찾기"를 상정한 것. 실제로는 헤더 오버헤드 때문에 대부분 1MB 안팎을 씀

### 에러 복구 특성

- footer 손상 → **파일 전체 손실**
- Column Chunk 메타데이터 손상 → 그 청크만 손실 (다른 Row Group의 같은 컬럼은 무사)
- 페이지 헤더 손상 → 그 청크의 이후 페이지 전부 손실
- 페이지 데이터 손상 → 그 페이지만 손실
- 즉 **Row Group을 작게 잡을수록 손상에 강함** 페이지는 CRC32로 개별 체크섬을 붙일 수 있음

## Type

"디스크에 어떻게 저장되는가"에만 관심이 있어서 16비트 정수 같은 건 아예 없음 (INT32 + 효율적 인코딩으로 커버)

| 물리 타입 | 비고 |
| --- | --- |
| `BOOLEAN` | 1비트 |
| `INT32` / `INT64` | 부호 있는 정수 |
| `INT96` | **deprecated.** 옛 Impala/Hive 타임스탬프 호환용으로만 남음 |
| `FLOAT` / `DOUBLE` | IEEE 754 |
| `BYTE_ARRAY` | 가변 길이 |
| `FIXED_LEN_BYTE_ARRAY` | 고정 길이 (`type_length`로 지정) |

나머지는 전부 **논리 타입 어노테이션**으로 처리함 (e.g. 문자열은 `BYTE_ARRAY` + `STRING` 어노테이션)

```
1 STRING   2 MAP      3 LIST     4 ENUM     5 DECIMAL   6 DATE
7 TIME     8 TIMESTAMP           10 INTEGER 11 UNKNOWN  12 JSON
13 BSON    14 UUID    15 FLOAT16 16 VARIANT 17 GEOMETRY 18 GEOGRAPHY  19 FILE
(9는 INTERVAL 용으로 예약만 돼 있음)
```

- 이렇게 나눈 이유: 물리 타입을 적게 유지하면 리더/라이터 구현이 단순해지고, 새 의미 타입을 추가해도 **기존 인코딩을 그대로 재사용**할 수 있음
- 구버전 `ConvertedType`과 신버전 `LogicalType`이 공존함. 대부분 1:1 대응되지만 FLOAT16 이후 타입들은 `ConvertedType`이 없음
- `VARIANT`, `GEOMETRY`, `GEOGRAPHY`, `FILE`은 최근 추가분이라 지원하는 엔진이 제한적임

## Dremel

중첩 구조를 평탄화하지 않고 컬럼으로 쪼개기 위해,  Google Dremel 논문의 record shredding / assembly 알고리즘을 그대로 씀.

- **definition level**: 이 값까지 오는 경로에서 optional 필드가 *몇 개까지 정의됐는지*를 나타냄. NULL이 어느 깊이에 있는지를 표현함
- **repetition level**: *어느 깊이의 반복 필드에서* 값이 반복됐는지
- 두 레벨의 최댓값은 스키마에서 계산됨 → 저장에 필요한 비트 폭이 결정됨
- 레벨 인코딩은 `RLE`와 `BIT_PACKED` 둘이 정의돼 있지만 **실제로는 RLE만 씀** (BIT_PACKED의 상위 집합이라)

- NULL 여부는 오직 definition level에만 기록되고, **값 영역에는 아무것도 안 쓰임**
- 그래서 비중첩 컬럼에 NULL이 1000개면 → definition level에 `(0, 1000번 반복)` RLE 런 하나가 전부이고 값 영역은 비어 있음
- 리더 입장에서 함정이 되는 지점이기도 함: **"논리 행 i번째"와 "인코딩된 값 i번째"가 다름.** 이걸 헷갈리면 값이 통째로 밀림

### 레벨 생략

- 컬럼이 중첩이 아니면(경로 길이 1) repetition level을 아예 안 씀
- `REQUIRED` 데이터는 definition level을 생략함 항상 최댓값이기 때문
- 비중첩 + required 컬럼은 페이지에 **값만** 들어감

## Encoding

| encoding | enum | type | 비고 |
| --- | --- | --- | --- |
| `PLAIN` | 0 | 전부 | 값을 그대로 연속 배치. 리틀엔디안, BYTE_ARRAY는 4바이트 길이 + 바이트 |
| `PLAIN_DICTIONARY` | 2 | 전부 | **deprecated.** 신규 파일은 RLE_DICTIONARY를 쓸 것 |
| `RLE` | 3 | BOOLEAN, 딕셔너리 인덱스, 레벨 | RLE + 비트패킹 하이브리드 |
| `BIT_PACKED` | 4 | 레벨만 | **deprecated.** RLE로 대체됨 |
| `DELTA_BINARY_PACKED` | 5 | INT32, INT64 | 블록/미니블록 델타 + frame of reference |
| `DELTA_LENGTH_BYTE_ARRAY` | 6 | BYTE_ARRAY | 길이는 델타로, 바이트는 뒤에 몰아서. **PLAIN보다 항상 나음** |
| `DELTA_BYTE_ARRAY` | 7 | BYTE_ARRAY, FLBA | 앞 값과의 공통 접두사 길이 + 접미사 (front compression) |
| `RLE_DICTIONARY` | 8 | 전부 | 현재 표준 딕셔너리 인코딩 |
| `BYTE_STREAM_SPLIT` | 9 | FLOAT, DOUBLE, INT32, INT64, FLBA | 바이트 위치별로 스트림 분리 |
| `ALP` | 10 | FLOAT, DOUBLE | **Preview (2026-08-01 기준).** SIGMOD 2024 논문 기반 |

`1`(GROUP_VAR_INT)은 정의만 되고 쓰인 적이 없어 thrift에서 주석 처리돼 있음.

### RLE / 비트패킹 하이브리드

가장 많이 쓰이는 인코딩

같은 값이 연속되면 런으로, 아니면 비트패킹으로 저장하고 둘을 섞음.

```
run := <bit-packed-run> | <rle-run>
rle-run        := varint(런길이 << 1)        + 반복값
bit-packed-run := varint((개수/8) << 1 | 1)  + 패킹된 값들
```

- **비트패킹 순서가 LSB first임** 리틀엔디안 하드웨어에서 4바이트를 32비트 레지스터에 통째로 읽어 시프트+마스크만으로 언패킹하기 위해 일부러 이렇게 함
- 그래서 deprecated된 `BIT_PACKED`(MSB first)와 비트 순서가 다름. 둘을 섞으면 값이 깨짐
- 런 길이는 `[1, 2^31-1]` 범위. 이 제약은 2.5.0 이후에 명문화됐음
- 4바이트 길이 접두사를 붙이는지 여부가 **Page V1/V2와 데이터 종류마다 다름**. 리더가 자주 틀리는 부분

| Page | 레벨 | 딕셔너리 인덱스 | BOOLEAN |
| --- | --- | --- | --- |
| V1 | 길이 접두사 O | X | O |
| V2 | **X** | X | O |

### 딕셔너리 인코딩

- 컬럼 청크에 등장한 값 목록을 Dictionary Page에 모으고, 데이터 페이지에는 정수 ID만 RLE로 저장함
- **Dictionary Page는 청크 맨 앞에 와야 하고, 청크당 최대 하나임**
- 딕셔너리가 너무 커지면(크기 또는 distinct 개수) 라이터가 **중간에 PLAIN으로 폴백함** → 한 청크 안에 딕셔너리 페이지와 plain 페이지가 섞임
- 데이터 페이지 첫 1바이트가 ID의 비트 폭(최대 32)이고, 그 뒤가 RLE 하이브리드
- 읽는 쪽에서 가지치기로 역이용할 수 있지만(딕셔너리에 없으면 데이터에도 없음), **청크의 모든 데이터 페이지가 딕셔너리 인코딩일 때만** 성립함. 폴백이 섞이면 불가

### DELTA 계열

- `DELTA_BINARY_PACKED` — 블록(128의 배수) → 미니블록으로 나누고, 미니블록마다 **개별 비트 폭**을 둠. 블록마다 min delta를 빼서 전부 음이 아닌 수로 만든 뒤 비트패킹
  - RLE와의 차이: RLE는 페이지 전체에 단일 비트 폭이라 값 범위 변동에 취약함. DELTA는 미니블록 단위라 덜 민감
  - **뺄셈/덧셈 오버플로를 2의 보수 wrap-around로 허용함.** 언어에 따라 unsigned 도메인에서 계산해야 원값이 복원됨
- `DELTA_LENGTH_BYTE_ARRAY` — `[델타 인코딩된 길이들][바이트 데이터 전부]`. 길이와 데이터가 섞이지 않아 압축률도 좋아짐. 스펙이 **BYTE_ARRAY에는 PLAIN보다 항상 낫다**고 명시함
- `DELTA_BYTE_ARRAY` — `[접두사 길이들][접미사 길이들][접미사 바이트]`. 정렬된 문자열에 강함
  - 예: `axis, axle, babble, babyhood` → 접두사 `0,2,0,3` / 접미사 `4,2,6,5` / `"axislebabbleyhood"`

### BYTE_STREAM_SPLIT

- **데이터 크기를 안 줄임.** 대신 뒤에 붙는 압축기의 효율을 크게 올림
- K바이트 타입 N개를 → 길이 N짜리 스트림 K개로 재배치. 0번째 바이트끼리, 1번째 바이트끼리 모음
- 부동소수점처럼 상위 바이트(지수부)는 비슷하고 하위 바이트(가수부)는 랜덤한 데이터에서 효과가 큼
- 2.11.0에서 INT32/INT64/FLBA까지 확대됨

## 5. 압축 코덱

`UNCOMPRESSED` / `SNAPPY` / `GZIP` / `LZO` / `BROTLI` / `LZ4`(deprecated) / `ZSTD` / `LZ4_RAW`

- 페이지의 raw 바이트를 **추가 프레이밍 없이 그대로** 압축 라이브러리에 넘김. 버퍼 크기 정보는 `PageHeader`에 있음
- `LZ4`는 Hadoop 압축 라이브러리의 문서화되지 않은 프레이밍이 섞여 들어가 **구현마다 호환이 깨짐.** 반드시 `LZ4_RAW`를 쓸 것
- GZIP은 멀티 멤버 페이지를 리더가 지원해야 하지만, 역사적으로 안 되는 구현이 많아 라이터는 만들지 않기를 권함
- 실무 기본값은 대체로 SNAPPY(빠름) 또는 ZSTD(압축률). 흥미롭게도 **parquet-java의 기본 코덱은 UNCOMPRESSED**라서 엔진이 따로 지정해주는 것

## 6. Data Page V1 vs V2

데이터 페이지 안 구성은 `[repetition levels][definition levels][encoded values]` 순서고 **패딩이 없음**. V1/V2는 이 세 조각을 어떻게 다루느냐가 다름.

| | V1 (`DataPageHeader`) | V2 (`DataPageHeaderV2`) |
| --- | --- | --- |
| 레벨 압축 | 값과 함께 통째로 압축됨 | **레벨은 비압축**, 값 부분만 압축 |
| 레벨 길이 | 헤더에 없음 (RLE 길이 접두사로 파악) | `definition_levels_byte_length` / `repetition_levels_byte_length` |
| NULL 개수 | 없음 | `num_nulls` 필수 |
| 행 개수 | 없음 | `num_rows` 필수. **행이 페이지 경계를 넘지 못함** |
| 압축 여부 | 항상 코덱 적용 | `is_compressed` 플래그 (기본 true) |

- V2의 장점은 **값을 압축 해제하지 않고 레벨만 읽을 수 있다는 것.** COUNT나 null 개수 집계에 유리함
- 스펙도 "V2가 V1보다 엄격히 낫지는 않다"고 명시함 (V1이 압축률이 나은 경우가 있음)
- 그리고 **parquet-java 기본 writer 버전은 아직 `PARQUET_1_0`임.** 세상에 돌아다니는 파일 대부분이 V1이라 리더는 둘 다 지원해야 함
- 참고: 페이지 인덱스를 쓰려면 **어느 헤더든** 페이지가 행 경계에서 시작/종료해야 함

## 7. 통계와 인덱스 — "안 읽고 판단하기" 장치들

### Statistics (Column Chunk 단위)

```thrift
struct Statistics {
  1: optional binary max;        // DEPRECATED
  2: optional binary min;        // DEPRECATED
  3: optional i64 null_count;
  4: optional i64 distinct_count;
  // + min_value / max_value (ColumnOrder 기준)
}
```

- footer 안에 이미 있으므로 **읽는 데 추가 I/O가 0임.** 가지치기 1순위가 되는 이유
- `null_count`는 0이어도 쓰라고 권고하고, 리더는 **"없음"과 "0"을 반드시 구분해야 함.** 없는데 0으로 가정하면 틀림

### ColumnIndex / OffsetIndex (Page 단위)

2.4.0에서 포맷에 들어가고(PARQUET-922) 2.5.0에서 라이터가 붙기 시작함(PARQUET-1201).

기존에도 페이지 통계는 `DataPageHeader` 안에 있었지만, **그걸 읽으려면 페이지 헤더를 전부 훑어야 해서 결국 컬럼 데이터를 거의 다 읽게 되는** 문제가 있었음. 그래서 통계만 따로 모아 footer 근처로 뺀 것.

- `ColumnIndex` — 값으로 페이지 찾기
  - `null_pages[]` — 전부 NULL인 페이지 표시. true면 대응 min/max는 `byte[0]`
  - `min_values[]` / `max_values[]` — **실제 값이 아니어도 됨.** `"Blart Versenwald III"` 대신 `"B"`~`"C"`로 truncate 가능. 인덱스 크기를 제한하려는 의도
  - `boundary_order` — 정렬돼 있으면 리더가 **이진 탐색** 가능
  - FLOAT/DOUBLE/FLOAT16의 NaN은 경계에서 제외해야 함
- `OffsetIndex` — 행 번호로 페이지 찾기
  - `PageLocation{offset, compressed_page_size, first_row_index}`
  - `compressed_page_size`는 **페이지 헤더 크기를 포함함**
  - OffsetIndex가 있으면 **페이지는 반드시 행 경계(repetition_level = 0)에서 시작해야 함**
- 두 구조는 RowGroup이 아니라 **footer 근처에 따로 저장됨.** 선택적 스캔을 안 하는 리더는 읽지도 역직렬화하지도 않게 하려는 설계
- ColumnIndex를 지원하는 리더는 **페이지 헤더 통계를 같이 쓰면 안 됨.** 페이지 통계를 쓰는 유일한 이유는 구버전 리더 호환뿐

### Bloom Filter (2.7.0, PARQUET-41)

딕셔너리가 커져서 못 쓰는 고카디널리티 컬럼을 위한 것. 딕셔너리보다 훨씬 작은 공간으로 "없음"을 증명함.

- **SBBF (Split Block Bloom Filter)** — 블록 하나가 256비트 = 32비트 워드 8개
- 홀수 상수 8개짜리 `salt`로 워드마다 정확히 1비트씩 세팅함. 곱한 뒤 `>> 27`해서 0~31 비트 위치를 얻음
- 블록 하나가 캐시 라인에 들어가 **조회가 메모리 접근 1회로 끝남.** 일반 블룸 필터가 k개 해시 위치를 흩뿌려 읽는 것과 대비됨
- 해시는 **xxHash의 XXH64** (xxHash spec 0.1.1)
- 오탐률은 값당 비트 수로 조절함

| 값당 비트 | 오탐률 |
| --- | --- |
| 20 bits | 0.04% |
| 10 bits | 1.26% |
| 5 bits | 18% |

- **거짓 음성은 없음.** 그래서 "없다"는 100% 신뢰 가능하고 "있다"는 확인이 필요함 → equality / IN 조건에만 쓸모 있음

### SizeStatistics (2.10.0, PARQUET-2261)

- BYTE_ARRAY의 **인코딩 전 크기**와 definition/repetition level 히스토그램
- 리더가 "이 페이지를 풀면 메모리를 얼마나 쓸까"를 미리 계산할 수 있게 함. 버퍼 선할당과 배치 크기 결정에 쓰임

## 모듈러 암호화 (2.7.0)

- `AES_GCM_V1` — 모든 모듈(footer, 페이지, 페이지 헤더, 인덱스)을 GCM으로 암호화 + 인증
- `AES_GCM_CTR_V1` — 메타데이터는 GCM, 데이터 페이지는 CTR. 인증을 일부 포기하고 처리량을 얻는 절충
- 컬럼 단위로 다른 키를 쓸 수 있음 → 민감 컬럼만 선택적으로 암호화 가능
- footer 자체를 암호화하면 `FileCryptoMetaData`가 평문으로 남아 복호화 진입점 역할을 함

## Write시 신경쓸 것

읽기 성능은 파일을 **어떻게 썼는가**가 거의 결정함. 리더 최적화로 만회할 수 있는 폭이 생각보다 좁음.

- **정렬이 가장 중요함** 자주 필터하는 컬럼으로 정렬해서 쓰면 Row Group / Page의 min~max가 좁아져 가지치기가 먹힘. 정렬 안 된 데이터는 리더가 아무리 좋아도 통계가 전부 겹쳐서 소용없음
- **Row Group 크기**: 크면 순차 I/O에 유리하고 footer가 작아짐. 작으면 가지치기 입도가 세밀해지고 손상에 강함. 오브젝트 스토리지면 128~512MB가 무난
- **페이지 인덱스를 쓰는 라이터를 쓸 것** 안 쓰면 리더의 페이지 단위 최적화가 통째로 비활성화됨
- **딕셔너리를 끄지 말 것** 저카디널리티 컬럼에서 압축과 가지치기 양쪽에 다 기여함
- **고카디널리티 필터 컬럼에는 Bloom Filter를 붙일 것** 딕셔너리도 통계도 못 거르는 유일한 구간
- 작은 파일이 많으면 footer 읽기와 요청 수가 지배적이 됨. 컴팩션이 답임

## Read시 신경쓸 것

포맷을 정확히 읽으려면 알아야 하는 것들 (대부분 하위호환 때문에 생김)

- **`min`/`max` (구 필드)는 정렬 순서가 정의되지 않았음**
  - 부호 없는 정수를 부호 있는 비교로 쓰거나, UTF-8을 바이트 비교로 쓰는 등 라이터마다 달랐음
  - 그래서 `ColumnOrder`를 명시한 `min_value`/`max_value`가 새로 생김
  - 리더는 **`created_by` 문자열을 파싱해 라이터 버전을 보고 통계를 믿을지 결정해야 함.** parquet-mr 1.8.0 미만의 문자열 통계는 틀림 (PARQUET-1025)
- **INT96은 deprecated**지만 옛 Hive/Impala 타임스탬프가 전부 이걸 씀. 12바이트 = (nanos-of-day 8바이트 + Julian day 4바이트)라 변환 로직이 따로 필요함
- **`null_count` 부재 ≠ 0.** 스펙이 명시적으로 경고함
- **NaN**: 부동소수점 min/max에서 제외돼야 함. 페이지 전체가 NaN이면 라이터가 특수 처리를 해야 함
- **truncated 경계값**: ColumnIndex의 min/max는 실제 존재하지 않는 값일 수 있음. "이 값이 실제로 있다"고 해석하면 안 되고 경계로만 써야 함
- **LZ4 vs LZ4_RAW**: 같은 이름인데 프레이밍이 달라서 구현 간 호환이 깨짐
- **레벨 비트 폭은 저장 한계일 뿐임** 스키마 최대 definition level이 2여도 2비트는 값 3을 표현할 수 있음. 리더가 스키마 최댓값 초과를 거부하지 않으면 손상 데이터가 그대로 통과함
- **논리 행 위치 ≠ 인코딩된 값 위치** NULL이 값 영역에 없어서 생기는 차이. selection/skip 로직에서 가장 사고가 잦은 지점
- **PARQUET-816 패딩**: 일부 옛 라이터가 최대 100바이트의 패딩을 남김. `created_by` 기반 보정이 필요함
