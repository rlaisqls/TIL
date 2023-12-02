# Thread의 상태

JVM은 쓰레드를 New, Runnable, Running, Wating, Terminate의 다섯가지 상태로 관리한다. 쓰레드의 상태는 `getState()` 메서드 호출로 반환받을 수 있다.

![image](https://user-images.githubusercontent.com/81006587/216767536-7644d9f4-d6b9-417c-83de-d26c5a227c56.png)

#### New

객체를 생성한 뒤, 아직 start() 메서드 호출되기 전의 상태이다.

### Runnable

start() 메서드를 호출하여 동작시킨 쓰레드 객체는 JVM의 쓰레드 스케줄링 대상이 되며 Runnable 상태에 돌입하게 된다. 한 번 Runnable 상태에 돌입한 쓰레드는 다시 New 상태가 될 수 없다.

#### Running

Runnable 상태의 쓰레드는 큐에 대기하게 되는데, JVM은 각 쓰레드의 우선순위에 따라서 Running 상태로 만들어 쓰레드를 동작시킨다.

쓰레드 스케줄러에 의해 Running 상태로 이동하게된 쓰레드는 재정의된 run() 메소드가 호출된다.

run() 메소드가 호출되면 실제 동작이 수행되며, 그 결과에 따라 Waiting 또는 Terminate 상태로 바뀌게 된다.

### Waiting

쓰레드의 수행 중 I/O 블로킹이나 sleep(), join() 메서드에 의해 대기해야하는 경우 Waiting Pool 로 이동하게 된다.

Waiting Pool 내의 쓰레드는 해당 I/O의 수행을 마치거나, sleep(), join() 등의 대기 조건이 끝나거나 혹은 인터럽트가 발생되게 되면 다시 Runnable 큐로 이동한다.

### Terminate

run()메소드의 수행이 끝나면 Terminate 상태가 되며 쓰레드가 종료된다. 한번 Terminate 된 쓰레드 객체는 start() 메서드를 호출해도 스레드 스케쥴링에 포함시킬 수 없다.