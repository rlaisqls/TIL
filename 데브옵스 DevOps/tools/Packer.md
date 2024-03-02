
Packer (https://www.packer.io/) 는 HashiCorp에서 개발한 가상 머신 이미지를 만들어주는 오픈소스이다. 

예를 들어서, 아마존 클라우드 AMI이미지나, 구글 클라우드 이미지를 스크립트를 이용하여 생성이 가능하다.

하나의 스크립트를 이용하여, 구글 클라우드, VMWare, 아마존 클라우드 등 여러 클라우드 환경 (가상화 환경)과 컨테이너 엔진용 이미지를 생성할 수 있다.

Chef, Puppet, Ansible과 같은 Configuration management 툴과 혼동이 될 수 있지만, Packer는 OS 이미지를 만들어주는 역할을 하고, Configuration management 툴들은 이렇게 만들어진 이미지 위에 소프트웨어를 설치하고, 이를 설정하는 상호 보완적인 역할을 하게 된다. 

특히 [피닉스 서버](./IaC/Phoenix%E2%80%85Server.md) 패턴에서 VM 이미지를 생성하는데 매우 유용하게 사용될 수 있다.

## 특징

- 패커는 특정 플랫폼의 이미지를 만드는 도구가 아니라, 다양한 플랫폼에 대한 이미지 생성 과정을 추상화해주는 역할을 한다. (VM의 이미지 뿐만 아니라 도커 이미지 등 여러 종류의 이미지를 다룸) 
- 이러한 특징 덕분에 플랫폼 간 이동을 쉽게 해주며, 인스턴스 기반 환경에서 컨테이너 기반으로 이동하는 가교 역할을 하는 것도 가능하다.
- 또한 이 전체를 코드로서 관리할 수 있기 때문에, 재현 가능성도 높아지고 관리 역시 쉬워진다.

## 템플릿

전체 컨셉은 VM의 설정을 JSON 파일에 정의해놓고, packer 툴을 이용하여 이미지를 생성하는 방식이다. 

VM의 설정을 정의한 파일을 템플릿 파일이라고 하는데, 다음과 같은 구조를 가지고 있다. 

- **Variable :** 변수를 정의하는 섹션으로, 동적으로 변경될 수 있는 클라우드 프로젝트명, 리전명등을 정의하는 부분이다. 메인 템플릿내에 섹션으로 정의할 수 도 있고, 또는 환경 변수나 별도의 변수만 지정한 파일 또는 CLI 옵션으로도 변수값을 전달할 수 있다. 
- **Builder :** 가장 핵심이 되는 부분으로 OS 버전등 VM 설정에 대한 부분을 정의한다. 
- **Provisioner :** 이미지에서 OS 설정이 끝난후에, 소프트웨어 스택을 설치하는 부분을 정의한다. 앞에서도 언급하였지만 Packer는 다양한 가상환경에 대한 이미지 생성에 최적화 되어 있지 소프트웨어 설치를 용도로 하지 않기 때문에, Provisioner에서는 다른 configuration management 툴과의 연계를 통해서 소프트웨어를 설치하도록 지원한다. 간단한 쉘을 이용하는것에서 부터, ansible,chef,puppet,salt stack등 다양한 configuration management 도구를 지원하도록 되어 있다. https://www.packer.io/docs/provisioners/index.html
이 과정에서 OS 설치 후, 소프트웨어 스택 설치 뿐만 아니라, 패치 및 기타 OS 설정 작업을 진행할 수 있다. 
- **Post-Processor :** Builder와 Provisioner에 의한 이미지 생성이 끝나면 다음으로 실행되는 명령이다. 

```json
{
  "variables":{
    // ...
  },
  "builders": [{
    // ...
  }],
  "provisioners": [{
    // ...
  }],
  "post-processors": [{
    // ...
  }]
}
```

## Ansible Playbook으로 AMI 빌드

예시를 알아보기 위해서 앤서블로 AMI를 빌드해보자.

```json
{
  "builders": [{
    "type": "amazon-ebs",
    "access_key": "<AWS_ACCESS_KEY>",
    "secret_key": "<AWS_SECRET_KEY>",
    "region": "ap-northeast-1",
    "source_ami": "ami-cbf90ecb",
    "instance_type": "m3.medium",
    "ssh_username": "ec2-user",
    "ami_name": "CustomImage {{isotime | clean_ami_name}}"
  }],
  "provisioners": [{
    "type": "ansible-local",
    "playbook_file" : "ansible/playbook.yml",
    "playbook_dir": "/Users/../ansible"
  }]
}
```

- builders
    - 먼저 `type`에는 amazon-ebs를 지정했다. 그리고 `access_key`와 `secret_key`에는 아마존 API 인증 정보를, `region`은 이미지가 생성되는 지역, `source_ami`는 이미지를 생성할 베이스 이미지(ami-cbf90ecb는 아마존 리눅스이다), `instance_type`은 이미지를 빌드할 때 사용할 인스턴스 타입, `ssh_username`에는 SSH 사용자 이름, 마지막으로 `ami_name`에는 새로 생성될 이미지 이름을 지정한다.
    - 패커의 JSON에서는 몇 가지 미리 정의되어있는 변수들을 사용할 수 있다. 이미지 이름에서 사용하는 `isotime`은 시간을 출력하며, `|` 다음의 `clean_ami_name` 필터를 통해서 이미지에서 사용할 수 없는 기호들을 미리 제거할 수 있다.
- provisioners
    - 앤서블을 프로비저너로 사용하고자 하는 경우에는 앤서블 플레이북을 미리 작성해야한다. `type`에는 ansible-local을 지정하고, 플레이북의 경로를 지정한다. 

완성된 템블릿으로 빌드해보자.

```bash
$ packer build ./template.json
amazon-ebs output will be in this color.

==> amazon-ebs: Inspecting the source AMI...
==> amazon-ebs: Creating temporary keypair: packer 55e9b978-5a49...
==> amazon-ebs: Creating temporary security group for this instance...
==> amazon-ebs: Authorizing SSH access on the temporary security group...
==> amazon-ebs: Launching a source AWS instance...
    amazon-ebs: Instance ID: i-12345678
==> amazon-ebs: Waiting for instance (i-12345678) to become ready...

...

==> amazon-ebs: Stopping the source instance...
==> amazon-ebs: Waiting for the instance to stop...
==> amazon-ebs: Creating the AMI: CustomImage 2015-09-04T15-32-08Z
    amazon-ebs: AMI: ami-12345678
==> amazon-ebs: Waiting for AMI to become ready...
==> amazon-ebs: Terminating the source AWS instance...
==> amazon-ebs: Deleting temporary security group...
==> amazon-ebs: Deleting temporary keypair...
Build 'amazon-ebs' finished.

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:

ap-northeast-1: ami-12345678
```

성공적으로 AMI가 만들어졌다. 이제 이 AMI를 가지고 새로운 인스턴스를 실행할 수 있다.