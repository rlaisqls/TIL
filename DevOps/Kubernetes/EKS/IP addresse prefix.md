
각 Amazon EC2 인스턴스는 지원할 수 있는 elastic network interface의 최대 개수와 각 네트워크 인터페이스에 할당할 수 있는 IP 주소의 최대 개수가 정해져 있다. 각 노드는 네트워크 인터페이스당 하나의 IP 주소가 필요하다. 그 외 사용 가능한 모든 IP 주소는 Pod에 할당될 수 있다. 각 Pod는 고유한 IP 주소가 필요하다. 결과적으로, 노드에 사용 가능한 컴퓨팅 및 메모리 리소스가 있더라도 Pod에 할당할 IP 주소가 부족하여 추가 Pod를 수용할 수 없는 상황이 발생할 수 있다.

노드에 개별 보조 IP 주소를 할당하는 대신 **IP prefix**를 할당하면 노드가 Pod에 할당할 수 있는 IP 주소 수를 크게 늘릴 수 있다. 각 prefix에는 여러 개의 IP 주소가 포함되어 있다.

클러스터에 IP prefix 할당을 구성하지 않으면, 클러스터는 Pod 연결에 필요한 네트워크 인터페이스와 IP 주소를 구성하기 위해 더 많은 Amazon EC2 API 호출을 수행해야 한다.

클러스터가 더 큰 규모로 성장하면, 이러한 API 호출의 빈도가 증가하여 Pod 및 인스턴스 시작 시간이 길어질 수 있다. 이는 대규모이고 급증하는 워크로드의 수요를 충족하기 위한 스케일링 지연을 초래하며, 스케일링 요구사항을 충족하기 위해 추가 클러스터와 VPC를 프로비저닝해야 하므로 비용과 관리 오버헤드가 증가한다. 자세한 내용은 GitHub의 [Kubernetes Scalability threshold](https://github.com/kubernetes/community/blob/master/sig-scalability/configs-and-limits/thresholds.md)를 참고한다.

## 고려사항

- 각 Amazon EC2 인스턴스 타입은 지원할 수 있는 최대 Pod 수가 정해져 있다. 관리형 노드 그룹이 여러 인스턴스 타입으로 구성된 경우, 클러스터의 인스턴스 중 최소 최대 Pod 수가 클러스터의 모든 노드에 적용된다.

- 기본적으로 노드에서 실행할 수 있는 최대 Pod 수는 110개이지만, 이 숫자를 변경할 수 있다. 기존 관리형 노드 그룹이 있는 상태에서 이 숫자를 변경하면, 다음 AMI 또는 시작 템플릿 업데이트 시 새 노드가 변경된 값으로 생성된다.

- IP 주소 할당에서 IP prefix 할당으로 전환할 때, 기존 노드를 롤링 교체하는 대신 새 노드 그룹을 생성하여 사용 가능한 IP 주소 수를 늘리는 것을 권장한다. IP 주소와 prefix가 모두 할당된 노드에서 Pod를 실행하면 광고된 IP 주소 용량에 일관성이 없어져 노드의 향후 워크로드에 영향을 미칠 수 있다. 권장되는 전환 방법은 Amazon EKS 모범 사례 가이드의 [Secondary IP mode to Prefix Delegation mode or vice versa](https://github.com/aws/aws-eks-best-practices/blob/master/content/networking/prefix-mode/index_windows.md#replace-all-nodes-during-migration-from-secondary-ip-mode-to-prefix-delegation-mode-or-vice-versa)에서 Replace all nodes during migration을 참고한다.

- Linux 노드가 있는 클러스터의 경우
  - 네트워크 인터페이스에 prefix를 할당하도록 add-on을 구성한 후에는, 클러스터의 모든 노드 그룹에서 모든 노드를 제거하지 않고는 Amazon VPC CNI plugin for Kubernetes add-on을 `1.9.0`(또는 `1.10.1`)보다 낮은 버전으로 다운그레이드할 수 없다.
  - Pod용 security group도 사용하고 있고 `POD_SECURITY_GROUP_ENFORCING_MODE=standard` 및 `AWS_VPC_K8S_CNI_EXTERNALSNAT=false`로 설정된 경우, Pod가 VPC 외부의 엔드포인트와 통신할 때 Pod에 할당한 security group이 아닌 노드의 security group이 사용된다.
  - Pod용 security group도 사용하고 있고 `POD_SECURITY_GROUP_ENFORCING_MODE=strict`로 설정된 경우, Pod가 VPC 외부의 엔드포인트와 통신할 때 Pod의 security group이 사용된다.

## 사전 요구사항

- 기존 클러스터가 있어야 한다. 클러스터를 배포하려면 Creating an Amazon EKS cluster를 참고한다.

- Amazon EKS 노드가 위치한 서브넷에는 충분한 연속적인 `/28`(IPv4 클러스터의 경우) 또는 `/80`(IPv6 클러스터의 경우) Classless Inter-Domain Routing (CIDR) 블록이 있어야 한다. IPv6 클러스터에는 Linux 노드만 사용할 수 있다. IP 주소가 서브넷 CIDR 전체에 흩어져 있으면 IP prefix 사용이 실패할 수 있다. 다음을 권장한다.

- 서브넷 CIDR 예약을 사용하여 예약된 범위 내의 IP 주소가 여전히 사용 중이더라도 해제되면 IP 주소가 재할당되지 않도록 한다. 이를 통해 분할 없이 prefix를 할당할 수 있도록 보장한다.

- IP prefix가 할당될 워크로드를 실행하는 데 특별히 사용되는 새 서브넷을 사용한다. IP prefix를 할당할 때 Windows와 Linux 워크로드 모두 동일한 서브넷에서 실행할 수 있다.

- 노드에 IP prefix를 할당하려면 노드가 AWS Nitro 기반이어야 한다. Nitro 기반이 아닌 인스턴스는 개별 보조 IP 주소를 계속 할당하지만, Nitro 기반 인스턴스에 비해 Pod에 할당할 수 있는 IP 주소 수가 현저히 적다.

- Linux 노드가 있는 클러스터의 경우 – 클러스터가 IPv4 패밀리로 구성된 경우, Amazon VPC CNI plugin for Kubernetes add-on 버전 1.9.0 이상이 설치되어 있어야 한다. 다음 명령으로 현재 버전을 확인할 수 있다.

```bash
kubectl describe daemonset aws-node --namespace kube-system | grep Image | cut -d "/" -f 2
```

- 클러스터가 IPv6 패밀리로 구성된 경우, add-on 버전 1.10.1이 설치되어 있어야 한다. 플러그인 버전이 필요한 버전보다 낮으면 업데이트해야 한다. 자세한 내용은 Working with the Amazon VPC CNI plugin for Kubernetes Amazon EKS add-on의 업데이트 섹션을 참고한다.

## Amazon EC2 노드의 사용 가능한 IP 주소 수를 늘리는 방법

노드에 IP 주소 prefix를 할당하도록 클러스터를 구성한다. 노드의 운영 체제와 일치하는 탭의 절차를 완료한다.

## Linux의 경우

1. Amazon VPC CNI DaemonSet의 네트워크 인터페이스에 prefix를 할당하는 파라미터를 활성화한다. `1.21` 이상 버전의 클러스터를 배포하면 Amazon VPC CNI plugin for Kubernetes add-on 버전 `1.10.1` 이상이 함께 배포된다. IPv6 패밀리로 클러스터를 생성한 경우 이 설정은 기본적으로 true로 설정된다. IPv4 패밀리로 클러스터를 생성한 경우 이 설정은 기본적으로 false로 설정된다.
    ```bash
    kubectl set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true
    ```
    - 서브넷에 사용 가능한 IP 주소가 있더라도 서브넷에 사용 가능한 연속적인 `/28` 블록이 없으면 Amazon VPC CNI plugin for Kubernetes 로그에 다음 오류가 표시된다.
    - `InsufficientCidrBlocks: The specified subnet does not have enough free cidr blocks to satisfy the request`
    - 이는 서브넷 전체에 흩어져 있는 기존 보조 IP 주소의 단편화로 인해 발생할 수 있다. 이 오류를 해결하려면 새 서브넷을 생성하여 Pod를 시작하거나, Amazon EC2 서브넷 CIDR 예약을 사용하여 prefix 할당에 사용할 서브넷 내 공간을 예약한다. 자세한 내용은 Amazon VPC User Guide의 [Subnet CIDR reservations](https://docs.aws.amazon.com/vpc/latest/userguide/subnet-cidr-reservation.html)를 참고한다.

- 시작 템플릿 없이 관리형 노드 그룹을 배포하거나, AMI ID를 지정하지 않은 시작 템플릿으로 배포할 계획이고, 사전 요구사항에 나열된 버전 이상의 Amazon VPC CNI plugin for Kubernetes를 사용하는 경우 다음 단계로 건너뛴다. 관리형 노드 그룹은 자동으로 최대 Pod 수를 계산한다.
    자체 관리형 노드 그룹 또는 AMI ID를 지정한 시작 템플릿을 사용하는 관리형 노드 그룹을 배포하는 경우, 노드에 대한 Amazon EKS 권장 최대 Pod 수를 결정해야 한다. Amazon EKS recommended maximum Pods for each Amazon EC2 instance type의 지침을 따르고, 3단계에 `--cni-prefix-delegation-enabled`를 추가한다. 나중에 사용할 수 있도록 출력을 기록한다.

- 하나 이상의 Amazon EC2를 포함하는 다음 유형의 노드 그룹 중 하나를 생성한다.


---
참고
- https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
- [Amazon VPC CNI](./Amazon VPC CNI.md)