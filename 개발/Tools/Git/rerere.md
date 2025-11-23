git rerere는 비교적 장기간 유지되는 토픽 브랜치를 사용하는 워크플로우에서 동일한 충돌을 반복적으로 해결해야 하는 문제를 해결하기 위한 도구이다. 토픽 브랜치가 "release" 브랜치에 병합되거나 업스트림에 전송되어 승인될 때까지, 개발자는 종종 같은 충돌을 여러 번 해결해야 한다.

이 명령어는 최초 수동 병합 시 충돌이 발생한 자동 병합 결과와 그에 대응하는 수동 해결 결과를 기록하고, 이후 동일한 충돌이 발생했을 때 이전에 기록된 해결 방법을 자동으로 적용한다.

> **주의**: 이 명령어를 사용하려면 `rerere.enabled` 설정 변수를 활성화해야 한다.

---

## 명령어

일반적으로 `git rerere`는 인자 없이 또는 사용자 개입 없이 실행된다. 하지만 작업 상태와 상호작용할 수 있는 여러 명령어를 제공한다.

- **clear**: 병합 해결을 중단할 때 rerere가 사용하는 메타데이터를 초기화한다. `git am [--skip|--abort]` 또는 `git rebase [--skip|--abort]`를 호출하면 자동으로 이 명령어가 실행된다.

- **forget `<pathspec>`**: `<pathspec>`의 현재 충돌에 대해 rerere가 기록한 충돌 해결 정보를 초기화한다.

- **diff**: 현재 해결 상태의 diff를 표시한다. 사용자가 충돌을 해결하는 동안 변경된 내용을 추적하는 데 유용하다. 추가 인자는 PATH에 설치된 시스템 diff 명령어에 직접 전달된다.

- **status**: rerere가 병합 해결을 기록할 충돌이 있는 경로를 출력한다.

- **remaining**: rerere에 의해 자동 해결되지 않은 충돌이 있는 경로를 출력한다. 여기에는 충돌하는 서브모듈과 같이 rerere가 추적할 수 없는 해결 방법이 포함된다.

- **gc**: 오래 전에 발생한 충돌 병합 기록을 정리한다. 기본적으로 15일 이상 된 미해결 충돌과 60일 이상 된 해결된 충돌이 정리된다. 이러한 기본값은 각각 `gc.rerereUnresolved`와 `gc.rerereResolved` 설정 변수로 제어할 수 있다.

---

## 동작 원리

토픽 브랜치가 master 브랜치(또는 업스트림)에서 분기된 이후 master가 수정한 영역을 토픽 브랜치에서도 수정했다면, 토픽 브랜치가 업스트림에 푸시되기 전에 최신 master로 테스트하고 싶을 수 있다:

```
              o---*---o topic
             /
    o---o---o---*---o---o master
```

이러한 테스트를 위해서는 master와 topic을 어떻게든 병합해야 한다. 한 가지 방법은 master를 토픽 브랜치로 pull하는 것이다:

```bash
git switch topic
git merge master
```

```
              o---*---o---+ topic
             /           /
    o---o---o---*---o---o master
```

`*`로 표시된 커밋들은 동일한 파일의 동일한 영역을 수정한다. `+`로 표시된 커밋을 생성할 때 충돌을 해결해야 한다. 그런 다음 결과를 테스트하여 진행 중인 작업이 최신 master와 여전히 잘 작동하는지 확인할 수 있다.

이 테스트 병합 이후, 토픽에서 작업을 계속하는 두 가지 방법이 있다. 가장 쉬운 방법은 테스트 병합 커밋 `+` 위에 계속 작업하고, 토픽 브랜치의 작업이 최종적으로 완료되면 토픽 브랜치를 master로 pull하거나 업스트림에 pull을 요청하는 것이다. 하지만 그때까지 master 또는 업스트림이 테스트 병합 `+` 이후로 진행되었을 수 있으며, 이 경우 최종 커밋 그래프는 다음과 같다:

```bash
git switch topic
git merge master
... work on both topic and master branches
git switch master
git merge topic
```

```
              o---*---o---+---o---o topic
             /           /         \
    o---o---o---*---o---o---o---o---+ master
```

하지만 토픽 브랜치가 장기간 유지되면, 토픽 브랜치에 많은 "Merge from master" 커밋이 생겨 불필요하게 개발 히스토리가 복잡해진다. Linux 커널 메일링 리스트 독자들은 Linus가 "쓸모없는 병합"으로 가득 찬 브랜치에서 pull을 요청한 서브시스템 관리자에게 너무 잦은 테스트 병합에 대해 불평했던 것을 기억할 것이다.

대안으로, 토픽 브랜치를 테스트 병합으로부터 깨끗하게 유지하려면, 테스트 병합을 제거하고 테스트 병합 이전의 tip 위에 계속 작업할 수 있다:

```bash
git switch topic
git merge master
git reset --hard HEAD^ ;# rewind the test merge
... work on both topic and master branches
git switch master
git merge topic
```

```
              o---*---o-------o---o topic
             /                     \
    o---o---o---*---o---o---o---o---+ master
```

- 이렇게 하면 토픽 브랜치가 최종적으로 준비되어 master 브랜치에 병합될 때 하나의 병합 커밋만 남게 된다.이 병합은 `*`로 표시된 커밋들이 도입한 충돌을 해결해야 한다. 하지만 이 충돌은 종종 제거한 테스트 병합을 생성할 때 해결했던 것과 동일한 충돌이다. git rerere는 이전의 수동 해결 정보를 사용하여 최종 컨플릭트를 해결하는 데 도움을 준다.

- 충돌이 발생한 자동 병합 직후 `git rerere` 명령어를 실행하면, 일반적인 충돌 마커 `<<<<<<<`, `=======`, `>>>>>>>`가 포함된 충돌 상태의 작업 트리 파일이 기록된다. 나중에 충돌 해결을 완료한 후 `git rerere`를 다시 실행하면 이러한 파일의 해결된 상태가 기록된다. master를 토픽 브랜치에 테스트 병합할 때 이렇게 했다고 가정하자.

- 다음번에 동일한 충돌이 발생한 자동 병합을 보면, `git rerere`를 실행할 때 이전의 충돌 자동 병합, 이전의 수동 해결, 현재의 충돌 자동 병합 사이에서 3-way 병합을 수행한다. 이 3-way 병합이 깔끔하게 해결되면, 결과가 작업 트리 파일에 기록되므로 수동으로 해결할 필요가 없다. 단, `git rerere`는 인덱스 파일은 그대로 두므로, 만족스러우면 `git diff`(또는 `git diff -c`)와 `git add`로 최종 검사를 수행해야 한다.

- 편의를 위해, `git merge`는 자동 병합 실패로 종료될 때 자동으로 `git rerere`를 호출하고, `git rerere`는 새로운 충돌일 때는 수동 해결을 기록하고 그렇지 않으면 이전의 수동 해결을 재사용한다. `git commit`도 병합 결과를 커밋할 때 `git rerere`를 호출한다. 즉, `rerere.enabled` 설정 변수를 활성화하는 것 외에는 특별히 할 일이 없다는 의미이다.

- `git rerere`가 기록한 정보는 `git rebase`를 실행할 때도 사용된다.

    ```
                o---*---o-------o---o topic
                /
        o---o---o---*---o---o---o---o   master
    ```

    ```bash
    git rebase master topic
    ```

    ```
        o---*---o-------o---o topic
        /
        o---o---o---*---o---o---o---o   master
    ```

- 토픽이 업스트림으로 전송될 준비가 되기 전에 최신 상태로 업데이트하기 위해 `git rebase master topic`을 실행할 수 있다. 이는 3-way 병합으로 돌아가며, 이전에 해결한 테스트 병합과 같은 방식으로 충돌한다. `git rerere`가 `git rebase`에 의해 실행되어 이 충돌을 해결하는 데 도움을 준다.

> **참고**: `git rerere`는 파일의 충돌 마커에 의존하여 충돌을 감지한다. 파일에 이미 충돌 마커와 동일하게 보이는 줄이 포함되어 있으면, `git rerere`가 충돌 해결을 기록하지 못할 수 있다. 이를 해결하려면 gitattributes[5]의 `conflict-marker-size` 설정을 사용할 수 있다.

---
참고

- <https://scottchacon.com/2010/03/08/rerere>
- <https://git-scm.com/docs/git-rerere.html>
- <https://stackoverflow.com/questions/7241678/how-to-prevent-many-git-conflicts-when-rebasing-many-commits>
