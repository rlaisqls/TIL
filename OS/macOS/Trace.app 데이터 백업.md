Trace.app은 macOS용 시간 추적 앱으로, DuckDB를 사용하여 데이터를 저장한다.

**데이터 저장 위치**

```
~/Library/Application Support/com.trace.dev/
```

- **database.duckdb**: 메인 DuckDB 데이터베이스
- **database.duckdb.wal**: Write-Ahead Log (미반영 트랜잭션)

**백업 방법**

앱 종료 후 폴더 전체를 복사한다. WAL 파일도 함께 백업해야 최신 데이터가 보존된다.

```bash
cp -r ~/Library/Application\ Support/com.trace.dev ~/Desktop/Trace_Backup
```

---

```bash
#!/bin/bash
BACKUP_DIR=~/Backups/Trace
mkdir -p "$BACKUP_DIR"
cp -r ~/Library/Application\ Support/com.trace.dev "$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S)"
```

```bash
cp -r ~/Desktop/Trace_Backup_20240101/* ~/Library/Application\ Support/com.trace.dev/
```
