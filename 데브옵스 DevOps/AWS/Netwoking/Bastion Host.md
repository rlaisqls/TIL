
AWS 리소스 구성 후 관리자는 VPC 외부에서 Private Subnet에 직접 접근할 수 없다.

Private Subnet의 Private한 특성을 지키기 위해 Public Subnet인 인스턴스를 하나 만들어서 그 인스턴스를 통해 접근하는 방법을 많이 쓰는데, 이러한 host를 Bastion Host라고 부른다. 쉽게 말하면  내부와 외부 네트워크 사이에서 일종의 게이트 역할을 수행하는 호스트이다.

관리자가 Bastion Host으로 SSH 연결을 한 후 Bastion Host에서 Private Subnet의 Host에 SSH 연결을 하는 형태로 Private Subnet에 접근할 수 있다. SSH 연결을 수행해야 하기 때문에 Bastion Host 또한 Public Subnet에 위치하는 EC2 Insatnce이다.

![image](https://github.com/rlaisqls/rlaisqls/assets/81006587/775149ad-dd6e-4823-9440-f8bf9793716f)
