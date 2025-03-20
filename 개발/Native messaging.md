
브라우저 **Native Messaging**은 확장 프로그램(Extension)이 외부 네이티브 애플리케이션과 직접 통신할 수 있도록 하는 기술이다. 보통 웹 브라우저 내에서 실행되는 확장 프로그램은 보안상의 이유로 로컬 파일이나 시스템 리소스에 직접 접근할 수 없다. 하지만, Native Messaging을 사용하면 브라우저 확장이 특정한 **네이티브 애플리케이션**을 실행하고 JSON 메시지를 주고받을 수 있다.

Native messaging을 사용하면 브라우저 확장 플러그인에 아래 같은 기능을 추가할 수 있다.

- **파일 시스템 접근**: 확장 프로그램에서 로컬 파일을 읽거나 쓰는 작업 수행
- **네이티브 애플리케이션 제어**: 특정 데스크톱 애플리케이션을 실행하고 상태를 확인
- **보안 관련 작업**: 키보드 보안, 암호 관리 소프트웨어와 연동
- **VPN 및 네트워크 제어**: 네이티브 VPN 클라이언트와 통신하여 연결 설정

## 동작 방식

1. **확장 프로그램이 Native Messaging Host를 실행**
   - 확장 프로그램이 `chrome.runtime.connectNative()` 또는 `chrome.runtime.sendNativeMessage()` API를 호출하면, 브라우저가 사전에 등록된 네이티브 애플리케이션을 실행한다.

2. **확장 프로그램과 네이티브 애플리케이션 간 메시지 교환**
   - 확장 프로그램은 JSON 메시지를 네이티브 애플리케이션으로 전송하고, 네이티브 애플리케이션은 응답 메시지를 JSON 형식으로 반환한다.

3. **네이티브 애플리케이션 종료**
   - 통신이 끝나거나 특정 조건이 충족되면 네이티브 애플리케이션이 종료된다.

## 주요 구성 요소

### 1. **네이티브 애플리케이션 (Native Messaging Host)**

- 브라우저 외부에서 실행되는 프로그램으로, JSON 형식의 데이터를 표준 입력(`stdin`)과 표준 출력(`stdout`)을 통해 주고받는다.
- Python, Node.js, C++, Java 등의 언어로 구현할 수 있다.

### 2. **Native Messaging 매니페스트 파일**

- 네이티브 애플리케이션을 브라우저 확장에서 사용할 수 있도록 등록하는 JSON 파일이다.
- 예제:

     ```json
     {
       "name": "com.example.native_host",
       "description": "Example native messaging host",
       "path": "/path/to/native/messaging/host",
       "type": "stdio",
       "allowed_origins": [
         "chrome-extension://abcdefghijklmno/"
       ]
     }
     ```

- 이 파일은 OS에 따라 특정 경로에 배치해야 한다.
  - Windows: `HKEY_LOCAL_MACHINE\SOFTWARE\Google\Chrome\NativeMessagingHosts\`
  - macOS/Linux: `/Library/Google/Chrome/NativeMessagingHosts/` 또는 `~/.config/google-chrome/NativeMessagingHosts/`

### 3. **확장 프로그램에서의 API 호출**

- `chrome.runtime.sendNativeMessage()` 또는 `chrome.runtime.connectNative()`를 사용하여 네이티브 애플리케이션과 메시지를 주고받는다.

- 예제 (JavaScript):

     ```javascript
     chrome.runtime.sendNativeMessage(
       "com.example.native_host",
       { text: "Hello from extension!" },
       function(response) {
         console.log("Received response:", response);
       }
     );
     ```

## 보안 고려 사항

- 네이티브 메시징 호스트는 **확장 프로그램에서 명시적으로 등록된 경우에만 실행** 가능하다.
- **악성 코드 방지**를 위해 네이티브 메시징 호스트의 실행 경로는 확장 프로그램에서 제어할 수 없다.
- 메시지 크기는 브라우저마다 제한이 있으며, Chrome에서는 **최대 1MB**까지 가능하다.

---
참고

- <https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging>
- <https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_messaging>
