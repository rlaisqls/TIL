
GPG(GNU Privacy Guard)는 GNU에서 제공하는 OpenPGP(RFC4880)의 오픈소스 구현이다.

PGP(Pretty Good Privacy)는 1991년 Phil Zimmermann이 개발한 암호화 프로그램으로, 이메일과 파일을 암호화하고 서명하는 표준이 되었다. GPG는 이 표준을 무료로 구현한 것이다.

인터넷에서 메시지나 파일을 주고받을 때 세 가지 문제가 있다. GPG는 이 세 가지 문제를 공개 키 암호화와 디지털 서명으로 해결한다.

- 기밀성(Confidentiality): 메시지를 오직 의도한 수신자만 읽을 수 있어야 한다.
- 무결성(Integrity): 메시지가 전송 중 변조되지 않았음을 확인할 수 있어야 한다.
- 인증(Authentication): 메시지가 실제로 주장하는 발신자로부터 온 것임을 확인할 수 있어야 한다.

GPG는 메시지를 암호화할 때 하이브리드 암호화 방식을 사용한다. 따라서 GPG는 다음과 같이 동작한다.

1. 세션 키 생성: 무작위로 대칭 키(세션 키)를 생성한다. 보통 AES-256 같은 대칭 암호 알고리즘용 키다.
2. 메시지 암호화: 이 세션 키로 실제 메시지를 암호화한다. 대칭 암호는 매우 빠르므로 큰 메시지도 빠르게 암호화할 수 있다.
3. 세션 키 암호화: 세션 키 자체를 수신자의 공개 키로 RSA 암호화한다. 세션 키는 작은 크기(예: 256비트)이므로 RSA로 암호화하기 적합하다.
4. 전송: 암호화된 메시지와 암호화된 세션 키를 함께 전송한다.

수신자는 역순으로 복호화한다.

1. 세션 키 복호화: 자신의 개인 키로 암호화된 세션 키를 복호화한다.
2. 메시지 복호화: 복호화한 세션 키로 암호화된 메시지를 복호화한다.

```
alice → bob에게 메시지 전송

[alice]
1. 무작위 세션 키 k 생성
2. 메시지를 k로 대칭 암호화 → 암호문 c
3. k를 Bob의 공개키로 RSA 암호화 → 암호화된 키 e_k
4. {c, e_k} 전송

[bob]
1. 자신의 개인키로 e_k 복호화 → k
2. k로 c 복호화 → 원본 메시지
```

서명은 메시지의 출처를 증명한다. 간단하게 RSA 암호화를 역으로 사용하는 것이다.

- 암호화: 공개 키로 암호화, 개인 키로 복호화
- 서명: 개인 키로 "암호화", 공개 키로 "복호화"

개인 키로 만든 것은 오직 그 사람만 만들 수 있다. 하지만 공개 키를 가진 누구나 검증할 수 있다.

서명 과정

1. 해시 계산: 메시지의 해시값을 계산한다. (예: SHA-256) 해시는 메시지의 고유한 지문이다.
2. 해시 서명: 이 해시값을 발신자의 개인 키로 암호화한다. 이것이 디지털 서명이다.
3. 전송: 원본 메시지와 서명을 함께 전송한다.

검증 과정

1. 해시 계산: 받은 메시지의 해시값을 계산한다.
2. 서명 복호화: 발신자의 공개 키로 서명을 복호화한다. 이렇게 얻은 값이 발신자가 서명했던 원래 해시값이다.
3. 비교: 두 해시값이 일치하면 서명이 유효하다.

```
alice가 메시지에 서명

[alice]
1. 메시지의 해시 h = SHA256(메시지) 계산
2. Alice의 개인키로 h를 암호화 → 서명 s
3. {메시지, s} 전송

[bob]
1. 받은 메시지의 해시 h' = SHA256(메시지) 계산
2. Alice의 공개키로 s를 복호화 → h
3. h == h' 인지 확인
   - 같으면: 메시지는 Alice가 서명했고 변조되지 않음
   - 다르면: 서명이 위조되었거나 메시지가 변조됨
```

왜 메시지 전체를 서명하지 않고 해시를 서명할까?

- RSA는 느리므로 큰 메시지를 직접 서명하면 비효율적이다.
- RSA로 서명할 수 있는 데이터 크기에 제한이 있다. (모듈러스 n보다 작아야 함)
- 해시는 고정된 크기(예: SHA-256은 256비트)이므로 항상 서명 가능하다.

해시의 특성상 메시지가 단 1비트라도 바뀌면 해시값이 완전히 달라진다. 따라서 해시 서명만으로도 메시지 전체의 무결성을 보장할 수 있다.

### 서명의 수학적 원리

RSA에서 배웠듯이, 공개 지수 e와 개인 지수 d는 `e·d ≡ 1 (mod φ(n))`을 만족한다. 따라서

```
m^(e·d) ≡ m (mod n)
```

이 성립한다.

암호화는 `c = m^e mod n`, 복호화는 `m = c^d mod n`이다.

서명은 이를 역으로 사용한다.

- 서명: `s = h^d mod n` (개인 키 d로 해시 h를 "암호화")
- 검증: `h' = s^e mod n` (공개 키 e로 서명 s를 "복호화")

서명이 유효하면 `h' = h`이다.

```
h' = s^e
   = (h^d)^e
   = h^(d·e)
   ≡ h (mod n)
```

오직 개인 키 d를 가진 사람만 `h^d`를 계산할 수 있으므로, 이 서명은 그 사람만 만들 수 있다.

## Web of Trust: 탈중앙화된 신뢰 모델

공개 키 암호화에는 근본적인 문제가 하나 있다. 받은 공개 키가 정말 그 사람의 것인지 어떻게 확인할까?

예를 들어 Alice가 "Bob의 공개 키"라고 주장하는 키를 받았다고 하자. 하지만 이게 진짜 Bob의 키일까? 중간에 공격자가 자신의 키를 Bob의 키라고 속일 수도 있기 떄문에 확신할 수는 없다. (중간자 공격, MITM)

이 문제를 해결하는 방법은 크게 두 가지다.

### 중앙화된 방식: PKI (Public Key Infrastructure)

HTTPS에서 사용하는 방식이다. 신뢰할 수 있는 중앙 기관(Certificate Authority, CA)이 있어서, CA가 "이 공개 키는 정말 이 사람의 것입니다"라고 서명해준다. 브라우저는 이미 CA의 공개 키를 알고 있으므로, CA의 서명을 검증할 수 있다.

- 장점: 간단하고 확실하다.
- 단점: CA를 신뢰해야 한다. CA가 해킹당하거나 부패하면 전체 시스템이 무너진다.

### 탈중앙화된 방식: Web of Trust

GPG가 사용하는 방식이다. 중앙 기관 없이, 사용자들이 서로의 키를 검증하고 서명해준다.

#### 작동 방식

1. 키 검증: Alice가 Bob을 직접 만나서, Bob의 공개 키 지문(fingerprint)을 확인한다. 지문이 맞으면 Alice는 Bob의 공개 키를 자신의 개인 키로 서명한다.
2. 서명 공유: Alice의 서명이 포함된 Bob의 공개 키가 배포된다.
3. 전이적 신뢰: Carol이 Alice를 신뢰한다면, Alice가 서명한 Bob의 키도 신뢰할 수 있다.

```
Carol ← 신뢰 → Alice ← 직접 검증 → Bob

Carol은 Alice를 신뢰하고,
Alice는 Bob의 키를 검증했으므로,
Carol도 Bob의 키를 (간접적으로) 신뢰할 수 있다.
```

이렇게 신뢰의 그물(Web of Trust)이 형성된다.

#### 신뢰 수준

GPG는 키에 대한 신뢰를 여러 단계로 구분한다.

- Unknown: 이 키를 모른다.
- None: 이 키를 신뢰하지 않는다.
- Marginal: 이 키를 약간 신뢰한다.
- Full: 이 키를 완전히 신뢰한다.
- Ultimate: 이 키는 내 키다.

GPG는 기본적으로 1개의 "Full" 서명 또는 3개의 "Marginal" 서명이 있으면 키가 유효하다고 판단하는 규칙을 사용한다.

#### 장단점

- 장점: 중앙 기관에 의존하지 않는다. 검열에 강하다.
- 단점: 사용이 복잡하다. 직접 만나서 키를 검증해야 한다. 확장성이 떨어진다.

실제로 Web of Trust는 이론적으로는 우아하지만, 실용적으로는 관리가 어렵다. 최근에는 [Keybase](https://keybase.io/)같이 소셜 네트워크를 통한 신원 증명 방식도 등장했다.

## GPG 키 구조

GPG 키는 단순히 하나의 키 쌍이 아니라, 여러 하위 키로 구성된 복잡한 구조를 가진다.

### Primary Key)

- 용도: 주로 서명용 (Certification)
- 역할: 다른 하위 키들을 서명하고 인증한다. 신원의 최상위 증명이다.
- 보안: 가장 중요한 키이므로 오프라인에 안전하게 보관하는 것이 좋다.

### 하위 키 (Subkeys)

주 키 아래에 여러 하위 키를 만들 수 있다. 각 하위 키는 특정 용도로 사용된다.

- 서명 하위 키 (Signing subkey): 메시지와 파일 서명용
- 암호화 하위 키 (Encryption subkey): 메시지 암호화용
- 인증 하위 키 (Authentication subkey): SSH 인증 등에 사용

하위키를 사용하는 이유는, 키를 역할별로 분리해 보안을 강화하기 위함이다.

- 주 키를 오프라인에 보관하고, 일상적으로는 하위 키만 사용할 수 있다.
- 하위 키가 손상되면 주 키로 해당 하위 키만 폐기하고 새 하위 키를 발급할 수 있다.
- 주 키가 손상되면 전체를 폐기해야 하지만, 하위 키는 개별적으로 관리할 수 있다.

```
주 키 [C] (Certification)
├── 하위 키 [S] (Signing)
├── 하위 키 [E] (Encryption)
└── 하위 키 [A] (Authentication)
```

앞서 키 생성 예제에서 본 출력을 다시 보자.

```
pub   rsa4096 2021-03-16 [SC] [expires: 2023-03-16]
      EFD634321C5A23B17A74AB6DB821C2E8600096BE
uid                      rlaisqls (ACME Inc.) <rlaisqls@gmail.com>
sub   rsa4096 2021-03-16 [E] [expires: 2023-03-16]
```

- `pub`: 주 키 (primary key)
- `[SC]`: 이 키는 서명(Sign)과 인증(Certify) 용도다.
- `sub`: 하위 키 (subkey)
- `[E]`: 이 하위 키는 암호화(Encrypt) 용도다.

### UID (User ID)

키에는 하나 이상의 사용자 ID를 첨부할 수 있다. 일반적으로 이름과 이메일 주소를 포함한다.

```
rlaisqls (ACME Inc.) <rlaisqls@gmail.com>
```

여러 이메일 주소를 사용한다면 여러 UID를 추가할 수 있다. 각 UID는 주 키로 서명되어 연결된다.

## 키 관리

키를 안전하게 관리하기 위한 모범 사례들이 있다.

1. 강력한 암호구문 사용

    - 개인 키는 암호구문(passphrase)으로 보호된다. 개인 키 파일이 유출되더라도 암호구문 없이는 사용할 수 없다. 강력한 암호구문을 사용하고, 절대 공유하지 않는다.

2. 키 백업

   - 개인 키를 안전하게 백업한다. 키를 잃어버리면 암호화된 메시지를 영원히 복호화할 수 없다.

        ```bash
        # 개인 키 백업
        gpg --export-secret-keys --armor your-email@example.com > private-key-backup.asc
        ```

        백업 파일은 암호화된 USB나 종이에 인쇄해서 금고에 보관하는 것이 좋다.

3. 폐기 인증서 미리 생성

    - 키를 생성하자마자 폐기 인증서를 만들어 안전하게 보관한다. 키가 손상되었을 때 폐기할 수 있는 유일한 방법이다.

4. 키 만료 기한 설정
    - 키에 만료 기한을 설정한다. 일반적으로 1~2년이 적당하다. 키가 여전히 유효하다면 만료 기한을 연장할 수 있다.
    - 만료 기한이 있으면, 키를 분실해도 자동으로 사용이 중단된다. 폐기 인증서를 분실했을 때의 안전장치다.

5. 키 서버에 업로드

    - 공개 키를 키 서버에 업로드하면 다른 사람들이 쉽게 찾을 수 있다.

        ```bash
        gpg --send-keys --keyserver keys.openpgp.org YOUR_KEY_ID
        ```

        하지만 키 서버에 업로드한 키는 삭제할 수 없다. 폐기는 가능하지만, 폐기된 키 정보는 영구히 남는다.

6. Primary key 오프라인 보관 (고급)

    - 보안이 매우 중요한 경우, 주 키를 오프라인 USB에 보관하고 일상적으로는 하위 키만 사용할 수 있다.

        1. 주 키로 하위 키들을 생성한다.
        2. 하위 키만 일상 사용 컴퓨터에 복사한다.
        3. 주 키는 오프라인 USB에 보관한다.

    - 이렇게 하면 컴퓨터가 해킹당해도 주 키는 안전하다. 하위 키만 폐기하고 새로 발급하면 된다.

## 예시

### 파일 암호화하기

파일을 Alice에게만 보낼 수 있게 암호화한다.

```bash
# Alice의 공개 키로 파일 암호화
gpg --encrypt --recipient alice@example.com secret.txt
# 결과: secret.txt.gpg

# Alice는 자신의 개인 키로 복호화
gpg --decrypt secret.txt.gpg > secret.txt
```

여러 수신자에게 보낼 수도 있다.

```bash
gpg --encrypt --recipient alice@example.com --recipient bob@example.com secret.txt
```

이 경우 세션 키를 각 수신자의 공개 키로 암호화한 복사본이 함께 포함된다. Alice와 Bob 모두 자신의 개인 키로 복호화할 수 있다.

### 파일 서명하기

소프트웨어 배포 시 무결성을 보장하기 위해 서명을 첨부한다.

```bash
# 파일 서명 (분리된 서명 파일 생성)
gpg --detach-sign --armor myprogram-1.0.tar.gz
# 결과: myprogram-1.0.tar.gz.asc

# 서명 검증
gpg --verify myprogram-1.0.tar.gz.asc myprogram-1.0.tar.gz
```

`--armor` 옵션은 바이너리 대신 ASCII 형식으로 출력한다. 이메일에 붙여넣거나 웹에 게시하기 편리해진다.

### 서명과 동시에 암호화

메시지를 암호화하면서 동시에 서명할 수 있다.

```bash
gpg --sign --encrypt --recipient alice@example.com message.txt
```

이렇게 하면 Alice는 메시지를 복호화할 수 있고, 동시에 발신자가 누구인지 검증할 수 있다.

### Git 커밋 서명

Git 커밋에 GPG 서명을 추가하면 커밋이 정말 본인이 작성한 것임을 증명할 수 있다. GitHub도 서명된 커밋에 "Verified" 배지를 표시한다.

```bash
# Git에 GPG 키 설정
git config --global user.signingkey YOUR_KEY_ID

# 커밋 시 서명
git commit -S -m "Add new feature"

# 모든 커밋에 자동으로 서명
git config --global commit.gpgsign true
```

### SSH 인증에 GPG 사용

GPG의 인증 하위 키를 SSH 인증에 사용할 수 있다. 이렇게 하면 별도의 SSH 키를 관리하지 않아도 된다.

```bash
# gpg-agent를 SSH 에이전트로 사용
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

# SSH 공개 키 내보내기
gpg --export-ssh-key your-email@example.com
```

## GPG의 한계와 대안

GPG는 강력하지만 완벽하지 않다. 주요 한계점과 대안은 다음과 같다.

- GPG는 메시지 내용은 암호화하지만, 메타데이터(누가 누구에게 보냈는지, 언제 보냈는지)는 보호하지 않는다.
  - 통신 패턴 자체가 정보를 노출할 수 있다.
  - Signal, Wire 같은 현대적 메신저는 메타데이터 보호에 더 신경 쓴다.

- 개인 키가 손상되면 과거에 암호화된 모든 메시지를 복호화할 수 있다. (전방향 보안, Forward Secrecy 부족)
  - 현대적 프로토콜(Signal Protocol, TLS 1.3)은 세션마다 임시 키를 생성한다.
  - 세션 키가 유출되어도 다른 세션에 영향을 주지 않는다.

- 명령줄 도구이고 키 관리가 복잡하여 일반 사용자에게는 진입 장벽이 높다.
  - ProtonMail, Tutanota 같은 서비스는 GPG의 암호화 기능을 사용자 친화적으로 제공한다.
  - Keybase는 소셜 네트워크를 통한 신원 증명으로 Web of Trust의 복잡성을 완화한다.

- 현대적 대안:
  - Signal Protocol: 메신저용. 전방향 보안, 메타데이터 보호, 부인 방지 제공.
  - Age: 파일 암호화용. GPG보다 간단하고 현대적인 설계.
  - Minisign: 파일 서명용. GPG의 서명 기능만 간단하게 구현.

그럼에도 GPG는 여전히 중요하다. 이메일 암호화, 소프트웨어 배포 서명, Git 커밋 서명 등에 널리 사용된다. Linux 배포판의 패키지는 거의 모두 GPG로 서명된다.

## CLI

### Key Pair 생성

```bash
gpg --full-gen-key
> Please select what kind of key you want: 1
> What keysize do you want? 4096
> Key is valid for? y
> Is this correct? (y/N) y
> Real name: rlaisqls
> Email address: rlaisqls@gmail.com
> Comment: N/A
> Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
```

아래는 키 생성에 대한 전체 예제이다.

```bash
$ gpg --full-gen-key
gpg (GnuPG) 2.2.27; Copyright (C) 2021 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
  (14) Existing key from card
Your selection? 1
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (3072) 4096
Requested keysize is 4096 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 2y
Key expires at Thu 16 Mar 2023 11:12:08 AM KST
Is this correct? (y/N) y

GnuPG needs to construct a user ID to identify your key.

Real name: rlaisqls
Email address: rlaisqls@gmail.com
Comment: ACME Inc.
You selected this USER-ID:
    "rlaisqls (ACME Inc.) <rlaisqls@gmail.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
gpg: key B821C2E8600096BE marked as ultimately trusted
gpg: revocation certificate stored as '/home/euikook/.gnupg/openpgp-revocs.d/EFD634321C5A23B17A74AB6DB821C2E8600096BE.rev'
public and secret key created and signed.

pub   rsa4096 2021-03-16 [SC] [expires: 2023-03-16]
      EFD634321C5A23B17A74AB6DB821C2E8600096BE
uid                      rlaisqls (ACME Inc.) <rlaisqls@gmail.com>
sub   rsa4096 2021-03-16 [E] [expires: 2023-03-16]
```

### 키 확인 하기

```bash
gpg --list-key
gpg --list-keys
gpg: checking the trustdb
gpg: marginals needed: 3  completes needed: 1  trust model: pgp
gpg: depth: 0  valid:   2  signed:   0  trust: 0-, 0q, 0n, 0m, 0f, 2u
gpg: next trustdb check due at 2023-03-16
/home/euikook/.gnupg/pubring.kbx
--------------------------------
pub   rsa4096 2021-03-16 [SC] [expires: 2023-03-16]
      EFD634321C5A23B17A74AB6DB821C2E8600096BE
uid           [ultimate] rlaisqls (ACME Inc.) <rlaisqls@gmail.com>
sub   rsa4096 2021-03-16 [E] [expires: 2023-03-16]
```

### Key에 서명하기

```bash
gpg --sign-key rlaisqls@gmail.com
```

### GPG 키 편집

`--edit-key`옵션으로 생성된 키의 정보를 수정할 수 있다.

```bash
gpg --edit-key rlaisqls@gmail.com
```

위 명령을 수행 하면 `gpg>` 프롬프트가 뜬다. `?`를 입력하면 입력 가능한 명령이 나온다.

adduid 명령으로 uid를 추가 할 수 있다.

편집이 완료 되었으면 quit 명령으로 프로그램을 종료 한다.

개인 키에서 암호 변경/제거하기

```bash
gpg --list-keys
/home/john/.gnupg/pubring.kbx
--------------------------------
pub   rsa3072 2021-03-16 [SC]
      AA1AC070A86C0523A867C0261D3E87647AD3517E
uid           [ultimate] rlaisqls <rlaisqls@gmail.com>
sub   rsa3072 2021-03-16 [E]
gpg --edit-key AA1AC070A86C0523A867C0261D3E87647AD3517E
```

`gpg>` 프롬프트가 뜨면 passwd를 입력하여 비밀번호를 변경한다.

기존 비밀번호를 입력 하고 새로운 비밀번호를 입력한다. 암호를 제거 하려면 암호를 입력 하지 않고 OK를 선택한다.

암호를 입력 하지 않으면 입호 입력을 권하는 경고 메시지가 뜬다. 암호 없이 키를 생성 하려면 Yes, protection is not nedded를 선택한다.

### GPG 폐기 인증서(Revocation Certificate) 생성

Key Pair를 생성한 후 폐기 인증서를 만들어야 한다. 명시적으로 키를 폐기 하고자 할때 만들어도 되지만 개인 키가 손상되었거나 분실하였을 경우 폐기 인증서를 만들 수 없기 때문에 미리 만들어서 안전한 곳에 보관한다.

> 폐기 인증서는 키 생성 후 바로 생성 하는 것이 좋다. 폐기 인증서를 만든다고 키가 바로 폐기 되는것이 아니고, 암호를 잊어 버리거나 키를 분실한 경우 키를 안전하게 폐기 할 수 있는 방법을 제공한다.

```bash
gpg --output john.revoke.asc --gen-revoke rlaisqls@gmail.com
```

아래는 폐기 인증서를 만드는 전체 과정이다.

```bash
gpg --output euikook.revoke.asc --gen-revoke rlaisqls@gmail.com

sec  rsa4096/B821C2E8600096BE 2021-03-16 rlaisqls (ACME Inc.) <rlaisqls@gmail.com>

Create a revocation certificate for this key? (y/N) y
Please select the reason for the revocation:
  0 = No reason specified
  1 = Key has been compromised
  2 = Key is superseded
  3 = Key is no longer used
  Q = Cancel
(Probably you want to select 1 here)
Your decision? 0
Enter an optional description; end it with an empty line:
> 
Reason for revocation: No reason specified
(No description given)
Is this okay? (y/N) y
ASCII armored output forced.
Revocation certificate created.

Please move it to a medium which you can hide away; if Mallory gets
access to this certificate he can use it to make your key unusable.
It is smart to print this certificate and store it away, just in case
your media become unreadable.  But have some caution:  The print system of
your machine might store the data and make it available to others!
```

폐기 인증서만 있다면 누구든지 공개키를 폐기할 수 있으므로 인증서는 안전한 곳에 보관하여야 한다.

### 공개 키 내보내기

타인에게 공개할 공개 키를 공유하기 위해서는 키를 내보내야 한다. `--export` 옵션을 사용하여 키를 내보낸다. 기본적으로 키를 바이너리 형식으로 내보내지만 이를 공유 할 때 불편할 수 있다. `--armor` 옵션을 사용하여 키를 ASCII형식으로 출력한다.

```bash
gpg --export --armor --output test.pub rlaisqls@gmail.com
```

다른 사람들이 공개 키를 검증 하는 것을 허용 하려면 공개 키의 지문(fingerprint)도 같이 공유 한다.

```bash
gpg --fingerprint rlaisqls@gmail.com
```

---
참고

- <https://gnupg.org/>
- <https://en.wikipedia.org/wiki/GNU_Privacy_Guard>
- <https://librewiki.net/wiki/%EC%8B%9C%EB%A6%AC%EC%A6%88:%EC%95%94%ED%98%B8%EC%9D%98_%EC%95%94%EB%8F%84_%EB%AA%B0%EB%9D%BC%EB%8F%84_%EC%89%BD%EA%B2%8C_%ED%95%98%EB%8A%94_GPG>
