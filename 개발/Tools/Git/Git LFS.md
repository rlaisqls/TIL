Git LFS(Large File Storage)는 대용량 파일을 Git 저장소에서 효율적으로 관리하기 위한 Git 확장 도구이다.

Git은 모든 파일의 전체 히스토리를 로컬에 저장하는 분산 버전 관리 시스템이다. 그런데 바이너리 파일이나 대용량 미디어 파일처럼 크기가 큰 파일이 저장소에 포함되면, clone이나 fetch 시 모든 버전을 다운로드해야 하므로 저장소 크기가 급격히 커지고 속도가 느려진다. Git LFS는 이 문제를 해결한다.

Git LFS는 대용량 파일의 실제 콘텐츠를 별도의 원격 스토리지에 저장하고, Git 저장소에는 해당 파일을 가리키는 작은 **포인터 파일**만 커밋하는 것이다.

**예시**

```
version https://git-lfs.github.com/spec/v1
oid sha256:4d7a214614ab2935c943f9e0ff69d22eadbb8f32b1258daaa5e2ca24d17e2393
size 12345678
```

- **version**: LFS 포인터 스펙 버전
- **oid**: 실제 파일 콘텐츠의 SHA-256 해시
- **size**: 실제 파일의 바이트 크기

이 포인터 파일은 보통 150바이트 이하로, 수백 MB짜리 원본 파일 대신 저장소에 커밋된다.

## 동작 원리

Git LFS는 Git의 **clean/smudge 필터**와 **pre-push 훅**을 활용한다.

1. **git add (clean 필터)**: 파일을 스테이징할 때, LFS가 추적하는 파일이면 실제 콘텐츠를 로컬 LFS 캐시(`/.git/lfs/objects/`)에 저장하고, Git에는 포인터 파일만 스테이징한다.
2. **git commit**: 포인터 파일이 일반 커밋처럼 저장소에 기록된다. 실제 대용량 파일은 아직 로컬 LFS 캐시에만 존재한다.
3. **git push (pre-push 훅)**: push 시 LFS pre-push 훅이 실행되어, 새로 추가된 LFS 객체를 원격 LFS 스토어(GitHub LFS, GitLab LFS 등)에 업로드한다. Git 저장소 자체에는 포인터만 push된다.
4. **git clone/pull (smudge 필터)**: checkout 시 smudge 필터가 포인터 파일을 감지하고, 원격 LFS 스토어에서 실제 콘텐츠를 다운로드하여 워킹 디렉토리에 배치한다.

따라서 사용자 입장에서는 일반 파일과 동일하게 작업할 수 있지만, 내부적으로는 대용량 콘텐츠가 분리되어 관리된다.

## 설치 및 사용

**설치**

```bash
# macOS
brew install git-lfs

# Ubuntu/Debian
sudo apt install git-lfs

# 설치 후 초기화 (전역 설정, 최초 1회)
git lfs install
```

`git lfs install`은 `~/.gitconfig`에 clean/smudge 필터와 pre-push 훅을 등록한다.

**파일 추적 설정**

```bash
# 특정 확장자를 LFS로 추적
git lfs track "*.psd"
git lfs track "*.zip"
git lfs track "*.mp4"

# 특정 디렉토리의 모든 파일을 추적
git lfs track "assets/large/**"
```

이 명령은 `.gitattributes` 파일에 추적 규칙을 추가한다:

```
*.psd filter=lfs diff=lfs merge=lfs -text
*.zip filter=lfs diff=lfs merge=lfs -text
*.mp4 filter=lfs diff=lfs merge=lfs -text
```

`.gitattributes`는 반드시 커밋해야 다른 사용자도 동일한 LFS 설정을 공유할 수 있다.

**상태 확인**

```bash
# 현재 LFS로 추적 중인 패턴 확인
git lfs track

# LFS로 관리되는 파일 목록
git lfs ls-files

# LFS 환경 정보
git lfs env
```

## 명령어

- **`git lfs track <pattern>`**: 지정한 패턴의 파일을 LFS로 추적한다
- **`git lfs untrack <pattern>`**: LFS 추적을 해제한다
- **`git lfs ls-files`**: LFS로 관리되는 파일 목록을 출력한다
- **`git lfs fetch`**: 원격에서 LFS 객체를 다운로드한다 (checkout은 하지 않음)
- **`git lfs pull`**: fetch + checkout을 동시에 수행한다
- **`git lfs push`**: LFS 객체를 원격에 업로드한다
- **`git lfs migrate`**: 기존 커밋 히스토리의 파일을 LFS로 마이그레이션한다
- **`git lfs prune`**: 로컬 LFS 캐시에서 더 이상 필요 없는 오래된 객체를 삭제한다
- **`git lfs locks`**: 파일 잠금 상태를 확인한다
등등

## 기존 파일

이미 커밋된 대용량 파일을 LFS로 전환하려면 `git lfs migrate` 명령을 사용한다.

```bash
# 히스토리 전체에서 특정 확장자를 LFS로 마이그레이션
git lfs migrate import --include="*.psd" --everything

# 특정 브랜치 범위만 마이그레이션
git lfs migrate import --include="*.zip" --include-ref=refs/heads/main
```

이 명령은 Git 히스토리를 재작성하므로 force push가 필요하다. 팀에서 사용 중인 저장소라면 반드시 사전에 합의한 후 진행해야 한다.

반대로 LFS에서 일반 Git 객체로 되돌리려면:

```bash
git lfs migrate export --include="*.psd" --everything
```

## 파일 잠금

Git LFS는 바이너리 파일의 동시 편집 충돌을 방지하기 위한 **파일 잠금(File Locking)** 기능을 제공한다. 바이너리 파일은 텍스트처럼 diff/merge가 불가능하므로, 두 사람이 동시에 수정하면 한쪽의 작업이 유실될 수 있다. 잠금을 사용하면 이를 방지할 수 있다.

```bash
# 파일 잠금
git lfs lock assets/model.psd

# 잠금 목록 확인
git lfs locks

# 잠금 해제
git lfs unlock assets/model.psd

# 다른 사용자의 잠금을 강제 해제 (관리자)
git lfs unlock assets/model.psd --force
```

`.gitattributes`에서 lockable 속성을 설정하면, 잠금하지 않은 LFS 파일을 읽기 전용으로 만들어 실수로 편집하는 것을 방지할 수 있다:

```
*.psd filter=lfs diff=lfs merge=lfs -text lockable
```

## 용량 및 비용

Git LFS는 호스팅 서비스에 따라 스토리지와 대역폭 제한이 있다.

- **GitHub**: 무료 계정 기준 1GB 스토리지, 월 1GB 대역폭. 추가 Data Pack 구매 가능 ($5/월당 50GB 스토리지 + 50GB 대역폭)
- **GitLab**: 프로젝트당 10GB (Self-hosted는 설정에 따라 다름)
- **Bitbucket**: 무료 계정 기준 1GB, 유료 플랜에서 확장 가능

대역폭은 clone, fetch, pull 시 LFS 객체를 다운로드할 때 소모된다. CI/CD 파이프라인이 매번 clone하는 환경에서는 대역폭 소모가 빠르게 증가할 수 있으므로, `GIT_LFS_SKIP_SMUDGE=1`로 LFS 다운로드를 건너뛰거나 필요한 파일만 선택적으로 fetch하는 전략이 필요하다.

```bash
# CI에서 LFS 다운로드 건너뛰기
GIT_LFS_SKIP_SMUDGE=1 git clone <repo-url>

# 필요한 파일만 선택적으로 가져오기
git lfs fetch --include="path/to/needed/**"
git lfs checkout
```

## 주의

- `.gitattributes`를 먼저 커밋한 후 대용량 파일을 추가해야 한다. 순서가 반대이면 파일이 일반 Git 객체로 저장된다.
- LFS 서버가 다운되면 실제 파일 콘텐츠에 접근할 수 없다. 포인터 파일만 checkout된다.
- `git lfs migrate`로 히스토리를 재작성하면 모든 커밋 해시가 변경된다.
- shallow clone(`--depth`)과 LFS를 함께 사용할 때는 `git lfs fetch --recent` 옵션을 활용하면 최근 커밋의 LFS 객체만 가져올 수 있다.
- Git LFS로 추적되는 파일은 GitHub 웹 UI에서 diff를 볼 수 없다.

---
참고

- <https://git-lfs.com/>
- <https://github.com/git-lfs/git-lfs/blob/main/docs/spec.md>
- <https://docs.github.com/en/repositories/working-with-files/managing-large-files/about-git-large-file-storage>
