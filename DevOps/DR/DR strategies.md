
DR(재해 복구)은 비즈니스 연속성 계획의 핵심 요소이다. 재해에 대비하고 복구하는 과정인 DR을 위해 어떻게 아키텍처를 설계할 수 있을까?

재해 이벤트는 워크로드를 중단시킬 수 있기 때문에, DR의 목표는 워크로드를 다시 가동하거나 다운타임을 완전히 방지하는 것이어야 한다. 이를 위해 다음과 같은 목표 지표를 사용한다:

- **Recovery Time Objective (RTO)**: 서비스 중단부터 서비스 복원까지 허용 가능한 최대 지연 시간이다. 허용 가능한 서비스 다운타임 길이를 결정한다.
- **Recovery Point Objective (RPO)**: 마지막 데이터 복구 시점 이후 허용 가능한 최대 시간이다. 허용 가능한 데이터 손실량을 결정한다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/662360ab-2732-42a6-9043-13683496de51)

RTO와 RPO는 숫자가 낮을수록 다운타임과 데이터 손실이 적다는 것을 의미한다. 그러나 RTO와 RPO를 낮추려면 리소스 비용과 운영 복잡성 측면에서 더 많은 비용이 든다. 따라서 워크로드에 적절한 가치를 제공하는 RTO와 RPO 목표를 선택해야 한다.

## DR 전략

## Backup and Restore

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/eddbe7fb-1f4b-42e5-952b-c4975693ee08)

- 우선순위가 낮은 사용 사례에 적합
- 이벤트 발생 후 모든 AWS 리소스를 프로비저닝
- 이벤트 발생 후 백업을 복원

백업은 소스와 동일한 리전에 생성되며 다른 리전으로도 복사된다. 이를 통해 모든 범위의 재해로부터 가장 효과적인 보호를 제공한다.

백업 및 복구 전략은 RTO 측면에서 가장 비효율적인 것으로 간주된다. 그러나 Amazon EventBridge와 같은 AWS 리소스를 사용하여 서버리스 자동화를 구축하면 감지 및 복구를 개선하여 RTO를 줄일 수 있다.

## Pilot Light

<img width="755" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/e40ffc10-6d7d-45d5-a113-0591daf76c41">

- 데이터는 활성 상태
- 서비스는 유휴 상태
- 이벤트 발생 후 일부 AWS 리소스를 프로비저닝하고 확장

Pilot Light 전략에서는 데이터는 활성 상태이지만 서비스는 유휴 상태이다.

- 활성 데이터란 데이터 저장소와 데이터베이스가 활성 리전과 최신 상태(또는 거의 최신 상태)로 유지되어 읽기 작업을 처리할 준비가 되어 있음을 의미한다.

그러나 모든 DR 전략과 마찬가지로 백업도 필요하다. 데이터를 삭제하거나 손상시키는 재해 이벤트의 경우, 이러한 백업을 통해 마지막으로 알려진 정상 상태로 "되감기"할 수 있다.

## Warm Standby

<img width="748" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/24ab88d8-88f0-45be-9b6b-3a102d0af317">

- 항상 실행 중이지만 규모가 작음
- 비즈니스에 중요한 워크로드에 적합
- 이벤트 발생 후 AWS 리소스 확장

Pilot Light 전략과 마찬가지로 Warm Standby 전략도 주기적인 백업 외에 활성 데이터를 유지한다. 두 전략의 차이점은 인프라와 그 위에서 실행되는 코드이다.

Warm Standby는 요청을 처리할 수 있는 최소 배포를 유지하지만 용량이 감소된 상태이다. 즉, 프로덕션 수준의 트래픽을 처리할 수 없다.

## Multi-site Active/Active

<img width="762" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/17750286-da68-46cf-9257-b2819be5f474">

Multi-site Active/Active에서는 두 개 이상의 리전이 적극적으로 요청을 수락한다.

장애 조치는 요청을 처리할 수 없는 리전에서 요청을 다른 곳으로 라우팅하는 것으로 구성된다.

여기서 데이터는 리전 간에 복제되며 해당 리전에서 읽기 요청을 처리하는 데 적극적으로 사용된다. 쓰기 요청의 경우 로컬 리전에 쓰기 또는 특정 리전으로 쓰기를 재라우팅하는 등 여러 패턴을 사용할 수 있다.

---
참고

- <https://aws.amazon.com/ko/blogs/architecture/disaster-recovery-dr-architecture-on-aws-part-i-strategies-for-recovery-in-the-cloud/>
- <https://aws.amazon.com/ko/blogs/architecture/disaster-recovery-dr-architecture-on-aws-part-iii-pilot-light-and-warm-standby/>
