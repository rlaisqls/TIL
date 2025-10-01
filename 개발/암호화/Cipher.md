
암호화는 메시지를 인코딩하여 인가된 사용자만 이해하거나 접근할 수 있도록 하는 프로세스임.

평문(plaintext)이라고 하는 메시지를 암호화 알고리즘(cipher)을 사용하여 암호화하면, 인가된 사용자만 복호화를 통해 읽을 수 있는 암호문(ciphertext)이 생성됨.

## Cipher

- JCE(Java Cryptography Extension)는 JCA(Java Cryptography Architecture)의 일부로, 애플리케이션에 데이터 암호화/복호화 및 개인 데이터 해싱을 위한 암호화 cipher 제공
- `javax.crypto.Cipher` 클래스는 JCE 프레임워크의 핵심으로, 암호화 및 복호화 기능 제공

```java
public class Cipher {
    private static final Debug debug =
                        Debug.getInstance("jca", "Cipher");
    private static final Debug pdebug =
                        Debug.getInstance("provider", "Provider");
    private static final boolean skipDebug =
        Debug.isOn("engine=") && !Debug.isOn("cipher");

    /**
     * Constant used to initialize cipher to encryption mode.
     */
    public static final int ENCRYPT_MODE = 1;

    /**
     * Constant used to initialize cipher to decryption mode.
     */
    public static final int DECRYPT_MODE = 2;
    ...
}
```

- `getInstance` 메서드를 호출하고 요청된 변환(transformation) 이름 전달
- 선택적으로 공급자(provider) 이름 지정 가능

```java
public class Encryptor {
    public byte[] encryptMessage(byte[] message, byte[] keyBytes)
      throws InvalidKeyException, NoSuchPaddingException, NoSuchAlgorithmException {
        Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
        //...
    }
}
```

스레드 안전성

- Cipher 클래스는 내부 동기화 없이 상태를 가진 클래스
- `init()` 또는 `update()` 같은 메서드는 특정 Cipher 인스턴스의 내부 상태 변경
- 따라서 Cipher 클래스는 스레드 안전하지 않음
- 암호화/복호화 요구사항마다 하나의 Cipher 인스턴스 생성 필요

Keys

- Key 인터페이스는 암호화 작업을 위한 키를 나타냄
- 키는 인코딩된 키, 키의 인코딩 형식, 암호화 알고리즘을 보유하는 불투명 컨테이너
- 일반적으로 키 생성기, 인증서 또는 키 팩토리를 사용한 키 사양을 통해 얻음
- 제공된 키 바이트에서 대칭 키 생성:

```java
SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");
```

초기화

- `init()` 메서드를 호출하여 Key 또는 Certificate와 cipher의 동작 모드를 나타내는 `opmode`로 Cipher 객체 초기화
- 선택적으로 난수 소스 전달 가능
- 기본적으로 최고 우선순위 설치 공급자의 SecureRandom 구현 사용, 그렇지 않으면 시스템 제공 소스 사용
- 선택적으로 알고리즘별 매개변수 집합 지정 가능
- 예: `IvParameterSpec`을 전달하여 초기화 벡터 지정 가능

Cipher 동작 모드

- `ENCRYPT_MODE`: cipher 객체를 암호화 모드로 초기화
- `DECRYPT_MODE`: cipher 객체를 복호화 모드로 초기화
- `WRAP_MODE`: cipher 객체를 키 래핑 모드로 초기화
- `UNWRAP_MODE`: cipher 객체를 키 언래핑 모드로 초기화

```java
Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");
cipher.init(Cipher.ENCRYPT_MODE, secretKey);
// ...
```

- `init` 메서드는 제공된 키가 cipher 초기화에 부적절하면 `InvalidKeyException` 발생 (키 길이/인코딩 잘못됨)
- cipher에 키에서 결정할 수 없는 특정 알고리즘 매개변수가 필요하거나, 키 크기가 최대 허용 키 크기를 초과하는 경우에도 발생 (JCE 관할권 정책 파일에서 결정)
- Certificate 사용 예

    ```java
    public byte[] encryptMessage(byte[] message, Certificate certificate)
                    throws InvalidKeyException, NoSuchPaddingException, NoSuchAlgorithmException {
                        Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding");
                        cipher.init(Cipher.ENCRYPT_MODE, certificate);
                        // ...
                    }
    ```

암호화 및 복호화

- Cipher 객체 초기화 후 `doFinal()` 메서드를 호출하여 암호화 또는 복호화 작업 수행
- 이 메서드는 암호화되거나 복호화된 메시지를 포함하는 바이트 배열 반환
- `doFinal()` 메서드는 Cipher 객체를 `init()` 메서드를 통해 이전에 초기화된 상태로 재설정
- Cipher 객체를 추가 메시지 암호화 또는 복호화에 사용 가능하게 함

```java
public byte[] encryptMessage(byte[] message, byte[] keyBytes)
  throws InvalidKeyException, NoSuchPaddingException, NoSuchAlgorithmException,
    BadPaddingException, IllegalBlockSizeException {
    Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
    SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");
    cipher.init(Cipher.ENCRYPT_MODE, secretKey);
    return cipher.doFinal(message);
}
```

- 복호화 작업을 수행하려면 opmode를 DECRYPT_MODE로 변경:

```java
public byte[] decryptMessage(byte[] encryptedMessage, byte[] keyBytes)
  throws NoSuchPaddingException, NoSuchAlgorithmException, InvalidKeyException,
    BadPaddingException, IllegalBlockSizeException {
    Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
    SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");
    cipher.init(Cipher.DECRYPT_MODE, secretKey);
    return cipher.doFinal(encryptedMessage);
}
```

### 예제 코드

128비트 키로 AES 암호화 알고리즘을 사용하고 복호화된 결과가 원본 메시지 텍스트와 같은지 확인하는 테스트

```java
@Test
public void whenIsEncryptedAndDecrypted_thenDecryptedEqualsOriginal()
  throws Exception {
    String encryptionKeyString =  "thisisa128bitkey";
    String originalMessage = "This is a secret message";
    byte[] encryptionKeyBytes = encryptionKeyString.getBytes();

    Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
    SecretKey secretKey = new SecretKeySpec(encryptionKeyBytes, "AES");
    cipher.init(Cipher.ENCRYPT_MODE, secretKey);

    byte[] encryptedMessageBytes = cipher.doFinal(message.getBytes());

    cipher.init(Cipher.DECRYPT_MODE, secretKey);

    byte[] decryptedMessageBytes = cipher.doFinal(encryptedMessageBytes);
    assertThat(originalMessage).isEqualTo(new String(decryptedMessageBytes));
}
```

---

참고:

- <https://www.baeldung.com/java-cipher-class>
- <https://docs.oracle.com/en/java/javase/11/docs/api/java.base/javax/crypto/Cipher.html>
- <https://docs.oracle.com/javase/9/security/java-cryptography-architecture-jca-reference-guide.htm>
