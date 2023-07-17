
# Apps of Apps

ArgoCD application을 모아서 관리하는 패턴을 `App of Apps` 패턴이라고 한다. app of app 패턴으로 구성된 application을 sync하면 여러 argoCD application을 생성하고, 생성된 application은 바라보는 git에 저장된 쿠버네티스 리소스를 배포한다.

상위 앱이, 하위 앱을 여러개 포함하는 구조라고 보면 된다. 

공식 레포에 있는 예제를 살펴보자. (https://github.com/argoproj/argocd-example-apps/tree/master/apps)
 
```yml
├── Chart.yaml
├── templates
│   ├── guestbook.yaml
│   ├── helm-dependency.yaml
│   ├── helm-guestbook.yaml
│   └── kustomize-guestbook.yaml
└── values.yaml
```

`Chart.yaml`는 여러 application들로 구성되어 있다.

```yml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: guestbook
  namespace: argocd
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  destination:
    namespace: argocd
    server: {{ .Values.spec.destination.server }}
  project: default
  source:
    path: guestbook
    repoURL: https://github.com/argoproj/argocd-example-apps
    targetRevision: HEAD
```

이 앱을 배포하면, 이 차트에 대한 배포와 하위에 대한 앱들이 자동으로 생긴다.

---

## cascade

삭제를 위한 cascade 옵션들이 있다. default 옵션인 cascade를 선택하면 app of app application과 모든 application이 삭제된다. 하지만, non cascade를 선택하면 app of app application만 삭제되고 다른 application은 유지된다.