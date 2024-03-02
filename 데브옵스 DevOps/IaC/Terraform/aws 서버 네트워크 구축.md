
### 1. 네트워크 구성

```hcl
resource "aws_vpc" "scenario_1_vpc" {
  cidr_block = "172.16.0.0/26"
  tags = {
    Name = "scenario-1-vpc"
  }
}
```

- VPC는 AWS에서 다루는 네트워크의 기본단위이다.
- 사용자들이 앞으로 만들 서버와 인터넷을 통해 통신하기 위해선 네트워크 구축이 필요한데 가장 먼저 VPC를 만들어주어야 한다. 
- cidr_block을 통해 어떤 ip 대역을 사용할지 결정한다. 보통 `10.0.0.0/8`, `172.16.0.0/16`, `192.168.0.0/24`의 private ip 대역을 사용하지만 공인 ip 대역 역시 사용이 가능하다.
- 다만 공인 ip 대역 사용시 인터넷을 통한 통신이 불가능하므로 private ip대역을 사용하는것이 좋다.

VPC를 구축한 다음엔 다음 코드로 서브넷팅을 할 차례다.

```hcl
resource "aws_subnet" "scenario-1-public-subnet" {
  vpc_id = aws_vpc.scenario_1_vpc.id
  cidr_block = "172.16.0.0/28"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "scenario-1-public-subnet"
  }
}
resource "aws_subnet" "scenario-1-private-subnet" {
  vpc_id = aws_vpc.scenario_1_vpc.id
  cidr_block = "172.16.0.16/28"
  availability_zone = "ap-northeast-2a"
  tags = {
    Name = "scenario-1-private-subnet"
  }
}
resource "aws_subnet" "scenario-1-private-subnet-2" {
  vpc_id = aws_vpc.scenario_1_vpc.id
  cidr_block = "172.16.0.32/28"
  availability_zone = "ap-northeast-2b"
  tags = {
    Name = "scenario-1-private-subnet-2"
  }
}
```

- VPC가 허용하는 대역 안에서 웹서버를 배치할 public subnet 1개, 데이터베이스를 배치할 private 2개를 생성했다.
- 서브넷을 사용할때는 가용영역을 설정할 수 있는데, 여러 가용영역에 서브넷을 만들어서 장애발생시에도 고가용성을 유지하도록 구현할수 있다.
- private 서브넷은 internet gateway와 연결되어있지 않기 때문에 인터넷을 통한 외부 공격을 방지할수 있는 장점이 있다.

public 서브넷을 만들기 위해선 internet gateway를 정의해야한다.

```hcl
resource "aws_internet_gateway" "scenario_1_igw" {
  vpc_id = aws_vpc.scenario_1_vpc.id
  tags = {
    Name = "main"
  }
}
```

- internet gateway는 VPC와 인터넷 사이를 연결해준다.
- internet gateway에 연결된 서브넷(public 서브넷)은 인터넷을 통한 통신이 가능하며, 공인 ip 주소를 VPC내의 사설 ip 주소로 변환해주는 NAT로써의 역할을 수행한다

internet gateway를 생성 했다면 router가 참조할수 있는 routing table들을 생성해주는 작업이 필요하다.

```hcl
resource "aws_route_table" "scenario_1_public_route_table" {
  vpc_id = aws_vpc.scenario_1_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.scenario_1_igw.id
  }
  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "scenario_1_private_route_table" {
  vpc_id = aws_vpc.scenario_1_vpc.id
  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "scenario_1_public_rt_association" {
  subnet_id      = aws_subnet.scenario-1-public-subnet.id
  route_table_id = aws_route_table.scenario_1_public_route_table.id
}

resource "aws_route_table_association" "scenario_1_private_rt_1_association" {
  subnet_id      = aws_subnet.scenario-1-private-subnet.id
  route_table_id = aws_route_table.scenario_1_private_route_table.id
}

resource "aws_route_table_association" "scenario_1_private_rt_2_association" {
  subnet_id      = aws_subnet.scenario-1-private-subnet-2.id
  route_table_id = aws_route_table.scenario_1_private_route_table.id
}
```

- routing table은 서브넷의 라우터가 통신할때 참조하는 테이블이다.
- 여기서 public subnet과 private의 차이점이 한번더 드러나는데, public subnet이 참조하는 routing table은 목적지가 공인 ip 대역인 요청을 internet gateway로 보내는 규칙이 필요하다.
- routing table들을 생성하고 필요한 규칙을 추가하면 네트워크 구성은 마무리 된다.

### security group 구성

- security group은 instance의 방화벽의 역활을 담당하는 중요한 오브젝트이다.
- 이 시나리오에서는 웹서버와 데이터베이스와 웹서버를 위해 각각 1개의 security group이 필요하다.
- 웹서버는 고객들이 접근할수 있도록 `0.0.0.0/0` 에 대해 443 포트를, ssh 연결을 위해 `x.x.x.x/32`(관리자가 접속하는 ip)의 22번 포트 연결을 허용해야 한다.
- AWS가 제공하는 security group은 특정 IP 대역뿐만 아니라 특정 security group에 속해 있는 instance와의 통신만 허용하는것이 가능하다.
- 이 점에 착안하며 웹서버를 위한 security group을 생성한후 데이터베이스는 웹서버가 속한 security group의 소스들만 통신을 허용하도록 구성해야 한다.

```hcl
resource "aws_security_group" "scenario_1_ec2" {
  description = "Allow"
  vpc_id      = aws_vpc.scenario_1_vpc.id
  ingress {
    description = "communication"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<your_source_ip>/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "scenario_1_rds" {
  description = "Allow"
  vpc_id      = aws_vpc.scenario_1_vpc.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.scenario_1_ec2.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "with logic"
  }
}
```

---
참고
- ttps://www.44bits.io/ko/post/terraform_introduction_infrastrucute_as_code
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs
