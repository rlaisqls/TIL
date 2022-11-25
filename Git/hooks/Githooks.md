# 🌳 Githooks

Git에서는 어떤 이벤트가 생겼을 때 자동으로 특정 스크립트를 실행하도록 할 수 있다. 이 훅은 클라이언트 훅과 서버 훅으로 나눌 수 있는데, 클라이언트 훅은 커밋이나 Merge 할 때 실행되고 서버 훅은 Push 할 때 서버에서 실행된다. 

프로젝트의 `.git/hooks` 폴더에 들어가서 해당 훅의 이름을 파일명으로 쉘스크립트를 작성하면, 해당 훅이 특정 상황에 자동으로 실행된다. 

<img width="776" alt="image" src="https://user-images.githubusercontent.com/81006587/203177263-6763519c-e0d9-4dc0-a1e7-d9ea1b529de1.png">

분류에 따른 훅은 아래 표와 같다.​

### Commit workflow hook

|훅|설명|
|-|-|
|pre-commit|commit 을 실행하기 전에 실행|
|prepare-commit-msg|commit 메시지를 생성하고 편집기를 실행하기 전에 실행|
|commit-msg|commit 메시지를 완성한 후 commit 을 최종 완료하기 전에 실행|
|post-commit|commit 을 완료한 후 실행|

### Email workflow hook

|훅|설명|
|-|-|
|applypatch-msg|git am 명령 실행 시 가장 먼저 실행|
|pre-applypatch|patch 적용 후 실행하며, patch 를 중단시킬 수 있음|
|post-applypatch|git am 명령에서 마지막으로 실행하며, patch 를 중단시킬 수 없음|

### 기타

|훅|설명|
|-|-|
|pre-rebase|Rebase 하기 전에 실행|
|post-rewrite|git commit –amend, git rebase 와 같이 커밋을 변경하는 명령을 실행한 후 실행
|post-merge|Merge 가 끝나고 나서 실행|
|pre-push|git push 명령 실행 시 동작하며 리모트 정보를 업데이트 하고 난 후 리모트로 데이터를 전송하기 전에 실행. push 를 중단시킬 수 있음|
