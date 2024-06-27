- Cramfs (Compressed ROM File System)는 플래시 디바이스 내부에서 사용 가능한 압축된 읽기 전용 리눅스 파일 시스템이다.
- 간단하고 공간 효율적이다.
- 메모리 크기가 작은 임베디드 디자인에 활용된다.
- 현재 시스템에서 사용자 어플리케이션 실행폴더로 활용
- 읽기 전용으로 중간에 전원이 꺼지더라도 파일시스템이 안전하다.

- Cramfs Util 설치
  
    ```bash
    sudo apt-get install cramfsprogs
    ```

- Cramfs 폴더: `/sdk/rootfs/cramfs`
- 해당 폴더에 작성한 어플리케이션 카피하여 이미지를 만듬
  
- Cramfs 만들기
  ```bash
  cd /sdk/rootfs/
  sudo ./mkcramfs
  ```

- 이후 ua.cramfs가 만들어지고, 이 파일을 /tftpboot나 업그레이드 폴더에 카피하여 업그레이드할 수 있다.
