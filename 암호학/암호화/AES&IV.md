
AES에서 동일한 평문에 대해 항상 동일한 암호문을 얻을까? (동일한 IV와 키 사용 시)

- AES의 ECB(Electronic Code Book) 모드에서는 동일한 키에 대해 항상 동일한 암호문을 얻는다.
- 블록 암호이므로 패딩이 마지막 문자를 변경하지만, 16바이트가 있는 한 첫 번째 블록은 동일하다.
- 하지만 IV를 사용하는 모드는 어떨까? 스트림 암호 모드인 GCM을 살펴보고 동일한 키와 동일한 IV를 사용할 때 어떤 일이 발생하는지 확인해보자.

- 다음과 같은 Golang 코드를 작성함.

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

    위 코드에서는 패스워드를 암호화 키로 변환하고, IV를 모두 0으로 설정하며, 키 생성 시 동일한 salt를 사용함.

    "Testing 123"과 패스워드 "qwerty123"을 사용하면:

    ```yml
    Message: Testing 123
    Cipher:  80f8087e75d6875d56198a082820fb3dc6c0ba7e4bac4f697094e2
    Key:  2f7ffec39904ee5b61a73d881f6d2f36c27d2a60a42d828b52b6409dc13d1318
    Nonce:  000000000000000000000000
    Decrypted: Testing 123
    ```

- 동일한 암호화 키와 IV로 "Testing 1234"를 암호화하면:

    ```yml
    Message: Testing 1234
    Cipher:  80f8087e75d6875d56198acf54928581167bca942c9baa407511d4f6
    Key:  2f7ffec39904ee5b61a73d881f6d2f36c27d2a60a42d828b52b6409dc13d1318
    Nonce:  000000000000000000000000
    Decrypted: Testing 1234
    ```

- 동일한 암호화 키와 IV로 "Testing 12345"를 암호화하면:

    ```yml
    Message: Testing 12345
    Cipher:  80f8087e75d6875d56198acfa267d902af38c544c7cfb088b51b8b7442
    Key:  2f7ffec39904ee5b61a73d881f6d2f36c27d2a60a42d828b52b6409dc13d1318
    Nonce:  000000000000000000000000
    Decrypted: Testing 12345
    ```

결과:

- 각 암호문에서 `"80f8087e75d6875d56198"`가 공통적으로 나타남
- 이는 "Testing 123"에 매핑됨
- "4"의 암호화는 "ac"
- "5"의 암호화는 "fa"

결론: 동일한 키와 동일한 IV를 사용하면 모든 모드에서 동일한 암호화 출력을 얻음. 이는 보안 측면에서 위험할 수 있으므로, 실제 환경에서는 IV를 매번 다르게 사용해야 함.
