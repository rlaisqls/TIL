# Cipher

> https://www.baeldung.com/java-cipher-class

Simply put, encryption is the process of **encoding a message** such that only authorized users can understand or access it.

The message, referred to as plaintext, is encrypted using an encryption algorithm – a cipher – generating ciphertext that can only be read by authorized users via decryption.

In this article, we describe in detail the core Cipher class, which provides cryptographic encryption and decryption functionality in Java.

## Cipher Class

**Java Cryptography Extension(JCE)** is the part of the Java Cryptography Architecture(JCA) that provides an application with cryptographic ciphers for data encryption and decryption as well as hashing of private data.

The `javax.crypto.Cipher` class forms the core of the JCE framework, providing the functionality for encryption and decryption.

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

## Cipher Instatntiation

To instantiate a Cipher object, we call the static getInstance method, passing the name of the requested transformation. Optionally, the name of a provider may be specified.

Let's write an example class illustrating the instantiation of a Cipher:

```java
public class Encryptor {

    public byte[] encryptMessage(byte[] message, byte[] keyBytes) 
      throws InvalidKeyException, NoSuchPaddingException, NoSuchAlgorithmException {
        Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
        //...
    }
}
```

The transformation AES/ECB/PKCS5Padding tells the getInstance method to instantiate the Cipher object as an AES cipher with ECB mode of operation and PKCS5 padding scheme.

We can also instantiate the Cipher object by specifying only the algorithm in the transformation:

```java
Cipher cipher = Cipher.getInstance("AES");
```

In this case, Java will use provider-specific default values for the mode and padding scheme.

Note that getInstance will throw a NoSuchAlgorithmException if the transformation is null, empty, or in an invalid format, or if the provider doesn't support it. Also it will throw a NoSuchPaddingException if the transformation contains an unsupported padding scheme.


## Thread-Safety

The Cipher class is a stateful one without any form of internal synchronization. As a matter of fact, methods like `init()` or `update()` will change the internal state of a particular Cipher instance.

Therefore, the Cipher class is not thread-safe. So we should create one Cipher instance per encryption/decryption need.

> reference: https://www.baeldung.com/java-cipher-class

## Keys

The Key interface represents keys for cryptographic operations. Keys are opaque containers that hold an encoded key, the key's encoding format, and its cryptographic algorithm.

Keys are generally obtained through key generators, certificates, or key specifications using a key factory.

Let's create a symmetric Key from the supplied key bytes:

```java
SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");
```

## Cipher Initialization

We call the `init()` method to **initialize the Cipher object with a Key** or **Certificate and an `opmode` indicating the operation mode of the cipher.**

Optionally, we can pass in a source of randomness. By default, a SecureRandom implementation of the highest-priority installed provider is used. Otherwise, it'll use a `system-provided` source. We can specify a set of algorithm-specific parameters optionally. For example, we can pass an `IvParameterSpec` to specify an initialization vector.

Here are the available cipher operation modes:

- **ENCRYPT_MODE:** initialize cipher object to encryption mode
- **DECRYPT_MODE:** initialize cipher object to decryption mode
- **WRAP_MODE:** initialize cipher object to key-wrapping mode
- **UNWRAP_MODE:** initialize cipher object to key-unwrapping mode

Let's initialize the Cipher object:

```java
Cipher cipher = Cipher.getInstance("AES/ECB/PKCS5Padding");
SecretKey secretKey = new SecretKeySpec(keyBytes, "AES");
cipher.init(Cipher.ENCRYPT_MODE, secretKey);
// ...
```

Now, the init method throws an InvalidKeyException if the supplied key is inappropriate for initializing the cipher, like when a key length/encoding is invalid.

It's also thrown when <u>the cipher requires certain algorithm parameters that cannot be determined from the key</u>, or <u>if the key has a key size that exceeds the maximum allowable key size</u> (determined from the configured JCE jurisdiction policy files).

Let's look at an example using a Certificate:

```java
public byte[] encryptMessage(byte[] message, Certificate certificate) 
  throws InvalidKeyException, NoSuchPaddingException, NoSuchAlgorithmException {
 
    Cipher cipher = Cipher.getInstance("RSA/ECB/PKCS1Padding");
    cipher.init(Cipher.ENCRYPT_MODE, certificate);
    // ...
}
```

The Cipher object gets the public key for data encryption from the certificate by calling the getPublicKey method.

## Encryption and Decryption

After initializing the Cipher object, we call the `doFinal()` method to perform the encryption or decryption operation. This method returns a byte array containing the encrypted or decrypted message.

The `doFinal()` method also resets the Cipher object to the state it was in when previously initialized via a call to `init()` method, making the Cipher object available to encrypt or decrypt additional messages.

Let's call doFinal in our encryptMessage method:

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

To perform a decrypt operation, we change the opmode to DECRYPT_MODE:

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

## exmaple code

In this test, we use AES encryption algorithm with a 128-bit key and assert that the decrypted result is equal to the original message text:

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

## Conclusion

In this article, we discussed the Cipher class and presented usage examples. More details on the Cipher class and the JCE Framework can be found in the [class documentation](https://docs.oracle.com/en/java/javase/11/docs/api/java.base/javax/crypto/Cipher.html) and the [Java Cryptography Architecture (JCA) Reference Guide](https://docs.oracle.com/javase/9/security/java-cryptography-architecture-jca-reference-guide.htm)

Implementation of all these examples and code snippets can be found over on GitHub. This is a Maven-based project, so it should be easy to import and run as it is.

