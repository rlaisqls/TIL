# TLAB과 PLAB

## 1. TLAB(Thread Local Allocation Buffers)

JVM에서는 Eden 영역에 객체를 빠르게 할당(Allocation)하기 위해 bump the pointer와 TLABs(Thread-Local Allocation Buffers)라는 기술을 사용하고 있다. bump the pointer란 Eden 영역에 마지막으로 할당된 객체의 주소를 캐싱해두는 것이다. bump the pointer를 통해 새로운 객체를 위해 유효한 메모리를 탐색할 필요 없이 마지막 주소의 다음 주소를 사용하게 함으로써 속도를 높이고 있다. 이를 통해 새로운 객체를 할당할 때 객체의 크기가 Eden 영역에 적합한지만 판별하면 되므로 빠르게 메모리 할당을 할 수 있다.

- Heap 메모리에 새로운 객체가 생성될 때, 만약 TLAB이 활성화되어 있다면 객체는 우선 TLAB에 위치하게 된다.
- TLAB은 Eden 영역에만 존재한다. 따라서 TLAB을 사용하면 에덴 영역을 좀 더 많이 사용하게 되지만 객체 생성시 성능 효과를 볼 수 있다.
- 각 스레드는 빠른 메모리 할당을 위해 자신만의 TLAB을 가지고 있다.
- TLAB은 각 스레드에 미리 할당되어 있다. 따라서 TLAB의 총 크기는 스레드 수에 비례한다.
- TLAB을 사용하려면 `-XX:+UseTLAB` 옵션을 사용해야한다.
- TLAB의 크기를 조절하려면 `-XX:+UseTLAB` 옵션을 사용해야한다. 디폴트는 `0`인데 이때는 시스템이 알아서 조절하게 된다.

> As the runtime has TLAB per thread, it makes the process thread safe automatically (we have nothing to synchronize) and very cheap, as we take the pointer to the top of free space and move it on allocation size. Using pseudo-code, the algorithm looks like this:

```c
start = currentThread.tlabTop;
end = start + sizeof(Object.class);

if (end > currentThread.tlabEnd) {
  goto slow_path;
}
```

## 2. PLAB(Promotion Local Allocation Buffers)

- GC에서 Generation을 청소하는 동안 사용된다.
- 각 스레드에 존재한다.

---
참고
- https://www.gmc-uk.org/registration-and-licensing/join-the-register/plab
- https://www.oracle.com/webfolder/technetwork/tutorials/obe/java/gc01/index.html
- https://www.oracle.com/technetwork/java/javase/memorymanagement-whitepaper-150215.pdf