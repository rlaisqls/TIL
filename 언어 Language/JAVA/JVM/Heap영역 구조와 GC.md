# ☕ Heap영역 구조 및 GC.md

<a href="https://github.com/rlaisqls/TIL/blob/main/%EC%96%B8%EC%96%B4%E2%80%85Language/JAVA/JVM/Runtime%E2%80%85Data%E2%80%85Area.md">여기</a>에선, JVM이 사용하는 런타임 데이터 영역이 어떻게 나뉘어지는지에 대해 알아봤다. 런타임 데이터 영역은 크게 Method영역, Heap영역, Stack영역 등등으로 나뉘어있는데, 런타임중 가장 많은 메모리가 새로 할당되는 영역이 Heap영역이기 때문에, GC 또한 Heap영역을 위주로 실행된다.

이때, Heap 영역은 GC와 메모리 관리를 위해 저장되어있는 데이터를 내부에서 여러 유형으로 분류하여 저장한다.

<img height=250px src="https://user-images.githubusercontent.com/81006587/209074379-f2412b8f-7cc4-4516-842d-e711029305db.png">

Heap영역은 크게 3가지의 영역으로 나뉜다.

### Young Generation 영역

자바 객체가 생성되자마자 저장되는 영역이다. 이름 그대로 생긴지 얼마 안되는 어린 객체들이 속하는 곳이다. 

Heap 영역에 객체가 생성되면 그 즉시 Young Generation 중에서도 Eden 영역에 할당되고, 이 영역에 데이터가 어느정도 쌓이게 되면 참조정도에 따라 Servivor의 빈 공간으로 이동되거나 회수된다.

━━> 각 영역이 채워지면, <u>참조가 남아있는 객체들이 비워진 Survivor(s0, s1)로 이동</u>한다. <br>
  - s0이 채워져있다면 s1으로, s1이 채워져있다면 s0로 이동하는 것이다. (따라서 s0과 s1중 한 곳은 항상 비어있다)<br>
  - 그리고 참조가 없는 객체들은 `Minor GC`를 통해 수집되어 삭제된다.

### Old Generation(Tenured) 영역

Young Generation(Eden+Servivor) 영역이 차게 되면 또 참조정도에 따라 Old영역으로 이동하거나 회수된다.

이 Old 영역에도 공간이 모자라면 모든 스레드를 멈추고(이걸 `Stop-The-World`라고 부른다.) 긴 시간동안 **Major GC**를 수행하는데, 그 시간동안은 애플리케이션을 구동시킬 수 없기 때문에 처리가 지연된다. 성능 향상을 위해선 이 Major GC가 자주 일어나지 않도록, 메모리 관리를 잘 해야한다.

### Permanent 영역

Permanent 영역(PermGen)은, 보통 Class의 Meta 정보나 Method의 Meta 정보, Static 변수와 상수 정보들을 저장하는 영역으로,(Method 영역을 포함한 개념), heap 영역에 포함되어 있기는 하나 heap 영역과는 다른 개념으로 간주되었다.

![image](https://user-images.githubusercontent.com/81006587/209075255-602ec07e-906d-4576-8297-0fe4c3f89ab6.png)

(Permanent는 Heap영역 안에 있긴 하지만, Non-Heap으로 취급되는 영역, Method 영역을 포함하고있음 <a href="https://stackoverflow.com/questions/9095748/method-area-and-permgen#comment40650163_9095799">참고</a>)

그래서 이 Permanent 영역을 Heap이라고 해야하는지, 아닌지 애매하여 많이 혼동되었다.

하지만 JAVA 8부터는 Permanent라는 개념이 사라지고 완전히 Non-Heap인 Metaspace라는 영역이 생겼다!

Permanent 영역은 JVM에 의해 크기가  제한되어있는 영역이었는데, 그로 인해 큰 애플리케이션을 돌리는 경우 OS에 여유공간이 있더라도 메모리가 초과되어 사용할 수 없는 문제가 있었다. 그를 해결하기 위해 JAVA에는 JVM에 의해 메모리가 제한되지 않는 `Native Memory 영역`에 **Metaspace**라는 영역을 만들어 대체하여 사용하도록 하였고, 이젠 OS에 의해 메모리 할당 공간이 자동으로 조절되므로 이론상 아키텍쳐가 지원하는 메모리 크기까지 확장할 수 있다.

Metaspace가 Permanent의 어떤 역할을 대체하고있고, 그로 인해 어떤 변화가 생겼는지는 여기에서 더 알아보자.

---

참고

https://stackoverflow.com/questions/9095748/method-area-and-permgen<br>
https://stackoverflow.com/questions/1262328/how-is-the-java-memory-pool-divided<br>
https://jaemunbro.medium.com/java-metaspace%EC%97%90-%EB%8C%80%ED%95%B4-%EC%95%8C%EC%95%84%EB%B3%B4%EC%9E%90-ac363816d35e<br>
https://8iggy.tistory.com/229<br>
https://javapapers.com/core-java/java-jvm-memory-types/