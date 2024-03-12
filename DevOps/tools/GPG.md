
GPG(GNU Privacy Cuard)는 GNU에서 제공하는 OpenPGP(RFC4880)의 오픈소스 구현이다.

### PGP란?
- 메시지나 파일을 암호화하여 전송할 수 있는 툴이나 소스를 배포하는 각종 프로그램의 변조 유무를 검사할 수 있는 프로그램이다.
- 누군가 악의적인 목적으로 소스에 해킹툴이나 바이러스를 내포하여 원본과 다른 소스를 배포할 수 있는데, 배포자의 서명과 서명된 파일을 제공하여 소스에 대한 무결성 검사를 할 수 있도록 한다.
- 메일이나 중요한 데이터에 대해 서명과 함께 전송함으로써 허가된 사용자만 해당 데이터를 볼 수 있는 권한을 부여할 수 있다.
- 보안 메일, 전자 서명 시스템에서 응용 가능하다.

정리하자면 GPG(PGP)는 개인간, 머신간 또는 개인 - 머신간에 교환되는 메시지나 파일을 암호화 하거나 서명을 추가 하여 작성자를 확인하고 변조 유무를 식별할 수 있게 해주는 도구다.

기본적으로 RSA와 같은 공개 키 암호화 방식을 사용하여 종단간 파일이나 메시지를 암호화 하거나 서명 하는 기능을 제공한다.

## GPG 사용하기

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
`--edit-key `옵션으로 생성된 키의 정보를 수정할 수 있다.

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

> 폐기 인증서는 키 생성 후 바로 생성 하는 것이 좋다. 폐기 인증서를 만든다고 키가 바로 폐기 되는것이 아니고, 이렇게 만들어 놓은 폐기 인증서는 암호를 잊어 버리거나 키를 분실한 경우 키를 안전하게 폐기 할 수 있는 방법을 제공한다.

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

폐기 인증서만 있다면 누구든지 공개키를 폐기할 수 있으므로 인증서는 안전한 곳에 보관 하여야 한다.

### 공개 키 내보내기

타인에게 공개할 공개 키를 공유 하기 위해서는 키를 내보야 한다. `--export` 옵션을 사용하여 키를 내보낸다. 기본적으로 키를 바이너리 형식으로 내보내지만 이를 공유 할 때 불편할 수 있다. `--armor` 옵션을 사용하여 키를 ASCII형식으로 출력한다.

```bash
gpg --export --armor --output test.pub rlaisqls@gmail.com
```

다른 사람들이 공개 키를 검증 하는 것을 허용 하려면 공개 키의 지문(fingerprint)도 같이 공유 한다.

```bash
gpg --fingerprint rlaisqls@gmail.com
```

---
참고
- https://gnupg.org/
- https://en.wikipedia.org/wiki/GNU_Privacy_Guard
- https://librewiki.net/wiki/%EC%8B%9C%EB%A6%AC%EC%A6%88:%EC%95%94%ED%98%B8%EC%9D%98_%EC%95%94%EB%8F%84_%EB%AA%B0%EB%9D%BC%EB%8F%84_%EC%89%BD%EA%B2%8C_%ED%95%98%EB%8A%94_GPG