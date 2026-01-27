
Shaka Player는 Google에서 개발한 오픈소스 미디어 플레이어 라이브러리이다. 다양한 브라우저 환경에서 일관된 미디어 재생 경험을 제공하기 위해 여러 polyfill을 내장하고 있으며, `shaka.polyfill.installAll()`을 호출하면 등록된 모든 polyfill이 설치된다.

이 문서에서는 Shaka Player가 제공하는 각 polyfill의 역할과 등록 순서를 살펴보고, 그 중 가장 복잡한 EncryptionScheme polyfill의 동작 원리를 상세히 알아본다.

## Polyfill 등록 메커니즘

### `shaka.polyfill.register(callback, priority)`

- `priority`가 **높을수록 먼저** 실행된다
- 기본값은 `0`
- 같은 priority 내에서는 등록된 순서대로 실행

```javascript
// lib/polyfill/all.js
shaka.polyfill.register = function(polyfill, priority) {
  const newItem = {priority: priority || 0, callback: polyfill};
  for (let i = 0; i < shaka.polyfill.polyfills_.length; i++) {
    const item = shaka.polyfill.polyfills_[i];
    if (item.priority < newItem.priority) {
      shaka.polyfill.polyfills_.splice(i, 0, newItem);
      return;
    }
  }
  shaka.polyfill.polyfills_.push(newItem);
};
```

## 실행 순서별 Polyfill 목록

### Priority 0 (기본값) - 가장 먼저 실행

| Polyfill | 파일 | 설명 |
|----------|------|------|
| **PiPWebkit** | `pip_webkit.js` | Safari에서 Picture-in-Picture 지원 |
| **Fullscreen** | `fullscreen.js` | 브라우저별 fullscreen API 통합 |
| **RandomUUID** | `random_uuid.js` | `crypto.randomUUID()` 지원 |
| **VideoPlaybackQuality** | `videoplaybackquality.js` | MSE VideoPlaybackQuality 메트릭 |
| **Orientation** | `orientation.js` | `screen.orientation` API 지원 |
| **Aria** | `aria.js` | ARIAMixin 인터페이스 지원 |
| **Symbol** | `symbol.js` | `Symbol.prototype.description` 지원 |
| **VTTCue** | `vttcue.js` | VTTCue 객체 지원 |
| **PatchedMediaKeysWebkit** | `patchedmediakeys_webkit.js` | webkit-prefixed EME v0.1b 변환 |
| **VideoPlayPromise** | `video_play_promise.js` | `video.play()` Promise rejection 처리 |
| **AbortController** | `abort_controller.js` | AbortController/AbortSignal 지원 |
| **MediaSource** | `mediasource.js` | MSE 버그 패치 |

### Priority -1 - MediaSource 이후 실행

| Polyfill | 파일 | 설명 |
|----------|------|------|
| **MediaCapabilities** | `media_capabilities.js` | `navigator.mediaCapabilities` 지원 |

### Priority -2 - MediaCapabilities 이후 실행

| Polyfill | 파일 | 설명 |
|----------|------|------|
| **EncryptionScheme** | `encryption_scheme.js` | EME EncryptionScheme 쿼리 지원 |

### Priority -10 - 가장 마지막에 실행 (Fallback)

| Polyfill | 파일 | 설명 |
|----------|------|------|
| **PatchedMediaKeysNop** | `patchedmediakeys_nop.js` | EME 미지원 브라우저용 stub |

### 등록 없음 - 조건부 호출

| Polyfill | 파일 | 설명 |
|----------|------|------|
| **PatchedMediaKeysApple** | `patchedmediakeys_apple.js` | Safari FairPlay legacy API 변환 |

## 실행 흐름

```
shaka.polyfill.installAll()
    │
    ├── Priority 0 (12개)
    │   ├── PiPWebkit
    │   ├── Fullscreen
    │   ├── RandomUUID
    │   ├── VideoPlaybackQuality
    │   ├── Orientation
    │   ├── Aria
    │   ├── Symbol
    │   ├── VTTCue
    │   ├── PatchedMediaKeysWebkit
    │   ├── VideoPlayPromise
    │   ├── AbortController
    │   └── MediaSource
    │
    ├── Priority -1 (1개)
    │   └── MediaCapabilities
    │
    ├── Priority -2 (1개)
    │   └── EncryptionScheme
    │
    └── Priority -10 (1개)
        └── PatchedMediaKeysNop (fallback)
```

## Polyfill 상세 설명

### AbortController (Priority: 0)

`AbortController`와 `AbortSignal`을 지원하지 않는 브라우저를 위한 polyfill이다. 네트워크 요청 취소, 스트리밍 중단 등에 사용된다.

**주요 기능:**
- `AbortController.abort(reason)`
- `AbortSignal.aborted`, `AbortSignal.reason`
- `AbortSignal.throwIfAborted()`
- 정적 메서드: `AbortSignal.abort()`, `AbortSignal.timeout()`

```javascript
const controller = new AbortController();
fetch(url, { signal: controller.signal });
controller.abort(); // 요청 취소
```

### Aria (Priority: 0)

접근성(Accessibility)을 위한 ARIA 속성 polyfill이다. ARIAMixin 인터페이스를 지원하지 않는 브라우저(Firefox 등)에서 ARIA 속성을 제공한다.

**지원 속성:**
- `ariaHidden`
- `ariaLabel`
- `ariaPressed`
- `ariaSelected`

### Fullscreen (Priority: 0)

Fullscreen API의 브라우저 간 차이를 해결한다. 각 브라우저마다 다른 prefix를 통일시킨다:

**통합되는 API:**
- `Element.requestFullscreen` (webkit, moz, ms)
- `document.exitFullscreen`
- `document.fullscreenElement` getter
- `document.fullscreenEnabled` getter
- fullscreen 이벤트 프록시 (`fullscreenchange`, `fullscreenerror`)

### MediaSource (Priority: 0)

Media Source Extensions(MSE) API의 브라우저별 버그를 패치한다.

**Safari 버전별 처리:**
- Safari ≤ 10: MSE 블랙리스트 (사용 불가)
- Safari 11-12: `abort()` stub + `remove()` 범위 패치
- Safari 13-15: `abort()` stub

**Tizen 처리:**
- Tizen 2/3/4: Opus 코덱 거부

**공통 처리:**
- 모든 브라우저: TS(mp2t) 컨테이너 거부
- VP09 코덱 문자열 패치 (구형 스마트 TV)

### Orientation (Priority: 0)

Screen Orientation API의 브라우저 간 차이를 해결한다. `screen.orientation`이 없는 환경(예: iPad)에서 화면 방향 API를 제공한다.

**두 가지 모드:**
1. **Screen 기반**: `screen.orientation`이 존재하지만 불완전한 경우 (`lock`, `unlock` 메서드 추가)
2. **Window 기반**: `window.orientation`을 기반으로 전체 polyfill 구현

**지원 방향:**
- `portrait-primary` (0°)
- `portrait-secondary` (180°)
- `landscape-primary` (90°)
- `landscape-secondary` (270°)

### PatchedMediaKeysWebkit (Priority: 0)

`WebKitMediaKeys` 기반의 구형 EME 구현(prefixed EME v0.1b)을 표준 EME API(2015년 3월 드래프트)로 변환한다. Apple 이외의 WebKit 기반 브라우저(구형 Tizen, WebOS 등 Smart TV 환경)를 대상으로 한다.

**주요 기능:**
- `navigator.requestMediaKeySystemAccess` 구현
- `HTMLMediaElement.setMediaKeys` 구현
- `MediaKeys`, `MediaKeySystemAccess`, `MediaKeySession`, `MediaKeyStatusMap` 클래스 구현

**이벤트 변환:**
- `webkitneedkey` → `encrypted`
- `webkitkeymessage` → `message`
- `webkitkeyadded` → `keystatuseschange`
- `webkitkeyerror` → 에러 처리

### PiPWebkit (Priority: 0)

Safari의 webkit-prefixed Picture-in-Picture API를 표준 API로 변환한다.

**주요 기능:**
- `document.pictureInPictureEnabled` 제공
- `HTMLVideoElement.requestPictureInPicture()` 구현
- `document.exitPictureInPicture()` 구현
- `enterpictureinpicture`, `leavepictureinpicture` 이벤트 프록시

**적용 조건:**
- `HTMLVideoElement`가 존재하고
- 표준 PiP API가 없으며
- `webkitSupportsPresentationMode`가 존재할 때

### RandomUUID (Priority: 0)

`crypto.randomUUID()`를 지원하지 않는 브라우저에서 UUID 생성을 지원한다.

**구현 방식:**
```javascript
static randomUUID_() {
  const url = URL.createObjectURL(new Blob());
  const uuid = url.toString();
  URL.revokeObjectURL(url);
  return uuid.substr(uuid.lastIndexOf('/') + 1);
}
```

### Symbol (Priority: 0)

ES6 `Symbol.prototype.description`을 지원하지 않는 환경을 위한 polyfill이다.

```javascript
static getSymbolDescription_() {
  const m = /\((.*)\)/.exec(this.toString());
  return m ? m[1] : undefined;
}
```

### VideoPlayPromise (Priority: 0)

`video.play()` 호출 시 반환되는 Promise의 rejection을 자동으로 무시한다.

**목적:**
일부 앱에서 play() Promise를 처리하지 않아 콘솔에 에러가 표시되는 것을 방지

```javascript
HTMLMediaElement.prototype.play = function() {
  const p = originalPlay.apply(this);
  if (p) {
    p.catch(() => {});  // rejection 무시
  }
  return p;
};
```

### VideoPlaybackQuality (Priority: 0)

`HTMLVideoElement.getVideoPlaybackQuality()`를 지원하지 않는 브라우저를 위한 polyfill이다.

**반환값:**
```javascript
{
  droppedVideoFrames: this.webkitDroppedFrameCount,
  totalVideoFrames: this.webkitDecodedFrameCount,
  corruptedVideoFrames: 0,
  creationTime: NaN,
  totalFrameDelay: 0
}
```

### VTTCue (Priority: 0)

WebVTT 자막 처리를 위한 `VTTCue` 생성자 polyfill이다.

**지원 케이스:**
- 3인자 TextTrackCue
- 6인자 TextTrackCue (구버전)
- Edge 브라우저 특수 처리

### MediaCapabilities (Priority: -1)

`navigator.mediaCapabilities` API를 제공한다.

**항상 polyfill 적용되는 플랫폼:**
- Apple 브라우저 (Safari)
- PlayStation 4/5
- WebOS (LG)
- Tizen (Samsung)
- Chromecast
- EOS
- Hisense

**주요 기능:**
- `decodingInfo()` 구현
- DRM 지원 확인 (`requestMediaKeySystemAccess` 래핑)
- Chromecast: `cast.__platform__.canDisplayType()` 활용
- 결과 캐싱

**Priority가 -1인 이유:**
`MediaSource` polyfill이 먼저 적용된 후 실행되어야 한다.

### EncryptionScheme (Priority: -2)

EME EncryptionScheme 쿼리를 지원한다. 내부적으로 `EncryptionSchemePolyfills` 외부 라이브러리를 사용한다.

**Priority가 -2인 이유:**
다른 EME polyfill들이 먼저 적용된 후 실행되어야 한다.

### PatchedMediaKeysNop (Priority: -10)

EME를 전혀 지원하지 않는 브라우저용 fallback stub이다.

**동작:**
- `requestMediaKeySystemAccess`: 항상 "The key system specified is not supported" 에러 반환
- `setMediaKeys`: mediaKeys가 null이 아니면 "MediaKeys not supported" 에러 반환
- `MediaKeys`, `MediaKeySystemAccess`: 생성자에서 TypeError 발생

**Priority가 -10인 이유:**
가장 마지막에 실행되어 다른 MediaKeys polyfill이 설치되지 않은 경우에만 동작한다.

### PatchedMediaKeysApple (등록 없음)

Safari의 legacy Apple FairPlay Streaming을 위한 polyfill이다. `WebKitMediaKeys`를 표준 `MediaKeys` 인터페이스로 변환한다.

**직접 register하지 않는 이유:**
`MediaCapabilities` 등 다른 코드에서 필요시 직접 `install()` 호출

**특징:**
- FairPlay Streaming(FPS) DRM 지원
- `WebKitMediaKeys.isTypeSupported()` 사용
- `webkitneedkey` → `encrypted` 이벤트 변환
- skd URL 형식의 init data 처리
- `uninstall()` 메서드 제공 (선택적 활성화)

## EME와 DRM 배경 지식

EncryptionScheme polyfill을 이해하려면 EME와 DRM의 관계를 먼저 알아야 한다.

웹에서 저작권이 있는 미디어를 재생하려면 DRM(Digital Rights Management) 시스템이 필요하다. DRM 시스템은 각 벤더마다 다르게 구현되어 있어서, W3C에서 EME(Encrypted Media Extensions)라는 표준 API를 정의했다. EME는 웹 애플리케이션과 CDM(Content Decryption Module) 사이의 표준화된 인터페이스 역할을 한다.

```
┌─────────────────────────────────────────────────────────────────┐
│                       웹 애플리케이션                           │
│                    (JavaScript Player)                          │
└─────────────────────────┬───────────────────────────────────────┘
                          │ EME API 호출
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     EME API (브라우저)                          │
│          navigator.requestMediaKeySystemAccess()                │
│          MediaKeys, MediaKeySession 등                          │
└─────────────────────────┬───────────────────────────────────────┘
                          │
          ┌───────────────┼───────────────┐
          ▼               ▼               ▼
    ┌──────────┐    ┌──────────┐    ┌──────────┐
    │ Widevine │    │ PlayReady│    │ FairPlay │
    │  (CDM)   │    │  (CDM)   │    │  (CDM)   │
    └──────────┘    └──────────┘    └──────────┘
```

**주요 CDM 시스템**

- **Widevine** (`com.widevine.alpha`): Google에서 개발. Chrome, Firefox, Edge, Android에서 지원
- **PlayReady** (`com.microsoft.playready`): Microsoft에서 개발. Edge, Windows, Xbox에서 지원
- **FairPlay** (`com.apple.fps.1_0`): Apple에서 개발. Safari, iOS, macOS에서 지원

## EncryptionScheme 상세

**encryptionScheme이란**

암호화된 미디어 콘텐츠는 여러 가지 암호화 방식(encryption scheme)으로 보호될 수 있다. EME API의 `encryptionScheme` 속성은 콘텐츠가 어떤 암호화 방식을 사용하는지 명시한다.

**cenc (Common Encryption)**: AES-128-CTR 모드를 사용한다. DASH 스트리밍에서 주로 사용되며, Widevine과 PlayReady가 지원한다.

```
원본 데이터:  [Block 1] [Block 2] [Block 3] ...
                 ↓         ↓         ↓
CTR 모드:    XOR with   XOR with   XOR with
             Counter1   Counter2   Counter3
                 ↓         ↓         ↓
암호화 결과:  [Enc 1]   [Enc 2]   [Enc 3]  ...
```

- 블록을 순서대로 처리하지 않아도 됨 (Random Access 가능)
- 병렬 처리 가능
- 패딩 불필요

**cbcs (Common Encryption with CBC and Subsample)**: AES-128-CBC 모드에 패턴 암호화를 적용한다. HLS 스트리밍과 FairPlay에서 주로 사용된다.

```
패턴 암호화 (1:9 패턴 예시):
[암호화 블록] [평문 9블록...] [암호화 블록] [평문 9블록...] ...
```

- 일부 블록만 암호화하여 성능 최적화
- 하드웨어 디코더와의 호환성 우수
- Apple 생태계에서 필수

**왜 구분이 필요할까**

동일한 CDM이라도 모든 암호화 방식을 지원하지 않을 수 있다:

- **Widevine L1**: cenc O, cbcs O
- **Widevine L3**: cenc O, cbcs는 일부 플랫폼만
- **PlayReady**: cenc O, cbcs는 버전에 따라 다름
- **FairPlay**: cenc X, cbcs O

따라서 미디어 플레이어는 재생 전에 브라우저가 해당 암호화 방식을 지원하는지 확인해야 한다.

**encryptionScheme 미지원 시 문제**

`encryptionScheme`을 지원하지 않는 브라우저는 해당 속성을 무시하고 `requestMediaKeySystemAccess()`를 성공시킨다:

```javascript
const config = [
  {
    videoCapabilities: [
      {
        contentType: 'video/mp4; codecs="avc1.42E01E"',
        encryptionScheme: "cbcs", // 브라우저가 무시함
      },
    ],
  },
];

const access = await navigator.requestMediaKeySystemAccess(
  "com.widevine.alpha",
  config,
);
// 성공! 하지만 실제로 cbcs를 지원하지 않을 수 있음
// → 재생 시작 후에야 오류 발생
```

**Polyfill 동작 방식**

EncryptionScheme polyfill은 3단계 프로브 시스템을 사용한다:

1. `install()` 호출 시 `requestMediaKeySystemAccess`를 프로브 함수로 교체
2. 첫 번째 호출 시 네이티브 `encryptionScheme` 지원 여부를 비동기로 감지
3. 감지 결과에 따라 polyfill 활성화 또는 원본 API 유지

```javascript
// 핵심 로직 (단순화)
const originalRequestAccess = navigator.requestMediaKeySystemAccess;

navigator.requestMediaKeySystemAccess = async function (keySystem, configs) {
  // 1. encryptionScheme 정보를 추출하여 저장
  const schemeMap = extractEncryptionSchemes(configs);

  // 2. encryptionScheme을 제거한 config로 원본 API 호출
  const cleanedConfigs = removeEncryptionSchemes(configs);
  const access = await originalRequestAccess.call(
    navigator,
    keySystem,
    cleanedConfigs,
  );

  // 3. 실제 지원 여부를 probing으로 확인
  const supported = await probeEncryptionScheme(keySystem, schemeMap);
  if (!supported) {
    throw new DOMException(
      "Unsupported encryption scheme",
      "NotSupportedError",
    );
  }

  // 4. getConfiguration()을 래핑하여 encryptionScheme 정보 복원
  return wrapKeySystemAccess(access, schemeMap);
};
```

## 설치 타이밍 문제

Shaka Player에서 polyfill 설치 타이밍에 따라 문제가 발생할 수 있다. 특히 Safari 환경에서 주의가 필요하다.

**문제 상황**

`shaka.polyfill.installAll()`을 명시적으로 호출하지 않으면, polyfill이 Shaka Player 내부에서 자동으로 설치된다. 하지만 설치 타이밍이 번들링/로딩 순서에 따라 달라진다:

- 로컬 개발 서버: 모듈을 lazy하게 로드 → polyfill 먼저 설치됨
- 배포 번들: 빠르게 실행 → polyfill 설치 전에 `player.load()` 실행될 수 있음

이 경우 "Waiting to detect encryptionScheme support" 메시지가 `player.load()` 이후에 나타나며, 감지가 완료되기 전에 DRM 쿼리가 수행된다.

**Safari에서만 문제가 되는 이유**

- Chrome/Firefox: Widevine 사용, `encryptionScheme` 네이티브 지원 → polyfill 불필요
- Safari: FairPlay 사용, `encryptionScheme` 지원 방식이 다름 → polyfill 감지 필요

**installAll() vs 개별 install()**

- `installAll()`: 등록된 모든 polyfill을 설치하지만, Shaka 4.x부터 `PatchedMediaKeysApple`은 자동 포함되지 않음
- `PatchedMediaKeysApple.install()`: Safari의 legacy Apple Media Keys를 위한 polyfill을 명시적으로 설치

Safari 14+ 이후 Modern EME(`com.apple.fps`)를 지원하면서, Shaka Player는 Safari 14+ 감지 시 legacy polyfill을 설치하지 않는다. 하지만 `encryptionScheme` 감지는 여전히 비동기적으로 수행되므로, 브라우저 성능 향상으로 인해 감지 완료 전에 `player.load()`가 실행될 확률이 높아졌다.

**권장 해결 방법**

DRM 관련 polyfill만 명시적으로 설치하면 불필요한 polyfill을 로드하지 않으면서도 타이밍 문제를 해결할 수 있다:

```javascript
import shaka from "shaka-player";

// player 생성 전에 DRM 관련 polyfill을 명시적으로 설치
shaka.polyfill.EncryptionScheme.install();
shaka.polyfill.PatchedMediaKeysApple.install();
shaka.polyfill.PatchedMediaKeysWebkit.install();
shaka.polyfill.PatchedMediaKeysNop.install();
shaka.polyfill.MediaCapabilities.install();

const player = new shaka.Player(videoElement);
await player.load(manifestUrl);
```

- **EncryptionScheme**: `encryptionScheme` 감지 및 polyfill (EME + MediaCapabilities 모두 래핑)
- **PatchedMediaKeysApple**: Safari FairPlay legacy API 변환
- **PatchedMediaKeysWebkit**: WebKit 기반 Smart TV 환경의 prefixed EME 변환
- **PatchedMediaKeysNop**: EME 미지원 환경에서 graceful degradation
- **MediaCapabilities**: `decodingInfo()`에서 DRM 정보 포함한 capability 쿼리 지원

모든 polyfill을 나열해서 호출해도 충돌이 발생하지 않는다. 각 polyfill이 `install()` 내부에서 자체적으로 환경을 감지하여, 조건에 맞을 때만 실제로 적용되기 때문이다:

- **PatchedMediaKeysApple**: `window.WebKitMediaKeys`가 존재하고 Safari인 경우에만 적용
- **PatchedMediaKeysWebkit**: `HTMLMediaElement.prototype.webkitGenerateKeyRequest`가 존재하는 경우에만 적용
- **PatchedMediaKeysNop**: `navigator.requestMediaKeySystemAccess`가 존재하지 않는 경우에만 적용

```javascript
// PatchedMediaKeysNop 내부 로직 (단순화)
static install() {
  if (navigator.requestMediaKeySystemAccess &&
      MediaKeySystemAccess.prototype.getConfiguration) {
    // 네이티브 EME가 이미 존재하므로 아무것도 하지 않음
    return;
  }

  // EME가 없는 환경 → stub 구현 설치
  navigator.requestMediaKeySystemAccess = function () {
    return Promise.reject(new Error("EME not supported"));
  };
}
```

따라서 모던 브라우저에서는 PatchedMediaKeys 계열 polyfill이 모두 무시되고, EncryptionScheme과 MediaCapabilities만 실질적으로 동작한다.

---
참고

- <https://www.w3.org/TR/encrypted-media/>
- <https://github.com/shaka-project/eme-encryption-scheme-polyfill>
- <https://github.com/shaka-project/shaka-player/issues/4489>
