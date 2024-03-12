
`java.net`의 Socket class와 Thread를 이용해 간단한 socket 통신 프로그램을 만들어보자.

## socket client

```java
public class ServerMain {

    public static void main(String[] args) {

        // ServerSocket 클래스로 객체를 생성해준다. port는 6000으로 설정해주었다.
        try (ServerSocket ss = new ServerSocket(6000)) {

            // accept() 는 클라이언트가 들어오는 것을 대기 하는 역할을 한다.
            // 클라이언트가 설정해준 포트(6000)로 연결을 시도한다면 accept 메소드는 대기를 풀고, 클라이언트와 연결시키는 Socket 클래스를 생성하여 반환한다.
            Socket sc = ss.accept();

            // input과 output 작업을 수행할 스레드를 별도로 정의하여 실행시킨다.
            Thread inputThread = new InputThread(sc);
            Thread outputThread = new OutputThread(sc);

            inputThread.start();
            outputThread.start();

        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
```

```java
public class ClientMain {

    public static void main(String[] args) {

        try {

            // Socket 객체를 생성하여 연결을 시도한다.
            // 연결할 IP 주소와 Port 번호를 매개변수로 넘겨 주어서, 해당 주소로 연결을 시도하게 한다.
            Socket sc = new Socket("127.0.0.1", 6000);

            // 연결이 완료 되었다면 여기에서도 마찬가지로 input과 output 작업을 수행할 스레드를 별도로 정의하여 실행시킨다
            Thread inputThread = new InputThread(sc);
            Thread outputThread = new OutputThread(sc);

            inputThread.start();
            outputThread.start();

        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
```

## Input / Output Thread

```java
public class OutputThread extends Thread {

    private final Socket sc;
    private final Scanner scanner;

    public OutputThread(Socket sc) {
        this.sc = sc;
        this.scanner = new Scanner(System.in);
    }

    @Override
    public void run() {
        try {
            OutputStream os = sc.getOutputStream();
            PrintWriter pw = new PrintWriter(os, true);
            while (true) {
                // Scanner로 들어온 값을 읽어서 PrintWriter로 출력한다.
                pw.println(scanner.nextLine());
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        } finally {
            this.scanner.close();
        }
    }
}
```

```java
public class InputThread extends Thread {

    private final Socket sc;

    public InputThread(Socket sc) {
        this.sc = sc;
    }

    @Override
    public void run() {
        try {
            InputStream is = sc.getInputStream();
            BufferedReader br = new BufferedReader(new InputStreamReader(is));
            while (true) {
                // InputStream을 BufferedReader로 읽어서 출력한다.
                System.out.println(br.readLine());
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
```

## 결과

Server나 Client 중 한 쪽에서 메시지를 입력하면 서로 잘 전송되는 것을 볼 수 있다.

<img width="423" alt="image" src="https://user-images.githubusercontent.com/81006587/233892297-59da0153-d3fe-4ab5-985c-d6a329f453a9.png">
<img width="375" alt="image" src="https://user-images.githubusercontent.com/81006587/233892339-1d23c64f-2dd3-4475-a3be-31859465871d.png">
