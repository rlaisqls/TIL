
이미 사용하고 있는 인프라를 Terraform으로 가져오려면 import 명령어를 사용해야한다.

> The current implementation of Terraform import can only import resources into the state. It does not generate configuration. A future version of Terraform will also generate configuration.

import 명령어를 사용하면 상태 파일에 기존 리소스의 상태가 적용된다. import는 아래와 같이 사용할 수 있다.

```bash
$ terraform import {유형}.{이름} {식별자}
$ terraform import aws_instance.web i-12345678
```

`aws_instance`는 리소스의 유형(여기서는 EC2 인스턴스)을 나타내는 것이고 `web`은 직접 지정한 이름이다. `i-12345678`는 AWS에서 만든 인스턴스 ID다. 다시 풀어서 설명하면 `i-12345678` 인스턴스를 `aws_instance.web`으로 가져오겠다는 뜻이다. 뒷부분에 있는 식별자는 리소스 유형마다 조금씩 다를 수 있는데, 그런 경우는 [공식 문서](https://www.terraform.io/docs/providers/aws/r/instance.html#import)를 참조하면 된다.


한 번에 딱 한 개만 가져올 수 있으므로 인스턴스가 3개 있으면 3번 가져와야 한다.

```bash
$ terraform import aws_instance.server1 i-017eb8d5ec586a067

aws_instance.server1: Importing from ID "i-017eb8d5ec586a067"...
aws_instance.server1: Import complete!
  Imported aws_instance (ID: i-017eb8d5ec586a067)
aws_instance.server1: Refreshing state... (ID: i-017eb8d5ec586a067)

Import success! The resources imported are shown above. These are
now in your Terraform state. Import does not currently generate
configuration, so you must do this next. If you do not create configuration
for the above resources, then the next `terraform plan` will mark
them for destruction.
```

EC2 인스턴스를 성공적으로 가져왔다. 현재 폴더를 보면 다음과 같은 `terraform.tfstate` 파일이 생긴 걸 볼 수 있다. 기존에 `terraform.tfstate` 파일이 없었지만, 자동으로 만들어 준다. 이미 파일이 존재했거나 backend가 설정되어 있었다면 그곳에 반영되었을 것이다.

```json
{
    "version": 3,
    "terraform_version": "0.9.6",
    "serial": 0,
    "lineage": "20c7dcdf-4258-4834-ab4c-54bc1b6fa67e",
    "modules": [
        {
            "path": [
                "root"
            ],
            "outputs": {},
            "resources": {
                "aws_instance.server1": {
                  ...
                }
            },
            "depends_on": []
        }
    ]
}
```

## Terraforming

원래 이 설정은 처음 작성할 때와 마찬가지로 손으로 직접 작성해야 한다. 하지만 이를 도와주는 terraforming이라는 Ruby 프로젝트가 있다. `brew install terraforming`으로 설치하면 terraforming이라는 명령어를 쓸 수 있다. EC2 인스턴스를 가져오는 명령어는 terraforming ec2이다.

```bash
# 설치
brew install terraforming

# 실행
terraform $리소스
```

terraform import와는 달리 terraforming은 한 서비스의 자원을 한꺼번에 가져오므로 여기서 필요한 자원을 가져다 써야 한다. 위에서 보듯이 AWS에 설정된 내용을 그대로 가져온 것이므로 이름이나 참조 관계 등은 알아서 지정해주지 않는다. 처음부터 작성하는 대신 teraforming 한 설정을 바탕으로 작성해서 노력을 줄여줄 수는 있다.

약간씩 다른 부분이 있다면 Terrafoam 문법에 맞추어 조금씩 수정하면 된다.

> https://developers.cloudflare.com/terraform/advanced-topics/import-cloudflare-resources/

Cloudflare를 사용하는 경우에는 `cf-terraforming`라는 별도의 도구를 사용할 수 있다. 마찬가지로 brew로 깔 수 있다. 

```bash
# 설치
brew install --cask cloudflare/cloudflare/cf-terraforming

# 실행
cf-terraforming generate --email $CLOUDFLARE_EMAIL --token $CLOUDFLARE_API_TOKEN --resource-type $리소스 > importing-example.tf
```