# Symbolic Link

Linux/UNIX 시스템에는 두 가지 유형의 링크가 있다. 

- Hard link : Hard link를 기존 파일의 추가 이름으로 생각할 수 있다. Hard link는 둘 이상의 파일 이름을 동일한 i-node와 연결한다.

- Soft link : Soft link는 Windows(윈도우)의 바로 가기 같은 것으로, 파일 또는 디렉터리에 대한 간접 포인터이다. Hard link와 달리 심볼릭 링크는 다른 파일 시스템 또는 파티션의 파일이나 디렉터리를 가리킬 수 있다.

### ln

ln은 파일 간의 링크를 만드는 명령어이다.

기본적으로 ln 명령은 Hard link를 생성한다. 심볼릭 링크를 만들려면 `-s` 옵션을 사용해야한다. 

심볼릭 링크를 생성하기 위한 ln 명령 구문은 다음과 같다.

```bash
ln -s [OPTIONS] FILE LINK
```

FILE과 LINK가 모두 주어지면 ln은 첫 번째 인수(FILE)로 지정된 파일에서 두 번째 인수(LINK)로 지정된 파일에 대한 링크를 생성한다.

### Symlinks 제거

심볼릭 링크를 삭제/제거하려면 unlink나 rm 명령을 사용할 수 있다.

```bash
unlink symlink_to_remove
rm symlink_to_remove
```

---
참고
- https://www.freecodecamp.org/korean/news/rinugseu-symlink-tyutorieol-simbolrig-ringkeu-symbolic-link-reul-saengseonghago-sagjehaneun-bangbeob/