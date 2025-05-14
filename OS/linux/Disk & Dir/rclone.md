
- `--local-no-set-modtime`
  - local을 백엔드로 사용할 때, rclone은 기본적으로 업로드 이후 chtimes 명령어로 modtime을 갱신한다.
    - (업로드가 완료된 시점을 modtime으로 기록하기 위해)
  - 그런데, mountpoint-s3에선 modtime만 갱신하는 동작을 지원하지 않는다.
    - (modtime 갱신에 대응하는 s3 API가 없기 때문)
    - <https://github.com/awslabs/mountpoint-s3/blob/main/doc/SEMANTICS.md#permissions-and-metadata>

  - 이처럼 modtime 갱신이 불가한 파일 시스템, 혹은 마운트를 사용하는 경우 `--local-no-set-modtime` 옵션을 사용해야한다. 이 옵션을 사용하면 업로드된 파일의 mod time이 실제 업로드된 (이후의) 시각이 아닌, 파일 시스템에서 파일이 복사된 시간으로 기록된다.
    - <https://github.com/rclone/rclone/commit/bf355c45274733368abc43e234563eb3141f1b68>

- `--ignore-times`
  - rclone은 기본적으로 modification time이 같거나, 파일 size가 같으면 업로드를 건너뛴다.
  - `--ignore-times` 옵션을 사용하면 그 조건을 무시하고 무조건 다시 업로드한다.

    > <https://rclone.org/docs/#i-ignore-times><br/>

    > Using this option will cause rclone to unconditionally upload all files regardless of the state of files on the destination.<br/>

    > Normally rclone would skip any files that have the same modification time and are the same size (or have the same checksum if using --checksum).

---
참고

- <https://github.com/rclone/rclone>
- <https://rclone.org/>
