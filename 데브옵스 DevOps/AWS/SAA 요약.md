## Analytics
- QuickSight: Visualization


## Compute
- EC2: Elastic Compute Cloud

## Management and governance
- [CloudTrail](./Management%E2%80%85and%E2%80%85governance/CloudTrail.md): 권한이나 Policy에 대한 기록 트래킹
- [CloudFormation](./Management%E2%80%85and%E2%80%85governance/CloudFormation.md): 클라우드 전체 배포 관리

## Networking
- [WAF](./Netwoking/WAF.md): 7계층 방화벽, origin 변조나 script/SQL inject 방지
- Shield: DDos 방지

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
  