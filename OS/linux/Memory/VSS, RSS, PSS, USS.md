<img width="496" alt="image" src="https://github.com/dodoplamingo/test/assets/108961398/51bc4e91-9539-465a-91aa-57ee1118dc31">

## VSS (Virtual set size)

- VSS는 프로세스의 액세스 가능한 전체 주소 공간이다.
- 이 크기에는 (malloc과 같은 방법으로) 할당되었지만 기록되지 않은 RAM에 상주하지 않을 수 있는 메모리도 포함된다. 
- 따라서 VSS는 프로세스의 실제 메모리 사용량을 결정하는 데 큰 관련이 없다.

## RSS (Resident set size)

- RSS는 프로세스를 위해 실제로 RAM에 보관된 총 메모리이다.
- RSS는 공유 라이브러리를 사용하는 경우에 중복해서 카운팅하기 때문에 정확하지 않다. 
- 즉, 단일 프로세스의 메모리 사용량을 정확하게 나타내지 않는다.

## PSS (Proportional set size)

- PSS는 RSS와 달리 공유 라이브러리를 고려하여 비례한 크기를 나타낸다.
- 세 프로세스가 모두 30 페이지 크기의 공유 라이브러리를 사용하는 경우 해당 라이브러리는 세 프로세스 각각에 대해 보고되는 PSS에는 10 페이지가 더해진다.
- 시스템의 모든 프로세스에 대한 PSS를 합하면 시스템의 총 메모리 사용량과 동일하다.
- 프로세스가 종료되면 해당 PSS에 기여한 공유 라이브러리는 해당 라이브러리를 사용하는 나머지 프로세스의 PSS 총계에 비례하여 다시 분배된다.
- 따라서 프로세스가 종료될 때 전체 시스템에 반환된 메모리를 나타내지는 못한다.

## USS (Unique set size)

- USS는 프로세스의 총 개인 메모리, 즉 해당 프로세스에 완전히 고유한 메모리이다.
- USS는 특정 프로세스를 실행하는 실제 증분 비용을 나타내기 때문에 유용하다.
- 프로세스가 종료되면 실제로 시스템에 반환되는 총 메모리와 같다.
- 처음에 프로세스에서 메모리 누수가 의심될 때 관찰할 수 있는 가장 좋은 숫자이다.

---
참고
- https://www.baeldung.com/linux/resident-set-vs-virtual-memory-size
- https://en.wikipedia.org/wiki/Resident_set_size
- https://en.wikipedia.org/wiki/Proportional_set_size
- https://en.wikipedia.org/wiki/Unique_set_size