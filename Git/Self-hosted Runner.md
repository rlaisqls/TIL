# Self-hosted Runner

Self-hosted Runner란 Github Actions에서 사용자가 지정하는 로컬 컴퓨팅 자원으로 빌드를 수행하도록 설정하는 기능이다. 주로 배포작업이 많아 배포가 지체되거나 서버 비용이 부담되는 경우 유용하게 쓰인다. 

## 설정 방법

Github Actions을 사용하고자 하는 저장소에서 Settings - Actions - Runners로 이동한다.

<img width="1268" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/6634f525-7bbc-4876-8eae-5e08f7655906">

설정하고자 하는 로컬 머신에 해당되는 OS를 선택하면 OS 별로 설정하는 방법이 Download와 Configure란에 설명되어 있다. Linux 기준으로는 다음과 같다.

#### Download
```bash
# Create a folder
$ mkdir actions-runner && cd actions-runner# Download the latest runner package
$ curl -o actions-runner-linux-x64-2.307.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.307.1/actions-runner-linux-x64-2.307.1.tar.gz# Optional: Validate the hash
$ echo "038c9e98b3912c5fd6d0b277f2e4266b2a10accc1ff8ff981b9971a8e76b5441  actions-runner-linux-x64-2.307.1.tar.gz" | shasum -a 256 -c# Extract the installer
$ tar xzf ./actions-runner-linux-x64-2.307.1.tar.gz
```

#### Configure
```bash
# Create the runner and start the configuration experience
$ ./config.sh --url https://github.com/rlaisqls/rlaisqls --token ATKA767R3GXF2HTFSJ72VZ3E3MNQ6# Last step, run it!
$ ./run.sh
```

Github가 로컬머신에 접속하는 방식이 아닌 로컬머신에서 github 저장소로 접속하는 방식이기 때문에 github 저장소 주소와 액세스 토큰으로 설정해야 한다.

토큰은 개인 계정 Settings - Developer settings - Personal access tokens - Generate new token 에서 `admin:enterprise - manage_runners:enterprise`로 발급받을 수도 있습니다.

## 사용 방법

정상적으로 github에 등록이 되면 github의 Runners에서도 목록을 확인할 수 있습니다.

등록한 Self-hosted Runner를 활성화시키기 위해서는 해당 로컬 기기의 actions-runner 폴더에서 run.sh 프로그램을 실행시킨다.

```bash
./run.sh
```

이제 workflows 디렉토리 안에 actions 사용시 해당 self-hosted runner를 통해 빌드되도록 yaml 파일을 만들어주면 된다.

```bash
runs-on: self-hosted
```

등록된 self-hosted runner가 많을 경우 OS 값을 조합하거나, Custom 라벨을 붙여 구분할 수 있다.

```bash
runs-on: [self-hosted, linux, x64, custom-label]
```

Self-Hosted Runner의 장점으로는 enter Github-hosted Runner와 달리 사용 비용이 전혀 없기 때문에, private repository에서 작업하는 경우에 비용을 줄일 수 있다는 점이 있다. 하지만 사용하는 시점에 Github와 연결이 되어있어야 하고 로컬머신에 대한 관리가 추가로 필요하다는 단점이 있다. 배포하는 상황에 따라서 적절히 로컬 머신을 연결하여 배포용 서버로 사용하면 좋을 것 같다.

---
참고
- https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners
