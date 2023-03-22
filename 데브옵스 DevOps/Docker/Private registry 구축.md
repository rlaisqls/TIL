
# 🐳 Private registry 구축

내부 Private Cloud 환경에 적용가능한 Docker Private Registry를 구현해보자. 구현하는 이유와 목적은 다음과 같다.

- Docker Hub등의 Public Registry의 경우 하나의 이미지만 private 등록이 가능하고 organization의 경우 비용을 지불해야 하지만, Private Registry는 제한이 없다.

- 개인 공간에서 보다 많은 권한을 부여하여 사용할 수 있다.

Docker Private registry는 내부망에 Registry를 쉽게 구축해서 프로젝트 단위의 이미지를 관리하기 위한 좋은 방법이다.

### 1. Docker registry Images 가져오기

```bash
# docker pull registry:2
Trying to pull repository docker.io/library/registry ... 
latest: Pulling from docker.io/library/registry
c87736221ed0: Pull complete 
1cc8e0bb44df: Pull complete 
54d33bcb37f5: Pull complete 
e8afc091c171: Pull complete 
b4541f6d3db6: Pull complete 
Digest: sha256:8004747f1e8cd820a148fb7499d71a76d45ff66bac6a29129bfdbfdc0154d146
Status: Downloaded newer image for docker.io/registry:latest
```

`docker images`로 이미지를 확인해보자.

### 2. Docket Registry 실행

```bash
# docker run -d -p 5000:5000 --restart=always --name registry registry:2
```

docker run 명령어로 컨테이너를 실행한다.

- --name은 docker image 이름

- -d daemon으로 (백그라운드) 실행

- -p 5000:5000 registry 실행 (local 5000번 포트 -> 이미지 5000번 포트로 바인딩)

Docker registry가 잘 실행되었는지 확인해보자.

```
# docker ps -a
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                    NAMES
3d407c3736dd        registry            "/entrypoint.sh /e..."   About a minute ago   Up About a minute   0.0.0.0:5000->5000/tcp   repo-registry
```

만약 레지스트리에 비밀번호를 설정하고 싶다면 이렇게 하면 된다.

```
# 사용자 정보 담을 파일 경로 생성
cd ~
mkdir .registry_auth
      
# 사용자 정보담은 파일 생성
docker run --entrypoint htpasswd httpd -Bbn {user} {password} > /home/admin/.registry_auth/htpasswd
      
# registry 컨테이너 띄우기
docker run -d \
--name registry \
--restart=always \
-p 5000:5000 \
-v /home/admin/registry_data:/var/lib/registry \
-v /home/admin/registry_auth:/auth \
-e "REGISTRY_AUTH=htpasswd" \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry Realm" \
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
registry
```

### 3. 이미지 push

다음과 같은 형식으로 이미지를 build하고 push할 수 있다.

Dockerfile이 있다고 가정했을때, 이렇게 해주면 된다.

```bash
docker build -t {주소(IP:Port)}/{레포지토리 이름}:{버전} .
docker push {주소(IP:Port)}/{레포지토리 이름}:{버전}
```
