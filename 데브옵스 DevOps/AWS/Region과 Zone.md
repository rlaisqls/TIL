# Region과 Zone

AWS resouce는 전세계의 여러 위치에서 호스팅되고 있다. 그리고 내부적으로도 여러 영역으로 나뉘어있다. 그 중 Availability Zone, Local Zone, Wavelength Zones에 대해 알아보자.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/ad0d86d7-b794-47bd-9cb8-fac0c50abe0f)

## Availability Zone

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/f7d32e0e-3b29-44d1-b7b0-5a88825de4c5)

각 Region에는 **Availability Zone**이라고 하는 여러 개의 격리된 위치가 있다. Availability Zone은 Region 내의 서버를 분리 시켜놔서, 일부분이 피해를 입어도 동작시키기 위해 구분해놓은 IDC라고 생각할 수 있다.

ELB를 이용해서 서로 다른 AZ에서도 같은 서비스를 사용가능하게끔 트래픽을 분배시켜준다. 이러한 특징을 가용성이 높다고 표현한다.

### AZ IDs

리소스가 Availability Zone에 분산되도록 하기 위해, AWS는 각 계정에 Availability Zone을 독립적으로 매핑한다. 내 계정에서는 A, B, C로 보이지만 다른 사람의 계정에서는 B, A, C와 같은 식으로 이름이 다르게 붙여져서, 사용자는 `us-east-1a`와 같은 코드를 통해 실제로 어떤 AZ에 저장되어있는지 알 수 없다.

실제 리소스의 AZ 위치를 알고싶다면 식별자인 **AZ ID**를 이용해야한다. 리소스의 physical location이 정해진 시점에 확인할 수 있다. AZ 코드와 다르게 AZ ID는 무조건 하나의 Zone을 가리킨다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/71a69e38-dd99-4dd2-a675-9ac936a6fbed)

```bash
# 특정 region의 az 확인
aws ec2 describe-availability-zones --region region-name
# 모든 region의 az 확인
aws ec2 describe-availability-zones --all-availability-zones
```

## Local Zone

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/e6e3f52e-33ae-4e10-a961-ce952a431421)

[Local Zone](https://aws.amazon.com/ko/about-aws/global-infrastructure/localzones/features/#:~:text=AWS%20Local%20Zones%EB%8A%94%20%EC%BB%B4%ED%93%A8%ED%8C%85,AWS%20%EC%9D%B8%ED%94%84%EB%9D%BC%20%EB%B0%B0%ED%8F%AC%20%EC%9C%A0%ED%98%95%EC%9E%85%EB%8B%88%EB%8B%A4.)은 사용자에게 근접한 지역에서 서비스를 제공할 수 있도록 하는 유형이다.

EC2 인스턴스를 시작할때 Local Zone에서 서브넷을 선택하면 Local Zone은 인터넷에 대한 자체 연결을 가지며 AWS Direct Connect를 지원한다. 따라서 Local Zone에서 생성된 리소스가 매우 짧은 지연 시간의 통신으로 로컬 사용자에게 제공할 수 있다는 이점이 있다.

Local Zone은 지역 코드와 위치를 나타내는 식별자(`us-west2-lax-la`)로 표시된다.

## Wavelength Zones

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/2718b928-dc35-4b42-8a2a-f1d912d7e2f0)

Wavelength는 모바일 기기나 유저의 요청에 엄청나게 낮은 latency로 응답할 수 있도록 한다. Wavelength Zone는 Wavelength infrastructure가 배포되는 캐리어 위치의 격리 구역이다. 

Region에서 VPC를 만들면 VPC에 연결되어있는 Wavelength zone에 subnet이 만들어진다. Wavelength Zone 외에도 VPC와 연결된 모든 Availability Zone 및 Local Zone에 리소스를 생성할 수 있다.

Carrier gateway는 carrier network로부터 온 특정 위치의 inbound 트래픽이나, 서버에서 전송하는 outbound 트래픽을 허용하는 역할을 한다. 외부에서 Wavelength Zone에 접근하려면 무조건 carrier gateway를 거쳐야한다. Carrier gateway는 Wavelength Zone 안에 있는 subnet을 포함한 VPC에서만 사용할 수 있다. 여러 Wavelength zone을 묶어주고 서로 원격통신할 수 있도록 해준다.

> Wavelength deploys standard AWS compute and storage services to the edge of telecommunication carriers' 5G networks. Developers can extend a virtual private cloud (VPC) to one or more Wavelength Zones, and then use AWS resources like Amazon EC2 instances to run applications that require ultra-low latency and a connection to AWS services in the Region.

<img width="960" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/d3ada84b-19e4-4698-b109-d601f26690d2">

## Outposts

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/43d365e3-1d1f-4518-b748-64e69b750c61)

Outpost는 사용자의 premise 서버를 AWS의 서비스나 API를 사용하여 확장할 수 있게 하는 기능이다. 

AWS Outposts는 AWS 관리 인프라에 대한 로컬 액세스를 제공하여 고객이 AWS에 서버를 둔 것과 동일한 프로그래밍 인터페이스를 사용하여 사내에서 애플리케이션을 구축하고 실행할 수 있게 한다. 그리고 지연 시간과 로컬 데이터 처리 요구사항을 줄이기 위해 AWS의 로컬 컴퓨팅 및 스토리지 리소스를 사용할 수 있도록 지원한다.

아래 그림은 `us-west-2`의 Availability zone 두개와 Outpost가 같은 VPC에 묶여있는 모습이다. Outpost는 사용자의 on-premise 데이터 센터이고, VPC에 있는 각 영역은 하나의 subnet을 가진다.

---
참고
- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.RegionsAndAvailabilityZones.html
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html
- https://medium.com/@ranadheerraju11/what-are-regions-availability-zones-and-local-zones-428f9b739763
- https://docs.aws.amazon.com/wavelength/index.html