- go는 builder보다 함수형 옵션 패턴을 많이 쓴다.
- slice를 선언할 수 있는 방법은 매우 다양하다.

    ```
    var s []string // empty=true, nil=true
    s = []string(nil) // empty=true, nil=true
    s = []string{} // empty=true, nil=false
    s = make([]string, 0) // empty=true, nil=false
    ```
- 책의 권장사항
    - `var s[]string`: 최종 길이를 모르고 슬라이스가 빌 수도 있는 경우
    - `[]string(nil)`: nil 슬라이스이면서 empty슬라이스를 생성하는 편의 구문
    - `make([]strign, length)`: 최종 길이를 아는 경우. <- 이 경우는 실제 성능적으로 slice 길이를 조절하지 않아도 되기 때문에 성능이 좋은 편이다.
- 슬라이스가 비었는지 제대로 확인하라
    - 모든 slice은 선언과 동시에 nil이라도 길이가 0이다. 그래서 실제 slice가 nil이라도 len(slice)를 통해서 검증하게 되면 원하지 않는 동작을 할 수 있다.
    - 결국 모든 slice를 길이로만 검증하려고 한다면 자신이 원하지 않은 결과가 나올 수도 있다.
- slice에 대해서 arr[:5]와 같은 방식으로 자르면 다른 slice로 사용할 수 있다. 하지만 이렇게 되면 길이는 실제로 slicing한 만큼이지만 용량은 그대로이다.해결하기 위해선 하나하나 복제해야 한다.
- 포인터를 가진 slice에 대해서 slicing하면 gc 이후에도 기존 slice가 지속적으로 메모리에 남아있는 문제가 있다. 해결방법으로는 slicing을 원하는 slice만큼 복제를 진행하거나 명시적으로 필요하지 않은 엘리멘트에 대해서는 명시적으로 nil로 값을 넣는것이다.
- range가 동작할 때 v값은 언제나 복제본이다. 순회하며 업데이트하고 싶다면 명시적으로 인덱스를 선택해서 값을 바꿔야 한다. (배열도 복사본을 따르기 때문에, 순회 중간에 배열 요소를 추가, 삭제하여도 영향이 없다.)
- 아래 코드의 실행 결과는 6이다. go에서 string은 각 문자가 같은 바이트를 사용하지 않고, 1-4바이트를 사용할 수 있는 유니코드 코드 포인트인 rune으로 구성되기 때문이다.

    ```
    func main() {
        text := "하ihi"
        println(len(text))
    }
    ```
- 따라서 index가 아닌 range로 돌아야 각 문자 단위로 순회할 수 있다.

    ```
    s := "헬low"
    runes := []rune(s)
    for i, v := range runes {
    fmt.Printf("position %d, %c\n", i, v)
    }
    ---
    position 0, 헬
    position 3, l
    position 4, o
    position 5, w
    ```
- string에 값을 반복적으로 추가하는 것 보다, `strings.Bulder{}`을 사용하는 게 성능이 더 좋다. 메모리 복사가 덜 일어나기 때문이다.
