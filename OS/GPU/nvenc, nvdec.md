
NVIDIA GPU는 Kepler 세대 이후부터 하드웨어 가속 인코딩(NVENC)을, Fermi 세대 이후부터 하드웨어 가속 디코딩(NVDEC)을 지원한다.

- **NVENC: CUDA와 독립적으로 작동하며 GPU의 성능 저하 없이 동작
- **NVDEC: 여러 코덱을 지원하며 실시간 디코딩 가능

지원 여부는 GPU 세대에 따라 다르며, 최신 정보는 [NVIDIA Video Encode and Decode Support Matrix](https://developer.nvidia.com/video-encode-decode-gpu-support-matrix)에서 확인할 수 있다.

---

## FFmpeg 하드웨어 가속 설정

### 빌드 과정

1. FFmpeg 및 관련 라이브러리 설치:
   - `git clone https://git.ffmpeg.org/ffmpeg.git`
   - NVIDIA 드라이버 및 CUDA Toolkit 설치
   - `nv-codec-headers` 설치: `make install`

2. FFmpeg 빌드 설정:

```bash
./configure --enable-cuda --enable-cuvid --enable-nvdec --enable-nvenc \
--enable-nonfree --enable-libnpp \
--extra-cflags=-I/usr/local/cuda/include \
--extra-ldflags=-L/usr/local/cuda/lib64
make -j -s
```

---

## 트랜스코딩 예시

### CPU 기반 소프트웨어 트랜스코딩 (느림)

```bash
ffmpeg -i input.mp4 -c:a copy -c:v h264 -b:v 5M output.mp4
```

### GPU 하드웨어 가속 트랜스코딩

```bash
ffmpeg -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
-c:v h264_nvenc -b:v 5M output.mp4
```

- `-hwaccel cuda`: GPU 디코딩 활성화
- `-hwaccel_output_format cuda`: GPU 메모리 내에서 프레임 유지 (PCIe 복사 최소화)
- `-c:v h264_nvenc`: NVIDIA 하드웨어 인코더 사용

---

## 해상도 조절 (Resizing)

### 1:1 트랜스코딩에서 GPU 리사이징

```bash
ffmpeg -vsync 0 -hwaccel cuvid -c:v h264_cuvid \
-resize 1280x720 -i input.mp4 \
-c:a copy -c:v h264_nvenc -b:v 5M output.mp4
```

### 1:N 트랜스코딩

```bash
ffmpeg -vsync 0 -hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
-c:a copy -vf scale_npp=1280:720 -c:v h264_nvenc -b:v 5M output_720.mp4 \
-c:a copy -vf scale_npp=640:320 -c:v h264_nvenc -b:v 3M output_360.mp4
```

- `scale_npp`: GPU 기반 리사이징 필터
- 보간 알고리즘 설정 가능 (e.g., `interp_algo=super`)

---

## CPU-GPU 혼합 처리

```bash
ffmpeg -vsync 0 -c:v h264_cuvid -i input.264 \
-vf "fade,hwupload_cuda,scale_npp=1280:720" \
-c:v h264_nvenc output.264
```

- CPU 메모리에서 처리 후 `hwupload_cuda` 필터로 GPU 업로드

---

## 멀티 GPU 설정

### GPU 목록 확인

```bash
ffmpeg -vsync 0 -i input.mp4 -c:v h264_nvenc -gpu list -f null –
```

### 특정 GPU 지정

```bash
ffmpeg -vsync 0 -hwaccel cuvid -hwaccel_device 1 \
-hwaccel cuda -hwaccel_output_format cuda -i input.mp4 \
-c:a copy -c:v h264_nvenc -b:v 5M output.mp4
```

---

## 최적화 및 프로파일링

- **GPU 활용도 측정**:

  ```bash
  nvidia-smi dmon
  nvidia-smi -q -d UTILIZATION
  ```

- **CPU 프로파일링**:

  ```bash
  ./configure --disable-stripping
  ```

- **시각화 도구**:
  - NVIDIA Visual Profiler로 CPU/GPU 타임라인 분석
  - `fade`, `scale_npp`, `hwupload_cuda` 등의 CUDA 연산 흐름 확인

---

참고

- <https://developer.nvidia.com/nvidia-video-codec-sdk>
- <https://docs.nvidia.com/video-technologies/video-codec-sdk/12.0/ffmpeg-with-nvidia-gpu/index.html>
- <https://developer.nvidia.com/blog/nvidia-ffmpeg-transcoding-guide>
