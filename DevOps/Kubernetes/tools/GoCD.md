

GoCD는 CI/CD(지속적 배포-Continuous Delivery) 파이프라인을 쉽게 모델링 및 시각화할 수 있도록 해주는 툴이다. 

젠킨스처럼 다양한 플러그인을 지원하지는 않지만, 파이프라인 요청에 따라 클러스터에서 적절한 리소스를 할당해 실해주는 Ad-Hoc 환경을 지원해주기 때문에 클라우드 환경에 좀더 적합할 수 있다.

## 실습

### 설치

helm으로 빠르게 깔아보자

```
helm repo add gocd https://gocd.github.io/helm-chart
helm repo update
helm install gocd gocd/gocd --namespace gocd --create-namespace
```

### 파이프라인 수정

처음 들어가면 getting_started_pipeline이 보인다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/56f55db0-815d-47bf-9d1a-59e331376c98" style="height: 300px"/>

GoCD의 파이프라인은 여러 개의 Stage로 구성되고, stage 밑에는 각각의 독립적인 job이 존재하여 병렬 실행되고, job의 하위에는 여러 Task가 존재한다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/ee8b09b8-f2d7-463d-b6cc-d38fee0ed450" style="height: 155px"/>

Material에서 Pipeline이 트리거되기 위한 조건, Git, Subversion… 등 Pipeline이 끝난 뒤 Pipeline이 트리거되도록 설정할 수 있다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/2970f8f9-ac60-49ba-b284-7f0c0aa421a7" style="height: 169px"/>

GUI에서의 설정은 입력칸이 보이는대로 적절히 하면 된다.

### 코드로 정의 

파이프라인을 코드로 정의하는 기능을 제공한다. 파이프라인 생성시 New Pipeline as Code를 선택하면 된다.

GUI에서 코드를 직접 넣는 것은 안되고, Github 등 소스에 저장되어있는 코드와 연결하여 생성하는 것만 가능한 것 같다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/78e30027-5590-4fe1-bab3-e66763d99248" style="height: 360px"/>

### Github 연결

파이프라인 코드를 Github 레포에 연동하고, 해당 레포에 있는 파이프라인이 자동으로 생성 및 싱크 되도록 할 수 있다. 그렇게 하려면 Admin -> Config Repositories에 들어가서 레포를 연결해줘야 한다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/d6f59b03-c61d-4adf-b8ab-4d206f35c77b" style="height: 360px">

공식에서 제공하는 sample 파이프라인을 설치해서 실행시켜보려면 이 [문서](https://docs.gocd.org/current/gocd_on_kubernetes/importing_a_sample_workflow.html)를 참고할 수 있다.

### Template

파이프라인 템플릿을 만들어 활용할 수도 있다. Admin > Template 탭에 가서 생성하면 된다. [(문서)](https://docs.gocd.org/current/configuration/pipeline_templates.html)

<img src="https://github.com/rlaisqls/TIL/assets/81006587/8b399c40-4239-4fa6-84ef-7997fa0964de" style="height: 210px"/>

---
## 실습

[문서](https://docs.gocd.org/current/gocd_on_kubernetes/importing_a_sample_workflow.html)에 따라 데모 레포지토리에 있는 파이프라인을 가져와 실행하는 실습을 해보자.

### 1. Artifact Store 설정

파이프라인에서 dockerhub에 접근하기 위해 Admin > Artifact Stores에 들어가 dockerhub 계정을 설정해준다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/3bce8027-9adf-4907-855f-08ff147e09a0" style="height: 300px"/>

<img src="https://github.com/rlaisqls/TIL/assets/81006587/e0373b7d-2a8f-4670-9e1c-bf0f47b17239" style="height: 300px"/>

### 2. Secret, Elastic Agent 설정

파이프라인에서 사용할 변수를 K8s secret으로 생성하고, Elastic Agent pod에 환경변수로 등록한다.

우선 k8s secret을 생성한다.

```yaml
cat <<EOF >./secrets-for-gocd.yaml
apiVersion: v1
kind: Secret
metadata:
  name: secrets-for-gocd
  namespace: gocd
type: Opaque
data:
  DOCKERHUB_USERNAME: <Base64 encoded Dockerhub user name>
  DOCKERHUB_ORG: <Base64 encoded Dockerhub organization>
EOF
kubectl apply -f secrets-for-gocd.yaml -n gocd
```

이후 Admin > Elastic Agent Configuration 탭에서 해당 환경변수를 Agent pod의 환경변수로 넣도록 한다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/af69600a-e578-418d-94a2-8eda67e7c173" style="height: 300px"/>
<img src="https://github.com/rlaisqls/TIL/assets/81006587/64ff1ef3-d077-43a7-b675-1cb3b2c60c3a" style="height: 300px"/>

pod yaml을 선택하고 아래와 같이 매니페스트를 넣으면 된다.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-name-prefix-{{ POD_POSTFIX }}
  labels:
    app: web
spec:
  containers:
    - name: gocd-agent-container-{{ CONTAINER_POSTFIX }}
      image: gocd/gocd-agent-wolfi:v24.2.0
      env:
        - name: DOCKERHUB_USERNAME
          valueFrom:
            secretKeyRef:
              name: secrets-for-gocd
              key: DOCKERHUB_USERNAME
        - name: DOCKERHUB_ORG
          valueFrom:
            secretKeyRef:
              name: secrets-for-gocd
              key: DOCKERHUB_ORG
        - name: NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
      securityContext:
        privileged: true
```

### 3. Config Repository

Admin > Config Repository를 설정해서 데모 레포지토리에 있는 파이프라인을 가져오도록 한다. 이름과 URL(https://github.com/gocd-demo/sample-k8s-workflow)을 입력해주고, 아래로 스크롤을 내려 Rule에서 파이프라인 그룹에 파이프라인을 추가할 수 있도록 허용해준다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/cc1e4c4d-dac8-40cc-9ce8-a6153b9406db" style="height: 300px"/>
<img src="https://github.com/rlaisqls/TIL/assets/81006587/2b784648-00f1-4cda-95f3-7b6f00bb4a1e" style="height: 300px"/>

### 4. 실행 확인

파이프라인 대시보드에서 파이프라인이 실행되는 것을 확인한다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/8f849a77-89f5-4a5f-ad58-12d53a6c5234" style="height: 250px"/>

---
참고
- https://pnguyen.io/posts/a-sample-gocd-pipeline/
- https://docs.gocd.org/current/introduction/concepts_in_go.html
- https://docs.gocd.org/current/gocd_on_kubernetes/introduction.html
