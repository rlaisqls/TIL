
## CI(Continuous Integration)
- CI는 지속적 통합이라는 뜻으로 여러 명이 하나의 코드에 대해서 수정을 진행해도 지속적으로 통합하면서 충돌 없이 작업, 관리할 수 있음을 의미한다. 
- 또한, 공유 버전 관리 레포지토리에 통합되어 있는 코드에 대해, 자동화된 테스트를 진행하여 통합된 코드에서 생기는 문제를 신속하게 파악하고 해결할 수 있도록 하는 것이 CI의 특징이다.

## CD(Continuous Delivery/Deployment)
<p>CD는 지속적인 제공또는 지속적인 배포를 모두 의미한다. 두 가지 모두 파이프라인의 추가 단계에 대한 자동화를 뜻하지만, 자세한 개념은 다르다.</P>

### 지속적인 제공(Continuous Delivery)
- 지속적인 제공은 개발자들이 애플리케이션에 적용한 변경사항이 버그 테스트를 거쳐 리포지토리에 자동으로 업로드되는 것을 뜻한다. 운영팀은 이 리포지토리에서 애플리케이션을 실시간 환경으로 배포할 수 있기 때문에 개발팀과 비즈니스팀 간의 가시성과 커뮤니케이션 부족 문제를 해결할 수 있다. 지속적인 제공은 최소한의 노력으로 새로운 코드를 배포하는 것을 목표로 한다.  

### 지속적인 배포(Continuous Deployment)
- 지속적인 배포는 개발자의 변경사항을 리포지토리에서 고객이 사용 가능한 프로덕션 환경까지 자동으로 릴리스하는 것을 의미한다 수동으로 배포하는 프로세스를 수행하지 않아도 되기 때문에 배포 과정을 보다 효율적으로 할 수 있다. 

## CI/CD 과정

![image](https://github.com/rlaisqls/TIL/assets/81006587/fe3bdd7a-9dff-42ae-a980-4383300b8fd4)

참고:<br>
<a href="https://www.redhat.com/ko/topics/devops/what-is-ci-cd">redhat CI/CD(지속적 통합/지속적 제공): 개념,방법,장점,구현 과정</a>

<br>
<br>

---

더 알아보기:<br>
CI/CD 툴들 https://ichi.pro/ko/hyeonjae-sayong-ganeunghan-choegoui-ci-cd-dogu-27gaji-194611649728144