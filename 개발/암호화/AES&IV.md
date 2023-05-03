In AES, For The Same Plaintext, Will We Always Get Same Ciphertext (for the same IV and Key)?

You will perhaps know that in ECB (Electronic Code Book) mode in AES, you will always get the same ciphertext for the same key. As this is a block cipher, the padding will change the end characters, but as long as we have 16 bytes then the first block will be the same. But what about the modes that use an IV? Well, let’s look at a stream cipher mode: GCM, and see what happens when we use the same key and the same IV.

So we will create the following Golang cod.

In this case, we just convert a password into an encryption key, and then just set an IV to all zeros, along with the same salt used with the key generation. If we try “Testing 123” and a password of “qwerty123”, we get :

```yml
Message:	Testing 123
Cipher:		80f8087e75d6875d56198a082820fb3dc6c0ba7e4bac4f697094e2
Key:		2f7ffec39904ee5b61a73d881f6d2f36c27d2a60a42d828b52b6409dc13d1318
Nonce:		000000000000000000000000
Decrypted:	Testing 123
```

If we use the same encryption key and IV, and encrypt “Testing 1234”, we get :

```yml
Message:	Testing 1234
Cipher:		80f8087e75d6875d56198acf54928581167bca942c9baa407511d4f6
Key:		2f7ffec39904ee5b61a73d881f6d2f36c27d2a60a42d828b52b6409dc13d1318
Nonce:		000000000000000000000000
Decrypted:	Testing 1234
```

If we use the same encryption key and IV, and encrypt “Testing 12354”, we get :

```yml
Message:	Testing 12345
Cipher:		80f8087e75d6875d56198acfa267d902af38c544c7cfb088b51b8b7442
Key:		2f7ffec39904ee5b61a73d881f6d2f36c27d2a60a42d828b52b6409dc13d1318
Nonce:		000000000000000000000000
Decrypted:	Testing 12345
```

And so we see “The following is the Golang code :

```go
package main
import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/sha256"
	"fmt"
	"os"
	"golang.org/x/crypto/pbkdf2"
)

func main() {
	passwd := "qwerty"
	nonce := []byte{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	salt := []byte{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
	pt := ""
	argCount := len(os.Args[1:])
	
	if argCount > 0 {
		pt = (os.Args[1])
	}

	key := pbkdf2.Key([]byte(passwd), salt, 10000, 32, sha256.New)
	block, err := aes.NewCipher(key)
	if err != nil {
		panic(err.Error())
	}

	plaintext := []byte(pt)
	aesgcm, err := cipher.NewGCM(block)
	if err != nil {
		panic(err.Error())
	}

	ciphertext := aesgcm.Seal(nil, nonce, plaintext, nil)
	fmt.Printf("Message:\t%s\n", pt)
	fmt.Printf("Cipher:\t\t%x\n", ciphertext)
	fmt.Printf("Key:\t\t%x\n", key)
	fmt.Printf("Nonce:\t\t%x\n", nonce)

	plain, _ := aesgcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		panic(err.Error())
	}
	fmt.Printf("Decrypted:\t%s\n", plain)
}
```

If we try “Testing 123” and a password of “qwerty123” :

```yml
Message:	Testing 123
Cipher:		80f8087e75d6875d56198a082820fb3dc6c0ba7e4bac4f697094e2
Key:		2f7ffec39904ee5b61a73d881f6d2f36c27d2a60a42d828b52b6409dc13d1318
Nonce:		000000000000000000000000
Decrypted:	Testing 123
```

If we use the same encryption key and IV, and encrypt “Testing 1234”, we get :

```yml
Message:	Testing 1234
Cipher:		80f8087e75d6875d56198acf54928581167bca942c9baa407511d4f6
Key:		2f7ffec39904ee5b61a73d881f6d2f36c27d2a60a42d828b52b6409dc13d1318
Nonce:		000000000000000000000000
Decrypted:	Testing 1234
```

If we use the same encryption key and IV, and encrypt “Testing 12354”, we get :

```yml
Message:	Testing 12345
Cipher:		80f8087e75d6875d56198acfa267d902af38c544c7cfb088b51b8b7442
Key:		2f7ffec39904ee5b61a73d881f6d2f36c27d2a60a42d828b52b6409dc13d1318
Nonce:		000000000000000000000000
Decrypted:	Testing 12345
```

And so we see `“80f8087e75d6875d56198”` for each of the cipher, and basically that maps to “Testing 123”. The ciphering of “4” is thus: “ac”, and “5” is “fa”.

And so we can see that we get **the same out for our ciphering, for the same key and the same IV for each of the modes.**

