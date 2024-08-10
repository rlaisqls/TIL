Go의 GC는 mark-sweep 방식으로 동작하며 두 가지 주요 단계로 나뉜다.

- 마킹: 메모리에서 살아있는 객체를 식별한다.
- 스윕: 죽은 객체를 해제하여 메모리를 반환한다.

GC는 스윕 → 비활성 → 마킹 세 단계를 순회하며 주기적으로 진행된다.

Go의 GC는 현시점의 Heap 크기와 직전 시점의 Heap 크기에 대한 증가율이 특정 정도에 다다르면 수행되는 로직으로 구현되었다. 이 때 그 정도를 정하는 변수는 GOGC라고 부른다. GOGC 값을 사용해 아래와 같이 목표 힙 메모리를 구한다.  

> 목표 힙 메모리 = 살아있는 힙 메모리 + (살아있는 힙 메모리 + GC 루트) × GOGC / 100

예를 들어, 살아있는 힙이 8 MiB이고, GOGC가 100일 때, 목표 힙 메모리는 18 MiB이다. GOGC가 50일 경우 13 MiB, GOGC가 200일 경우 28 MiB가 된다.

GC가 동작하는 Default 비율 값은 100으로, 기존 대비 Heap이 100% 증가, 즉 2배가 되면 GC를 수행한다. 이 값을 낮추면 GC가 더 자주 수행되고, 이 값을 높일수록 GC가 덜 수행되게 된다. GOGC 값이 너무 작은 경우 GC가 너무 빈번하게 수행될 수 있고, GOGC 값이 너무 큰 경우 OOM 발생 가능성이 커진다.

GOMEMLIMIT은 프로그램이 사용할 수 있는 메모리 사용량 한계선을 정하는 설정이다. 이 방식에서는 설정한 GOMOMLIMIT의 값만큼 메모리 사용량이 올라가는 경우에만 GC가 수행된다. 따라서 프로그램이 사용할 수 있는 최대 메모리 한계선을 미리 산정한 후, 그 값보다 작은 값을 GOMEMLIMIT으로 설정하면 GC를 쉽게 튜닝할 수 있다.

## Heap 할당을 줄이는 팁

### 비정형 인자 조심하기

아래 코드에서 j와 k 객체는 Heap 메모리에 할당되지만, i는 Stack 메모리에 할당된다.

`fmt.Println`, `fmt.Printf` 함수는 두 함수는 any 타입의 인자를 사용하기 때문에 무엇이든 전달받을 수 있다. 그리고 무엇이든 받기 위해, 각 변수에는 그 type을 설명하는 보조 정보가 필요하다. 이때, 보조 정보가 있는 데이터는 반드시 Heap 메모리 영역에 할당된다. 즉 any 만이 아니라, interface 및 reflect 등의 타입을 읽고 해석하는 추상화가 필요한 데이터들은 GC 부하를 일으키는 원인으로 작용한다. 

```go
package main

import (
    "fmt"
)

func main() {
    i := 0
    j := i + 1  // j escapes to heap
    k := j + 1 //  escapes to heap

    fmt.Println(j)
    fmt.Printf("%d\n",k)
}
```

### Pointer 변수 조심하기

> https://articles.wesionary.team/use-case-of-pointers-in-go-w-practical-example-heap-stack-pointer-receiver-60b8950473da

Go에서 포인터로 선언하면, 해당 오브젝트는 무조건 Heap 영역에 할당된다. 따라서 Go에서는 CallByPointer보다 CallByValue가 효율적인 경우가 종종 있다.

### 포인터 배열

go에서 GC시에 포인터가 일반 값보다 오래걸린다.

> https://blog.gopheracademy.com/advent-2018/avoid-gc-overhead-large-heaps

```go
func main() {
	a := make([]int, 1e9)

	for i := 0; i < 10; i++ {
		start := time.Now()
		runtime.GC()
		fmt.Printf("GC took %s\n", time.Since(start))
	}

	runtime.KeepAlive(a)
}
/*
실행결과
GC took 749.083µs
GC took 260.375µs
GC took 252.417µs
GC took 240.25µs
GC took 238.083µs
GC took 218.167µs
GC took 280.25µs
GC took 240.5µs
GC took 273.084µs
GC took 261.083µs
*/
```

```go
func main() {
	a := make([]*int, 1e9)

	for i := 0; i < 10; i++ {
		start := time.Now()
		runtime.GC()
		fmt.Printf("GC took %s\n", time.Since(start))
	}

	runtime.KeepAlive(a)
}
/*
실행결과
GC took 1.754290958s
GC took 434.731125ms
GC took 272.784333ms
GC took 281.748875ms
GC took 270.473041ms
GC took 276.79525ms
GC took 280.883542ms
GC took 271.704167ms
GC took 269.696375ms
GC took 269.201958ms
*/
```


---
참고
- https://gchandbook.org
- https://tip.golang.org/doc/gc-guide
- https://tech.kakao.com/posts/618
