QEMU는 다양한 아키텍처를 가상화하거나 에뮬레이션할 수 있는 오픈소스 도구이다. 리눅스 커널 기반 가상화(KVM)와 함께 사용할 수 있으며, ARM, x86, MIPS, PowerPC 등 여러 CPU 아키텍처를 지원한다.

에뮬레이션과 가상화를 모두 지원하기 때문에 테스트 환경 구축, 이종 플랫폼 디버깅, 운영체제 실습 등 다양한 목적으로 사용된다. docker에서 cross platform build를 할 때도 기본적으로 qemu가 사용된다.

## 주요 특징

- **오픈소스**이며 GNU GPL 라이선스로 배포됨
- **다중 아키텍처 지원**: x86, ARM, RISC-V, PowerPC 등
- **전체 시스템 에뮬레이션(full system emulation)**과 **유저 모드 에뮬레이션(user-mode emulation)** 지원
- **KVM과의 연동**으로 네이티브 수준의 성능 제공
- 스냅샷, 디버깅, USB/네트워크 가상화 등 부 기능 다수

## 에뮬레이션 방식

### 1. 시스템 에뮬레이션 (Full System Emulation)

전체 시스템을 가상화한다. 가상 CPU, 메모리, 디스크, 네트워크 인터페이스 등을 포함해 독립적인 머신처럼 동작시킬 수 있다.

- 예: `qemu-system-aarch64`를 사용하여 ARM 기반 리눅스 이미지를 부팅

```bash
qemu-system-aarch64 \
  -M virt -cpu cortex-a53 \
  -m 1024 -nographic \
  -kernel Image \
  -append "root=/dev/vda2" \
  -drive file=rootfs.img,format=raw,if=virtio
```

### 2. 유저 모드 에뮬레이션 (User Mode Emulation)

특정 바이너리만 에뮬레이션하여 다른 아키텍처의 실행파일을 현재 시스템에서 실행할 수 있도록 한다.

- 예: x86 시스템에서 ARM ELF 바이너리를 실행

```bash
qemu-arm ./app_arm
```

## KVM과의 연동

QEMU는 KVM(Kernel-based Virtual Machine)과 함께 사용할 수 있다. 이 경우 에뮬레이션이 아닌 **하드웨어 가상화 기반**으로 동작하기 때문 속도가 비약적으로 향상된다.

- KVM을 사용할 때는 `-enable-kvm` 옵션을 추가한다.
- 단, 호스트 CPU와 동일한 아키텍처의 게스트만 가속 가능하다.

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 2048 \
  -cdrom ubuntu.iso \
  -boot d
```

---
참고

- <https://www.qemu.org>
- <https://en.wikipedia.org/wiki/QEMU>
- <https://github.com/qemu/qemu>
