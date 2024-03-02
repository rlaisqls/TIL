
### 1. kubectl을 설치한다.

버전은 1.22로 통일한다.

linux 기준 명령어는 다음과 같다.

```bash
curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl
```

mac 기준 명령어는 다음과 같다.

```bash
curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/darwin/amd64/kubectl
```

window 기준 명령어는 다음과 같다.

```bash
curl -o kubectl.exe https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/windows/amd64/kubectl.exe
```

### 2. minikube 실행 파일을 다운로드받는다.

linux 기준 명령어는 다음과 같다.

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

mac 기준 명령어는 다음과 같다.

```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube
```

window에선 PowerShell을 관리자 권한으로 열어 다음 두개의 명령어를 입력한다.

```bash
New-Item -Path 'c:\' -Name 'minikube' -ItemType Directory -Force
Invoke-WebRequest -OutFile 'c:\minikube\minikube.exe' -Uri 'https://github.com/kubernetes/minikube/releases/latest/download/minikube-windows-amd64.exe' -UseBasicParsing
```

```bash
$oldPath = [Environment]::GetEnvironmentVariable('Path', [EnvironmentVariableTarget]::Machine)
if ($oldPath.Split(';') -inotcontains 'C:\minikube'){ `
  [Environment]::SetEnvironmentVariable('Path', $('{0};C:\minikube' -f $oldPath), [EnvironmentVariableTarget]::Machine) `
}
```

minikube 실행 전, 터미널을 닫고 다시 열면 끝이다.

### 3. 클러스터를 실행한다.

```
minikube start
```

만약 실행에 실패한다면, <a href="https://minikube.sigs.k8s.io/docs/drivers/">드라이버 페이지</a>에 가서 container나 VM manager를 사용해볼 수 있다.

```bash
minikube start --vm-driver=docker --base-image="kicbase/stable:v0.0.32" --image-mirror-country='cn' --image-repository='registry.cn-hangzhou.aliyuncs.com/google_containers' --kubernetes-version=v1.23.8 --force-systemd=true       
```

혹시 이상한 이유로 실행이 실패한다면 이 명령어를 써볼 수 있다. 본인은 위 명령어로 성공했다. (mac)

```bash
minikube start --extra-config=kubeadm.ignore-preflight-errors=NumCPU --force --cpus=1
```

만약 성능 제약을 무시하고 실행하길 원한다면 위와 같은 명령어를 사용할 수 있다.

> 여담이지만 싱글코어인 AWS EC2 t2.micro에서 minikube를 사용하는 것은 그렇게 좋은 선택이 아닌 것 같다......<br>배포에 K8s가 꼭 필요한 상황이 아니라면 그냥 로컬에서 돌려보자.

### 3. 클러스터와 상호작용해본다.

kubectl로 클러스터에 액세스 해본다. 또는, minikube로 명령어를 실행해본다. :
```bash
kubectl get po -A
minikube kubectl -- get po -A
```

아래 명령어로 minikube가 기본으로 사용되도록 설정할 수 있다.
```bash
alias kubectl="minikube kubectl --"
```

처음에는 스토리지 프로비저너와 같은 일부 서비스가 아직 실행 상태가 아닐 수도 있다. 대시보드로 클러스터의 상태를 확인해본다 :

```bash
minikube dashboard
```

### 4. 애플리케이션을 배포해본다.

배포를 만들고 expose로 포트를 지정해준다 :
```bash
kubectl create deployment hello-minikube --image=docker.io/nginx:1.23
kubectl expose deployment hello-minikube --type=NodePort --port=80
```

위의 명령어 대신 이 명령어로 포트포워딩을 설정할 수도 있다 :
```bash
kubectl port-forward service/hello-minikube 8080:8080
```

배포가 잘 완료되었는지 확인한다 :
```bash
kubectl get services hello-minikube
```

외부에서 접근할 수 있도록 launch한다.
```bash
minikube service hello-minikube --url
```

### 5. 클러스터를 관리한다.

쿠버네티스 일시 중지 (애플리케이션에 영향 X):
```bash
minikube pause
```

재시작:
```bash
minikube unpause
```

클러스터 멈추기:
```js
minikube stop
```

기본 메모리 제한 변경 (재시작 필요):
```js
minikube config set memory 9001
```

설치된 쿠버네티스 서비스 목록 보기:
```bash
minikube addons list
```

모든 클러스터 삭제:
```js
minikube delete --all
```