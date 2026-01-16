
```c
#include <unistd.h>
#include <sys/mman.h>

#ifdef _POSIX_MAPPED_FILES
void * mmap(void *start, size_t length, int prot, int
        flags, int fd, off_t offset);
int munmap(void *start, size_t length);

#endif
```

- `mmap`은 파일이나 장치를 메모리에 대응시키거나 푸는 시스템콜이다.
- `fd`로 지정된 파일(혹은 다른 객체)에서 `offset`을 시작으로 `length` 바이트 만큼을 `start` 주소로 대응시키도록 한다.

---

- 명시적인 `mmap`을 사용해 운영체제에 가상 메모리를 요청하면 운영체제는 RAM의 페이지를 즉시 할당해주지 않고, 가상 주소 범위만 제공한다.
  - 그리고 실제로 메모리에 접근할 때 MMU가 페이지 결함을 일으키면 그때 새로운 페이지를 할당해준다.

- 운영체제에서는 메모리를 **오버커밋** 상태로 관리한다.
  - 즉, 할당 가능한 RAM 용량을 물리적 최대 용량보다 크게 잡는다. 
  - 할당받았지만 메모리를 즉시 사용하지 않는 케이스가 생길 수 있기 때문이다.
  - 그렇기 떄문에 `mmap`으로 메모리를 할당받았지만 운영체제의 실제 메모리가 부족해서 사용시 문제가 생길 수도 있다.

---
참고 
- [Go 성능 최적화 가이드](https://www.yes24.com/Product/Goods/122308121?pid=123487&cosemkid=go16946818029110592&gad_source=1&gclid=CjwKCAiApuCrBhAuEiwA8VJ6Jvu_E0svIWMux506LsLfl9VgN1bn_VY-dkqqHDe_2_XmZme9qAv4ahoC_6cQAvD_BwE)
- https://man7.org/linux/man-pages/man2/mmap.2.html