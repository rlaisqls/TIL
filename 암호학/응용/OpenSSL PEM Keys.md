
### 1. openssl 설치

```js
sudo apt install rpm
rpm -qa openssl
```

### 2. rsa secret key text 파일 생성

그냥 vi로 파일 만들어서 넣어줘도 된다.

```
vi (원하는 경로)
```

### 3. pem key 생성

아래 명령어로, 텍스트 파일 이름과 pem 키를 저장할 위치와 이름을 지정해준다.

```js
openssl rsa -in {key text 파일} -text > {pem key 저장할 경로}
```

### 4. ssh로 접속

```js
ssh -i {pem key 경로} {username}@{url} -p {port}
```