
terraform taint는 특정 리소스를 "tainted" 상태로 표시하여, 다음 terraform apply 때 해당 리소스를 강제로 다시 만들게 한다. 특정 리소스를 교체해서 테스트하거나 디버깅해보고 싶을때 taint를 이용할 수 있다.

### 예제

igw에 장애가 있다고 가정해보자. 우선 `tf state list`를 통해 state 목록을 출력한다.

```bash
$ tf state list
module.route_table__private.aws_resourcegroups_group.this[0]
module.route_table__private.aws_route_table.this
module.route_table__private.aws_route_table_association.subnets[0]
module.route_table__private.aws_route_table_association.subnets[1]
module.route_table__public.aws_resourcegroups_group.this[0]
module.route_table__public.aws_route.ipv4["0.0.0.0/0"]
module.route_table__public.aws_route_table.this
module.route_table__public.aws_route_table_association.subnets[0]
module.route_table__public.aws_route_table_association.subnets[1]
module.subnet_group__private.aws_resourcegroups_group.this[0]
module.subnet_group__private.aws_subnet.this["default-private-001/az1"]
module.subnet_group__private.aws_subnet.this["default-private-002/az2"]
module.subnet_group__public.aws_resourcegroups_group.this[0]
module.subnet_group__public.aws_subnet.this["default-public-001/az1"]
module.subnet_group__public.aws_subnet.this["default-public-002/az2"]
module.vpc.data.aws_region.current
module.vpc.aws_internet_gateway.this[0]
module.vpc.aws_resourcegroups_group.this[0]
module.vpc.aws_vpc.this
```

`taint` 명령어로 다시 생성할 요소를 지정한다.

```bash
tf taint 'module.vpc.aws_internet_gateway.this[0]'
>>>
Resource instance module.vpc.aws_internet_gateway.this[0] has been marked as tainted.
```

`tf apply`를 입력하면 igw에 연결되어있던 라우팅 테이블 규칙이 다시 생성된다.

```bash
$ tf apply
>>>
# 중략
Terraform will perform the following actions:

  # module.route_table__public.aws_route.ipv4["0.0.0.0/0"] will be updated in-place
  ~ resource "aws_route" "ipv4" {
      ~ gateway_id             = "igw-09be7ce12b07438cf" -> (known after apply)
        id                     = "r-rtb-0314c188a357c38491080289494"
        # (4 unchanged attributes hidden)
    }

  # module.vpc.aws_internet_gateway.this[0] is tainted, so must be replaced
-/+ resource "aws_internet_gateway" "this" {
      ~ arn      = "arn:aws:ec2:ap-northeast-2:671393671211:internet-gateway/igw-09be7ce12b07438cf" -> (known after apply)
      ~ id       = "igw-09be7ce12b07438cf" -> (known after apply)
      ~ owner_id = "671393671211" -> (known after apply)
        tags     = {
            "Name"                          = "default"
            "Owner"                         = "posquit0"
            "Project"                       = "Network"
            "module.terraform.io/full-name" = "terraform-aws-network/vpc"
            "module.terraform.io/instance"  = "default"
            "module.terraform.io/name"      = "vpc"
            "module.terraform.io/package"   = "terraform-aws-network"
            "module.terraform.io/version"   = "0.24.0"
        }
        # (2 unchanged attributes hidden)
    }

Plan: 1 to add, 1 to change, 1 to destroy.
```

taint 상태를 제거하고 싶다면, `terraform untaint` 명령어를 사용하면 된다.

```bash
tf untaint 'module.vpc.aws_internet_gateway.this[0]'
```

리소스를 갱신하고 싶을 때, taint 외에도 아래와 같은 방법을 사용할 수 있다:

```bash
terraform plan -replace=resource
terraform apply -replace=resource
```

이러한 방법은 하나의 리소스를 대체할 때 유용하며, 여러 리소스를 갱신하고 싶을 때는 **taint**를 사용하는 것이 좋다.