슬라이스는 내부적으로 사용하는 배열의 부분 영역인 세그먼트에 대한 메타 정보를 가지고 있다. 슬라이스는 크게 3개의 필드로 구성되어 있다.

1. 내부적으로 사용하는 배열에 대한 포인터 정보
2. 세그먼트의 길이
3. 세그먼트의 최대 용량(Capacity)

<img style="height: 200px" src="https://github.com/user-attachments/assets/09a64514-9c03-4fe5-ae26-905dbcfd176b">


## append

`append()`가 슬라이스에 데이터를 추가할 때는
- 슬라이스 용량(capacity)이 아직 남아 있는 경우: 용량 내에서 슬라이스의 길이(length)를 변경하여 데이타를 추가한다.
- 용량(capacity)을 초과하는 경우: 현재 용량의 2배에 해당하는 새로운 Underlying array를 생성하고, 기존 배열 값들을 모두 새 배열에 복제한 후 다시 슬라이스를 할당한다.

아래 예제는 길이 0, 용량 3의 슬라이스에 1부터 15까지의 숫자를 계속 추가하면서 슬라이스의 길이와 용량이 어떻게 변하는 지를 체크하는 코드이다. 이 코드를 실행하면 1~3까지는 기존의 용량 3을 사용하고, 4~6까지는 용량 6을, 7~12는 용량 12, 그리고 13~15는 용량 24의 슬라이스가 사용되는 것을 볼 수 있다.

```go
package main
 
import "fmt"
 
func main() {
    // len=0, cap=3 인 슬라이스
    sliceA := make([]int, 0, 3)
 
    // 계속 한 요소씩 추가
    for i := 1; i <= 15; i++ {
        sliceA = append(sliceA, i)
        // 슬라이스 길이와 용량 확인
        fmt.Println(len(sliceA), cap(sliceA))
    }
 
    fmt.Println(sliceA) // 1 부터 15 까지 숫자 출력 
}
```

append를 잘못 사용하면 아래와 같은 문제가 생길 수 있다.

```go
func main() {
	s1 := []int{1, 2, 3}
	s2 := s1[1:2]
	s3 := append(s2, 10)
	fmt.Println(s1, s2, s3)
}
// [1 2 10] [2] [2 10]
```

이 코드를 실행하면 **s1에는 10을 직접 추가한 적이 없음에도** 값이 바뀌어 있다. s2의 각 element는 s1의 각 element와 같은 포인터를 가지기 때문에, s2의 요소 값을 수정하면 s1에도 반영된다.

그리고 slice로 생성된 s2의 용량은 s1의 1번째 인덱스부터 s1의 마지막 인덱스만큼의 크기이기 때문에, 기존 요소의 뒤에 해당하는 공간도 s1과 공유한다. 따라서 s2에 10을 추가해서 바로 뒤의 포인터에 append 되면 s1의 2번 element가 덮어씌워지는 것이다.  

아래처럼 용량을 설정해주면 의도치 않은 덮어쓰기를 막을 수 있다. 기존 길이만큼의 s2 배열 요소 값을 수정했을 때에도 s1에 영향을 주지 않으려면 copy를 사용해야 한다

```go
func main() {
	s1 := []int{1, 2, 3}
	s2 := s1[:2:2]
	s2 = append(s2, 10)
	fmt.Println(s2, s1)
}
```


---
참고
- http://golang.site/go/article/13-Go-%EC%BB%AC%EB%A0%89%EC%85%98---Slice
- https://go.dev/blog/slices-intro
