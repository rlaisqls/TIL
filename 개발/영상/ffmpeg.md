
```
ffmpeg [options] [[infile options] -i infile]... {[outfile options] outfile}...
```

## 파일 정보 확인

- ffmpeg로 입력 파일 정보 확인
  - `ffmpeg -i input.mp4`
  - `-hide_banner` 옵션을 사용하면, FFmpeg의 로고와 불필요한 버전 정보 없이 파일 정보만을 출력한다.
- ffprobe
  - ffprobe는 FFmpeg 패키지의 일부로, 미디어 파일의 스트림 정보를 보다 상세하게 분석할 수 있다.
  - 해상도 확인
    - `ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 input.mp4`
  - 너비, 높이, 코덱 이름, 비트레이트 확인
    - `ffprobe -v error -select_streams v:0 -show_entries stream=width,height,codec_name,bit_rate -of default=noprint_wrappers=1:nokey=1 input.mp4`

## 파일 형식 변환

- 3gp 파일을 mp4로 변환
  - `ffmpeg -i input.3gp output.mp4`

- m4a를 wav로 변환
  - `ffmpeg -i inputFilename.m4a OutputFilename.wav`

- mkv를 mp4로 변환
  - `ffmpeg -i input.mkv -codec copy output.mp4`

- vcodec, crf, preset 옵션
  - vcodec, crf, preset 옵션을 지정하지 않을 경우 ffmpeg는 다음과 같은 기본 설정을 사용한다.

  - 비디오 코덱 (-vcodec)
    - 기본값: libx264
    - 의미: libx264는 H.264 비디오 코덱이다. H.264는 높은 압축률과 좋은 품질을 제공하는 비디오 코덱으로, 많은 경우에 기본 코덱으로 사용된다.
    - 설정 방법: 기본값을 사용하지 않으려면 다음과 같이 명시적으로 코덱을 지정할 수 있다.

        ```
        ffmpeg -i input.mp4 -vcodec libx265 output.mp4  # H.265 코덱 사용 예시
        ```

  - 품질 설정 (-crf)
    - 기본값: 23
    - 의미: -crf(Constant Rate Factor)는 품질을 조절하는 매개변수
    - 숫자가 낮을수록 품질이 높아지고 파일 크기가 커짐. 숫자가 높을수록 품질이 낮아지고 파일 크기가 작아짐.
    - 일반적으로 18에서 28 사이의 값이 사용된다. (0-51 사이의 값 사용)
    - 설정 방법: 기본값을 변경하려면 다음과 같이 설정할 수 있다.

        ```
        ffmpeg -i input.mp4 -crf 18 output.mp4  # 더 높은 품질
        ffmpeg -i input.mp4 -crf 28 output.mp4  # 더 낮은 품질
        ```

  - 인코딩 속도/효율 (-preset)
    - 기본값: medium
    - 의미: -preset은 인코딩 속도와 압축 효율 간의 균형을 조절한다. medium은 속도, 효율이 중간 정도이고 더 빠른 속도로 인코딩하면 파일 크기가 크게, 더 느린 속도로 인코딩하면 파일 크기가 작아지게 된다.
    - 설정 방법: 기본값을 변경하려면 다음과 같이 설정할 수 있다.

        ```
        ffmpeg -i input.mp4 -preset slow output.mp4  # 더 작은 파일 크기
        ffmpeg -i input.mp4 -preset fast output.mp4  # 더 빠른 인코딩
        ```

- vcodec, crf, preset 설정

  - `ffmpeg -i input.mp4 -vcodec libx264 -crf 20 -preset slow output.mp4`

    - 비디오 코덱: libx264 (H.264)
    - 품질 설정: -crf 20 (기본값 23보다 높은 품질)
    - 인코딩 속도: -preset slow (기본값 medium보다 느린 속도, 더 작은 파일 크기)

### 코덱

비디오 코덱 설정

- 코덱은 인코딩 및 디코딩 방식을 정의한다. -c:v 옵션을 사용해서 비디오 코덱을 지정할 수 있고, -c:a 옵션으로 오디오 코덱을 지정할 수 있다.
  - 코덱을 지정하지 않는 경우: 코덱을 명시적으로 지정하지 않으면 FFmpeg는 소스 파일의 기존 코덱을 사용해서 변환을 시도한다. 이 경우 변환 과정이 빠르고 간단하지만, 호환성 문제가 생길 수 있다.
  - 다른 코덱을 설정하는 경우: 출력 파일에 다른 코덱을 설정하면 원본 비디오와 다르게 새로운 코덱의 특성에 맞게 인코딩된다. 예를 들어, H.264 코덱(libx264)은 높은 압축률을 제공해서 품질을 유지하면서 파일 크기를 줄일 수 있다.

        ```
        ffmpeg -i input.mp4 -c:v libx264 -crf 23 output.mp4
        ```

오디오 코덱 설정

- -c:a copy 옵션을 사용하면 오디오를 재인코딩하지 않고 복사해서, 변환 속도가 빠르고 오디오 품질이 유지된다.
- 오디오 코덱을 바꿀 필요가 있는 경우 (예: AAC 코덱으로) 다음과 같이 명령어를 사용할 수 있다.

    ```
    ffmpeg -i input.mp4 -c:v libx264 -c:a aac -b:a 192k output.mp4
    ```

### 해상도 변환

해상도 변환은 비디오 크기를 조절하는 과정이다. 다양한 장치에서 호환성을 높이거나 저장 공간을 절약하기 위해 필요하다.

- -vf scale과 -s 옵션
- FFmpeg에서 해상도를 바꾸는 두 가지 주요 방법은 -vf scale 필터 옵션과 -s 옵션이다.

- -vf scale 옵션: 이 옵션은 비디오 필터를 사용해서 해상도를 조정한다. 사용자가 비디오 처리 방식을 세밀하게 제어할 수 있고, 추가적인 필터와 연결해서 사용할 수 있다.

    ```
    ffmpeg -i input.mp4 -vf "scale=1280:720" output.mp4
    ```

- -s 옵션: 이 옵션은 해상도를 간단하게 바꾼다. -s 다음에 원하는 해상도를 직접 지정하면 된다.

    ```
    ffmpeg -i input.mp4 -s 1280x720 output.mp4
    ```

  - 예시: 480p로 변환

    - `ffmpeg -i input.mp4 -vf scale=640:480 output.mp4`

### 예시

#### 화면을 잘라내어 해상도 변환하기 (crop과 scale을 함께 사용)

원본 영상의 비율을 유지하면서 해상도를 변경할 때, 필요에 따라 화면의 일부를 자르고(crop) 크기를 바꾸는(scale) 예시는 아래와 같다.

- 목표
  - 원본 영상 해상도: 2880x1824
  - 출력 영상 해상도: 1920x1080
  - 출력 영상의 비율을 유지하고, 위아래를 적절히 자름.

```
ffmpeg -i input_file.mp4 -vf "crop=2880:1620:0:(in_h-1620)/2,scale=1920:1080" -c:a copy output_file.mp4
```

- crop=2880:1620:0:(in_h-1620)/2:
  - 2880:1620: 가로는 2880 그대로 유지하고, 세로는 1620으로 잘라낸다.
  - 0: 가로 방향으로는 자르지 않기 때문에, 시작점은 0이다.
  - (in_h-1620)/2: 원본 영상의 높이(in_h)에서 자를 높이(1620)를 뺀 후, 그 값을 2로 나누어 자를 부분을 위아래로 균등하게 분배한다. 즉, 위아래 각각 102픽셀씩 잘라내는 방식이다.

#### 특정 시간대의 비디오 자르기

- FFmpeg를 사용하여 특정 시간대의 비디오를 자르려면 -ss (시작 시간)와 -t (지속 시간) 또는 -to (종료 시간) 옵션을 사용할 수 있다. 예를 들어 비디오를 0:02:01부터 0:02:43까지 자르고 싶다면, 다음 두 가지 방법 중 하나를 사용할 수 있다.

- 방법 1: -ss와 -to 사용

  - -ss로 시작 시간을 설정, -to로 종료 시간을 설정한다.

    ```
    ffmpeg -i input.mp4 -ss 00:02:01 -to 00:02:43 -output.mp4
    ```

- 방법 2: -ss와 -t 사용

  - -ss로 시작 시간을 설정, -t로 자르고자 하는 구간의 지속 시간을 설정한다.

    ```
    ffmpeg -i input.mp4 -ss 00:02:01 -t 42 -c copy output.mp4
    ```

두 방법 모두 -c copy 옵션을 사용하여 오디오와 비디오 스트림을 재압축하지 않고 복사한다. 이렇게 하면 프로세스가 빨라지고 원본 품질을 유지할 수 있다. 그러나 이 방식은 모든 경우에 적용할 수 없을 수도 있으며, 특정 경우에는 스트림을 재인코딩해야 할 수도 있다.

#### 자른 영상 앞부분이 제대로 보이지 않는 경우

키 프레임은 비디오의 특정 시점에서 전체 프레임을 저장하는 프레임으로, 이 사이의 다른 프레임들은 이전 키 프레임에 대한 차이점만을 저장한다.
따라서 키 프레임이 아닌 지점에서 비디오를 자르면 시작 부분이 올바르게 디코딩되지 않아 영상이 제대로 보이지 않을 수 있다.

이 문제를 해결하기 위해 다음과 같은 방법을 시도해볼 수 있다.

1. 자르기 시작 위치를 약간 조정하기

   - 자르기 시작 위치를 키 프레임에 맞추기 위해 시작 시간을 조금 앞당겨 본다. 예를 들어, 0:02:01 대신에 0:02:00으로 시작하여 원하는 부분을 포함시킬 수 있다.
   - `ffmpeg -i input.mp4 -ss 00:02:00 -c copy temp.mp4`

2. 비디오 재인코딩 사용하기

   - 비디오를 재인코딩하면 시작 부분에 문제가 발생하지 않는다. 하지만 이 방법은 처리 시간이 더 오래 걸리고 파일 크기가 커질 수 있으며, 약간의 품질 저하가 발생할 수 있다.
   - `ffmpeg -i input.mp4 -ss 00:02:01 -to 00:02:43 output.mp4`

3. 두 단계로 자르기

   - 먼저 -ss 옵션으로 시작 부분을 조금 앞당겨서 자른 다음, 두 번째 단계에서 정확한 시작 지점을 재조정한다.

        ```sh
        # 1. 조금 일찍 시작하여 자르기
        ffmpeg -i input.mp4 -ss 00:02:00 -c copy temp.mp4

        # 2. 정확한 시작 지점과 지속 시간으로 자르기
        ffmpeg -i temp.mp4 -ss 00:00:01 -t 42 -c copy output.mp4
        ```

#### 오디오 딜레이

ffmpeg을 사용하여 영상을 변환할 때 오디오 딜레이가 생기는 문제는 여러 원인으로 발생할 수 있다. 이러한 문제를 해결하려면, 다음의 방법들을 시도해볼 수 있다.

- 소스 파일 검사:
    원본 비디오 파일에 이미 오디오 딜레이가 있는지 확인한다. 원본 파일에 문제가 있다면 변환 과정에서 이 문제를 해결하기는 어려울 수 있다.

- 최신 버전의 ffmpeg 사용:
    사용 중인 ffmpeg의 버전이 오래된 경우, 최신 버전으로 업그레이드해 보라.

- 오디오와 비디오 재인코딩:
  - -c:a copy 옵션을 사용하여 오디오를 복사하는 대신 오디오를 명시적으로 재인코딩
  - `ffmpeg -i input_video.mp4 -vf "scale=1920:1080" -c:v libx264 -c:a aac output_video_1080p.mp4`

- 비트레이트 지정:
  - 오디오 딜레이 문제를 해결하기 위해 오디오 비트레이트를 명시적으로 지정해 보라.
  - `ffmpeg -i input_video.mp4 -vf "scale=1920:1080" -c:v libx264 -c:a aac -b:a 192k output_video_1080p.mp4`

- -async 옵션 사용:
  - ffmpeg에는 오디오 딜레이를 수정하기 위한 -async 옵션이 있다. 이 옵션은 오디오 프레임을 비디오 프레임에 맞게 조정한다.
  - `ffmpeg -i input_video.mp4 -vf "scale=1920:1080" -c:v libx264 -c:a aac -async 1 output_video_1080p.mp4`
  - -async 1은 오디오와 비디오 간에 타임스탬프를 동기화하도록 지시한다.

#### hls 인코딩

- ffmpeg -i a.mp3 -c:a copy -vn -hls_playlist_type vod -hls_segment_filename "a_%d.ts" "a.m3u8"

---
참고

- <https://www.ffmpeg.org/>
- <https://trac.ffmpeg.org/wiki/Encode>
