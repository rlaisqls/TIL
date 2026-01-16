
### Command Line Argument 사용

Go 프로그램의 `main()` 함수는 C,C# 등의 다른 언어에서 갖고 있는 argument 파라미터를 갖지 않는다. 따라서, Command Line의 Argument를 얻기 위해서는 `os.Args` 를 사용해야 한다.

`os.Args`는 문자열 슬라이스로 정의되어 있고, Args는 프로그램의 Command Line 정보를 순서대로 담고 있다.

```go
var Args []string
```

프로그램이 2개의 argument를 가진다고 가정했을 때, `os.Args[0:1]`는 실행되는 Go 프로그램 이름을 가지며, `os.Args[1:2]`는 첫번째 argument를, `os.Args[2:3]`는 두번째 argument를 갖는다.

아래 예제는 프로그래명과 2개의 Command Line argument를 출력하는 예시이다.

```go
package main
 
import ("fmt";  "os")
 
func main() {
    if len(os.Args) < 2 {
        panic("에러: 2개 미만의 argument")
    }
     
    programName := os.Args[0:1]
    firstArg := os.Args[1:2]
    secondArg := os.Args[2:3]
    allArgs := os.Args[1:]
     
    fmt.Println(programName, firstArg, secondArg)
}
```

### Command Line Flag 사용

위의 Command Line Args 기능에서 한발 나아가 Go는 흔히 사용되는 Command Line 옵션(예:`-h`, `-input` 등)을 파싱하는 기능을 제공한다. Command Line Flag라 불리우는 이 기능은 "flag" 표준패키지에서 제공한다.

flag는 문자열, 정수, 그리고 Boolean 3가지 데이터타입을 지원하는데, 각각 `flag.String()`, `flag.Int()`, `flag.Bool()` 같은 메서드를 사용하여 Command 옵션을 지정할 수 있다.

Command 옵션을 지정하는 플래그 메서드는 플래그명, 디폴트값, 그리고 간단한 플래그 도움말 등을 받아들이는데, 예를 들어, `flag.String`(플래그명, 디폴트값, 플래그 설명) 과 같은 형태이다. 모든 옵션이 정의된 후, `flag.Parse()` 호출하는데, 이는 실제 Command Line 옵션들을 파싱해서 읽어들여 (포인터)변수에 저장하는 역활을 한다.

포인터 변수에 저장된 데이터는 Dereference하여 사용하면 된다. 아래 예제는 `-file`, `-maxtrial`, `-root` 라는 3가지 옵션 플래그를 읽고 그대로 출력하는 코드이다.

```go
/* test.go */
package main
 
import (
    "flag"
    "fmt"
)
 
func main() {
 
    file := flag.String("file", "default.txt", "Input file")
    trials := flag.Int("maxtrial", 10, "Max Trial Count")
    isroot := flag.Bool("root", false, "Run as root")
 
    flag.Parse()
 
    // 포인터 변수이므로 앞에 * 를 붙어 deference 해야
    fmt.Println(*file, *trials, *isroot)
}
 
/* 테스트
$ go build test.go
$ test -file=test.csv -maxtrial=5 -root=true
test.csv 5 true
*/
````

flag에 기본적으로 내장된 옵션으로 `-h` 혹은 `--help` 옵션이 있다. 즉, 사용자가 `test --help` 처럼 실행하면, 등록된 모든 플래그 옵션들을 플래그 도움말(플래그 정의시 개발자가 지정한 도움말)과 함께 화면에 출력해 준다.

```bash
$ test --help
Usage of test:
  -file string
        Input file (default "default.txt")
  -maxtrial int
        Max Trial Count (default 10)
  -root
        Run as root
```

---
참고
- http://golang.site/go/article/206-Command-Line-Argument-%EC%82%AC%EC%9A%A9
- https://blog.stackademic.com/advanced-go-build-techniques-d44cbc0cbeda