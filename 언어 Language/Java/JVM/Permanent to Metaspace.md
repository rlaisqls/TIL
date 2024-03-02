
JAVA8에서부터, Permanent가 사라지고 Metaspace가 생김으로써 그 역할을 일부 대체하게 되었다.

Permanent는 JVM에 의해 크기가 강제되었지만, Metaspace는 OS가 자동으로 크기를 조절할 수 있는 Native memory 영역이기 때문에 기존과 비교해 큰 메모리 영역을 사용할 수 있게 되었다.

Perm 영역에는 주로 클래스, 메소드 정보와 클래스 변수의 정보, static 변수와 상수 정보들이 저장되었는데, 이게 **Metaspace로 대체**되면서 <u>Perm에 있었던 대부분의 정보가 Metaspace에 저장</u>되도록 바뀌었다. 

다만, 기존 Perm 영역에 존재하던 **static Object**는 Heap 영역으로 옮겨져서 최대한 GC의 대상이 될 수 있도록 하였다고 한다.

> The proposed implementation will allocate class meta-data in native memory and move interned Strings and class statics to the Java heap. Hotspot(JVM) will explicitly allocate and free the native memory for the class meta-data.

또한, 메모리 옵션을 설정하는 명령어도 명칭이 바뀌었다. 표로 정리하자면 아래와 같다.

|Java 7 (Permanent)|Java 8 (Metaspace)|
|-|-|
|Class 메타 데이터|저장|저장|
|Method 메타 데이터|저장|저장|
|Static Object 변수,상수|저장|Heap 영역으로 이동|
|메모리 옵션|-XX:PermSize<br>-XX:MaxPermSize|-XX:MetaspaceSize<br>-XX:MaxMetaspaceSize|

그림으로 구조를 표현하자면 아래와 같다.

- JAVA7의 JVM
```js
<----- Java Heap -----------------> <--- Native Memory --->
+------+----+----+-----+-----------+--------+--------------+
| Eden | S0 | S1 | Old | Permanent | C Heap | Thread Stack |
+------+----+----+-----+-----------+--------+--------------+
                        <--------->
                       Permanent Heap
S0: Survivor 0
S1: Survivor 1
```

- JAVA8의 JVM
```js
<----- Java Heap -----> <--------- Native Memory --------->
+------+----+----+-----+-----------+--------+--------------+
| Eden | S0 | S1 | Old | Metaspace | C Heap | Thread Stack |
+------+----+----+-----+-----------+--------+--------------+

```

### Static Object가 GC된다고?

static Object를 Heap 영역으로 옮겨서 최대한 GC의 대상이 될 수 있다는건 뭔가 좀 이상하다.

static 변수는 클래스 변수로, 명시적 null 선언이 되지 않은 경우엔 <u>GC되어서는 안되는 변수</u>이기 때문이다.

하지만 여기서 GC 한다는 것은 static 변수에 대한 참조를 삭제한다는 것이 아니라, 그 내용물을 지우겠다는 뜻이다. static Object를 GC하더라도, 그 객체나 변수에 대한 reference는 여전히 metaspace에 남아있도록 되어있기 때문에 상관이 없다.

static object가 참조를 잃은 경우에 GC의 대상이 될 수 있으나, static object에 대한 참조가 살아있다면 GC의 대상이 되지 않음을 의미한다.

다시말해, static Object가 Heap 영역으로 옮겨진다고 하더라도 metaspace는 여전히 static object에 대한 reference를 보관하고 있는 것이고, static 변수(primitive type, interned string)는 heap 영역으로 옮겨짐에 따라 GC의 대상이 될 수 있게끔 조치한 것이다.

이는 클래스 변수 및 객체의 저장위치와 클래스 메타 정보의 위치가 **Method 영역이 속한 ParmGen으로부터 Heap과 메모리로 서로 분리되었다**는 점을 의미한다.

---

참고
https://openjdk.java.net/jeps/122
http://mail.openjdk.java.net/pipermail/hotspot-dev/2012-September/006679.html
https://blogs.oracle.com/poonam/about-g1-garbage-collector%2c-permanent-generation-and-metaspace