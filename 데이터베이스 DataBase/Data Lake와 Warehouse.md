
데이터 레이크는 구조화되거나 반구조화되거나 구조화되지 않은 대량의 데이터를 저장, 처리, 보호하기 위한 중앙 집중식 저장소이다. 데이터 레이크는 데이터를 기본 형식으로 저장할 수 있으며, 크기 제한을 무시하고 다양한 데이터를 처리할 수 있다.

저장되기 전에 구조화되지 않기 때문에 데이터 웨어하우스보다 훨씬 빠르게 광범위한 데이터에 액세스 할 수 있다.

### 장점

- **Agility:** 사전 계획 없이 쿼리, data models 또는 applications을 쉽게 구성할 수 있다. SQL 쿼리 외에도 data lake strategy은 real-time analytics,  big data analytics 및 machine learning을 지원하는 데 적합하다
  
- **Real-time:** 실시간으로 여러 소스에서 원본 형식의 데이터를 가져올 수 있다. 이를 통해 real-time analytics 및 machine learning을 수행하고 다른 애플리케이션에서 작업을 trigger할 수 있다.
  
- **Scale:** structure가 없기 때문에 Data lake는 ERP 트랜잭션 및 call log과 같은 대량의 정형 및 비정형 데이터를 처리할 수 있다.
  
- **Speed:**  데이터를 원시 상태로 유지하면 해결해야 하는 비즈니스 질문을 정의할 때까지 ETL 및 Schema 정의와 같은 시간 집약적인 작업을 수행할 필요가 없으므로 훨씬 빠르게 사용할 수 있다.
  
- **Better insights:** 보다 광범위한 데이터를 새로운 방식으로 분석하여 예상치 못한 이전에 사용할 수 없었던 통찰력을 얻을 수 있다.
  
- **Cost savings:** Data lake는 관리하는 데 시간이 덜 걸리므로 운영 비용이 더 낮다. 또한 스토리지 관리에 사용하는 대부분의 도구가 오픈 소스이고 저렴한 하드웨어에서 실행되기 때문에 스토리지 비용은 기존 데이터 웨어하우스보다 저렴하다.

# Data Warehouse

데이터 웨어하우스는 POS 트랜잭션, 마케팅 자동화, 고객 관계 관리 시스템 등의 여러 소스에서 가져온 구조화된 데이터와 반구조화된 데이터를 분석하고 보고하는 데 사용되는 엔터프라이즈 시스템이다. 데이터 웨어하우스는 임시 분석과 커스텀 보고서 생성에 적합하다. 데이터 웨어하우스는 현재 데이터와 과거 데이터를 모두 한 곳에 저장할 수 있으며, 시간 흐름에 따른 장기간의 데이터 동향을 확인할 수 있도록 설계되었다.

엔터프라이즈 Data warehouse를 사용하면 서로 다른 데이터 저장소에 직접 액세스하지 않고 통계형 데이터를 빠르게 뽑아낼 수 있기 때문에 조직 전체에서 의사 결정을 더 빠르게 수행할 수 있다.

- **Better data quality. More trust:** 데이터가 필요한 형태로 가공, 표준화되어 저장되고, 단일 소스로 운영되기 때문에 신뢰성이 있다.
  
- **Complete picture. Better, faster analysis:** Data warehouse는 운영 데이터베이스, 트랜잭션 시스템 및 플랫 파일과 같은 다양한 소스의 데이터를 통합하고 조화시킨다. 비즈니스에 대한 정확하고 완전한 데이터를 더 빨리 사용할 수 있으므로 정보를 유용한 정보로서 사용하기 쉽다.

# Data Lake와 Warehouse의 차이

| 구분             | Data Lake                                         | Data Warehouse                                       |
|------------------|---------------------------------------------------|-------------------------------------------------------|
| 데이터 저장 방식  | 구조화되지 않은 Raw Data 형식으로 무기한 저장    | 사전 정의된 비즈니스 요구사항 기반으로 전략적 분석이 가능한 정재 및 처리된 구조화 데이터 저장 |
| 사용자            | 대량의 비정형 데이터를 통해 새로운 Insight를 얻기 위해 데이터를 연구하는 데이터 과학자 혹은 엔지니어가 사용 | 일반적으로 비즈니스 KPI에서 Insight를 얻으려는 관리자와 비즈니스 최종 사용자가 사용 |
| 분석              | Predictive analytics, machine learning, data visualization, BI, big data analytics. | Data visualization, BI, data analytics. |
| 스키마            | 비정형 데이터를 저장하기 위해서 Schema 정의하지 않고 ETL 과정에서 Schema 정의하는 "Schema on Read" | 비즈니스 요구사항 기반으로 정형화된 데이터를 저장하기위해 Schema 정의 및 저장할 때 Schema를 정의하는 "Schema on Write" |
| 처리              | Raw Data를 바로 저장 및 필요시 ETL 과정에서 Schema 정의 ("Schema on Read") | 저장하는 과정해서 ETL를 통한 Schema 정의 ("Schema on Write") |
| 비용              | Storage cost가 낮을 뿐만 아니라, 관리하는 cost가 낮음 | Storage cost가 높을 뿐만 아니라, 관리하는 cost도 높음 |

---
참고
- https://link.coupang.com/a/DPWfc
- https://aws.amazon.com/lake-formation/