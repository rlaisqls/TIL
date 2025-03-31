
**Mise**는 개발 환경을 손쉽게 관리할 수 있도록 도와주는 도구로, 다양한 프로그래밍 언어와 툴을 한 번에 관리할 수 있다. `asdf`, `fnm`, `nvm` 등의 버전 관리 도구와 유사하지만, 실행 속도가 더 빠르다.

## 기능

### 멀티 런타임 관리

`mise`는 하나의 도구로 여러 언어와 런타임을 관리할 수 있다. 예를 들어, Node.js, Python, Ruby 등의 버전을 동시에 설치하고 관리할 수 있다.

```sh
mise use node@18 python@3.10
```

위 명령어를 실행하면 현재 프로젝트에서 Node.js 18 버전과 Python 3.10 버전을 사용할 수 있다.

### `.tool-versions` 파일을 통한 버전 고정

프로젝트별로 특정 버전을 고정하려면 `.tool-versions` 파일을 사용하면 된다.

```sh
node 18.16.0
python 3.10.6
```

위 파일을 프로젝트 루트에 두면, `mise`가 자동으로 해당 버전을 사용하도록 설정한다.

### 플러그인 시스템 활용

`mise`는 다양한 언어와 툴을 지원하기 위해 플러그인 시스템을 제공한다.

```sh
mise plugin add rust
mise install rust
```

위와 같이 사용하면 Rust 버전 관리도 가능하다.

### 글로벌 버전 설정

사용자 환경에서 특정 언어의 기본 버전을 설정할 수도 있다.

```sh
mise global node@20
```

이렇게 하면 모든 프로젝트에서 기본적으로 Node.js 20 버전이 적용된다.

### 5. 빠른 실행 속도

Mise는 Rust로 작성되어 기존 `asdf`보다 빠르게 실행된다. 즉, `asdf`와 동일한 기능을 제공하면서도 속도 측면에서 더 큰 이점을 갖는다.

```sh
mise install
```

위 명령어를 실행하면 `.tool-versions`에 정의된 모든 툴을 빠르게 설치한다.

## 설치

### 1. Homebrew

```sh
brew install mise
```

### 2. 스크립트

```sh
curl -fsSL https://mise.run/install.sh | sh
```

설치 후 `mise --version`을 실행하여 정상적으로 설치되었는지 확인할 수 있다.

## 예제

### 1. 특정 프로젝트에서 버전 지정하기

```sh
mise use node@18.16.0
```

이후 `.tool-versions` 파일이 자동으로 생성되어 프로젝트에서 해당 버전이 적용된다.

### 2. 특정 패키지 매니저와 함께 사용하기

예를 들어, Node.js 버전을 `mise`로 관리하고, `pnpm`을 함께 사용할 수 있다.

```sh
mise use node@18
npm install -g pnpm
```

### 3. `.envrc`와 함께 사용하여 자동 설정

`direnv`와 `mise`를 함께 사용하면, 특정 디렉터리에 들어갈 때 자동으로 런타임을 설정할 수 있다.

```sh
echo "use node@18" > .envrc
direnv allow
```

---
참고

- <https://github.com/jdx/mise>
- <https://mise.jdx.dev/>
- <https://mise.jdx.dev/dev-tools/>
