# Spark

Apache Spark는 빅 데이터 워크로드에 주로 사용되는 오픈 소스 분산 처리 시스템이다. Apache Spark는 빠른 성능을 위해 인 메모리 캐싱과 최적화된 실행을 사용하며, 일반 배치 처리, 스트리밍 분석, 기계 학습, 그래프 데이터베이스 및 임시 쿼리를 지원한다.

## 장점

- **빠른 성능:** Apache Spark는 방향성 비순환 그래프(DAG) 실행 엔진을 사용함으로써 데이터 변환에 대한 효율적인 쿼리 계획을 생성할 수 있다. 또한, Apache Spark는 입력, 출력 및 중간 데이터를 인 메모리에 RDD(Resilient Distributed Dataset)로 저장하므로, I/O 비용 없이 반복 또는 대화형 워크로드를 빠르게 처리하고 성능을 높일 수 있다.
  
- **애플리케이션을 신속하게 개발:** Apache Spark는 기본적으로 Java, Scala 및 Python 등 애플리케이션을 구축할 수 있는 다양한 언어를 제공한다. 또한, Spark SQL 모듈을 사용하여 SQL 또는 HiveQL 쿼리를 Apache Spark에 제출할 수 있다. 애플리케이션을 실행하는 것 외에도, Apache Spark API를 Python과 대화식으로 사용하거나 클러스터의 Apache Spark 셸에서 Scala를 직접 사용할 수 있다. Zeppelin을 사용하여 데이터 탐색과 시각화를 위한 대화형 협업 노트북을 생성할 수도 있다.

- **다양한 워크플로 생성:** Apache Spark에는 기계 학습(MLlib), 스트림 처리(Spark Streaming) 및 그래프 처리(GraphX)용 애플리케이션을 구축하는 데 도움이 되는 몇 가지 라이브러리가 포함되어 있다. 이러한 라이브러리는 Apache Spark 에코시스템과 긴밀하게 통합되며, 다양한 사용 사례를 해결하는 데 바로 활용할 수 있다.

---