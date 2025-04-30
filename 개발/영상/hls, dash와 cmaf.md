## HLS (HTTP Live Streaming)

- 애플(Apple)이 개발한 스트리밍 프로토콜
- 전체 온라인 스트리밍 시장의 약 **70%**를 차지
- **iOS/macOS** 기기에서 필수적으로 사용하는 `FairPlay Streaming` DRM은 **HLS를 통해서만 적용 가능**

- 기술 구성
  - **컨테이너**: `m3u8` 플레이리스트 + MPEG2-TS 청크 (fMP4도 지원됨)
  - **코덱**: H.264 (AVC), H.265 (HEVC)
  - **DRM 호환성**:
  - FairPlay Streaming (기본)
  - Widevine (추가 지원)
  - **암호화 방식**: AES-CBC 모드 (SAMPLE-AES 포함)

---

## MPEG-DASH (Dynamic Adaptive Streaming over HTTP)

- MPEG에서 표준화된 스트리밍 포맷
- HLS 다음으로 많이 사용됨
- `CENC(Common Encryption)`을 통해 **PlayReady**와 **Widevine**을 하나의 콘텐츠에 적용 가능

- 기술 구성
  - **컨테이너**: `mpd` 매니페스트 + MP4 또는 MPEG2-TS 청크 (fMP4 지원)
  - **코덱**: AVC, HEVC, VP9 등 제한 없음
  - **DRM 호환성**:
  - PlayReady
  - Widevine
  - **암호화 방식**: AES-CTR 모드 (CBC도 일부 지원)

---

## CMAF (Common Media Application Format)

- HLS, DASH를 사용하는 경우 멀티 DRM 지원을 위해선 양쪽으로 모두 패키징해야만 했다.
- 이를 위해 2016년 애플과 마이크로소프트가 제안, 2018년 MPEG에서 공식 표준화한 것이 CMAF 포맷이다.
- 클라이언트에 따라 DASH 또는 HLS 형태로 재생이 되지만 미디어 파일은 한 벌로 지원할 수 있게 된다.

- 설계 목적
  - 콘텐츠 저장 및 전송 비용 절감
  - CDN 효율성 개선
  - **초저지연(Ultra Low Latency)** 지원

- 기술 구성
  - **컨테이너 포맷**: fMP4 (Fragmented MP4)
  - HLS도 2016년부터 fMP4 지원
  - **암호화 방식**:
  - DASH: AES-128 CTR
  - HLS: SAMPLE-AES CBC
  - CMAF는 두 방식 모두 지원하지만, 단일 포맷화를 위해 **CBC 중심**으로 통일 중

---
참고

- <https://pallycon.com/ko/blog/%eb%a9%80%ed%8b%b0-drm-%ec%bd%98%ed%85%90%ec%b8%a0-cmaf%ec%9c%bc%eb%a1%9c-%eb%8b%a8%ec%9d%bc%ed%99%94%ed%95%a0-%ec%88%98-%ec%9e%88%ec%9d%84%ea%b9%8c/>
- <https://antmedia.io/cmaf-streaming/>
