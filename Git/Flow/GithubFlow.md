
GitFlow의 브랜치 전략의 복잡한 부분을 생략하여 간략화한 브랜치 전략이다. github flow는 master 브랜치 하나만을 가지고 진행하는 방식이다.

<br>
<img src="https://user-images.githubusercontent.com/43775108/125813582-d1500c51-e1af-44e7-9f90-83901dfec03f.png">
<br>

GitHub Flow는 `master`와 `feature`, 두개의 브랜치로 나뉜다.

Github Flow의 개발 과정은 다음과 같다.

1. master 브랜치에서 개발이 시작된다.
2. 기능이나 버그에 대해 issue를 작성한다.
3. 팀원들이 issue 해결을 위해 master 브랜치에서 생성한 `feature/{구현기능}` 브랜치에서 개발을 진행하고 커밋한다.
4. 개발한 코드를 master 브랜치에 병합할 수 있도록 요청을 보낸다.
    즉, **pull request**를 날린다.
5. pull request를 통해 팀원들간에 피드백을 주고받거나 버그를 찾는다. 
6. 모든 리뷰가 이뤄지면 테스트를 진행한 후 master 브랜치에 머지한다.

github flow는 시시각각 master에 머지될 때마다 배포가 이루어지는 것이 좋다. 따라서 CI/CD를 통한 배포 자동화를 적용하는 것이 좋다.

pull request에서 충분한 리뷰와 피드백이 진행되지 않으면 배포된 코드에서 버그가 발생할 수 있으므로 주의해야한다.