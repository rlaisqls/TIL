
Git Flow 는 2010년 Vincent Driessen 이 작성한 블로그 글을 통해 유명해지기 시작한 Git Branching Model중 하나로, Git의 사용 방법론이다. GitFlow는 프로젝트를 런칭한 이후에도 코드를 관리하기 용이하게 하고, 프로젝트에서 발생하는 다영한 워크플로우의 구현이 가능하기 떄문에 많은 개발자들이 사용하는 방법론으로 자리잡게 되었다. 에디터와 IDE에서 플러그인으로 지원하는 경우도 많다.

브랜치의 종류가 많아 복잡하고, release와 master의 구분이 모호하기도 하지만 프로젝트의 규모가 커지면 커질수록 소스코드를 관리하기에 용이하다는 장점이 있다.

<br>
<img src="https://techblog.woowahan.com/wp-content/uploads/img/2017-10-30/git-flow_overall_graph.png">

---

## GitFlow의 브랜치

Git Flow는 크게 5개의 branch 를 사용한다. 그중 가장 중심이 되는 브랜치는 Main 브랜치인 `master`와 `develop`브랜치이고, 나머지인 `feature`, `release`, `hotfix` 브랜치는 중간 과정을 보조하는 역할을 한다.

- ### feature
    각각의 기능 구현을 담당하는 브랜치이다. 주로 `feature/{구현기능명}`과 같은 명칭으로 생성되며, develop 브랜치로 머지된다. 머지된 후에는 해당 브랜치가 삭제된다. 

- ### develop 
    develop 브랜치는 말 그대로 개발을 진행하는 브랜치이다. 하나의 feature 브랜치가 머지될 때마다 develop 브랜치에 해당 기능이 추가된다. develop 브랜치는 배포할 수준의 기능을 갖추면 release 브랜치로 머지된다.

- ### release
    개발된 내용을 배포하기 위해 준비하는 브랜치이다. develop 브랜치에서 개발한 기능이 합쳐져 relese 브랜치가 생성되고, 검토 후에는 master 브랜치로 머지한다.

- ### hotfix
    배포된 소스에서 버그가 발생하면 생성되는 브랜치이다.  release 브랜치를 거쳐 한차례 버그 검사를 했지만 예상치 못하게 배포 후에 발견된 버그들에 대해서 빠르게 수정하기 위해 만들어진다. 수정이 완료되면 develop 브랜치, release 브랜치와 marster 브랜치에 수정사항을 반영한다.

- ### master
    바로 배포되어 사용 가능한 (production-ready) 상태를 가지고 있는 브랜치이다. 최종적으로 배포될 코드가 있기 때문에, 프로젝트의 중심이 된다.
