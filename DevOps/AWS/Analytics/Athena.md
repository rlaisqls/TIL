
- Amazon Athena는 오픈 소스 프레임워크를 기반으로 구축된 서버리스 대화형 분석 서비스로, 오픈 테이블 및 파일 형식을 지원한다. 페타바이트 규모의 데이터를 분석할 수 있는 간단한 방법을 제공한다.
  
- Athena를 사용하면 SQL 또는 Python을 사용하여 Amazon Simple Storage Service(S3) 데이터 레이크와 온프레미스 데이터 소스나 다른 클라우드 시스템을 포함한 30개의 데이터 소스에서 데이터를 분석하거나 애플리케이션을 구축할 수 있다.

- 오픈 소스 Trino 및 Presto 엔진과 Apache Spark 프레임워크를 기반으로 구축되어 있으며, 프로비저닝이나 구성 작업 없이 사용할 수 있다.
  
- SQL용 Amazon Athena는 AWS Management Console, AWS SDK 및 CLI, 또는 Athena의 ODBC나 JDBC 드라이버를 통해 접근할 수 있다. ODBC 또는 JDBC 드라이버를 사용하여 프로그래밍 방식으로 쿼리를 실행하거나 테이블 또는 파티션을 추가할 수 있다.

![image](https://github.com/rlaisqls/TIL/assets/81006587/b46e7e45-8038-44d0-85d1-dfc2f95c9a17)

### SerDe

- Athena는 다양한 데이터 형식의 데이터를 구문 분석하는 여러 SerDe(Serializer/Deserializer) 라이브러리를 지원한다.
- Athena에서 테이블을 생성할 때 데이터의 형식에 해당하는 SerDe를 지정할 수 있다.
- 기본값으론 [Lazy Simple SerDe](https://docs.aws.amazon.com/athena/latest/ug/lazy-simple-serde.html)를 사용한다. CSV, TSV 등 규칙적인 구분자로 데이터를 구분하는 형식에 대해 파싱할 수 있다.
  - Lazy Simple serde 구분자 지정 예시

    ```sql
    ROW FORMAT DELIMITED
    FIELDS TERMINATED BY '\t'
    ESCAPED BY '\\'
    LINES TERMINATED BY '\n'
    ```

- Parquet serde 예시

    ```sql
    ...
    ROW FORMAT SERDE  
    'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' 
    WITH SERDEPROPERTIES (  
    'parquet.ignore.statistics'='true')  
    STORED AS PARQUET 
    ...

    ```

- AWS에서 지원하는 더 다양한 serde 목록 및 사용법은 [공식문서](https://docs.aws.amazon.com/athena/latest/ug/supported-serdes.html)에서 확인할 수 있다.

### 파티션 프로젝션 설정

파티션은 말 그대로, 데이터를 특정 단위로 분류하여 필요한 범주의 파일을 더 빠르게 찾을 수 있도록 돕는 기능이다.

만약 파일 저장 경로가 `/{yyyy}/{MM}/{dd}` 와 같이 날짜별로 나눠져있을 때 파티션을 설정한 후 2024년 12월의 데이터를 쿼리하면, Athena는 다른 폴더를 무시하고 /2024/12 경로만 탐색한다. 따라서 검색 속도가 빨라진다. 데이터의 양이 많아지면 쿼리 성능을 위해 파티션 지정은 필수적이다.

이 파티션 정보는 데이터 분석 특화 엔진인 Glue나 외부에 수동으로 지정할 수도 있고, Athena에서 쿼리를 실행할 때 실시간으로 계산하도록 할 수도 있는데 파티션이 자주 변하는 경우 Athena에서 계산하는 것이 더 성능 효율적이다.

이 기능을 파티션 프로젝션이라고 한다.

파티션 프로젝션을 적용하기 위해선 `PARTITIONED BY`, `TBLPROPERTIES` 두 부분에 설정을 추가해야한다.

- `PARTITIONED BY`

  - 파티션 항목의 이름을 정의한다

- `TBLPROPERTIES`

  - `'projection.enabled'='true'`: projection을 활성화한다.

  - `'projection.{field-name}.type'={type}`: 파티션 할 항목(필드)의 타입을 지정한다.

    - 총 4가지 타입(enum, integer, date, injected)이 있다.

    - 타입별로 허용할 파티션 값의 범위 (int는 range 등)를 각각 지정해줘야한다. 자세한 내용은 [공식문서](https://docs.aws.amazon.com/ko_kr/athena/latest/ug/partition-projection-supported-types.html) 참고

  - `'storage.location.template'='s3://...'`: 파티션 항목이 폴더 경로에 어떻게 포함되는지 표현한다.

- 아래는 연월일, 시간을 파티션 필드로 지정한 예시이다.

```
PARTITIONED BY ( 
  `year` string, 
  `month` string, 
  `day` string, 
  `hour` string)
ROW FORMAT SERDE ...
LOCATION ...
TBLPROPERTIES (
  'projection.enabled'='true', 
  'projection.day.type'='integer',
  'projection.day.range'='1, 31', 
  'projection.hour.type'='integer', 
  'projection.hour.range'='0, 23', 
  'projection.month.type'='integer', 
  'projection.month.range'='1, 12', 
  'projection.year.type'='integer',
  'projection.year.range'='2024, 2124', 
  'storage.location.template'='s3://test-log-bucket/${year}/${month}/${day}/${hour}/'
);
```

### 테이블 생성

테이블 생성 후 파티션 메타데이터를 등록하기 위해 REPAIR 명령어를 사용한다.

```sql
MSCK REPAIR TABLE {table_name};
```

---
reference

- <https://aws.amazon.com/athena/faqs/?nc=sn&loc=6>
- <https://docs.aws.amazon.com/athena/latest/ug/serde-reference.html>
