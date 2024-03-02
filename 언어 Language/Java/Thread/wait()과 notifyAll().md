
`wait()`과 `notifyAll()`을 사용하면 스레드의 순서를 제어할 수 있다.

![image](https://user-images.githubusercontent.com/81006587/234431001-e64a2240-ffcd-4363-bee0-dab7e8c0d4a5.png)


간단하게 말하자면 wait은 스레드를 대기하게 만들고, notifyAll(또는 notify)는 대기중인 스레드를 꺠워주는 역할을 하는데, 자세한 것은 예시 코드를 보며 이해해보자.

```java
package voting;

public class VotingPlace {
    private String voter1;
    private String voter2;
    private boolean isEmptyPlace1;
    private boolean isEmptyPlace2;

    public VotingPlace() {
        this.isEmptyPlace1 = true;
        this.isEmptyPlace2 = true;
    }

    public synchronized void vote (String voter) throws InterruptedException {
        while ( (isEmptyPlace1 == false) && (isEmptyPlace2 == false)) wait(); // 두 방이 모두 꽉차있다면 기다린다.
        // 두 방중 하나 이상이 비어있으면 탈출한다.

        if (isEmptyPlace1) { // 첫번쨰 방이 비어있으면 첫번쨰 방으로 들어가고
            voter1 = voter;
            isEmptyPlace1 = false;
            System.out.println("투표소1 : " + voter1 + "님이 투표중 입니다.");
        } else if (isEmptyPlace2) { // 두번쨰 방이 비어있으면 두번쨰 방으로 들어간다.
            voter2 = voter;
            isEmptyPlace2 = false;
            System.out.println("투표소2 : " + voter2 + "님이 투표중 입니다.");
        }
    }

    public synchronized void voteDone(String voter) {
        // 방에서 나온다.
        if (voter.equals(voter1)) { 
            voter1 = null;
            isEmptyPlace1 = true;
            System.out.println("투표소1 : " + voter + "투표 완료. 현재 비어있음");
        } else if (voter.equals(voter2)) {
            voter2 = null;
            isEmptyPlace2 = true;
            System.out.println("투표소2 : " + voter + "투표 완료. 현재 비어있음");
        }

        // 대기중인 스레드를 깨운다.
        notifyAll();
    }
}
```

여기서 가장 중요한건 `wait()`과 `notifyAll()` 메서드 모두 synchronized 처리되어 있는 메서드 내부에서 호출되어야한다는 것이다.

그리고 `notify()`라는 메서드도 있는데, notifyAll() 은 잠자고 있는 모든 스레드를 깨우고 notify()는 하나의 스레드만 깨운다. 여기서는 둘중 어느것을 써도 결과는 똑같다.

```java
public class VoteThread implements Runnable {
    VotingPlace votingPlace;
    String voter;

    public VoteThread(VotingPlace votingPlace, String voter) {
        this.votingPlace = votingPlace;
        this.voter = voter;
    }

    @Override
    public void run() {
        try {
            votingPlace.vote(voter);
            Thread.sleep(3000);
            votingPlace.voteDone(voter);
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }
}
```

아래 코드를 보면 투표소가 두개 있고, 해당 투표소에서 투표를 하는 사람은 모두 10명이다.

```java
public class Vote {
    public static void main (String[] args) {
        VotingPlace votingPlace = new VotingPlace();
        for(int i=1; i<= 10; i++) {
            Thread thread = new Thread(new VoteThread(votingPlace, "투표자"+i));
            thread.start();
        }
    }
}
```

여기서 투표소가 빈 곳이 하나도 없으면 기다리다가 하나라도 비었다고 알려주면 대기하던 사람 하나가 해당 투표소에서 투표를 할 수 있게 된다ㅏ.