
NFS(Network File System)는 네트워크를 통해 원격 서버의 파일시스템을 로컬처럼 사용할 수 있게 해주는 분산 파일시스템 프로토콜이다.

클라이언트에서 `/mnt/nfs/file.txt`를 열면, 커널의 VFS가 이를 NFS 모듈로 위임하고, NFS 모듈이 RPC를 통해 서버에 요청을 보낸다. 애플리케이션 입장에서는 로컬 파일과 완전히 동일한 시스템콜(`open`, `read`, `write`)을 사용한다.

## 마운트

NFS 마운트는 클라이언트가 서버의 특정 디렉토리를 자신의 경로에 연결하는 과정이다.

```bash
# nfs-client에서 실행
sudo apt install -y nfs-common
sudo mkdir -p /mnt/nfs
sudo mount -t nfs nfs-server.orb.local:/export/share /mnt/nfs
```

`-t nfs`는 파일시스템 타입을 지정하는 옵션이다. 커널에는 ext4, XFS, NFS 등 여러 파일시스템 모듈이 있고, `-t`로 어떤 모듈을 사용할지 알려준다. `-t nfs`를 지정하면 mount는 직접 처리하지 않고 `/sbin/mount.nfs` 헬퍼를 호출한다. 네트워크 파일시스템은 자동 감지가 안 되므로 반드시 명시해야 한다.

**마운트 시 일어나는 일**

1. `mount -t nfs` → `/sbin/mount.nfs` 헬퍼 호출
2. 서버 2049 포트로 TCP 연결
3. NFS RPC 교환 (`EXCHANGE_ID` → `CREATE_SESSION` → `PUTROOTFH` → `LOOKUP` → `GETATTR`/`FSINFO`)
4. 서버가 file handle(fh) 발급
5. 커널에 마운트 등록, VFS에 super_block 생성
6. `/mnt/nfs` 경로가 NFS 파일시스템에 연결

이 시점부터 `/mnt/nfs` 하위의 모든 파일 접근은 VFS → NFS 모듈로 위임된다.

**마운트 옵션**

- **vers=4.2**: 서버와 자동 협상된 최신 버전
- **rsize/wsize=1048576**: 한 번의 RPC로 전송하는 최대 크기 1MB
- **hard**: 서버 무응답 시 무한 재시도
- **timeo=600**: RPC 타임아웃 60초 (단위 0.1초)
- **sec=sys**: UID/GID 기반 인증

옵션을 생략하면 커널 기본값이 적용된다.

```bash
# 옵션 생략 (커널 기본값)
sudo mount -t nfs nfs-server.orb.local:/export/share /mnt/nfs

# 옵션 명시 (AWS 권장값)
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-xxx.efs.amazonaws.com:/ efs
```

로컬 마운트와 AWS EFS 마운트의 차이를 보면:

- **옵션**: 로컬은 생략(기본값과 동일), AWS는 명시적 지정
- **NFS 버전**: 로컬은 4.2(자동 협상), EFS는 4.1(EFS 최대)
- **noresvport**: 로컬은 불필요, AWS는 필수(AZ failover 시 재연결)
- **export 경로**: 로컬은 특정 디렉토리, EFS는 `/`(파일시스템 전체)

## VFS와 NFS의 동작

NFS는 VFS 뒤에서 동작하는 파일시스템 중 하나이다. ext4가 블록 I/O 계층을 통해 로컬 디스크에 접근하는 것처럼, NFS는 RPC를 통해 원격 서버에 접근한다. VFS 핵심 객체인 super_block과 inode가 NFS에서는 어떻게 다르게 동작하는지 살펴보자.

**super_block**

super_block은 마운트된 파일시스템 하나의 메타데이터를 담는 커널 자료구조이다. 파일시스템을 마운트하면 커널이 super_block을 생성하고, 그 파일시스템에 대한 전반적인 정보를 저장한다. 핵심 역할은 VFS가 파일 연산을 받았을 때 **어떤 파일시스템의 어떤 구현을 호출해야 하는지** 연결해주는 것이다.

로컬 파일시스템(ext4 등)의 super_block은 디스크 블록 크기, 전체 블록/inode 수 같은 물리적 정보를 담지만, NFS super_block은 서버 주소, FSID, 프로토콜 버전 같은 네트워크 연결 정보를 담는다.

NFS super_block에 블록 크기가 없는 이유는, NFS 클라이언트가 디스크를 관리하지 않기 때문이다. 블록 할당은 전부 서버가 하고, 클라이언트가 실제로 필요한 건 네트워크로 한 번에 얼마나 보내고 받을지(rsize/wsize)뿐이다. 물리적 저장을 하지 않으니 디스크 블록 크기라는 개념 자체가 없다.

nfs-client에서 NFS super_block 정보를 확인할 수 있다.

```bash
cat /proc/fs/nfsfs/servers    # 어떤 NFS 서버에 연결되어 있는가
cat /proc/fs/nfsfs/volumes    # 그 서버에서 어떤 볼륨을 마운트했는가
```

```
servers:
  NV SERVER                              PORT USE HOSTNAME
  v4 fd07b51acc660000cafe000000000004      801   1 nfs-server.orb.local

volumes:
  NV SERVER                              PORT DEV   FSID                       FSC
  v4 fd07b51acc660000cafe000000000004      801 0:87  60e24db6ae6bb9fb:0          no
```

**inode**

inode는 파일 하나의 메타데이터(파일 크기, 소유자, 권한, 타임스탬프, 데이터 블록 위치)를 담는 자료구조이다. 파일 이름은 inode에 없고, 디렉토리가 `(파일명 → inode 번호)` 매핑을 들고 있다.

NFS에서 클라이언트와 서버의 inode를 비교해보면:

```
클라이언트:   Device: 57h/87d   Inode: 27634964   IO Block: 1048576
서버:        Device: 26h/38d   Inode: 27634964   IO Block: 4096
```

inode 번호(27634964)가 같은 이유는, NFS 클라이언트가 자체적으로 inode 번호를 만들지 않기 때문이다. 서버가 `GETATTR` RPC 응답에 `fileid`라는 값을 보내주면, 클라이언트는 이를 그대로 inode 번호로 사용한다. 실제 파일의 원본은 서버 디스크에 하나만 존재하고 클라이언트는 네트워크로 참조하는 것이므로, 서버의 fileid를 그대로 쓰는 게 자연스럽다.

다만 항상 같은 것은 아니다. 서버가 64비트 fileid를 쓰는데 클라이언트가 32비트면 잘려서 달라질 수 있고, NFS gateway를 경유하면 재매핑될 수도 있다.

달라지는 값들도 있다.

- **Device**: 서버는 실제 블록 디바이스 번호, 클라이언트는 커널이 부여한 가상 디바이스 번호이다. 파일 식별은 `(Device + Inode)` 쌍이므로, Device가 다른 건 자연스럽다.
- **IO Block**: 서버는 디스크 블록 크기(4KB), 클라이언트는 NFS rsize(1MB)이다. 클라이언트의 IO Block은 디스크 블록이 아니라 rsize 값이 표시된 것이다.

## File Handle과 Inode

NFS에서 네트워크 너머의 파일을 식별하기 위해서는 inode 번호만으로는 부족하다. 이를 보완하기 위해 file handle과 generation이라는 개념이 존재한다.

**File Handle vs Inode Number**

- **inode number**: 로컬 파일시스템 내에서 파일을 식별하는 숫자 하나이다. 비유하면 "방 번호"에 해당한다.
- **file handle**: `fsid + inode number + generation`으로 구성되며, 네트워크 너머에서 파일을 식별하는 데 사용된다. 비유하면 "방 번호 + 건물 주소 + 발급 시점"에 해당한다.

inode number만으로는 어떤 파일시스템의 어떤 파일인지 네트워크 너머에서 특정할 수 없으므로, file handle이 이를 감싸는 구조이다.

**inode number와 generation**

inode number는 파일이 삭제되면 재사용된다. 이때 문제가 발생한다.

```
1. 파일 A 생성 → inode 100 할당
2. 클라이언트가 file handle 획득 (inode=100 포함)
3. 파일 A 삭제 → inode 100 반환
4. 파일 B 생성 → inode 100 재할당
5. 클라이언트가 기존 file handle로 접근 → inode 100 → 파일 B에 접근?
```

inode 번호만으로는 같은 100번이 원래 그 파일인지, 새로 만든 다른 파일인지 구별할 수 없다. generation은 이 문제를 해결한다. inode가 할당될 때마다 generation이 증가한다.

```
파일 A: inode=100, generation=5
파일 B: inode=100, generation=6
```

file handle에는 `(fsid + inode + generation)` 세 값이 들어있으므로:

```
클라이언트의 file handle: inode=100, generation=5
서버의 현재 상태:         inode=100, generation=6
→ 불일치 → ESTALE 에러 반환
```

정리하면, inode number는 "몇 번 방인가"를 나타내고, generation은 "몇 번째 입주자인가"를 나타낸다. generation 덕분에 같은 inode 번호가 재사용되더라도 이전 파일과 새 파일을 안전하게 구별할 수 있다.

---
참고

- https://www.kernel.org/doc/html/latest/filesystems/nfs/index.html
- https://datatracker.ietf.org/doc/html/rfc7530 (NFSv4)
- https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html
