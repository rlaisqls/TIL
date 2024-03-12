
<img width="839" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/d6216964-7b4a-4eab-8c34-f21af466f893">

### RI

예약 인스턴스(Reserved Instance)라고 한다. 1년 혹은 3년 동안 EC2 혹은 RDS 인스턴스의 특정 유형을 예약하여 사용하는 방법이다.

예를 들어, `t2.micro` 인스턴스 3개를 1년치 예약한다고 하자. 그럼 1년 동안은 실행 중인 t2.micro 인스턴스 3개에 대해 추가 비용 없이 사용할 수 있다(이미 비용을 지불했기 때문). 즉, 기존 t2.micro 인스턴스를 삭제하고 새로운 t2.micro 인스턴스를 생성해도 새로운 인스턴스는 자동으로 예약 인스턴스에 포함된다.

예약 인스턴스는 3가지 결제 방식을 지원한다.
1. 전체 선결제(All Upfront) - 비용을 모두 선결제, 가장 저렴하다.
2. 부분 선결제(Partial Upfront) - 일부는 선결제, 일부는 선결제 없음(No Upfront)보다 저렴한 가격에 매월 시간당 사용료 지불
3. 선결제 없음(No Upfront) - 온디맨드보다 저렴한 가격에 매월 시간당 사용료 지불

### Savings Plan

RI와 비슷하게 1년 혹은 3년 동안 EC2 인스턴스의 특정 유형(ex. t2.micro)을 예약하여 사용하는 방법이다. 그러나 Savings Plan은 특정 기간에 특정 인스턴스 유형(t2.micro)을 예약하는 것이 아닌 특정 인스턴스 패밀리(t2)를 예약할 수 있다. 인스턴스 패밀리(t2) 안에서 여러 인스터스 크기(micro, small, large, ...)를 사용할 수 있어서 RI 보다 유연하다.

Savings Plan은 세 가지 종류를 제공한다.
1. Compute Savings Plans - 온디맨드 가격의 최대 66%, 여러 지역에 걸쳐 적용 가능, 인스턴스 패밀리에 제한이 없다.
2. EC2 Instance Savings Plans - 온디맨드 가격에 최대 72%, 단일 지역에 적용 가능, 인스턴스 패밀리가 고정이다.(크기는 변경 가능)
3. SageMaker Savings Plans - AWS SageMaker 서비스 사용에 적용된다. 

---
참고
- https://repost.aws/ko/knowledge-center/savings-plans-considerations
- https://aws.amazon.com/ko/savingsplans/compute-pricing/