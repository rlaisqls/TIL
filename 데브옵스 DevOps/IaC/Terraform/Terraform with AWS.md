# Terraform with AWS

AWS Provider로 간단한 인프라를 구성해보자.

우선 AWS IAM에 가서 Terraform이 사용할 계정을 만들고, 사용할 서비스 VPC, EC2에 대한 권한을 부여한다.

생성된 계정에 할당된 access key와 secret key로 다음과 같은 aws.tf 파일을 생성한다.

```hcl
provider "aws" {
  access_key = "ACCESS-KEY"
  secret_key = "SECRET-KEY"
  region     = "ap-northeast-2"
}
```

이제 AWS 리소스를 정의할 때 이 파일을 이용하게 된다.

Terraform을 사용하면 API Gateway, App Autoscaleing, CloudFomation, CloudFront, CloudWatch, CodeCommit, CodeDeploy, DynamoDB, EC2, ECS, ElasticCache, Elastic Beanstalk, ElasticSearch, IAM, Kinesis, Lambda, OpsWorks, RDS, RedShift, Route53, S3, SES, SimpleDB, SNS, SQS, VPC 등 AWS의 거의 모든 인프라를 관리할 수 있다.

### VPC 구성

VPC부터 Terraform으로 구성해서 사용해보자. vpc.tf라는 파일을 만들어서 다음 내용을 입력한다.

```hcl
resource "aws_vpc" "example" {
  cidr_block = "172.10.0.0/20"
  tags {
    Name = "example"
  }
}

resource "aws_subnet" "example-a" {
  vpc_id = "${aws_vpc.example.id}"
  cidr_block = "172.10.0.0/24"
  availability_zone = "ap-northeast-2a"
}

resource "aws_subnet" "example-c" {
  vpc_id = "${aws_vpc.example.id}"
  cidr_block = "172.10.1.0/24"
  availability_zone = "ap-northeast-2c"
}
```

VPC 하나(`aws_vpc`)와 VPC에서 사용할 서브넷을 2개 만들었다(`aws_subnet`). AWS 프로바이더의 리소스이므로 리소스 타입의 이름의 접두사에 aws_가 붙은 것을 볼 수 있다. 이 리소스 타입은 Terraform에서 미리 정의된 이름이므로 문서를 봐야 한다. 그 뒤에 온 example, example-a 같은 이름은 알아보기 쉽게 이름을 직접 지정한 것이다. 

example이라는 VPC를 정의하고 서브넷을 정의할 때는 앞에서 정의한 리소스의 ID를 `${aws_vpc.example.id}`처럼 참조해서 VPC 내에 서브넷을 정의했다.

VPC에서 사용할 시큐리티 그룹을 정의해보자. 다음 파일은 security-group.tf의 내용이다.

```hcl
resource "aws_security_group" "example-allow-all" {
  name = "example-allow_all"
  description = "Allow all inbound traffic"
  vpc_id = "${aws_vpc.example.id}"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

여기서도 마찬가지로 인바운드/아웃바운드를 모두 허용하는 시큐리티 그룹을 VPC 내에서 생성하는 설정이다.

```bash
├── aws.tf
├── security-group.tf
└── vpc.tf
```

이제 현재 디렉터리의 위처럼 3개의 파일이 존재한다. Terraform이 로딩은 알파벳순으로, 의존성 관계는 알아서 맺어주므로 리소스 정의 순서는 전혀 상관없다.

## Terraform으로 적용하기

이제 실제로 Terraform을 사용해보자.

우선 `terraform plan` 명령어로 설정이 이상 없는지도 확인하고 실제로 적용하면 인프라가 어떻게 달라지는지 확인할 수 있다. 현재 폴더에서 `terraform plan` 명령어를 실행한다.

```bash
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but
will not be persisted to local or remote state storage.


The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed. Cyan entries are data sources to be read.

Note: You didn't specify an "-out" parameter to save this plan, so when
"apply" is called, Terraform can't guarantee this is what will execute.

+ aws_security_group.example-allow-all
    description:                         "Allow all inbound traffic"
    egress.#:                            "1"
    egress.482069346.cidr_blocks.#:      "1"
    egress.482069346.cidr_blocks.0:      "0.0.0.0/0"
    egress.482069346.from_port:          "0"
    egress.482069346.prefix_list_ids.#:  "0"
    egress.482069346.protocol:           "-1"
    egress.482069346.security_groups.#:  "0"
    egress.482069346.self:               "false"
    egress.482069346.to_port:            "0"
    ingress.#:                           "1"
    ingress.482069346.cidr_blocks.#:     "1"
    ingress.482069346.cidr_blocks.0:     "0.0.0.0/0"
    ingress.482069346.from_port:         "0"
    ingress.482069346.protocol:          "-1"
    ingress.482069346.security_groups.#: "0"
    ingress.482069346.self:              "false"
    ingress.482069346.to_port:           "0"
    name:                                "example-allow_all"
    owner_id:                            "<computed>"
    vpc_id:                              "${aws_vpc.example.id}"

+ aws_subnet.example-a
    availability_zone:       "ap-northeast-1a"
    cidr_block:              "172.10.0.0/24"
    map_public_ip_on_launch: "false"
    vpc_id:                  "${aws_vpc.example.id}"

+ aws_subnet.example-c
    availability_zone:       "ap-northeast-1c"
    cidr_block:              "172.10.1.0/24"
    map_public_ip_on_launch: "false"
    vpc_id:                  "${aws_vpc.example.id}"

+ aws_vpc.example
    cidr_block:                "172.10.0.0/20"
    default_network_acl_id:    "<computed>"
    default_route_table_id:    "<computed>"
    default_security_group_id: "<computed>"
    dhcp_options_id:           "<computed>"
    enable_classiclink:        "<computed>"
    enable_dns_hostnames:      "<computed>"
    enable_dns_support:        "true"
    instance_tenancy:          "<computed>"
    main_route_table_id:       "<computed>"
    tags.%:                    "1"
    tags.Name:                 "example"


Plan: 4 to add, 0 to change, 0 to destroy.
```

새로 추가되는 설정은 +로 표시되는데, 다음 4개가 추가된 것을 볼 수 있다.

```bash
+ aws_security_group.example-allow-all
+ aws_subnet.example-a
+ aws_subnet.example-c
+ aws_vpc.example
```

이 plan 기능은 미리 구성을 테스트해볼 수 있다는 점에서 매력적이고, 실수로 인프라를 변경하지 않도록 확인해 볼 수 있는 장치이기도 하다. 그래서 HCL 파일을 작성하면서 plan으로 확인해 보고 다시 변경해보고 하면서 사용할 수 있다.

plan에 이상이 없으므로 이제 적용해보자. 적용은 `terraform apply` 명령어를 사용한다.


```bash
$ terraform apply
aws_vpc.example: Creating...
  cidr_block:                "" => "172.10.0.0/20"
  default_network_acl_id:    "" => "<computed>"
  default_route_table_id:    "" => "<computed>"
  default_security_group_id: "" => "<computed>"
  dhcp_options_id:           "" => "<computed>"
  enable_classiclink:        "" => "<computed>"
  enable_dns_hostnames:      "" => "<computed>"
  enable_dns_support:        "" => "true"
  instance_tenancy:          "" => "<computed>"
  main_route_table_id:       "" => "<computed>"
  tags.%:                    "" => "1"
  tags.Name:                 "" => "example"
aws_vpc.example: Creation complete
aws_subnet.example-a: Creating...
  availability_zone:       "" => "ap-northeast-1a"
  cidr_block:              "" => "172.10.0.0/24"
  map_public_ip_on_launch: "" => "false"
  vpc_id:                  "" => "vpc-14ff2570"
aws_subnet.example-c: Creating...
  availability_zone:       "" => "ap-northeast-1c"
  cidr_block:              "" => "172.10.1.0/24"
  map_public_ip_on_launch: "" => "false"
  vpc_id:                  "" => "vpc-14ff2570"
aws_security_group.example-allow-all: Creating...
  description:                         "" => "Allow all inbound traffic"
  egress.#:                            "" => "1"
  egress.482069346.cidr_blocks.#:      "" => "1"
  egress.482069346.cidr_blocks.0:      "" => "0.0.0.0/0"
  egress.482069346.from_port:          "" => "0"
  egress.482069346.prefix_list_ids.#:  "" => "0"
  egress.482069346.protocol:           "" => "-1"
  egress.482069346.security_groups.#:  "" => "0"
  egress.482069346.self:               "" => "false"
  egress.482069346.to_port:            "" => "0"
  ingress.#:                           "" => "1"
  ingress.482069346.cidr_blocks.#:     "" => "1"
  ingress.482069346.cidr_blocks.0:     "" => "0.0.0.0/0"
  ingress.482069346.from_port:         "" => "0"
  ingress.482069346.protocol:          "" => "-1"
  ingress.482069346.security_groups.#: "" => "0"
  ingress.482069346.self:              "" => "false"
  ingress.482069346.to_port:           "" => "0"
  name:                                "" => "example-allow_all"
  owner_id:                            "" => "<computed>"
  vpc_id:                              "" => "vpc-14ff2570"
aws_subnet.example-a: Creation complete
aws_subnet.example-c: Creation complete
aws_security_group.example-allow-all: Creation complete

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
```

적용이 완료되었다. 제대로 적용되었는지 AWS에 들어가서 확인해 보자.

설정한 VPC, Subnet, Security Group이 모두 정상적으로 만들어 진 것을 볼 수 있다.

```hcl
resource "aws_vpc" "example" {
  cidr_block = "172.10.0.0/20"
  tags {
    Name = "example"
  }
}
```

앞에서 정의한 VPC 구성을 보면 여기서 리소스 이름의 example은 실제 AWS 구성되는 이름과는 아무런 상관이 없고 Terraform에서 참조하기 위해서 이름을 할당한 것일 뿐이다. 그래서 VPC의 이름으로 표시되는 것은 tags에서 `Name = "example"`로 설정한 이름이 지정된다.

추가로 apply한 마지막 로그를 보면 `State path: terraform.tfstate`라고 나온 걸 볼 수 있는데 이는 적용한 인프라의 상태를 관리하는 파일로 다음과 같이 hcl으로 되어 있다. 적용된 인프라를 이 파일에서 관리하고 있으므로 Terraform으로 인프라를 관리한다면 `terraform.tfstate` 파일도 Git 등으로 관리하고 보관해야 한다. 이후 적용하면 `terraform.tfstate.backup `파일이 하나 생기면서 마지막 버전을 하나 더 보관한다.

```hcl
{
    "version": 3,
    "terraform_version": "0.8.2",
    "serial": 0,
    "lineage": "d7b033b3-03a4-4020-b389-fe8f7e95dec0",
    "modules": [
        {
            "path": [
                "root"
            ],
            "outputs": {},
            "resources": {
                "aws_security_group.example-allow-all": {
                    "type": "aws_security_group",
                    "depends_on": [
                        "aws_vpc.example"
                    ],
                    "primary": {
                        "id": "sg-d2fa7db5",
                        "attributes": {
                            "description": "Allow all inbound traffic",
                            "egress.#": "1",
                            "egress.482069346.cidr_blocks.#": "1",
                            "egress.482069346.cidr_blocks.0": "0.0.0.0/0",
                            "egress.482069346.from_port": "0",
                            "egress.482069346.prefix_list_ids.#": "0",
                            "egress.482069346.protocol": "-1",
                            "egress.482069346.security_groups.#": "0",
                            "egress.482069346.self": "false",
                            "egress.482069346.to_port": "0",
                            "id": "sg-d2fa7db5",
                            "ingress.#": "1",
                            "ingress.482069346.cidr_blocks.#": "1",
                            "ingress.482069346.cidr_blocks.0": "0.0.0.0/0",
                            "ingress.482069346.from_port": "0",
                            "ingress.482069346.protocol": "-1",
                            "ingress.482069346.security_groups.#": "0",
                            "ingress.482069346.self": "false",
                            "ingress.482069346.to_port": "0",
                            "name": "example-allow_all",
                            "owner_id": "410655858509",
                            "tags.%": "0",
                            "vpc_id": "vpc-14ff2570"
                        },
                        "meta": {},
                        "tainted": false
                    },
                    "deposed": [],
                    "provider": ""
                },
                "aws_subnet.example-a": {
                    "type": "aws_subnet",
                    "depends_on": [
                        "aws_vpc.example"
                    ],
                    "primary": {
                        "id": "subnet-4fbcdb39",
                        "attributes": {
                            "availability_zone": "ap-northeast-1a",
                            "cidr_block": "172.10.0.0/24",
                            "id": "subnet-4fbcdb39",
                            "map_public_ip_on_launch": "false",
                            "tags.%": "0",
                            "vpc_id": "vpc-14ff2570"
                        },
                        "meta": {},
                        "tainted": false
                    },
                    "deposed": [],
                    "provider": ""
                },
                "aws_subnet.example-c": {
                    "type": "aws_subnet",
                    "depends_on": [
                        "aws_vpc.example"
                    ],
                    "primary": {
                        "id": "subnet-40b81718",
                        "attributes": {
                            "availability_zone": "ap-northeast-1c",
                            "cidr_block": "172.10.1.0/24",
                            "id": "subnet-40b81718",
                            "map_public_ip_on_launch": "false",
                            "tags.%": "0",
                            "vpc_id": "vpc-14ff2570"
                        },
                        "meta": {},
                        "tainted": false
                    },
                    "deposed": [],
                    "provider": ""
                },
                "aws_vpc.example": {
                    "type": "aws_vpc",
                    "depends_on": [],
                    "primary": {
                        "id": "vpc-14ff2570",
                        "attributes": {
                            "cidr_block": "172.10.0.0/20",
                            "default_network_acl_id": "acl-2b28b94f",
                            "default_route_table_id": "rtb-ff04639b",
                            "default_security_group_id": "sg-d3fa7db4",
                            "dhcp_options_id": "dopt-a30b4bc6",
                            "enable_classiclink": "false",
                            "enable_dns_hostnames": "false",
                            "enable_dns_support": "true",
                            "id": "vpc-14ff2570",
                            "instance_tenancy": "default",
                            "main_route_table_id": "rtb-ff04639b",
                            "tags.%": "1",
                            "tags.Name": "example"
                        },
                        "meta": {},
                        "tainted": false
                    },
                    "deposed": [],
                    "provider": ""
                }
            },
            "depends_on": []
        }
    ]
}
```

`terraform show` 명령어로 적용된 내용을 확인해 볼 수 있다.

## EC2 인스턴스 구성

이제 EC2 인스턴스를 구성해 보자. `aws-ec2.tf`라는 파일로 다음의 내용을 넣는다.

```hcl
variable "key_pair" {
  default = "outsider-aws"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "example-server" {
    ami = "${data.aws_ami.ubuntu.id}"
    instance_type = "t2.micro"
    subnet_id = "${aws_subnet.example-a.id}"
    vpc_security_group_ids = ["${aws_security_group.example-allow-all.id}"]
    key_name = "${var.key_pair}"
    count = 3
    tags {
        Name = "examples"
    }
}
```

여기서 처음으로 `data` 키워드로 데이터소스를 정의했다. 데이터소스는 프로바이더에서 값을 가져오는 기능을 하는데 `aws_ami`로 타입을 지정하고 Canonical에서 등록한 Ubuntu 16.04의 AMI ID를 조회해 온 것이다. 이런 식으로 최신 Amazon Linux의 AMI를 조회해서 사용한다거나 할 수 있어서 이런 값을 하드 코딩할 필요가 없다.

그 아래 `aws_instance`는 EC2 인스턴스를 지정한 것이다. `t2.micro`로 띄우고 앞에서 조회한 AMI의 ID를 사용하도록 했다. 그리고 위에서 정의한 VPC와 subnet을 사용하고 키는 선언해놓은 `var.key_pair` 변수를 참조하도록 했다. count=3이므로 서버는 3대를 띄우겠다는 의미이다.

이제 plan을 먼저 실행해보자.

```bash
$ terraform plan
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but
will not be persisted to local or remote state storage.

aws_vpc.example: Refreshing state... (ID: vpc-14ff2570)
data.aws_ami.ubuntu: Refreshing state...
aws_subnet.example-a: Refreshing state... (ID: subnet-4fbcdb39)
aws_subnet.example-c: Refreshing state... (ID: subnet-40b81718)
aws_security_group.example-allow-all: Refreshing state... (ID: sg-d2fa7db5)

The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed. Cyan entries are data sources to be read.

Note: You didn't specify an "-out" parameter to save this plan, so when
"apply" is called, Terraform can't guarantee this is what will execute.

+ aws_instance.example-server.0
    ami:                               "ami-18afc47f"
    associate_public_ip_address:       "<computed>"
    availability_zone:                 "<computed>"
    ebs_block_device.#:                "<computed>"
    ephemeral_block_device.#:          "<computed>"
    instance_state:                    "<computed>"
    instance_type:                     "t2.micro"
    key_name:                          "outsider-aws"
    network_interface_id:              "<computed>"
    placement_group:                   "<computed>"
    private_dns:                       "<computed>"
    private_ip:                        "<computed>"
    public_dns:                        "<computed>"
    public_ip:                         "<computed>"
    root_block_device.#:               "<computed>"
    security_groups.#:                 "<computed>"
    source_dest_check:                 "true"
    subnet_id:                         "subnet-4fbcdb39"
    tags.%:                            "1"
    tags.Name:                         "examples"
    tenancy:                           "<computed>"
    vpc_security_group_ids.#:          "1"
    vpc_security_group_ids.2117745025: "sg-d2fa7db5"

+ aws_instance.example-server.1
    ami:                               "ami-18afc47f"
    associate_public_ip_address:       "<computed>"
    availability_zone:                 "<computed>"
    ebs_block_device.#:                "<computed>"
    ephemeral_block_device.#:          "<computed>"
    instance_state:                    "<computed>"
    instance_type:                     "t2.micro"
    key_name:                          "outsider-aws"
    network_interface_id:              "<computed>"
    placement_group:                   "<computed>"
    private_dns:                       "<computed>"
    private_ip:                        "<computed>"
    public_dns:                        "<computed>"
    public_ip:                         "<computed>"
    root_block_device.#:               "<computed>"
    security_groups.#:                 "<computed>"
    source_dest_check:                 "true"
    subnet_id:                         "subnet-4fbcdb39"
    tags.%:                            "1"
    tags.Name:                         "examples"
    tenancy:                           "<computed>"
    vpc_security_group_ids.#:          "1"
    vpc_security_group_ids.2117745025: "sg-d2fa7db5"

+ aws_instance.example-server.2
    ami:                               "ami-18afc47f"
    associate_public_ip_address:       "<computed>"
    availability_zone:                 "<computed>"
    ebs_block_device.#:                "<computed>"
    ephemeral_block_device.#:          "<computed>"
    instance_state:                    "<computed>"
    instance_type:                     "t2.micro"
    key_name:                          "outsider-aws"
    network_interface_id:              "<computed>"
    placement_group:                   "<computed>"
    private_dns:                       "<computed>"
    private_ip:                        "<computed>"
    public_dns:                        "<computed>"
    public_ip:                         "<computed>"
    root_block_device.#:               "<computed>"
    security_groups.#:                 "<computed>"
    source_dest_check:                 "true"
    subnet_id:                         "subnet-4fbcdb39"
    tags.%:                            "1"
    tags.Name:                         "examples"
    tenancy:                           "<computed>"
    vpc_security_group_ids.#:          "1"
    vpc_security_group_ids.2117745025: "sg-d2fa7db5"


Plan: 3 to add, 0 to change, 0 to destroy.
```

EC2 인스턴스 3대가 잘 표시되었으므로 이제 실제로 적용해보자.

```bash
terraform apply
aws_vpc.example: Refreshing state... (ID: vpc-14ff2570)
data.aws_ami.ubuntu: Refreshing state...
aws_subnet.example-c: Refreshing state... (ID: subnet-40b81718)
aws_security_group.example-allow-all: Refreshing state... (ID: sg-d2fa7db5)
aws_subnet.example-a: Refreshing state... (ID: subnet-4fbcdb39)
aws_instance.example-server.1: Creating...
  ami:                               "" => "ami-18afc47f"
  associate_public_ip_address:       "" => "<computed>"
  availability_zone:                 "" => "<computed>"
  ebs_block_device.#:                "" => "<computed>"
  ephemeral_block_device.#:          "" => "<computed>"
  instance_state:                    "" => "<computed>"
  instance_type:                     "" => "t2.micro"
  key_name:                          "" => "outsider-aws"
  network_interface_id:              "" => "<computed>"
  placement_group:                   "" => "<computed>"
  private_dns:                       "" => "<computed>"
  private_ip:                        "" => "<computed>"
  public_dns:                        "" => "<computed>"
  public_ip:                         "" => "<computed>"
  root_block_device.#:               "" => "<computed>"
  security_groups.#:                 "" => "<computed>"
  source_dest_check:                 "" => "true"
  subnet_id:                         "" => "subnet-4fbcdb39"
  tags.%:                            "" => "1"
  tags.Name:                         "" => "examples"
  tenancy:                           "" => "<computed>"
  vpc_security_group_ids.#:          "" => "1"
  vpc_security_group_ids.2117745025: "" => "sg-d2fa7db5"
aws_instance.example-server.0: Creating...
  ami:                               "" => "ami-18afc47f"
  associate_public_ip_address:       "" => "<computed>"
  availability_zone:                 "" => "<computed>"
  ebs_block_device.#:                "" => "<computed>"
  ephemeral_block_device.#:          "" => "<computed>"
  instance_state:                    "" => "<computed>"
  instance_type:                     "" => "t2.micro"
  key_name:                          "" => "outsider-aws"
  network_interface_id:              "" => "<computed>"
  placement_group:                   "" => "<computed>"
  private_dns:                       "" => "<computed>"
  private_ip:                        "" => "<computed>"
  public_dns:                        "" => "<computed>"
  public_ip:                         "" => "<computed>"
  root_block_device.#:               "" => "<computed>"
  security_groups.#:                 "" => "<computed>"
  source_dest_check:                 "" => "true"
  subnet_id:                         "" => "subnet-4fbcdb39"
  tags.%:                            "" => "1"
  tags.Name:                         "" => "examples"
  tenancy:                           "" => "<computed>"
  vpc_security_group_ids.#:          "" => "1"
  vpc_security_group_ids.2117745025: "" => "sg-d2fa7db5"
aws_instance.example-server.2: Creating...
  ami:                               "" => "ami-18afc47f"
  associate_public_ip_address:       "" => "<computed>"
  availability_zone:                 "" => "<computed>"
  ebs_block_device.#:                "" => "<computed>"
  ephemeral_block_device.#:          "" => "<computed>"
  instance_state:                    "" => "<computed>"
  instance_type:                     "" => "t2.micro"
  key_name:                          "" => "outsider-aws"
  network_interface_id:              "" => "<computed>"
  placement_group:                   "" => "<computed>"
  private_dns:                       "" => "<computed>"
  private_ip:                        "" => "<computed>"
  public_dns:                        "" => "<computed>"
  public_ip:                         "" => "<computed>"
  root_block_device.#:               "" => "<computed>"
  security_groups.#:                 "" => "<computed>"
  source_dest_check:                 "" => "true"
  subnet_id:                         "" => "subnet-4fbcdb39"
  tags.%:                            "" => "1"
  tags.Name:                         "" => "examples"
  tenancy:                           "" => "<computed>"
  vpc_security_group_ids.#:          "" => "1"
  vpc_security_group_ids.2117745025: "" => "sg-d2fa7db5"
aws_instance.example-server.1: Still creating... (10s elapsed)
aws_instance.example-server.2: Still creating... (10s elapsed)
aws_instance.example-server.0: Still creating... (10s elapsed)
aws_instance.example-server.1: Still creating... (20s elapsed)
aws_instance.example-server.2: Still creating... (20s elapsed)
aws_instance.example-server.0: Still creating... (20s elapsed)
aws_instance.example-server.1: Creation complete
aws_instance.example-server.2: Creation complete
aws_instance.example-server.0: Creation complete

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
```

AWS 웹 콘솔에 가면 3대가 잘 뜬 걸 볼 수 있다.

이런 식으로 필요한 리소스를 관리하고 설정을 변경하면서 관리하면 인프라를 모두 코드로 관리할 수 있다.

## 리소스 그래프
`terraform graph` 명령어를 사용하면 설정한 리소스의 의존성 그래프를 그릴 수 있다.

```hcl
$ terraform graph
digraph {
  compound = "true"
  newrank = "true"
  subgraph "root" {
    "[root] aws_instance.example-server" [label = "aws_instance.example-server", shape = "box"]
    "[root] aws_security_group.example-allow-all" [label = "aws_security_group.example-allow-all", shape = "box"]
    "[root] aws_subnet.example-a" [label = "aws_subnet.example-a", shape = "box"]
    "[root] aws_subnet.example-c" [label = "aws_subnet.example-c", shape = "box"]
    "[root] aws_vpc.example" [label = "aws_vpc.example", shape = "box"]
    "[root] data.aws_ami.ubuntu" [label = "data.aws_ami.ubuntu", shape = "box"]
    "[root] provider.aws" [label = "provider.aws", shape = "diamond"]
    "[root] aws_instance.example-server" -> "[root] aws_security_group.example-allow-all"
    "[root] aws_instance.example-server" -> "[root] aws_subnet.example-a"
    "[root] aws_instance.example-server" -> "[root] data.aws_ami.ubuntu"
    "[root] aws_instance.example-server" -> "[root] var.key_pair"
    "[root] aws_security_group.example-allow-all" -> "[root] aws_vpc.example"
    "[root] aws_subnet.example-a" -> "[root] aws_vpc.example"
    "[root] aws_subnet.example-c" -> "[root] aws_vpc.example"
    "[root] aws_vpc.example" -> "[root] provider.aws"
    "[root] data.aws_ami.ubuntu" -> "[root] provider.aws"
    "[root] root" -> "[root] aws_instance.example-server"
    "[root] root" -> "[root] aws_subnet.example-c"
  }
}
```

이 형식은 GraphViz 형식이므로 그래프를 그려주는 서비스에 접근하면 의존성 그래프를 그려준다.

<img width="613" alt="image" src="https://github.com/rlaisqls/rlaisqls/assets/81006587/95132354-8c42-455b-b055-5a73e2deece6">

## 인프라 삭제

실제로 운영할 때는 전체 인프라를 삭제할 일은 없겠지만, 삭제 기능도 제공한다. 실제 사용할 때는 아마 일부 구성을 지우고 적용하는 접근을 할 것이다.

`terraform plan -destroy`처럼 plan에 -destroy 옵션을 제공하면 전체 삭제에 대한 플랜을 볼 수 있다.

```bash
$ terraform plan -destroy
Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but
will not be persisted to local or remote state storage.

aws_vpc.example: Refreshing state... (ID: vpc-14ff2570)
data.aws_ami.ubuntu: Refreshing state...
aws_subnet.example-a: Refreshing state... (ID: subnet-4fbcdb39)
aws_subnet.example-c: Refreshing state... (ID: subnet-40b81718)
aws_security_group.example-allow-all: Refreshing state... (ID: sg-d2fa7db5)
aws_instance.example-server.1: Refreshing state... (ID: i-0d3d99af50750c06b)
aws_instance.example-server.0: Refreshing state... (ID: i-08e00391c847c219f)
aws_instance.example-server.2: Refreshing state... (ID: i-03a26df56274ab044)

The Terraform execution plan has been generated and is shown below.
Resources are shown in alphabetical order for quick scanning. Green resources
will be created (or destroyed and then created if an existing resource
exists), yellow resources are being changed in-place, and red resources
will be destroyed. Cyan entries are data sources to be read.

Note: You didn't specify an "-out" parameter to save this plan, so when
"apply" is called, Terraform can't guarantee this is what will execute.

- aws_instance.example-server.0

- aws_instance.example-server.1

- aws_instance.example-server.2

- aws_security_group.example-allow-all

- aws_subnet.example-a

- aws_subnet.example-c

- aws_vpc.example

- data.aws_ami.ubuntu


Plan: 0 to add, 0 to change, 7 to destroy.
```

모두 지워지는 것을 확인했으므로 이제 terraform destroy를 실행하면 여기서 설정한 모든 구성이 제거된다.

```bash
$ terraform destroy
Do you really want to destroy?
  Terraform will delete all your managed infrastructure.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: ㅛyes

aws_vpc.example: Refreshing state... (ID: vpc-14ff2570)
data.aws_ami.ubuntu: Refreshing state...
aws_subnet.example-a: Refreshing state... (ID: subnet-4fbcdb39)
aws_subnet.example-c: Refreshing state... (ID: subnet-40b81718)
aws_security_group.example-allow-all: Refreshing state... (ID: sg-d2fa7db5)
aws_instance.example-server.0: Refreshing state... (ID: i-08e00391c847c219f)
aws_instance.example-server.2: Refreshing state... (ID: i-03a26df56274ab044)
aws_instance.example-server.1: Refreshing state... (ID: i-0d3d99af50750c06b)
aws_subnet.example-c: Destroying...
aws_instance.example-server.2: Destroying...
aws_instance.example-server.0: Destroying...
aws_instance.example-server.1: Destroying...
aws_subnet.example-c: Destruction complete
aws_instance.example-server.0: Still destroying... (10s elapsed)
aws_instance.example-server.2: Still destroying... (10s elapsed)
aws_instance.example-server.1: Still destroying... (10s elapsed)
aws_instance.example-server.2: Still destroying... (20s elapsed)
aws_instance.example-server.0: Still destroying... (20s elapsed)
aws_instance.example-server.1: Still destroying... (20s elapsed)
aws_instance.example-server.2: Still destroying... (30s elapsed)
aws_instance.example-server.0: Still destroying... (30s elapsed)
aws_instance.example-server.1: Still destroying... (30s elapsed)
aws_instance.example-server.2: Still destroying... (40s elapsed)
aws_instance.example-server.0: Still destroying... (40s elapsed)
aws_instance.example-server.1: Still destroying... (40s elapsed)
aws_instance.example-server.1: Still destroying... (50s elapsed)
aws_instance.example-server.2: Still destroying... (50s elapsed)
aws_instance.example-server.0: Still destroying... (50s elapsed)
aws_instance.example-server.2: Destruction complete
aws_instance.example-server.1: Destruction complete
aws_instance.example-server.0: Still destroying... (1m0s elapsed)
aws_instance.example-server.0: Destruction complete
aws_security_group.example-allow-all: Destroying...
aws_subnet.example-a: Destroying...
aws_subnet.example-a: Destruction complete
aws_security_group.example-allow-all: Destruction complete
aws_vpc.example: Destroying...
aws_vpc.example: Destruction complete

Destroy complete! Resources: 7 destroyed.
```
