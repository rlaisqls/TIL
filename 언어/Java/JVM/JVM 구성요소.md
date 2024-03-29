
<img src="https://user-images.githubusercontent.com/81006587/208055622-f52c1340-dfc4-4dfa-9d9b-fd347c27a215.png" height=400px>

JVM 구성요소는 아래와 같은 것들이 있다.

- 클래스 로더(Class Loader)
- 실행 엔진(Execution Engine)
    - 인터프리터(Interpreter)
    - JIT 컴파일러(Just-in-Time)
    - 가비지 콜렉터(Garbage collector)
- 런타임 데이터 영역 (Runtime Data Area)

각각에 대해서 자세히 알아보자.

## 클래스 로더

JVM 내로 클래스 파일(`*.class`)을 로드하고, 링크를 통해 배치하는 작업을 수행하는 모듈이다. 런타임시 동적으로 클래스를 로드하고 jar 파일 내에 저장된 클래스들을 JVM 위에 탑재한다.
즉, **클래스를 처음으로 참조할 때, 해당 클래스를 로드하고 링크**하는 역할을 한다.

## 실행 엔진

클래스 로더가 JVM내의 런타임 데이터 영역에 바이트 코드를 배치시키면, 실행엔진은 **그것을 실행한다.**

자바 바이트 코드(*.class)는 기계가 바로 수행할 수 있는 언어보다는 비교적 인간이 보기 편한 형태로 기술된 것인데, 실행 엔진은 이와 같은 <u>바이트 코드를 실제로 JVM 내부에서 기계가 실행할 수 있는 형태로 변경</u>한다.

- 인터프리터
    자바 바이트 코드를 명령어 단위로 읽어서 실행한다.<br>
    하지만 한 줄씩 수행하기 때문에 느리다는 단점이 있다.

- JIT(Just-In-Time)
    인터프리터 방식으로 실행하다가 적절한 시점에 바이트 코드 전체를 컴파일하여 기계어로 변경하고, 이후에는 해당 더 이상 인터프리팅 하지 않고 기계어로 직접 실행하는 방식이다

- 가비지 콜렉터(GC)
    더이상 사용되지 않는 인스턴스를 찾아 메모리에서 삭제한다. 자세한 내용은 <a href="./Heap영역 구조와 GC.md">여기</a>에서 더 다룬다.


## 런타임 데이터 영역

JVM이 프로그램을 수행하기 위해 OS에서 할당받은 메모리 공간이다. 자세한 내용은 <a href="./Runtime Data Area.md">여기</a>에서 더 다룬다.

 
