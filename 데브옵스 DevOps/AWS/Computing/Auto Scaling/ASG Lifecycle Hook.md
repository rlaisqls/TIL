
ASG를 통해 생성되는 인스턴스들은 아래와 같은 Lifecycle을 가지고 있다.

<img src="https://github.com/rlaisqls/rlaisqls/assets/81006587/06239a07-4f7a-495f-8419-634406b4a63a" height=300px>

https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html

- ASG가 인스턴스를 증가시키는 이벤트는 Scale out 이벤트이며, 이 때는 `Pending` 상태가 된다.
- 인스턴스가 부트스트랩 과정을 마치고 나면 `InService` 상태가 된다.
- 인스턴스가 축소되는 이벤트는 Scale in 이벤트이며, `Terminating` 상태를 거쳐 `Terminated` 상태가 된다.

ASG의 Lifecycle Hook은 이 과정 중 Scale in과 Scale out 과정에 설정할 수 있다. 먼저 Scale out 이벤트에 걸게 된다면 인스턴스는 `Pending` 이후에 `Pending:Wait` 상태와 `Pending:Proceed` 상태를 거치게 되고, Scale in 이벤트에 걸게 된다면 인스턴스는 `Terminating:Wait` 상태와 `Terminating:Proceed` 상태를 거치게 된다.  

그렇기 때문에 인스턴스가 생성된 후 부트 스트랩 이후에 뭔가 추가적으로 작업해야 할 것이 있다면 `EC2_INSTANCE_LAUNCHING` 이벤트에, 인스턴스가 삭제될 때 추가적으로 작업해야 할 것이 있다면 `EC2_INSTANCE_TERMINATING` 이벤트에 Lifecycle Hook을 설정해주면 된다. 

## ASG Lifecycle Hook의 처리 순서

ASG의 Lifecycle Hook 이벤트는 Cloudwatch Event Bridge, SQS, SNS 등을 통해서 전달받을 수 있다.

![image](https://github.com/rlaisqls/TIL/assets/81006587/6fb2cd39-44db-4e70-be30-3d17e9f99aab)

ASG에서 설정한 Lifecycle 이벤트가 발생하면 Cloudwatch Event Bridge (이하 Event Bridge)를 통해 이벤트가 생성되고 Lambda 함수가 실행된다. 실행된 Lambda 함수는 SSM의 Run Command를 이용해서 Lifecycle 이벤트의 대상이 된 인스턴스에 주어진 명령을 실행한다. 그리고 정상적으로 실행이 완료되면 Lambda 함수가 ASG 에게 Lifecycle Hook에 의해 진행된 작업이 완료되었음을 알려준다. 

## 실습

EC2_INSTANCE_TERMINATING 이벤트에 Lifecycle Hook을 설정해서 인스턴스가 삭제되기 전에 애플리케이션이 확실하게 종료될 수 있도록 구성해보자.

### Lambda

이벤트시 실행 된 Lambda 코드를 짜보자. AWS 세션을 획득한 후 EventBridge를 통해 전달받은 이벤트를 확인하고 애플리케이션을 중지시키도록 SSM의 Run Command를 호출 한 뒤 Lifecycle Hook Action이 완료되었음을 알리는 중심 코드이다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/3d0cc6ca-6a8f-41e4-9c61-300892b95c2e" height="200px">

또 핵심이 되는 부분 중에 하나는 EventBridge를 통해 전달받은 이벤트를 함수 내부에서 사용할 수 있도록 구조체로 변경하는 부분이다. 그리고 이 이벤트는 TerminationDetail 이라는 구조체로 정의되어 있다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/96fd7ce2-5a37-4514-b4fe-3735bcaea0f5" height="100px">

이렇게 이벤트의 내용을 구조체로 변환한 다음 `stopApplication` 이라는 함수를 호출한다. 이 함수는 아래와 같이 구성되어 있다. 

`stopApplication` 함수는 크게 두 부분으로 나뉘어 있다. 먼저 SSM RunCommand를 호출하는 부분과 호출된 RunCommand가 정상적으로 종료되었는지를 확인하는 부분이다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/abafdaf2-082e-4340-82bc-30ca39e7478d" height="200px">

ASG의 Lifecycle 대상이 된 인스턴스 ID와 실행해야 하는 명령을 인자로 넘겨주어서 AWS-RunShellScript 방식으로 RunCommand를 실행한다. 이때 넘겨주는 명령은 `systemctl stop application` 이라는 명령이다. 그럼 인스턴스는 종료되기 전에 `systemctl stop application` 이라는 명령을 실행하고, 애플리케이션을 정상적으로 종료할 수 있게 된다. 

<img src="https://github.com/rlaisqls/TIL/assets/81006587/8f58b19c-3ffc-413c-8932-90a705233f97" height="400px">

그리고 생성된 RunCommand가 정상적으로 종료되었는지를 확인한다. RunCommand가 실행되고 API를 통해 상태를 확인하기 위해서는 약간의 시간이 소요되기 때문에 강제로 Sleep을 주어 텀을 줘야한다.

### serverless를 이용한 배포

Lambda 함수를 만들었으니 [serverless](https://www.serverless.com/) 프레임워크를 사용해 배포해 보자.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/c9758380-7964-4f91-9dc5-c207107ffca8" height="300px">

함수의 이름은 asg-termination-handler라고 지어준다. `serverless.yml` 파일의 핵심은 EventBridge를 정의하기 위한 하단 events 부분이다. event 하단에 있는 `source`와 `detail-type`은 이미 정의되어 있는 부분이기 때문에 동일하게 맞춰 주어야 한다.

만약 Scale in이 아닌 Scale out시에 걸고 싶으면 detail-type을 EC2 Instance-launch Lifecycle Action로 변경해 주면 된다. 또한 Lifecycle Hook을 처리하기 위한 Lambda 함수는 일반적인 Lambda 함수 실행 권한 외에도 ASG와 SSM과 관련된 권한이 더 필요하다. 그래서 롤을 먼저 만들어 준 다음에 `serverless.yml` 파일에 role을 명시해서 추가해 준다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/60773c40-b819-4f89-a24d-c78eb7044a6c" height="200px">

이후 serverless 프레임워크로 배포하면 Lifecycle Hook 이벤트를 받아서 처리하기 위한 준비는 끝난다.

### ASG에 Lifecycle Hook 설정하기

이제 마지막으로 ASG에 Lifecycle Hook 을 설정한다. AWS 콘솔에서 EC2 -> Auto Scaling Gropus -> Instance Management 탭에 들어가면 아래와 같이 Lifecycle hooks를 설정할 수 있는 콘솔이 나온다.

![image](https://github.com/rlaisqls/TIL/assets/81006587/43e55c6e-ab3b-4f58-b19d-be00eb528573)

Create lifecycle hook 버튼을 클릭하면 아래와 같은 입력창이 나온다. 우리가 구현한 것은 Scale in 시의 작업이기 때문에 이름은 자유롭게 지어주되 Lifecycle transition만 Instance terminate로 설정해준다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/f557bfd7-d515-419f-8437-1c70dafaa70c" height=400px>

Heartbeat timeout은 Lifecycle Hook Action 의 유지 시간인데, 앞에서 언급했던 것처럼 completion 처리를 별도로 해주지 않으면 액션 처리를 위한 람다 함수가 종료되고도 Heartbeat timeout에 설정한 시간만큼 기다리게 된다. 만약 Lifecycle Hook 이벤트를 받은 후 진행하는 작업이 오래 걸린다면 충분히 크게 주어서 안정적으로 진행되도록 해주어야 한다. 이 값의 최대 값은 7200초이다.

설정이 완료된 후 ASG를 통해서 Scale in 해 보면 아래와 같이 인스턴스들이 `Terminating:Waiting` 상태를 거쳐 `Terminating:Proceed` 상태로 변경되는 것을 볼 수 있다.

<img width="376" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/fd79bc0c-8fdb-40f1-8957-9f202fdd7efe">

<br>

<img width="376" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/583af32a-9128-419f-a0bd-8881e4a8b493">

<br>

<img width="376" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/4e6dfcee-2541-4fe9-942a-a11b163a6a49">

그리고 SSM의 RunCommand 콘솔로 가보면 아래와 같이 정상적으로 RunCommand가 실행된 것도 볼 수 있다.

<img width="699" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/a0a683fa-eae6-44e6-9baa-82cfee19f7fa">

## 마무리

Lifecycle Hook은 ASG에 의해 인스턴스가 늘어나거나 줄어들 때 이벤트를 발생시켜서 사용자가 별도의 원하는 작업을 수행할 수 있게 해준다. Heartbeat timeout 이내에 가능한 작업이라면 인스턴스의 데이터를 다른 곳으로 옮긴다거나 하는 형태의 복잡한 작업도 가능하다. 

ASG의 기본 기능으로만으로는 유연한 인프라를 구성하는 것에 부족함을 느낀다면 Lifecycle Hook을 사용해보자.

---
참고
- https://docs.aws.amazon.com/autoscaling/ec2/userguide/lifecycle-hooks.html
- https://docs.aws.amazon.com/autoscaling/ec2/userguide/configuring-lifecycle-hook-notifications.html)