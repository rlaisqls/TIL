
<img src="https://github.com/rlaisqls/TIL/assets/81006587/15c7a0f8-26ba-434f-9f6e-de608dd0215f" style="height: 300px"/>

AWS Organization는 AWS 계정 (accounts)을 단일 단위로 통합해 관리할 수 있는 개체이다. Organization 안의 모든 계정을 중앙에서 확인하고 관리할 수 있다. AWS Organizations는 비즈니스의 예산, 보안과 규정 준수 필요 충족에 도움이 되는 계정 관리 및 통합 결제 기능까지 함께 제공한다. 조직의 관리자로서 조직에서 계정을 생성하고 기존 계정을 조직에 초대할 수 있다. 1개의 관리자 계정(management account)과 0개 이상의 멤버 계정(member account)을 갖고 있다. 위 그림에 나타나 있듯이 tree 계층 구조로 OU를 생성할 수 있다. 각 계정(Each Account)을 OU에 포함하거나 루트에 포함할 수 있다. 

#### 루트 (Root)
Organization에서 맨 위에 있는 폴더(컨테이너)이다. 루트에 정책을 적용하면 하위 모든 OU 및 멤버 계정에 적용한다. 

#### OU(Orgazation Unit)
하위 그룹, 또는 sub 폴더와 같은 개념이다. 루트 아래에 OU를 여러개 포함할 수 있다. OU는 하위에 다른 OU를 포함할 수 있다. 한 개의 계정 (account)는 1개 OUI에만 속한다. 

#### 계정 (Account)

AWS 사용자(user)와 리소스를 가진 AWS account를 말한다. Account는 user를 말하는 것이 아니다. Organization 안에는 2개 계정(Account) 유형이 있다.

- 관리 계정 (management account): 계정생성/제거, 다른 계정을 조직에 초대, 조직 안 개체(Root, OU, Account)에 정책 적용. 무엇보다도 모든 계정에서 발생하는 요금을 지불해야 함. 관리 계정은 변경할 수 없음. payer account라고도 함
- 멤버 계정 (member account): 관리 계정이 아닌 나머지 계정(account)

#### 서비스 제어 정책 (SCP)

Organizatio, OU, Account가 실행할 수 있는 권한을 제어한다. 

## Organization 기능

- AWS 계정을 중앙 집중하여 관리
- 모든 멤버 계정에 대해 통합 결제
- 예산, 보안, 규정 준수 충족을 위해 계정을 계층적으로 그룹핑
- 정책 중앙 집중 관리
- 태그 관리 정책
- 자동 백업 정책

### 장점
- 프로그래밍 방식으로 새 account를 생성할 수 있으므로 빠르게 Workload를 확장할 수 있다. 
- OU를 생성하고 OU에 SCP를 적용하여 거버넌스 경계를 만들 수 있다. 
- 중앙에서 여러 계정에 대해 보안 및 감사를 할 수 있다. 
- AWS SSO 및 AD를 통해 권한 관리 및 접근 인증을 간소화할 수 있다. 
- Resource Access Manager(RAM)을 통해 조직안에서 리소스를 공유하여 중복을 줄일 수 있다. 
- 이용료를 한 곳에서 청구받아 지급할 수 있으며, 할인 혜택을 받을 수 있다. 

---
참고
- https://docs.aws.amazon.com/ko_kr/organizations/latest/userguide/orgs_introduction.html
- https://docs.aws.amazon.com/ko_kr/organizations/latest/userguide/orgs_getting-started_concepts.html