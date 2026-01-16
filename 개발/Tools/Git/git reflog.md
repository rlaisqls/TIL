
git branch를 실수로 reset하여 복구하고 싶을 때가 있다.

그런 경우 `git reflog`를 사용해 특정 명령어 실행 전의 코드로 돌아갈 수 있다. (`git log -g --abbrev-commit --pretty=oneline`도 사용할 수 있다.)

```
$ git reflog
a1b2c3d (HEAD -> wip/goofy, origin/develop, origin/HEAD) HEAD@{0}: checkout: moving from wip/goofy to develop
a1b2c3d (HEAD -> wip/goofy, origin/develop, origin/HEAD) HEAD@{1}: reset: moving to a1b2c3d7aa62eaab5fdc1dfa83993d9b9e78bde5
c7d8e9f HEAD@{2}: commit (amend): 테스트
```

reflog 결과가 위와 같다고 해보자.

`git checkout HEAD@{2}` 또는 `git checkout c7d8ef` 명령어를 입력하면 reset 전 commit으로 그대로 복구 가능하다.

`HEAD@{2}`는 2번 움직이기 전의 HEAD 위치라는 뜻이다.

원하는 경우 `git reflog`의 하위 명령어로 reflog를 관리할 수 있다.

- `expire`
  - expire 시간보다 오래된 항목들을 삭제한다.
  - 이 명령어를 직접 사용하는 것보다는 [git-gc](https://git-scm.com/docs/git-gc)를 사용하는 게 더 권장된다.

- `delete`
  - reflog에서 지정한 단일 항목을 삭제한다.
  - 삭제할 항목을 정확하게 지정해야 한다. (예: `git reflog delete master@{2}`)

- `exists`
  - ref에 reflog가 존재하는지 여부를 확인한다.
  - reflog가 존재하면 0, 존재하지 않으면 0이 아닌 상태값으로 종료된다.

---
참고

- <https://git-scm.com/docs/git-reflog>
