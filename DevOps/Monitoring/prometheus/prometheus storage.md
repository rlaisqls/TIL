
Prometheus includes a local on-disk time series database, but also optionally integrates with remote storage systems.

## Local storage

Prometheus's local time series database stores data in a custom, highly efficient format on local storage.

### On-disk layout

Ingested samples are grouped into **blocks of two hours**. Each two-hour block consists of a directory containing a chunks subdirectory containing all the time series samples for that window of time, a metadata file, and an index file (which indexes metric names an labels to time series in the chunks directory).

The samples in the chunks directory are grouped together into one or more segment files of up to 512MB each by default. When series are deleted via the API, deletion records are stored in separate tombstone files (instead of deleting the data immediately from the chunk segments).

The current block for inconming samples is kept in memory and is not fully persisted. It is **secured against craches by a write-ahead log files** are stored in the `wal` directory in 128MB segments.

These files contain raw data that has not yet been compacted; thus they are significantly larger that regular block files. Prometheus will retain a minimum of three write-ahead log files. High-traffic servers may retain more that three WAL files in order to keep at least two hours of raw data.

A Prometheus server's data directory looks something like this:

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

Note that a limitation of local storage is that is not clustered or replicated. Thus, it is not arbitrily scalable or durable in the face of drive or node outages and should be managed like any other single node database. The use of **RAID** is suggested for strage availabiliry, and [snapshots](https://prometheus.io/docs/prometheus/latest/querying/api/#snapshot) are recommanded for backups. With proper architecture, it is possible to retain years of data in local storage.

Alternatively, external storage may be used via the [remote read/write APIs](https://prometheus.io/docs/operating/integrations/#remote-endpoints-and-storage). Careful evaluation is required for these systems as they vary greatly in durability, performance, and efficiency.

---
reference
- https://prometheus.io/docs/prometheus/latest/storage/