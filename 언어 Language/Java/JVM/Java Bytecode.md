
Java는 **JVM** 이라는 가상머신을 거쳐서 OS에 도달하기 때문에 OS가 인식할 수 있는 기계어로 바로 컴파일 되는게 아니라 JVM이 인식할 수 있는 Java bytecode(`*.class`)로 먼저 변환된다.

`.java` 파일을 `.class` 라는 Java bytecode로 변환하는 것은 Java compiler의 역할이다.

## (바이트코드로) 직접 컴파일 하는방법

아래는 Java Compiler에 의해 'java' 파일을 '.class' 라는 Java bytecode로 만드는 과정이다.

Java Compiler는 JDK를 설치하면 `javac.exe`라는 실행 파일 형태로 설치된다. 정확히는 JDK의 bin 폴더에 'javac.exe'로 존재한다.

Java Complier 의 `javac` 라는 명령어를 사용하면 .class 파일을 생성할 수 있다.

```java
public class test {
    public static void main(String[] args) {
        System.out.println("Hello World");
    }
}
```

`"Hello World"`를 출력하는 .java 파일을 생성하고 이를 .class 파일로 변환시켜보자.

```bash
C:\Users\owner>cd Desktop
```

Windows를 기준으로, cmd 창을 열고 해당 .java 파일이 있는 곳으로 이동한다.

```bash
C:\Users\owner\Desktop>javac test.java
```

해당 위치에서 javac 명령어로 컴파일을 진행한다. 그렇기 하면 현재 위치(바탕화면)에 .class 파일이 생성된 걸 확인할 수 있다.


```bash
C:\Users\owner\Desktop>java test
```

위 명령어를 입력하면 java.exe를 통해 JVM이 구동되어 결과가 나오는 것을 볼 수 있다!