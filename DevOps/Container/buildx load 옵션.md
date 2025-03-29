
Docker의 고급 빌드 도구인 `buildx`는 멀티 플랫폼 지원과 빌드 캐시 최적화 기능 등 다양한 장점을 제공한다. 그러나 빌드 결과가 로컬에 저장되지 않거나 푸시되지 않는 문제가 발생할 수 있다. 이는 `--load` 또는 `--push` 옵션을 명시하지 않았기 때문이다.

## 예시

```bash
docker buildx build --platform linux/amd64 -t subtitle-generator .
```

- 빌드는 성공하지만 `--load`나 `--push` 옵션이 없어서 결과 이미지가 로컬에 존재하지 않는다

빌드 로그에는 다음과 같은 경고가 나타난다.

```
WARNING: No output specified with docker-container driver. Build result will only remain in the build cache.
```

## 원인

buildx는 내부적으로 BuildKit을 사용하며, 이때 사용되는 드라이버 종류에 따라 빌드 결과 처리 방식이 달라진다.

|드라이버 종류|설명|--load 없이 로컬 저장 여부|
|-|-|-|
|docker|기본 Docker 데몬 사용|저장됨|
|docker-container|BuildKit 컨테이너를 통해 빌드|저장되지 않음 (명시 필요)|

현재 사용 중인 빌더 드라이버는 다음 명령어로 확인할 수 있다.

```
docker buildx ls
```

## buildx 주요 옵션

- `--load`
  - 빌드된 이미지를 로컬 docker 데몬에 저장
  - 테스트나 로컬 실행 목적
  - 단일 플랫폼 빌드에서만 사용 가능

    ```
    docker buildx build --platform linux/amd64 -t my-image-name . --load
    ```

- `--push`

  - 빌드된 이미지를 원격 레지스트리로 푸시
  - 멀티 플랫폼 빌드 지원

    ```
    docker buildx build --platform linux/amd64 -t my-registry/my-image-name . --push
    ```

- `--output`

  - 결과물을 파일 또는 다른 형식으로 출력
  - 예: tar 파일로 저장

    ```
    --output type=tar,dest=./image.tar
    ```
