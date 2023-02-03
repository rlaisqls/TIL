# ⚓ Service

쿠버네티스 환경에서 **Service**는 <u>Pod들을 통해 실행되고 있는 애플리케이션을 네트워크에 노출(expose)시키는 가상의 컴포넌트</u>다. 쿠버네티스 내부의 다양한 객체들이 애플리케이션과, 그리고 애플리케이션이 다른 외부의 애플리케이션이나 사용자와 연결될 수 있도록 도와주는 역할을 한다.

쿠버네티스에 Service가 있는 이유는, Pod들이 반영속적인 특성을 가지고 있기 때문이다. 쿠버네티스에서의 Pod는 무언가가 구동 중인 상태를 유지하기 위해 동원되는 **일회성 자원**으로 언제든 다른 노드로 옮겨지거나 삭제될 수 있다. 또한 Pod는 **생성될 때마다 새로운 내부 IP**를 받게 되므로, 이것만으로 클러스터 내/외부와의 통신을 계속 유지하기 어렵다. 

따라서 쿠버네티스는 <u>Pod가 외부와 통신할 수 있도록 클러스터 내부에서 고정적인 IP를 갖는 Service</u>를 이용하도록 하고 있다. 서비스는 Deployment나 StatefulSet처럼 같은 애플리케이션을 구동하도록 구성된 여러 Pod들에게 **단일한 네트워크 진입점**을 부여하는 역할도 한다.

서비스를 정의하고 생성할 때에는 `spec.port` 아래에 연결하고자 하는 항목별로 각각 2개씩의 포트가 지정되어야 한다.


`port` : 서비스 쪽에서 해당 Pod를 향해 열려있는 포트를 의미한다.

`targetPort` : Pod의 애플리케이션 쪽에서 열려있는 포트를 의미한다. Service로 들어온 트래픽은 해당 Pod의 <클러스터 내부 IP>:<targetPort>로 넘어가게 된다.

```yml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    name: MyApp
  ports:
    - protocol: TCP
      port: 80 # Service가 줄 포트
      targetPort: 9376 # Pod가 받을 포트
```

# 서비스의 유형

쿠버네티스에서 서비스의 유형은 크게 4가지로 분류된다. 명세(spec) 상에 type가 별도로 지정되지 않았다면 ClusterIP로 고정된다.

|이름|설명|
|-|-|
|ClusterIP (Default)|Pod들이 클러스터 내부의 다른 리소스들과 통신할 수 있도록 해주는 가상의 클러스터 전용 IP|
|NodePort|외부에서 노드 IP의 특정 포트로 들어오는 요청을 감지하여, 해당 포트와 연결된 Pod로 트래픽을 전달|
|LoadBalancer|로드밸런서를 클러스터의 서비스로 프로비저닝할 수 있는 유형|
|ExternalName|selector 대신 DNS name을 직접 명시|

## 1. ClusterIP

ClusterIP는 Pod들이 클러스터 내부의 다른 리소스들과 통신할 수 있도록 해주는 가상의 클러스터 전용 IP다. 이 유형의 서비스는 `<ClusterIP>`로 들어온 클러스터 내부 트래픽을 해당 Pod의 `<Pod IP>:<targetPort>`로 넘겨주도록 동작하므로, **오직 클러스터 내부에서만 접근 가능**하게 된다. 쿠버네티스가 지원하는 기본적인 형태의 서비스다.

<img height=300px src="https://user-images.githubusercontent.com/81006587/205313660-eb2175c2-6fb6-4ea7-bbaa-417f14995094.png">

#### Selector를 포함하는 형태

TCP 포트 9376을 수신 대기(listen)하며 app=myapp, type=frontend라는 레이블을 공유하는 파드들에게 myapp-service라는 이름으로 접근할 수 있게 해주는 ClusterIP 유형의 서비스를 정의하면 다음과 같다.

```yml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: ClusterIP # 생략 가능
  selector:
    app: myapp
  ports:
    - protocol: TCP
      port: 80 # Service가 줄 포트
      targetPort: 9376 # Pod가 받을 포트
```

`spec.selector`에서 지정된 레이블로 여러 파드들이 존재할 경우, 서비스는 그 파드들을 **외부 요청(request)을 전달할 엔드포인트(endpoints)로 선택하여 트래픽을 분배**하게 된다. 이를 이용하여 <u>한 노드 안에 여러 파드, 또는 여러 노드에 걸쳐 있는 여러 파드에 동일한 서비스</u>를 적용할 수 있다.

때로는 여러 포트들의 연결이 필요할 때도 있는데, 그럴 땐 spec.ports에 리스트 형태로 name 값을 부여하여 각각 추가해주면 된다. 

#### Selector가 제외된 형태

필요에 따라 **엔드포인트(Endpoints)를 수동으로 직접 지정해줘야 할 때**가 있다. 테스트 환경과 상용 환경의 설정이 서로 다르거나, 다른 네임스페이스 또는 클러스터에 존재하는 파드와의 네트워크를 위해 서비스-서비스 간의 연결을 만들어야 하는 상황 등이 있다.

이런 경우에는 `spec.selector` 없이 서비스를 만들고, <u>해당 서비스가 가리킬 엔드포인트(Endpoints) 객체를 직접 만들어 해당 서비스에 맵핑</u>하는 방법이 있다.

```yml
apiVersion: v1
kind: Endpoints
metadata:
  app: my-service # 연결할 서비스와 동일한 name을 메타데이터로 입력
subsets: # 해당 서비스로 가리킬 endpoint를 명시
  - addresses:
      - ip: 192.0.2.42
    ports:
      - port: 9376
```

이때 주의해야 할 점은, 엔드포인트로 명시할 IP는 **loopback(127.0.0.0/8) 또는 link-local(169.254.0.0/16, 224.0.0.0/24) 이어서는 안 된다**는 것이다. 이에 대한 자세한 내용은 쿠버네티스 <a href="https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors">공식문서</a>에서 확인할 수 있다.


## 2. NodePort

NodePort는 외부에서 노드 IP의 특정 포트(`<NodeIP>:<NodePort>`)로 들어오는 요청을 감지하여, 해당 포트와 연결된 Pod로 트래픽을 전달하는 유형의 서비스다. 이때 클러스터 내부로 들어온 트래픽을 특정 Pod로 연결하기 위한 ClusterIP 역시 자동으로 생성된다.

<img height=300px src="https://user-images.githubusercontent.com/81006587/205410661-f0834032-92ad-4e60-b81d-5f55695842e8.png">

이 유형의 서비스에서 `spec.ports` 아래에 `nodePort`를 추가로 지정할 수 있다. `nodePort`는 외부에서 노드 안의 특정 서비스로 접근할 수 있도록 지정된 노드의 특정 포트응 의미한다. `nodePort`로 할당 가능한 포트 번호의 범위는 `30000`에서 `32767`사이이며, 미지정시 해당 범위 안에서 임의로 부여된다.

```yml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: NodePort
  selector:	# 이 서비스가 적용될 파드 정보를 지정
    app: myapp
  ports:
  - targetPort: 80	
    port: 80     
    nodePort: 30008 # 외부 사용자가 애플리케이션에 접근하기 위한 포트번호(선택)
```

## 3. LoadBalancer

별도의 외부 로드밸런서를 제공하는 클라우드(AWS, Azure, GCP 등) 환경을 고려하여, 해당 로드밸런서를 클러스터의 서비스로 프로비저닝할 수 있는 유형이다.

<img height=300px src="https://user-images.githubusercontent.com/81006587/205411535-2783360f-aae3-48e5-b8a0-9f97b738784c.png">

이 유형은 서비스를 **클라우드 제공자 측의 자체 로드밸런서**로 노출시키며, 이에 필요한 NodePort와 ClusterIP 역시 자동 생성된다. 이때 프로비저닝된 로드 밸런서의 정보는 서비스의 `status.loadBalancer` 필드에 게재된다.

```yml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type:: LoadBalancer
  clusterIP: 10.0.171.239	#  클러스터 IP
  selector:				
    app: myapp
  ports:
  - targetPort: 80	
    port: 80
    nodePort: 30008
status:
  loadBalancer:	# 프로비저닝된 로드 밸런서 정보
    ingress:
    - ip: 192.0.2.127
```


이렇게 구성된 환경에서는, 외부의 로드 밸런서를 통해 들어온 트래픽이 서비스의 설정값을 따라 해당되는 파드들로 연결된다. 이 트래픽이 어떻게 로드 밸런싱이 될지는 클라우드 제공자의 설정에 따르게 된다.

만약 이러한 방식의 로드 밸런서 프로비저닝을 지원하지 않는 클라우드 환경(예: Virtualbox)일 경우, 이 유형으로 지정된 서비스는 **NodePort와 동일한 방식**으로 동작하게 된다.

## 4. ExternalName

서비스에 selector 대신 DNS name을 직접 명시하고자 할 때에 쓰인다. spec.externalName 항목에 필요한 DNS 주소를 기입하면, 클러스터의 DNS 서비스가 해당 주소에 대한 CNAME 레코드를 반환하게 된다.

```yml
apiVersion: v1
kind: Service
metadata:
  name: my-service
  namespace: prod
spec:
  type: ExternalName
  externalName: my.database.example.com
```

### CLI 명령어로 파드에 서비스 적용하기

서비스는 YAML 형태로 정의하는 것이 좋지만, 생성된 파드를 간단히 외부에 노출시키고자 할 때에는 CLI 명령어로 보다 간편하게 수행할 수도 있다. 특정 리소스에 한해 즉시 노출시키고자 한다면 kubectl expose 명령을 이용하여 서비스 배포와 노출을 동시에 진행 가능하다.

(이렇게 해도 내부적으로 ClusterIP 타입의 service가 생성되긴 한다.)

```js
kubectl expose pod redis --port=6379 --name redis-service
```