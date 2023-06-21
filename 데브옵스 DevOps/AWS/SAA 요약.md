## Analytics
- QuickSight: Visualization

## Compute
- [EC2](./Computing/EC2.md): Elastic Compute Cloud
  - 종류
    - **On-Demand instances**: 서버 대여, 시간 당 지불
    - **Reserved instance**: 1~3년간 대여
    - **Spot instances**: 사용자 제시 가격(입찰가격)을 정해놓고 저렴할 때 이용
- [API Gateway](./Netwoking/API%E2%80%85Gateway.md): REST 및 Websocker API를 생성, 유지, 관리

# Database
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
- [WAF](./Netwoking/WAF.md): 7계층 방화벽, origin 변조나 script/SQL inject 방지
- Shield: DDos 방지
- [VPC](./Netwoking/VPC.md): 가상 네트워크, 다른 네트워크와 논리적 분리

- [WAF]: SQL injection, macious ip 등 막아주는 7계층 방화벽
- [Security Groups](./Netwoking/Security%E2%80%85Groups.md): instance 수준의 control access, stateful, allow만 가능
- [NACLs](./Netwoking/NACLs.md): subnet 수준의 control access, allow만 가능, stateless, allow와 disallow 가능

## Security
- [Cognito](./Security/Cognite.md): User pools, Identity pools 제공
- [IAM](./Security/IAM.md): 접근 유저 및 Policy 관리
- [KMS](./Security/KMS.md): Key 관리

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

---


- [Security Group](./Security%E2%80%85Groups.md) : instance level 보안 규칙
  - allow만 가능 / stateful
- [NACLs](./NACLs.md) : subnet level 보안 규칙
  - allow, disallow 가능 / stateles
  