
CUE는 논리 프로그래밍에 기반을 둔 오픈소스 데이터 검증 언어 및 추론 엔진이다. 이 언어는 데이터 검증, 템플릿 작성, 구성 관리, 쿼리 실행, 코드 생성, 스크립팅 등 다양한 용도로 사용될 수 있다. CUE의 추론 엔진은 코드 내에서 데이터를 검증하거나 코드 생성 파이프라인의 일부로 활용될 수 있어 유연성이 높다.
 
JSON의 슈퍼셋이기 때문에 json과 비슷하게 사용할 수 있고, json이나 yaml로 export하는 것도 가능하다.

```json
// json.cue
one: 1
two: 2

// A field using quotes.
"two-and-a-half": 2.5

list: [
  1,
  2,
  3,
]
```

```json
$ cue export json.cue
{
    "one": 1,
    "two": 2,
    "two-and-a-half": 2.5,
    "list": [
        1,
        2,
        3
    ]
}
```

```yaml
$ cue export --out yaml json.cue
one: 1
two: 2
two-and-a-half: 2.5
list:
  - 1
  - 2
  - 3
```

### 그래프 통합

CUE는 그래프 통합(graph unification)을 중심으로 설계되었다. 그래프 통합은 타입과 값의 세트가 방향을 가진 그래프로 모델링 될 수 있어서 모든 그래프의 가장 구체적인 표현으로 통합될 수 있다.

쉽게 말해 CUE에서 타입은 값이다. 이는 타입을 필드에 할당할 수 있고 그 즉시 구성에서 값을 제약하는 데 사용할 수 있다는 의미이다. 필드는 각 구조체에서 구체적인 값을 더 제약하는 것도 볼 수 있다. 아래는 이 특성을 보여주는 CUE 예시이다.

```json
// Schema
municipality: {
  name:    string
  pop:     int
  capital: bool
}

// Schema & Data
// largeCapital은 인구 크기에 대한 제약사항을 가진 municipiality이다. 
largeCapital: municipality
largeCapital: {
  name:    string
  pop:     >5M
  capital: true
}

// Data
// moscow는 모든 필드에 구체적인 값(가장 구체적인 타입)을 가지는 largeCapital이다. 
// largeCapital은 moscow를 포함하고 moscow는 largeCapital의 인스턴스다.
moscow: largeCapital
moscow: {
  name:    "Moscow"
  pop:     11.92M
  capital: true
}
```

### 타입 검사와 보일러 플레이트 제거

타입과 추상화는 큰 규모의 구성을 관리하는데 가장 큰 요소이다. 타입으로 데이터에서 제약 사항을 표현하고 잠재적인 수많은 사용자에게 의도를 선언한다. 구성을 정의하고 자동화된 문서로 제공될 때 타입은 사용자를 에러에서 보호해준다.

CUE의 타입 시스템은 표현력이 뛰어나서 다른 필드의 선택 사항과 제약 사항을 지정하기 위해 필드를 단순히 타입으로 표시할 수 있다. 이러한 특징으로 유연성은 덜하지만 대신 훨씬 명확하다. 

```json
Spec :: {
  kind: string

  name: {
    first:   !="" // 지정되어야 하고 비어있으면 안된다
    middle?: !="" // 선택적이지만 지정할 때는 비어있으면 안된다
    last:    !=""
  }

  // 최소는 최대보다 엄격하게 작아야 하고 반대도 마찬가지다
  minimum?: int & <maximum
  maximum?: int & >minimum
}

// spec은 Spec 타입이다.
spec: Spec
spec: {
  knid: "Homo Sapiens" // 오타가 난 필드로 에러

  name: first: "Jane"
  name: last:  "Doe"
}
```

### k8s 예시

필요한 정보를 가진 deployment 템플릿을 아래처럼 정의할 수 있다. 필요한 경우 모듈, 컴포넌트에 따라 고정되는 값을 미리 넣어두고 사용할 수 있다.

```json
deployment: [Name=_]: _base & {
	// Allow any string, but take Name by default.
	name:     string | *Name
	kind:     *"deployment" | "stateful" | "daemon"
	replicas: int | *1

	image: string

	// expose port defines named ports that is exposed in the service
	expose: port: [string]: int

	// port defines named ports that is not exposed in the service.
	port: [string]: int

	arg: [string]: string
	args: *[ for k, v in arg {"-\(k)=\(v)"}] | [...string]

	// Environment variables
	env: [string]: string

	envSpec: [string]: {}
	envSpec: {
		for k, v in env {
			"\(k)": value: v
		}
	}

	volume: [Name=_]: {
		name:      string | *Name
		mountPath: string
		subPath:   string | *null
		readOnly:  *false | true
		kubernetes: {}
	}
}
```

사용할 때는 동적으로 구분하여 넣을 값만 아래처럼 넣어줄 수 있다.

```go
package kube

deployment: host: {
	replicas: 2
	image:    "gcr.io/myproj/host:v0.1.10"
}
```

이 예제에 대한 자세한 설명은 [여기](https://github.com/cue-labs/cue-by-example/tree/main/003_kubernetes_tutorial)에서 볼 수 있다.

---
참고
- https://cuelang.org/
- https://github.com/cue-labs/cue-by-example/tree/main
- https://blog.outsider.ne.kr/1600