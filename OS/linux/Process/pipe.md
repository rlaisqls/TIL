
Linux에서 pipe는 한 프로세스에서 다른 프로세스로 정보를 넘겨주는 방법 중 하나이다.

아래와 같이 사용하면 왼쪽 명령어의 결과(output)을 오른쪽에 있는 명령어에 입력(input)으로 전달한다. 즉, 좌측의 stdout을 우측의 stdin으로 넘긴다고 생각하면 된다.

```bash
$ ps -ef | grep bash
```

> Redirect(`>`)는 프로그램의 결과 혹은 출력(output)을 파일이나 다른 스트림으로 넘길 때 사용되는 반면, pipe(`|`)는 프로세스로 넘겨준다는 점이 차이이다.

## c언어에서의 pipe

`unistd.h` 헤더의 pipe 함수를 사용하면 프로그램 내에서 pipe를 사용할 수 있다.

```c
#include<unistd.h>
int pipe(int filedes[2]);
```

인자로 받는 파일기술자 배열에서 `[0]`은 읽기용이고 `[1]`은 쓰기용이다. 호출이 성공하면 0을 반환하고, 실패하면 -1을 반환한다.

파일기술자는 파이프 용 특수 파일을 가리키게 되는데, 일반 파일을 다루는 것과 동일하게 사용하면 된다. 

### 예제

pipe를 활용한 프로그래밍 예제를 살펴보자. 

코드는 아래와 같은 동작을 수행한다.

- **부모 프로세스:**
  - for 루프를 통해 msg 배열의 각 문자열을 파이프를 통해 자식 프로세스로 보낸다. 각각의 문자열을 buffer에 복사하고, `write()` 함수를 사용하여 파이프에 쓰기 작업을 수행한다.
  - 첫 버퍼를 출력해보고 버퍼에 msg의 첫 요소를 다시 삽입한다.
  - 마지막으로 "bye!"라는 메시지를 출력한다.
   
- **자식 프로세스:**
  - 파이프를 통해 받은 데이터를 (`read()` 함수를 사용하여) 읽고, 해당 값을 출력한다. 이 과정을 for 루프 안에서 세 번 반복한다.
  - 마지막으로 "bye!"라는 메시지를 출력한다.

```c
#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <stdlib.h>
#include <string.h>

#define SIZE 512

int main() {
	char *msg[] = {"apple is red", "banana is yellow", "cherry is red"};
	char buffer[SIZE];
	int filedes[2], nread, i;
	pid_t pid;

	if (pipe(filedes) == -1) {
		printf("fail to call pipe()\n");
		exit(1);
	} if ((pid = fork()) == -1) {
		printf("fail to call fork()\n");
		exit(1);
	} else if (pid > 0) {
		for(i = 0 ; i < 3 ; i++){
			strcpy(buffer, msg[i]);
			write(filedes[1], buffer, SIZE);
		}
		nread = read(filedes[0], buffer, SIZE);
		printf("[parent] %s\n", buffer);

		write(filedes[1], buffer, SIZE);
		printf("[parent] bye!\n");
	} else {
		for (i = 0 ; i < 3 ; i++){
		    nread = read(filedes[0], buffer, SIZE);
		    printf("[child] %s\n", buffer);
		}
		printf("[child] bye!\n");
	}
}
```

출력 결과는 아래와 같다.

```c
[parent] apple is red
[parent] bye!
[child] banana is yellow
[child] cherry is red
[child] apple is red
[child] bye!
```

---
참고
- 리눅스 시스템 프로그래밍 수업
- https://tldp.org/LDP/lpg/node11.html
- https://man7.org/linux/man-pages/man2/pipe.2.html
- https://twpower.github.io/133-difference-between-redirect-and-pipe