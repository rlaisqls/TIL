> <https://github.com/deepflowio/deepflow/blob/main/docs/deepflow_sigcomm2023.pdf>

DeepFlow는 복잡한 클라우드 인프라와 클라우드 네이티브 애플리케이션에 대한 심층 관찰성을 제공하도록 설계된 observability product 이다.

## Network-Centric Tracing Plane

### ingress-egress와 enter-exit 두 가지 함수 세트를 가진 narrow-waist instrumentation 모델

DeepFlow는 10개의 시스템 콜 ABI를 계측하고 이를 ingress 또는 egress로 분류한다. DeepFlow는 각 ingress 또는 egress 호출이 커널에 들어가거나(enter) 나올 때(exit) 정보를 저장한다.

유저 공간에서 추가 처리를 위해 네 가지 범주의 정보가 기록된다:

1. 프로그램 정보: 프로세스 ID, 스레드 ID, 코루틴 ID, 프로그램 이름 등
2. 네트워크 정보: DeepFlow가 할당한 전역 고유 소켓 ID, five-tuple, TCP 시퀀스 등
3. 트레이싱 정보: 데이터 캡처 타임스탬프, ingress/egress 방향 등
4. 시스템 콜 정보: read/write 데이터의 총 길이, DeepFlow 에이전트로 전송될 페이로드 등

### 커널 내 훅 기반 계측

사전 정의된 instrumentation 모델에 따라, DeepFlow는 자동으로 훅을 등록해서 trace 데이터를 수집한다.

<img width="484" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/1bbbd90b-6df2-4e54-ab90-37a6a1dd1266">

- 메시지 ingress(➀) 또는 egress(➁)에 대해, 해당 시스템 콜은 커널에 들어갈 때(➃)와 나올 때(➄) 등록된 kprobe 또는 tracepoint 훅을 트리거한다.
- 트레이싱 프로세스는 인자를 가져오고(➆), 커널이 처리를 완료할 때까지 기다린 다음, 반환 결과를 가져온다(➇).
- 예비 파서(➈)는 주요 데이터를 통합해서 버퍼(➉)에 넣고, 이후 유저 공간으로 전송해 추가 처리를 진행한다.
- 추가로 DeepFlow는 uprobes와 uretprobes를 사용해서 컴포넌트 로직(➂) 내의 확장된 instrumentation 포인트에서 정보를 추출한다(➅).
- 이 모든 작업은 자동으로 수행된다. 사용자는 코드 수정 없이 분산 트레이싱을 수행할 수 있다.

## 암묵적 컨텍스트 전파 (Implicit Context Propagation)

기존 분산 트레이싱 프레임워크는 소스 코드나 직렬화 라이브러리를 수정해서 메시지의 헤더나 페이로드에 컨텍스트 정보를 명시적으로 삽입한다.

DeepFlow의 핵심 인사이트는 **컨텍스트 전파에 필요한 정보가 이미 네트워크 관련 데이터에 포함되어 있다**는 것이다. 각 네트워크 레이어의 데이터를 최대한 활용함으로써, DeepFlow는 메시지 내에 컨텍스트 정보를 명시적으로 포함할 필요가 없다.

그렇다면 DeepFlow는 어떻게 완전한 trace를 만들어낼까?

커널에서 수집한 데이터는 각각 독립적이고 단편적이다. 개별 시스템 콜 하나하나의 정보일 뿐이다. DeepFlow는 이런 흩어진 조각들을 모아서 요청의 전체 흐름을 보여주는 완전한 trace로 만든다. 각 조각 사이의 인과 관계를 정확히 파악해서 연결하는 것이다.

이 과정은 두 단계로 나뉜다:

### 1. instrumentation 데이터로부터 span 구성

DeepFlow는 항상 요청으로 시작하고 응답으로 끝나는 span을 생성한다.

<img width="487" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/093a9b43-0596-4859-a91d-d60ff4f9923f">

**시스템 콜의 enter와 exit 연결**

먼저 DeepFlow는 프로세스 ID와 스레드 ID를 사용해서 동일한 시스템 콜의 enter와 exit 시 캡처된 정보를 연결한다. 커널은 주어진 (𝑃𝑟𝑜𝑐𝑒𝑠𝑠_𝐼𝐷, 𝑇h𝑟𝑒𝑎𝑑_𝐼𝐷)에 대해 동시에 하나의 선택된 시스템 콜만 처리할 수 있다는 사실에 기반한다.

결합된 데이터는 메시지 데이터라고 하며, 캡처된 시스템 콜의 타입에 따라 ingress 또는 egress로 분류된다. 전송되는 데이터 양을 줄이기 위해, 메시지의 첫 번째 시스템 콜만 처리하고 추가 데이터 전송에 사용되는 후속 시스템 콜은 처리하지 않는다.

> Golang 같은 언어의 경우, DeepFlow는 코루틴 생성을 모니터링해서 부모-자식 코루틴 관계를 의사 스레드 구조에 저장하고 유사한 작업을 수행한다. DeepFlow는 enter 파라미터를 해시맵에 임시 저장하고, exit 시점에 가져와서 exit 파라미터와 결합한다.

> deep packet inspection은 불가피하지만, 오픈소스 프로젝트인 DeepFlow는 일반적으로 패킷 헤더에서만 정보를 추출하고 주로 페이로드에 위치한 민감한 사용자 데이터는 검사하지 않는다.

**파이프라인에서 메시지 대응**

DeepFlow는 파이프라인에서 메시지 간의 정확한 대응을 보장한다. 병렬 프로토콜을 사용하는 경우, 요청과 응답의 순서를 매칭하거나 메시지에 포함된 구별 속성(DNS 헤더의 ID, HTTP/2 헤더의 stream identifier 등)을 활용한다.

**시간 윈도우 배열**

DeepFlow는 시간 윈도우 배열을 구현하고 타임스탬프에 따라 메시지를 저장한다. 집계할 때는 같은 시간 슬롯이나 인접한 슬롯의 메시지만 쿼리한다. (DeepFlow는 현재 각 시간 슬롯의 지속 시간을 60초로 설정한다)

<img width="476" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/996c4f1b-1835-4d6f-bfad-9dd8c9f6745c">

### 2. 암묵적 인과 관계를 사용해 span으로부터 trace 조립

DeepFlow는 사용자가 쿼리하는 span을 시작점으로 삼아 연관된 span들을 병합한다. 동시에 컴포넌트 내부 및 컴포넌트 간 연결과 서드파티 span 통합을 통해 교차 레이어 상관관계를 지원한다.

**스레드 ID를 사용한 span 연결**

DeepFlow는 스레드 ID를 사용해서 동일한 스레드 내의 span을 연결한다. Golang의 코루틴의 경우, DeepFlow는 코루틴 간의 호출 관계를 추적해서 연결을 수행할 수 있다.

<img width="487" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/902f939e-c8ac-4a63-859d-7c1af74b886c">

스레드가 재사용되면 trace는 시간 순서에 따라 분할된다.

**여러 요청이나 응답 관리**

DeepFlow는 여러 요청이나 응답을 관리한다. 단일 스레드에서 컴퓨팅은 네트워크 통신과 달리 스케줄링을 위해 일시 중지되지 않는다. 따라서 다른 타입이고 다른 소켓에서 온 연속된 두 메시지에 동일한 systrace_id를 할당한다.

**TCP 시퀀스를 활용한 컴포넌트 간 연결**

네트워크 전송(레이어 2/3/4 포워딩)은 TCP 시퀀스를 변경하지 않으므로, DeepFlow는 이를 컴포넌트 간 연결에 활용한다. instrumentation 단계에서 커널의 각 메시지에 대한 TCP 시퀀스를 계산하고 기록한다. 그런 다음 이를 사용해서 동일한 플로우 내의 span들의 컴포넌트 간 연결을 구별하고 유지한다.

## Trace 조립

아래 알고리즘은 trace 조립의 최종 단계를 보여준다.

<img width="483" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/cecf17ab-7965-4fbf-a5a6-6c1725158ce9">

각 반복에서, 현재 span들과 다음을 공유하는 새로운 span들을 span 세트에 추가한다:

- systrace_id (Line 6)
- 의사 스레드 ID (Line 7)
- X-Request-ID (Line 8)
- TCP 시퀀스 (Line 9)
- trace ID (Line 10)

연속된 두 검색 간에 관련 span의 수가 증가하지 않으면 검색이 종료된다 (Lines 13-14).

알고리즘의 두 번째 단계에서는 span 세트를 반복하며 부모 span을 설정한다. 부모 span의 결정도 앞서 언급한 컴포넌트 내부 및 컴포넌트 간 연결을 기반으로 하지만 더 엄격한 조건을 적용한다.

- 수집 위치(서버 또는 클라이언트), 시작 시간과 종료 시간, span 타입, 메시지 타입에 따라 16개의 규칙이 설정되었다 (Line 20).
- 예를 들어, 클라이언트 측에서 수집된 eBPF span이 서버 측에서 수집된 eBPF span과 동일한 TCP 시퀀스를 가지면, 클라이언트 측 span의 부모는 서버 측 span으로 설정된다.

마지막으로 시간과 부모 관계에 따라 span 세트를 정렬해서 (Line 25) 표시하기 좋은 trace를 생성하고 프론트엔드로 전송한다.

## 태그 기반 상관관계 (Tag-Based Correlation)

코드 수정 없이 교차 컴포넌트 상관관계를 달성하기 위해, DeepFlow는 span에 균일한 태그를 주입한다.

DeepFlow는 Kubernetes 리소스 태그(예: node, service, pod 등), 사용자 정의 레이블(예: version, commit-ID 등), 클라우드 리소스 태그(예: region, availability zone, VPC 등)의 주입을 가능하게 한다.

태깅 오버헤드를 최소화하기 위해, smart-encoding이라는 기법을 도입했다.

<img width="479" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/1759d816-716c-4e63-b345-d9daacf8adff">

**태그 수집 단계**

- 클러스터 내부의 DeepFlow Agent가 Kubernetes 태그를 수집하고(➀) Server로 전송한다(➁)
- 클라우드 리소스 태그는 Server가 직접 수집한다(➂)

**Smart-encoding 단계**

- DeepFlow는 VPC(virtual private cloud) 태그와 IP 태그만 Int 형식으로 trace에 주입한다(➃-➅)
- Server는 VPC/IP 태그를 기반으로 리소스 태그를 Int 형식으로 trace에 주입하고 데이터베이스에 저장한다(➆)

**쿼리 시점**

- DeepFlow Server는 사용자 정의 태그와 리소스 태그 간의 관계를 결정하고, 사용자 정의 태그를 trace에 주입한 다음, 모든 태그가 포함된 trace를 프론트엔드에 업로드한다(➇)

태그 주입 단계를 분할함으로써, DeepFlow는 계산, 전송, 저장 오버헤드를 줄인다.
