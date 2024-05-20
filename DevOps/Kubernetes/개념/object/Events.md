
Kubernetes Events는 하나의 Kubernetes 리소스 타입으로서 Kubernetes 리소스들의 state 변화, 에러 또는 시스템에 특정 메세지를 전파해야할 때 자동으로 만들어진다. 이러한 Kubernetes Events 리소스는 Kubernetes 개발 및 운영하며 디버깅시에 매우 유용하게 사용된다.

## Events 조회

`kubectl describe pod pod-name`를 사용하면 아랫부분에 Events 항목을 볼 수 있다. 이것이 바로 해당 Pod와 관련된 Kubernetes Events들의 정보를 나타낸다.

<img width="756" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/5f22c8df-9ff9-480d-983d-308a2691c691">

특정 Pod 뿐 아니라 현재 namespace 에 발생하는 모든 Events를 조회하고 싶다면 `kubectl get events` 를 통해 조회할 수 있다. 하지만 모든 리소스들의 Events들이 조회되기 때문에 리소스가 많은 상황이라면 원하는 정보를 찾기 힘들 것이다. 만약 특정 셀렉터를 통해 원하는 정보만 찾아보고 싶다면 `--field-selector` 옵션을 사용하면 된다.

```bash
# Warning 타입만 조회
kubectl get events --field-selector type=Warning

# Pod events를 제외한 다른 events 조회
kubectl get events --field-selector involvedObject.kind!=Pod

# minikube 라는 이름의 node에서 발생한 events만 조회
kubectl get events --field-selector involvedObject.kind=Node,involvedObject.name=minikube
```

Kubernetes를 사용하다보면 Events가 계속 쌓이게 되는데 이걸 계속 유지하다보면 용량 및 성능에서 악영향이 있을 수 있다. 그래서 기본적으로는 1시간동안 유지되고 자동으로 제거됩니다.

## Events 필드 (events.k8s.io v1 Events)

위의 describe 부분의 사진에서 Events 정보를 보면 여러 필드를 가지고 있는 것을 볼 수 있다. Events의 모든 필드는 [Kubernetes Reference](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#event-v1-events-k8s-io)에서 확인하실 수 있다.

간략하게 위에서 출력된 필드만 살펴보자.

- **type**: Normal, Warning 2가지의 값 중 하나를 가지며 추후 추가될 수 있다. 말 그대로 일반적인 작업에 의해 생겨난 Event인지, 아니면 어느 오류 및 실패로 인해 생겨난 Event인지 표현한다.
- **reason**: 왜 해당 Event가 발생했는지를 나타낸다. 딱히 정해진 형식은 없고, 128자 이하의 사람이 이해할 수 있는 짧은 명칭이다. kubelet에서 사용하는 Reason의 종류는 [여기](https://github.com/kubernetes/kubernetes/blob/master/pkg/kubelet/events/event.go)서 볼 수 있다.
- **eventTime**: Age로 출력된 부분의 값을 나타낸다. Event 발생한 시각을 의미하며 MicroTime 타입의 데이터로 이루어져있다.
- **reportingController**: From으로 출력된 부분의 값을 나타낸다. 말 그대로 해당 Event를 발생시킨 Controller의 이름을 의미한다.
- **note**: Events가 발생된 작업. 그 작업의 상태(status)에 대한 설명을 의미한다.

## Deprecated Events

```bash
$ kubectl api-resources -o wide | grep event
NAME                              SHORTNAMES   APIGROUP            NAMESPACED   KIND                             VERBS
events                            ev           v1                  true         Event                            create,delete,deletecollection,get,list,patch,update,watch
events                            ev           events.k8s.io/v1    true         Event                            create,delete,deletecollection,get,list,patch,update,watch
```

Kubernetes 기본 리소스 중 Events는 api group이 `v1`인 것과 `events.k8s.io/v1`인 것 두가지가 있다. 그 이유는 무엇일까? 

기존에 core 그룹의 Events가 존재했다. 하지만 이 Events에는 2가지 문제점이 있었다.

- Events는 어플리케이션 개발자에게 해당 어플리케이션에 무슨 일이 일어나고 있는지 명확하게 알려줄 수 있어야 한다. 하지만 core 그룹의 Events는 불명확한 의미를 가진 스팸성이었다.
- Events는 Kubernetes의 성능에 문제를 일으키거나 영향을 주어서는 안된다. 하지만 core 그룹의 Events는 알려진 성능문제가 존재했다.

이를 비롯한 여러 문제들로 인해 계속해서 변화 요구가 있었고, 이에 새로운 `events.k8s.io` API GROUP의 events가 나오게 된 것이다. 현재까진 `core.Event`에서 `events.Event`로 점점 넘어가고 있는 추세라고 한다. 하위호환성을 지키기 위해 `core.Event` 에서 제거할 필드들은 제거 없이 앞에 Deprecated prefix가 붙은 상태로 유지되었다.

`core.Event`와 `events.Event`의 필드는 조금씩 다르다. 모든 필드 차이들은 [여기](https://github.com/kubernetes/enhancements/blob/master/keps/sig-instrumentation/383-new-event-api-ga-graduation/README.md#backward-compatibility)에서 확인할 수 있다. 

## Event와 Slack 연동

[BotKube](https://botkube.io/), [DataDog](https://docs.datadoghq.com/events/) 등의 툴을 사용해서 Event 정보를 slack 알림으로 전송할 수 있다.

자세한 방법은 각 툴의 사이트를 방문하여 살펴보자 ㅇㅅㅇ

---
참고
- https://github.com/kubernetes/enhancements/blob/master/keps/sig-instrumentation/383-new-event-api-ga-graduation/README.md#motivation