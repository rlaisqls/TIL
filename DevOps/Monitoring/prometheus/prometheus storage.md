Prometheus는 기본적으로 로컬 디스크 기반의 시계열 데이터베이스를 내장하고 있다.

### 구조

- 2시간 단위의 블록(block) 으로 샘플 데이터를 그룹화하여 저장한다.
- 각 블록은 디렉터리 하나로 구성되고, 아래와 같은 구조를 가진다.
  - `chunks/` 하위 디렉터리: 해당 시간 구간의 시계열 샘플 데이터
    - chunks 디렉터리 안의 데이터는 기본적으로 최대 512MB 크기의 segment 파일들로 구성된다.
  - `index`: 메트릭 이름 및 라벨 → 시계열 매핑 정보를 담고 있음
  - `meta.json`: 블록의 메타데이터
  - `tombstones`: 삭제 요청된 시계열 정보를 별도로 기록 (바로 삭제하지 않음)

> WAL (Write-Ahead Log, 선기록 로그)<br/>
>
> - 최신 샘플 데이터는 아직 블록으로 완전히 저장되지 않은 상태이며, 메모리 상에 유지된다.
> - 이 메모리 데이터는 crash(충돌) 대비를 위해 wal/ 디렉터리에 WAL 로그 형태로 저장된다.
> - WAL은 128MB 단위의 segment 파일로 구성된다.
> - 아직 압축되지 않은 원시(raw) 데이터를 포함하고 있어, 일반 블록보다 파일 크기가 크다.
> - Prometheus는 최소 3개의 WAL 파일을 유지하고, 트래픽이 많은 서버에서는 2시간 이상의 데이터를 보존하기 위해 더 많은 WAL 파일을 사용할 수 있다.

```bash
./data
├── 01BKGV7JBM69T2G1BGBGM6KB12
│   └── meta.json
├── 01BKGTZQ1SYQJTR4PB43C8PD98
│   ├── chunks
│   │   └── 000001
│   ├── tombstones
│   ├── index
│   └── meta.json
├── 01BKGTZQ1HHWHV8FBJXW1Y3W0K
│   └── meta.json
├── 01BKGV7JC0RY8A6MACW02A2PJD
│   ├── chunks
│   │   └── 000001
│   ├── tombstones
│   ├── index
│   └── meta.json
├── chunks_head
│   └── 000001
└── wal
    ├── 000000002
    └── checkpoint.00000001
        └── 00000000
```

- Prometheus의 로컬 스토리지는 클러스터링이나 복제 기능이 없다.
- 따라서 하드 디스크나 노드 장애에 취약하며, 단일 노드 데이터베이스로서의 한계를 가진다.
- 운영 환경에서는 아래같은 백업 수단을 사용하는 것을 권장한다.
  - RAID 구성를 구성해 디스크 장애에 대비한 내구성을 확보한다.
  - Prometheus API를 통해 [snapshot](https://prometheus.io/docs/prometheus/latest/querying/api/#snapshot)을 생성한다.
  - [remote read/write APIs](https://prometheus.io/docs/operating/integrations/#remote-endpoints-and-storage)를 사용해 외부에 저장한다.

- Prometheus의 한계를 극복하기 위한 다른 Scalable Solutions을 사용하는 방법도 있다.
  - Thanos
  - Cortex
  - Grafana Mimir
  - M3DB
  - Promscale
  - VictoriaMetrics

---
reference

- <https://prometheus.io/docs/prometheus/latest/storage/>

