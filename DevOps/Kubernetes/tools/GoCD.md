

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

<img src="https://github.com/rlaisqls/TIL/assets/81006587/56f55db0-815d-47bf-9d1a-59e331376c98" style="height: 400px"/>

GoCD의 파이프라인은 여러 개의 Stage로 구성되고, stage 밑에는 각각의 독립적인 job이 존재하여 병렬 실행되고, job의 하위에는 여러 Task가 존재한다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/ee8b09b8-f2d7-463d-b6cc-d38fee0ed450" style="height: 175px"/>

Material에서 Pipeline이 트리거되기 위한 조건, Git, Subversion… 등 Pipeline이 끝난 뒤 Pipeline이 트리거되도록 설정할 수 있다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/2970f8f9-ac60-49ba-b284-7f0c0aa421a7" style="height: 200px"/>

GUI에서의 설정은 입력칸이 보이는대로 적절히 하면 된다.

### 코드로 정의 

파이프라인을 코드로 정의하는 기능을 제공한다. 파이프라인 생성시 New Pipeline as Code를 선택하면 된다.

GUI에서 코드를 직접 넣는 것은 안되고, Github 등 소스에 저장되어있는 코드와 연결하여 생성하는 것만 가능한 것 같다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/78e30027-5590-4fe1-bab3-e66763d99248" style="height: 400px"/>

### Github 연결

파이프라인 코드를 Github 레포에 연동하고, 해당 레포에 있는 파이프라인이 자동으로 생성 및 싱크 되도록 할 수 있다. 그렇게 하려면 Admin -> Config Repositories에 들어가서 레포를 연결해줘야 한다.

<img src="https://github.com/rlaisqls/TIL/assets/81006587/d6f59b03-c61d-4adf-b8ab-4d206f35c77b" style="height: 300px">

공식에서 제공하는 sample 파이프라인을 설치해서 실행시켜보려면 이 [문서](https://docs.gocd.org/current/gocd_on_kubernetes/importing_a_sample_workflow.html)를 참고할 수 있다.

### Template

파이프라인 템플릿을 만들어 활용할 수도 있다. Admin > Template 탭에 가서 생성하면 된다. [(문서)](https://docs.gocd.org/current/configuration/pipeline_templates.html)

<img src="https://github.com/rlaisqls/TIL/assets/81006587/8b399c40-4239-4fa6-84ef-7997fa0964de" style="height: 300px"/>

---
참고
- https://pnguyen.io/posts/a-sample-gocd-pipeline/
- https://docs.gocd.org/current/introduction/concepts_in_go.html
- https://docs.gocd.org/current/gocd_on_kubernetes/introduction.html