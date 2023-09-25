## Analytics
- QuickSight: Visualization

## Compute
- [EC2](./Computing/EC2.md): Elastic Compute Cloud
  - 종류
    - **On-Demand instances**: 서버 대여, 시간 당 지불
    - **Reserved instance**: 1~3년간 대여
    - **Spot instances**: 사용자 제시 가격(입찰가격)을 정해놓고 저렴할 때 이용
  - placement
    - default
    - partition: 대규모 분산 및 복제 워크로드
    - cluster: HPC
- [API Gateway](./Netwoking/API%E2%80%85Gateway.md): REST 및 Websocker API를 생성, 유지, 관리

## Database
- [EFS](./Database/EFS.md): File System
- [DynamoDB](./Database/DynamoDB.md): NoSQL
- [RDS](./Database/RDS.md): RDBMS
- [Aurora](./Database/Aurora.md): 안정성과 고가용성을 겸비한 RDBMS (Serverless 가능)
- [Redshift](./Database/Redshift.md): fully managed, petabyte-scale data warehouse service in the cloud.

## Management and governance
- [CloudWatch](./Management%E2%80%85and%E2%80%85governance/CloudWatch.md): 애플리케이션 지표, 로그 모니터링
  - [EventBridge](https://docs.aws.amazon.com/ko_kr/AmazonCloudWatch/latest/events/WhatIsCloudWatchEvents.html): 변경 사항 실시간 전달
- [CloudTrail](./Management%E2%80%85and%E2%80%85governance/CloudTrail.md): 권한이나 Policy에 대한 기록 트래킹
- [CloudFormation](./Management%E2%80%85and%E2%80%85governance/CloudFormation.md): 클라우드 리소스 전체 모델링 관리
  - Origin Shield: Caching Layer

## Networking
- [WAF]: SQL injection, macious ip 등 막아주는 7계층 방화벽
- Shield: DDos 방지
- [VPC](./Netwoking/VPC.md): 가상 네트워크, 다른 네트워크와 논리적 분리
- [Security Groups](./Netwoking/Security%E2%80%85Groups.md): instance 수준의 control access, stateful, allow만 가능
- [NACLs](./Netwoking/NACLs.md): subnet 수준의 control access, allow만 가능, stateless, allow와 disallow 가능

## Security
- [Cognito](./Security/Cognite.md): User pools, Identity pools 제공
- [IAM](./Security/IAM.md): 접근 유저 및 Policy 관리
- [KMS](./Security/KMS.md): Key 관리
- AWS Shield Advanced: DDoS 보호

## Storage
- [DayaSync](./Storage/DayaSync.md) : on premises와 AWS Storage services 사이 데이터를 sync 해줌
- [EBS](./Storage/EBS.md): EC2 Image
- [EFS](./Storage/EFS.md): Serverless NFS file system
- [FSx](./Storage/FSx.md): fully managed File Systen
  - FSx for NetApp ONTAP: 범용
  - FSx for Lustre: ML 특화
  - FSx for OpenZFS: ZFS, Linux 기반 범용
  - Windows File Server: Window 기반
- [Storage Gateway](./Storage/Storage%E2%80%85Gateway.md): on-prem 이전용
  - (FSx) File Gateway, Volume Gateway, Tape Gateway
- [S3](./Storage/S3.md) : 파일 스토리지
    - Standard: 일반적인 스토리지, 99.99% availability와 11 9s durability를 지원
    - Infrequently Accessed(IA): 덜 조회되는 데이터
    - One Zone Infrequently Accessed: IA에서 availability를 포기했기 때문에 더 저렴
    - Intelligent Tiering: 특정 기간동안 접근되지 않으면 더 싼 Storage로 옮겨줌
    - Glacier: Data achiving을 위한 저장소, 조회하려면 몇 시간씩 걸릴 수 있음
- [Amazon Macie](https://docs.aws.amazon.com/ko_kr/macie/latest/user/what-is-macie.html) : S3에서 민감한 데이터 감지, 보안 및 액세스 제어를 위한 데이터 평가 및 모니터링

## AI

- [Comprehend](https://docs.aws.amazon.com/ko_kr/comprehend/latest/dg/what-is.html): 자연어 처리
- [Textract](https://aws.amazon.com/ko/textract/): 문서에서 텍스트 추출
- [Rekognition](https://aws.amazon.com/ko/rekognition/): 이미지 인식 및 비디오 분석
- [SageMaker](https://aws.amazon.com/ko/sagemaker/): 완전 관리형 기계 학습 서비스


## data

- kinesis: 비디오와 데이터 스트림을 실시간으로 손 쉽게 수집 및 처리, 분석
  - Kinesis Data Streams: 데이터 스트림을 분석하는 사용자 정의 애플리케이션 개발에 사용
  - Kinesis Data Firehose: 데이터 스트림을 AWS 데이터 저장소에 적재 (S3나 redshift, elasticsearch 등)
  - Kinesis Data Analytics: SQL을 사용해 데이터 스트림 분석
    - Kinesis Data Stream 또는 Firehose에 쉽게 연결하고 SQL 검색을 할 수 있다.
    - 수행 결과를 다시 Data Stream 또는 Fireshose로 보냄
    - 스트리밍 소스에 연결 → SQL 코드를 쉽게 작성 → 지속적으로 SQL 결과를 전달함
    - 데이터를 처리하기 위한 2가지 컨셉을 사용하고 있다.
      - 스트림(인-메모리 테이블) → 가상의 테이블 or view라고 봐야 함
      - 펌프(연속 쿼리) → 실제 데이터를 앞서 만든 view에 넣어주는 역할
  - Kinesis Video Streams: 분석을 위한 비디오 스트림 캡쳐 및 처리, 저장

---

- **AWS 스토리지간 데이터 복사**
  - DataSync: 파일시스템간 데이터 복사가 필요할때 사용.
  - Database Migration Service: 데이터 베이스에 특화된 서비스. 무중단 및 지속적인 동기화가 가능하다. 데이터베이스를 대상으로 복제가 필요할 경우 사용.
  - Backup: 백업주기, 보관주기, 모니터링 등 백업 정책을 관리하는 목적이 강하다. 데이터 백업이 목적일 경우 사용. 파일시스템, DB 모두 가능
- **온프레미스에서 AWS로 데이터 복사**
  - DataSync: 파일시스템간 데이터 복사가 필요할때 사용
  - Database Migration Service: 데이터베이스를 대상으로 복제가 필요한 경우 사용
- **클라우드 스토리지 최대한 활용하기**
  - File Gateway: 온프레미스의 Application이 클라우드의 스토리지(File, Tape, Volume)를 활용할수 있음
  - Transfer Family: 클라우드의 스토리지를 파일서버로 사용 (SFTP, FTP)

---


- [Security Group](./Security%E2%80%85Groups.md) : instance level 보안 규칙
  - allow만 가능 / stateful
- [NACLs](./NACLs.md) : subnet level 보안 규칙
  - allow, disallow 가능 / stateles
  
---

- API Calllog를 확인하기 위해서는 Cloudtrail을 씀
- S3-IA 와 S3 의 처리량, 지연시간은 동일함
- CloudWatch 의 default 수집주기는 5 분이지만, 최소 1 분까지 가능함
- S3는 RedirectWebsite를 지원함
- S3는 Multipartuploads를 통해 S3TransferAcceleration이 가능함
- Glacier 에서 오브젝트를 복원할 때는 S3 API 혹은 AWS Console 을 이용해야함
- EC2 의 SLA는 99.95%
- S3-IA 의 오브젝트 최소 사이즈는 128KB
- S3 멀티파트 업로드 파트의 크기는 5MB ~ 5GB (오브젝트 최대 크기는 5TB)
- S3에 특정 오브젝트가 반드시 CRR이 되어야 한다면 그 오브젝트의 subset에만 CRR를 허용해 줄 수 있음 (소스 설정 가능)
- S3는 HTTPS를 이용하여 SSL, HTTP Endpoint에 접근할 수 있음
- Versioning이 활성화된 Bucket은 소유자만이 지울 수 있음

- CloudWatch는 데이터를 최대 2주까지 보관
- CRR은 S3 오브젝트의 Metadata 와 ACL을 복제함
- S3 스탠다드 클래스의 최소 사이즈는 1 Byte
- Multi AZ가 활성화된 상태에서는 Primary RDS 가 아닌 Standby가 Backup 실시
- infrastructure를 다른 리전에 복사 및 배포하고 싶을 경우, Cloud formation을 사용해야함
- StorageGateway with CachedVolume은 자주 사용되는 데이터만 Cache하고 나머지 데이터를 S3 에 저장함
- Reserved instance를 사용하다가 나중에 다시 사용해야할 경우, 스냅샷을 떠놓고 종료해야 함
- S3 RRS 는 99.99%의 가용성과 내구성을 보장하며, 재생성이 쉬운 데이터를 보관함
- 각 서비스들의 설정 변경을 감독, 관리하고 싶은 경우 AWS Config를 사용하면 됨
- Read Replica, Elastic Cache 까지 썼음에도 병목현상이 발생한다면 DB 파티셔닝 후 다수의 DB instance 로 분산하는 것이 좋음
- ReadReplica는 동기식 복제를 지원하지 않음 (Asynchronous)
- RDS 가 Standby Replica 로 Failover 되는 요건 3 가지 : Compute Unit fail, 네트워크 연결 끊김, AZ 가용성 상실
- EBS SSD 볼륨은 1GiB ~ 16TiB
- Read Replica 의 Multi-AZ 복사는 불가능
- RDS가 삭제될 때, automatic backup은 자동으로 삭제되며, final snapshot이 생성되어 남음 (설정을 활성화했을 경우)
- EC2 메타 데이터 얻는 법 : curl http://169.254.169.254/latest/meta-data/public-hostname
- Read Replica 는 MySQL, PostgreSQL, MariaDB, Aurora, Oracle 서비스만 가능(MPMAO)
- Multi-AZRDSStandby에서는 동기식 복제를 지원함

---

- AWS Migration Service 를 이용할 경우, 동시에 Migration 가능한 VM 의 갯수는 50개
- CloudHSM은 SSL offload를 목적으로 사용하므로 Network Latency를 최소화하기 위해 EC2 주변에 두는 것이 좋음
- KMS 대신 CloudHSM 을 써야하는 경우 : **VPC 고성능 암호화가 필요한 경우, 키가 사용자의 독점적 제어 하에 다른 하드웨어 내에 저장되어있음, 애플리케이션과 통합되어있음**
- S3 업로드시 edge location 에 직접 쓰는 것이 가능 (Transfer Acceleration)
- SQS는 최소 한번 메시지를 전달하지만 순서를 보장하지 못 하고, 중복전송을 할 가능성이 있음
- IAM을 이용해 EC2의 Root Account 에 접근하는 것을 막을 수 없음(Root account는 모든 서비스에 접근 가능)
  
- VPC Peering은 인접 VPC에 대한 Routing Table 필요
- VPC Peering은 두 VPC간 두 개의 Peering을 생성할 수 없으며, 다른 Region의 VPC이 가능하고, CIDR block이 충돌하는 경우 사용 불가능
  
- SQS의 짧은 폴링 구성은 Receive Message Wait Time 을 0 초로 만드는 것임
  - 짧은 폴링을 쓸 경우, 처리되지 못하는 메시지가 발생할 수 있음
  - SQS Standard는 FIFO를 보장하지 않음
  - SQS queue에서 메시지를 실행하기만 하고 지우지 않으면 그 메시지가 queue로 돌아가 다시 실행됨
  - SQS 메시지의 표시되는 시간이 끝나면 다른 인스턴스에 의해 활용가능해짐
  - SQS의 메시지 보관 최대 일수는 14일 -> 앱의 문제로 메시지가 13 일간 쌓여있다하더라도 앱이 다시 시작만 한다면 바로 처리 가능
  
- S3 Object의 최소 사이즈는 0bytes임 (즉 빈 파일을 올릴 수 있음)
- AWS의 WellArchitected Framework의 구성요소는 **보안, 신뢰성, 성능, 비용최적화**임 (가용성은 없음)
- EFS를 활성화하기 위해 EC2 와 EFS 의 Security group에 포트를 열고, 리눅스에 chmod 명령어를 실행하여 권한을 줌
- Autoscaling 생성 후 '예악된 작업'에서 예악된 시간에 정책 적용 가능
- Error: No supported authentication methods available
  - 이 에러가 뜰 경우, 로그인시 ID와 private key를 확인해야 함
  
- RDS와 Dynamo DB
  - Schema가flexible한 경우RDS를 사용
  - Scale up/down 은 RDS 가 아닌 Dynamo DB 가능
  - RDS는 다음과 같은 이유로 확장성(Scaleup/down)이 떨어짐
  - 데이터를 정상화하고 디스크에 쓰려면 여러 개의 쿼리가 필요한 여러 테이블에 저장한다.
  - 일반적으로 ACID 준수 트랜잭션 시스템의 성능 비용을 발생시킨다.
  - 고가의 조인을 이용하여 조회 결과의 필요한 뷰를 재조립한다.
  - RDBMS 의 경우, 세부적인 구현이나 성능을 걱정하지 않고 유연성을 목적으로 설계. 일반적으로 쿼리 최적화가 스키마 설계에 영향을 미치지 않지만, 정규화가 아주 중요
  
- DynamoDB is not a totally schemaless database since the very definition of a schema is just the model or structure of your data.
  - DynamoDB 의 경우, 가장 중요하고 범용적인 쿼리를 가능한 빠르고 저렴하게 수행할 수 있도록 스키마를 설계. 사용자의 데이터 구조는 사용자 비즈니스 사용 사례의 특정 요구 사항에 적합
  
- 온프레미스에서 사용하던 고유의 IP 를 가져오기 위해서는 **ROA(Route Origin Authorization)**을 사용하여 Amazon ASN 이 해당 주소를 광고하도록 허용하게 함
- AWS 내부가 아닌 외부에서 AWS 에 access 할 수 있도록 하기 위해 SAML(SSO)을 연동하면 됨
- RDS 내 보다 면밀한 모니터링을 위해서는 Enhanced Monitoring 을 하는 것이 좋음

- Redshift
  - 쿼리 큐를 정의하는 방식은 WLM(Workload management)가 있음
  - Redshift에서 클러스터와 VPC 외부의 COPY, UNLOAD 트래픽을 모니터링하기 위해서는 Enhanced VPC routing 을 사용해야함
- API Gateway 에는 트래픽 쏠림으로 인한 병목현상을 막아주는 Throttling Limit 기능이 존재
- Memory utilization, disk swap utilization, disk space utilization, page file utilization, log collection 은 custom monitoring 항목
- EC2에 에이전트를 설치하고 해당 항목을 감시해야 함
- ELB를 쓰지 않으려면, EC2에 공인 IP를 할당하고 스크립트로 헬스체크를 하고 Failover하는 것이 좋음
  
- Cloudfront 의 Signed URL: RTMP를 사용할 경우 SignedCookie를 지원하지 않으므로 사용
  - 개별 파일에 대한 액세스를 제공하려는 경우
  - 클라이언트가 Cookie 를 지원하지 않을 경우
- Cloudfront 의 Signed Cookie
  - HLS 형식의 비디오 파일 전체 또는 웹 사이트의 구독자 영역에 있는 파일 전체 등 제한된 파일 여러 개에 대한 액세스 권한을 제공하려는 경우
  - 현재의URL을 변경하고 싶지 않은 경우
- EBS 스냅샷이 진행되는 동안 EBS의 읽기 및 쓰기는 영향을 받지 않음

- 온프레미스에서 이미 메시지 큐 서비스를 사용하고 있다면 MQ 로 넘어가는 것이 유리함
- 오로라에는 Endpoint가 있어 트래픽을 분산할 수 있음

- Lambda 의 배포방법(기존 Lambda 함수에서 새로운 Lambda 함수로)
  - Canary : 트래픽이 2번에 걸쳐 이동하여 2번째 이동에서 이동할 트래픽 비율, 간격을 정할 수 있음
  - Linear : 트래픽을 동일한 비율로 이동시키며 증분간 간격이 돌이하고, 비율과 간격시간을 정할 수 있음
  - All-at-once : 한 번에 이동

- AWS IoT Core
  - AWS에 연결된 디바이스들이AWSService와 쉽게 상호작용하도록 돕는 서비스
- EC2 에 호스팅된 Database(Raid array)를 백업시 다운타임을 최소화하는 방법
  - 모든 RAID array로 쓰기 작동을 멈춤
  - 모든 cache를 disk에 flush함
  - EC2가 RAID에 쓰기작업을 하지 않는지 확인
  - RAID에 대한 모든 디스크 관련 활동을 중지하는 단계를 수행한 후 스냅샷 생성
  
- 기본적으로 data at rest 를 암호화하는 솔루션은 Storage Gateway 와 Glacier
- PFS 가 지원되는 솔루션은 Cloudfront 와 ELB

- EBS의 특징
  - EBS를 생성할 경우, 다른 AZ가 아닌 해당 AZ에만 자동으로 복제됨
  - EBS는 해당 AZ 어느 EC2든 연결할 수 있음
- 서비스 사용중인 상태에서 volume type(gp2, io1, standard), size, IOPS를 바꿀 수 있음
- APIGateway는 받거나 처리한 양만큼은 요금을 지불하면 됨

- SNI(Server Name Indication)
  - 여러 도메인을 하나의 IP주소로 연결하는 TLS의 확장 표준 중 하나(인증서에서 사용하는 방식)
  - SNI를 사용하게 되면 하나의 웹서버에서 여러 도메인의 웹사이트를 서비스하는 경우에도 인증서를 사용한 HTTPS 활성화가 가능


- S3
  - S3 에서 사용 가능한 Event Notification Service 는 SQS, SNS, Lambda
  - Standard에서 IA, OneZONE_IA로 가려면 30일을 기다려야 함
  - S3 에서 모든 액세스 요청에 대한 자세한 정보를 확인하고 싶다면 Server Access Log를 사용 가능
  - Cloudwatch는 ec2 메모리 사용 관련 지표가 없으므로 인스턴스 내 스크립트를 통해 지표를 생성하고 Cloudwatch로 보내야 함
  - 확장 모니터링의 경우, 인스턴스 내 에이전트에서 정보를 받기 때문에 메모리 관련 정보를 얻음


- AWS SSO가 STS를 이용하여 권한을 발급함
  - STS: AWS Security Token Service(AWS STS)를 사용하면 AWS 리소스에 대한 액세스를 제어할 수 있는 임시 보안 자격 증명을 생성하여 신뢰받는 사용자에게 제공할 수 있다. 

- EBS volume의 백업을 자동화하기 위해서는 DLM(Data Lifecycle Manager)를 쓰는
것이 좋음
- Autoscaling cool down 정책
- scaling action 이 발동되기 전에는 launch 나 termination 을 하지 않음 - 기본값은 300 초임
- cooldown은scaleout후 발동되는 것

- EC2의 경우 Region당 20개가 한계이며 별도의 요청이 있으면 그 이상의 생성이 가능

- 확장성과 탄력성을 위해서는 ELB 와 Route 53(Weighted Routing Policy)를 사용하는 것이 바람직

- non-default subnet은 public ipv4, DNS hostname 을 받지 않음

- Lambda monitoring metric
  - Invocations : 5분 기간 동안 함수가 호출된 횟수
  - Duration : 평균, 최소, 최대 실행 시간
  - 오류 수 및 성공률(%) : 오류 수 및 오류 없이 완료된 실행의 비율
  - Throttles : 동시 사용자 한도로 인해 실행에 실패한 횟수
  - IteratorAge : 스트림 이벤트 소스에서 Lambda 가 배치의 마지막 항목을 받아 함수를 호출했을 때 해당 항목의 수명
  - DeadLetterErrors : Lambda가 배달 못한 편지 대기열에 쓰려고 시도했으나 실패한 이벤트 수
  
- VPC Peering의 기능 중 다음 2가지는 불가능함
  - Transit Gateway : A VPC가 Peering된 B VPC를 통해 C VPC로 갈 수 없음
  - EdgetoEdgeRouting : Peering을 통해 다른 서비스로의 이동이 불가능함 - 이미 생성된 Autoscaling 의 시작구성은 변경할 수 없음
  
- VPC 내 IP 대역은 `/16` ~ `/28` 사이이며, 새로운 서브넷을 생성하면 main route table에 연계됨(`172.16.0.0/16`)
  
- Redshift Spectrum : S3 의 exabyte 급 데이터 처리를 가능하게 함

- SQS의 중복문제를 궁극적으로 해결하고 싶을 경우, SWF를 쓰는 것이 좋음

- SSL/TLS 인증서를 안전하게 import 할 수 있게 도와주는 서비스는 ACM, IAM cert store

- Management Console을 통해 Glacier로 직접 업로드하는 것은 불가능
- Spot Instance는 사용 후 첫 1시간 이내에 AWS에 의해 종료되면 요금을 부과하지 않고, 그 이후에 AWS에 의해 종료되면 초단위로 부과됨
- Trusted Advisor 는 비용 최적화, 성능, 보안, 내결함성, 서비스 한도 등을 체크하여 사용자에게 알려줌

- Aurora Failover
  - ReadReplica가 있는 경우 : CNAME이 정상 복제본을 가리키도록 변경되며, 해당 복제본이 승격됨
  - Read Replica가 없는 경우 : 동일한 AZ에 새 인스턴스를 하나 생성시도, 생성이 어려운 경우 다른AZ에 생성 시도
- CloudHSM은 키 또는 자격 증명에 대한 액세스 권한을 가지지 않으므로 자격 증명을 분실할 경우 키 복구 불가

- API Gateway는 오로지 HTTP Sendpoints만을 게시함

- EBS의 스냅샷의 경우, 하나의 스냅샷을 유지하면서 변경된 부분만 증분함 (하나의 스냅샷만이 유지됨)
- 예약 인스턴스의 경우, 비용을 아끼려면 마켓플레이스에 팔거나 인스턴스를 종료시켜야 함
  
- Elastic beanstalk의 application file은 S3 에 쌓고 로그는 선택적으로 S3 혹은 Cloudwatch Log 에 쌓임
  
- ENI에는 고정된 MAC주소가 지정됨

- 온프레미스 AD로 디렉터리 요청을 하기 위해서는 AD Connector가 필요하며 IAM Role을 생성해 권한을 정의함
- PrivateLink 를 사용하면 VPC 를 지원하는 AWS 서비스, 다른 계정에서 호스팅하는 서비스에 연결 가능
- 낮은 대기시간 및 높은 네트워크 처리량을 보장하는 EC2 디자인은 향상된 네트워킹과 Placement Group
- IGW는 대역폭에 대한 제한이 없음
- 프록시 프로토콜은 L4 단계에서 실행하는 것으로 웹계층에서는 소용 없음
- AWS Directory service 는 AD connector 를 사용하여 온프레미스 AD 사용자와
그룹에 할당할 수 있으며 IAM 정책에 따라 사용자 액세스 제어

- Auto scaling 은 손상된 인스턴스가 확인될 경우 이를 종료한 후!!! 새로운 인스턴스로 교체함

- ALB 는 Cognito 와 통합되어 OIDC ID 공급자 인증을 지원함
- DynamoDB 의 경우, 읽기/쓰기 용량을 결정해야 하며 Lambda, Kinesis 는 용량을 결정하지 않음

- 부서당 AWS 계정을 만든 상태에서 단일 Direct Connect 회로를 주문하면 가상 인터페이스를 구성하고 부서 계정번호로 태그를 걸면 가능
- VPC Peering의 경우 기본적으로 NACL에서 거부

Shield is DDoS protection and also located "at the edge". GuardDuty is intelligent threat detection. That means without much configuration, it reads your CloudTrail, Config and VPC FlowLogs and notifies if something unexpected happened. That is usually for infrastructure.

Amazon Inspector is more for applications. It's an automated security assessment service that helps improve the security and compliance of applications.