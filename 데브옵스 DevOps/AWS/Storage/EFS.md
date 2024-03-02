
EFS provides a simple and fully managed elastic NFS file system for use within AWS. EFS automatically and instantly scales you file system storage capacity up or down as you add or remove files without disrupting your application.

--- 

- In EFS, storage capacity is elastic (grows and shrinks automatically) and its size changes based on adding or removing files.

- While EBS mounts on EBS volume to one instance, you can attach one EFS volume across multiple EC2 instances.

- The EC2 instances communicate to the remote file system using the NFSv4 protocol. This makes it required to open up the NFS port for our security group (EC2 firewall rules) to allow inbound traffic on that port.

- Within an EFS volume, the mount target state will let you know what instances are available for mounting

- With EFS, you only pay for the storage that you use so you pay as you go. No pre-provisioning required.

- EFS can scale up to the petabytes and can support thousands of concurrent NFS connections.

- Data is stored across multiple AZs in a region and EFS ensures read after write consistency.

- It is best for file storage that is accessed by a fleet of servers rather than just one server

---

EFS 성능 모드
- Provisioned Throughput mode:
  - 고정된 처리량을 가지는 EFS 파일 시스템 제공.
  - 이 모드에서는 파일 시스템이 필요로하는 I/O 처리량을 사전에 선언하면 파일 시스템의 처리량이 일정하게 유지된다. (예약한 처리량을 통해 일관된 성능을 제공)
  - 파일 시스템 크기에 관계없이 특정 처리량을 예약할 수 있다.
  - 파일 시스템에 대한 트래픽이 일시적으로 증가하는 경우에도 성능을 일관되게 유지할 수 있다.
  - 사용례
    - 높은 처리량이 필요한 애플리케이션: 대량의 동시 사용자 요청을 처리해야 하는 웹 서버 애플리케이션 등과 같이 높은 처리량이 필요한 경우, Provisioned Throughput mode를 사용하여 일관된 성능을 유지할 수 있다.
    - 대용량 데이터 분석: 대용량의 데이터를 읽고 분석해야 하는 데이터 분석 애플리케이션에서도 Provisioned Throughput mode를 사용하여 원활한 데이터 처리를 보장할 수 있다.
  
- Bursting Throughput mode:
  - first-burst 처리량을 가지는 EFS 파일 시스템을 제공.
  - 파일 시스템의 처리량은 평상시에는 크레딧을 소모하지 않고 first-burst 상태로 유지됩니다.
  - 파일 시스템에 대한 트래픽이 증가하면 크레딧을 사용하여 일시적으로 더 높은 처리량을 제공할 수 있다.
  - 파일 시스템의 크레딧이 소진되면 처리량이 평상시 수준으로 돌아간다.
  - 사용례
    - 저렴한 비용으로 가변적인 트래픽 처리: 일정 기간 동안 예측할 수 없는 트래픽 패턴이 있는 애플리케이션에서는 Bursting Throughput mode를 사용하여 가변적인 트래픽에 대한 비용 효율적인 파일 스토리지를 구축할 수 있습니다.
    - 개발 및 테스트 환경: 개발 및 테스트 환경에서는 일시적인 트래픽 증가가 있을 수 있으므로 Bursting Throughput mode를 사용하여 필요한 처리량을 제공할 수 있습니다.

- Max I/O mode:
  - 매우 높은 처리량이 필요한 애플리케이션에 사용된다. 최대 100MB/s의 처리량이 제공된다.
  
- Cold mode:
  - 드문 액세스 또는 액세스 비율이 낮은 파일 시스템에 사용한다. 파일 시스템의 데이터는 자주 액세스되지 않으며, 액세스할 때 전체 데이터를 로드해야 한다.

- Infrequent Access mode:
  - 일반적으로 액세스 비율이 낮은 데이터를 위한 비용 효율적인 스토리지이다. 파일 시스템의 데이터는 자주 액세스되지 않으며, 액세스할 때 전체 데이터를 로드해야 한다.


---
reference
- https://aws.amazon.com/efs/
- https://docs.aws.amazon.com/ko_kr/AWSEC2/latest/UserGuide/AmazonEFS.html