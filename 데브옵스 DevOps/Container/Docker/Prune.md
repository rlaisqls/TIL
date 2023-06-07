# 🐳 Prune

Docker를 오랜 시간 사용하게 되면 여러가지 오브젝트들이 시스템에 쌓이게 된다. 컨테이너나 이미지는 많으면 수십 수백개까지도 늘어난다. Docker 컨테이너, 이미지, 볼륨은 사용중이 아니더라도 디스크를 차지하고 있다. 

오브젝트들을 일일히 삭제하거나 통째로 날려버릴 수도 있지만, 사용하지 않는 오브젝트들을 파악해 빠르게 시스템 자원을 확보하는 방법도 있다. prune 서브 커맨드가 바로 이런 역할을 한다.

Prune 커맨드를 사용하면 사용하지 않는 컨테이너, 볼륨, 이미지를 일괄적으로 삭제할 수 있다.

## container 

```
docker container prune
```

`--filter` 옵션으로 특정 오브젝트만 삭제할 수도 있다.

```
# 중지된 지 1시간 이상 지난 컨테이너만 삭제
docker container prune --filter until=1h

# env 키가 있는 컨테이너
docker container prune --filter label=env

# env 키가 없는 컨테이너
docker container prune --filter label!=env

# env 키의 값이 development인 컨테이너
docker container prune --filter label=env=development

# env 키의 값이 production이 아닌 컨테이너
docker container prune --filter label!=env=production
```

## image

docker image prune 명령어가 삭제하고자 하는 대상은 dangling된 이미지들이다. 일반적으로 이미지는 이미지를 구분하기 위한 이름을 가지고 있는데, dangling된 이미지는 해당 이미지를 지칭하는 이름이 없는 상태를 의미한다. 예를 들어 같은 이름으로 도커 이미지를 여러번 빌드하다보면 새로 만들어진 이미지가 기존 이미지의 이름을 뺏어버려서, 기존 이미지는 dangling된 상태가 된다.

dangling된 이미지 뿐만아니라 컨테이너에서 사용하고 있지 않은 이미지도 삭제하고 싶다면 `-a` 태그를 사용하면 된다.

```
# dangling된 이미지 삭제
docker image prune

# dangling된 이미지 삭제
docker image prune -a
```

## 볼륨, network
```
docker volume prune
docker network prune
```

## 전체삭제

아래 명령어를 치면, 사용하지 않는 도커 오브젝트가 모두 삭제된다.

```
docker system prune
```