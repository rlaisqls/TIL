
Gradle은 의존성 기반의 프로그래밍용 언어이다. 이 말은 태스크를 정의하고 또한 태스크들 사이의 의존성도 정의 할 수 있다는 뜻이다.

Gradle은 태스크들이 의존성의 순서에 따라 실행되고, 오직 한 번만 실행될 것임을 보장한다.

Gradle은 태스크를 실행하기 전에 완전한 의존성 그래프를 구축한다.

## 빌드 단계

Gradle 빌드는 3단계로 구분된다.

```md
## Initialization
Gradle supports single and multi-project builds. During the initialization phase, Gradle determines which projects are going to take part in the build, and creates a Project instance for each of these projects.

## Configuration
During this phase the project objects are configured. The build scripts of all projects which are part of the build are executed.

## Execution
Gradle determines the subset of the tasks, created and configured during the configuration phase, to be executed. The subset is determined by the task name arguments passed to the gradle command and the current directory. Gradle then executes each of the selected tasks.
```

- **초기화 (Initialization)** : 초기화 단계에서는 어느 프로젝트를 빌드하는지 결정하고 각각에 대해 Project 객체를 생성한다.
- **구성 (Configuration)** : 빌드에 속하는 **모든 프로젝트의 빌드 스크립트**를 실행한다. 이를 통해 프로젝트 객체를 구성한다.
- **실행 (Execution)** : 구성 단계에서 생성하고 설정된 태스크 중에 실행할 것을 결정한다. 이 때 gradle 명령행에 인자로 지정한 태스크 이름과 현재 디렉토리를 기반으로 태스크를 결정하여 선택된 것들을 실행한다.

## 초기화 (Initialization)

그래들은 빌드를 시작하는 단계에서 해당 `settings.gradle` 파일을 기준으로 멀티 모듈로 실행할지, 혹은 싱글로 실행할지를 결정한다. 그래들이 파일을 탐색하고 판단하는 순서는 아래와 같다.

- 현재 디렉토리와 동일한 계층 단계의 master 디렉토리에서 `settings.gradle`을 찾는다.
- 없으면, 부모 디렉토리에서 settings.gradle을 찾는다.
- 없으면, 단일 프로젝트로 빌드를 실행한다.
  
`settings.gradle`가 존재하면 현재 프로젝트가 멀티 프로젝트 계층에 속하는지 판단한다. 아니라면 단일 프로젝트로 실행하고 맞다면 멀티 프로젝트로 빌드를 실행한다.

이런 식으로 작동하는 이유는 멀티 프로젝트 일 경우 모든 멀티프로젝트 빌드 구성을 생성해야하기 때문이다. `-u` 옵션을 주면 부모 디렉토리에서 설정파일을 찾는 것을 막고 항상 단일 프로젝트로 실행한다. `settings.gradle` 파일이 있는 곳에서 `-u`는 아무 기능도 없다.

Gradle은 빌드에 참여하는 모든 프로젝트에 대해 Project 객체를 생성한다. 각 프로젝트는 기본적으로 탑레벨 디렉토리를 이름으로 갖는다. 최상위를 제외한 모든 프로젝트는 부모 프로젝트가 있고, 자식 프로젝트를 가질 수 있다.

Settings File을 통해 하는 작업은 아래와 같은 것들이 있다.

- 빌드 스크립트 클래스 경로에 라이브러리를 추가한다.
- 다중 프로젝트 빌드에 참여할 프로젝트를 정의한다.

## 구성 (Configuration)

구성 단계에서 Gradle은 초기화 단계에서 생성된 프로젝트에 태스크 및 기타 속성을 추가한다. 구성 단계가 끝날 때까지 Gradle은 요청된 작업에 대한 전체 작업 실행 그래프를 갖게 된다.

각 프로젝트 내에서 작업은 방향 비순환 그래프(DAG)를 형성한다.

<img width="784" alt="image" src="https://user-images.githubusercontent.com/81006587/230752723-586f4e22-b76e-41c7-a714-461f3ee8339f.png">


## 실행 (Execution)

실행 단계에서는 task를 직접 실행한다. 구성 단계에서 생성된 태스크 실행 그래프를 사용하여 실행할 태스크를 결정하게 된다.

작업 실행에는 라이브러리 다운로드, 코드 컴파일, 입력 읽기 및 출력 쓰기 등 빌드와 관련된 대부분의 작업이 포함된다.


---

참고

- https://stackoverflow.com/questions/23484960/gradle-executes-all-tasks/23485085#23485085
- https://docs.gradle.org/current/userguide/build_lifecycle.html#sec:build_phases