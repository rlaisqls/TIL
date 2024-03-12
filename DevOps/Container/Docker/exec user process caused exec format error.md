
docker image build시 이런 에러가 날 때가 있다.

```bash
exec user process caused “exec format error” 
```

m1으로 빌드한 이미지를 서버가 arm 운영체제인 상황에서 돌리려고 할 떄 나는 에러이다.

이 경우 이미지 빌드시 플랫폼을 지정해줌으로써 해결할 수 있다.

```bash
docker buildx build --platform=linux/amd64 ...
```

## [Buildx](https://github.com/docker/buildx)

Docker는 multi-architecture 빌드 등, 다양한 빌드 옵션을 지원하는 CLI 플러그인인 Buildx를 제공한다. Docker Desktop을 사용하는 Windows나 MacOS 사용자 혹은 DEB, RPM 패키지로 도커를 설치한 사용자들은 자동으로 Buildx 플러그인이 같이 설치된다.

docker buildx 명령어를 터미널에 입력했을 때, 다음과 같은 화면이 출력된다면 buildx를 사용할 수 있다.

```bash
$ docker buildx

Usage:  docker buildx [OPTIONS] COMMAND

Extended build capabilities with BuildKit

Options:
      --builder string   Override the configured builder instance

Management Commands:
  imagetools  Commands to work on images in registry

Commands:
  bake        Build from a file
  build       Start a build
  create      Create a new builder instance
  du          Disk usage
  inspect     Inspect current builder instance
  ls          List builder instances
  prune       Remove build cache
  rm          Remove a builder instance
  stop        Stop builder instance
  use         Set the current builder instance
  version     Show buildx version information

Run 'docker buildx COMMAND --help' for more information on a command
```

