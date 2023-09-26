# Instance Store

AWS Instance Store는 Amazon Elastic Compute Cloud (EC2)에서 제공하는 임시 블록 수준 스토리지 서비스이다. EC2 인스턴스에 직접 연결된 로컬 디스크로, EC2 인스턴스가 실행 중인 동안에만 데이터를 유지한다.

Instance Store는 인스턴스와 함께 묶여 있어 저렴하면서도 빠른 I/O 처리량을 제공한다. 그러므로 인스턴스 스토어를 사용하여 저지연 및 높은 처리량 작업을 수행할 수 있다. (대규모 데이터베이스, 데이터 웨어하우스, 로그 분석, 캐싱 등)

하지만 Instance Store는 휘발성이므로, 인스턴스가 종료되거나 재부팅되면 데이터가 영구적으로 삭제된다. 그러므로 임시 데이터나 캐시와 같이 데이터의 지속성이 필요하지 않은 작업에 적합하다.

AWS Instance Store는 EC2 인스턴스에 연결된 로컬 디스크로서 저렴하고 높은 성능을 제공한다. 데이터의 지속성이 필요하지 않은 작업에 이상적이며, 대용량 데이터베이스, 데이터 웨어하우스, 로그 분석, 캐싱 등에 사용될 수 있다. 그러나 데이터의 지속성과 백업이 필요한 경우에는 영구 스토리지 솔루션인 Amazon EBS를 고려해야 한다.

---

<img width="892" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/d57b62f1-6a97-4666-99af-ab36c462fd00">

---

- The engineering team at a startup is evaluating the most optimal block storage volume type for the EC2 instances hosting its flagship application. The storage volume should support very low latency but it does not need to persist the data when the instance terminates. As a solutions architect, you have proposed using Instance Store volumes to meet these requirements.
    Which of the following would you identify as the key characteristics of the Instance Store volumes? (Select two)

- **You can't detach an instance store volume from one instance and attach it to a different instance**
  - You can specify instance store volumes for an instance only when you launch it. You can't detach an instance store volume from one instance and attach it to a different instance. The data in an instance store persists only during the lifetime of its associated instance. If an instance reboots (intentionally or unintentionally), data in the instance store persists.

- **If you create an AMI from an instance, the data on its instance store volumes isn't preserved**
  - If you create an AMI from an instance, the data on its instance store volumes isn't preserved and isn't present on the instance store volumes of the instances that you launch from the AMI.

Incorrect options:

- Instance store is reset when you stop or terminate an instance. Instance store data is preserved during hibernation
  - **When you stop, hibernate, or terminate an instance, every block of storage in the instance store is reset.** Therefore, this option is incorrect.

- You can specify instance store volumes for an instance when you launch or restart it
  - **You can specify instance store volumes for an instance only when you launch it.**

- An instance store is a network storage type
  - **An instance store provides temporary block-level storage for your instance.** This storage is located on disks that are physically attached to the host computer.
