Lustre는 대규모 HPC(High Performance Computing) 환경에서 사용되는 병렬 분산 파일시스템이다. 수천 개의 클라이언트가 동시에 접근하는 대용량 스토리지를 제공하며, 슈퍼컴퓨터 클러스터나 AI 학습 인프라에서 자주 사용된다.

## 구성 요소

- **MDS(Metadata Server)**: 파일/디렉토리 메타데이터(inode, 권한, 이름) 관리
- **OSS(Object Storage Server)**: 실제 파일 데이터를 저장하는 스토리지 서버
- **MGS(Management Server)**: Lustre 설정 정보 저장
- **클라이언트**: `lustre` 커널 모듈을 통해 마운트

파일 데이터는 여러 OSS에 걸쳐 stripe(분산) 저장되고, 메타데이터는 MDS가 별도로 관리한다.

## 마운트

```bash
# 커널 모듈 로드
sudo modprobe lustre

# 마운트
sudo mount -t lustre mgs-server@tcp:/fsname /mnt/lustre

# 확인
df -h /mnt/lustre
lctl dl   # Lustre 디바이스 목록
```

`-t lustre`를 지정하면 커널이 `/sbin/mount.lustre` 헬퍼를 호출한다. NFS와 달리 Lustre는 MGS를 통해 설정을 받아오므로 마운트 시 MGS 주소가 필요하다.

**마운트 시 일어나는 일**

1. `mount.lustre` 헬퍼가 MGS에 접속해 파일시스템 설정 수신
2. MDS에서 루트 디렉토리 메타데이터 획득
3. OSS 목록과 연결 확인
4. 커널 VFS에 마운트 등록

## 디렉토리 권한

Lustre는 기본적으로 POSIX 표준 권한 모델을 따른다.

```bash
# 일반 권한 설정 (표준 chmod/chown과 동일)
chmod 755 /mnt/lustre/mydir
chown user:group /mnt/lustre/mydir

# setgid 비트: 하위 파일이 부모 디렉토리의 그룹을 상속
chmod g+s /mnt/lustre/shared
```

**Lustre ACL**

Lustre는 POSIX ACL을 지원한다. 마운트 시 `acl` 옵션을 줘야 활성화된다.

```bash
sudo mount -t lustre -o acl mgs-server@tcp:/fsname /mnt/lustre
```

```bash
# ACL 설정
setfacl -m u:alice:rwx /mnt/lustre/project
setfacl -m g:devteam:rx /mnt/lustre/project

# ACL 확인
getfacl /mnt/lustre/project

# 기본 ACL (하위 파일/디렉토리에 자동 적용)
setfacl -d -m u:alice:rwx /mnt/lustre/project
```

**UID/GID 매핑**

클라이언트와 서버의 UID/GID가 일치해야 권한이 올바르게 적용된다. HPC 환경에서는 보통 LDAP이나 NIS로 UID를 통일한다. 불일치 시 파일 소유자가 `nobody`로 보이거나 접근이 거부된다.

## 스트라이프 설정

Lustre의 특징적인 기능으로, 파일 데이터를 여러 OSS에 분산 저장해 대역폭을 높인다.

```bash
# 현재 스트라이프 확인
lfs getstripe /mnt/lustre/myfile

# 디렉토리에 스트라이프 설정 (하위 파일에 상속)
lfs setstripe -c 4 /mnt/lustre/project   # OST 4개에 분산
lfs setstripe -s 1M /mnt/lustre/project  # 스트라이프 크기 1MB

# 파일 생성 시 스트라이프 지정
lfs setstripe -c 8 -s 4M /mnt/lustre/bigfile.dat
```

- `-c`: stripe count (사용할 OST 수, `-1`이면 전체 OST 사용)
- `-s`: stripe size (각 OST에 한 번에 쓰는 청크 크기)

권한 설정처럼 디렉토리에 스트라이프를 설정하면 하위에 생성되는 파일이 자동으로 해당 설정을 상속한다.

## 프로젝트 쿼터

Lustre는 사용자/그룹 쿼터 외에 디렉토리 단위로 용량을 제한하는 프로젝트 쿼터를 지원한다.

```bash
# 프로젝트 ID 할당
lfs project -p 100 -r /mnt/lustre/team-a

# 쿼터 설정 (MDS에서 실행)
lctl set_param qmt.*.md-0x0.glb-prj='projid=100 hardlimit=1T softlimit=900G'

# 사용량 확인
lfs quota -p 100 /mnt/lustre
```

## 주요 lfs 명령어

```bash
lfs df /mnt/lustre           # 전체 OST 사용량
lfs df -i /mnt/lustre        # inode 사용량 (MDS 기준)
lfs find /mnt/lustre -type f -size +1G   # 대용량 파일 검색
lfs check all                # MDS/OSS 상태 확인
```

---
참고

- https://wiki.lustre.org/Lustre_Wiki
- https://doc.lustre.org/lustre_manual.xhtml
- https://www.kernel.org/doc/html/latest/filesystems/lustre.html
