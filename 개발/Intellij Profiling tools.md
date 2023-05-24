# Intellij Profiling tools

IntelliJ IDEA Ultimate를 사용하고 있다면 **Profiling tools**을 사용하여 애플리케이션에 대한 부가적인 분석 정보를 얻을 수 있다. 세부 기능으로는 애플리케이션의 실행 방식과 메모리, CPU 리소스가 할당되는 방식에 대한 분석을 제공하는 Async Profiler, 애플리케이션이 실행되는 동안 JVM에서 발생한 이벤트에 대한 정보를 수집하는 모니터링 도구인 Java Flight Recorder 등이 있다.

또한 애플리케이션의 특정 시점의 스냅샷으로 메모리를 분석하거나(Analyze memory snapshots) 애플리케이션이 실행되는 도중에도 CPU와 메모리 현황을 실시간으로 확인할 수 있는 기능(CPU and memory live charts)들이 있다.

## 기능

### Profiling Application

Async Profiler, Java Flight Recorder 기능 등을 통해서 애플리케이션을 분석할 수 있다. CPU와 메모리를 많이 쓸수록 더 넓은 직사각형으로 표현하여 애플리케이션의 호출 트리(call tree)를 시각화하는 플레임 그래프(Flame Graph), 프로그램의 호출 스택에 대한 정보를 나타내는 호출 트리(Call Tree) 그리고 메소드의 호출을 추적하거나 특정 메서드에서 호출된 모든 메서드를 확인할 수 있는 메서드 리스트(Method List) 등의 기능을 제공한다. 

## CPU and memory live charts

실행 중인 애플리케이션 리소스 상태를 아래와 같이 차트 형태로 실시간 확인할 수 있다. 옵션을 통해서 데이터 확인 기간도 모든 데이터, 최근 5분 등으로 범위를 변경할 수 있다.

![image](https://github.com/artilleryio/artillery-core/assets/81006587/3de30f4a-9df0-428d-b6c3-c1f7e32aa127)

## Analyze memory snapshots

메모리 스냅샷 기능을 통해서 힙(heap) 메모리를 사용하는 코드를 분석하고 메모리 누수를 찾는 등 애플리케이션의 성능 문제를 분석할 수도 있다. 위에서 살펴본 라이브 차트에서 “Capture Memory Snapshot” 기능을 사용하면, 해당 시점의 메모리를 덤프하여 스냅샷으로 캡처할 수 있다.

![image](https://github.com/artilleryio/artillery-core/assets/81006587/499993b4-42e1-46a0-86b8-d752767174c7)

캡처가 완료되면 아래와 같이 여러 정보를 분석할 수 있다. 왼쪽 프레임에서는 메모리에 할당된 각 클래스의 정보를 확인할 수 있는데 각 항목은 다음과 같다.

- Class: 애플리케이션의 클래스 목록
- Count: 각 클래스의 사용 횟수
- Shallow: 객체 자체가 저장되기 위해 할당되는 메모리 크기인 Shallow size 표기
- Retained: 객체들의 shallow size와 해당 객체에서 직간접적으로 접근 가능한 객체들의 shallow size 합인 Retained size 표기
오른쪽 프레임에서는 다음과 같은 탭을 확인할 수 있다.

- Biggest Objects: 리소스를 가장 많이 차지하는 객체를 순서대로 나열
- GC Roots: 클래스 별로 그룹핑된 가비지 수집기 루트 객체와 Shallow Size, Retained Size 표기
- Merged Paths: 클래스 별로 그룹핑된 인스턴스의 개수 등을 확인
- Summary: 인스턴스 개수, 스택 트레이스(stack traces) 등과 같이 일반적인 정보 표기
- Packages: 모든 객체를 패키지별로 표기

---
참고
- https://www.jetbrains.com/help/idea/profiler-intro.html