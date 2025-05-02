- Bloom Filter는 1970년 Burton Howard Bloom에 의해 고안된 공간 효율적인 확률적 데이터 구조로서, 어떤 요소가 집합에 속하는지를 테스트하는 데 사용된다.
- 이 구조의 핵심적인 특징은 false positive가 발생할 수 있지만, false negative는 발생하지 않는다는 점이다. 즉, Bloom Filter는 주어진 쿼리에 대해 "집합에 포함되어 있을 수도 있음" 또는 "집합에 확실히 포함되어 있지 않음" 중 하나의 결과를 반환한다.
- 충분한 메모리가 있다면 오류 없는 인덱스 해시를 사용할 수 있지만, 메모리가 제한적일 경우 Bloom Filter를 사용하는 것 만으로도 대부분의 디스크 접근을 불필요하게 만들 수 있다.

- Bloom Filter는 add only이고, 삭제 기능이 필요한 경우 Counting Bloom Filter와 같은 변형을 사용해야한다. 변형 알고리즘에선 요소가 필터에 많이 추가될수록 false positive가 발생할 확률은 점점 증가한다.

- 평균적으로 원소 하나당 약 10비트 미만의 공간만으로도 1%의 false positive 확률을 유지할 수 있고, 집합의 크기나 요소의 개수에 관계없이 비슷한 정확도를 유지한다. 이처럼 Bloom Filter는 낮은 오차를 감수하는 대신 메모리 사용량을 획기적으로 줄여주는 방식으로 동작한다.

## 동작 방식

1. 빈 Bloom Filter는 길이가 `m`인 비트 배열로 구성되며, 처음엔 모든 비트가 0으로 초기화된다.

    - 이 필터에는 서로 독립적인 `k`개의 해시 함수가 존재하며, 각 해시 함수는 입력된 요소를 `m`개의 가능한 인덱스 중 하나로 매핑한다.
    - 삽입 시에는 각 해시 함수로부터 도출된 인덱스의 비트를 모두 1로 설정한다.

2. 어떤 요소가 집합에 속하는지를 확인하려면, 해당 요소를 각 해시 함수에 넣어 인덱스를 얻고, 이 인덱스에 해당하는 비트들이 모두 1인지 확인한다.

3. 0이 하나라도 있으면 그 요소는 "확실히 집합에 없다"고 판단한다. 모든 비트가 1이면 그 요소는 "있을 수도 있다"는 응답을 하게 되며, 이 경우 false positive가 발생할 수 있다.

![image](https://github.com/user-attachments/assets/8b251bee-4697-4b3f-a340-e3701113ed72)

## 활용 예시

- **Akamai**: 1회만 요청되는 웹 오브젝트(one-hit-wonder)를 캐시하지 않기 위해 Bloom Filter를 사용. 2회 이상 요청된 오브젝트만 디스크에 캐시하여, 디스크 접근을 절반 이상 줄이고 전체 캐시 효율을 향상.
- **Google Bigtable / HBase / Cassandra / ScyllaDB**: SSTable 또는 ColumnFamily 단위로 Bloom Filter를 저장하여, 존재하지 않는 row나 column에 대해 디스크 접근을 방지함으로써 데이터베이스 성능을 크게 향상.
- **Grafana Tempo**: 각 백엔드 블록에 대해 Bloom Filter를 저장하여 trace ID에 대한 빠른 필터링을 제공.
- **PostgreSQL**: 다중 열 인덱스에서 Bloom Index를 제공, 특정 필드 조합이 존재하는지를 빠르게 판단.

## 주의사항

- Bloom Filter는 false positive를 완전히 제거할 수 없으므로, **정확성이 중요한 로직에서는 보조 수단**으로만 사용해야 한다.
- 예상되는 요소 수 `n`과 허용 가능한 false positive 비율 `ε`에 따라 비트 배열 크기 `m`과 해시 함수 수 `k`를 적절히 조정해야 한다.
- 요소가 일정 주기를 넘어서거나 너무 많이 삽입되면 false positive 확률이 급격히 증가하므로, Bloom Filter를 **회전하거나 재생성하는 정책**이 필요하다.
- 요소 삭제가 필요한 경우 아래 같은 대안을 사용할 수 있다.
  - [Counting Bloom Filter](https://en.wikipedia.org/wiki/Counting_Bloom_filter):
    - 비트를 단순히 0 또는 1로 유지하는 대신, 각 위치에  비트 카운터를 사용한다.
    - 삽입 시 해당 위치의 값을 증가시키고, 삭제 시 감소시켜서 요소의 제거를 가능하게 한다.
  - [Cuckoo Filter](https://en.wikipedia.org/wiki/Cuckoo_filter):
    - Cuckoo 해싱의 원리를 기반으로 하여 삭제를 지원하면서도 Bloom Filter와 유사한 성능을 제공한다.
  - [Xor Filter](https://lemire.me/blog/2019/12/19/xor-filters-faster-and-smaller-than-bloom-filters):
    - 모든 항목을 미리 알고 있을 때 사용할 수 있는 구조로, 항상 세 개의 해시 함수만으로 일정한 오탐률을 유지한다.

---
참고

- <https://en.wikipedia.org/wiki/Bloom_filter>
- <https://medium.com/@kennyrich/what-is-bloom-filter-28ce4318d606>
- <https://brilliant.org/wiki/bloom-filter/>
