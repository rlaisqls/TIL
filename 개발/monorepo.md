
lerna: 각 패키지들을 배포하고 버전 관리하는 역할
yarn: 각 패키지간의 의존성 관리 하는 역할
여기서 yarn workspaces 만으로 구성하지 않는 이유는, 여러 개의 패키지를 용이하게 관리 할 수 있는 CLI 명령어 (publish, version 등)는 Lerna에서 많이 제공 되고 있기 때문입니다.

반면에 패키지 관리는 yarn으로 하는 이유는 다음과 같습니다.

    npm은 모노레포를 지원하지 않음
        yarn 은 yarn workspaces 를 추가적인 라이브러리 설치 없이 쉬운 방법으로 제공
    yarn workspaces 가 불필요하게 lerna bootstrap 등의 명령을 실행하지 않으면서 더 안전하고 깔끔하게 패키지를 관리

<https://simsimjae.medium.com/monorepo-lerna-yarn-workspace-%ED%81%AC%EA%B2%8C-%EA%B0%9C%EB%85%90%EB%A7%8C-%EC%9E%A1%EC%95%84%EB%B3%B4%EA%B8%B0-c58bc4ba31fe>
<https://jojoldu.tistory.com/594>
<https://blog.webudding.com/nest-js%EC%9D%98-monorepo-%EC%82%AC%EC%9A%A9%EA%B8%B0-528514372b4a>

---

front는 turborepo

---
<https://docs.nestjs.com/cli/monorepo>

NestJS에서는 CLI로 모노레포 구성을 지원한다.
