# Rc 타입과 Weak 타입

- 소유권 규칙에 따라 Rust에서 어떤 값은 여러 소유자를 가질 수 없다. 
- Reference Counted를 의미하는 Rc는 힙 메모리에 할당된 타입 T 값의 소유권을 공유할 수 있게 해주는 타입이다. 즉, 스마트 포인터 Rc를 사용하면 타입 T의 값에 대한 여러 개의 소유자를 만들 수 있다.
- 기본적으로, Rc 타입은 Clone Trait을 구현하고 있고 clone을 호출해서 T 값에 대한 새로운 포인터를 생성하며, 모든 Rc 포인터가 해제되면 메모리에 할당된 T 값이 drop되는 구조이다. 
  - Rust에서 공유된 참조자는 수정할 수 없는데, Rc 타입 또한 예외가 아니며 일반적인 방법으로는 mutable한 참조를 얻을 수 없다. 만약, mutable 한 참조가 필요하면 Cell 타입이나 RefCell 타입을 함께 사용해야 한다.

- Rc 타입은 원자적이지 않은 참조 카운팅으로 오버헤드가 낮은 장점이 있지만 단일 스레드에서만 사용 가능하다. 
  - 따라서, Rc 타입은 스레드 간 전송을 위한 Trait인 Send 타입을 구현하지 않다. 한편, 원자적 참조 카운팅 타입인 Arc(Atomic Reference Counted)가 있다. Arc 타입은 다중 스레드 간 사용이 가능하지만 Rc 타입보다 오버헤드가 큰 단점이 있다.

- `std::rc` 모듈에는 Rc 타입과 더불어 약한 참조인 Weak 타입이 존재한다. 
  - Rc 타입을 downgrade해서 `Weak<T>` 타입을 얻을 수 있고, Weak 타입을 upgrade해서 `Option<Rc<T>>` 타입을 얻을 수 있다. Weak 타입에서 Rc 타입을 얻고자 upgrade를 사용할 때, T 값이 이미 drop 되었다면 None을 리턴한다. 이 말은 Rc 타입과 다르게 Weak 타입은 메모리에 할당된 **타입 T의 값이 살아있는 것을 보장하지 않는다**는 의미이다.
  - 즉, Rc 타입의 강한 참조 카운트가 0이 되면 T 값이 drop 되는데, 약한 참조 카운트를 의미하는 Weak 타입은 영향을 미치지 않는다.

- 앞서 설명했듯, Rc 타입이 갖고 있는 강한 참조 카운트가 0이 되지 않으면 T 값은 drop 되지 않는다. 이는 T 값이 결코 drop 될 수 없는 순환 참조를 야기할 수도 있다. T 값의 drop에 영향을 미치지 않는 Weak 타입은 이런 문제의 상황에서 유용하게 사용될 수 있다. 

자세한 내용은 아래에서 코드와 함께 살펴보자.

## Rc 타입 사용하기


```rust
fn main() {
    let rc = Rc::new(10);
    println!("[ 1 ]");
    println!("value of rc => {}", rc);
    println!("strong count => {}", Rc::strong_count(&rc));
    println!("weak count => {}", Rc::weak_count(&rc));
}

```

Rc 타입은 new 함수를 통해 생성할 수 있다. 위 코드 3번째 라인에서 볼 수 있듯이 Rc 타입은 Deref Trait을 구현하고 있어 자동으로 역참조 된다. Rc가 생성될 때 strong_count 값은 1로 초기화된다. 

아래 코드는 clone을 통해 타입 T 값에 대한 여러 개의 참조자를 만드는 것을 보여준다.


```rust
fn main() {
    let rc = Rc::new(10);
    println!("[ 1 ]");
    println!("value of rc => {}", rc);
    println!("strong count => {}", Rc::strong_count(&rc));
    println!("weak count => {}", Rc::weak_count(&rc));

    {
        let rc2 = rc.clone();
        println!("[ 2 ]");
        println!("value of rc2 => {}", rc2);
        println!("strong count => {}", Rc::strong_count(&rc));
        println!("weak count => {}", Rc::weak_count(&rc));

        let rc3 = Rc::clone(&rc);
        println!("[ 3 ]");
        println!("value of rc3 => {}", rc3);
        println!("strong count => {}", Rc::strong_count(&rc));
        println!("weak count => {}", Rc::weak_count(&rc));
    }

    println!("[ 4 ]");
    println!("strong count => {}", Rc::strong_count(&rc));
    println!("weak count => {}", Rc::weak_count(&rc));
}

```

Rc 타입은 Clone Trait을 구현하고 있고 `rc.clone()`과 `Rc::clone()` 두 가지 방식으로 호출할 수 있다. clone을 호출하면 타입 T 값에 대한 새로운 참조자가 생성되며, strong_count는 1 증가한다. rc2와 rc3가 코드 블록을 벗어남에 따라 strong_count는 총 2가 감소해 마지막으로 출력되는 strong_count의 값은 1이 된다. 생성된 모든 Rc 타입이 drop 되면 strong_count가 0이 되면서 힙에 할당된 타입 T 값 역시 drop 된다.
 

## Weak 타입 사용하기

Weak 타입에도 생성 메서드 new가 존재하지만, 인자로 어떠한 타입 값도 받지 않는다. 즉, 타입 T에 대한 어떠한 값도 메모리에 할당되지 않다. 따라서, new로 새롭게 생성한 Weak 타입의 upgrade 메서드는 항상 None을 리턴한다.

```rust
fn main() {
    let weak: Weak<i32> = Weak::new();
    assert!(weak.upgrade().is_none());
}
```
 

아래 코드에서 Rc 타입을 Weak 타입으로 downgrade 하고, Weak 타입을 Rc 타입으로 upgrade 하는 과정을 볼 수 있다. 예제를 실행해 strong_count와 weak_count 값의 변화를 확인해보자.

```rust
fn main() {
    let rc = Rc::new(10);
    println!("[ 1 ]");
    println!("value of rc => {}", rc);
    println!("strong count => {}", Rc::strong_count(&rc));
    println!("weak count => {}", Rc::weak_count(&rc));

    let weak = Rc::downgrade(&rc);
    println!("[ 2 ]");
    println!("value of weak => {}", unsafe { &*weak.as_ptr() });
    println!("strong count => {}", Rc::strong_count(&rc));
    println!("weak count => {}", Rc::weak_count(&rc));

    if let Some(rc2) = Weak::upgrade(&weak) {
        println!("[ 3 ]");
        println!("value of rc2 => {}", rc2);
        println!("strong count => {}", Rc::strong_count(&rc));
        println!("weak count => {}", Rc::weak_count(&rc));
    } else {
        println!("강한 참조가 남아 있지 않다.");
    }
}
```

9번째 줄에서 값을 출력하는 방식이 Rc와 다른 것을 확인할 수 있다. Weak 타입은 Rc 타입과 다르게 Deref Trait을 구현하고 있지 않기 때문에 자동으로 역참조가 일어나지 않다. 또한, as_ptr() 메서드를 통해 T 값에 접근할 수 있지만, 아직 타입 T 값이 메모리에서 drop 되지 않았다는 것을 알 수 없기 때문에 unsafe 키워드를 사용해야 한다. 그래서 개발자는 Weak 참조자가 가리키는 값이 아직 유효하다는 것을 보장할 수 있을 때 사용해야 한다.


Weak 타입은 Rc 타입으로 upgrade 할 수 있는데, downgrade와 달리 upgrade는 Option<Rc> 을 반환한다. 이는, 앞서 설명했듯이 Weak 타입이 메모리에 할당된 타입 T 값의 유효성을 보장하지 않기 때문이다. 만약 strong_count가 0이 되어 타입 T 값이 drop 된 상태라면, upgrade 메서드는 None을 반환할 것이다.


## 순환 참조의 문제

Rc 타입 간에는 순환 참조 문제가 발생할 수 있는데, Weak 타입을 사용하여 이를 해결할 수 있다. 트리 데이터 구조 예제 코드를 통해 순환 참조가 일어날 수 있는 상황에서 Weak 타입을 활용하는 방법을 알아보자.

```rust
#[derive(Debug)]
struct Node {
    value: i32,
    children: RefCell<Vec<Rc<Node>>>,
}
```

먼저, 트리의 노드 구조체를 만든다. 이 노드는 하나의 값과 자식 노드들의 참조자들을 가지고 있다. 여기서 자식 노드는 Rc 타입으로 소유권을 공유하고 직접 접근할 수 있다. 또한 자식 노드가 수정될 수 있도록 RefCell<T> 타입으로 감쌌다.
 

이제, 이 노드 구조체를 이용해 leaf와 leaf를 자식 노드로 가지는 branch를 만들어 보자.

 
```rust
fn main() {
    let leaf = Rc::new(
        Node {
            value: 3,
            children: RefCell::new(vec![]),
        }
    );

    let branch = Rc::new(
        Node {
            value: 5,
            children: RefCell::new(vec![Rc::clone(&leaf)]),
        }
    );
} 
```

leaf는 자식이 없는 Node이고, branch는 leaf를 자식으로 갖는 Node이다. 우리는 이제 branch.children을 통해 branch에서 leaf로 접근할 수 있다. 하지만, leaf가 부모 노드에 대한 참조자를 알지 못하기 때문에 leaf에서 branch로는 접근이 불가능한 상황이다. 이를 위해 자식 노드가 부모 노드로 접근할 수 있도록 하는 parent 참조자를 추가해야 한다.

 

parent 타입을 추가함으로써 leaf가 부모인 branch를 참조하고, branch가 자식인 leaf를 참조한다는 것을 쉽게 생각해볼 수 있다. 이때 parent의 타입을 children과 같이 Rc 타입으로 만든다면, strong_count 값이 0이 될 수 없는 순환 참조 문제를 야기할 수 있다. 따라서, 우리는 순환 참조 문제를 피하기 위해 parent 타입을 Weak 타입으로 만들 것이다.

 
```rust
#[derive(Debug)]
struct Node {
    value: i32,
    parent: RefCell<Weak<Node>>,
    children: RefCell<Vec<Rc<Node>>>,
}
 
```

이제, 노드는 부모 노드를 소유하지는 않지만 참조할 수 있게 되었다.

 
```rust
fn main() {
    let leaf = Rc::new(Node {
        value: 3,
        parent: RefCell::new(Weak::new()),
        children: RefCell::new(vec![]),
    });

    println!("leaf parent = {:?}", leaf.parent.borrow().upgrade());

    let branch = Rc::new(Node {
        value: 5,
        parent: RefCell::new(Weak::new()),
        children: RefCell::new(vec![Rc::clone(&leaf)]),
    });

    *leaf.parent.borrow_mut() = Rc::downgrade(&branch);

    println!("leaf parent = {:?}", leaf.parent.borrow().upgrade());
}

```

16번째 줄에서 leaf 노드의 parent에 branch 노드의 Weak 참조자를 넣어 주는 것을 볼 수 있다.


아래는 위 코드를 출력한 결과이다.

![image](https://github.com/rlaisqls/TIL/assets/81006587/918510c0-96a6-4276-a326-e7cc9ea4d3db)

결과를 보면 Weak 참조자가 (Weak)로 출력되는 것을 알 수 있고, 무한 출력이 없다는 것은 순환 참조를 야기하지 않는다는 것을 의미한다.

---
 참고
 - https://doc.rust-lang.org/stable/std/rc/struct.Rc.html
 - https://doc.rust-lang.org/book/ch15-06-reference-cycles.html