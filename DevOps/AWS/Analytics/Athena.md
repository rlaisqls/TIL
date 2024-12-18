
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

### 테이블 생성

테이블 생성 후 파티션 메타데이터를 등록하기 위해 REPAIR 명령어를 사용한다.

```sql
MSCK REPAIR TABLE {table_name};
```

---
reference

- <https://aws.amazon.com/athena/faqs/?nc=sn&loc=6>
- <https://docs.aws.amazon.com/athena/latest/ug/serde-reference.html>

