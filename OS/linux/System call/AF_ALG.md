
AF_ALG는 Linux 커널의 Crypto API를 유저스페이스에 소켓 인터페이스로 노출하는 소켓 패밀리이다. 커널 2.6.38에서 도입되었다.

일반적으로 암호화 연산은 OpenSSL 같은 유저스페이스 라이브러리로 수행한다. 하지만 커널 내부에도 자체 암호화 엔진(Crypto API)이 존재하고, AF_ALG는 이 엔진을 `socket()` → `bind()` → `accept()` → `sendmsg()`/`recv()` 흐름으로 사용할 수 있게 해준다. 네트워크 소켓에서 데이터를 주고받듯이, 평문을 커널에 보내면 커널이 연산을 수행하고 결과를 돌려주는 구조이다.

커널 Crypto API는 하드웨어 가속(AES-NI, ARM CE 등)을 자동으로 활용한다. AF_ALG를 쓰면 유저스페이스 프로그램이 별도 라이브러리 없이도 하드웨어 가속 암호화를 사용할 수 있다.

## 사용

1. `socket(AF_ALG, SOCK_SEQPACKET, 0)`으로 소켓을 만들기
2. `bind()`로 사용할 알고리즘을 지정하기

```c
#include <linux/if_alg.h>
#include <sys/socket.h>

int sockfd = socket(AF_ALG, SOCK_SEQPACKET, 0);

struct sockaddr_alg sa = {
    .salg_family = AF_ALG,
    .salg_type   = "hash",       // 알고리즘 타입
    .salg_name   = "sha256"      // 알고리즘 이름
};
bind(sockfd, (struct sockaddr *)&sa, sizeof(sa));
```

`sockaddr_alg` 구조체의 필드는 다음과 같다.

- **salg_family**: 항상 `AF_ALG`
- **salg_type**: 알고리즘 타입. `"hash"`, `"skcipher"`, `"aead"`, `"rng"` 등
- **salg_name**: 커널에 등록된 알고리즘 이름. `"sha256"`, `"hmac(sha256)"`, `"cbc(aes)"`, `"gcm(aes)"` 등

`bind()` 이후 `accept()`를 호출하면 실제 연산에 사용할 파일 디스크립터(`opfd`)를 얻는다. 이 `opfd`에 대해 `sendmsg()`/`recv()`로 데이터를 주고받는다.

```c
int opfd = accept(sockfd, NULL, 0);
```

`accept()`를 여러 번 호출해서 독립적인 연산 컨텍스트를 여러 개 만들 수도 있다.

## 타입별 예시

**hash (SHA256)**

가장 단순한 형태이다. 데이터를 보내고 해시값을 받는다.

```c
// bind: type="hash", name="sha256"
int opfd = accept(sockfd, NULL, 0);
send(opfd, "hello", 5, 0);

unsigned char digest[32];
recv(opfd, digest, sizeof(digest), 0);
// digest에 SHA256("hello") 결과가 들어온다
```

여러 청크를 나눠 보내려면 `send()`의 flags에 `MSG_MORE`를 사용한다. 마지막 청크에서는 `MSG_MORE` 없이 보내면 커널이 최종 해시를 계산한다.

```c
send(opfd, chunk1, len1, MSG_MORE);
send(opfd, chunk2, len2, 0);        // 마지막 청크
recv(opfd, digest, 32, 0);
```

**HMAC**

HMAC은 키가 필요하다. `setsockopt()`으로 키를 설정한 뒤 해시와 동일하게 사용한다.

```c
// bind: type="hash", name="hmac(sha256)"
setsockopt(sockfd, SOL_ALG, ALG_SET_KEY, key, key_len);

int opfd = accept(sockfd, NULL, 0);
send(opfd, data, data_len, 0);
recv(opfd, mac, 32, 0);
```

`setsockopt()`은 `accept()` 전에, 즉 `sockfd`에 대해 호출해야 한다. 설정한 키는 이후 `accept()`로 생성되는 모든 `opfd`에 적용된다.

**skcipher (AES-CBC)**

대칭키 암호화는 키 외에 IV(Initialization Vector)도 필요하다. IV는 `sendmsg()`의 control message(`cmsg`)로 전달한다.

```c
// bind: type="skcipher", name="cbc(aes)"
setsockopt(sockfd, SOL_ALG, ALG_SET_KEY, key, 16);

int opfd = accept(sockfd, NULL, 0);

// sendmsg()로 IV + 암호화/복호화 방향 + 평문을 한 번에 전달
struct msghdr msg = {};
struct cmsghdr *cmsg;
char cbuf[CMSG_SPACE(4) + CMSG_SPACE(16)];  // op + iv

msg.msg_control = cbuf;
msg.msg_controllen = sizeof(cbuf);

// 첫 번째 cmsg: 암호화(ALG_OP_ENCRYPT) 또는 복호화(ALG_OP_DECRYPT)
cmsg = CMSG_FIRSTHDR(&msg);
cmsg->cmsg_level = SOL_ALG;
cmsg->cmsg_type  = ALG_SET_OP;
cmsg->cmsg_len   = CMSG_LEN(4);
*(__u32 *)CMSG_DATA(cmsg) = ALG_OP_ENCRYPT;

// 두 번째 cmsg: IV 설정
cmsg = CMSG_NXTHDR(&msg, cmsg);
cmsg->cmsg_level = SOL_ALG;
cmsg->cmsg_type  = ALG_SET_IV;
cmsg->cmsg_len   = CMSG_LEN(20);  // 4(ivlen) + 16(iv)
struct af_alg_iv *aiv = (void *)CMSG_DATA(cmsg);
aiv->ivlen = 16;
memcpy(aiv->iv, iv, 16);

// iov에 평문 설정
struct iovec iov = { .iov_base = plaintext, .iov_len = 16 };
msg.msg_iov = &iov;
msg.msg_iovlen = 1;

sendmsg(opfd, &msg, 0);

unsigned char ciphertext[16];
recv(opfd, ciphertext, sizeof(ciphertext), 0);
```

`cmsg`를 통해 연산 파라미터(방향, IV)를 전달하고, `iov`를 통해 실제 데이터를 전달하는 구조이다. 복호화는 `ALG_OP_DECRYPT`로 방향만 바꾸면 된다.

**AEAD (AES-GCM)**

AEAD(Authenticated Encryption with Associated Data)는 암호화와 무결성 검증을 동시에 수행한다. AES-GCM이 대표적이다.

skcipher와 비슷하지만, 추가 인증 데이터(AAD)와 인증 태그(tag)를 다뤄야 한다.

```c
// bind: type="aead", name="gcm(aes)"
setsockopt(sockfd, SOL_ALG, ALG_SET_KEY, key, 16);

// 인증 태그 길이 설정 (GCM은 보통 16바이트)
setsockopt(sockfd, SOL_ALG, ALG_SET_AEAD_AUTHSIZE, NULL, 16);

int opfd = accept(sockfd, NULL, 0);
```

암호화 시 `sendmsg()`에 AAD와 평문을 함께 보낸다. `recv()`로 받는 결과에는 암호문 뒤에 인증 태그가 붙어있다. 복호화 시에는 암호문 + 태그를 보내고, 커널이 태그를 검증한 뒤 평문을 돌려준다. 태그 검증에 실패하면 `recv()`가 `-EBADMSG`를 반환한다.

AEAD에서 AAD 길이는 `cmsg`의 `ALG_SET_AEAD_ASSOCLEN`으로 지정한다.

```c
// cmsg에 ALG_SET_AEAD_ASSOCLEN 추가
cmsg->cmsg_level = SOL_ALG;
cmsg->cmsg_type  = ALG_SET_AEAD_ASSOCLEN;
cmsg->cmsg_len   = CMSG_LEN(4);
*(__u32 *)CMSG_DATA(cmsg) = aad_len;
```

## 지원 알고리즘 확인

`/proc/crypto`를 읽으면 현재 커널에 로드된 암호화 알고리즘 목록을 볼 수 있다.

```bash
$ cat /proc/crypto | grep -A 3 "name"
name         : gcm(aes)
driver       : gcm_aes_aesni
module       : aesni_intel
priority     : 400
...
```

`priority`가 높은 드라이버가 우선 사용된다. `aesni_intel` 모듈이 로드되어 있으면 AES-NI 하드웨어 가속이 적용된다.

## 사용 시 고려사항

- **소켓 기반**이므로 `epoll`/`select`와 조합할 수 있다. 대량의 비동기 암호화 연산이 필요한 경우 유용하다.
- **zero-copy**: `vmsplice()` + `splice()`를 사용하면 유저스페이스와 커널 사이의 메모리 복사를 줄일 수 있다.
- 유저스페이스 라이브러리 대비 **시스템 콜 오버헤드**가 존재한다. 소량의 데이터를 반복적으로 처리하는 경우 OpenSSL 등이 더 빠를 수 있다. 대량 데이터나 하드웨어 가속이 중요한 경우에 AF_ALG가 유리하다.
- `SOCK_SEQPACKET` 외에 `SOCK_STREAM`도 사용 가능하다. `SOCK_STREAM`은 청크 경계 없이 스트리밍으로 데이터를 보낼 수 있다.

---
참고

- <https://www.kernel.org/doc/html/latest/crypto/userspace-if.html>
- <https://man7.org/linux/man-pages/man7/socket.7.html>
- <https://man7.org/linux/man-pages/man2/sendmsg.2.html>
