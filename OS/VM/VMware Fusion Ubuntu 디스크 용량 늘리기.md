
VMWare + Ubuntu 조합을 사용하다 보면, 미리 설정해 둔 디스크 용량이 부족한 경우가 있다. VMware의 옵션으로 디스크 용량을 늘릴 수는 있지만, 이 경우 소프트웨어적으로 인식을 못하기 때문에 직접 우분투에서 설정을 변경해야 한다.

### VMWare 디스크 할당 늘리기

우선 가상 머신을 Shut down 시킨 후 설정에 들어가서 하드디스크 용량을 늘려준다.

<img width="352" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/560755df-14e9-4f5c-92dd-7bbf8d9e5753">

<br/>

<img width="352" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/13cdfd6b-af3c-4bb0-96d1-59cb124337b5">

### 디스크 파티션 늘리기

`lsblk` 명령어로 디스크를 확인해보면 `nvme0n1`이라는 디스크의 용량이 늘어나있는 걸 볼 수 있다. 

<img width="350" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/10b27c31-e74c-437a-a8bc-856d0a8a1bc9">

해당 디스크의 파티션 중 1, 2번 파티션은 부팅을 위한 공간이고, 3번 파티션이 실제 lv 볼륨을 가지고 있는 파티션이다. 따라서 `growpart` 명령어로 `/dev/nvm0n1`의 3번 파티션에 공간을 더 할당해준다.

<img width="626" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/8e786c3f-55f4-40ab-9774-95fd51b14683">

`nvme0n1p3` 파티션에 공간이 할당된 것을 확인할 수 있다. 하지만 아직 lv에 용량이 할당된 상태는 아니다.

<img width="352" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/8a1d6654-ec12-4b57-be56-a89c0465bcdf">

<img width="418" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/c07e07fe-3f65-47a9-8c54-e0bfdb6ea444">

### lv 할당 늘리기

lv가 해당 파티션의 용량을 모두 사용할 수 있도록 확장하기 위해서 아래와 같이 `lvextend` 명령어를 사용할 수 있다.

```bash
lvextend -l +100%FREE -n /dev/ubuntu-vg/ubuntu-lv
```

<img width="707" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/0b2cd353-57b7-4796-8ed0-7878b386a1a2">

### 파일시스템 확장

마지막으로 파일시스템을 늘어난 파티션에 맞게 확장한다. 파일 시스템 타입이 `ext4`이므로 `resize2fs`로 확장한다.  

```bash
resize2fs /dev/ubuntu-vg/ubuntu-lv
```

<img width="804" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/4fad307b-8c54-43ed-a8b3-acfde66576d3">

resize2fs 실행 후 `df` 명령어를 쳐보면 파일 시스템이 성공적으로 늘어난 것을 볼 수 있다!

---
참고
- https://www.lesstif.com/lpt/lsblk-106856724.html
- https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/lv_extend
- https://linux.die.net/man/8/resize2fs