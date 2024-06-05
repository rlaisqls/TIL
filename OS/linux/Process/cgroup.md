
cgroup은 Control group의 약자로, 커널에서 프로세스를 계층적 그룹으로 합쳐 관리하기 위한 기능이다. cgroup을 통해 해당 그룹이 사용할 수 있는 CPU, memory를 제한하는 등의 제어를 할 수 있다.

### cgroup 설정 방법

cgroup는 `/sys/fs/cgroup` 하위의 파일로 정의된다. cgroup은 오직 프로세스(태스크)들을 그룹화 하는 역할만 하며 내부적으로 자원을 제한하거나 할당하는 역할은 서브시스템에서 수행한다.

cgroup 설정을 수정하기 위해선 cgroup 가상파일시스템을 마운트하여 파일 및 디렉토리를 직접 조작하거나, 사용자 도구(Debian, ubuntu는 cgroup-bin/RHEL, CentOS는 libcgroup)를 사용할 수 있다.
  
### 서브시스템

서브시스템은 cgroup에서 접근을 제한할 수 있는 단위, 개념이다. CPU, memory 외에도 커널 버전에 따라 여러 종류의 서브 시스템이 있다.

- `cpu`: 스케줄러를 이용해 cgroup에 속한 프로세스의 CPU 사용시간을 제어하는 서브시스템이다. 이 서브시스템은 CPU에 cgroup 작업 액세스를 제공하기 위한 스케줄러를 제공한다. ([문서](https://www.kernel.org/doc/Documentation/scheduler/sched-design-CFS.txt))
- `cpuacct`: 프로세스 그룹 별 CPU 자원 사용에 대한 분석 통계를 생성 및 제공한다. ([문서](https://www.kernel.org/doc/Documentation/cgroup-v1/cpuacct.txt))
- `cpusets`: 개별 CPU 및 메모리 노드를 cgroup에 바인딩 하기 위해 사용하는 서브시스템이다. ([문서](https://www.kernel.org/doc/Documentation/cgroup-v1/cpusets.txt)) 
- `memory`: cgroup에 속한 프로세스의 메모리 사용량 제어하는 서브 시스템이다. ([문서](https://www.kernel.org/doc/Documentation/cgroup-v1/memory.txt))
- `blkio`: 특정 block device에 대한 접근을 제한하거나 제어하기 위한 서브시스템이다. block device에 대한 IO 접근 제한을 설정할 수 있다. ([문서](https://www.kernel.org/doc/Documentation/cgroup-v1/blkio.txt))
- `devices`: cgroup의 작업 단위로 device에 대한 접근을 허용하거나 제한한다. whitelist와 blacklist로 명시되어 있다. ([문서](https://www.kernel.org/doc/Documentation/cgroup-v1/devices.txt))
- `freezer`: cgroup의 작업을 일시적으로 정지(suspend)하거나 다시 시작(restore)할 수 있다. ([문서](https://www.kernel.org/doc/Documentation/cgroup-v1/pids.txt))
- `net_cls`: 특정 cgroup 작업에서 발생하는 패킷을 식별하기 위한 태그(classid)를 지정할 수 있다. 이 태그는 방화벽 규칙으로 사용되어 질 수 있다. ([문서](https://www.kernel.org/doc/Documentation/cgroup-v1/net_cls.txt))
- `net_prio`: cgroup 작업에서 생성되는 네트워크 트래픽의 우선순위를 선정할 수 있다. ([문서](https://www.kernel.org/doc/Documentation/cgroup-v1/net_prio.txt))
- `pid`: cgroup 작업에서 생성되는 프로세스의 수를 제한할 수 있다. ([문서](https://www.kernel.org/doc/Documentation/cgroup-v1/pids.txt))

### v1, v2

<img src="https://github.com/rlaisqls/TIL/assets/81006587/25a2ce90-0084-46b8-a6d2-1585f98753d2" style="height: 300px"/>

Cgroup은 두 가지 버전으로 나눠지며, 두 버전은 위 그림처럼 계층 구조가 다르다.

- cgroupv1 : control 대상이 되는 리소스들을 기준으로 control 그룹들을 나눔
- cgroupv2 : control 대상이 되는 워크로드들을 기준으로 control 그룹들을 나눔

### 커널 구현

Control Groups는 커널에 아래와 같은 영향을 준다.

- 각 시스템의 작업(task)마다 `css_set`에 대한 참조 카운트된 포인터가 있다.
- `css_set`은 시스템에 등록된 각 cgroup 서브시스템에 대한 참조 카운트된 포인터 세트를 포함하며, 이는 `cgroup_subsys_state` 객체로 구성된다. 
    
    작업에서 각 계층의 cgroup 멤버를 직접적으로 연결하는 링크는 없지만, `cgroup_subsys_state` 객체를 통해 포인터를 따라가면 이를 확인할 수 있다. 이는 서브시스템 상태에 접근하는 것이 빈번하고 성능에 예민한 반면, 작업의 실제 cgroup 할당(특히 cgroup 간 이동)이 필요한 작업은 덜 빈번하기 때문이다.
    
    각 `task_struct`의 `cg_list` 필드를 통해 `css_set`을 사용하여 연결 리스트가 형성되며, 이는 `css_set->tasks`에 고정되어 있다.

- cgroup 계층 파일 시스템은 사용자 공간에서 탐색 및 조작을 위해 마운트할 수 있다.
- 특정 cgroup에 연결된 모든 작업(PID 기준)을 나열할 수 있다.

cgroup의 구현은 성능이 중요한 경로에서 몇 가지 간단한 훅을 커널에 추가한다:

- `init/main.c`에서 시스템 부팅 시 루트 `cgroups` 및 초기 `css_set`을 초기화한다.
- fork 및 exit에서 작업을 `css_set`에 연결하거나 분리한다.

추가로, “cgroup” 유형의 새로운 파일 시스템을 마운트하여 현재 커널에 알려진 cgroups를 탐색하고 수정할 수 있게 한다. cgroup 계층을 마운트할 때, 파일 시스템 마운트 옵션으로 쉼표로 구분된 서브시스템 목록을 지정할 수 있다. 기본적으로 cgroup 파일 시스템을 마운트하면 모든 등록된 서브시스템을 포함하는 계층을 마운트하려고 시도한다.

정확히 동일한 서브시스템 세트를 가진 cgroup 계층이 이미 존재하면 새로운 마운트로 덮어씌워진다. 만약  요청된 서브시스템 중 일부가 기존 계층에서 사용 중이면 마운트는 `-EBUSY` 오류로 실패한다. 활성화된 cgroup 계층에 새로운 서브시스템을 바인딩하거나, 활성 cgroup 계층에서 서브시스템을 언바인딩하는 것은 현재 불가능하다.

cgroup 파일 시스템이 언마운트될 때, 최상위 cgroup 아래에 생성된 자식 cgroup이 있으면, 해당 계층은 언마운트된 상태로 남아 있다. 자식 cgroup이 없으면 계층은 비활성화된다. cgroups에 대한 새로운 시스템 호출은 추가되지 않는다 - 모든 cgroups 쿼리 및 수정 지원은 이 cgroup 파일 시스템을 통해 이루어진다.

각 작업은 `/proc` 아래에 추가된 ‘cgroup’ 파일을 가지고 있으며, 각 활성 계층에 대해 서브시스템 이름 및 cgroup 이름을 cgroup 파일 시스템의 루트에서 상대 경로로 표시한다.

각 cgroup은 해당 cgroup을 설명하는 다음 파일을 포함하는 디렉터리로 표시된다:

- `tasks`: 해당 cgroup에 연결된 작업 목록(PID 기준). 이 목록은 정렬이 보장되지 않는다. 이 파일에 스레드 ID를 쓰면 해당 스레드는 이 cgroup으로 이동한다.
- `cgroup.procs`: cgroup의 스레드 그룹 ID 목록. 이 목록은 정렬되거나 중복 TGID가 없음을 보장하지 않으며, 사용자 공간에서 목록을 정렬/중복 제거해야 한다. 이 파일에 스레드 그룹 ID를 쓰면 해당 그룹의 모든 스레드가 이 cgroup으로 이동한다.
- `notify_on_release flag`: 종료 시 릴리스 에이전트를 실행할 것인가?
- `release_agent`: 릴리스 알림에 사용할 경로 (이 파일은 최상위 cgroup에만 존재).

cpusets와 같은 다른 서브시스템은 각 cgroup 디렉터리에 추가 파일을 추가할 수 있다.

새로운 cgroups는 mkdir 시스템 호출이나 셸 명령을 사용하여 생성된다. cgroup의 속성, 예를 들어 플래그는 위에 나열된 각 cgroup 디렉터리의 적절한 파일에 쓰는 것으로 수정된다. 중첩된 cgroups의 명명된 계층 구조는 큰 시스템을 중첩되고 동적으로 변경 가능한 “소프트 파티션”으로 분할할 수 있게 한다.

각 작업은 해당 작업의 자식이 되는 모든 작업이 자동으로 상속받는 cgroup에 부착되며, 이를 통해 시스템의 작업 부하를 관련된 작업 집합으로 조직할 수 있다. 작업은 필요한 cgroup 파일 시스템 디렉터리에 대한 권한이 허용되는 경우, 다른 cgroup으로 다시 부착될 수 있다.

작업이 한 cgroup에서 다른 cgroup으로 이동되면, 새로운 `css_set` 포인터를 받는다 - 원하는 cgroups 모음이 있는 기존 `css_set`이 이미 있으면 해당 그룹이 재사용되고, 그렇지 않으면 새로운 `css_set`이 할당된다. 적절한 기존 `css_set`은 해시 테이블을 조회하여 찾는다.

cgroup에서 해당 cgroup을 구성하는 css_set(및 따라서 작업)에 접근할 수 있도록, `cg_cgroup_link` 객체 세트가 격자 구조를 형성한다; 각 `cg_cgroup_link`는 `cgrp_link_list` 필드에 단일 cgroup에 대한 `cg_cgroup_links` 목록에 연결되고, `cg_link_list` 필드에 단일 css_set에 대한 `cg_cgroup_links` 목록에 연결된다.

따라서 cgroup의 작업 집합은 cgroup을 참조하는 각 `css_set`을 반복하고, 각 css_set의 작업 집합을 반복하여 순회할 수 있다.

---
참고
- https://www.man7.org/linux/man-pages/man7/cgroups.7.html
- https://access.redhat.com/documentation/ko-kr/red_hat_enterprise_linux/6/html/resource_management_guide/ch01
- https://docs.kernel.org/admin-guide/cgroup-v1/cgroups.html