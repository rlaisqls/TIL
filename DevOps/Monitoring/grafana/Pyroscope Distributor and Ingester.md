<img width="330" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/37fb9cc1-8767-4f68-aa27-77b46583650b">

## Distributor

- Distributor는 **Agent로부터 프로파일링 데이터를 받아 처리하는 Stateless 컴포넌트**이다.

- Distributor는 데이터를 일괄 처리하여 여러 Ingesters에 병렬로 보내고, 시리즈를 Ingesters 사이에 나누며, 각 시리즈를 구성된 복제 요소에 따라 복제한다. 기본적으로 구성된 복제 요소는 세 개이다.

#### 유효성 검사

- Distributor는 데이터를 Ingester에 전달하기 전에 유효성을 검사, 변환 절차를 거친다. 

- 데이터 중 일부 샘플만 유효하다면 유효한 데이터만 Ingester에 전달하고, 유효하지 않은 데이터는 Ingesters에 보내지지 않는다. 요청에 유효하지 않은 데이터가 포함되어 있으면 Distributor는 Bad Request 코드인 400을 반환하고 상세 내용을 응답 Body에 반환한다.

- Distributor에서는 다음과 같은 데이터 변환 과정을 거친다.

  - 프로필에 타임스탬프가 설정되어 있는지 확인하고, 설정되어 있지 않으면 Distributor가 프로파일을 수신한 시간으로 설정한다.
  - 값이 0인 샘플을 제거한다.
  - 동일한 스택 트레이스를 공유하는 샘플은 합친다.

#### 복제

- Distributor는 Ingesters 사이에 들어오는 시리즈를 분할하고 복제한다.

- 각 시리즈가 쓰여지는 Ingesters의 수를 구성할 수 있다. 기본적으로 `-distributor.replication-factor` 플래그를 통해 1로 설정된다.
  
- Distributor는 일관된 해싱을 사용하여 지정된 시리즈를 수신하는 Ingesters를 결정하기 위해 구성 가능한 복제 요소와 함께 사용된다.

- 샤딩 및 복제는 Ingesters의 해시 링을 사용한다. 각 들어오는 시리즈에 대해, Distributor는 프로필 이름, 레이블 및 테넌트 ID를 사용하여 해시를 계산한다.

- 계산된 해시는 토큰이라고하며, Distributor는 토큰을 해시 링에서 찾아 시리즈를 어느 Ingesters에 쓸지 결정한다.

- 해시 링에 대한 자세한 내용은 [여기](https://grafana.com/docs/pyroscope/latest/reference-pyroscope-architecture/hash-ring/)에서 확인할 수 있다.

#### 쿼럼 일관성

- Distributor가 동일한 해시 링에 액세스를 공유하기 때문에, 어떤 Distributor에게든 쓰기 요청을 보낼 수 있다. 상태를 가지지 않는 로드 밸런서도 설정할 수 있다.

- 일관된 쿼리 결과를 보장하기 위해 Pyroscope는 읽기 및 쓰기에 대해 다이나모 스타일의 쿼럼 일관성을 사용한다.
   
- Distributor는 에이전트 푸시 요청에 성공적인 응답을 보내기 전에 구성된 복제 요소 n의 `n/2 + 1` Ingesters로부터 성공적인 응답을 기다린다.

## Ingester

- Ingester는 **입력 프로파일을 먼저 디스크에 저장하고 쿼리를 위한 시리즈 샘플을 반환하는 Stateful 컴포넌트**이다.

- Distributor로부터 들어오는 프로파일은 즉시 장기 저장소에 기록되지 않고, Ingester의 메모리에 유지되거나 Ingester의 디스크에 비동기로 기록된다. 
  - Ingesters가 수신된 샘플을 바로 장기 저장소에 기록하면 장기 저장소에 대한 I/O 트래픽이 자주 발생하여 시스템 확장이 어려울 것이다. 따라서 Pyroscope의 Ingesters는 메모리에 샘플을 일괄로 처리하고 압축하고 주기적으로 장기 저장소에 업로드한다.

- 결국 모든 프로파일은 디스크에 기록되고 주기적으로 장기 저장소에 업로드된다. 이러한 이유로 쿼리를 실행하는 동안 쿼리어가 읽기 경로에서 Ingesters 및 장기 저장소에서 샘플을 가져올 수 있다.

- Ingesters를 호출하는 Pyroscope 컴포넌트는 해시 링에 등록된 Ingesters를 찾아 사용할 수 있는지 확인한다. 각 Ingester는 다음 중 하나의 상태를 가진다.

  - `PENDING`: Ingester가 방금 시작된 상태이다. 이 상태에서는 Ingester가 쓰기 또는 읽기 요청을 받지 않는다.
  - `JOINING`: Ingester가 시작되고 링에 참여한다. 이 상태에서는 Ingester가 쓰기 또는 읽기 요청을 받지 않는다.
    Ingester는 디스크에서 토큰을 로드한다 (만약 -ingester.ring.tokens-file-path가 구성되어 있으면) 또는 새로운 임의 토큰 세트를 생성한다. 마지막으로 Ingester는 선택적으로 토큰 충돌을 관찰하고 해결되면 ACTIVE 상태로 이동한다.
  - `ACTIVE`: Ingester가 작동 중인 상태이다. 이 상태에서는 Ingester가 쓰기 및 읽기 요청을 모두 받을 수 있다.
  - `LEAVING`: Ingester가 종료되고 링을 떠난다. 이 상태에서는 Ingester가 쓰기 요청을 받지 않지만 읽기 요청은 계속 받을 수 있다.
  - `UNHEALTHY`: Ingester가 해시 링에 하트 비트를 보내지 못했다. 이 상태에서는 Distributor가 Ingester를 우회하므로 Ingester는 쓰기 또는 읽기 요청을 받지 않는다.

- Ingesters의 해시 링을 설정하는 방법은 [이 링크](https://grafana.com/docs/pyroscope/latest/configure-server/configuring-memberlist/)를 참고할 수 있다.

#### Replication

- Ingester 프로세스가 충돌하거나 갑작스럽게 종료되면 아직 장기 저장소에 업로드되지 않은 모든 메모리 내 프로파일이 손실될 수 있다. 이러한 손실를 완화하기 위해 Pyroscope는 Replication를 구현한다.

- 각 프로파일 시리즈는 기본적으로 세 개의 Ingesters로 복제된다.
  
- Pyroscope 클러스터에 쓰기가 성공하려면 데이터를 받은 과반수의 Ingesters로부터 쿼럼을 받아야 한다. 

- Pyroscope 클러스터가 Ingester를 하나 잃어도 잃어진 Ingester의 헤드 블록에 보유된 메모리 내 프로파일은 적어도 다른 하나의 Ingesters에 남아있을 것이다. 따라서 단일 Ingester에 장애가 생겨도 프로파일이 손실되지 않는다. 

- 하지만 여러 Ingester가 실패하는 경우 특정 프로파일 시리즈의 복제본을 보유하는 모든 Ingester에 장애가 발생하는 경우 프로파일이 손실될 수 있다.
  
---
참고
- https://grafana.com/docs/pyroscope/latest/reference-pyroscope-architecture/components/
- https://grafana.com/docs/pyroscope/latest/reference-pyroscope-architecture/components/distributor/
- https://grafana.com/docs/pyroscope/latest/reference-pyroscope-architecture/components/ingester/
