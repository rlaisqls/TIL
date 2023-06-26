# resource

resource는 테라폼에서 가장 중요한 요소이다. resource 블록은 하나 이상의 인프라스트럭처의 오브젝트를 기술한다. 아래는 providers로 AWS를 사용하고 있을 때 인스턴스를 사용하는 예제이다.

resource "aws_instance" "web" {
  ami           = "ami-a1b2c3d4"
  instance_type = "t2.micro"
}
위에 첫 번째 라인을 살펴보면 resource 옆에 첫 번째 자리는 리소스 타입으로 “aws_instance”를 써주고 두 번째 자리에는 “web”을 적어줬습니다. 리소스 타입은 사전에 정의된 AWS 리소스 이름이다. 여기서 “aws_instance”는 인스턴스를 나타내고 있습니다. aws라는 프로바이더 정보를 prefix로 사용하고 있는 것을 알 수 있습니다. HCL에서 key-value 조합으로 코드를 쓸 때 등호(=)는 보통 라인을 맞춰서 사용한다. 

resource 옆 두 번째 자리에 `web`은 실제 생성되는 리소스의 이름과 별개로 테라폼 내에서 사용될 이름을 써준 것이다. 또한 providers에 따라 사용 가능한 resource 타입이 다릅니다.

각 resource는 오직 한 개의 리소스 타입만을 갖는다.

```json
resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_network_interface" "foo" {
  subnet_id   = aws_subnet.my_subnet.id
  private_ips = ["172.16.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "foo" {
  ami           = "ami-005e54dee72cc1d00" # us-west-2
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.foo.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}
```

resource 블록 바디에는 ami, instance_type이 지정되었는데 AWS 리소스에서 사용 가능한 매개변수를 적어주면 됩니다. AWS 콘솔에서 설정하는 변수는 대부분 사용 가능하다. 

resource "aws_db_instance" "example" {
  # ...

  timeouts {
    create = "60m"
    delete = "2h"
  }
}
사용 가능한 매개변수는 아래 링크를 참고하세요.
registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

 

# environment variables

AWS_ACCESS_KEY 처럼 중요한 정보는 환경변수로 관리해 줍니다. terraform에서 읽히도록 환경변수 이름은 TF_VAR_ 을 Prefix로 사용해 줍니다.

export TF_VAR_aws_access_key="blabla"
 

development, staging, production 환경에 상관없는 공통으로 적용되는 변수는 terraform.tfvars과 같은 파일로 관리한다. 이 파일은 terraform apply 명령에서 자동으로 읽힙니다. 파일 형식은 다음과 같이 지정한다.

# terraform.tfvars
region = "us-west-2"
cidrs = [ "10.0.0.0/16", "10.1.0.0/16" ]
환경에 따라 구분되어야 하는 변수는 production.tfvars, development.tfvars처럼 별도의 파일로 관리해 줍시다.

terraform apply는 아래와 같이 -var-file 옵션과 함께 사용해 줍니다. 위에서 설정한 환경변수가 적용됩니다. 자동으로 읽히는 terraform.tfvars 는 -var-file로 굳이 지정할 필요가 없습니다.

terraform apply \
  -var-file="secret.tfvars" \
  -var-file="production.tfvars"
변수는 사용 예시는 다음과 같습니다. var.region를 적어주면 plan, apply 시에 us-west-2로 대치돼서 사용됩니다.

provider "aws" {
  profile = "default"
  region  = var.region
}
 

# normal variables

한편, 환경변수 외에 변수는 variables.tf 파일에 지정해주면 됩니다. 파일 이름은 뭐든 상관없습니다. terraform은 확장자가 tf인 모든 파일을 읽어 들이다. 아래는 위에서 지정한 환경변수를 tf 파일에 담아내는 예제이다. (앞에 글에서도 이야기했지만 terraform 명령어가 실행되는 디렉터리에 있는 파일만 읽어 들이다. 다른 경로의 tf 파일을 읽기 위해서는 module을 사용해야 한다) 

# variables.tf
variable "region" {
  default = "us-west-2"
}
 

map은 아래와 같이 사용하면 됩니다.

# variables.tf
variable "amis" {
  type = "map"
  default = {
    "us-east-1" = "ami-b374d5a5"
    "us-west-2" = "ami-fc0b939c"
  }
}
 

위에서 설정한 변수와 환경변수를 조합해서 resource를 생성하는 예제를 통해 변수가 어떻게 사용이 되는지 살펴봅시다. variables.tf에 있는 변수를 var.amis를 통해 가져왔고, 환경변수 var.regionvar.region을 사용해주는 예제이다.

resource "aws_instance" "example" {
  ami           = var.amis[var.region]
  instance_type = "t2.micro"
}
 

# output

복잡한 인프라를 구축할 때 테라폼은 리소스의 수백, 수천 개의 속성을 저장한다. 하지만 사용자에게 이 모든 것들이 관심사는 아니죠. 보통은 LB에 할당된 IP라던지, VPN 주소 등만 궁금할 겁니다. output은 테라폼이 apply 될 때 지정된 리소스를 출력해 줍니다. 혹은 terraform output으로 확인할 수 있습니다.

아래는 테라폼의 공식 예제로 AWS에 인스턴스를 생성하고 Elastic IP를 연결하는 코드이다.

# example.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_instance" "example" {
  ami           = "ami-08d70e59c07c61a3a"
  instance_type = "t2.micro"
}

resource "aws_eip" "ip" {
  vpc      = true
  instance = aws_instance.example.id
} 
 

위 예제에서 생성되는 eip는 다음과 같이 output.tf 파일을 생성해서 확인할 수 있습니다. 파일 이름은 중요하지 않습니다. 앞에 과정에서 이야기했듯이 테라폼은 확장자가 tf인 모든 파일을 읽습니다. public_ippublic_ip는 위에서 생성한 aws_eip의 사전에 정의된 속성이다.

output "ip" {
  value = aws_eip.ip.public_ip
} 
 

terraform apply가 되면 아래와 같은 출력을 확인할 수 있습니다.

$ terraform apply
...

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

  ip = 50.17.232.209
또한 다음과 같이 terraform output을 통해 관심사만 뽑아볼 수 있습니다.

$ terraform output ip
50.17.232.209
 

# data source

data source는 data 블록을 통해 사용할 수 있습니다. 프로바이더에서 제공하는 리소스 정보를 가져와서 테라폼에서 사용할 수 있는 형태로 매핑시킬 수 있습니다. 즉, 이미 클라우드 콘솔에 존재하는 리소스를 가져오는 겁니다. 아래 예시를 살펴봅시다.

data "aws_ami" "example" {
  most_recent = true

  owners = ["self"]
  tags = {
    Name   = "app-server"
    Tested = "true"
  }
}
“aws_ami”의 prefix 정보를 통해 우리는 프로바이더가 AWS라는 것을 알 수 있습니다. data 블록에 지정된 tags 정보를 기반으로 이름이 “app-server”, Tested 필드가 “true”인 AMI 정보를 가져오게 됩니다.

다음과 같이 필터를 통해 정보를 가져오는 방법도 있습니다.

# Find the latest available AMI that is tagged with Component = web
data "aws_ami" "web" {
  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:Component"
    values = ["web"]
  }

  most_recent = true
}
 

이렇게 가져온 정보는 인스턴스를 생성하는 리소스에서 다음과 같이 data.aws_ami.web.id처럼 사용됩니다.

resource "aws_instance" "web" {
  ami           = data.aws_ami.web.id
  instance_type = "t1.micro"
}