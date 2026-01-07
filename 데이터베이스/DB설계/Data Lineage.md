
데이터 리니지(Data Lineage)는 데이터가 어디서 와서 어디로 가는지 추적하는 것이다.

데이터 웨어하우스 등에서, 테이블이 많아지면 간접적으로 의존하는 테이블이 있을 수 있어 스키마 변경이 점점 어려워진다. 리니지가 있으면 이런 의존 관계를 한눈에 볼 수 있어서 영향 범위 파악이 훨씬 쉬워진다.

데이터 리니지를 설명할 때 `A → B → C`처럼 B 입장에서 A는 upstream(데이터 출처), C는 downstream(데이터 소비처)로 부르기도 한다. 리니지를 어느 방향으로 따라가느냐에 따라 forward lineage(downstream 방향, 영향도 분석)와 backward lineage(upstream 방향, 원인 추적)로도 나눈다.

## 테이블 리니지, 컬럼 리니지

테이블 단위 리니지는 "테이블 A → 테이블 B" 수준으로만 추적한다. 쿼리가 실행될 때 어떤 테이블을 읽어서 어떤 테이블에 썼는지만 기록하는 것이다. BigQuery는 `INFORMATION_SCHEMA.JOBS`, Snowflake는 `ACCOUNT_USAGE.ACCESS_HISTORY`, Redshift는 `STL_SCAN` 같은 시스템 테이블에서 이 정보를 얻을 수 있다.

근데 테이블 단위로는 부족한 경우가 있다. `users` 테이블의 `email` 컬럼을 삭제하고 싶은데, `users`를 참조하는 테이블이 10개라고 하자. 테이블 리니지만 있으면 10개를 다 열어서 `email`을 쓰는지 확인해야 한다. 근데 실제로 `email`을 쓰는 테이블이 2개뿐이라면 나머지 8개는 괜히 확인한 셈이다.

컬럼 리니지는 컬럼 단위로 관계를 추적한다. 아래 쿼리에서 컬럼 리니지가 있으면 `full_name`이 `first_name`과 `last_name`에서 파생됐다는 걸 기록해둔다. 나중에 `last_name`을 삭제하려고 하면 `full_name`이 영향받는다는 걸 바로 알 수 있다.

```sql
SELECT
    u.id,
    u.first_name || ' ' || u.last_name AS full_name
FROM users u
```

이걸 coarse-grained lineage(테이블 단위)와 fine-grained lineage(컬럼 단위)라고 부르기도 한다.

## 테이블 리니지 조회 예시

DW별로 특정 테이블을 참조한 쿼리들을 찾는 방법이다.

**BigQuery**

```sql
SELECT
  creation_time,
  user_email,
  destination_table.project_id || '.' || destination_table.dataset_id || '.' || destination_table.table_id AS destination,
  ref.project_id || '.' || ref.dataset_id || '.' || ref.table_id AS source
FROM `region-us`.INFORMATION_SCHEMA.JOBS,
UNNEST(referenced_tables) AS ref
WHERE ref.table_id = 'users'
  AND destination_table IS NOT NULL
ORDER BY creation_time DESC
LIMIT 100;
```

**Snowflake**

```sql
SELECT
  query_start_time,
  user_name,
  direct_objects_accessed,
  objects_modified
FROM snowflake.account_usage.access_history,
LATERAL FLATTEN(input => direct_objects_accessed) AS src
WHERE src.value:objectName::STRING = 'USERS'
  AND src.value:objectDomain::STRING = 'Table'
ORDER BY query_start_time DESC
LIMIT 100;
```

**Redshift**

```sql
SELECT DISTINCT
  q.starttime,
  u.usename,
  q.querytxt,
  t.schemaname || '.' || t.tablename AS source_table
FROM stl_scan s
JOIN stl_query q ON s.query = q.query
JOIN svv_tables t ON s.tbl = t.table_id
JOIN pg_user u ON q.userid = u.usesysid
WHERE t.tablename = 'users'
ORDER BY q.starttime DESC
LIMIT 100;
```

## 컬럼 리니지 조회 예시

컬럼 리니지는 시스템 테이블에서 바로 뽑을 수 없다. SQL을 파싱해서 컬럼 간 관계를 추출해야 한다.

**sqlglot으로 직접 파싱**

```python
import sqlglot
from sqlglot.lineage import lineage

sql = """
SELECT
    u.id,
    u.first_name || ' ' || u.last_name AS full_name
FROM users u
"""

# full_name 컬럼의 upstream 컬럼 추적
node = lineage("full_name", sql, dialect="postgres")
for n in node.walk():
    print(f"{n.source.sql()} -> {n.name}")
# users.first_name -> full_name
# users.last_name -> full_name
```

**dbt**

dbt 1.6+에서는 `dbt docs generate` 후 `manifest.json`에 컬럼 리니지가 포함된다.

```bash
cat target/manifest.json | jq '.nodes["model.my_project.user_summary"].columns.full_name.depends_on'
# ["model.my_project.users.first_name", "model.my_project.users.last_name"]
```

**DataHub GraphQL API**

```graphql
{
  dataset(urn: "urn:li:dataset:(urn:li:dataPlatform:bigquery,project.dataset.user_summary,PROD)") {
    schemaMetadata {
      fields {
        fieldPath
        upstreamLineage {
          dataset
          fieldPath
        }
      }
    }
  }
}
```

## 수집 방식

리니지를 수집하는 방식은 크게 두 가지 방식이 있다.

쿼리 로그 파싱

- 이미 실행된 쿼리 로그를 가져와서 파싱한다. BigQuery `INFORMATION_SCHEMA.JOBS` 같은 곳에서 쿼리를 뽑아올 수 있다. DW 한 곳에서 모든 쿼리가 실행되면 거기만 보면 되니까 편하다. 단점은 과거에 실행된 쿼리만 볼 수 있다는 것. 새로 만든 파이프라인은 한 번 실행해봐야 리니지가 생긴다.

실행 시점 계측

- 작업이 실행될 때 리니지 이벤트를 실시간으로 수집한다. OpenLineage가 대표적인데, Airflow나 Spark에 플러그인을 설치해서 작업 실행할 때마다 리니지 이벤트를 전송한다. 표준 스펙이라 여러 도구 간 통합이 쉽다. 단점은 모든 실행 환경에 플러그인을 설치해야 해서 초기 세팅이 번거롭다.

## Tools

리니지를 다루는 도구들은 아래와 같은 것들이 있다.

- **dbt**: `ref()` 함수로 모델 간 참조를 명시하면 테이블 리니지가 자동으로 생긴다. 1.6부터는 컬럼 리니지도 지원한다.
- **DataHub**: 오픈소스 데이터 카탈로그다. 쿼리 로그에서 리니지를 추출해주고, GraphQL API로 "이 테이블의 upstream 전부 보여줘" 같은 질의를 날릴 수 있다.
- **OpenLineage**: 리니지 이벤트의 표준 스펙이다. Marquez나 DataHub 같은 백엔드로 보내서 저장한다.

## Data Provenance

Data Provenance는 리니지랑 비슷한데, "이 데이터가 어떻게 만들어졌는지"에 좀 더 초점을 둔다. 리니지가 "A에서 B로 흘러갔다"라면, provenance는 "누가 언제 어떤 작업으로 A를 B로 바꿨는지"까지 기록한다.

W3C에서 PROV라는 표준 데이터 모델을 정의해뒀다. 세 가지 개념으로 구성된다.

- **Entity**: 데이터 자체
- **Activity**: 데이터를 변환하는 작업
- **Agent**: 그 작업을 실행한 주체(사람이나 시스템)

이 세 가지 관계를 기록하면 l누가 언제 어떤 작업으로 이 데이터를 만들었는지l를 추적할 수 있다. 감사(audit) 목적이나 규정 준수에 유용하다.

---
참고

- <https://medium.com/daangn/당근-데이터-지도를-그리다-컬럼-레벨-리니지-구축기-15cd862c7743>
- <https://en.wikipedia.org/wiki/Data_lineage>
- <https://www.ibm.com/kr-ko/think/topics/data-lineage>
- <https://openlineage.io>
- <https://datahubproject.io/docs/lineage/lineage-feature-guide>
- <https://docs.getdbt.com/docs/collaborate/column-level-lineage>
