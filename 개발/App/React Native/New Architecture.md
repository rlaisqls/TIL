## JIS
- 맨 처음엔 RN에서 js 엔진으로 JSC(Apple에서 만든, safari에서 쓰이는 엔진)가 사용되었는데, 브릿지의 책임이 커지고 서로 강결합된다는 문제가 발생했다. 이러한 문제를 해결하기 위해 엔진 인터페이스(JSI)가 만들어졌다.
- JIS는 Native와 JS 코드가 직접 상호작용할 수 있도록 한다. 즉 JSI라는 인터페이스를 통해서 자바스크립트가 호스트 쪽 객체의 레퍼런스를 직접 가질 수 있도록, 그리고 호스트 쪽 메소드도 직접 호출할 수 있도록 한다.

- 데이터 전달 과정
  - 네이티브 모듈 인프라로 전달
  - js runtime이 c++로 전해주고, 네이티브 모듈 인프라로 전해서 처리
  - 뷰도 같은 식으로 전달해서 UI Manager로 전해서 처리 (메모리 업데이트 되면 JS에 반영이 되어서 표시됨)
  - [Native Runtime] <-JSI-> [C++ memory] <-JSI impl-> [Js Runtime]
  - [Js Runtime] -JS Value-> [C++ memory] -jsi::Value-> [HostFunction "nativeCall"] -C++ dynamic-> [native module infra] -native type-> [MyModule]

## Codegen

RN에서는 빌드시에 **Codegen**이라는 기능을 통해 플랫폼 코드의 타입을 js에서도 활용할 수 있게 정적 타이핑을 지원한다. 
- Codegen은 코드 생성(Code Generation)의 줄임말로, React Native에서 TypeScript 또는 Flow 타입 정의를 기반으로 네이티브 코드(C++ 등)를 자동으로 생성하는 도구이다.
- 이를 통해 JavaScript와 네이티브 코드 간의 타입 안정성을 보장하고, 개발 과정을 간소화할 수 있다. 
- 실행 흐름은 다음과 같다. 
    1. 빌드 명령이 JavaScript 코드를 바이트코드로 컴파일한다.
    2. Codegen을 사용하여 빌드 시간에 네이티브 코드를 함께 생성한다.
       이렇게 생성된 "네이티브 코드"는 브리지를 사용하지 않고 "타입이 지정된 JavaScript 코드"와 직접 통신할 수 있다. 
       결과적으로 Codegen은 브리지를 사용하지 않기 때문에 JavaScript와 네이티브 코드 간의 통신을 더 빠르고 안정적으로 만든다.
    3. 바이트코드와 네이티브 코드가 기기에 설치할 수 있는 앱 패키지에 포함된다.
- Codegen은 앱 빌드 시간에만 작동하며 앱 실행 시간에는 작동하지 않는다.

- 사용자가 앱을 실행하면 React Native 앱의 아키텍처 흐름에서 Turbo Module, Fabric 두 가지 주요 컴포넌트가 작동한다. 새로운 아키텍처의 이 두 가지 주요 컴포넌트 모두 Codegen이 생성해야 하는 네이티브 코드가 필요하다. Codegen이 네이티브 코드를 생성하는 방법을 이해해 보자:

### Hermes Engine

- Hermes는 사용자가 기기에서 앱을 실행할 때 작동하는 JavaScript 엔진이다. Hermes는 다음과 같은 이점이 있다:
    - 앱 크기를 개선한다
    - 메모리 사용량을 개선한다
    - 앱의 시작 시간을 개선한다
- Hermes는 아래와 같은 이유 때문에 우수한 성능을 가진다. [(참고)](https://reactnative.dev/blog/2022/07/08/hermes-as-the-default)
  - 사전 컴파일: Hermes는 시작하기 전에 앱 소스 코드를 바이트코드로 사전 컴파일한다.
  - 더 빠른 TTI: Hermes는 TTI를 줄여 부드러운 사용자 경험을 제공한다.
  - 더 작은 앱 번들 크기: Hermes로 컴파일된 애플리케이션의 크기는 다른 JavaScript 엔진으로 빌드된 것보다 작다.
- 사용자가 기기에서 앱을 실행할 때 Hermes가 동작하는 흐름은 다음과 같다.
  1. 개발자가 프로덕션 배포 전에 React Native 프로젝트의 "바이트코드"를 빌드한다. 
  2. 그런 다음 사용자가 기기에서 앱을 실행하면 Hermes가 앱의 JavaScript 코드와 "네이티브 코드"(Codegen이 생성한 "네이티브 코드")가 포함된 "바이트코드" 파일을 로드한다.
  3. Hermes는 API에서 데이터를 가져오거나, 상태를 업데이트하거나, 사용자 입력에 응답하는 등 앱의 로직, 데이터, 이벤트를 처리한다.
  4. JavaScript Interface(JSI)라는 기능을 사용하여 Hermes가 앱의 "네이티브 코드"와 통신한다. JSI를 통해 Hermes는 브리지를 사용하지 않고 네이티브 함수와 객체에 직접 접근할 수 있다.

### Turbo Modules

- Turbo Modules는 구 네이티브 모듈 시스템을 대체한 새로운 네이티브 모듈 시스템이다. 이전의 네이티브 모듈 시스템은 성능이 느린 JSON 데이터 직렬화 기술을 사용했다. 이를 개선한 새로운 네이티브 모듈 시스템을 "Turbo Module"이라고 하며, JSON 데이터 직렬화 대신 JSI 기술을 사용한다. JSI(JavaScript Interface)는 C++로 작성되었다.

- Turbo Module은 React Native에서 "네이티브 모듈"을 구현하는 새로운 방식이다. JSI와 Codegen이 생성한 "네이티브 코드"를 사용하여 네이티브 모듈을 구현한다. Turbo Module은 사용자가 앱을 실행할 때 네이티브 모듈(예: 블루투스, 지리적 위치, 파일 저장소)을 로드하기 위한 지연 로딩을 도입했다. 구 아키텍처에서는 사용자가 이러한 모듈 중 하나를 필요로 하지 않더라도 앱에서 사용되는 모든 네이티브 모듈을 시작 시 초기화해야 했다.

- Turbo Modules는 JavaScript 코드가 이러한 네이티브 모듈에 대한 참조를 보유할 수 있게 한다. 결과적으로 특정 네이티브 모듈은 필요한 경우에만 로드되기 때문에, 앱 시작 시간이 더 빨라진다.

### Fabric

- Fabric은 기기에서 UI를 렌더링하는 역할을 담당하는 UI Manager이다.
- Facric을 사용하면 브리지를 통해 JavaScript와 통신하는 대신, Fabric이 JavaScript를 통해 함수를 노출하여 JS 측과 네이티브 측(반대의 경우도 마찬가지)이 참조 함수를 통해 직접 통신할 수 있다. user interaction을 메인스레드/네이티브 스레드에서 동기적으로 처리하기 때문에 양측 간의 데이터 전달 성능이 좋아진다.

- Fabric은 JSI를 사용하여 Hermes 및 네이티브 코드와 통신하기 때문에 브릿지를 사용하지 않는다. Fabric은 React Native를 위한 새로운 렌더링 시스템으로, 프레임워크와 호스트 플랫폼(네이티브 측의 플랫폼. 예: Android 또는 iOS) 간의 상호 운용성을 개선하고, JavaScript와 네이티브 스레드 간의 통신을 개선한다.


---
참고
- https://mycodings.fly.dev/blog/2022-11-29-react-native-new-architecture-jsi-javascript-interface
- https://github.com/reactwg/react-native-new-architecture/blob/main/docs/codegen.md
- https://blog.notesnook.com/getting-started-react-native-jsi
- https://engineering.teknasyon.com/deep-dive-into-react-native-jsi-5fbad4ea8f06?gi=11d86b26453d
- https://medium.com/@anisurrahmanbup/react-native-new-architecture-in-depth-hermes-jsi-fabric-fabric-renderer-yoga-turbo-module-1284a192a82b
- https://github.com/anisurrahman072/React-Native-Advanced-Guide/blob/master/New-Architecture/New-Architecture-in-depth.md
