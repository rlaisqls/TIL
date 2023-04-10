# Git action에 gradle caching 설정하는 법

Gradle은 빌드할때 의존성 패키지들을 모두 다운받는다. 이때 Gradle은 빌드 시간과 네트워크 통신을 줄이기 위해 의존성 패키지를 캐싱해서 재사용하는 방법을 사용한다. 

하지만 Github Actions의 workflow는 매 실행하다 새로운 환경을 구축하고, 매번 새롭게 의존성 패키지들을 가지고 와야 한다. 이는 전체 빌드 시간의 증가로 이어진다. 빌드 시간의 단축을 위해서 우리는 Github Actions의 actions/cache를 사용해서 gradle의 의존성을 캐싱할 수 있다. 

```yml
- name: Gradle Caching
  uses: actions/cache@v3
  with:
    path: |  
        ~/.gradle/caches
        ~/.gradle/wrapper
    key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
    restore-keys: |
        ${{ runner.os }}-gradle-


- name: Grant execute permission for gradlew
  run: chmod +x ./gradlew
  shell: bash

- name: Build with Gradle
  run: ./gradlew build
  shell: bash
```

- path : 캐시의 저장과 복원에 사용되는 runner 내 파일 경로이다. 
- key : 캐시를 저장, 복원에 사용되는 키. 여러 값들을 조합해서 512자 제한으로 생성할 수 있다.
- restore-keys : 내가 설정한 key로 cache miss가 발생할때 사용할 수 있는 후보군 키들이다. 

gradle에 정의된 git action을 활용하면 아래와 같이 사용할 수 있다.

`gradle-build-action`의 용도와 의미에 대해선 추후 별도의 문서로 작성할 예정이다.

```yml
      - name: Build Gradle
        uses: gradle/gradle-build-action@v2
        with:
          arguments: |
            build
            --build-cache
            --no-daemon
```