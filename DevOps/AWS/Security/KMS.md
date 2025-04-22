
KMS는 Key Management Service의 약자로, 데이터를 암호화 할떄 사용되는 암호화 Key를 안전하게 관리하는데 목적을 둔 AWS의 서비스이다.

KMS는 크게 세가지 방식으로 key 관리 서비스를 제공한다.

- AWS managed key
  - AWS 서비스들이 내부적으로 발급받는 Key로, 내부적으로 자동으로 일어나게 되며 사용자가 직접적으로 제어가 불가능하다.
  - 자신의 AWS 계정에 들어가면 만들어진 Key의 목록을 확인하는건 가능하다. [(참고)](https://docs.aws.amazon.com/kms/latest/developerguide/viewing-keys.html)
  - 모든 AWS managed keys는 1년마다 rotate된다. 이 주기는 사용자가 변경할 수 없다.
- Customer managed key(CMK)
  - 사용자가 직접 key를 생성하고 관리하는 것이다. CMK에 대해서는 IAM을 통해 권한을 부여받아 제어 할 수 있다.
- Custom key stores
  - AWS에서 제공하는 또 다른 key 관리형 서비스인 CloudHSM을 활용한 key 관리 형태를 의미한다. KMS 와 CloudHSM의 차이가 무엇인지는 AWS의 공식 FAQ 문서를 보면 알 수 있다.
  - "AWS Key Management Service(KMS)는 암호화 키를 사용하고 관리할 수 있는 멀티 테넌트 관리형 서비스다. 두 서비스 모두 암호화 키를 위한 높은 수준의 보안을 제공합니다. AWS CloudHSM은 Amazon Virtual Private Cloud(VPC)에서 바로 FIPS 140-2 레벨 3 전용 HSM을 제공하며 이 HSM은 사용자가 독점적으로 제어하게 됩니다."
  - 즉, KMS는 Shared 형태의 managed 서비스이며, CloudHSM은 dedicated managed 서비스로 사용자 VPC의 EC2에 HSM(Hardware Security Module)을 올려서 서비스되는 형태라고 보면 된다. 결국 CloudHSM이 조금 더 강력한 형태의 보안 안정성을 제공한다고 이해하면 될 것 같다.

## Data keys

Data keys는 많은 양의 데이터 및 기타 데이터 암호화 키를 포함한 여러 data를 encrypt 하는데 사용할 수 있는 대칭키이다. 다운로드할 수 없는 [KMS 대칭키](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html#kms_keys)와 달리 직접 다운로드받을 수 있다.

AWS KMS는 data key를 생성하고, 암호화하고, 복호화 한다. 하지만 KMS는 key를 저장하거나, 관리하거나, 트래킹하거나, 다른 작업을 수행하지 않는다. data key는 본인이 직접 보관해야하는데, 그 key를 더 안전하게 보관하고 싶다면 [AWS Encryption SDK](https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/)를 사용할 수 있다고 한다.

### Create data key

데이터 키를 만들려면 GenerateDataKey 작업을 호출해야한다.

KMS가 data key를 만들면, 바로 사용할 수 있는 plaintext 형태의 key와 해당 key를 안전하게 보관할 수 있도록 encrypt된 복사본을 반환한다. data를 복호화 하고싶다면 encrypt된 ket로 KMS에 요청을 보내면 된다.

### Encrypt data with a data key

AWS KMS는 data key를 사용하여 데이터를 암호화할 수 없다. 하지만 OpenSSL 또는 [AWS Encryption SDK](https://docs.aws.amazon.com/encryption-sdk/latest/developer-guide/) 같은 암호화 라이브러리를 사용하먄 AWS KMS 외부에서 data key를 사용할 수 있다.

plain text data key를 사용하여 데이터를 암호화한 다음 해당 키는 가능한 빨리 메모리에서 제거하길 권장된다. 데이터 암호화를 해제하는 데 사용할 수 있도록 암호화된 데이터와 함께 암호화된 data key를 안전하게 저장할 수 있다.

### Decrypt data with a data key

데이터를 해독하기 위해서 암호화된 data key를 [Decrypt](https://docs.aws.amazon.com/kms/latest/APIReference/API_Decrypt.html) 작업에 전달해준다. KMS는 당신의 KMS key를 해독해서 plain text data key를 반환해준다. 해당 key를 사용해서 해독한 다음, 암호화하는 경우와 마찬가지로 해당 키는 가능한 빨리 메모리에서 제거하길 권장된다.

---
참고

- <https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html>
- <https://aws.amazon.com/ko/cloudhsm/faqs>
